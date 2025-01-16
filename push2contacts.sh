#!/bin/bash

# Source the config file to import credentials and other variables
source ./conf.sh

# Microsoft Graph API endpoints
GRAPH_API="https://graph.microsoft.com/v1.0"

# Get Access Token
get_access_token() {
    echo "Fetching access token..."
    ACCESS_TOKEN=$(curl -s -X POST -d "client_id=$CLIENT_ID&scope=https://graph.microsoft.com/.default&client_secret=$CLIENT_SECRET&grant_type=client_credentials" $TOKEN_ENDPOINT | jq -r '.access_token')

    if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
        echo "Failed to fetch access token. Exiting."
        exit 1
    fi
}

# Fetch all contacts for a user
fetch_all_contacts() {
    USER_EMAIL="$1"
    NEXT_LINK="$GRAPH_API/users/$USER_EMAIL/contacts"
    ALL_CONTACTS="[]"

    while [[ -n "$NEXT_LINK" ]]; do
        RESPONSE=$(curl -s -X GET "$NEXT_LINK" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json")

        if ! echo "$RESPONSE" | jq -e '.' > /dev/null 2>&1; then
            echo "Error: Invalid JSON response while fetching contacts for $USER_EMAIL."
            echo "$RESPONSE"
            exit 1
        fi

        CONTACTS=$(echo "$RESPONSE" | jq '.value // []')
        NEXT_LINK=$(echo "$RESPONSE" | jq -r '.["@odata.nextLink"] // empty')

        # Append current page contacts to the full list
        ALL_CONTACTS=$(echo "$ALL_CONTACTS $CONTACTS" | jq -s 'add')
    done

    echo "$ALL_CONTACTS"
}

# Push contacts to a user's Contacts folder
push_contacts() {
    USER_EMAIL="$1"
    CONTACT_CSV="$2"

    echo "Fetching existing contacts for $USER_EMAIL..."
    ALL_CONTACTS=$(fetch_all_contacts "$USER_EMAIL")

    echo "Pushing contacts to $USER_EMAIL..."
    tail -n +2 "$CONTACT_CSV" | while IFS=',' read -r GivenName Surname EmailAddress BusinessPhone MobilePhone JobTitle; do
        # Remove surrounding quotes and trim whitespace
        GivenName=$(echo "$GivenName" | sed 's/^"//;s/"$//' | awk '{$1=$1};1')
        Surname=$(echo "$Surname" | sed 's/^"//;s/"$//' | awk '{$1=$1};1')
        EmailAddress=$(echo "$EmailAddress" | sed 's/^"//;s/"$//' | awk '{$1=$1};1')
        BusinessPhone=$(echo "$BusinessPhone" | sed 's/^"//;s/"$//' | awk '{$1=$1};1')
        MobilePhone=$(echo "$MobilePhone" | sed 's/^"//;s/"$//' | awk '{$1=$1};1')
        JobTitle=$(echo "$JobTitle" | sed 's/^"//;s/"$//' | awk '{$1=$1};1')

        # Skip contact if both email and phone are missing
        if [[ -z "$EmailAddress" && -z "$BusinessPhone" && -z "$MobilePhone" ]]; then
            echo "Skipping contact with no email or phone: $GivenName $Surname"
            continue
        fi

        # Check if contact already exists in the fetched list
        if echo "$ALL_CONTACTS" | jq -e --arg email "$EmailAddress" '.[] | select(.emailAddresses[]?.address == $email)' > /dev/null; then
            echo "Contact with email $EmailAddress already exists for $USER_EMAIL."
            continue
        fi

        # Create the contact payload
        CONTACT_JSON=$(jq -n \
            --arg fn "$GivenName" \
            --arg ln "$Surname" \
            --arg email "$EmailAddress" \
            --arg businessPhone "$BusinessPhone" \
            --arg mobilePhone "$MobilePhone" \
            --arg jobTitle "$JobTitle" \
            '{
                givenName: $fn,
                surname: $ln,
                emailAddresses: ($email | select(length > 0) | [{ address: $email, name: "\($fn) \($ln)" }] // []),
                businessPhones: ($businessPhone | select(length > 0) | [.] // []),
                mobilePhone: ($mobilePhone | select(length > 0) // null),
                jobTitle: ($jobTitle | select(length > 0) // null)
            }'
        )

        # Push the contact to Microsoft Graph
        RESPONSE=$(curl -s -X POST "$GRAPH_API/users/$USER_EMAIL/contacts" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$CONTACT_JSON")

        # Check for errors
        if echo "$RESPONSE" | jq -e '.error' > /dev/null; then
            echo "Failed to add contact $EmailAddress for $USER_EMAIL: $(echo "$RESPONSE" | jq -r '.error.message')"
        else
            echo "Successfully added contact $EmailAddress for $USER_EMAIL."
        fi
    done
}

# Main function
main() {
    # Validate input
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <CSV_File> <User_Email_List>"
        exit 1
    fi

    CONTACT_CSV="$1"
    USER_LIST="$2"

    # Get access token
    get_access_token

    # Process each user in the list
    while IFS= read -r USER_EMAIL; do
        push_contacts "$USER_EMAIL" "$CONTACT_CSV"
    done < "$USER_LIST"

    echo "Contacts have been pushed to all specified users."
}

# Execute main function
main "$@"
