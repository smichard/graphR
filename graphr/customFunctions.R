# both applications
readData_old <- function (file=choose.files()){
  data <- read.xlsx(file, sheetIndex=1, startRow=1, as.data.frame=TRUE, header=TRUE, keepFormulas=FALSE)
  return(data)
}

readData <- function (file=choose.files()){
  data <- data.frame(read_excel(file, sheet=1, col_names=TRUE))
  #data <- data.frame(data)
  return(data)
}

designPlot <- function(plotVar){
  plotVar <- plotVar + theme(title = element_text(face="bold", size=24),
                             axis.title.x = element_text(face="bold", size=22, margin=margin(20,0,0,0)),
                             axis.text.x  = element_text(vjust=0.5, size=18),
                             axis.title.y = element_text(face="bold", size=22, margin=margin(20,15,0,0)),
                             axis.text.y  = element_text(vjust=0.5, size=18))
  return(plotVar)
}

# get report name, in order to get a unique identity for each report session and for each generated report
# function returns vector, first argument report name, second argument file path
get_rep_name <- function(){
  report_name <- paste("report", ceiling(as.numeric(Sys.time())), floor(runif(1, min=1000, max=9999)), sep = "_")
  report_name <- paste(report_name, ".pdf", sep = "")
  file_path <- paste("www/", report_name, sep = "")
  return(c(report_name, file_path))
}

# exclusiv rv
# get dataframe stats - summary for each datacenter
get_stats <- function(df){
  profile <- df %>%
    mutate(Description = ifelse(CPU >= 6, "Large",
                                ifelse(CPU < 6 & CPU > 2, "Medium", 
                                       ifelse(CPU <= 2, "Small", NA)))) %>%
    mutate(VM_on = ifelse(Powerstate =="poweredOn", 1, 0)) %>%
    group_by(Description) %>%
    summarise(VM_Count = n(), n_VMs_on = sum(VM_on), n_VMs_off = n()-sum(VM_on), Concurrent_Ratio = round(n_VMs_on*100/(VM_Count), 1),
              CPU_Count = sum(CPU), Memory_Count = round(sum(Memory)/1000, 1), Storage_Occupied = round(sum(In_Use_MB)/1000, 1),
              Storage_Provisioned = round(sum(Provisioned_MB)/1000, 1), free_space = round(100-Storage_Occupied/Storage_Provisioned*100 ,1),
              CPU_Count_per_VM = round(CPU_Count/VM_Count, 1), Memory_Count_per_VM = round(Memory_Count/VM_Count, 1),
              Storage_Occupied_per_VM = round(Storage_Occupied/VM_Count, 1), Storage_Provisioned_per_VM = round(Storage_Provisioned/VM_Count, 1))
  
  total <- profile %>%
    mutate(Description = "Total") %>%
    group_by(Description) %>%
    summarise(VM_Count = sum(VM_Count), n_VMs_on = sum(n_VMs_on), n_VMs_off = sum(n_VMs_off), Concurrent_Ratio = round(n_VMs_on*100/VM_Count, 1),
              CPU_Count = sum(CPU_Count), Memory_Count = round(sum(Memory_Count), 1), Storage_Occupied = round(sum(Storage_Occupied), 1),
              Storage_Provisioned = round(sum(Storage_Provisioned), 1), free_space = round(100-Storage_Occupied/Storage_Provisioned*100 ,1),
              CPU_Count_per_VM = round(sum(CPU_Count)/VM_Count, 1), Memory_Count_per_VM = round(Memory_Count/VM_Count, 1),
              Storage_Occupied_per_VM = round(Storage_Occupied/VM_Count, 1), Storage_Provisioned_per_VM = round(Storage_Provisioned/VM_Count, 1))
  
  total <- rbind(profile, total)
  return(total)
}

# get dataframe stats - overview of all datacenter
get_stats_overview <- function(df){
  overview <- df %>%
    group_by(Datacenter) %>%
    summarise(Host_Count = n_distinct(Host), VM_Count = n(), CPU_Count = sum(CPU), Memory_Count = round(sum(Memory)/1000, 1), Storage_Occupied = round(sum(In_Use_MB)/1000, 1),
              Storage_Provisioned = round(sum(Provisioned_MB)/1000, 1), free_space = round(100-Storage_Occupied/Storage_Provisioned*100 ,1)) %>%
    arrange(desc(CPU_Count))
  return(overview)
}

