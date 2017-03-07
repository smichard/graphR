server_sfdc <- function(input, output) {
  observe({
    shinyjs::disable(id = "Generate_sfdc")
    shinyjs::toggleState(id = "Generate_sfdc",condition = !is.null(input$file_sfdc))
    
  })
  

  observeEvent(input$Generate_sfdc, {
    #browser()
    
    #progress
    shinyjs::show("progress_bar_sfdc")
    output$progress_bar_sfdc <- renderPlot({
      withProgress(message = 'Generating Report', value = 0, {
        
    # progress
    setProgress(0.1, message = "Importing Data")
    
    file2<- input$file_sfdc
    data_sfdc <- read.xlsx(file2$datapath, sheetIndex=1, startRow=1, as.data.frame=TRUE, header=TRUE, keepFormulas=FALSE)
    data_sfdc <- data_sfdc[1:(nrow(data_sfdc)-5),]
    colnames(data_sfdc) <- c("Opportunity_Name", "Account_Name", "Forecast_Currency", "Forecast_Amount", "Forecast_Currency_USD", "Forecast_Amount_USD", "Forecast_Status", "Close_Date", "Account_Owner", "Primary_SE", "Solution_Win", "Solution_Win_Comments", "Service_Comments", "Manager_Comments", "PreSales_Speciality", "Speciality_Engagement", "Products", "Won", "Closed")
    data_sfdc$Products <- sub(";.*", "", data_sfdc$Products)
    data_sfdc$Forecast_Amount_USD <- round(data_sfdc$Forecast_Amount_USD, 0)
    
    # progress
    setProgress(0.3, message = "Performing Calculations")
    
    # create subsets, commit, closed, booked, upside, Won, Lost
    fcs_list <- unique(data_sfdc$Forecast_Status)
    data_status_list <- list()
    for(i in 1:length(fcs_list)){
      df <- data_sfdc %>%
        filter(Forecast_Status == fcs_list[i]) %>%
        arrange(desc(Forecast_Amount_USD))
      data_status_list[[length(data_status_list)+1]] <- df
      names(data_status_list)[i] <- as.character(fcs_list[i])
      i <- i + 1
    }
    
    # progress
    setProgress(0.6, message = "Generating Diagrams")
    
    # calculate Amount for each Forecast Status
    summary.forecastStatus <- data_sfdc %>% group_by(Forecast_Status) %>%  summarise(Forecast_Amount_USD = sum(Forecast_Amount_USD))
    summary.forecastStatus$Forecast_Status <- factor(fct_relevel(summary.forecastStatus$Forecast_Status, "Commit", "Upside", "Won", "Lost", "Closed", "Booked"))
    
    # Plot Forecast Amount for each Forecast Status
    forecast.plot <- ggplot(data=summary.forecastStatus, aes(x=Forecast_Status, y=Forecast_Amount_USD, fill=Forecast_Status)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Forecast Status") + ylab("Value in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Forecast_Amount_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    forecast.plot <- designPlot(forecast.plot)
    #forecast.plot
    
    # calculate Frequency for each Forecast Status
    summary.frequencyStatus <- data_sfdc %>% group_by(Forecast_Status) %>% summarise(Frequency_Status = length(Forecast_Status))
    summary.frequencyStatus$Forecast_Status <- factor(fct_relevel(summary.frequencyStatus$Forecast_Status, "Commit", "Upside", "Won", "Lost", "Closed", "Booked"))
    
    # Plot Frequency for each Forecast Status
    frequencyStatus.plot <- ggplot(data=summary.frequencyStatus, aes(x=Forecast_Status, y=Frequency_Status, fill=Forecast_Status)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Forecast Status") + ylab("Number of Projects") + geom_text(aes(label=Frequency_Status), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    frequencyStatus.plot <- designPlot(frequencyStatus.plot)
    #frequencyStatus.plot
    
    
    # calculate Frequency for each Primary SE
    summary.frequencySE <- data_sfdc %>% group_by(Primary_SE) %>% summarise(Frequency_SE = length(Primary_SE))
    
    # Plot Frequency for each Primary SE
    frequencySE.plot <- ggplot(data=summary.frequencySE, aes(x=Primary_SE, y=Frequency_SE, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Number of Projects") + geom_text(aes(label=Frequency_SE), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    frequencySE.plot <- designPlot(frequencySE.plot)
    #frequencySE.plot
    
    # calculate Frequency for each Account Manager
    # if Statement to distinguish how many Primary SE are contained in dataset
    if(nrow(summary.frequencySE) == 1){
      summary.frequencyAM <- data_sfdc %>% group_by(Account_Owner) %>% summarise(Frequency_AM = length(Account_Owner))
      frequencyAM.plot <- ggplot(data=summary.frequencyAM, aes(x=Account_Owner, y=Frequency_AM, fill=Account_Owner)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Account Manager") + ylab("Number of Projects") + geom_text(aes(label=Frequency_AM), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    }else if(nrow(summary.frequencySE) > 1){
      summary.frequencyAM <- data_sfdc %>% group_by(Account_Owner, Primary_SE) %>% summarise(Frequency_AM=n())
      colnames(summary.frequencyAM) <- c('Account_Owner', 'Primary_SE', 'Frequency_AM')
      frequencyAM.plot <- ggplot(data=summary.frequencyAM, aes(x=Account_Owner, y=Frequency_AM, fill=Primary_SE)) +
        geom_bar(stat="identity", position=position_dodge(), width=.7) + xlab("Account Manager") + ylab("Number of Projects") + scale_fill_discrete(name="Primary SE")
    }
    frequencyAM.plot <- designPlot(frequencyAM.plot)
    #frequencyAM.plot
    
    
    # calculate Revenue for each Primary SE, booked projects
    if(!is.null(data_status_list[["Booked"]])){
      summary.revenueSE <- data_status_list$Booked %>% group_by(Primary_SE) %>% summarise(Revenue_SE_USD = sum(Forecast_Amount_USD))
      
      # Plot Frequency for each Account Manager
      revenueSE.plot <- ggplot(data=summary.revenueSE, aes(x=Primary_SE, y=Revenue_SE_USD, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Revenue of booked Projects in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Revenue_SE_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
      revenueSE.plot <- designPlot(revenueSE.plot)
      #revenueSE.plot
    }
    
    # calculate Revenue for each Primary SE, closed projects
    #summary.revenueSE2 <- ddply(data.closed, "Primary_SE", summarize, Revenue_SE_USD = sum(Forecast_Amount_USD))
    # adjust
    if(!is.null(data_status_list[["Closed"]])){
      summary.revenueSE2 <- data_status_list$Closed %>% group_by(Primary_SE) %>% summarise(Revenue_SE_USD = sum(Forecast_Amount_USD))
      
      # Plot Frequency for each Account Manager
      revenueSE2.plot <- ggplot(data=summary.revenueSE2, aes(x=Primary_SE, y=Revenue_SE_USD, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Revenue of closed Projects in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Revenue_SE_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
      revenueSE2.plot <- designPlot(revenueSE2.plot)
      #revenueSE2.plot
    }
    
    # calculate Revenue for each Primary SE, won projects
    # adjust
    if(!is.null(data_status_list[["Won"]])){
      summary.revenueSE3 <- data_status_list$Won %>% group_by(Primary_SE) %>% summarise(Revenue_SE_USD = sum(Forecast_Amount_USD))
      
      # Plot Frequency for each Account Manager
      revenueSE3.plot <- ggplot(data=summary.revenueSE3, aes(x=Primary_SE, y=Revenue_SE_USD, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Revenue of Won Projects in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Revenue_SE_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
      revenueSE3.plot <- designPlot(revenueSE3.plot)
      #revenueSE3.plot
    }
    
    # calculating solution win comments, number of projects commit/upside, number of projects without evalutation, number of evaluted projects
    summary.solutionWin <- data_sfdc %>%
      filter(((Forecast_Status == "Commit") | (Forecast_Status == "Upside")) & Forecast_Amount_USD > 249000) %>%
      summarise(EvaluatedProjects = sum(!is.na(Solution_Win_Comments)), MissingEvaluation = sum(is.na(Solution_Win_Comments)))
    summary.solutionWin <- melt(summary.solutionWin, value.name = "value")
    
    solutionWin.plot <- ggplot(summary.solutionWin, aes(x="", y=value, fill=variable)) +
      geom_bar(width = 1, stat = "identity") + coord_polar("y", start=pi/5) +
      scale_fill_manual(values=c("#009E73", "#D55E00")) + theme_void() +
      theme(legend.title=element_blank(), legend.position="bottom", legend.text = element_text(size = 16)) 
    # geom_text(aes(label=value), vjust=-0.7, color="white", size=6.5, fontface="bold")
    #solutionWin.plot
    
    
    # calculate product mix
    #summary.productMix <- ddply(data, "Products", summarize, Product_Counts = length(Products))
    summary.productMix <- data_sfdc %>% group_by(Products) %>% summarise(Product_Counts = length(Products))
    summary.productMix$Products <- factor(summary.productMix$Products, levels = summary.productMix$Products[order(summary.productMix$Product_Counts)])
    
    # Plot Product Mix
    productMix.plot <- ggplot(data=summary.productMix, aes(x=Products, y=Product_Counts)) + geom_bar(stat="identity", width=.7, fill="steelblue")  + xlab("Products") + ylab("Number of Projects") + geom_text(aes(label=Products), vjust=0, hjust=-0.2, colour="black", angle="270")
    productMix.plot <- designPlot(productMix.plot)
    productMix.plot <- productMix.plot + theme(axis.text.x=element_blank(), axis.ticks.x=element_blank())
    #productMix.plot
    
    # set proper format, function
    data_status_list <- lapply(data_status_list, formatDataframe)
    
    # rename dataframe header
    data_status_list <- lapply(data_status_list, adjustHeader)
    
    # progress
    setProgress(0.8, message = "Generating Slides")
    
    # generate report
    file_name <- get_rep_name()
    
    # this is the part that build presentation.
    pdf(file = file_name[2], width = 16, height = 9)
    
    # first slide title, author and date
    slideFirst(titleName =ifelse(input$title_sfdc =="Report Title","Project Summary",as.character(input$title_sfdc)),
               authorName = ifelse(input$author_sfdc =="Author of the Report","Name",as.character(input$author_sfdc)),
               documDate = Sys.Date())
    
    #main part
    message =ifelse(input$comments_sfdc == "Comments","Please find attached an overview of the projects I am currently working on.  
                    You will find a summary of the number of projects, forecast amount and forecast status
                    as well as an overview of the number of projects for each account owner.",as.character(input$comments_sfdc))
    slideText(paste(strwrap(message,80),collapse = "\n"),
              "Introduction")
    
    # Tables
    
    if(input$tableCondition_sfdc == TRUE){
      
      # data Tables
      k <- ifelse(is.null(input$kvalue_sfdc),10,input$kvalue_sfdc)
      
      if(!is.null(data_status_list[["Commit"]])){
        slideDataframe(data_status_list$Commit, m=k, title="Current Projects with Status commit")}
      
      if(!is.null(data_status_list[["Upside"]])){
        slideDataframe(data_status_list$Upside, m=k, title="Current Projects with Status upside")}
      
      if(!is.null(data_status_list[["Closed"]])){
        slideDataframe(data_status_list$Closed, m=k, title="Closed Projects")}
      
      if(!is.null(data_status_list[["Booked"]])){
        slideDataframe(data_status_list$Booked, m=k, title="Booked Projects")}
      
      if(!is.null(data_status_list[["Won"]])){
        slideDataframe(data_status_list$Won, m=k, title="Project Wins")}
      
      if(!is.null(data_status_list[["Lost"]])){
        slideDataframe(data_status_list$Lost, m=k, title="Lost Projects")}
      
    }
    # Plots
    slidePlot(forecast.plot, "Forecast Amount in USD for each Forecast Status", pathImg = "./backgrounds/main_slide_internal.PNG")
    
    slidePlot(frequencyStatus.plot, "Project Count for each Forecast Status", pathImg = "./backgrounds/main_slide_internal.PNG")
    
    slidePlot(frequencyAM.plot, "Number of Projects for each Account Owner", pathImg = "./backgrounds/main_slide_internal.PNG")
    
    if( nrow(summary.frequencySE) > 1){
      
      slidePlot(frequencySE.plot, "Number of Projects for each Primary SE", pathImg = "./backgrounds/main_slide_internal.PNG")
      
      if( nrow(summary.revenueSE) != 0){
        slidePlot(revenueSE.plot, "Revenue of booked Projects for each Primary SE", pathImg = "./backgrounds/main_slide_internal.PNG")
      }
      if( nrow(summary.revenueSE2) != 0){
        slidePlot(revenueSE2.plot, "Revenue of closed Projects for each Primary SE", pathImg = "./backgrounds/main_slide_internal.PNG")
      }
      if( nrow(summary.revenueSE3) != 0){
        slidePlot(revenueSE3.plot, "Revenue of Projects Wins for each Primary SE", pathImg = "./backgrounds/main_slide_internal.PNG")
      }
    }
    
    slidePlot(solutionWin.plot, "Solution Win Comments", pathImg = "./backgrounds/main_slide_internal.PNG")
    
    slidePlot(productMix.plot, "Product Mix of all Projects", pathImg = "./backgrounds/main_slide_internal.PNG")
    
    # final slide
    slideLast()
    
    dev.off()
    
    }) #progress
    
    output$pdfview_sfdc <- renderUI({
      tags$iframe(style="height:610px; width:100%; scrolling=yes", 
                  src=file_name[1])
    })
    shinyjs::hide("progress_bar_sfdc")
    }) #progress
    
  })
  
}