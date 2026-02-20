import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier, GradientBoostingRegressor
from sklearn.svm import SVR, SVC
from sklearn.metrics import mean_squared_error, r2_score, accuracy_score, precision_score, recall_score, f1_score
import joblib
import os

class ModelTrainer:
    def __init__(self, problem_type='regression'):
        """
        problem_type: 'regression' or 'classification'
        """
        self.problem_type = problem_type
        self.model = None
        self.best_model = None
        self.training_history = {}
        
    def get_models(self):
        """Get available models based on problem type"""
        if self.problem_type == 'regression':
            models = {
                'Linear Regression': LinearRegression(),
                'Random Forest': RandomForestRegressor(n_estimators=100, random_state=42),
                'Gradient Boosting': GradientBoostingRegressor(n_estimators=100, random_state=42),
                'SVR': SVR(kernel='rbf')
            }
        else:  # classification
            models = {
                'Logistic Regression': LogisticRegression(random_state=42),
                'Random Forest': RandomForestClassifier(n_estimators=100, random_state=42),
                'SVC': SVC(kernel='rbf', random_state=42)
            }
        return models
    
    def train_model(self, model_name, X_train, y_train, X_test, y_test):
        """Train a specific model"""
        models = self.get_models()
        
        if model_name not in models:
            raise ValueError(f"Model {model_name} not available")
        
        model = models[model_name]
        
        # Train the model
        model.fit(X_train, y_train)
        
        # Make predictions
        y_pred_train = model.predict(X_train)
        y_pred_test = model.predict(X_test)
        
        # Evaluate
        if self.problem_type == 'regression':
            train_score = r2_score(y_train, y_pred_train)
            test_score = r2_score(y_test, y_pred_test)
            train_rmse = np.sqrt(mean_squared_error(y_train, y_pred_train))
            test_rmse = np.sqrt(mean_squared_error(y_test, y_pred_test))
            
            metrics = {
                'train_r2': train_score,
                'test_r2': test_score,
                'train_rmse': train_rmse,
                'test_rmse': test_rmse
            }
        else:  # classification
            train_accuracy = accuracy_score(y_train, y_pred_train)
            test_accuracy = accuracy_score(y_test, y_pred_test)
            precision = precision_score(y_test, y_pred_test, average='weighted')
            recall = recall_score(y_test, y_pred_test, average='weighted')
            f1 = f1_score(y_test, y_pred_test, average='weighted')
            
            metrics = {
                'train_accuracy': train_accuracy,
                'test_accuracy': test_accuracy,
                'precision': precision,
                'recall': recall,
                'f1_score': f1
            }
        
        self.training_history[model_name] = metrics
        print(f"\n=== {model_name} Results ===")
        for key, value in metrics.items():
            print(f"{key}: {value:.4f}")
        
        return model, metrics
    
    def train_all_models(self, X_train, y_train, X_test, y_test):
        """Train all available models and find the best one"""
        models = self.get_models()
        best_score = -np.inf
        best_model_name = None
        
        for model_name in models:
            print(f"\n--- Training {model_name} ---")
            model, metrics = self.train_model(model_name, X_train, y_train, X_test, y_test)
            
            # Determine best model based on appropriate metric
            if self.problem_type == 'regression':
                current_score = metrics['test_r2']
            else:
                current_score = metrics['test_accuracy']
            
            if current_score > best_score:
                best_score = current_score
                best_model_name = model_name
                self.best_model = model
        
        print(f"\n✅ Best Model: {best_model_name} with score: {best_score:.4f}")
        return self.best_model, best_model_name, self.training_history
    
    def hyperparameter_tuning(self, X_train, y_train, X_test, y_test, model_name='Random Forest'):
        """Simple hyperparameter tuning"""
        from sklearn.model_selection import GridSearchCV
        
        if self.problem_type == 'regression':
            if model_name == 'Random Forest':
                param_grid = {
                    'n_estimators': [50, 100, 200],
                    'max_depth': [None, 10, 20, 30],
                    'min_samples_split': [2, 5, 10]
                }
                base_model = RandomForestRegressor(random_state=42)
            elif model_name == 'Gradient Boosting':
                param_grid = {
                    'n_estimators': [50, 100, 200],
                    'learning_rate': [0.01, 0.1, 0.3],
                    'max_depth': [3, 5, 7]
                }
                base_model = GradientBoostingRegressor(random_state=42)
        else:  # classification
            if model_name == 'Random Forest':
                param_grid = {
                    'n_estimators': [50, 100, 200],
                    'max_depth': [None, 10, 20],
                    'min_samples_split': [2, 5, 10]
                }
                base_model = RandomForestClassifier(random_state=42)
        
        # Perform grid search
        grid_search = GridSearchCV(base_model, param_grid, cv=5, scoring='r2' if self.problem_type == 'regression' else 'accuracy')
        grid_search.fit(X_train, y_train)
        
        print(f"\n=== Best Parameters for {model_name} ===")
        print(grid_search.best_params_)
        print(f"Best Score: {grid_search.best_score_:.4f}")
        
        # Evaluate on test set
        y_pred = grid_search.predict(X_test)
        if self.problem_type == 'regression':
            test_score = r2_score(y_test, y_pred)
            print(f"Test R2 Score: {test_score:.4f}")
        else:
            test_score = accuracy_score(y_test, y_pred)
            print(f"Test Accuracy: {test_score:.4f}")
        
        return grid_search.best_estimator_, grid_search.best_params_
    
    def save_model(self, model, path='models/best_model.pkl'):
        """Save trained model"""
        joblib.dump(model, path)
        print(f"Model saved to {path}")
    
    def load_model(self, path='models/best_model.pkl'):
        """Load trained model"""
        self.model = joblib.load(path)
        print(f"Model loaded from {path}")
        return self.model