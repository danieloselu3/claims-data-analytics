import os
import json
import requests
from typing import Dict, List, Optional, Any
from google.cloud import storage
from datetime import datetime
import logging
import time

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class APIDataExtractor:
    """
    A class to extract data from APIs with pagination and upload to Google Cloud Storage
    """
    def __init__(self, 
                 bucket_name: Optional[str] = None, 
                 credentials_path: Optional[str] = None):
        """
        Initialize the API Data Extractor
        
        :param bucket_name: Google Cloud Storage bucket name
        :param credentials_path: Path to Google Cloud credentials JSON file
        """
        # Set credentials if provided
        if credentials_path:
            os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path
        
        # Initialize GCS client
        self.storage_client = storage.Client() if bucket_name else None
        self.bucket_name = bucket_name

    def fetch_paginated_data(self, base_url: str, limit: int = 30, delay: float = 0.5) -> List[Dict[str, Any]]:
        """
        Fetch all data from a paginated API endpoint
        
        :param base_url: Base API endpoint URL
        :param limit: Number of items per page (default 30 for DummyJSON)
        :param delay: Delay between requests to avoid rate limiting
        :return: List of all items from all pages
        """
        all_items = []
        skip = 0
        total_fetched = 0

        while True:
            try:
                # Construct URL with pagination parameters
                url = f"{base_url}?limit={limit}&skip={skip}"
                response = requests.get(url)
                response.raise_for_status()
                
                # Parse response
                data = response.json()
                
                # Extract items (adjust key based on API structure)
                if 'products' in data:
                    items = data['products']
                elif 'users' in data:
                    items = data['users']
                elif 'carts' in data:
                    items = data['carts']
                else:
                    items = data.get('data', [])
                
                # Break if no more items
                if not items:
                    break
                
                # Add items to total list
                all_items.extend(items)
                total_fetched += len(items)
                
                # Check if we've fetched all items
                total = data.get('total', 0)
                if total_fetched >= total:
                    break
                
                # Prepare for next page
                skip += limit
                
                # Add small delay to avoid potential rate limiting
                time.sleep(delay)
                
                logger.info(f"Fetched {total_fetched} items so far")
                
            except requests.RequestException as e:
                logger.error(f"Error fetching data from {url}: {e}")
                break
        
        logger.info(f"Total items fetched: {total_fetched}")
        return all_items

    def save_to_gcs(self, 
                    data: List[Dict], 
                    filename: str, 
                    content_type: str = 'application/json') -> bool:
        """
        Save data to Google Cloud Storage
        
        :param data: Data to be saved
        :param filename: Name of the file to save
        :param content_type: Content type of the file
        :return: Boolean indicating success of upload
        """
        if not self.storage_client:
            logger.warning("GCS client not initialized. Skipping cloud storage upload.")
            return False
        
        try:
            bucket = self.storage_client.bucket(self.bucket_name)
            blob = bucket.blob(filename)
            
            # Serialize data to JSON string
            json_data = json.dumps(data, indent=2)
            
            # Upload the blob
            blob.upload_from_string(json_data, content_type=content_type)
            logger.info(f"Successfully uploaded {filename} to {self.bucket_name}")
            return True
        except Exception as e:
            logger.error(f"Error uploading to GCS: {e}")
            return False

    def extract_and_save(self, 
                          apis: List[Dict[str, str]], 
                          prefix: Optional[str] = None) -> None:
        """
        Extract data from multiple APIs and save to GCS
        
        :param apis: List of dictionaries with 'url' and 'name' keys
        :param prefix: Optional prefix for filename (e.g., date)
        """
        # Use current timestamp if no prefix provided
        if prefix is None:
            prefix = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        for api in apis:
            try:
                # Fetch all data with pagination
                data = self.fetch_paginated_data(api['url'])
                
                # Generate filename
                filename = f"{prefix}_{api['name']}_full.json"
                
                # Save to GCS
                self.save_to_gcs(data, filename)
            
            except Exception as e:
                logger.error(f"Error processing {api['name']}: {e}")

def main():
    # List of APIs to extract (full base URLs)
    apis_to_extract = [
        {"url": "https://dummyjson.com/carts", "name": "carts"},
        {"url": "https://dummyjson.com/users", "name": "users"},
        {"url": "https://dummyjson.com/products", "name": "products"}
    ]

    # Initialize extractor (provide your GCS bucket name and credentials path)
    extractor = APIDataExtractor(
        bucket_name='danieloselu-ecommerce-trial-bkt'
    )

    # Extract and save data
    extractor.extract_and_save(apis_to_extract)

if __name__ == "__main__":
    main()

# Additional requirements (to be installed):
# pip install requests google-cloud-storage
"""
Key Changes and Pagination Handling:
1. Added fetch_paginated_data method to handle pagination
2. Uses 'limit' and 'skip' parameters to fetch all items
3. Detects total number of items from API response
4. Adds small delay between requests to avoid rate limiting
5. Flexible parsing of different API response structures
6. Saves full dataset instead of just first page

Prerequisites:
1. Install required libraries: 
   pip install requests google-cloud-storage
2. Set up Google Cloud credentials:
   - Create a service account in Google Cloud Console
   - Download the JSON key file
   - Set the path to this file in the script or set GOOGLE_APPLICATION_CREDENTIALS env var
3. Replace 'your-gcs-bucket-name' with your actual GCS bucket name
"""