source("NSCH_proj.R")
future::plan("multisession")
mlr3resampling::proj_compute_all(proj.dir, verbose=TRUE)
mlr3resampling::proj_results(proj.dir)
mlr3resampling::proj_todo(proj.dir)

file.copy(
  file.path(proj.dir, "results.csv"),
  file.path("results", "2026-02-24", "NSCH_local_laptop.csv"))
file.copy(
  file.path("data_meta", "NSCH_autism.csv"),
  file.path("results", "2026-02-24", "meta.csv"))
