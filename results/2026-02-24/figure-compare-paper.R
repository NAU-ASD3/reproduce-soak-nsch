library(data.table)
library(ggplot2)
if(!file.exists("data_Classif_batchmark_registry.csv")){
  download.file("https://raw.githubusercontent.com/tdhock/cv-same-other-paper/refs/heads/main/data_Classif_batchmark_registry.csv", "data_Classif_batchmark_registry.csv")
}
orig_dt <- fread("data_Classif_batchmark_registry.csv")[
  task_id=="NSCH_autism" & algorithm=="cv_glmnet"]
new_dt <- fread("NSCH_batchtools.csv")

compare_dt <- rbind(
  orig_dt[, .(
    results="original",
    task_id, algorithm,
    train.subsets=train.groups, test.subset=test.group, test.fold,
    classif.auc, Accuracy=1-classif.ce)],
  new_dt[, .(
    results="reproduced",
    task_id, algorithm,
    train.subsets, test.subset, test.fold,
    classif.auc, Accuracy=classif.acc)]
)[, let(
  test=test.subset,
  train=train.subsets,
  AUC=classif.auc,
  Percent_error=(1-Accuracy)*100
)][]

ures <- sort(unique(compare_dt$results))
yfac <- function(x)factor(x, rev(c(
  #"",
  ures)))
compare_dt[, Results := yfac(results)]
measure.vars <- c("Accuracy","AUC","Percent_error")

res_dt <- compare_dt[results=="reproduced" & train.subsets!="other"]
plist <- mlr3resampling::pvalue(res_dt, value.var="Percent_error")
gg <- plot(plist)
out.png <- "figure-compare-paper-reproduce-figure5.png"
png(out.png, width=8, height=2.5, units="in", res=200)
print(gg)
dev.off()

p_dt_list <- list()
for(res in ures){
  res_dt <- compare_dt[results==res]
  plist <- mlr3resampling::pvalue(res_dt, value.var="Percent_error")
  for(data_type in c("stats","pvalues")){
    p_dt_list[[data_type]][[res]] <- data.table(results=res, plist[[data_type]])
  }
}
p_dts <- lapply(p_dt_list, rbindlist)
gg <- mlr3resampling:::plot.pvalue(p_dts, text.size=4)+
  facet_grid(
    results ~ test.subset,
    labeller=label_both,
    scales="free")+
  scale_x_continuous("Percent prediction error on test set (mean±SD, 10-fold CV)")
out.png <- "figure-compare-paper-pvalues.png"
png(out.png, width=8, height=4, units="in", res=200)
print(gg)
dev.off()

compare_long <- melt(compare_dt, measure.vars=measure.vars)
compare_stats_long <- dcast(
  compare_long,
  Results+train+test+variable~.,
  list(mean,sd,length))
compare_wide <- dcast(
  compare_long,
  train+test+test.fold+variable~Results)
all_test_dt <- compare_wide[, {
  tlist <- t.test(original, reproduced, paired=TRUE)
  with(tlist, data.table(p.value, N=.N))
}, by=.(train, test, variable)]

for(eval_metric in measure.vars){
  compare_stats <- compare_stats_long[variable==eval_metric]
  test_dt <- all_test_dt[variable==eval_metric]
  gg <- ggplot()+
    theme_bw()+
    theme(panel.spacing.x=grid::unit(2, "lines"))+
    test_dt[, ggtitle(sprintf("No significant differences between original and reproduced: %s\n(different train/test splits, different random subtrain/validation splits)\nP-value range: %.2f–%.2f", eval_metric, min(p.value), max(p.value)))]+
    geom_point(aes(
      value_mean, Results),
      data=compare_stats)+
    geom_text(aes(
      value_mean, Results, label=sprintf(
        "%.4f±%.4f", value_mean, value_sd)),
      vjust=-0.5,
      size=3,
      data=compare_stats)+
    geom_segment(aes(
      value_mean+value_sd, Results,
      xend=value_mean-value_sd, yend=Results),
      data=compare_stats)+
    scale_y_discrete(
      "Results",
      drop=FALSE)+
    scale_x_continuous(sprintf(
      "%s for cv_glmnet predictions on test subset (mean±SD over 10 folds in CV)", eval_metric))+
    facet_grid(train~test, scales="free", labeller=label_both)
  out.png <- sprintf("figure-compare-paper-%s.png", eval_metric)
  png(out.png, width=8, height=3.5, units="in", res=200)
  print(gg)
  dev.off()
}
