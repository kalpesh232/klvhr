import pandas as pd
import numpy as np
import joblib

class Predictor:
    def __init__(self, model_path=None, preprocessor_path=None):
        self.model = None
        self.preprocessor = None
        
        if model_path:
            self.load_model(model_path)
        if preprocessor_path:
            self.load_preprocessor(preprocessor_path)
    
    def load_model(self, path):
        """Load trained model"""
        self.model = joblib.load(path)
        print(f"Model loaded from {path}")
    
    def load_preprocessor(self, path):
        """Load preprocessor objects"""
        self.preprocessor = joblib.load(path)
        print(f"Preprocessor loaded from {path}")
    
    def preprocess_input(self, input_data):
        """Preprocess single input or batch of inputs"""
        if isinstance(input_data, dict):
            # Single prediction
            df = pd.DataFrame([input_data])
        elif isinstance(input_data, list):
            if isinstance(input_data[0], dict):
                # Multiple predictions as list of dicts
                df = pd.DataFrame(input_data)
            else:
                # Single prediction as list of values
                df = pd.DataFrame([input_data])
        elif isinstance(input_data, pd.DataFrame):
            df = input_data
        else:
            raise ValueError("Input format not supported")
        
        # Apply preprocessing
        if self.preprocessor:
            # Apply label encoding if needed
            if 'label_encoders' in self.preprocessor:
                for column, encoder in self.preprocessor['label_encoders'].items():
                    if column in df.columns:
                        df[column] = encoder.transform(df[column].astype(str))
            
            # Apply scaling
            if 'scaler' in self.preprocessor:
                scaled_data = self.preprocessor['scaler'].transform(df)
                df = pd.DataFrame(scaled_data, columns=df.columns)
        
        return df
    
    def predict_single(self, input_data):
        """Make prediction for single input"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        # Preprocess input
        processed_data = self.preprocess_input(input_data)
        
        # Make prediction
        prediction = self.model.predict(processed_data)
        
        return prediction[0]
    
    def predict_batch(self, input_data):
        """Make predictions for batch of inputs"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        # Preprocess input
        processed_data = self.preprocess_input(input_data)
        
        # Make predictions
        predictions = self.model.predict(processed_data)
        
        return predictions
    
    def predict_with_probability(self, input_data):
        """Get prediction probabilities (for classification)"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        if not hasattr(self.model, 'predict_proba'):
            raise ValueError("Model does not support probability prediction")
        
        # Preprocess input
        processed_data = self.preprocess_input(input_data)
        
        # Get probabilities
        probabilities = self.model.predict_proba(processed_data)
        
        return probabilities