🫀 Multi-level ECG Analysis: Detection and Multi-class Classification of Arrhythmia
📌 Project Overview

Electrocardiogram (ECG) interpretation is a complex clinical task requiring specialized cardiological expertise. This project presents a machine learning–based multi-level ECG analysis pipeline for automated detection and classification of cardiac arrhythmias using standardized diagnostic ECG labels.

The system is designed as a two-stage diagnostic framework:

Detection Stage – Classifies ECG signals as Normal or Abnormal
Classification Stage – Categorizes abnormal ECGs into clinically meaningful diagnostic groups

The goal is to support cardiologists by enabling faster screening and improving interpretability through data-driven insights and visualization.

🎯 Objectives
Detect the presence of cardiac arrhythmia from ECG data
Classify ECG signals using standardized diagnostic labels
Identify influential ECG-derived diagnostic features
Build an interpretable and clinically meaningful ML pipeline
Visualize prediction insights using an interactive Power BI dashboard
📊 Dataset Information
Source: PTB-XL ECG Dataset
Provider: Springer Nature Figshare Repository
Dataset Link:
https://springernature.figshare.com/collections/A_large-scale_multi-label_12-lead_electrocardiogram_database_with_standardized_diagnostic_statements/5779802/1
Dataset Description

The dataset contains 12-lead ECG recordings with standardized cardiologist-verified diagnostic annotations.

Key characteristics:

Multi-label ECG classification dataset
Includes demographic attributes (Age, Sex)
Contains diagnostic superclass labels (AHA grouped categories)
Includes binary abnormality indicators
Provides clinically structured rhythm annotations
Suitable for arrhythmia detection pipelines
🧠 Methodology
🔹 Stage 1: Arrhythmia Detection (Binary Classification)

Task: Detect whether ECG signals are Normal or Abnormal

Purpose:

Enable rapid screening
Identify potentially risky ECG cases
Reduce cardiologist workload

Class mapping:

Normal → No abnormality detected
Abnormal → Any diagnostic abnormal ECG pattern

Models used:

Random Forest
Gradient Boosting / XGBoost
🔹 Stage 2: Diagnostic Classification (Multi-class)

Task: Identify ECG diagnostic superclass labels

Classes derived from standardized PTB-XL annotations such as:

Myocardial Infarction
ST/T Changes
Conduction Disturbance
Hypertrophy
Normal ECG patterns

Models used:

Random Forest
XGBoost
🔹 Diagnostic & Interpretability Analysis

To improve interpretability:

Feature importance analysis performed
Diagnostic superclass contribution evaluated
Demographic feature influence analyzed
Binary prediction correctness examined

These steps help explain prediction behavior in clinically meaningful terms.

📊 Power BI Dashboard

An interactive Power BI dashboard was developed to visualize model performance and classification insights.

Key Visualizations Included
Model Accuracy KPI card
Confusion Matrix (R visual)
Feature Importance plot (R visual)
Prediction vs Actual comparison chart
Class Distribution visualization
Interactive filters for Age and Sex
Total Records summary card

Dashboard file:

powerbi/ecg_dashboard.pbix

This dashboard improves interpretability and enables quick exploratory analysis of classification outcomes.

🛠️ Tech Stack
Programming Language
Python
Libraries Used
pandas
numpy
scikit-learn
XGBoost
matplotlib
seaborn
Visualization Tools
Power BI
R (used inside Power BI for confusion matrix & feature importance visuals)
Platform
Google Colab
Jupyter Notebook
📁 Repository Structure
ECG-Arrhythmia-Detection-Classification/
│
├── data/
│   ├── raw/                 # Original PTB-XL dataset files
│   └── processed/           # Cleaned CSV dataset
│
├── notebooks/
│   ├── 01_eda.ipynb
│   ├── 02_preprocessing.ipynb
│   ├── 03_detection_model.ipynb
│   └── 04_classification_model.ipynb
│
├── results/                 # Model outputs and plots
│
├── powerbi/
│   └── ecg_dashboard.pbix   # Interactive visualization dashboard
│
├── src/                     # Utility scripts (if applicable)
│
├── README.md
└── requirements.txt
📈 Evaluation Metrics
Binary Detection Performance
Accuracy
Precision
Recall
ROC-AUC Score
Multi-class Classification Performance
Accuracy
Macro F1-score
Weighted F1-score
Confusion Matrix

Special attention is given to class imbalance, which is common in ECG diagnostic datasets.

👥 Collaborators
Ridhima Joshi
Archi Garg
🚀 Future Work

Potential improvements include:

Applying deep learning models (CNN / LSTM) on ECG waveform signals
Implementing cost-sensitive learning for rare diagnostic classes
Deploying as a clinical decision-support web application
Integrating with real-time ECG acquisition pipelines
⚠️ Disclaimer

This project is intended for academic and research purposes only. It is not a certified medical diagnostic system and should not be used for clinical decision-making without professional validation.

⭐ Acknowledgements
Springer Nature Figshare (PTB-XL dataset contributors)
Original dataset authors: Wagner et al.

If you find this project useful, consider giving it a ⭐ on GitHub.