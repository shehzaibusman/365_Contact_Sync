# 365_Contact_Sync

## 1. Create an Azure AD App Registration
Create an app in Azure Active Directory with the following **API permissions**:
- **Contacts.ReadWrite** (Application)
- **User.Read.All** (Application)

These permissions will allow the app to read and write contacts for the users in your organization.

## 2. Install Required Dependencies
Make sure you have the required dependencies installed for the scripts to run smoothly:
- **jq**: For JSON parsing
- **curl**: For making API requests

You can install them using the following commands:
```bash
# For Ubuntu/Debian-based systems
sudo apt install jq curl

# For macOS
brew install jq curl
```

## 3. Create conf.sh to Store Azure AD App Credentials
```bash
# Azure AD App credentials
CLIENT_ID="UPDATE_ME"
CLIENT_SECRET="UPDATE_ME"
TENANT_ID="UPDATE_ME"
TOKEN_ENDPOINT="https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token"
```

## 4. Fetch the User List
```bash
./fetch_contacts.sh
```
The resulting all_users.csv will include all users' contact details.

## 5. Sanitize the CSV
Review and sanitize the all_users.csv file to remove any users you don't want synchronized. You can delete rows for users you don't wish to include in the synchronization process.  
This push will look at values that include a phone number and an email address so add the email and phone number in entra.

## 6. Create user_list.txt
Add the recipients who will have contacts added/updated in their exchange.
```bash
user1@example.com
user2@example.com
user3@example.com
```

## 7. Push Contacts to Users
Run the script push2contacts.sh to push contacts to the specified users. This script will read from the all_users.csv file and add contacts to the users listed in user_list.txt:
```bash
./push2contacts.sh all_users.csv user_list.txt
```
The contacts will be pushed to each user's Exchange contact list.




