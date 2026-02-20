from flask import Flask, request, jsonify
import joblib
import pandas as pd
import numpy as np
from src.prediction import Predictor

app = Flask(__name__)

# Initialize predictor
predictor = Predictor(
    model_path='models/best_model.pkl',
    preprocessor_path='models/preprocessor.pkl'
)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'message': 'Prediction API is running'
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Make prediction"""
    try:
        # Get data from request
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Make prediction
        prediction = predictor.predict_single(data)
        
        # Convert numpy types to Python types
        if isinstance(prediction, np.generic):
            prediction = prediction.item()
        
        return jsonify({
            'success': True,
            'prediction': prediction,
            'message': 'Prediction successful'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/predict_batch', methods=['POST'])
def predict_batch():
    """Make batch predictions"""
    try:
        # Get data from request
        data = request.get_json()
        
        if not data or 'inputs' not in data:
            return jsonify({'error': 'No inputs provided'}), 400
        
        # Make predictions
        predictions = predictor.predict_batch(data['inputs'])
        
        # Convert numpy types to Python types
        predictions = [p.item() if isinstance(p, np.generic) else p for p in predictions]
        
        return jsonify({
            'success': True,
            'predictions': predictions,
            'count': len(predictions),
            'message': 'Batch prediction successful'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/model_info', methods=['GET'])
def model_info():
    """Get model information"""
    try:
        model = predictor.model
        
        info = {
            'model_type': type(model).__name__,
            'features': predictor.preprocessor['scaler'].feature_names_in_.tolist() if predictor.preprocessor else None,
            'is_classifier': hasattr(model, 'predict_proba')
        }
        
        return jsonify({
            'success': True,
            'model_info': info
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)