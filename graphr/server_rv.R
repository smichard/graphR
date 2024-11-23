options(shiny.maxRequestSize = 50 * 1024^2)

server_rv <- function(input, output, session) {
  
  processed_data <- reactive({
    file1 <- input$file_rv
    req(file1)
    ext <- tools::file_ext(file1$name)
    file_path <- paste(file1$datapath, ext, sep = ".")
    file.rename(file1$datapath, file_path)
    
    if (ext == "csv") {
      data <- read.csv(file_path, header = TRUE, sep = ",", dec = ".", fill = FALSE, comment.char = "")
    } else {
      data <- data.frame(read_excel(file_path, sheet = 1, col_names = TRUE))
    }
    standardize_columns(data)
  })
  observe({
    shinyjs::disable(id = "Generate_rv")
    shinyjs::toggleState(id = "Generate_rv", condition = !is.null(input$file_rv))
  })
  
  observeEvent(input$Generate_rv, {
    shinyjs::hide("pdfview_rv")
    shinyjs::show("progress_bar_rv")
    
    output$progress_bar_rv <- renderPlot({
      withProgress(message = 'Generating Report', value = 0, {
        # Progress: Importing Data
        setProgress(0.1, message = "Importing Data")
        
        # Process input file
        data_sub <- processed_data()
        
        # Prepare host information
        overview_host <- prepare_host_information(data_sub, file_path)
        
        # Progress: Calculations
        setProgress(0.3, message = "Performing Calculations")
        data_comp <- get_stats(data_sub)
        top_VM_comp <- get_top_VM(data_sub)
        
        # Get statistics for each datacenter if multiple are available
        dc_list <- unique(data_sub$Datacenter)
        data_list <- list()
        top_VM_list <- list()
        plot_dc <- list()
        
        if (length(dc_list) > 1) {
          data_overview <- get_stats_overview(data_sub)
          for (i in seq_along(dc_list)) {
            df <- data_sub %>% filter(Datacenter == dc_list[i]) %>% get_stats()
            data_list[[i]] <- df
            top_VM_list[[i]] <- get_top_VM(df)
            plot_dc[[i]] <- generate_plots(df, data_sub, dc_list[i])
          }
        }
        
        # Progress: Generating Diagrams
        setProgress(0.6, message = "Generating Diagrams")
        
        # Generate plots for the entire dataset
        plot_comp <- generate_plots(data_comp, data_sub)
        
        # Additional plots
        plot_OS <- generate_plot_OS(data_sub)
        plot_Host <- generate_plot_Host(data_sub)
        
        # Prepare network plots
        plot_network_VM <- generate_network_plot(data_sub, "Datacenter", "VM")
        plot_network_Host <- generate_network_plot(data_sub, "Host", "VM")
        plot_network_Network <- generate_network_plot(data_sub, "Network_1", "VM")
        
        # Progress: Generating Slides
        setProgress(0.8, message = "Generating Slides")
        file_name <- get_rep_name()
        
        # Generate the report
        generate_report(input, file_name, data_comp, plot_comp, top_VM_comp, data_list, plot_dc, top_VM_list, dc_list, overview_host, plot_Host, plot_OS, plot_network_VM, plot_network_Host, plot_network_Network)
        
        # Update UI element to display generated report
        output$pdfview_rv <- renderUI({
          tags$iframe(style = "height:610px; width:100%; scrolling=yes", src = file_name[1])
        })
        
        shinyjs::hide("progress_bar_rv")
        shinyjs::show("pdfview_rv")
      })
    })
  })
}

# Helper function to process input data


# Helper function to prepare host information
prepare_host_information <- function(data_sub, file_path) {
  tryCatch({
    overview_host <- data.frame(read_excel(file_path, sheet = "vHost", col_names = TRUE))
    overview_host <- overview_host %>%
      na.omit() %>%
      mutate(Memory = round(Memory / 1000, 1)) %>%
      arrange(Datacenter)
    overview_host
  }, error = function(e) {
    NULL
  })
}

# Helper function to standardize columns in the dataset
standardize_columns <- function(data) {
  if ("In.Use.MiB" %in% colnames(data)) {
    cols <- c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MiB", "In.Use.MiB", "Datacenter", "OS.according.to.the.configuration.file", "Host", "Network..1")
  } else {
    cols <- c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MB", "In.Use.MB", "Datacenter", "OS.according.to.the.configuration.file", "Host", "Network..1")
  }
  data <- data[, cols]
  colnames(data) <- c("VM", "Powerstate", "CPU", "Memory", "Provisioned_MB", "In_Use_MB", "Datacenter", "OS", "Host", "Network_1")
  na.omit(data)
}

