# Source the config file to import credentials and other variables
source ./conf.sh

GRAPH_API="https://graph.microsoft.com/v1.0/users"

# Output file
OUTPUT_FILE="all_users2.csv"

# Fetch Access Token
echo "Fetching access token..."
ACCESS_TOKEN=$(curl -s -X POST $TOKEN_ENDPOINT \
  -d "client_id=$CLIENT_ID" \
  -d "scope=https://graph.microsoft.com/.default" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "grant_type=client_credentials" | jq -r '.access_token')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "Failed to fetch access token. Check credentials."
  exit 1
fi

# Fetch all users and write to CSV
echo "Fetching users..."
echo '"Given Name","Surname","Email","Business Phone","Mobile Phone","Job Title"' > $OUTPUT_FILE

NEXT_LINK=$GRAPH_API
while [ -n "$NEXT_LINK" ]; do
  RESPONSE=$(curl -s -X GET "$NEXT_LINK" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")

  if [ "$(echo "$RESPONSE" | jq -r '.value | length')" -eq 0 ]; then
    echo "No users found or insufficient permissions."
    exit 1
  fi

  USERS=$(echo "$RESPONSE" | jq -r '.value[] | [.givenName, .surname, .mail, (.businessPhones[0] // ""), (.mobilePhone // ""), (.jobTitle // "")] | @csv')
  echo "$USERS" >> $OUTPUT_FILE

  NEXT_LINK=$(echo "$RESPONSE" | jq -r '.["@odata.nextLink"] // empty')
done

echo "Users have been saved to $OUTPUT_FILE."
