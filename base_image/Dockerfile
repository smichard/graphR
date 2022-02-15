FROM centos:7

# Installing Cent OS packages
RUN yum -y update && yum -y install \
	epel-release \
	java-1.8.0-openjdk \
	java-1.8.0-openjdk-devel \
	libapreq2-devel \
	libcurl-devel \
	libpng-devel \
	libtiff-devel \
	libjpeg-turbo-devel \
	libxml2-devel \
	yum-utils && \
	yum clean all

# Installing R
RUN yum -y update && yum -y install \
	R

# Copy Packages	
COPY ./packages /packages

# Installing R-Shiny and R packages
RUN	R -e "install.packages('shiny', repos='http://cran.rstudio.com/')" && \
	yum -y install --nogpgcheck /packages/shiny-server-1.5.3.838-rh5-x86_64.rpm && \
	R -e "install.packages(c('ape', 'broom', 'compiler', 'digest', 'dplyr', 'flexdashboard', 'forcats', 'GGally', 'ggplot2', 'graph', 'igraphdata', 'igraph', 'intergraph', 'irlba', 'maps', 'magrittr', 'markdown', 'network', 'NMF', 'pkgconfig', 'png', 'RColorBrewer', 'readxl', 'reshape2', 'rgl', 'rmarkdown', 'scales', 'shinydashboard', 'shinyjs', 'sna', 'statnet.common', 'stats4', 'tcltk', 'testthat', 'tibble'), repos='https://cran.rstudio.com/')"

EXPOSE 3838

CMD [ "/bin/sh" ]
