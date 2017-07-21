source("libraries.R")

overview_host <- data.frame(read_excel("export.xlsx", sheet="tabvHost", col_names=TRUE))

overview_host <- data.frame(read_excel(choose.files(), sheet="tabvHost", col_names=TRUE))


exists("overview_host")
host_sub <- overview_host[, c("Host", "Datacenter", "CPU.Model", "X..CPU", "Cores.per.CPU", "X..Cores", "X..Memory", "X..vCPUs", "ESX.Version")]

colnames(host_sub) <- c("Host", "Datacenter", "CPU_Model", "n_CPU", "Cores_per_CPU", "n_Cores", "Memory", "n_vCPU", "ESX_Version")
host_sub <- na.omit(host_sub)


host_sub <- host_sub %>%
    mutate(test = round(n_vCPU / n_Cores, 1))

host_summary <- host_sub %>%
    summarise(CPU_count = sum(n_CPU), Core_count = sum(n_Cores), Memory_count = sum(Memory), vCPU_count = sum(n_vCPU), vCPU_to_Core = round(vCPU_count/Core_count, 1))  

total <- rbind(host_sub, host_summary)