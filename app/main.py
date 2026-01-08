from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd

app = FastAPI()
# Chargement du modèle
model = joblib.load("model/churn_model.pkl")

class Customer(BaseModel):
    CreditScore: int
    Age: int
    Tenure: int
    Balance: float
    NumOfProducts: int
    HasCrCard: int
    IsActiveMember: int
    EstimatedSalary: float
    Geography_Germany: int
    Geography_Spain: int

@app.get("/")
def root():
    return {"message": "API Bank Churn est en ligne !"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/predict")
def predict(data: Customer):
    df = pd.DataFrame([data.model_dump()])
    proba = model.predict_proba(df)[0][1]
    return {"churn_probability": float(proba), "risk": "High" if proba > 0.5 else "Low"}
