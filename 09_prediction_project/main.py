import pandas as pd
import numpy as np
from src.data_preprocessing import DataPreprocessor
from src.model_training import ModelTrainer
from src.prediction import Predictor
from src.evaluation import ModelEvaluator
import warnings
warnings.filterwarnings('ignore')

def main():
    # Configuration
    DATA_PATH = 'data/raw/mumbai_houses.csv'
    TARGET_COLUMN = 'price'  # Replace with your target column name
    PROBLEM_TYPE = 'regression'  # or 'classification'
    
    print("="*50)
    print("PREDICTION PIPELINE")
    print("="*50)
    
    # Step 1: Data Preprocessing
    print("\n📊 STEP 1: Data Preprocessing")
    preprocessor = DataPreprocessor()
    
    # Load data
    df = preprocessor.load_data(DATA_PATH)
    
    # Explore data
    preprocessor.explore_data(df)
    
    # Handle missing values
    df = preprocessor.handle_missing_values(df, strategy='mean')
    
    # Encode categorical variables
    df = preprocessor.encode_categorical(df)
    
    # Scale features
    df_scaled = preprocessor.scale_features(df, target_column=TARGET_COLUMN, scaler_type='standard')
    
    # Split data
    X_train, X_test, y_train, y_test = preprocessor.split_data(df_scaled, TARGET_COLUMN)
    
    # Save preprocessor
    preprocessor.save_preprocessor('models/preprocessor.pkl')
    
    # Step 2: Model Training
    print("\n🤖 STEP 2: Model Training")
    trainer = ModelTrainer(problem_type=PROBLEM_TYPE)
    
    # Train all models
    best_model, best_model_name, history = trainer.train_all_models(X_train, y_train, X_test, y_test)
    
    # Optional: Hyperparameter tuning
    print("\n🔧 Performing Hyperparameter Tuning...")
    tuned_model, best_params = trainer.hyperparameter_tuning(X_train, y_train, X_test, y_test, model_name=best_model_name)
    
    # Save best model
    trainer.save_model(tuned_model, 'models/best_model.pkl')
    
    # Step 3: Model Evaluation
    print("\n📈 STEP 3: Model Evaluation")
    evaluator = ModelEvaluator(tuned_model, X_test, y_test, problem_type=PROBLEM_TYPE)
    
    # Generate evaluation report
    report = evaluator.generate_report()
    print("\n=== Evaluation Report ===")
    for metric, value in report.items():
        if metric != 'classification_report':
            print(f"{metric}: {value:.4f}")
    
    # Plot results
    evaluator.plot_predictions()
    
    if PROBLEM_TYPE == 'regression':
        evaluator.plot_residuals()
    
    # Plot feature importance
    feature_names = X_train.columns.tolist()
    evaluator.plot_feature_importance(feature_names)
    
    # Step 4: Make Predictions
    print("\n🎯 STEP 4: Making Predictions")
    predictor = Predictor(
        model_path='models/best_model.pkl',
        preprocessor_path='models/preprocessor.pkl'
    )
    
    # Example: Single prediction
    sample_input = {
        'feature1': 25.5,
        'feature2': 100,
        'feature3': 'category_value',
        # Add all your features here
    }
    
    prediction = predictor.predict_single(sample_input)
    print(f"\nSample Prediction: {prediction}")
    
    # Example: Batch prediction
    batch_input = [
        {'feature1': 25.5, 'feature2': 100, 'feature3': 'category_value'},
        {'feature1': 30.2, 'feature2': 150, 'feature3': 'other_value'},
    ]
    
    batch_predictions = predictor.predict_batch(batch_input)
    print(f"\nBatch Predictions: {batch_predictions}")
    
    print("\n✅ Pipeline completed successfully!")

if __name__ == "__main__":
    main()