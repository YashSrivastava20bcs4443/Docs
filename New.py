import requests
import csv
import json

def fetch_fortigate_policies(base_url, api_token):
    try:
        # Set the headers for the API request
        headers = {
            'Authorization': f'Bearer {api_token}'
        }

        # Define the endpoint URL for fetching firewall policies
        endpoint = f'{base_url}/api/v2/cmdb/firewall/policy/'

        # Send the GET request to the FortiGate API
        response = requests.get(endpoint, headers=headers, verify=False)

        # Check if the request was successful
        if response.status_code == 200:
            policies = response.json()
            return policies['results']
        else:
            print(f"Failed to fetch policies: {response.status_code} - {response.text}")
            return None

    except Exception as e:
        print(f"An error occurred: {e}")
        return None

def save_policies_to_csv(policies, filename):
    try:
        # Define the CSV headers
        if policies:
            keys = policies[0].keys()
            with open(filename, 'w', newline='') as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=keys)
                writer.writeheader()
                writer.writerows(policies)
            print(f"Policies have been successfully saved to '{filename}'")
        else:
            print("No policies found to save.")

    except Exception as e:
        print(f"An error occurred while saving to CSV: {e}")

# Replace the following variables with your FortiGate firewall details
base_url = 'https://your_fortigate_ip'
api_token = 'your_api_token'

policies = fetch_fortigate_policies(base_url, api_token)

if policies:
    save_policies_to_csv(policies, 'fortigate_policies.csv')
else:
    print("Failed to fetch policies.")
