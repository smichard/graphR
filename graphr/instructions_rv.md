### Introduction
[RVTools](http://www.robware.net/rvtools/) is a VMware utility that connects to a vCenter and gathers information with an impressive level of detail on the VMware environment (e. g. on virtual machines, on ESX hosts, on the network configuration). The data collection is fast and easy. The end result can be stored in a Microsoft Excel file. RVTools exports are a great way to collect data on VMware environments. However, analyzing RVTool exports especially of complex environments can be time-consuming, error-prone and cumbersome.  

The purpose of **graphR** is to automatize and simplify the analysis of RVTools exports and to give a visual presentation of the information contained within an Excel file or a comma seperated file.

### Instructions
The use of **graphR** is designed to be simple and should be self-explanatory. Just upload the Excel file (recommended) or the comma seperated file after inserting a title and author name and hit *Generate Report*. If using the `.csv` file the `tabvInfo.csv` should be uploaded.    
The RVTools export should at least contain the following columns:  
VM, Powerstate, CPUs, Memory, Network #1, Provisioned MB, In Use MB, Datacenter, Host, OS according to the configuration file 


### Caution
The Excel file should not be altered in any kind, e. g. by inserting comments, changing column names or inserting new rows manually.  

### Feedback
Please use the [GitHub repository](https://github.com/smichard/graphr) to provide feedback, new ideas or bugs or reach out to the author on [Twitter](https://twitter.com/StephanMichard).

