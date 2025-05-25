import requests
import json

# Define your OpenSearch URL
opensearch_url = "http://localhost:9200"

# Function to get all indices
def get_all_indices():
    url = f"{opensearch_url}/_cat/indices?h=index"
    response = requests.get(url)
    if response.status_code == 200:
        indices = response.text.strip().split("\n")
        return indices
    else:
        print(f"Error fetching indices: {response.status_code} - {response.text}")
        return []

# Function to create a new index (if necessary)
def create_new_index(index_name):
    url = f"{opensearch_url}/{index_name}"
    headers = {'Content-Type': 'application/json'}
    # Optionally, you can define mappings or settings here
    payload = {
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 1
        }
    }
    response = requests.put(url, headers=headers, data=json.dumps(payload))
    if response.status_code == 200:
        print(f"New index {index_name} created successfully.")
    else:
        print(f"Error creating index {index_name}: {response.status_code} - {response.text}")

# Function to perform the reindex operation with conflicts ignored
def reindex_with_ignore_conflicts(source_index, dest_index):
    url = f"{opensearch_url}/_reindex"  # Corrected query parameter
    headers = {'Content-Type': 'application/json'}
    payload = {
        "source": {
            "index": source_index
        },
        "dest": {
            "index": dest_index
        }
    }
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    if response.status_code == 200:
        print(f"Reindexing from {source_index} to {dest_index} completed successfully.")
    else:
        print(f"Error reindexing from {source_index} to {dest_index}: {response.status_code} - {response.text}")

def main():
    # Step 1: Get all the indices
    indices = get_all_indices()
    
    if not indices:
        print("No indices found.")
        return
    
    # Step 2: Create a new index (if necessary)
    new_index = "new_index_name"
    create_new_index(new_index)

    # Step 3: Reindex each index to the new one with conflict ignoring
    for index in indices:
        print(f"Reindexing {index} to {new_index}...")
        reindex_with_ignore_conflicts(index, new_index)

if __name__ == "__main__":
    main()

