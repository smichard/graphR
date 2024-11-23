# Base R Shiny image
FROM rocker/shiny:4.4.2

# Make a directory in the container
RUN mkdir /home/shiny-app

WORKDIR /home/shiny-app

# Install R dependencies
RUN R -e "install.packages(c('ape', 'broom', 'compiler', 'digest', 'dplyr', 'flexdashboard', 'forcats', 'GGally', 'ggplot2', 'graph', 'igraphdata', 'igraph', 'intergraph', 'irlba', 'maps', 'magrittr', 'markdown', 'network', 'NMF', 'pkgconfig', 'png', 'RColorBrewer', 'readxl', 'reshape2', 'rgl', 'rmarkdown', 'scales', 'shinydashboard', 'shinyjs', 'sna', 'statnet.common', 'stats4', 'tcltk', 'testthat', 'tibble'), repos='https://cran.rstudio.com/')"

# Copy the Shiny app code
COPY graphr/ /home/shiny-app/
RUN chmod -R 777 /home/shiny-app/www

# Expose the application port
EXPOSE 3838

# Run the R Shiny app
CMD ["Rscript", "/home/shiny-app/app.R"]