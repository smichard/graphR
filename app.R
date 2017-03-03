## app.R ##
source("libraries.R")
source("server_rv.R")
source("server_sfdc.R")


ui <- dashboardPage(
  dashboardHeader(title = "graphR."),
  dashboardSidebar(
    sidebarMenu(
      menuItem("RV Tools", tabName = "tab_rv", icon = icon("th-list")),
      menuItem("SFDC", tabName = "tab_sfdc", icon = icon("cloud"))
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
                            
                            fileInput("file_rv", "File input", accept=c('.xlsx', '.xls')),
                            
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
                            )
                          )
                        )
              )
              
      ),
      
      # Second tab content
      tabItem(tabName = "tab_sfdc",
              fluidPage(
                        # Application title.
                        titlePanel("SFDC"),
                        shinyjs::useShinyjs(),
                        
                        sidebarLayout(
                          sidebarPanel(
                            
                            textInput("title_sfdc", "Title", "Report Title"),
                            
                            textInput("author_sfdc", "Author", "Author of the Report"),
                            
                            textAreaInput("comments_sfdc", "Comments", "Comments", rows = 6),
                            
                            checkboxInput("tableCondition_sfdc", "Show Tables" , value = TRUE, width = NULL),
                            
                            sliderInput("kvalue_sfdc", "# table entries for each slide", 
                                        min = 2, max = 12, value = 4),
                            
                            fileInput("file_sfdc", "File input", accept=c('.xlsx', '.xls')),
                            
                            #helpText("Note: bladi bladi bla"),
                            
                            actionButton("Generate_sfdc","Generate Report")
                          ),
                          
                          # Show a summary of the dataset and an HTML table with the
                          # requested number of observations. Note the use of the h4
                          # function to provide an additional header above each output
                          # section.
                          mainPanel(
                            
                            tabsetPanel(
                              # using iframe along with tags() within tab to display pdf with scroll, height and width could be adjusted
                              tabPanel("Report", 
                                       uiOutput("pdfview_sfdc")),
                              tabPanel("Instructions", includeMarkdown("instructions_sfdc.md"))
                            )
                          )
                        )
              )
      )
    )
  )
)
server <- function(input, output) {
  server_rv(input, output)
  server_sfdc(input, output)
}

shinyApp(ui, server)