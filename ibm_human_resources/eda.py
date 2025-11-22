import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns   

hr = pd.read_csv('ibm_hr.csv')
hr.head()
hr.info()
hr.describe()
hr.columns


all_cols = hr.columns.tolist()
print(all_cols)
# ['Age', 'Attrition', 'BusinessTravel', 'DailyRate', 'Department', 'DistanceFromHome', \
# 'Education', 'EducationField', 'EmployeeCount', 'EmployeeNumber', 'EnvironmentSatisfaction', 'Gender', 'HourlyRate', 'JobInvolvement', \
# 'JobLevel', 'JobRole', 'JobSatisfaction', 'MaritalStatus', 'MonthlyIncome', 'MonthlyRate', 'NumCompaniesWorked', 'Over18', \
# 'OverTime', 'PercentSalaryHike', 'PerformanceRating', 'RelationshipSatisfaction', 'StandardHours', 'StockOptionLevel', 
# 'TotalWorkingYears', 'TrainingTimesLastYear', 'WorkLifeBalance', 'YearsAtCompany', 'YearsInCurrentRole', 'YearsSinceLastPromotion', 'YearsWithCurrManager']
hr.columns = [col.lower() for col in hr.columns]
all_cols = hr.columns.tolist()


int_cols = ['age', 'dailyrate', 'employeecount', 'employeenumber', 'hourlyrate', 'monthlyincome', 'monthlyrate', \
            'totalworkingyears', 'trainingtimeslastyear', 'yearsatcompany', 'yearsincurrentrole',
            'yearssincelastpromotion', 'yearswithcurrmanager']

cat_cols = list(set(all_cols) - set(int_cols))
print(cat_cols)
# ['overtime', 'joblevel', 'jobrole', 'standardhours', 'department', 'performancerating', 'stockoptionlevel', 'attrition', \
# 'educationfield', 'maritalstatus', 'percentsalaryhike', 'worklifebalance', 'employeenumber', 'jobinvolvement', 'businesstravel', 'distancefromhome', 'jobsatisfaction', 'environmentsatisfaction', 'gender', 'numcompaniesworked', 'education', 'relationshipsatisfaction', 'over18']
for col in int_cols:
    hr[col] = hr[col].astype('int64')

for col in cat_cols:
    hr[col] = hr[col].astype('category')

for col in cat_cols:
    print(f"Value counts for {col}:")
    print(hr[col].value_counts())
    print("\n")

## column 'Over18' has only 'Y' and 'StandardHours' and 'EmployeeCount' which only has 80 as value. Remove this colum as it does not give any more info
hr.drop(columns=['over18'], inplace=True)
hr.drop(columns=['standardhours'], inplace=True)
hr.drop(columns=['employeecount'], inplace=True)

## lowercase all column names

######################################
## Pairplot of variables to check comultinliearity problem
######################################
sns.pairplot(hr, hue='Attrition')


######################################
## A. Check for data quality issues: MIDOFI: missing values, invalid data, duplicates, outliers, format, and inconsistencies
######################################
# A - Missing values
hr.isnull().sum()
# no missing value found

# A - invalid data, all numeric columns have to be positive
for col in int_cols:
    if (hr[col] < 0).any():
        print(f"Invalid data found in column {col}.")
    else:
        print(f"All values in column {col} are positive.")
# no invalid data found


# A - duplicates
# employee number is unique identifier
duplicates = hr[hr.duplicated(subset=['employeenumber'], keep=False)]
duplicates.shape
# no duplicates found

# for ourliters, formats, and inconsistencies, I will check it while visualizing the data in Tableau because it is easier to spot outliers by that way
######################################
## Export cleaned data
hr.to_csv('ibm_hr_cleaned.csv', index=False)
######################################
# note, when loading these columns into tableau, change to dimension
# education
# environment satisfaction
# job involvement
# job level
# job satisfaction
# performance rating
# relationship satisfaction
# stock option level
# work life balance