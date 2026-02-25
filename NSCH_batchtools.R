source("NSCH.R")

reg.dir <- file.path(scratch.dir, "registry")
unlink(reg.dir, recursive=TRUE)
(class.bench.grid <- mlr3::benchmark_grid(
  task.list,
  class.learner.list,
  SOAK))
unlink(reg.dir, recursive=TRUE)
reg = batchtools::makeExperimentRegistry(
  file.dir = reg.dir,
  seed = 1)
mlr3batchmark::batchmark(
  class.bench.grid, store_models = TRUE, reg=reg)
(job.table <- batchtools::getJobTable(reg=reg))
chunks <- data.frame(job.table, chunk=1)
batchtools::submitJobs(chunks, resources=list(
  walltime = 1*60*60,#seconds
  memory = 3000,#megabytes per cpu
  ncpus=1,  #>1 for multicore/parallel jobs.
  ntasks=1, #>1 for MPI jobs.
  chunks.as.arrayjobs=TRUE), reg=reg)
## rorqual 7302694
reg <- batchtools::loadRegistry(reg.dir)
bmr = mlr3batchmark::reduceResultsBatchmark(
  reg = reg, store_backends = FALSE)
out.RData <- paste0(reg.dir, ".RData")
save(bmr, file=out.RData)
score_dt <- mlr3resampling::score(bmr, mlr3::msrs(c("classif.auc", "classif.acc")))
out.csv <- paste0(reg.dir, "_scores.csv")
fwrite(score_dt[, .SD, .SDcols=is.atomic], out.csv)
file.copy(
  out.csv,
  file.path("results", "2026-02-24", "NSCH_batchtools.csv"))

(job.table <- batchtools::getJobTable(reg=reg))
job.table[, learner_id := sapply(algo.pars, "[[", "learner_id")]
job.csv <- paste0(reg.dir, "_jobs.csv")
fwrite(job.table[, .SD, .SDcols=is.atomic], job.csv)
file.copy(
  job.csv,
  file.path("results", "2026-02-24", "NSCH_batchtools_jobs.csv"),
  overwrite = TRUE)

