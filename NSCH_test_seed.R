library(data.table)
options(timeout=9999)
if(!file.exists("data_Classif.zip")){
  download.file("https://zenodo.org/records/18273949/files/SOAK_data_Classif.zip?download=1", "data_Classif.zip")
}


set.seed(1)
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
    task_id, task.dt[sample(.N, 200)], target="y")
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
SOAK$instantiate(task.obj)

lrn_cvg <- mlr3resampling::LearnerClassifCVGlmnetSave$new()
lrn_cvg$param_set$values$seed <- 1L
class.learner.list <- list(lrn_cvg)  
for(learner.i in seq_along(class.learner.list)){
  class.learner.list[[learner.i]]$predict_type <- "prob"
}

proj.dir <- file.path(scratch.dir, "test")
unlink(proj.dir, recursive=TRUE)
score_args <- mlr3::msrs(c("classif.auc","classif.acc"))
mlr3resampling::proj_grid(
  proj.dir,
  task.list,
  class.learner.list,
  SOAK,
  score_args=score_args)
first <- mlr3resampling::proj_compute(1, proj.dir)
first$learner[[1]]$weights[weight!=0]
second <- mlr3resampling::proj_compute(1, proj.dir)
second$learner[[1]]$weights[weight!=0]
