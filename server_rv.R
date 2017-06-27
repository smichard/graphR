server_rv <- function(input, output) {
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
    file1<- input$file_rv
    #data <- read.xlsx(file1$datapath, sheetIndex=1, startRow=1, as.data.frame=TRUE, header=TRUE, keepFormulas=FALSE)
    # using readxl package for xls import
    ext <- tools::file_ext(file1$name)
    file.rename(file1$datapath, paste(file1$datapath, ext, sep = "."))
    data <- data.frame(read_excel(paste(file1$datapath, ext, sep="."), sheet=1, col_names=TRUE))
    # check for OS column
    if("OS.according.to.the.configuration.file" %in% colnames(data)){
      data_sub <- data[, c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MB", "In.Use.MB", "Datacenter", "OS.according.to.the.configuration.file", "Host", "Network..1")]
    } else{
      data_sub <- data[, c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MB", "In.Use.MB", "Datacenter", "OS", "Host", "Network..1")]
    }
    colnames(data_sub) <- c("VM", "Powerstate", "CPU", "Memory", "Provisioned_MB", "In_Use_MB", "Datacenter", "OS", "Host", "Network_1")
    data_sub <- na.omit(data_sub)
    
    # progress
    setProgress(0.3, message = "Performing Calculations")    
    
    # get stats for all entries in file
    data_comp <- get_stats(data_sub)
    
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
    plot_Host <- ggplot(tmp, aes(x=Host, y=Frequency_Host)) + geom_bar(stat="identity", width=.7, fill="steelblue")  + xlab("") + ylab("Count [ - ]") + geom_hline(yintercept = mode, col = "darkorange", size=1.2, linetype = "dashed", show.legend = TRUE) + geom_text(aes(3,mode,label = "Average", vjust = -0.3), col = "darkorange", size = 5)
    plot_Host <- designPlot(plot_Host)
    plot_Host <- plot_Host + theme(axis.text.x = element_text(size=12, angle=270, hjust=1, vjust=0.0), axis.ticks.x=element_blank())
    #plot_Host
    
    # Network Plot: VM's per Datacenter
    ## get new vertices and label
    net_dc <- unique(data_sub$Datacenter)
    new_vertices <- get_vertices(net_dc)
    network_label <- as.vector(net_dc)
    ## plot graph
    tmp <- data_sub[, c("Datacenter", "VM")]
    tmp.g <- graph.data.frame(d = tmp, directed = FALSE)
    tmp.g <- add_vertices(tmp.g, length(net_dc), attr=new_vertices)
    plot_network_VM <- ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
    #plot_network_VM
    
    # Network Plot: VM's per Host
    ## get new vertices and label
    net_host <- unique(data_sub$Host)
    new_vertices <- get_vertices(net_host)
    network_label <- as.vector(net_host)
    ## plot graph
    tmp <- data_sub[, c("Host", "VM")]
    tmp.g <- graph.data.frame(d = tmp, directed = FALSE)
    tmp.g <- add_vertices(tmp.g, length(net_host), attr=new_vertices)
    plot_network_Host <- ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
    #plot_network_Host
    
    # Network Plot: VM's per Network
    ## get new vertices and label
    net_network <- unique(data_sub$Network_1)
    new_vertices <- get_vertices(net_network)
    network_label <- as.vector(net_network)
    ## plot graph
    tmp <- data_sub[, c("Network_1", "VM")]
    tmp.g <- graph.data.frame(d = tmp, directed = FALSE)
    tmp.g <- add_vertices(tmp.g, length(net_network), attr=new_vertices)
    plot_network_Network <- ggnet2(tmp.g, color = "steelblue", alpha = 0.75, size = 5, edge.alpha = 0.5, edge.color = "grey", label.size = 4, label.alpha = 1, label.color = "black", label = network_label)
    #plot_network_Network

    # progress
    setProgress(0.8, message = "Generating Slides")
    
    file_name <- get_rep_name()
    
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
              "Introduction", pathImg = "./backgrounds/main_slide.PNG")
    
    # Tables
    if(length(dc_list) > 1){
      generate_overview_slide(data_overview)
    }
    generate_slides(data_comp, plot_comp)
    
    if(length(dc_list) > 1){
      for(i in 1:length(dc_list)){
        generate_slides(data_list[[i]], plot_dc[[i]], dc_list[i])
        i <- i + 1
      }
    }
    
    slideChapter("Host and OS overview")
    
    slidePlot(plot_Host, "Number of VM's for each Host")
    
    slidePlot(plot_OS, "Overview of Operating Systems")
    
    slideChapter("Cluster diagrams")
    
    slidePlot(plot_network_VM, "Cluster: VM's per Datacenter")
    
    slidePlot(plot_network_Host, "Cluster: VM's per Host")
    
    slidePlot(plot_network_Network, "Cluster: VM's per Network")
    
    # final slide
    slideLast()
    
    dev.off()
    
      }) #progress
    
    output$pdfview_rv <- renderUI({
      tags$iframe(style="height:610px; width:100%; scrolling=yes", 
                  src=file_name[1])
    })
    shinyjs::hide("progress_bar_rv")
    shinyjs::show("pdfview_rv")
    }) #progress
  })
}