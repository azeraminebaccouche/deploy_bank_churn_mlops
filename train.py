import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib

# Génération de données factices
np.random.seed(42)
n_samples = 1000
data = {
    'CreditScore': np.random.randint(300, 850, n_samples),
    'Age': np.random.randint(18, 80, n_samples),
    'Tenure': np.random.randint(0, 11, n_samples),
    'Balance': np.random.uniform(0, 200000, n_samples),
    'NumOfProducts': np.random.randint(1, 5, n_samples),
    'HasCrCard': np.random.choice([0, 1], n_samples),
    'IsActiveMember': np.random.choice([0, 1], n_samples),
    'EstimatedSalary': np.random.uniform(20000, 150000, n_samples),
    'Geography_Germany': np.random.choice([0, 1], n_samples),
    'Geography_Spain': np.random.choice([0, 1], n_samples),
    'Exited': np.random.choice([0, 1], n_samples)
}
df = pd.DataFrame(data)
X = df.drop('Exited', axis=1)
y = df['Exited']

# Entraînement
print("Entraînement du modèle en cours...")
model = RandomForestClassifier(n_estimators=50, max_depth=5)
model.fit(X, y)
joblib.dump(model, "model/churn_model.pkl")
print("✅ Modèle sauvegardé dans model/churn_model.pkl")
