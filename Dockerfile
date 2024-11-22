# Base R Shiny image
FROM rocker/shiny:4.4.2

WORKDIR /home/shiny-app

# Install R dependencies
RUN R -e "install.packages(c('ape', 'broom', 'compiler', 'digest', 'dplyr', 'flexdashboard', 'forcats', 'GGally', 'ggplot2', 'graph', 'igraphdata', 'igraph', 'intergraph', 'irlba', 'maps', 'magrittr', 'markdown', 'network', 'NMF', 'pkgconfig', 'png', 'RColorBrewer', 'readxl', 'reshape2', 'rgl', 'rmarkdown', 'scales', 'shinydashboard', 'shinyjs', 'sna', 'statnet.common', 'stats4', 'tcltk', 'testthat', 'tibble'), repos='https://cran.rstudio.com/')"

# Copy the Shiny app code
COPY graphr/ /home/shiny-app/

# Create necessary directories
RUN mkdir -p /home/shiny-app/logs /home/shiny-app/bookmarks

# Set ownership and permissions
RUN chown -R shiny:root /home/shiny-app && \
    chmod -R 775 /home/shiny-app

# Copy the Shiny configuration to a writable location
COPY shiny-server.conf /home/shiny-app/shiny-server.conf

# Copy the startup script
COPY run.sh /usr/bin/run.sh
RUN chmod +x /usr/bin/run.sh

# Expose the application port
EXPOSE 3838

# Run the R Shiny app
#CMD ["Rscript", "/home/shiny-app/app.R"]
CMD ["/usr/bin/run.sh"]