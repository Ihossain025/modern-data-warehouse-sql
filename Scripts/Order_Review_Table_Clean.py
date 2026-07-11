import pandas as pd

# Define paths
csv_path = r"D:\Learning_and_Development\Weiterbildung_bei_Alfatraining\Data Engineer\Data_Engineer_Course\Data_Engineer_Course\Week_04_Final_Project\Dataset\archive\olist_order_reviews_dataset.csv"
clean_txt_path = csv_path.replace('.csv', '_cleaned.txt')

print("Starting data sanitization... Please wait.")

try:
    # Load the messy CSV
    df = pd.read_csv(csv_path, encoding='utf-8', na_filter=False)

    # Clean up the text fields by removing raw line breaks/carriage returns
    df['review_comment_title'] = df['review_comment_title'].astype(str).str.replace('\r', '').str.replace('\n', ' ')
    df['review_comment_message'] = df['review_comment_message'].astype(str).str.replace('\r', '').str.replace('\n', ' ')

    # Export as a Tab-Separated Values file (removes the comma-shifting conflict)
    df.to_csv(clean_txt_path, sep='\t', index=False, encoding='utf-8')
    print(" Success! Cleaned file generated perfectly at:")
    print(clean_txt_path)

except Exception as e:
    print(f"❌ Error: {e}")
