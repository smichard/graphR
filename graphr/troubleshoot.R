source("libraries.R")


  # xls file - using readxl package for xls import
  data <- data.frame(read_excel(choose.files(), sheet=1, col_names=TRUE))
  
  # csv file - using read.csv for import
  data <- read.csv(choose.files(), header = TRUE, sep = ";", dec = ".", fill = FALSE, comment.char = "")
  
  # check for OS column
  if("OS.according.to.the.configuration.file" %in% colnames(data)){
    data_sub <- data[, c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MB", "In.Use.MB", "Datacenter", "OS.according.to.the.configuration.file", "Host", "Network..1")]
  } else{
    data_sub <- data[, c("VM", "Powerstate", "CPUs", "Memory", "Provisioned.MB", "In.Use.MB", "Datacenter", "OS", "Host", "Network..1")]
  }
  colnames(data_sub) <- c("VM", "Powerstate", "CPU", "Memory", "Provisioned_MB", "In_Use_MB", "Datacenter", "OS", "Host", "Network_1")
  data_sub <- na.omit(data_sub)
  


"VM" %in% colnames(data)
"Powerstate" %in% colnames(data)
"CPUs" %in% colnames(data)
"Memory" %in% colnames(data)
"Provisioned.MB" %in% colnames(data)
"In.Use.MB" %in% colnames(data)
"Datacenter" %in% colnames(data)
"OS.according.to.the.configuration.file" %in% colnames(data)
"Host" %in% colnames(data)
"Network..1" %in% colnames(data)


# test if rows have been ommitted
if(nrow(data_sub) <  nrow(data)){
  # everthing as usual
}else{
  # show warning
  print(2)
}
