import requests
import json

# Replace with your OpenSearch endpoint
url = "http://localhost:9200/_mapping"

# Get the mapping of all indices
response = requests.get(url)  # Use basic authentication if needed

if response.status_code == 200:
    mappings = response.json()
    
    # A dictionary to track field types across indices
    field_types = {}

    # Traverse all indices and their fields
    for index, data in mappings.items():
        properties = data.get("mappings", {}).get("properties", {})
        
        for field, field_data in properties.items():
            field_type = field_data.get("type", "unknown")
            
            if field not in field_types:
                field_types[field] = set()
            
            field_types[field].add(field_type)

    # Check for conflicts
    conflicts = {field: types for field, types in field_types.items() if len(types) > 1}

    # Print conflicting fields
    if conflicts:
        print("Conflicting fields detected:")
        for field, types in conflicts.items():
            print(f"Field: {field}, Types: {', '.join(types)}")
    else:
        print("No conflicting fields found.")

else:
    print("Error fetching mappings:", response.status_code)

