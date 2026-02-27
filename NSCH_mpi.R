source("NSCH_proj.R")

mlr3resampling::proj_submit(
  proj.dir,
  tasks=20,
  hours=6,
  gigabytes=3)#jid 7302689
mlr3resampling::proj_results(proj.dir)
mlr3resampling::proj_todo(proj.dir)
