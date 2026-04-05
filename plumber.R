library(plumber)
library(randomForest)
library(jsonlite)

# Load trained models
rf_stage1 <- readRDS("outputs/model/rf_stage1_binary.rds")
rf_stage2 <- readRDS("outputs/model/rf_stage2_multiclass.rds")


# Health check
#* @get /
#* @serializer json
function() {
  list(status = "ECG Arrhythmia API running successfully")
}


# Prediction endpoint
#* @post /predict
#* @serializer json
#* @param body:list ECG feature vector
function(body){
  
  tryCatch({
    
    input <- as.data.frame(body)
    
    required_cols <- rownames(rf_stage1$importance)
    
    missing_cols <- setdiff(required_cols, colnames(input))
    
    if(length(missing_cols) > 0){
      stop(paste("Missing columns:", paste(missing_cols, collapse=", ")))
    }
    
    input <- input[, required_cols, drop = FALSE]
    
    stage1 <- predict(rf_stage1, input)
    
    if(stage1 == "Normal"){
      return(list(prediction = "Normal ECG"))
    }
    
    stage2 <- predict(rf_stage2, input)
    
    list(
      prediction = "Abnormal ECG",
      arrhythmia_type = as.character(stage2)
    )
    
  }, error=function(e){
    
    list(
      error = "Prediction failed",
      message = e$message
    )
    
  })
}
