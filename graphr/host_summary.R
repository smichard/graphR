source("libraries.R")

overview_host <- data.frame(read_excel("export.xlsx", sheet="tabvHost", col_names=TRUE))

overview_host <- data.frame(read_excel(choose.files(), sheet="tabvHost", col_names=TRUE))


if(exists("overview_host")){
  host_sub <- overview_host[, c("Host", "Datacenter", "CPU.Model", "X..VMs", "X..CPU", "Cores.per.CPU", "X..Cores", "X..Memory", "X..vCPUs", "ESX.Version")]
  
  colnames(host_sub) <- c("Host", "Datacenter", "CPU_Model", "n_VMs", "n_CPU", "Cores_per_CPU", "n_Cores", "Memory", "n_vCPU", "ESX_Version")
  host_sub <- na.omit(host_sub)
}

#host_sub <- host_sub %>%
#    mutate(test = round(n_vCPU / n_Cores, 1))

host_summary <- host_sub %>%
    summarise(Host_count = round(n_distinct(Host), 0), Memory_count = round(sum(Memory)/1000, 1), VM_count = round(sum(n_VMs), 0), CPU_count = round(sum(n_CPU), 0), Core_count = round(sum(n_Cores),0), vCPU_count = round(sum(n_vCPU), 0), vCPU_to_Core = round(vCPU_count/Core_count, 1))  

colnames(host_summary) <- c("# of Hosts", "overall Memory [GB]", "# of VMs", "# of Sockets", "# of Cores", "# vCPU", "vCPU to Core ratio")

host_summary <- as.data.frame(t(host_summary))
host_summary <- rownames_to_column(host_summary)

colnames(host_summary) <- c("Description", "Value")


host_sub <- host_sub[, c("Host", "Datacenter", "CPU_Model", "Memory", "n_CPU", "n_vCPU", "ESX_Version")]