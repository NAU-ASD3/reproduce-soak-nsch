source("NSCH_proj.R")

mlr3resampling::proj_submit(
  proj.dir,
  tasks=20,
  hours=6,
  gigabytes=3)#jid 7302689
mlr3resampling::proj_results(proj.dir)
mlr3resampling::proj_todo(proj.dir)

file.copy(
  file.path(proj.dir, "results.csv"),
  file.path("results", "2026-02-24", "NSCH_mpi.csv"))
