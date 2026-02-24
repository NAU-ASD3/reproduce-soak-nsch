source("NSCH.R")

proj.dir <- file.path(scratch.dir, "proj")
unlink(proj.dir, recursive=TRUE)
score_args <- mlr3::msrs(c("classif.auc","classif.acc"))
mlr3resampling::proj_grid(
  proj.dir,
  task.list,
  class.learner.list,
  SOAK,
  score_args=score_args)