# Helper function to generate the report PDF
generate_report <- function(input, file_name, data_comp, plot_comp, top_VM_comp, data_list, plot_dc, top_VM_list, dc_list, overview_host, plot_Host, plot_OS, plot_network_VM, plot_network_Host, plot_network_Network) {
  
  # Ensure the 'www' directory exists
  if (!dir.exists("www")) {
    dir.create("www")
  }

  # Define the full file name with path to the 'www' directory
  file_name <- paste0("www/report_", as.integer(Sys.time()), "_", sample(1000:9999, 1), ".pdf")
  
  print(paste("Attempting to write PDF to:", file_name))
  pdf(file = file_name, width = 16, height = 9)
  
  slideFirst(titleName = ifelse(isolate(input$title_rv) == "Report Title", "RV_Tools Summary", as.character(isolate(input$title_rv))),
             authorName = ifelse(isolate(input$author_rv) == "Author of the Report", "Name", as.character(isolate(input$author_rv))),
             documDate = Sys.Date())
  
  slideText("Find herein a summary of the provided RV_Tools.  \nThe following profiles were considered:\nLarge: VM's with 6 vCPU or more\nMedium: VM's with less than 6 vCPU and more than 2 vCPU\nSmall: VM's with 2 vCPU or less.",
            "Introduction")
  
  if (length(dc_list) > 1) {
    generate_overview_slide(data_overview)
  }
  
  generate_slides(data_comp, plot_comp, top_VM_comp)
  
  if (length(dc_list) > 1) {
    for (i in seq_along(dc_list)) {
      generate_slides(data_list[[i]], plot_dc[[i]], top_VM_list[[i]], dc_list[i])
    }
  }
  
  slideChapter("Host and OS overview")
  slidePlot(plot_Host, "Number of VM's for each Host")
  slidePlot(plot_OS, "Overview of Operating Systems")
  
  if (!is.null(overview_host)) {
    slideTable(overview_host, "Host overview")
  }
  
  slideChapter("Cluster diagrams")
  slidePlot(plot_network_VM, "Cluster: VM's per Datacenter")
  slidePlot(plot_network_Host, "Cluster: VM's per Host")
  slidePlot(plot_network_Network, "Cluster: VM's per Network")
  
  slideLast()
  dev.off()
}

# Helper function to generate OS plot
generate_plot_OS <- function(data_sub) {
  tmp <- data_sub %>% group_by(OS) %>% summarise(Frequency_OS = n()) %>% mutate(OS = fct_reorder(OS, Frequency_OS, .desc = TRUE))
  plot_OS <- ggplot(tmp, aes(x = OS, y = Frequency_OS)) + 
    geom_bar(stat = "identity", width = .7, fill = "steelblue") + 
    xlab("") + ylab("Count [ - ]")
  plot_OS <- designPlot(plot_OS)
  plot_OS + theme(axis.text.x = element_text(size = 12, angle = 270, hjust = 0.6, vjust = 0.0), axis.ticks.x = element_blank())
}

# Helper function to generate Host plot
generate_plot_Host <- function(data_sub) {
  tmp <- data_sub %>% group_by(Host) %>% summarise(Frequency_Host = n())
  mode <- mean(tmp$Frequency_Host)
  plot_Host <- ggplot(tmp, aes(x = Host, y = Frequency_Host)) + 
    geom_bar(stat = "identity", width = .7, fill = "steelblue") + 
    xlab("") + ylab("Count [ - ]") + 
    geom_hline(yintercept = mode, col = "darkorange", size = 1.2, linetype = "dashed", show.legend = TRUE) + 
    geom_text(aes(3, mode, label = "Average", vjust = -0.3), col = "darkorange", size = 5)
  plot_Host <- designPlot(plot_Host)
  plot_Host + theme(axis.text.x = element_text(size = 12, angle = 270, hjust = 1, vjust = 0.0), axis.ticks.x = element_blank())
}

# Helper function to generate network plot
generate_network_plot <- function(data_sub, group_col, vm_col) {
  net <- unique(data_sub[[group_col]])
  new_vertices <- get_vertices(net)
  network_label <- as.vector(net)
  
  tmp <- data_sub[, c(group_col, vm_col)]
  tmp.g <- graph.data.frame(d = tmp, directed = FALSE)
  tmp.g <- add_vertices(tmp.g, length(net), attr = new_vertices)
  
  ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
}
