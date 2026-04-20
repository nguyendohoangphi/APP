import pandas as pd

file_path = r'c:\Users\Administrator\AndroidStudioProjects\ai-engine\dataset.xlsx'
try:
    df = pd.read_excel(file_path)
    print(f"Total samples: {len(df)}")
    print("Columns:", df.columns.tolist())
    
    label_col = None
    for col in ['label', 'intent', 'Label', 'Intent']:
        if col in df.columns:
            label_col = col
            break
    if not label_col and len(df.columns) > 1:
        label_col = df.columns[1]
        
    if label_col:
        val_counts = df[label_col].value_counts()
        print("\nIntent distribution:")
        print(val_counts.to_string())
        
        print("\nNumber of unique intents:", df[label_col].nunique())
    
    print("\nNull values:")
    print(df.isnull().sum().to_string())
    
    print("\nDuplicated rows:")
    print(df.duplicated().sum())
    
    print("\nSample data:")
    print(df.head().to_string())
    
    # Check text length if text column exists
    text_col = None
    for col in ['text', 'sentence', 'input_text', 'query']:
        if col in df.columns:
            text_col = col
            break
    if not text_col and len(df.columns) > 0:
        text_col = df.columns[0]
        
    if text_col:
        df['word_count'] = df[text_col].astype(str).apply(lambda x: len(x.split()))
        print(f"\nAverage word count: {df['word_count'].mean():.2f}")
        print(f"Max word count: {df['word_count'].max()}")
        print(f"Min word count: {df['word_count'].min()}")
        
except Exception as e:
    print(f"Error reading excel file: {e}")
