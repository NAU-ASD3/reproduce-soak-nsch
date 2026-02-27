source("NSCH.R")
today <- strftime(Sys.time(), "%Y-%m-%d")
result.dir <- file.path("results", today)
dir.create(result.dir, showWarnings = FALSE, recursive = TRUE)

R.scripts <- Sys.glob("results/2026-02-24/*R")
file.copy(R.scripts, result.dir)

file.copy(
  file.path("data_meta", "NSCH_autism.csv"),
  file.path(result.dir, "meta.csv"))

## To run after NSCH_local.R or NSCH_mpi.R is done.
file.copy(
  file.path(proj.dir, "results.csv"),
  file.path(result.dir, "NSCH_proj.csv"))

## To run after NSCH_batchtools.R calculations are done.
reg <- batchtools::loadRegistry(reg.dir)
bmr = mlr3batchmark::reduceResultsBatchmark(
  reg = reg, store_backends = FALSE)
out.RData <- paste0(reg.dir, ".RData")
save(bmr, file=out.RData)
score_dt <- mlr3resampling::score(bmr, mlr3::msrs(c("classif.auc", "classif.acc")))
fwrite(score_dt[, .SD, .SDcols=is.atomic], out.csv)
(job.table <- batchtools::getJobTable(reg=reg))
job.table[, learner_id := sapply(algo.pars, "[[", "learner_id")]
fwrite(job.table[, .SD, .SDcols=is.atomic], job.csv)
file.copy(
  out.csv,
  file.path(result.dir, "NSCH_batchtools.csv"))
file.copy(
  job.csv,
  file.path(result.dir, "NSCH_batchtools_jobs.csv"),
  overwrite = TRUE)

