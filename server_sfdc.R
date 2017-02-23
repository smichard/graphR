server_sfdc <- function(input, output) {
  observe({
    shinyjs::disable(id = "Generate_sfdc")
    shinyjs::toggleState(id = "Generate_sfdc",condition = !is.null(input$file_sfdc))
    
  })
  

  observeEvent(input$Generate_sfdc, {
    #browser()
    print("######################")
    print(input$author_sfdc)
    print(Sys.Date())
    print("######################")
    file2<- input$file_sfdc
    data_sfdc <- read.xlsx(file2$datapath, sheetIndex=1, startRow=1, as.data.frame=TRUE, header=TRUE, keepFormulas=FALSE)
    data_sfdc <- data_sfdc[1:(nrow(data_sfdc)-5),]
    colnames(data_sfdc) <- c("Opportunity_Name", "Account_Name", "Forecast_Currency", "Forecast_Amount", "Forecast_Currency_USD", "Forecast_Amount_USD", "Forecast_Status", "Close_Date", "Account_Owner", "Primary_SE", "Solution_Win", "Solution_Win_Comments", "Service_Comments", "Manager_Comments", "PreSales_Speciality", "Speciality_Engagement", "Products", "Won", "Closed")
    data_sfdc$Products <- sub(";.*", "", data_sfdc$Products)
    data_sfdc$Forecast_Amount_USD <- round(data_sfdc$Forecast_Amount_USD, 0)
    
    
    # create subsets, commit, closed, booked, upside
    data.commit <- subset(data_sfdc, Forecast_Status == "Commit")
    data.upside <- subset(data_sfdc, Forecast_Status == "Upside")
    data.closed <- subset(data_sfdc, Forecast_Status == "Closed")
    data.booked <- subset(data_sfdc, Forecast_Status == "Booked")
    data.won <- subset(data_sfdc, Forecast_Status == "Won")
    data.lost <- subset(data_sfdc, Forecast_Status == "Lost")
    
    
    # order data frames
    data.commit <- orderDataframe(data.commit)
    data.upside <- orderDataframe(data.upside)
    data.closed <- orderDataframe(data.closed)
    data.booked <- orderDataframe(data.booked)
    data.won <- orderDataframe(data.won)
    data.lost <- orderDataframe(data.lost)
    
    
    # calculate Amount for each Forecast Status
    # summary.forecastStatus <- ddply(data, "Forecast_Status", summarize, Forecast_Amount_USD = sum(Forecast_Amount_USD))
    summary.forecastStatus <- data_sfdc %>% group_by(Forecast_Status) %>% summarise(Forecast_Amount_USD = sum(Forecast_Amount_USD))
    summary.forecastStatus$Forecast_Status <- factor(fct_relevel(summary.forecastStatus$Forecast_Status, "Commit", "Upside", "Won", "Lost", "Closed", "Booked"))
    
    # Plot Forecast Amount for each Forecast Status
    forecast.plot <- ggplot(data=summary.forecastStatus, aes(x=Forecast_Status, y=Forecast_Amount_USD, fill=Forecast_Status)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Forecast Status") + ylab("Value in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Forecast_Amount_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    forecast.plot <- designPlot(forecast.plot)
    #forecast.plot
    
    # calculate Frequency for each Forecast Status
    #summary.frequencyStatus <- ddply(data, "Forecast_Status", summarize, Frequency_Status = length(Forecast_Status))
    summary.frequencyStatus <- data_sfdc %>% group_by(Forecast_Status) %>% summarise(Frequency_Status = length(Forecast_Status))
    summary.frequencyStatus$Forecast_Status <- factor(fct_relevel(summary.frequencyStatus$Forecast_Status, "Commit", "Upside", "Won", "Lost", "Closed", "Booked"))
    
    # Plot Frequency for each Forecast Status
    frequencyStatus.plot <- ggplot(data=summary.frequencyStatus, aes(x=Forecast_Status, y=Frequency_Status, fill=Forecast_Status)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Forecast Status") + ylab("Number of Projects") + geom_text(aes(label=Frequency_Status), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    frequencyStatus.plot <- designPlot(frequencyStatus.plot)
    #frequencyStatus.plot
    
    
    # calculate Frequency for each Primary SE
    #summary.frequencySE <- ddply(data, "Primary_SE", summarize, Frequency_SE = length(Primary_SE))
    summary.frequencySE <- data_sfdc %>% group_by(Primary_SE) %>% summarise(Frequency_SE = length(Primary_SE))
    
    
    # Plot Frequency for each Account Manager
    frequencySE.plot <- ggplot(data=summary.frequencySE, aes(x=Primary_SE, y=Frequency_SE, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Number of Projects") + geom_text(aes(label=Frequency_SE), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    frequencySE.plot <- designPlot(frequencySE.plot)
    #frequencySE.plot
    
    # calculate Frequency for each Account Manager
    # if Statement to distinguish how many Primary SE are contained in dataset
    if(nrow(summary.frequencySE) == 1){
      #summary.frequencyAM <- ddply(data, "Account_Owner", summarize, Frequency_AM = length(Account_Owner))
      summary.frequencyAM <- data_sfdc %>% group_by(Account_Owner) %>% summarise(Frequency_AM = length(Account_Owner))
      frequencyAM.plot <- ggplot(data=summary.frequencyAM, aes(x=Account_Owner, y=Frequency_AM, fill=Account_Owner)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Account Manager") + ylab("Number of Projects") + geom_text(aes(label=Frequency_AM), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    }else if(nrow(summary.frequencySE) > 1){
      #summary.frequencyAM <- ddply(data, c("Account_Owner", "Primary_SE"), summarise, Frequency_AM=length(result=="Account_Owner"))
      #summary.frequencyAM <- count(data, c('Account_Owner', 'Primary_SE'))
      summary.frequencyAM <- data_sfdc %>% group_by(Account_Owner, Primary_SE) %>% summarise(Frequency_AM=n())
      
      colnames(summary.frequencyAM) <- c('Account_Owner', 'Primary_SE', 'Frequency_AM')
      frequencyAM.plot <- ggplot(data=summary.frequencyAM, aes(x=Account_Owner, y=Frequency_AM, fill=Primary_SE)) +
        geom_bar(stat="identity", position=position_dodge(), width=.7) + xlab("Account Manager") + ylab("Number of Projects") + scale_fill_discrete(name="Primary SE")
    }
    frequencyAM.plot <- designPlot(frequencyAM.plot)
    #frequencyAM.plot
    
    
    # calculate Revenue for each Primary SE, booked projects
    # summary.revenueSE <- ddply(data.booked, "Primary_SE", summarize, Revenue_SE_USD = sum(Forecast_Amount_USD))
    summary.revenueSE <- data.booked %>% group_by(Primary_SE) %>% summarise(Revenue_SE_USD = sum(Forecast_Amount_USD))
    
    # Plot Frequency for each Account Manager
    revenueSE.plot <- ggplot(data=summary.revenueSE, aes(x=Primary_SE, y=Revenue_SE_USD, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Revenue of booked Projects in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Revenue_SE_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    revenueSE.plot <- designPlot(revenueSE.plot)
    #revenueSE.plot
    
    # calculate Revenue for each Primary SE, closed projects
    #summary.revenueSE2 <- ddply(data.closed, "Primary_SE", summarize, Revenue_SE_USD = sum(Forecast_Amount_USD))
    summary.revenueSE2 <- data.closed %>% group_by(Primary_SE) %>% summarise(Revenue_SE_USD = sum(Forecast_Amount_USD))
    
    
    # Plot Frequency for each Account Manager
    revenueSE2.plot <- ggplot(data=summary.revenueSE2, aes(x=Primary_SE, y=Revenue_SE_USD, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Revenue of closed Projects in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Revenue_SE_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    revenueSE2.plot <- designPlot(revenueSE2.plot)
    #revenueSE2.plot
    
    # calculate Revenue for each Primary SE, won projects
    #summary.revenueSE3 <- ddply(data.won, "Primary_SE", summarize, Revenue_SE_USD = sum(Forecast_Amount_USD))
    summary.revenueSE3 <- data.won %>% group_by(Primary_SE) %>% summarise(Revenue_SE_USD = sum(Forecast_Amount_USD))
    
    # Plot Frequency for each Account Manager
    revenueSE3.plot <- ggplot(data=summary.revenueSE3, aes(x=Primary_SE, y=Revenue_SE_USD, fill=Primary_SE)) + scale_fill_brewer(palette = "Set2") + geom_bar(stat="identity", width=.7)  + xlab("Primary SE") + ylab("Revenue of Won Projects in USD") + scale_y_continuous(labels = scales::format_format(big.mark = ".", decimal.mark = ",", scientific = FALSE)) + geom_text(aes(label=Revenue_SE_USD), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE)
    revenueSE3.plot <- designPlot(revenueSE3.plot)
    #revenueSE3.plot
    
    # calculating solution win comments, number of projects commit/upside, number of projects without evalutation, number of evaluted projects
    data.commit.win <- subset(data.commit, Forecast_Amount_USD > 249000)
    data.upside.win <- subset(data.upside, Forecast_Amount_USD > 249000)
    win.projects <- nrow(data.commit.win) + nrow(data.upside.win)
    win.missing <- sum(is.na(data.commit.win$Solution_Win_Comments)) + sum(is.na(data.upside.win$Solution_Win_Comments))
    win.evalutated <- win.projects - win.missing
    
    summary.solutionWin <- data.frame(
      group = c("Evaluated Projects","Missing Evaluation"),
      if(win.projects == 0){
        value = c(1, 0)
      }else{
        value = c(win.evalutated, win.missing)
      }
    )
    
    # Plotting Solution Win Comments
    solutionWin.plot <- ggplot(summary.solutionWin, aes(x="", y=value, fill=group)) +
      geom_bar(width = 1, stat = "identity") + coord_polar("y", start=pi/5) +
      scale_fill_manual(values=c("#009E73", "#D55E00")) + theme_void() +
      theme(legend.title=element_blank(), legend.position="bottom", legend.text = element_text(size = 16))
    #geom_text(aes(label=value), vjust=-0.7, color="white", size=6.5, fontface="bold")
    
    # calculate product mix
    #summary.productMix <- ddply(data, "Products", summarize, Product_Counts = length(Products))
    summary.productMix <- data_sfdc %>% group_by(Products) %>% summarise(Product_Counts = length(Products))
    summary.productMix$Products <- factor(summary.productMix$Products, levels = summary.productMix$Products[order(summary.productMix$Product_Counts)])
    
    # Plot Product Mix
    productMix.plot <- ggplot(data=summary.productMix, aes(x=Products, y=Product_Counts)) + geom_bar(stat="identity", width=.7, fill="steelblue")  + xlab("Products") + ylab("Number of Projects") + geom_text(aes(label=Products), vjust=0, hjust=-0.2, colour="black", angle="270")
    productMix.plot <- designPlot(productMix.plot)
    productMix.plot <- productMix.plot + theme(axis.text.x=element_blank(), axis.ticks.x=element_blank())
    #productMix.plot
    
    # set proper format
    data.commit <- formatDataframe(data.commit)
    data.upside <- formatDataframe(data.upside)
    data.closed <- formatDataframe(data.closed)
    data.booked <- formatDataframe(data.booked)
    data.won <- formatDataframe(data.won)
    data.lost <- formatDataframe(data.lost)
    
    # rename dataframe header
    data.commit <- adjustHeader(data.commit)
    data.upside <- adjustHeader(data.upside)
    data.closed <- adjustHeader(data.closed)
    data.booked <- adjustHeader(data.booked)
    data.won <- adjustHeader(data.won)
    data.lost <- adjustHeader(data.lost)
    
    
    # generate report
    
    
    # this is the part that build presentation.
    pdf(file = "www/report_sfdc.pdf", width = 16, height = 9)
    
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
      
      slideDataframe(data.commit, m=k, title="Current Projects with Status commit")
      
      slideDataframe(data.upside, m=k, title="Current Projects with Status upside")
      
      slideDataframe(data.closed, m=k, title="Closed Projects")
      
      slideDataframe(data.booked, m=k, title="Booked Projects")
      
      slideDataframe(data.won, m=k, title="Project Wins")
      
      slideDataframe(data.lost, m=k, title="Lost Projects")
      
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
    
    output$pdfview_sfdc <- renderUI({
      tags$iframe(style="height:610px; width:100%; scrolling=yes", 
                  src="report_sfdc.pdf")
    })
    
    
  })
  
}