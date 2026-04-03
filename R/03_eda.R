library(ggplot2)
library(dplyr)
library(tidyr)
library(corrplot)

BASE    <- "/Users/ridhimajoshi/Downloads/VIT Downloads/pds/ecg-arrhythmia-r"
PLOTS   <- file.path(BASE, "outputs/plots")
dataset <- readRDS(file.path(BASE, "data/dataset_clean.rds"))

dir.create(PLOTS, recursive = TRUE, showWarnings = FALSE)

# ── BASIC DATA INSPECTION ──
cat("══ BASIC DATA INSPECTION ══\n")

cat("\nStructure of dataset:\n")
str(dataset)

cat("\nSummary of dataset:\n")
print(summary(dataset))

cat("\nMissing values per column:\n")
print(colSums(is.na(dataset)))

# ── Printed summary stats (mandatory for QP) ──
cat("══ Summary Statistics ══\n")
cat("Total records: ", nrow(dataset), "\n")
cat("Features:      ", length(grep("^lead", colnames(dataset))), "\n\n")

cat("Binary class distribution:\n")
print(table(dataset$label_binary))
cat("\nProportions:\n")
print(round(prop.table(table(dataset$label_binary)), 3))

cat("\nAge summary:\n")
print(summary(dataset$Age))

cat("\nSex distribution:\n")
print(table(dataset$Sex))

cat("\nTop 10 AHA codes:\n")
print(sort(table(dataset$AHA_primary), decreasing = TRUE)[1:10])

cat("\nCorrelation — lead1_mean vs lead2_mean:",
    round(cor(dataset$lead1_mean, dataset$lead2_mean), 3), "\n")

feature_cols <- grep("^lead", colnames(dataset), value = TRUE)
sds          <- sapply(dataset[, feature_cols], sd)
cat("\nTop 5 highest variance features:\n")
print(sort(sds, decreasing = TRUE)[1:5])

# ── Plot 1: Normal vs Abnormal class distribution ──
p1 <- ggplot(dataset, aes(x = label_binary, fill = label_binary)) +
  geom_bar(width = 0.5) +
  geom_text(stat = "count", aes(label = ..count..), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("Abnormal" = "#E05C3A", "Normal" = "#2E86AB")) +
  labs(title = "Normal vs Abnormal ECG distribution (n=15,000)",
       x = "Class", y = "Count") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")

ggsave(file.path(PLOTS, "plot1_class_distribution.png"),
       p1, width = 6, height = 4, dpi = 150)
message("Plot 1 saved")

# ── Plot 2: Top 15 AHA arrhythmia codes ──
top_codes <- dataset %>%
  filter(label_binary == "Abnormal") %>%
  count(AHA_primary) %>%
  arrange(desc(n)) %>%
  slice(1:15) %>%
  mutate(AHA_label = paste0("AHA-", AHA_primary))

p2 <- ggplot(top_codes,
             aes(x = reorder(AHA_label, n), y = n, fill = n)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
  scale_fill_gradient(low = "#AED9E0", high = "#1B4F72") +
  coord_flip() +
  labs(title = "Top 15 arrhythmia types in Abnormal ECGs (n=15,000)",
       x = "AHA Code", y = "Count") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")

ggsave(file.path(PLOTS, "plot2_aha_distribution.png"),
       p2, width = 7, height = 5, dpi = 150)
message("Plot 2 saved")

# ── Plot 3: Lead mean amplitude boxplot — Normal vs Abnormal ──
mean_cols <- paste0("lead", 1:12, "_mean")

box_data <- dataset %>%
  select(label_binary, all_of(mean_cols)) %>%
  pivot_longer(-label_binary,
               names_to  = "lead",
               values_to = "mean_amplitude") %>%
  mutate(lead = gsub("_mean", "", lead))

p3 <- ggplot(box_data,
             aes(x = lead, y = mean_amplitude, fill = label_binary)) +
  geom_boxplot(outlier.size = 0.3, alpha = 0.8) +
  scale_fill_manual(values = c("Abnormal" = "#E05C3A",
                               "Normal"   = "#2E86AB")) +
  labs(title = "Mean ECG amplitude per lead — Normal vs Abnormal",
       x = "Lead", y = "Mean amplitude (mV)", fill = "Class") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(PLOTS, "plot3_lead_boxplot.png"),
       p3, width = 10, height = 5, dpi = 150)
message("Plot 3 saved")

# ── Plot 4: Correlation heatmap ──
cor_cols   <- c(paste0("lead", 1:12, "_mean"),
                paste0("lead", 1:12, "_sd"))
cor_matrix <- cor(dataset[, cor_cols], use = "complete.obs")

png(file.path(PLOTS, "plot4_correlation_heatmap.png"),
    width = 900, height = 800, res = 120)
corrplot(cor_matrix,
         method = "color",
         type   = "upper",
         tl.cex = 0.65,
         tl.col = "black",
         col    = colorRampPalette(c("#1B4F72", "white", "#A93226"))(200),
         title  = "Correlation — lead mean & SD features (n=15,000)",
         mar    = c(0, 0, 2, 0))
dev.off()
message("Plot 4 saved")

# ── Plot 5: Age distribution by class ──
p5 <- ggplot(dataset, aes(x = Age, fill = label_binary)) +
  geom_histogram(binwidth = 5, alpha = 0.7,
                 position = "identity", color = "white") +
  scale_fill_manual(values = c("Abnormal" = "#E05C3A",
                               "Normal"   = "#2E86AB")) +
  labs(title = "Age distribution by ECG class (n=15,000)",
       x = "Age (years)", y = "Count", fill = "Class") +
  theme_minimal(base_size = 13)

ggsave(file.path(PLOTS, "plot5_age_distribution.png"),
       p5, width = 7, height = 4, dpi = 150)
message("Plot 5 saved")

message("\nAll 5 plots saved to ", PLOTS)