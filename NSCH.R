library(data.table)
options(timeout=9999)
if(!file.exists("data_Classif.zip")){
  download.file("https://zenodo.org/records/18273949/files/SOAK_data_Classif.zip?download=1", "data_Classif.zip")
}

SOAK <- mlr3resampling::ResamplingSameOtherSizesCV$new()
SOAK$param_set$values$folds <- 10
task.list <- list()
dir.create("data_meta", showWarnings = FALSE)
for(task_id in "NSCH_autism"){
  data.csv <- sprintf("data_Classif/%s.csv", task_id)
  meta.csv <- sprintf("data_meta/%s.csv", task_id)
  if(!file.exists(data.csv)){
    unzip("data_Classif.zip", data.csv)
  }
  task.dt <- fread(
    data.csv,
    colClasses=list(factor="y"),
    check.names=TRUE)#required by mlr3.
  task.obj <- mlr3::TaskClassif$new(
    task_id, task.dt, target="y")
  subset.col <- names(task.dt)[1]
  task.obj$col_roles$subset <- subset.col
  task.obj$col_roles$stratum <- c(subset.col, "y")
  task.obj$col_roles$feature <- setdiff(names(task.dt), task.obj$col_roles$stratum)
  task.list[[task_id]] <- task.obj
  meta_dt <- setnames(
    task.dt[, .(rows=.N), by=subset.col],
    subset.col,
    "test.subset")
  fwrite(meta_dt, meta.csv)
}  
scratch.dir <- "scratch"
dir.create(scratch.dir, showWarnings=FALSE)

(class.learner.list <- list(
  mlr3resampling::LearnerClassifCVGlmnetSave$new())
for(learner.i in seq_along(class.learner.list)){
  class.learner.list[[learner.i]]$predict_type <- "prob"
}

