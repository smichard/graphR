source("libraries.R")

overview_host <- data.frame(read_excel("export.xlsx", sheet="tabvHost", col_names=TRUE))

host_sub <- overview_host[, c("Host", "Datacenter", "CPU.Model", "X..CPU", "Cores.per.CPU", "X..Cores", "X..Memory", "X..vCPUs", "ESX.Version")]

colnames(host_sub) <- c("Host", "Datacenter", "CPU_Model", "n_CPU", "Cores_per_CPU", "n_Cores", "Memory", "n_vCPU", "ESX_Version")
host_sub <- na.omit(host_sub)


host_sub %>%
  mutate(test = round(n_vCPU / n_Cores, 1)) %>%
  summarise(CPU_count = sum(n_CPU), Core_count = sum(n_Cores), Memory_count = sum(Memory), vCPU_count = sum(n_vCPU), vCPU_to_Core = round(vCPU_count/Core_count, 1))  



summarise(VM_Count = sum(VM_Count), n_VMs_on = sum(n_VMs_on), n_VMs_off = sum(n_VMs_off), Concurrent_Ratio = round(n_VMs_on*100/VM_Count, 1),
          CPU_Count = sum(CPU_Count), Memory_Count = round(sum(Memory_Count), 1), Storage_Occupied = round(sum(Storage_Occupied), 1),
          Storage_Provisioned = round(sum(Storage_Provisioned), 1), free_space = round(100-Storage_Occupied/Storage_Provisioned*100 ,1),
          CPU_Count_per_VM = round(sum(CPU_Count)/VM_Count, 1), Memory_Count_per_VM = round(Memory_Count/VM_Count, 1),
          Storage_Occupied_per_VM = round(Storage_Occupied/VM_Count, 1), Storage_Provisioned_per_VM = round(Storage_Provisioned/VM_Count, 1))

