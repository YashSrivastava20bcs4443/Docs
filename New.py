import requests
import json

# Replace with your FortiGate details
base_url = 'https://<fortigate-ip>/api/v2'
api_key = '<your-api-key>'
headers = {
    'Authorization': f'Bearer {api_key}',
    'Content-Type': 'application/json'
}

# Export Firewall Policies to JSON
response = requests.get(f'{base_url}/cmdb/firewall/policy', headers=headers, verify=False)
if response.status_code == 200:
    policies = response.json()['results']
    with open('firewall_policies.json', 'w') as f:
        json.dump(policies, f, indent=4)
    print("Policies exported to firewall_policies.json")
else:
    print(f"Failed to export policies. Status Code: {response.status_code}")

# Export Firewall Policies to CSV
import csv

if response.status_code == 200:
    policies = response.json()['results']
    keys = policies[0].keys()
    with open('firewall_policies.csv', 'w', newline='') as f:
        dict_writer = csv.DictWriter(f, fieldnames=keys)
        dict_writer.writeheader()
        dict_writer.writerows(policies)
    print("Policies exported to firewall_policies.csv")
else:
    print(f"Failed to export policies. Status Code: {response.status_code}")
