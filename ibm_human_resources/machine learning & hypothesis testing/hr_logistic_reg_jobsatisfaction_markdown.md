```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder, StandardScaler
import warnings
warnings.filterwarnings('ignore')

```


```python
# =============================================================================
# DATA PREPARATION FOR OLS REGRESSION
# =============================================================================
# Define predictors and target
predictors = [
    'environmentsatisfaction', 'jobinvolvement', 'overtime', 
    'worklifebalance', 'trainingtimeslastyear', 'yearssincelastpromotion',
    'yearsincurrentrole', 'yearswithcurrmanager', 'percentsalaryhike', 
    'distancefromhome'
]

target = 'jobsatisfaction'
```


```python
# Load your dataset (replace with your actual data loading)
dataset = pd.read_csv('ibm_hr_cleaned.csv', index_col=False)
dataset.shape # > 1470 x 32
```




    (1470, 32)




```python
# Prepare X and y
X = dataset[predictors]
y = dataset[target]

print(f"Dataset shape: {X.shape}")
print(f"Target variable: {target}")

```

    Dataset shape: (1470, 10)
    Target variable: jobsatisfaction
    


```python
# =============================================================================
# PREPROCESSING FOR MULTICLASS CLASSIFICATION
# =============================================================================

# Convert categorical variables to dummy variables
X_processed = X.copy()

# Identify categorical predictors
categorical_predictors = []
numeric_predictors = []

for predictor in predictors:
    if X_processed[predictor].dtype == 'object' or X_processed[predictor].nunique() <= 5:
        categorical_predictors.append(predictor)
    else:
        numeric_predictors.append(predictor)

print(f"\nCategorical predictors: {categorical_predictors}")
print(f"Numeric predictors: {numeric_predictors}")

# Create dummy variables for categorical predictors
if categorical_predictors:
    X_processed = pd.get_dummies(X_processed, columns=categorical_predictors, drop_first=True)

# Handle missing values
X_processed = X_processed.fillna(X_processed.mean())
y = y.fillna(y.mode()[0] if len(y.mode()) > 0 else y.mean())

print(f"Processed features shape: {X_processed.shape}")
```

    
    Categorical predictors: ['environmentsatisfaction', 'jobinvolvement', 'overtime', 'worklifebalance']
    Numeric predictors: ['trainingtimeslastyear', 'yearssincelastpromotion', 'yearsincurrentrole', 'yearswithcurrmanager', 'percentsalaryhike', 'distancefromhome']
    Processed features shape: (1470, 16)
    


```python
# =============================================================================
# TRAIN-TEST SPLIT
# =============================================================================

X_train, X_test, y_train, y_test = train_test_split(
    X_processed, y, test_size=0.3, random_state=42, stratify=y
)

print(f"\nTraining set: {X_train.shape}")
print(f"Testing set: {X_test.shape}")
print(f"Training target distribution:\n{y_train.value_counts().sort_index()}")

# Scale numeric features for better model performance
scaler = StandardScaler()
X_train_scaled = X_train.copy()
X_test_scaled = X_test.copy()

if numeric_predictors:
    # Scale only the numeric columns that remain after dummy encoding
    numeric_cols_remaining = [col for col in numeric_predictors if col in X_train.columns]
    if numeric_cols_remaining:
        X_train_scaled[numeric_cols_remaining] = scaler.fit_transform(X_train[numeric_cols_remaining])
        X_test_scaled[numeric_cols_remaining] = scaler.transform(X_test[numeric_cols_remaining])
```

    
    Training set: (1029, 16)
    Testing set: (441, 16)
    Training target distribution:
    jobsatisfaction
    1    202
    2    196
    3    310
    4    321
    Name: count, dtype: int64
    


