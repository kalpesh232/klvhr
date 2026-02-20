import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder, MinMaxScaler
import joblib
import os

class DataPreprocessor:
    def __init__(self):
        self.scaler = None
        self.label_encoders = {}
        self.feature_columns = None
        
    def load_data(self, file_path):
        """Load data from CSV or Excel"""
        if file_path.endswith('.csv'):
            df = pd.read_csv(file_path)
        elif file_path.endswith('.xlsx'):
            df = pd.read_excel(file_path)
        else:
            raise ValueError("Unsupported file format")
        
        print(f"Data loaded: {df.shape[0]} rows, {df.shape[1]} columns")
        return df
    
    def explore_data(self, df):
        """Basic data exploration"""
        print("\n=== DATA INFO ===")
        print(df.info())
        
        print("\n=== MISSING VALUES ===")
        print(df.isnull().sum())
        
        print("\n=== BASIC STATISTICS ===")
        print(df.describe())
        
        print("\n=== DATA TYPES ===")
        print(df.dtypes)
        
        return {
            'shape': df.shape,
            'missing_values': df.isnull().sum().to_dict(),
            'dtypes': df.dtypes.to_dict()
        }
    
    def handle_missing_values(self, df, strategy='mean'):
        """Handle missing values in dataset"""
        df_clean = df.copy()
        
        for column in df_clean.columns:
            if df_clean[column].isnull().sum() > 0:
                if df_clean[column].dtype in ['int64', 'float64']:
                    if strategy == 'mean':
                        df_clean[column].fillna(df_clean[column].mean(), inplace=True)
                    elif strategy == 'median':
                        df_clean[column].fillna(df_clean[column].median(), inplace=True)
                    elif strategy == 'mode':
                        df_clean[column].fillna(df_clean[column].mode()[0], inplace=True)
                else:
                    # For categorical data, fill with mode
                    df_clean[column].fillna(df_clean[column].mode()[0], inplace=True)
        
        print(f"Missing values handled using {strategy} strategy")
        return df_clean
    
    def encode_categorical(self, df):
        """Encode categorical variables"""
        df_encoded = df.copy()
        
        for column in df_encoded.columns:
            if df_encoded[column].dtype == 'object':
                le = LabelEncoder()
                df_encoded[column] = le.fit_transform(df_encoded[column].astype(str))
                self.label_encoders[column] = le
                print(f"Encoded column: {column}")
        
        return df_encoded
    
    def scale_features(self, df, target_column=None, scaler_type='standard'):
        """Scale numerical features"""
        if target_column:
            features = df.drop(columns=[target_column])
            target = df[target_column]
        else:
            features = df
            target = None
        
        if scaler_type == 'standard':
            self.scaler = StandardScaler()
        elif scaler_type == 'minmax':
            self.scaler = MinMaxScaler()
        
        features_scaled = self.scaler.fit_transform(features)
        features_scaled = pd.DataFrame(features_scaled, columns=features.columns)
        
        if target is not None:
            features_scaled[target_column] = target.values
        
        print(f"Features scaled using {scaler_type} scaler")
        return features_scaled
    
    def split_data(self, df, target_column, test_size=0.2, random_state=42):
        """Split data into training and testing sets"""
        X = df.drop(columns=[target_column])
        y = df[target_column]
        
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state
        )
        
        print(f"Training set: {X_train.shape[0]} samples")
        print(f"Testing set: {X_test.shape[0]} samples")
        
        return X_train, X_test, y_train, y_test
    
    def save_preprocessor(self, path='models/preprocessor.pkl'):
        """Save preprocessor objects"""
        preprocessor_objects = {
            'scaler': self.scaler,
            'label_encoders': self.label_encoders
        }
        joblib.dump(preprocessor_objects, path)
        print(f"Preprocessor saved to {path}")
    
    def load_preprocessor(self, path='models/preprocessor.pkl'):
        """Load preprocessor objects"""
        preprocessor_objects = joblib.load(path)
        self.scaler = preprocessor_objects['scaler']
        self.label_encoders = preprocessor_objects['label_encoders']
        print(f"Preprocessor loaded from {path}")

    def prepare_mumbai_data(self, df):
        """Special handling for Mumbai house prices"""
        
        # Convert price from Crores to actual numbers
        df['price'] = df.apply(lambda row: 
            float(row['price']) * 10000000 if row['price_unit'] == 'Cr' 
            else float(row['price']), axis=1)
        
        # Convert area to float (remove any commas or symbols)
        df['area'] = pd.to_numeric(df['area'], errors='coerce')
        
        # Handle categorical columns
        categorical_cols = ['bhk', 'type', 'locality', 'region', 'status', 'age']
        for col in categorical_cols:
            if col in df.columns:
                # Convert to category codes
                df[col] = df[col].astype('category').cat.codes
        
        # Drop unnecessary columns
        df = df.drop(['price_unit'], axis=1)  # We already used this
        
        return df