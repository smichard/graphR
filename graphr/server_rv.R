options(shiny.maxRequestSize=50*1024^2) 

server_rv <- function(input, output) {
  # Create a subdirectory in tempdir() for this session
  #temp_dir <- tempdir()
  #user_subdir <- file.path(temp_dir, paste0("session_", as.integer(Sys.time()), floor(runif(1, min=1000, max=9999))))
  #dir.create(user_subdir, showWarnings = FALSE)

  # Map a URL path to the user_subdir
  #resource_path <- paste0("tmp", floor(runif(1, min=1000, max=9999)))
  #shiny::addResourcePath(resource_path, user_subdir)
  
  # Create a temp directory within www
  temp_dir <- file.path("www", "tmp")
  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }


  observe({
    shinyjs::disable(id = "Generate_rv")
    shinyjs::toggleState(id = "Generate_rv",condition = !is.null(input$file_rv))
  })
  
  
  observeEvent(input$Generate_rv, {
    #progress
    shinyjs::hide("pdfview_rv")
    shinyjs::show("progress_bar_rv")
    output$progress_bar_rv <- renderPlot({
      withProgress(message = 'Generating Report', value = 0, {
        
        # progress
        setProgress(0.1, message = "Importing Data")
        
        #browser()
        file1 <- input$file_rv
        ext <- tools::file_ext(file1$name)
        file.rename(file1$datapath, paste(file1$datapath, ext, sep = "."))
        # check which file ending used
        if(ext == "csv"){
          data <- read.csv(paste(file1$datapath, ext, sep="."), header = TRUE, sep = ",", dec = ".", fill = FALSE, comment.char = "")
          # check for OS column
          if("OS.according.to.the.configuration.file" %in% colnames(data)){
            required_columns <- c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MiB", "In.Use.MiB", "Datacenter", "OS.according.to.the.configuration.file", "Host", "Network..1")
          } else{
            required_columns <- c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MiB", "In.Use.MiB", "Datacenter", "OS", "Host", "Network..1")
          }
          missing_columns <- setdiff(required_columns, colnames(data))
          if(length(missing_columns) > 0){
            stop(paste("The following required columns are missing from the data:", paste(missing_columns, collapse=", "), "\nPlease read the instructions carefully."))
          }
          data_sub <- data[, required_columns]
          colnames(data_sub) <- c("VM", "Powerstate", "CPU", "Memory", "Provisioned_MiB", "In_Use_MiB", "Datacenter", "OS", "Host", "Network_1")
          data_sub <- na.omit(data_sub)
          overview_host <- NULL
        }else{
          # using readxl package for xls import
          data <- data.frame(read_excel(paste(file1$datapath, ext, sep="."), sheet=1, col_names=TRUE))
          # check for OS column
          if("OS.according.to.the.configuration.file" %in% colnames(data)){
            required_columns <- c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MiB", "In.Use.MiB", "Datacenter", "OS.according.to.the.configuration.file", "Host", "Network..1")
          } else{
            required_columns <- c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MiB", "In.Use.MiB", "Datacenter", "OS", "Host", "Network..1")
          }
          missing_columns <- setdiff(required_columns, colnames(data))
          if(length(missing_columns) > 0){
            stop(paste("The following required columns are missing from the data:", paste(missing_columns, collapse=", "), "\nPlease read the instructions carefully."))
          }
          data_sub <- data[, required_columns]
          colnames(data_sub) <- c("VM", "Powerstate", "CPU", "Memory", "Provisioned_MiB", "In_Use_MiB", "Datacenter", "OS", "Host", "Network_1")
          data_sub <- na.omit(data_sub)
          
          # import host information
          overview_host <- tryCatch({
            data.frame(read_excel(paste(file1$datapath, ext, sep="."), sheet="vHost", col_names=TRUE))
          }, warning = function(war) {
            # Is executed if warning encountered
          }, error = function(err) {
            # Is executed if error encountered
          })  
        }
        
        # progress
        setProgress(0.3, message = "Performing Calculations")    
        
        # get stats for all entries in file
        data_comp <- get_stats(data_sub)
        
        top_VM_comp <- get_top_VM(data_sub)
        
        # get stats for each datacenter in file
        dc_list <- unique(data_sub$Datacenter)
        
        if(length(dc_list) > 1){
          data_overview <- get_stats_overview(data_sub)
          data_list <- list()
          for(i in 1:length(dc_list)){
            df <- data_sub %>%
              filter(Datacenter == dc_list[i]) %>%
              get_stats()
            data_list[[length(data_list)+1]] <- df 
            i <- i + 1
          }
        }
        
        if(length(dc_list) > 1){
          top_VM_list <- list()
          for(i in 1:length(dc_list)){
            df <- data_sub %>%
              filter(Datacenter == dc_list[i]) %>%
              get_top_VM()
            top_VM_list[[length(top_VM_list)+1]] <- df 
            i <- i + 1
          }
        }
        
        # progress
        setProgress(0.6, message = "Generating Diagrams")
        
        # generate plots for all entries
        plot_comp <- generate_plots(data_comp, data_sub)
        #plot_comp
        
        # generate plots for each data center
        if(length(dc_list) > 1){
          plot_dc <- list()
          for(i in 1:length(dc_list)){
            plot_dc[[length(plot_dc)+1]] <- generate_plots(data_list[[i]], data_sub, dc_list[i])
            i <- i + 1
          }
        }
        
        # additional plots
        # Plot OS
        tmp <- data_sub %>% group_by(OS) %>% summarise(Frequency_OS = n()) %>% mutate(OS = fct_reorder(OS, Frequency_OS, .desc = TRUE))
        plot_OS <- ggplot(tmp, aes(x=OS, y=Frequency_OS)) + geom_bar(stat="identity", width=.7, fill="steelblue")  + xlab("") + ylab("Count [ - ]")
        plot_OS <- designPlot(plot_OS)
        plot_OS <- plot_OS + theme(axis.text.x = element_text(size=12, angle=270, hjust=0.6, vjust=0.0), axis.ticks.x=element_blank())
        #plot_OS
        
        # Plot Host
        tmp <- data_sub %>% group_by(Host) %>% summarise(Frequency_Host = n())
        mode <- mean(tmp$Frequency_Host)
        plot_Host <- ggplot(tmp, aes(x=Host, y=Frequency_Host)) + geom_bar(stat="identity", width=.7, fill="steelblue")  + xlab("") + ylab("Count [ - ]") + geom_hline(yintercept = mode, col = "darkorange", linewidth=1.2, linetype = "dashed", show.legend = TRUE) + annotate("text", x = 1, y = mode, label = "Average", vjust = -0.3, col = "darkorange", size = 5)
        plot_Host <- designPlot(plot_Host)
        plot_Host <- plot_Host + theme(axis.text.x = element_text(size=12, angle=270, hjust=1, vjust=0.0), axis.ticks.x=element_blank())
        
        # if host information exist, perform descript. statistics
        if(is.null(overview_host)==FALSE){
          host_sub <- overview_host[, c("Host", "Datacenter", "CPU.Model", "X..VMs", "X..CPU", "Cores.per.CPU", "X..Cores", "X..Memory", "X..vCPUs", "ESX.Version")]
          
          colnames(host_sub) <- c("Host", "Datacenter", "CPU_Model", "n_VMs", "n_CPU", "Cores_per_CPU", "n_Cores", "Memory", "n_vCPU", "ESX_Version")
          host_sub <- na.omit(host_sub)
          host_sub <- host_sub %>%
            mutate(Memory = round(Memory /1000, 1)) %>%
            arrange(Datacenter)
          
          host_summary <- host_sub %>%
            summarise(Host_count = round(n_distinct(Host), 0), Memory_count = round(sum(Memory), 1), CPU_count = round(sum(n_CPU), 0), Core_count = round(sum(n_Cores),0), vCPU_count = round(sum(n_vCPU), 0), vCPU_to_Core = round(vCPU_count/Core_count, 1))  
          colnames(host_summary) <- c("# of Hosts", "overall Memory [GB]", "# of Sockets", "# of Cores", "# of vCPUs", "vCPU to Core ratio")
          host_summary <- as.data.frame(t(host_summary))
          host_summary <- rownames_to_column(host_summary)
          colnames(host_summary) <- c("Description", "Value")
          
          host_sub <- host_sub[, c("Host", "Datacenter", "CPU_Model", "Memory", "n_CPU", "n_vCPU")]
          colnames(host_sub) <- c("Host", "Datacenter", "CPU Model", "Memory [GB]", "# Sockets", "# vCPUs")
        }
        #plot_Host
        
        # Network Plot: VM's per Datacenter
        # Collect just Datacenter–VM, removing any duplicates:
        net_dc <- unique(data_sub$Datacenter)
        network_label <- as.vector(net_dc)
        
        tmp <- unique(data_sub[, c("Datacenter", "VM")])  # drop duplicate edges
        tmp.g <- graph_from_data_frame(d = tmp, directed = FALSE)
        
        # Merge parallel edges and remove self-loops (if any)
        tmp.g <- simplify(tmp.g, remove.multiple = TRUE, remove.loops = TRUE)
        plot_network_VM <- ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
        #plot_network_VM
        
        # Network Plot: VM's per Host
        net_host <- unique(data_sub$Host)
        network_label <- as.vector(net_host)
        
        # Remove duplicates so there's only one Host–VM edge per pair
        tmp <- unique(data_sub[, c("Host", "VM")])
        tmp.g <- graph_from_data_frame(d = tmp, directed = FALSE)
        
        # Merge parallel edges, remove self-loops (if any)
        tmp.g <- simplify(tmp.g, remove.multiple = TRUE, remove.loops = TRUE)
        plot_network_Host <- ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
        #plot_network_Host
        
        # Network Plot: VM's per Network
        net_network <- unique(data_sub$Network_1)
        network_label <- as.vector(net_network)
        
        # Remove duplicates so there's only one Network_1–VM edge per pair
        tmp <- unique(data_sub[, c("Network_1", "VM")])
        tmp.g <- graph_from_data_frame(d = tmp, directed = FALSE)
        
        # Merge parallel edges, remove self-loops (if any)
        tmp.g <- simplify(tmp.g, remove.multiple = TRUE, remove.loops = TRUE)
        
        plot_network_Network <- ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
        #plot_network_Network
        
        
        # progress
        setProgress(0.8, message = "Generating Slides")
        
        cat("Starting to generate the PDF report...\n")
        file_name <- get_rep_name(temp_dir)
        # Log the folder name to the console
        cat("File name:", file_name, "\n")

        cat("PDF will be saved as:", file_name[2], "\n")
        # Debugging: Check for write permissions
        write_test <- file.access(dirname(file_name[2]), mode = 2)
        if (write_test == 0) {
          cat("Write permission confirmed for directory:", dirname(file_name[2]), "\n")
        } else {
          cat("No write permission for directory:", dirname(file_name[2]), "\n")
        }
        
        # generate report
        # this is the part that build presentation.
        pdf(file = file_name[2], width = 16, height = 9)
        
        # first slide title, author and date
        slideFirst(titleName =ifelse(input$title_rv =="Report Title","RV_Tools Summary",as.character(input$title_rv)),
                   authorName = ifelse(input$author_rv =="Author of the Report","Name",as.character(input$author_rv)),
                   documDate = Sys.Date())
        
        
        #main part
        slideText("Find herein a summary of the provided RV_Tools.  
                  The following profiles were considered:  
                  Large:     VM's with 6 vCPU or more  
                  Medium: VM's with less than 6 vCPU and more than 2 vCPU  
                  Small:     VM's with 2 vCPU or less.",
                  "Introduction")
        
        # Tables
        if(length(dc_list) > 1){
          generate_overview_slide(data_overview)
        }
        
        generate_slides(data_comp, plot_comp, top_VM_comp)
        
        if(length(dc_list) > 1){
          for(i in 1:length(dc_list)){
            generate_slides(data_list[[i]], plot_dc[[i]], top_VM_list[[i]], dc_list[i])
            i <- i + 1
          }
        }
        
        slideChapter("Host and OS overview")
        
        slidePlot(plot_Host, "Number of VM's for each Host")
        
        slidePlot(plot_OS, "Overview of Operating Systems")
        
        # if host information exist, plot dataframes
        if(is.null(overview_host)==FALSE){
          i <- 0
          j <- ceiling(nrow(host_sub)/6)
          
          while(i < j){
            i <- i+1
            if(i == 1){
              if(j == 1){
                b <- nrow(host_sub)
                slideTable(host_sub[1:b,], "Host overview")
              }else {
                slideTable(host_sub[1:6, ], "Host overview")
              }
            }else if((i > 1) && (i < j)){
              a <- (i-1)*6+1
              b <- ((i-1)*6)+6
              slideTable(host_sub[a:b,], "Host overview" )
            }else if((i > 1) && (i == j)){
              a <- (i-1)*6+1
              b <- nrow(host_sub)
              slideTable(host_sub[a:b,], "Host overview")
            }
          }
          slideTable(host_summary, "Details")
        }
        
        ### begin: waiting on igraph issue to be fixed ###
        slideChapter("Cluster diagrams")
        
        slidePlot(plot_network_VM, "Cluster: VM's per Datacenter")
        
        slidePlot(plot_network_Host, "Cluster: VM's per Host")
        
        slidePlot(plot_network_Network, "Cluster: VM's per Network")
        
        # final slide
        slideLast()
        
        dev.off()

        # Clean up old files
        old_files <- list.files(temp_dir, full.names = TRUE)
        file_info <- file.info(old_files)
        unlink(old_files[file_info$mtime < (Sys.time() - 3600)])

      # Change permissions to 644
      system(paste("chmod 644", shQuote(file_name[2])))

      # Debugging: Check if the file exists and permissions
      if (file.exists(file_name[2])) {
        cat("PDF successfully written to disk at:", file_name[2], "\n")
        file_info <- file.info(file_name[2])
        cat("File permissions:", file_info$mode, "\n")
        cat("File owner:", file_info$uname, "\n")
      } else {
        cat("Failed to write PDF to disk at:", file_name[2], "\n")
      }

      }) #progress
      
      output$pdfview_rv <- renderUI({
        tags$iframe(style = "height:610px; width:100%; scrolling=yes",
                    src = paste0("tmp/", file_name[1]))
      })
      shinyjs::hide("progress_bar_rv")
      shinyjs::show("pdfview_rv")
    }) #progress
  })

}