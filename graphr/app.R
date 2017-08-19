## app.R ##
source("libraries.R")
source("server_rv.R")


ui <- dashboardPage(
  dashboardHeader(title = "graphR."),
  dashboardSidebar(
    sidebarMenu(
      menuItem("RV Tools", tabName = "tab_rv", icon = icon("th-list"))
    )
  ),
  ## Body content
  dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "tab_rv",
              fluidPage(theme = "custom.css",
                        # Application title.
                        titlePanel("RV Tools"),
                        shinyjs::useShinyjs(),
                        
                        sidebarLayout(
                          sidebarPanel(
                            
                            textInput("title_rv", "Title", "Report Title"),
                            
                            textInput("author_rv", "Author", "Author of the Report"),
                            
                            fileInput("file_rv", "File input", accept=c('.xlsx', '.xls', '.csv')),
                            
                            actionButton("Generate_rv","Generate Report")
                          ),
                          
                          # Show a summary of the dataset and an HTML table with the
                          # requested number of observations. Note the use of the h4
                          # function to provide an additional header above each output
                          # section.
                          mainPanel(
                            
                            tabsetPanel(
                              # using iframe along with tags() within tab to display pdf with scroll, height and width could be adjusted
                              tabPanel("Report", 
                                       uiOutput("pdfview_rv")),
                              tabPanel("Instructions", includeMarkdown("instructions_rv.md"))
                            ),
                            plotOutput("progress_bar_rv", height = 1,width = 1)
                          )
                        )
              )
              
      )
    )
  )
)
server <- function(input, output) {
  server_rv(input, output)
}

shinyApp(ui, server)