```python
# =============================================================================
# APPROACH 1: MULTINOMIAL LOGISTIC REGRESSION
# =============================================================================

print("\n" + "="*60)
print("APPROACH 1: MULTINOMIAL LOGISTIC REGRESSION")
print("="*60)

# Multinomial Logistic Regression for multiclass classification
multinomial_lr = LogisticRegression(
    multi_class='multinomial',
    solver='lbfgs',
    max_iter=1000,
    random_state=42
)

multinomial_lr.fit(X_train_scaled, y_train)

# Predictions
y_pred_multinomial = multinomial_lr.predict(X_test_scaled)
y_pred_proba_multinomial = multinomial_lr.predict_proba(X_test_scaled)

# Evaluation
accuracy_multinomial = accuracy_score(y_test, y_pred_multinomial)

print(f"Multinomial Logistic Regression Accuracy: {accuracy_multinomial:.4f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred_multinomial))

```

    
    ============================================================
    APPROACH 1: MULTINOMIAL LOGISTIC REGRESSION
    ============================================================
    Multinomial Logistic Regression Accuracy: 0.3039
    
    Classification Report:
                  precision    recall  f1-score   support
    
               1       0.00      0.00      0.00        87
               2       0.25      0.04      0.06        84
               3       0.31      0.45      0.36       132
               4       0.31      0.52      0.39       138
    
        accuracy                           0.30       441
       macro avg       0.22      0.25      0.20       441
    weighted avg       0.24      0.30      0.24       441
    
    


```python

# =============================================================================
# APPROACH 2: RANDOM FOREST (NON-LINEAR RELATIONSHIPS)
# =============================================================================

print("\n" + "="*60)
print("APPROACH 2: RANDOM FOREST CLASSIFIER")
print("="*60)

rf_classifier = RandomForestClassifier(
    n_estimators=100,
    max_depth=10,
    random_state=42
)

rf_classifier.fit(X_train, y_train)  # No scaling needed for Random Forest

# Predictions
y_pred_rf = rf_classifier.predict(X_test)
y_pred_proba_rf = rf_classifier.predict_proba(X_test)

# Evaluation
accuracy_rf = accuracy_score(y_test, y_pred_rf)

print(f"Random Forest Accuracy: {accuracy_rf:.4f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred_rf))
```

    
    ============================================================
    APPROACH 2: RANDOM FOREST CLASSIFIER
    ============================================================
    Random Forest Accuracy: 0.2789
    
    Classification Report:
                  precision    recall  f1-score   support
    
               1       0.17      0.03      0.06        87
               2       0.15      0.05      0.07        84
               3       0.28      0.40      0.33       132
               4       0.30      0.46      0.36       138
    
        accuracy                           0.28       441
       macro avg       0.23      0.24      0.21       441
    weighted avg       0.24      0.28      0.24       441
    
    


```python
# =============================================================================
# APPROACH 3: ORDINAL LOGISTIC REGRESSION (IF SATISFACTION IS ORDINAL)
# =============================================================================

print("\n" + "="*60)
print("APPROACH 3: ORDINAL LOGISTIC REGRESSION")
print("="*60)

try:
    from sklearn.linear_model import LogisticRegression
    # Use one-vs-rest for ordinal classification
    ordinal_lr = LogisticRegression(
        multi_class='ovr',  # One-vs-Rest
        solver='liblinear',
        max_iter=1000,
        random_state=42
    )
    
    ordinal_lr.fit(X_train_scaled, y_train)
    y_pred_ordinal = ordinal_lr.predict(X_test_scaled)
    accuracy_ordinal = accuracy_score(y_test, y_pred_ordinal)
    
    print(f"Ordinal Logistic Regression (OvR) Accuracy: {accuracy_ordinal:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred_ordinal))
    
except Exception as e:
    print(f"Ordinal logistic regression failed: {e}")

```

    
    ============================================================
    APPROACH 3: ORDINAL LOGISTIC REGRESSION
    ============================================================
    Ordinal Logistic Regression (OvR) Accuracy: 0.2993
    
    Classification Report:
                  precision    recall  f1-score   support
    
               1       0.00      0.00      0.00        87
               2       0.11      0.01      0.02        84
               3       0.30      0.45      0.36       132
               4       0.31      0.52      0.39       138
    
        accuracy                           0.30       441
       macro avg       0.18      0.25      0.19       441
    weighted avg       0.21      0.30      0.23       441
    
    


