
library(archimedR)
library(tidyverse)

set_config("archimed_simulations/app.properties", parameter = "file",
           value = "sim.ops")

list.files("archimed_simulations/opf")%>%
  lapply(., function(opf){
    OPS= read_ops(file = "archimed_simulations/Control_EW_MAP.ops")
    OPS$plants= OPS$plants%>%mutate(plantFileName= file.path("opf",opf))
    write_ops(data = OPS, file = "archimed_simulations/sim.ops")
    MAP= opf%>%strsplit(.,"_")%>%unlist(.)%>%tail(.,1)%>%gsub(".opf","",.)%>%as.numeric()
    set_config("archimed_simulations/app.properties", parameter = "outputDirectory",
               value = paste0("output_MAP_",MAP))
    run_archimed("archimed_simulations/archimed-2020-02-11-commit-e6ef3d7.jar", 16000, 
                 config = "app.properties")
  })

