library(rhdf5)
library(googledrive)
library(dplyr)
library(moments)

# ── Get full file listing from Drive (paginated API calls) ──
message("Fetching file list from Google Drive...")
ecg_folder  <- drive_ls(path = "records", pattern = "\\.h5$")
files_15k   <- ecg_folder[1:15000, ]
message("Total files to process: ", nrow(files_15k))

# ── Feature extraction function ──
extract_features <- function(filepath) {
  ecg_matrix <- h5read(filepath, "/ecg")
  patient_id <- tools::file_path_sans_ext(basename(filepath))
  features   <- c(patient_id = patient_id)
  
  for (lead in 1:12) {
    signal <- ecg_matrix[, lead]
    signal <- signal[is.finite(signal)]
    pfx    <- paste0("lead", lead, "_")
    features[paste0(pfx, "mean")] <- mean(signal)
    features[paste0(pfx, "sd")]   <- sd(signal)
    features[paste0(pfx, "min")]  <- min(signal)
    features[paste0(pfx, "max")]  <- max(signal)
    features[paste0(pfx, "skew")] <- skewness(signal)
    features[paste0(pfx, "kurt")] <- kurtosis(signal)
  }
  return(features)
}

# ── Main loop: download → extract → delete ──
tmp_dir      <- tempdir()   # OS temp folder, auto-cleaned
feature_list <- vector("list", nrow(files_15k))
failed       <- c()

message("Starting stream processing...")

for (i in seq_len(nrow(files_15k))) {
  tmp_path <- file.path(tmp_dir, files_15k$name[i])
  
  tryCatch({
    # 1. Download via API
    drive_download(
      file      = as_id(files_15k$id[i]),
      path      = tmp_path,
      overwrite = TRUE
    )
    
    # 2. Extract features
    feature_list[[i]] <- extract_features(tmp_path)
    
    # 3. Delete immediately to save disk space
    file.remove(tmp_path)
    
  }, error = function(e) {
    failed <<- c(failed, files_15k$name[i])
    if (file.exists(tmp_path)) file.remove(tmp_path)
  })
  
  # Progress every 500 files
  if (i %% 500 == 0) {
    message(i, " / ", nrow(files_15k), " done | failed: ", length(failed))
  }
}

message("Done! Failed files: ", length(failed))

# ── Build feature dataframe ──
feature_df <- bind_rows(lapply(
  Filter(Negate(is.null), feature_list),
  function(x) as.data.frame(t(x))
))
feature_df <- feature_df %>%
  mutate(across(-patient_id, as.numeric))

message("Feature matrix: ", nrow(feature_df), " rows x ", ncol(feature_df), " cols")

# ── Merge with metadata ──
metadata <- read.csv("/Users/ridhimajoshi/Downloads/VIT Downloads/pds/ecg-arrhythmia-r/data_new/metadata.csv", stringsAsFactors = FALSE)

metadata_clean <- metadata %>%
  mutate(AHA_primary = as.integer(sapply(strsplit(AHA_Code, ";"), `[`, 1))) %>%
  select(ECG_ID, AHA_primary, Age, Sex)

dataset <- feature_df %>%
  inner_join(metadata_clean, by = c("patient_id" = "ECG_ID")) %>%
  mutate(across(where(is.numeric), ~ ifelse(is.infinite(.), NA, .))) %>%
  na.omit()

# ── Group rare AHA codes (< 50 samples) into "Other" ──
class_counts  <- table(dataset$AHA_primary)
rare_codes    <- as.integer(names(class_counts[class_counts < 50]))

dataset <- dataset %>%
  mutate(
    AHA_grouped  = ifelse(AHA_primary %in% rare_codes, 999L, AHA_primary),
    label_binary = as.factor(ifelse(AHA_primary == 1, "Normal", "Abnormal")),
    label_multi  = as.integer(as.factor(AHA_grouped)) - 1L
  )

cat("\nBinary distribution:\n");  print(table(dataset$label_binary))
cat("\nGrouped AHA distribution:\n"); print(table(dataset$AHA_grouped))

# ── Save ──
saveRDS(dataset, "/Users/ridhimajoshi/Downloads/VIT Downloads/pds/ecg-arrhythmia-r/data_new/dataset_features.rds")
message("Saved → data_new/dataset_features.rds")