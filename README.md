# 🫀 Multi-level ECG Analysis: Detection and Multi-class Classification of Arrhythmia

## 📌 Project Overview

Electrocardiogram (ECG) interpretation is a complex and specialized task that requires expert cardiological knowledge. This project presents a **machine learning–based, multi-level ECG analysis pipeline** that assists in the automated detection and classification of cardiac arrhythmias.

The system is designed as a **two-stage diagnostic framework**:

1. **Detection Stage** – Screens ECG records to distinguish between **Normal** and **Abnormal** heart rhythms.
2. **Classification Stage** – Further classifies abnormal ECGs into **specific arrhythmia categories**.

The primary goal is to support cardiologists by reducing diagnostic workload and enabling faster screening in emergency or remote healthcare settings.

---

## 🎯 Objectives

* Detect the presence of cardiac arrhythmia from ECG data
* Classify abnormal ECG signals into one of **15 arrhythmia types**
* Identify the most influential ECG leads and signal features
* Build an interpretable and clinically meaningful ML pipeline

---

## 📊 Dataset Information

* **Source:** UCI Machine Learning Repository – Arrhythmia Dataset
* **Instances:** 452 patient records
* **Features:** 279 attributes

  * Demographic features (age, sex, height, weight)
  * ECG temporal intervals (PR, QRS, QT, T)
  * Morphological and amplitude features across 12 ECG leads (DI, DII, DIII, AVR, AVL, AVF, V1–V6)
* **Target Classes:** 16

  * Class 1: Normal
  * Classes 2–15: Specific arrhythmias
  * Class 16: Unclassified arrhythmia
* **Missing Values:** Represented using `?`
* **Final Format:** Cleaned multivariate CSV (schema reconstructed from `.names` file)

---

## 🧠 Methodology

### 🔹 Stage 1: Arrhythmia Detection (Binary Classification)

* **Task:** Normal vs Abnormal ECG
* **Purpose:** Rapid screening to flag potentially risky cases
* **Classes:**

  * Normal → Class 1
  * Abnormal → Classes 2–16

### 🔹 Stage 2: Arrhythmia Classification (Multi-class)

* **Task:** Identify the specific arrhythmia type
* **Classes:** 15 medical arrhythmia categories
* **Models Used:**

  * Random Forest
  * XGBoost / Gradient Boosting

### 🔹 Diagnostic & Interpretability Analysis

* Feature importance analysis
* ECG lead–wise contribution study (V1–V6)
* Identification of critical ECG intervals and morphology features

---

## 🛠️ Tech Stack

* **Programming Language:** Python
* **Libraries:**

  * pandas, numpy
  * scikit-learn
  * XGBoost
  * matplotlib, seaborn
* **Platform:** Google Colab / Jupyter Notebook

---

## 📁 Repository Structure

```
ECG-Arrhythmia-Detection-Classification/
│
├── data/
│   ├── raw/                 # Original .data and .names files
│   └── processed/           # Cleaned CSV with headers
│
├── notebooks/
│   ├── 01_eda.ipynb
│   ├── 02_preprocessing.ipynb
│   ├── 03_detection_model.ipynb
│   └── 04_classification_model.ipynb
│
├── src/                     # Utility scripts (if applicable)
├── results/                 # Model outputs and plots
├── README.md
└── requirements.txt
```

---

## 📈 Evaluation Metrics

* Binary Detection:

  * Accuracy
  * Precision, Recall
  * ROC-AUC

* Multi-class Classification:

  * Accuracy
  * Macro / Weighted F1-score
  * Confusion Matrix

Special attention is given to **class imbalance**, which is significant in this dataset.

---

## 👥 Collaborators

* **Ridhima Joshi**
* **Archi Garg**

---

## 🚀 Future Work

* Deep learning models (CNN/LSTM) on ECG signals
* Cost-sensitive learning for rare arrhythmia classes
* Deployment as a clinical decision support tool
* Integration with real-time ECG acquisition systems

---

## ⚠️ Disclaimer

This project is intended for **academic and research purposes only**. It is not a certified medical diagnostic system and should not be used for clinical decision-making without professional validation.

---

## ⭐ Acknowledgements

* UCI Machine Learning Repository
* Original dataset contributors: H. Altay Guvenir et al.

If you find this project useful, feel free to ⭐ the repository.
