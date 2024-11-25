# Base R Shiny image
FROM rocker/shiny:4.4.2

# Install R dependencies
RUN R -e "install.packages(c('ape', 'broom', 'compiler', 'digest', 'dplyr', 'flexdashboard', 'forcats', 'GGally', 'ggplot2', 'graph', 'igraphdata', 'igraph', 'intergraph', 'irlba', 'maps', 'magrittr', 'markdown', 'network', 'NMF', 'pkgconfig', 'png', 'RColorBrewer', 'readxl', 'reshape2', 'rgl', 'rmarkdown', 'scales', 'shinydashboard', 'shinyjs', 'sna', 'statnet.common', 'stats4', 'tcltk', 'testthat', 'tibble'), repos='https://cran.rstudio.com/')"

# Remove the default Shiny example apps
RUN rm -rf /srv/shiny-server/*

# Copy the Shiny app code
COPY graphr/ /srv/shiny-server/

# Create necessary directories and set permissions
RUN chown -R shiny:shiny /srv/shiny-server/

# Switch to the shiny user
USER shiny

# Expose the application port
EXPOSE 3838

# Run the R Shiny app
CMD ["/usr/bin/shiny-server"]