```python
# =============================================================================
# MODEL COMPARISON
# =============================================================================

print("\n" + "="*60)
print("MODEL COMPARISON SUMMARY")
print("="*60)

models_comparison = pd.DataFrame({
    'Model': ['Multinomial Logistic Regression', 'Random Forest', 'Ordinal Logistic Regression (OvR)'],
    'Accuracy': [accuracy_multinomial, accuracy_rf, accuracy_ordinal]
})

print(models_comparison.sort_values('Accuracy', ascending=False))

# =============================================================================
# DETAILED ANALYSIS OF BEST MODEL
# =============================================================================

# Identify best model
best_model_name = models_comparison.loc[models_comparison['Accuracy'].idxmax(), 'Model']
print(f"\n🏆 BEST PERFORMING MODEL: {best_model_name}")

if best_model_name == 'Multinomial Logistic Regression':
    best_model = multinomial_lr
    y_pred_best = y_pred_multinomial
    y_proba_best = y_pred_proba_multinomial
elif best_model_name == 'Random Forest':
    best_model = rf_classifier
    y_pred_best = y_pred_rf
    y_proba_best = y_pred_proba_rf
else:
    best_model = ordinal_lr
    y_pred_best = y_pred_ordinal
    y_proba_best = ordinal_lr.predict_proba(X_test_scaled)
```

    
    ============================================================
    MODEL COMPARISON SUMMARY
    ============================================================
                                   Model  Accuracy
    0    Multinomial Logistic Regression  0.303855
    2  Ordinal Logistic Regression (OvR)  0.299320
    1                      Random Forest  0.278912
    
    🏆 BEST PERFORMING MODEL: Multinomial Logistic Regression
    


```python
# Get the coefficient of multinomial logistic regression

```


