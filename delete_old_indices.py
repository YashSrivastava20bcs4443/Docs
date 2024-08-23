import requests
from datetime import datetime, timedelta
import urllib3

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Elasticsearch configuration
es_host = "https://192.168.31.191:9200"
es_user = "admin"
es_password = "yash2002"
index_prefix = "fortigate-logs-"

# Calculate the cutoff time for deletion (15 minutes ago from now)
cutoff_time = datetime.now() - timedelta(minutes=15)
cutoff_date_str = cutoff_time.strftime("%Y.%m.%d")
cutoff_time_str = cutoff_time.strftime("%H.%M")
print(f"Cutoff time for deletion: {cutoff_time}")

# Get the list of indices
response = requests.get(f"{es_host}/_cat/indices?v", auth=(es_user, es_password), verify=False)
indices = response.text.splitlines()

# Iterate through the indices and delete the ones older than 15 minutes
for index_line in indices:
    if index_prefix in index_line:
        index_name = index_line.split()[2].strip()  # Extracting the index name from the response
        index_date_str = index_name.replace(index_prefix, "")
        print(f"Processing index: {index_name} with date part: {index_date_str}")
        
        try:
            # Handle date-only indices
            if len(index_date_str.split(".")) == 3:  # YYYY.MM.DD format
                index_date = datetime.strptime(index_date_str, "%Y.%m.%d")
                if index_date_str < cutoff_date_str or (index_date_str == cutoff_date_str and "00.00" < cutoff_time_str):
                    print(f"Deleting index: {index_name}")
                    delete_response = requests.delete(f"{es_host}/{index_name}", auth=(es_user, es_password), verify=False)
                    if delete_response.status_code == 200:
                        print(f"Successfully deleted {index_name}")
                    else:
                        print(f"Failed to delete {index_name}: {delete_response.text}")
            else:
                print(f"Skipping index: {index_name}, not a date-based index")
        
        except ValueError as e:
            print(f"Failed to parse date for index: {index_name}. Error: {e}")
            continue
