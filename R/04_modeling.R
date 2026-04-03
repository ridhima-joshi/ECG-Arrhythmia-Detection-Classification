library(randomForest)
library(dplyr)

BASE    <- "/Users/ridhimajoshi/Downloads/VIT Downloads/pds/ecg-arrhythmia-r"
dataset <- readRDS(file.path(BASE, "data/dataset_clean.rds"))

dir.create(file.path(BASE, "outputs/model"), recursive = TRUE,
           showWarnings = FALSE)
dir.create(file.path(BASE, "powerbi"), showWarnings = FALSE)

feature_cols <- grep("^lead", colnames(dataset), value = TRUE)
X            <- as.matrix(dataset[, feature_cols])

# ── Train/test split ──
set.seed(42)
n         <- nrow(dataset)
train_idx <- sample(seq_len(n), size = floor(0.8 * n))
test_idx  <- setdiff(seq_len(n), train_idx)

X_train        <- X[train_idx, ]
X_test         <- X[test_idx,  ]
y_train_binary <- dataset$label_binary[train_idx]
y_test_binary  <- dataset$label_binary[test_idx]
y_train_aha    <- dataset$AHA_grouped[train_idx]
y_test_aha     <- dataset$AHA_grouped[test_idx]

cat("Train:", length(train_idx), "| Test:", length(test_idx), "\n")

# ── Helper: evaluation metrics ──
eval_binary <- function(actual, predicted) {
  cm        <- table(Predicted = predicted, Actual = actual)
  print(cm)
  TP <- cm["Abnormal", "Abnormal"]
  TN <- cm["Normal",   "Normal"]
  FP <- cm["Abnormal", "Normal"]
  FN <- cm["Normal",   "Abnormal"]
  accuracy  <- (TP + TN) / sum(cm)
  precision <- TP / (TP + FP)
  recall    <- TP / (TP + FN)
  f1        <- 2 * precision * recall / (precision + recall)
  cat("Accuracy: ", round(accuracy,  4), "\n")
  cat("Precision:", round(precision, 4), "\n")
  cat("Recall:   ", round(recall,    4), "\n")
  cat("F1 Score: ", round(f1,        4), "\n")
  list(accuracy = accuracy, precision = precision,
       recall = recall, f1 = f1)
}

# ══════════════════════════════════════════
# STAGE 1 — Normal vs Abnormal (binary RF)
# ══════════════════════════════════════════

cat("\n── Tuning Stage 1 RF (mtry) ──\n")
best_acc1  <- 0
best_mtry1 <- 8

for (m in c(4, 6, 8, 10, 12, 16)) {
  tmp <- randomForest(x = X_train, y = y_train_binary,
                      ntree = 200, mtry = m)
  acc <- mean(predict(tmp, X_test) == y_test_binary)
  cat("mtry =", m, "→", round(acc, 4), "\n")
  if (acc > best_acc1) { best_acc1 <- acc; best_mtry1 <- m }
}
cat("Best mtry:", best_mtry1, "\n")

# Class weights to handle imbalance
n_nor  <- sum(y_train_binary == "Normal")
n_ab   <- sum(y_train_binary == "Abnormal")
tot    <- length(y_train_binary)
cw     <- c(Normal = tot / (2 * n_nor), Abnormal = tot / (2 * n_ab))

set.seed(42)
message("\nTraining Stage 1 — Binary RF...")

rf_stage1 <- randomForest(
  x          = X_train,
  y          = y_train_binary,
  ntree      = 500,
  mtry       = best_mtry1,
  classwt    = cw,
  importance = TRUE
)

s1_preds <- predict(rf_stage1, X_test)

cat("\n── Stage 1 Results: Normal vs Abnormal ──\n")
s1_metrics <- eval_binary(y_test_binary, s1_preds)

# Feature importance
imp_df <- data.frame(
  feature    = rownames(importance(rf_stage1)),
  importance = importance(rf_stage1)[, "MeanDecreaseGini"]
) %>% arrange(desc(importance))
cat("\nTop 10 important features:\n")
print(head(imp_df, 10))

saveRDS(rf_stage1,
        file.path(BASE, "outputs/model/rf_stage1_binary.rds"))
message("Stage 1 model saved")

# ══════════════════════════════════════════
# STAGE 2 — Arrhythmia type (Abnormal only)
# ══════════════════════════════════════════

# Filter: only Abnormal samples for Stage 2
ab_train_idx <- which(y_train_binary == "Abnormal")
ab_test_idx  <- which(y_test_binary  == "Abnormal")

X_train_ab <- X_train[ab_train_idx, ]
X_test_ab  <- X_test[ab_test_idx,  ]
y_train_ab <- droplevels(y_train_aha[ab_train_idx])
y_test_ab  <- droplevels(y_test_aha[ab_test_idx])

