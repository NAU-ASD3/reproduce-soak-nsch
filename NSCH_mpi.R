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
mlr3resampling::proj_test(proj.dir)

mlr3resampling::proj_submit(
  proj.dir,
  tasks=100,
  hours=12,
  gigabytes=3)#jid 7290208 on rorqual
mlr3resampling::proj_results(proj.dir)
mlr3resampling::proj_todo(proj.dir)
