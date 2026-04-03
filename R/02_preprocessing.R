library(dplyr)

BASE <- "/Users/ridhimajoshi/Downloads/VIT Downloads/pds/ecg-arrhythmia-r"

# ── Read already-extracted feature matrix from data acquisition ──
feature_df <- readRDS(file.path(BASE, "data/dataset_features.rds"))

cat("Loaded feature matrix:", nrow(feature_df), "rows x",
    ncol(feature_df), "cols\n")
cat("First few columns:", paste(colnames(feature_df)[1:5], collapse = ", "), "\n")

# ── Load metadata ──
metadata <- read.csv(file.path(BASE, "data/metadata.csv"),
                     stringsAsFactors = FALSE)

cat("Metadata rows:", nrow(metadata), "\n")

# ── Clean metadata ──
# AHA_Code can be multi-value e.g. "22;23" — take first only
metadata_clean <- metadata %>%
  mutate(
    AHA_primary = as.integer(sapply(strsplit(AHA_Code, ";"), `[`, 1))
  ) %>%
  select(ECG_ID, AHA_primary, Age, Sex) %>%
  filter(!is.na(AHA_primary))

# ── Merge features with metadata ──
dataset <- feature_df %>%
  inner_join(metadata_clean, by = c("patient_id" = "ECG_ID"))

cat("After merge:", nrow(dataset), "rows\n")

# ── Remove NaN / Inf ──
dataset <- dataset %>%
  rename(
    AHA_primary = AHA_primary.y,
    Age = Age.y,
    Sex = Sex.y
  ) %>%
  select(-AHA_primary.x, -Age.x, -Sex.x)

cat("After cleaning:", nrow(dataset), "rows\n")

# ── Stage 1 label: Normal (AHA=1) vs Abnormal (everything else) ──
dataset <- dataset %>%
  mutate(
    label_binary = as.factor(ifelse(AHA_primary == 1, "Normal", "Abnormal"))
  )

# ── Stage 2 label: AHA code grouping ──
# Group AHA codes with fewer than 50 samples into code 999 (Other)
class_counts <- table(dataset$AHA_primary)
rare_codes   <- as.integer(names(class_counts[class_counts < 50]))

dataset <- dataset %>%
  mutate(
    AHA_grouped = as.factor(
      ifelse(AHA_primary %in% rare_codes, 999L, AHA_primary)
    )
  )

# ── Summary ──
cat("\nStage 1 — Binary label distribution:\n")
print(table(dataset$label_binary))

cat("\nStage 2 — Grouped AHA distribution (Abnormal only):\n")
abnormal_only <- dataset %>% filter(label_binary == "Abnormal")
print(sort(table(abnormal_only$AHA_grouped), decreasing = TRUE))

cat("\nTotal unique arrhythmia classes (Stage 2):",
    nlevels(abnormal_only$AHA_grouped), "\n")

# ── Save cleaned dataset ──
saveRDS(dataset, file.path(BASE, "data/dataset_clean.rds"))
message("Saved → data/dataset_clean.rds")