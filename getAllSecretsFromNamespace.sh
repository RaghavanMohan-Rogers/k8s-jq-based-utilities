#!/bin/bash
# Unable to check if namespace is part of the current cluster! To do this cluster level access is needed as kubectl get namespace does not work!

# Location of 'jq' in local machine. If 'jq' is configured in the machine this is not needed and we can use 'jq' directly.
jq="C:\Users\sriram\Downloads\jq.exe"

if [ -z "$1" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

namespace="$1"

# Reversing all the characters of the input parameter to lowercase. This is OPTIONAL.
lowercase_namespace="${namespace,,}"
echo "Namespace: " $lowercase_namespace

# Get today's date in DD-MMM-YYYY format
today_date=$(date +"%d-%b-%Y")

# Define the folder name
folder_name="$today_date"

# Check if the folder already exists
if [ -d "$folder_name" ]; then
    echo "Folder $folder_name already exists. Skipping creation."
else
    # Create the folder
    mkdir "$folder_name"
    echo "Folder $folder_name created successfully."
fi

# Name of the secrets file
output_file="$lowercase_namespace.json"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl and try again."
    exit 1
fi

# Get the current context
current_context=$(kubectl config current-context)

# Check if the current context is empty
if [ -z "$current_context" ]; then
    echo "Error: No current context found. Make sure your kubeconfig is properly configured."
    exit 1
fi

# Print the current context
echo "Current context: $current_context"

# Retrieve secrets
secrets_json=$(kubectl get secrets --namespace=${lowercase_namespace} -o json)

# Check if the secret exists
if [ -z "$secrets_json" ]; then
	echo "Secrets not found for namespace '$lowercase_namespace'."
    exit 1
else
	# Filter secrets, excluding those with "-backup-" in their name and type "helm.sh/release.v1"
	filtered_secrets=$(echo "$secrets_json" | $jq -c -r '.items[] | select(.metadata.name | contains("-backup-") | not) | select(.type != "helm.sh/release.v1")')

	# Format the output
	formatted_output=$(echo "$filtered_secrets" | $jq -c -r '.metadata.name as $name | .data | to_entries | "\($name)\n{\n  " + (map("\"\(.key)\": \"\(.value)\"") | join(",\n  ")) + "\n}"')

	# Write the output to the file
	echo "$formatted_output" > "$folder_name\\$output_file"

	echo "Secrets for namespace $lowercase_namespace have been written to $output_file"
fi
