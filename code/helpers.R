
#' Summarize nodes
#' 
#' @description Summarize the node values at hout or daily timescale
#'
#' @param data  The node values
#' @param timescale One of "all" or "step". Integrate over all time-steps, or not.
#' @param id    The tree id required (optional, character vector of ids).
#' @param group The functional group required. `NULL` summarize on all (default)
#' @param type  The component type required. `NULL` summarize on all (default)
#'
#' @details This function is often used in conjunction of a `dplyr::group_by()` grouping.
#' @return A data.frame of summarized values (one row)
#' @export
#' @example 
#' # Compute the daily results by functional group (e.g. soil and plants):
#' nodes%>%
#' group_by(group)%>%
#' summarize_nodes()
#' 
#' # Compute the daily results by functional group and component type:
#' nodes%>%
#' group_by(group)%>%
#' summarize_nodes()
summarize_nodes= function(data, timescale= c("day","hour"),id=NULL,group=NULL,type=NULL){
  timescale= match.arg(timescale, c("day","hour"), several.ok = FALSE)
  nsteps= length(unique(data$stepNumber))
  
  if(is.null(id)){
    id= unique(data$plantId)
  }
  if(is.null(group)){
    group= unique(data$group)
  }
  if(is.null(type)){
    type= unique(data$type)
  }
  data%>%
    filter(plantId%in%id,group%in%!!group,type%in%!!type)%>%
    # group_by_at(.tbl = .,vars(one_of(group_var)),add = TRUE)%>%
    {
      if(timescale=="hour"){
        group_by(.data = ., stepNumber,add = TRUE)
      }else{
        .
      }
    }%>%
    summarise(aPAR= sum(.data$absEnergy_withScattering_PAR*10^-6,na.rm=T),
              # aPAR in MJ node-1
              An= sum(.data$photo_assimilation_umol_s*.data$stepDuration*10^-6,na.rm=T), 
              # Palm tree photosynthesis umol s-1 -> mol node-1
              transpiration= sum(.data$enb_transpir_kg_s*.data$stepDuration,na.rm=T),
              # Palm tree transpiration in mm node-1
              Tleaf= mean(.data$enb_leaf_temp_C),
              area= sum(.data$meshArea)/!!nsteps,
              Gs= sum(.data$photo_stomatal_conductance_mol_m2_s*.data$stepDuration*.data$meshArea),
              H= sum(.data$enb_sensibleheat_W_m2*.data$meshArea*.data$stepDuration*10^-6))
}