cat("\n── Stage 2 setup ──\n")
cat("Abnormal train samples:", nrow(X_train_ab), "\n")
cat("Abnormal test samples: ", nrow(X_test_ab),  "\n")
cat("Arrhythmia classes:    ", nlevels(y_train_ab), "\n\n")

cat("Class distribution (training):\n")
print(sort(table(y_train_ab), decreasing = TRUE))

cat("\n── Tuning Stage 2 RF (mtry) ──\n")
best_acc2  <- 0
best_mtry2 <- 8

for (m in c(4, 6, 8, 10, 12)) {
  tmp2 <- randomForest(x = X_train_ab, y = y_train_ab,
                       ntree = 200, mtry = m)
  acc2 <- mean(predict(tmp2, X_test_ab) == y_test_ab)
  cat("mtry =", m, "→", round(acc2, 4), "\n")
  if (acc2 > best_acc2) { best_acc2 <- acc2; best_mtry2 <- m }
}
cat("Best mtry:", best_mtry2, "\n")

set.seed(42)
message("\nTraining Stage 2 — Multi-class RF (Abnormal only)...")

rf_stage2 <- randomForest(
  x          = X_train_ab,
  y          = y_train_ab,
  ntree      = 500,
  mtry       = best_mtry2,
  importance = TRUE
)

s2_preds <- predict(rf_stage2, X_test_ab)
s2_acc   <- mean(s2_preds == y_test_ab)

cat("\n── Stage 2 Results: Arrhythmia Type ──\n")
cat("Accuracy:", round(s2_acc, 4), "\n")
cat("RMSE (ordinal proxy):",
    round(sqrt(mean((as.integer(s2_preds) -
                       as.integer(y_test_ab))^2)), 4), "\n")
print(table(Predicted = s2_preds, Actual = y_test_ab))

saveRDS(rf_stage2,
        file.path(BASE, "outputs/model/rf_stage2_multiclass.rds"))
message("Stage 2 model saved")

# ══════════════════════════════════════════
# FULL PIPELINE EVALUATION
# ══════════════════════════════════════════

cat("\n── Full Pipeline (Stage 1 → Stage 2) ──\n")

# Ground truth: "Normal" or AHA group code
true_labels    <- ifelse(y_test_binary == "Normal",
                         "Normal",
                         as.character(y_test_aha))

# Start: predict everything as Normal
pipeline_preds <- rep("Normal", length(y_test_binary))

# For those predicted Abnormal by Stage 1 → run Stage 2
pred_ab_idx <- which(s1_preds == "Abnormal")
if (length(pred_ab_idx) > 0) {
  stage2_input  <- X_test[pred_ab_idx, , drop = FALSE]
  type_preds    <- predict(rf_stage2, stage2_input)
  pipeline_preds[pred_ab_idx] <- as.character(type_preds)
}

pipeline_acc <- mean(pipeline_preds == true_labels)
cat("End-to-end pipeline accuracy:", round(pipeline_acc, 4), "\n")

# ══════════════════════════════════════════
# EXPORT FOR POWER BI
# ══════════════════════════════════════════

results_df <- data.frame(
  Age              = dataset$Age[test_idx],
  Sex              = dataset$Sex[test_idx],
  AHA_primary      = dataset$AHA_primary[test_idx],
  AHA_grouped      = as.character(dataset$AHA_grouped[test_idx]),
  actual_binary    = as.character(y_test_binary),
  predicted_binary = as.character(s1_preds),
  correct_binary   = as.integer(y_test_binary == s1_preds),
  true_label       = true_labels,
  pipeline_pred    = pipeline_preds,
  correct_pipeline = as.integer(pipeline_preds == true_labels)
)

metrics_df <- data.frame(
  model    = c("RF Stage 1 — Normal vs Abnormal",
               "RF Stage 2 — Arrhythmia Type",
               "Full Pipeline — End to End"),
  accuracy = c(round(s1_metrics$accuracy, 4),
               round(s2_acc,              4),
               round(pipeline_acc,        4)),
  f1_score = c(round(s1_metrics$f1, 4), NA, NA),
  notes    = c("Binary classification",
               "Multi-class on Abnormal samples only",
               "Stage 1 → Stage 2 combined")
)

write.csv(results_df,
          file.path(BASE, "powerbi/ecg_results.csv"),
          row.names = FALSE)
write.csv(metrics_df,
          file.path(BASE, "powerbi/model_metrics.csv"),
          row.names = FALSE)

cat("\n── Final Model Summary ──\n")
print(metrics_df[, c("model", "accuracy", "f1_score")])
message("\nExported → powerbi/ecg_results.csv and model_metrics.csv")