source("NSCH.R")

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

