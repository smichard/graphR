<a href="https://www.graphr.de"><img src = "graphr/www/graphr_logo.png" width = "350" align="middle"></a>
# graphR.
<a href="https://www.graphr.de"><img src = "graphr/www/graphr_logo.png" width = "200" align="left"></a> 
xyz  
If you are interested, find out more at the [graphR. website](https://www.graphr.de). There you can also try the [app](https://www.launch.graphr.de) online and get started right away.


## Prerequisites

To run graphR. you just need an eviroment which supports Docker containers. To customize graphR. according to your needs the installation of the open source programming language [R](https://www.r-project.org/) is recommended.

## Getting Started

The easiest way to use graphR. is to pull the latest pre-build Docker container from [Dockerhub](https://hub.docker.com/r/smichard/graphr/) and to run it within your enviroment. The following commands will download graphR. from Dockerhub and make it available on your enviroment using it's ip-address

```
docker pull smichard/graphr
docker run -d -p 80:3838 smichard/graphr
```

## Customize

To customize graphR. aacording to your needs, e. g. by adding new ways to plot the data, altering threshold values or adding a custom design just clone this repository:

```
git clone https://github.com/smichard/graphr.git
```
Since the core of graphR. is written in R the installation of R is recommended to see the chances taking effect. If you are using R-Studio as code editor the `graphr_dashboard.Rproj` file contains all necessary files to adjust graphR.  
Following a short description of the most important files:  

* `app.R` - the main file, which is needed by the Shiny web framework to display the web app. Here the GUI of the web app is described, also sources the `libraries.R` and the `server_rv.R` files 
* `server_rv.R` - contains all necessary functions to ingest the raw data, to perform some basic analysis, to generate diagrams and to finally compile the pdf report
* `plottingFunctions.R` - a set of functions to display text, data frames and diagrams on slides
* `libraries.R` - contains a list of all required R packages, also sources the `plottingFunctions.R` file

In case you want to use custom backgrounds according to your corporate identity just replace the image files within the `/graphr/backgrounds` folder and make sure to use the `.png` file format.

Once all changes are done you can build your own custom graphR. container using the following commands: 
```
docker build -t <project name> .
docker run -d -p 80:3838 <project name>
```

## Built With

* [R](https://www.r-project.org/) - The open source programming language for statistical computing
* [R-Studio](https://www.rstudio.com/) - Used as code editor for R and for debugging and visualization
* [Shiny](https://shiny.rstudio.com/) - Used as web application framework for R
* [Docker](https://www.docker.com/) - Used to package all dependencies into one container

## Author

* **Stephan Michard** - reach out on [Twitter](https://twitter.com/StephanMichard)

## License

specific License tbd

## Support

Please file bugs and issues at the GitHub issues page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.