```python
# =============================================================================
# GET COEFFICIENTS FOR LOGISTIC REGRESSION MODELS
# =============================================================================
# 1. Multinomial Logistic Regression Coefficients

print("MULTINOMIAL LOGISTIC REGRESSION COEFFICIENTS")


if hasattr(multinomial_lr, 'coef_'):
    # Get the class labels
    classes = multinomial_lr.classes_
    
    # Create a DataFrame for coefficients
    coef_df_multinomial = pd.DataFrame(
        multinomial_lr.coef_,
        columns=X_train_scaled.columns,
        index=[f'Class_{cls}' for cls in classes]
    )
    
    print("Coefficients for each class (rows = classes, columns = features):")
    print(coef_df_multinomial)
    
    # Transpose for better readability (features as rows)
    print(f"\n{'='*40}")
    print("COEFFICIENTS BY FEATURE (Transposed)")
    print(f"{'='*40}")
    coef_transposed = coef_df_multinomial.T
    print(coef_transposed)
    
    # Get feature importance (average absolute coefficient across classes)
    print(f"\n{'='*40}")
    print("FEATURE IMPORTANCE (Average |Coefficient|)")
    print(f"{'='*40}")
    feature_importance = pd.DataFrame({
        'Feature': X_train_scaled.columns,
        'Avg_Abs_Coefficient': np.mean(np.abs(multinomial_lr.coef_), axis=0),
        'Max_Abs_Coefficient': np.max(np.abs(multinomial_lr.coef_), axis=0)
    }).sort_values('Avg_Abs_Coefficient', ascending=False)
    
    print(feature_importance.to_string(index=False))

# 2. Ordinal Logistic Regression (One-vs-Rest) Coefficients


if hasattr(ordinal_lr, 'coef_'):
    # Get the class labels
    classes_ordinal = ordinal_lr.classes_
    
    # Create a DataFrame for coefficients
    coef_df_ordinal = pd.DataFrame(
        ordinal_lr.coef_,
        columns=X_train_scaled.columns,
        index=[f'Class_{cls}_vs_Rest' for cls in classes_ordinal]
    )
    
    print("Coefficients for each One-vs-Rest model:")
    print(coef_df_ordinal)
    
    # Also show intercepts
    print(f"\nINTERCEPTS for each One-vs-Rest model:")
    intercept_df = pd.DataFrame({
        'Class': [f'Class_{cls}_vs_Rest' for cls in classes_ordinal],
        'Intercept': ordinal_lr.intercept_
    })
    print(intercept_df.to_string(index=False))

# =============================================================================
# INTERPRET COEFFICIENTS FOR BUSINESS INSIGHTS
# =============================================================================




# For Multinomial Logistic Regression
if hasattr(multinomial_lr, 'coef_'):
    print("\n📊 MULTINOMIAL LOGISTIC REGRESSION INSIGHTS:")
    
    # Analyze each feature's impact across classes
    for feature in X_train_scaled.columns[:5]:  # Show first 5 features
        feature_coefs = multinomial_lr.coef_[:, list(X_train_scaled.columns).index(feature)]
        
        print(f"\nFeature: {feature}")
        for i, cls in enumerate(multinomial_lr.classes_):
            coef = feature_coefs[i]
            effect = "INCREASES" if coef > 0 else "DECREASES"
            print(f"  - Class {cls}: {effect} probability (coef: {coef:.4f})")
        
        # Which class is most affected by this feature?
        max_impact_class = multinomial_lr.classes_[np.argmax(np.abs(feature_coefs))]
        print(f"  → Most affected: Class {max_impact_class}")

# For Ordinal Logistic Regression
if hasattr(ordinal_lr, 'coef_'):
    print(f"\n📊 ORDINAL LOGISTIC REGRESSION INSIGHTS (One-vs-Rest):")
    
    # Since it's One-vs-Rest, coefficients show effect vs all other classes
    for feature in X_train_scaled.columns[:5]:  # Show first 5 features
        print(f"\nFeature: {feature}")
        for i, cls in enumerate(ordinal_lr.classes_):
            coef = ordinal_lr.coef_[i, list(X_train_scaled.columns).index(feature)]
            effect = "INCREASES" if coef > 0 else "DECREASES"
            print(f"  - Class {cls} vs Rest: {effect} probability (coef: {coef:.4f})")

# =============================================================================
# EXPORT COEFFICIENTS TO CSV FOR FURTHER ANALYSIS
# =============================================================================


# Export Multinomial coefficients
if hasattr(multinomial_lr, 'coef_'):
    coef_df_multinomial.to_csv('multinomial_logistic_coefficients.csv')
    print("✓ Multinomial coefficients saved to 'multinomial_logistic_coefficients.csv'")

# Export Ordinal coefficients
if hasattr(ordinal_lr, 'coef_'):
    coef_df_ordinal.to_csv('ordinal_logistic_coefficients.csv')
    print("✓ Ordinal coefficients saved to 'ordinal_logistic_coefficients.csv'")

# =============================================================================
# VISUALIZE COEFFICIENTS
# =============================================================================

# Create visualization of top coefficients
plt.figure(figsize=(15, 10))

if hasattr(multinomial_lr, 'coef_'):
    # Get top 10 features by average absolute coefficient
    top_features = feature_importance.head(10)['Feature'].values
    
    # Create subplot for multinomial coefficients
    plt.subplot(2, 1, 1)
    
    # Plot coefficients for top features across all classes
    for i, feature in enumerate(top_features):
        feature_idx = list(X_train_scaled.columns).index(feature)
        coefficients = multinomial_lr.coef_[:, feature_idx]
        plt.bar(np.arange(len(coefficients)) + i*0.15, coefficients, width=0.15, label=feature)
    
    plt.xlabel('Classes')
    plt.ylabel('Coefficient Value')
    plt.title('Multinomial Logistic Regression - Top Feature Coefficients by Class')
    plt.xticks(np.arange(len(multinomial_lr.classes_)), [f'Class {cls}' for cls in multinomial_lr.classes_])
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, alpha=0.3)

if hasattr(ordinal_lr, 'coef_'):
    # Create subplot for ordinal coefficients
    plt.subplot(2, 1, 2)
    
    # Plot average absolute coefficients for ordinal model
    avg_abs_coef_ordinal = np.mean(np.abs(ordinal_lr.coef_), axis=0)
    top_features_ordinal_idx = np.argsort(avg_abs_coef_ordinal)[-10:][::-1]
    top_features_ordinal = X_train_scaled.columns[top_features_ordinal_idx]
    top_coef_ordinal = avg_abs_coef_ordinal[top_features_ordinal_idx]
    
    plt.barh(range(len(top_features_ordinal)), top_coef_ordinal)
    plt.yticks(range(len(top_features_ordinal)), top_features_ordinal)
    plt.xlabel('Average Absolute Coefficient')
    plt.title('Ordinal Logistic Regression - Top Feature Importances')
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

print("\n✅ All coefficients extracted and analyzed successfully!")
```

    MULTINOMIAL LOGISTIC REGRESSION COEFFICIENTS
    Coefficients for each class (rows = classes, columns = features):
             trainingtimeslastyear  yearssincelastpromotion  yearsincurrentrole  \
    Class_1               0.022421                 0.035395           -0.071751   
    Class_2               0.028845                 0.044813           -0.013174   
    Class_3              -0.061270                -0.045857            0.055537   
    Class_4               0.010003                -0.034350            0.029388   
    
             yearswithcurrmanager  percentsalaryhike  distancefromhome  \
    Class_1              0.101855           0.044338          0.029401   
    Class_2             -0.097714          -0.014928         -0.015655   
    Class_3             -0.044631          -0.088204         -0.008052   
    Class_4              0.040490           0.058795         -0.005694   
    
             environmentsatisfaction_2  environmentsatisfaction_3  \
    Class_1                   0.025552                   0.153598   
    Class_2                   0.033437                   0.024763   
    Class_3                  -0.096533                  -0.159107   
    Class_4                   0.037544                  -0.019254   
    
             environmentsatisfaction_4  jobinvolvement_2  jobinvolvement_3  \
    Class_1                  -0.106341         -0.117337         -0.028814   
    Class_2                   0.117067          0.441834          0.221711   
    Class_3                  -0.138757         -0.053937         -0.021839   
    Class_4                   0.128031         -0.270560         -0.171058   
    
             jobinvolvement_4  overtime_Yes  worklifebalance_2  worklifebalance_3  \
    Class_1          0.176612      0.051048          -0.064273          -0.098011   
    Class_2         -0.011665     -0.183099          -0.328618          -0.020244   
    Class_3          0.093964      0.045986           0.226384           0.155672   
    Class_4         -0.258912      0.086065           0.166506          -0.037416   
    
             worklifebalance_4  
    Class_1          -0.129774  
    Class_2           0.085874  
    Class_3           0.224818  
    Class_4          -0.180919  
    
    ========================================
    COEFFICIENTS BY FEATURE (Transposed)
    ========================================
                                Class_1   Class_2   Class_3   Class_4
    trainingtimeslastyear      0.022421  0.028845 -0.061270  0.010003
    yearssincelastpromotion    0.035395  0.044813 -0.045857 -0.034350
    yearsincurrentrole        -0.071751 -0.013174  0.055537  0.029388
    yearswithcurrmanager       0.101855 -0.097714 -0.044631  0.040490
    percentsalaryhike          0.044338 -0.014928 -0.088204  0.058795
    distancefromhome           0.029401 -0.015655 -0.008052 -0.005694
    environmentsatisfaction_2  0.025552  0.033437 -0.096533  0.037544
    environmentsatisfaction_3  0.153598  0.024763 -0.159107 -0.019254
    environmentsatisfaction_4 -0.106341  0.117067 -0.138757  0.128031
    jobinvolvement_2          -0.117337  0.441834 -0.053937 -0.270560
    jobinvolvement_3          -0.028814  0.221711 -0.021839 -0.171058
    jobinvolvement_4           0.176612 -0.011665  0.093964 -0.258912
    overtime_Yes               0.051048 -0.183099  0.045986  0.086065
    worklifebalance_2         -0.064273 -0.328618  0.226384  0.166506
    worklifebalance_3         -0.098011 -0.020244  0.155672 -0.037416
    worklifebalance_4         -0.129774  0.085874  0.224818 -0.180919
    
    ========================================
    FEATURE IMPORTANCE (Average |Coefficient|)
    ========================================
                      Feature  Avg_Abs_Coefficient  Max_Abs_Coefficient
             jobinvolvement_2             0.220917             0.441834
            worklifebalance_2             0.196445             0.328618
            worklifebalance_4             0.155346             0.224818
             jobinvolvement_4             0.135288             0.258912
    environmentsatisfaction_4             0.122549             0.138757
             jobinvolvement_3             0.110856             0.221711
                 overtime_Yes             0.091550             0.183099
    environmentsatisfaction_3             0.089180             0.159107
            worklifebalance_3             0.077836             0.155672
         yearswithcurrmanager             0.071172             0.101855
            percentsalaryhike             0.051566             0.088204
    environmentsatisfaction_2             0.048267             0.096533
           yearsincurrentrole             0.042462             0.071751
      yearssincelastpromotion             0.040104             0.045857
        trainingtimeslastyear             0.030635             0.061270
             distancefromhome             0.014700             0.029401
    Coefficients for each One-vs-Rest model:
                     trainingtimeslastyear  yearssincelastpromotion  \
    Class_1_vs_Rest               0.033115                 0.055245   
    Class_2_vs_Rest               0.041625                 0.063891   
    Class_3_vs_Rest              -0.079629                -0.053326   
    Class_4_vs_Rest               0.022256                -0.037564   
    
                     yearsincurrentrole  yearswithcurrmanager  percentsalaryhike  \
    Class_1_vs_Rest           -0.097793              0.122612           0.052996   
    Class_2_vs_Rest           -0.022341             -0.123376          -0.019900   
    Class_3_vs_Rest            0.067795             -0.066600          -0.125215   
    Class_4_vs_Rest            0.030611              0.055464           0.085979   
    
                     distancefromhome  environmentsatisfaction_2  \
    Class_1_vs_Rest          0.037841                   0.007520   
    Class_2_vs_Rest         -0.017545                   0.012394   
    Class_3_vs_Rest         -0.009693                  -0.139372   
    Class_4_vs_Rest         -0.006655                   0.048670   
    
                     environmentsatisfaction_3  environmentsatisfaction_4  \
    Class_1_vs_Rest                   0.187286                  -0.159694   
    Class_2_vs_Rest                   0.018371                   0.109583   
    Class_3_vs_Rest                  -0.211375                  -0.211917   
    Class_4_vs_Rest                  -0.016784                   0.170615   
    
                     jobinvolvement_2  jobinvolvement_3  jobinvolvement_4  \
    Class_1_vs_Rest         -0.194645         -0.100801          0.139875   
    Class_2_vs_Rest          0.433595          0.142429         -0.143000   
    Class_3_vs_Rest         -0.077241         -0.045295          0.095330   
    Class_4_vs_Rest         -0.352080         -0.226914         -0.376406   
    
                     overtime_Yes  worklifebalance_2  worklifebalance_3  \
    Class_1_vs_Rest      0.031511          -0.226801          -0.216576   
    Class_2_vs_Rest     -0.250998          -0.555373          -0.138968   
    Class_3_vs_Rest      0.035602           0.167393           0.126319   
    Class_4_vs_Rest      0.095856           0.143265          -0.095162   
    
                     worklifebalance_4  
    Class_1_vs_Rest          -0.249937  
    Class_2_vs_Rest           0.005930  
    Class_3_vs_Rest           0.227709  
    Class_4_vs_Rest          -0.287762  
    
    INTERCEPTS for each One-vs-Rest model:
              Class  Intercept
    Class_1_vs_Rest  -1.123599
    Class_2_vs_Rest  -1.413246
    Class_3_vs_Rest  -0.798949
    Class_4_vs_Rest  -0.565481
    
    📊 MULTINOMIAL LOGISTIC REGRESSION INSIGHTS:
    
    Feature: trainingtimeslastyear
      - Class 1: INCREASES probability (coef: 0.0224)
      - Class 2: INCREASES probability (coef: 0.0288)
      - Class 3: DECREASES probability (coef: -0.0613)
      - Class 4: INCREASES probability (coef: 0.0100)
      → Most affected: Class 3
    
    Feature: yearssincelastpromotion
      - Class 1: INCREASES probability (coef: 0.0354)
      - Class 2: INCREASES probability (coef: 0.0448)
      - Class 3: DECREASES probability (coef: -0.0459)
      - Class 4: DECREASES probability (coef: -0.0344)
      → Most affected: Class 3
    
    Feature: yearsincurrentrole
      - Class 1: DECREASES probability (coef: -0.0718)
      - Class 2: DECREASES probability (coef: -0.0132)
      - Class 3: INCREASES probability (coef: 0.0555)
      - Class 4: INCREASES probability (coef: 0.0294)
      → Most affected: Class 1
    
    Feature: yearswithcurrmanager
      - Class 1: INCREASES probability (coef: 0.1019)
      - Class 2: DECREASES probability (coef: -0.0977)
      - Class 3: DECREASES probability (coef: -0.0446)
      - Class 4: INCREASES probability (coef: 0.0405)
      → Most affected: Class 1
    
    Feature: percentsalaryhike
      - Class 1: INCREASES probability (coef: 0.0443)
      - Class 2: DECREASES probability (coef: -0.0149)
      - Class 3: DECREASES probability (coef: -0.0882)
      - Class 4: INCREASES probability (coef: 0.0588)
      → Most affected: Class 3
    
    📊 ORDINAL LOGISTIC REGRESSION INSIGHTS (One-vs-Rest):
    
    Feature: trainingtimeslastyear
      - Class 1 vs Rest: INCREASES probability (coef: 0.0331)
      - Class 2 vs Rest: INCREASES probability (coef: 0.0416)
      - Class 3 vs Rest: DECREASES probability (coef: -0.0796)
      - Class 4 vs Rest: INCREASES probability (coef: 0.0223)
    
    Feature: yearssincelastpromotion
      - Class 1 vs Rest: INCREASES probability (coef: 0.0552)
      - Class 2 vs Rest: INCREASES probability (coef: 0.0639)
      - Class 3 vs Rest: DECREASES probability (coef: -0.0533)
      - Class 4 vs Rest: DECREASES probability (coef: -0.0376)
    
    Feature: yearsincurrentrole
      - Class 1 vs Rest: DECREASES probability (coef: -0.0978)
      - Class 2 vs Rest: DECREASES probability (coef: -0.0223)
      - Class 3 vs Rest: INCREASES probability (coef: 0.0678)
      - Class 4 vs Rest: INCREASES probability (coef: 0.0306)
    
    Feature: yearswithcurrmanager
      - Class 1 vs Rest: INCREASES probability (coef: 0.1226)
      - Class 2 vs Rest: DECREASES probability (coef: -0.1234)
      - Class 3 vs Rest: DECREASES probability (coef: -0.0666)
      - Class 4 vs Rest: INCREASES probability (coef: 0.0555)
    
    Feature: percentsalaryhike
      - Class 1 vs Rest: INCREASES probability (coef: 0.0530)
      - Class 2 vs Rest: DECREASES probability (coef: -0.0199)
      - Class 3 vs Rest: DECREASES probability (coef: -0.1252)
      - Class 4 vs Rest: INCREASES probability (coef: 0.0860)
    ✓ Multinomial coefficients saved to 'multinomial_logistic_coefficients.csv'
    ✓ Ordinal coefficients saved to 'ordinal_logistic_coefficients.csv'
    


    
![png](output_11_1.png)
    


    
    ✅ All coefficients extracted and analyzed successfully!
    


```python

```


```python

```
