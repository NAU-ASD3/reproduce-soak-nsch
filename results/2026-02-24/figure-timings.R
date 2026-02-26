library(data.table)
library(ggplot2)
seq_dt <- fread("NSCH_local.csv")
laptop_dt <- fread("NSCH_local_laptop.csv")
desktop_dt <- fread("NSCH_local_desktop.csv")
proj_dt <- fread("NSCH_mpi.csv")
mpi_dt <- proj_dt[, .(
  cpus=length(unique(process))+1, host="rorqual", pkg="mlr3resampling",
  started=start.time, done=end.time, learner_id, job.id=process, row=.I)]
reg_dt <- fread("NSCH_batchtools_jobs.csv")
sec_all_dt <- rbind(
  laptop_dt[, .(
    cpus=length(unique(process)), host="laptop", pkg="mlr3resampling",
    started=start.time, done=end.time, learner_id, job.id=as.integer(factor(process)), row=.I)],
  desktop_dt[, .(
    cpus=length(unique(process)), host="desktop", pkg="mlr3resampling",
    started=start.time, done=end.time, learner_id, job.id=as.integer(factor(process)), row=.I)],
  seq_dt[, .(
    cpus=6, host="desktop-rep", pkg="mlr3resampling",
    started=start.time, done=end.time, learner_id, job.id=.I, row=.I)],
  reg_dt[, .(
    cpus=.N, host="rorqual", pkg="mlr3batchmark",
    started, done, learner_id, job.id, row=.I)],
  mpi_dt)

unit_all_dt <- nc::capture_melt_single(
  sec_all_dt,
  time="started|done",
  value.name="POSIXct"
)[
, seconds := as.numeric(POSIXct-min(POSIXct)), by=.(pkg,cpus,host)
][
, minutes := seconds/60
][
, hours := minutes/60
]
all_dt <- dcast(
  unit_all_dt,
  cpus+host+pkg+learner_id+job.id+row ~ time,
  value.var=c("seconds","minutes","hours"))

blank_dt <- data.table(mpi_dt[1], x=0, y=21)
compare_dt <- all_dt[host!="desktop-rep"]
gg <- ggplot()+
  facet_grid(cpus+pkg+host~., labeller=label_both, scales="free")+
  scale_y_continuous(
    "process",
    breaks=c(1,seq(10, 100, by=10)))+
  scale_x_continuous(
    "Minutes from start of computation (train + test cv_glmnet learner on NSCH_data)")+
  geom_segment(aes(
    minutes_started, job.id,
    xend=minutes_done, yend=job.id),
    data=compare_dt)+
  geom_point(aes(
    minutes_started, job.id),
    shape=21,
    fill="white",
    data=compare_dt)+
  geom_blank(aes(x,y),data=blank_dt)
png(
  "figure-timings.png",
  width=8, height=5.5, units="in", res=200)
print(gg)
dev.off()

desktop_dt <- all_dt[grep("desktop", host)]
gg <- ggplot()+
  facet_grid(cpus+pkg+host~., labeller=label_both, scales="free")+
  scale_y_continuous(
    "Train/test split",
    breaks=c(1,seq(10, 100, by=10)))+
  scale_x_continuous(
    "Minutes from start of computation (train + test cv_glmnet learner on NSCH_data)",
    breaks=seq(0, 100, by=10))+
  geom_segment(aes(
    minutes_started, row,
    xend=minutes_done, yend=row),
    data=desktop_dt)+
  geom_point(aes(
    minutes_started, row),
    shape=21,
    fill="white",
    data=desktop_dt)
png(
  "figure-timings-desktop.png",
  width=8, height=3, units="in", res=200)
print(gg)
dev.off()
