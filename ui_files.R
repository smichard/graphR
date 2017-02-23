fluidPage(theme = "bootstrapSpacelab.css",
          
          # Application title.
          titlePanel("project.Name"),
          shinyjs::useShinyjs(),
          
          sidebarLayout(
            sidebarPanel(
              
              textInput("title", "Title", "Report Title"),
              
              textInput("author", "Author", "Author of the Report"),
              
              fileInput("file", "File input", accept=c('.xlsx', '.xls')),
              
              actionButton("Generate","Generate Report")
            ),
            
            # Show a summary of the dataset and an HTML table with the
            # requested number of observations. Note the use of the h4
            # function to provide an additional header above each output
            # section.
            mainPanel(
              
              tabsetPanel(
                # using iframe along with tags() within tab to display pdf with scroll, height and width could be adjusted
                tabPanel("Report", 
                         uiOutput("pdfview")),
                tabPanel("Instructions", includeMarkdown("instructions.md"))
              )
            )
          )
)