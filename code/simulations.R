# Aim: Simulate the light interception of palm trees plantations 
# of increasing ages: 9, 12, 24, 36, 48, 60, 72 and 84 months after
# planting.
#
# Author: R. Vezy
# Date: 28/02/2020

library(archimedR)
library(tidyverse)
library(data.table)



# Make the simulations ----------------------------------------------------

set_config("archimed_simulations/app.properties", parameter = "file",
           value = "sim.ops")

Ages= list.files("archimed_simulations/opf")

Ages%>%
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


# Plot the outputs --------------------------------------------------------

plot_area= read_ops(file = "archimed_simulations/Control_EW_MAP.ops")$dimensions$area
meteo= archimedR::import_meteo("archimed_simulations/output_MAP_12/sim (0.0;0.0) (9.21;15.952)/000001/meteo.csv")
PAR_hour= meteo$`globalIrradiance (W/m2)`*0.48*meteo$timestep*10^-6
PAR_day= sum(PAR_hour)

MAPs= Ages%>%strsplit(.,"_")%>%lapply(., tail,1)%>%gsub(".opf","",.)%>%as.numeric()%>%sort()
nodes= 
  lapply(MAPs, function(x){
    sim_dir= paste0("archimed_simulations/output_MAP_",x)
    sim_files= list.files(sim_dir, recursive = TRUE, full.names = TRUE)
    nodes= fread(sim_files[grep("nodes_values.csv",sim_files)], data.table = FALSE)
  })
names(nodes)= MAPs 
nodes= dplyr::bind_rows(nodes, .id= "MAP")%>%mutate(MAP= as.numeric(MAP))


nodes%>%filter(MAP==9&plantId==1&type=="Leaflet"&stepNumber==0)%>%summarise(area= sum(meshArea))

nodes%>%
  group_by(MAP)%>%
  summarize_nodes(timescale = "day",type = "Leaflet")

# Daily results:

# Quantity: 
nodes%>%
  group_by(MAP)%>%
  filter(plantId>-1&type=="Leaflet")%>%
  summarize_nodes(timescale= "day")%>%
  mutate(An= An*12/1000/plot_area, 
         aPAR= aPAR/plot_area,
         faPAR= aPAR/PAR_day,
         transpiration= transpiration/plot_area,
         # H= H/plot_area,
         LAI= area/plot_area)%>%
  select(-aPAR,-area,-H, -Tleaf)%>%
  rename(`An~(g[C]~m[soil]^-2)`= An,
         # `aPAR~(MJ~m^-2)`= aPAR,
         # `H~(MJ~m[soil]^-2)`= H,
         `Gs~(µmole~m[soil]^-2~s^-1)`= Gs,
         `Transpiration~(mm~m[soil]^-2)`= transpiration,
         # `Tleaf~(degree~C)`= Tleaf
         )%>%
  reshape2::melt(id.vars= "MAP")%>%
  ggplot(aes(y= value, x= MAP, color= MAP))+
  facet_wrap(vars(variable), scales = "free_y", labeller = label_parsed, ncol = 2)+
  geom_point()+geom_line()+
  scale_color_viridis_c()

ggsave("output/daily_quantities.png",width = 5, height = 4)

# rates: 
nodes%>%
  group_by(MAP)%>%
  filter(plantId>-1&type=="Leaflet")%>%
  summarise(
            aPAR= mean(.data$absEnergy_withScattering_PAR/.data$meshArea/.data$stepDuration,na.rm=T),
            # aPAR in MJ node-1
            An_rate= mean(photo_assimilation_rate_umol_m2_s),
            transpiration_rate= mean(.data$enb_transpir_kg_s/.data$meshArea,na.rm=T),
            # Tleaf= mean(.data$enb_leaf_temp_C),
            # area= sum(.data$meshArea)/!!nsteps,
            Gs= mean(.data$photo_stomatal_conductance_mol_m2_s),
            # H= mean(.data$enb_sensibleheat_W_m2)
            )%>%
  # mutate(LAI= area/plot_area)%>%
  # select(-area)%>%
  rename(`An~rate~(g[C]~m[leaf]^-2~s^-1)`= An_rate,
         `aPAR~(MJ~m[leaf]^-2~s^-1)`= aPAR,
         # `H~(W~m[leaf]^-2)`= H,
         `Gs~(µmole~m[leaf]^-2~s^-1)`= Gs,
         `Transpiration~(mm~m[leaf]^-2~s^-1)`= transpiration_rate,
         # `Tleaf~(degree~C)`= Tleaf
         )%>%
  reshape2::melt(id.vars= "MAP")%>%
  ggplot(aes(y= value, x= MAP, color= MAP))+
  facet_wrap(vars(variable), scales = "free_y", labeller = label_parsed, ncol = 2)+
  geom_point()+geom_line()+
  scale_color_viridis_c()

ggsave("output/daily_rates.png",width = 5, height = 4)


# Hourly results
nodes%>%
  group_by(MAP,stepNumber)%>%
  filter(plantId>-1&type=="Leaflet")%>%
  summarize_nodes(timescale = "hour",type = "Leaflet")%>%
  select(-area)%>%
  rename(`Net~Assimilation~(g[C]~m[soil]^-2)`= An,
         `aPAR~(MJ~m[soil]^-2)`= aPAR,
         `H~(MJ~m[soil]^-2)`= H,
         `Gs~(µmole~m[soil]^-2~s^-1)`= Gs,
         `Transpiration~(mm~m[soil]^-2)`= transpiration,
         `Tleaf~(degree~C)`= Tleaf)%>%
  reshape2::melt(id.vars= c("MAP","stepNumber"))%>%
  ggplot(aes(y= value, x= stepNumber, color= as.factor(MAP)))+
  facet_wrap(vars(variable), scales = "free_y", labeller = label_parsed)+
  geom_point()+geom_line()+
  scale_color_viridis_d()+
  labs(color="MAP")

ggsave("output/hourly_quantities.png",width = 10, height = 5)

nodes%>%
  group_by(MAP, stepNumber)%>%
  filter(plantId>-1&type=="Leaflet")%>%
  summarise(aPAR= mean(.data$absEnergy_withScattering_PAR/.data$meshArea/.data$stepDuration,na.rm=T),
            # aPAR in MJ node-1
            An_rate= mean(photo_assimilation_rate_umol_m2_s),
            transpiration_rate= mean(.data$enb_transpir_kg_s/.data$meshArea,na.rm=T),
            Tleaf= mean(.data$enb_leaf_temp_C),
            area= sum(.data$meshArea)/!!nsteps,
            Gs= mean(.data$photo_stomatal_conductance_mol_m2_s),
            H= mean(.data$enb_sensibleheat_W_m2))%>%
  select(-area)%>%
  rename(`Net~Assimilation~rate~(g[C]~m[leaf]^-2~s^-1)`= An_rate,
         `aPAR~(MJ~m[leaf]^-2~s^-1)`= aPAR,
         `H~(W~m^-2)`= H,
         `Gs~(µmole~m^-2~s^-1)`= Gs,
         `Transpiration~(mm~m[leaf]^-2~s^-1)`= transpiration_rate,
         `Tleaf~(degree~C)`= Tleaf)%>%
  reshape2::melt(id.vars= c("MAP","stepNumber"))%>%
  ggplot(aes(y= value, x= stepNumber, color= as.factor(MAP)))+
  facet_wrap(vars(variable), scales = "free_y", labeller = label_parsed)+
  geom_point()+geom_line()+
  scale_color_viridis_d()+
  labs(color="MAP")

ggsave("output/hourly_rates.png",width = 10, height = 5)