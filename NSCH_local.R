source("NSCH_proj.R")
future::plan("multisession")
mlr3resampling::proj_compute_all(proj.dir, verbose=TRUE)