# get top 5 VM's
get_top_VM <- function(df){
  top_VM <- df %>%
    arrange(desc(CPU), desc(Memory)) %>%
    slice(1:5) %>%
    mutate(Memory = round(Memory / 1000, 1), In_Use_MB = round(In_Use_MB/1000, 1), Provisioned_MB = round(Provisioned_MB/1000, 1))
  return(top_VM)
}

generate_plots <- function(df, raw_df, praefix = "comp"){
  # Plot VM count
  plot_list <- list()
  plot_list[[length(plot_list)+1]] <- designPlot(ggplot(df, aes(x=Description, y=VM_Count))  + geom_bar(stat="identity", width=.7, fill="steelblue") + xlab("VM Profile") + ylab("Number of VM's") + geom_text(aes(label=VM_Count), vjust=1.6, color="white", size=5.5, fontface="bold") + guides(fill=FALSE))
  
  # Plot Power Status
  tmp <- df[, c("Description", "VM_Count", "n_VMs_on", "n_VMs_off")]
  tmp <- melt(tmp ,  id='Description', value.name='Count', variable.name = 'Type')
  plot_list[[length(plot_list)+1]] <- designPlot(ggplot(tmp, aes(x=Description, y=Count, fill=factor(Type, levels = c("n_VMs_off", "n_VMs_on", "VM_Count")))) + geom_bar(stat="identity", width=.7, position = "dodge") + xlab("VM Profile") + ylab("Number of VM's") + scale_fill_manual(values=c("#fc8d62", "#66c2a5", "#377eb8"), name ="", labels=c("VM's powered off", "VM's powered on", "Total Number of VM's")))
  
  # Plot CPU Density
  if(praefix != "comp"){
    df <- raw_df %>%
      filter(Datacenter == praefix)
  }else{
    df <- raw_df
  }
  plot_list[[length(plot_list)+1]] <- designPlot(ggplot(df, aes(x=CPU)) + geom_density(alpha =.5, fill="steelblue", aes(y= ..scaled..)) + xlab("vCPU Count") + ylab("Density [ - ]") + xlim(c(-0.5,20)))
  
  # Plot Memory Density
  plot_list[[length(plot_list)+1]] <- designPlot(ggplot(df, aes(x=Memory/1000)) + geom_density(alpha =.5, fill="steelblue", aes(y= ..scaled..)) + xlab("Memory [GB]") + ylab("Density [ - ]") + xlim(c(-0.5,60)))
  
  # Plot Storage Density
  tmp <- df[,c("Provisioned_MB", "In_Use_MB")]
  tmp <- melt(tmp, value.name='Count', variable.name = 'Type') 
  plot_list[[length(plot_list)+1]] <- designPlot(ggplot(tmp, aes(x=Count/1000, fill=Type)) + geom_density(alpha =.5, aes(y= ..scaled..)) + xlab("Storage [GB]") + ylab("Density [ - ]") + xlim(c(-0.5,2000))  + scale_fill_discrete(name ="", labels=c("Provisioned Storage [GB]", "Occupied Storage [GB]")))
  
  return(plot_list)
}

