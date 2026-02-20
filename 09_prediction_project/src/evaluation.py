import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from sklearn.metrics import confusion_matrix, roc_curve, auc
import pandas as pd

class ModelEvaluator:
    def __init__(self, model, X_test, y_test, problem_type='regression'):
        self.model = model
        self.X_test = X_test
        self.y_test = y_test
        self.problem_type = problem_type
        self.y_pred = model.predict(X_test)
        
    def plot_predictions(self):
        """Plot actual vs predicted values"""
        plt.figure(figsize=(10, 6))
        
        if self.problem_type == 'regression':
            plt.scatter(self.y_test, self.y_pred, alpha=0.5)
            plt.plot([self.y_test.min(), self.y_test.max()], 
                    [self.y_test.min(), self.y_test.max()], 'r--', lw=2)
            plt.xlabel('Actual Values')
            plt.ylabel('Predicted Values')
            plt.title('Actual vs Predicted Values')
        else:
            # For classification, create confusion matrix
            cm = confusion_matrix(self.y_test, self.y_pred)
            sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
            plt.xlabel('Predicted')
            plt.ylabel('Actual')
            plt.title('Confusion Matrix')
        
        plt.tight_layout()
        plt.show()
    
    def plot_feature_importance(self, feature_names):
        """Plot feature importance (for tree-based models)"""
        if hasattr(self.model, 'feature_importances_'):
            importances = self.model.feature_importances_
            indices = np.argsort(importances)[::-1]
            
            plt.figure(figsize=(10, 6))
            plt.title('Feature Importances')
            plt.bar(range(len(importances)), importances[indices])
            plt.xticks(range(len(importances)), 
                      [feature_names[i] for i in indices], rotation=45)
            plt.tight_layout()
            plt.show()
            
            # Print feature importance
            for i in range(len(importances)):
                print(f"{feature_names[indices[i]]}: {importances[indices[i]]:.4f}")
    
    def plot_residuals(self):
        """Plot residuals (for regression)"""
        if self.problem_type != 'regression':
            print("Residuals plot only available for regression")
            return
        
        residuals = self.y_test - self.y_pred
        
        fig, axes = plt.subplots(1, 2, figsize=(12, 5))
        
        # Residuals vs Predicted
        axes[0].scatter(self.y_pred, residuals, alpha=0.5)
        axes[0].axhline(y=0, color='r', linestyle='--')
        axes[0].set_xlabel('Predicted Values')
        axes[0].set_ylabel('Residuals')
        axes[0].set_title('Residuals vs Predicted')
        
        # Histogram of residuals
        axes[1].hist(residuals, bins=30, edgecolor='black')
        axes[1].set_xlabel('Residuals')
        axes[1].set_ylabel('Frequency')
        axes[1].set_title('Distribution of Residuals')
        
        plt.tight_layout()
        plt.show()
    
    def generate_report(self):
        """Generate comprehensive evaluation report"""
        from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
        
        report = {}
        
        if self.problem_type == 'regression':
            report['MAE'] = mean_absolute_error(self.y_test, self.y_pred)
            report['MSE'] = mean_squared_error(self.y_test, self.y_pred)
            report['RMSE'] = np.sqrt(report['MSE'])
            report['R2'] = r2_score(self.y_test, self.y_pred)
            
            # Calculate additional metrics
            report['MAPE'] = np.mean(np.abs((self.y_test - self.y_pred) / self.y_test)) * 100
            
        else:  # classification
            from sklearn.metrics import classification_report, accuracy_score, precision_recall_fscore_support
            
            report['accuracy'] = accuracy_score(self.y_test, self.y_pred)
            precision, recall, f1, _ = precision_recall_fscore_support(self.y_test, self.y_pred, average='weighted')
            report['precision'] = precision
            report['recall'] = recall
            report['f1_score'] = f1
            report['classification_report'] = classification_report(self.y_test, self.y_pred)
        
        return report