# graphR.
[![Docker Repository on Quay](https://quay.io/repository/michard/graphr/status "Docker Repository on Quay")](https://quay.io/repository/michard/graphr)

<a href="https://www.graphr.de"><img src = "graphr/www/graphR_logo.png" width = "200" align="left"></a> 
The purpose of **graphR.** is to automatize and simplify the analysis of RVTools exports and to give a visual presentation of the information contained within one Excel export. [RVTools](http://www.robware.net/rvtools/) is a VMware utility that connects to a vCenter and gathers information with an impressive level of detail on the VMware environment (e. g. on virtual machines, on ESX hosts, on the network configuration). The data collection is fast and easy. The result can be stored in a Microsoft Excel file. RVTools exports are a great way to collect data on VMware environments. However, analyzing RVTool exports, especially of complex environments can be time-consuming, error-prone, and cumbersome.  
That's where **graphR.** steps in. **GraphR.** processes RVTool exports which are saved as Microsoft Excel or as comma-separated files. It performs some statistical analysis on the data contained within the Microsoft Excel file. The dataset is visualized through some beautiful-looking diagrams. Finally, all tables and charts are assembled in one downloadable PDF report. Hence **graphR.** enables you to generate a concise report with some great graphics
in order to derive meaningful insights on the analyzed VMware environment.  

If you are interested, find out more at the [graphR. website](https://www.graphr.de). There you can also try the [app](https://www.launch.graphr.de) online and get started right away.  

To provide feedback or to point out bugs please reach out via mail: [graphr.feedback@gmail.com](mailto:graphr.feedback@gmail.com).  

If you find the project helpful please consider supporting graphR. as a sponsor - [Buy Me a Coffee](https://www.buymeacoffee.com/graphr).
___

## Table of Contents
    
* [Prerequisites](https://github.com/smichard/graphR#prerequisites)
* [Getting Started](https://github.com/smichard/graphR#getting-started)
* [Customize](https://github.com/smichard/graphR#customize)
* [How to use graphR.](https://github.com/smichard/graphR#how-to-use-graphr)
* [Built With](https://github.com/smichard/graphR#built-with)
* [Author](https://github.com/smichard/graphR#author)
* [Support](https://github.com/smichard/graphR#support)
___

## Prerequisites

To run **graphR.** you just need an environment that supports Docker containers. To customize **graphR.** according to your needs the installation of the open-source programming language [R](https://www.r-project.org/) is recommended.

## Getting Started

The easiest way to use **graphR.** is to pull the latest pre-build Docker container from [Dockerhub](https://hub.docker.com/r/smichard/graphr/) and run it within your environment. The following commands will download **graphR.** from Dockerhub and make it available on your environment using it's ip-address

```
docker pull smichard/graphr
docker run -d -p 80:3838 smichard/graphr
```

## Customize

To customize **graphR.** according to your needs, e. g. by adding new ways to plot the data, altering threshold values, or adding a custom design just clone this repository:

```
git clone https://github.com/smichard/graphR.git
```
Since the core of **graphR.** is written in R the installation of R is recommended to see the changes taking effect. If you are using R-Studio as a code editor the `graphr_dashboard.Rproj` file contains all necessary files to adjust **graphR.**    

Following is a short description of the most important files:  

* `app.R` - the main file, which is needed by the Shiny web framework to display the web app. Here the GUI of the web app is described, also the `libraries.R` and the `server_rv.R` files are sourced 
* `server_rv.R` - contains all necessary functions to ingest the raw data, perform some basic analysis, generate diagrams, and to finally generate the pdf report
* `plottingFunctions.R` - a set of functions to display text, data frames and diagrams on slides
* `libraries.R` - contains a list of all required R packages, and also sources the `plottingFunctions.R` file

In case you want to use custom backgrounds according to your corporate identity just replace the image files within the `/graphr/backgrounds` folder and make sure to use the `.png` file format. The recommended image dimensions are 960 px times 540 px.

Once all changes are done you can build your own custom **graphR.** container using the following commands: 
```
docker build -t <project name> .
docker run -d -p 80:3838 <project name>
```

## How to use graphR.

The use of graphR. is designed to be simple: 

1. Collect the data with the [RVTools](http://www.robware.net/rvtools/) and save the export as `.xls`, `.xlsx` or as `.csv` file
2. Upload the `.xls` / `.xlsx` file (recommended) or the `tabvInfo.csv` to graphR. and hit `Generate Report`
3. Enjoy your report

get a glimpse through this YouTube video:

<a href="https://youtu.be/dotbSX79FJg"><img src = "graphr/www/graphR_screenshot.jpg" width = "400" align="center"></a> 

## Deploy on OpenShift
To deploy graphR. on OpenShift, follow these steps:

1. Apply the Security Context Constraints (SCC):
Apply the `shiny-scc.yml` configuration to your OpenShift cluster to create a custom SCC. This SCC ensures that the application has the necessary permissions to run.
```bash
oc apply -f shiny-scc.yaml
```

2. Create a Service Account:
Generate a new service account named shiny-sa that will be associated with your application deployment.
```bash
oc create serviceaccount shiny-sa
```

3. Associate the SCC with the Service Account:
Grant the shiny-scc permissions to the shiny-sa service account to allow the application to run under the defined security policies.
```bash
oc adm policy add-scc-to-user shiny-scc -z shiny-sa
```

4. Apply the Deployment Configuration:
Deploy graphR. by applying the graphr-deployment.yaml file. Ensure you are targeting the correct namespace (e.g., graphr).
```bash
oc apply -f graphr-deployment.yaml -n graphr
```

5. Access the Application:
Retrieve the route URL to access your graphR. application.
```bash
oc get route graphr-route -n graphr
```
Open the obtained URL in your web browser to start using graphR.


## Deploy on Google Cloud Run
Deploying graphR. on Google Cloud Run allows you to run the application in a scalable, serverless environment. Follow these steps:

1. Build and Push the Docker Image:

Build your Docker image and push it to Google Container Registry (GCR):

```bash
# Build the Docker image
docker build -t gcr.io/your-project-id/graphr .

# Push the Docker image to GCR
docker push gcr.io/your-project-id/graphr
```
Replace `your-project-id` with your actual Google Cloud project ID.

2. Deploy to Cloud Run:

Use the gcloud command-line tool to deploy graphR. to Cloud Run:
```bash
gcloud run deploy graphr \
  --image gcr.io/your-project-id/graphr \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3838
```
- --platform managed specifies that you're using the fully managed version of Cloud Run.
- --allow-unauthenticated makes the service publicly accessible. Omit this flag if you want to restrict access.
- Adjust --region to a region close to your users or infrastructure.

3. Access the Application:

Upon successful deployment, the command will output a URL where the service is accessible. Open this URL in your web browser to start using graphR.

## Built With

* [R](https://www.r-project.org/) - The open source programming language for statistical computing
* [R-Studio](https://www.rstudio.com/) - Used as code editor for R and for debugging and visualization
* [Shiny](https://shiny.rstudio.com/) - Used as web application framework for R
* [Docker](https://www.docker.com/) - Used to package all dependencies into one container

## Author

* **Stephan Michard** - reach out on [Twitter](https://twitter.com/StephanMichard) or via [mail](mailto:graphr.feedback@gmail.com).

## Support

Please file bugs and issues on the GitHub issues page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community-driven process. If you find the project helpful and it adds value to your work, it would be nice if you would support the project as a sponsor, to ensure the long-term existence of the project - [Buy Me a Coffee](https://www.buymeacoffee.com/graphr).

