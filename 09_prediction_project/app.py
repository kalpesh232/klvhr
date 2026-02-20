import streamlit as st
import pandas as pd
import requests
import json
import plotly.graph_objects as go
import plotly.express as px

st.set_page_config(
    page_title="Prediction Platform",
    page_icon="🎯",
    layout="wide"
)

# Title
st.title("🎯 Machine Learning Prediction Platform")

# Sidebar
st.sidebar.header("Navigation")
page = st.sidebar.selectbox(
    "Choose a page",
    ["Make Predictions", "Batch Prediction", "Model Info", "Data Upload"]
)

# API endpoint
API_URL = "http://localhost:5000"

if page == "Make Predictions":
    st.header("Make Single Prediction")
    
    # Create input form based on model features
    st.subheader("Enter Features")
    
    # Try to get model info
    try:
        response = requests.get(f"{API_URL}/model_info")
        if response.status_code == 200:
            model_info = response.json()['model_info']
            features = model_info['features']
            
            # Create input fields dynamically
            col1, col2 = st.columns(2)
            input_data = {}
            
            for i, feature in enumerate(features):
                with col1 if i % 2 == 0 else col2:
                    input_data[feature] = st.number_input(
                        f"Enter {feature}",
                        value=0.0,
                        format="%.2f"
                    )
            
            # Make prediction button
            if st.button("Predict", type="primary"):
                with st.spinner("Making prediction..."):
                    response = requests.post(
                        f"{API_URL}/predict",
                        json=input_data
                    )
                    
                    if response.status_code == 200:
                        result = response.json()
                        
                        # Display prediction
                        st.success("Prediction successful!")
                        
                        # Create metric display
                        col1, col2, col3 = st.columns(3)
                        with col2:
                            st.metric(
                                label="Prediction Result",
                                value=f"{result['prediction']:.2f}"
                            )
                        
                        # Optional: Add visualization
                        fig = go.Figure()
                        fig.add_trace(go.Indicator(
                            mode = "number+delta",
                            value = result['prediction'],
                            title = {"text": "Predicted Value"},
                            delta = {'reference': 0}
                        ))
                        st.plotly_chart(fig)
                        
                    else:
                        st.error(f"Error: {response.json().get('error', 'Unknown error')}")
        else:
            st.warning("Could not fetch model info. Make sure the API is running.")
            
    except Exception as e:
        st.error(f"Error connecting to API: {str(e)}")
        st.info("Please make sure the prediction API is running on localhost:5000")

elif page == "Batch Prediction":
    st.header("Batch Prediction")
    
    st.subheader("Upload CSV File for Batch Prediction")
    
    uploaded_file = st.file_uploader("Choose a CSV file", type="csv")
    
    if uploaded_file is not None:
        # Preview data
        df = pd.read_csv(uploaded_file)
        st.write("Data Preview:")
        st.dataframe(df.head())
        
        if st.button("Run Batch Prediction", type="primary"):
            with st.spinner("Processing..."):
                # Convert dataframe to list of dicts
                inputs = df.to_dict('records')
                
                response = requests.post(
                    f"{API_URL}/predict_batch",
                    json={"inputs": inputs}
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    # Add predictions to dataframe
                    df['Prediction'] = result['predictions']
                    
                    # Display results
                    st.success(f"Batch prediction complete! {result['count']} predictions made.")
                    
                    # Show results
                    st.subheader("Results with Predictions")
                    st.dataframe(df)
                    
                    # Download button
                    csv = df.to_csv(index=False)
                    st.download_button(
                        label="Download Results as CSV",
                        data=csv,
                        file_name="predictions.csv",
                        mime="text/csv"
                    )
                    
                    # Visualization
                    st.subheader("Prediction Distribution")
                    fig = px.histogram(df, x='Prediction', nbins=30)
                    st.plotly_chart(fig)
                    
                else:
                    st.error(f"Error: {response.json().get('error', 'Unknown error')}")

elif page == "Model Info":
    st.header("Model Information")
    
    try:
        response = requests.get(f"{API_URL}/model_info")
        if response.status_code == 200:
            info = response.json()['model_info']
            
            # Display model info in cards
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.metric("Model Type", info['model_type'])
            
            with col2:
                st.metric("Number of Features", len(info['features']) if info['features'] else 0)
            
            with col3:
                st.metric("Problem Type", "Classification" if info['is_classifier'] else "Regression")
            
            # Display features
            st.subheader("Features Used by Model")
            if info['features']:
                features_df = pd.DataFrame({
                    'Feature Name': info['features'],
                    'Index': range(len(info['features']))
                })
                st.dataframe(features_df)
            else:
                st.info("No feature information available")
        else:
            st.error("Could not fetch model info")
            
    except Exception as e:
        st.error(f"Error connecting to API: {str(e)}")

elif page == "Data Upload":
    st.header("Upload Training Data")
    
    st.subheader("Upload New Dataset for Training")
    
    uploaded_file = st.file_uploader("Choose a CSV file", type="csv")
    
    if uploaded_file is not None:
        df = pd.read_csv(uploaded_file)
        
        st.write("Dataset Overview:")
        st.write(f"Shape: {df.shape[0]} rows, {df.shape[1]} columns")
        
        # Show data info
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Data Types")
            dtypes_df = pd.DataFrame({
                'Column': df.columns,
                'Data Type': df.dtypes.values
            })
            st.dataframe(dtypes_df)
        
        with col2:
            st.subheader("Missing Values")
            missing_df = pd.DataFrame({
                'Column': df.columns,
                'Missing Values': df.isnull().sum().values,
                'Percentage': (df.isnull().sum() / len(df) * 100).values
            })
            st.dataframe(missing_df)
        
        # Data preview
        st.subheader("Data Preview")
        st.dataframe(df.head())
        
        # Select target column
        target_column = st.selectbox("Select Target Column", df.columns)
        
        if st.button("Start Training", type="primary"):
            st.info("Training functionality would be implemented here")
            # You would call your training pipeline here