generate_slides <- function(df, plot_list, top_VM, praefix = "comp"){
  if(praefix == "comp"){
    # table all values
    tmp <- as.data.frame(df[, c("Description", "VM_Count", "n_VMs_on", "n_VMs_off", "Concurrent_Ratio", "CPU_Count", "Memory_Count", "Storage_Occupied", "Storage_Provisioned", "free_space")])
    colnames(tmp) <- c("Description", "# VM's", "# VM's on", "# VM's off", "Concurrent Ratio [%]", "# vCPU's", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]", "Free Space [%]")
    slideTable(tmp, "Summary of collected components")
    
    # table: summary per VM, average
    tmp <- as.data.frame(df[, c("Description","VM_Count", "Concurrent_Ratio", "CPU_Count_per_VM", "Memory_Count_per_VM", "Storage_Occupied_per_VM", "Storage_Provisioned_per_VM")])
    colnames(tmp) <- c("Description", "# VM's", "Concurrent Ratio [%]", "# vCPU's", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]")
    slideTable(tmp, "Average values of collected components")
    
    # Plots
    slidePlot(plot_list[[1]], "Number of VM's for each profile")
    
    slidePlot(plot_list[[2]], "Overview of powered on / off VM's for each profile")
    
    slidePlot(plot_list[[3]], "Distribution of vCPU for all VM's")
    
    slidePlot(plot_list[[4]], "Distribution of Memory for all VM's")
    
    slidePlot(plot_list[[5]], "Distribution of occup. and provis. storage for all VM's")
    
    tmp <- as.data.frame(top_VM[, c("VM", "CPU", "Memory", "In_Use_MB", "Provisioned_MB", "Datacenter", "Host")])
    colnames(tmp) <- c("VM Name", "# vCPU", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]", "Datacenter", "Host")
    slideTable(tmp, "Top 5 VM's")
    
  }else{
    slideChapter(paste("Summary for Datacenter: ", praefix, ""))
    
    # table all values
    tmp <- as.data.frame(df[, c("Description", "VM_Count", "n_VMs_on", "n_VMs_off", "Concurrent_Ratio", "CPU_Count", "Memory_Count", "Storage_Occupied", "Storage_Provisioned", "free_space")])
    colnames(tmp) <- c("Description", "# VM's", "# VM's on", "# VM's off", "Concurrent Ratio [%]", "# vCPU's", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]", "Free Space [%]")
    slideTable(tmp, paste("Summary of collected components for: ", praefix, ""))
    
    # table: summary per VM
    tmp <- as.data.frame(df[, c("Description","VM_Count", "Concurrent_Ratio", "CPU_Count_per_VM", "Memory_Count_per_VM", "Storage_Occupied_per_VM", "Storage_Provisioned_per_VM")])
    colnames(tmp) <- c("Description", "# VM's", "Concurrent Ratio [%]", "# vCPU's", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]")
    slideTable(tmp, paste("Average values of collected components for: ", praefix, ""))
    
    slidePlot(plot_list[[1]], paste("Number of VM's for each profile - ", praefix, ""))
    
    slidePlot(plot_list[[2]], paste("Overview of powered on / off VM's for each profile - ", praefix, ""))
    
    slidePlot(plot_list[[3]], paste("Distribution of vCPU for all VM's - ", praefix, ""))
    
    slidePlot(plot_list[[4]], paste("Distribution of Memory for all VM's - ", praefix, ""))
    
    slidePlot(plot_list[[5]], paste("Distribution of occup. and provis. storage for all VM's - ", praefix, ""))
    
    tmp <- as.data.frame(top_VM[, c("VM", "CPU", "Memory", "In_Use_MB", "Provisioned_MB", "Datacenter", "Host")])
    colnames(tmp) <- c("VM Name", "# vCPU", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]", "Datacenter", "Host")
    slideTable(tmp, paste("Top 5 VM's for: ", praefix, ""))
  }  
}

generate_overview_slide <- function(df){
  # table all values
  tmp <- as.data.frame(df[, c("Datacenter", "Host_Count","VM_Count", "CPU_Count", "Memory_Count", "Storage_Occupied", "Storage_Provisioned", "free_space")])
  colnames(tmp) <- c("Datacenter", "# Hosts", "# VM's", "# vCPU's", "Memory [GB]", "Occupied Storage [GB]", "Provisioned Storage [GB]", "Free Space [%]")
  slideTable(tmp, paste("Overview for ", nrow(df), " Datacenter", sep=""))
}

# function to get new vertices, gol is to add labels to network plots
get_vertices <- function(var_list){
  tmp_list <- list()
  for(i in 1:length(var_list)){
    tmp_list[[length(tmp_list)+1]] <- paste(var_list[i], "--", var_list[i], sep="")
    names(tmp_list)[i] <- as.character(i)
    i <- i+1
  }
  return(tmp_list)
}