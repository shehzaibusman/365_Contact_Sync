# 365_Contact_Sync

## Overview
This project provides scripts to synchronize contact information from Microsoft Entra (Azure AD) to users' Exchange contact lists. The steps below guide you through setting up and using the tool.

---

## 1. Create an Azure AD App Registration
1. Go to the **Azure Portal** and create an **App Registration**.
2. Assign the following **API permissions** to the app:
   - **Contacts.ReadWrite** (Application)
   - **User.Read.All** (Application)

> These permissions allow the app to read and write contacts for users in your organization.

## 2. Install Required Dependencies
Ensure the following dependencies are installed:
- **jq**: For JSON parsing.
- **curl**: For making API requests.

### Installation Commands:
```bash
# For Ubuntu/Debian-based systems
sudo apt install jq curl
```

```bash
# For macOS
brew install jq curl
```

## 3. Create conf.sh to store Azure AD App Credentials
Create a file named `conf.sh` to store your Azure AD App credentials. Replace `UPDATE_ME` with your actual values:

```bash
# Azure AD App credentials
CLIENT_ID="UPDATE_ME"
CLIENT_SECRET="UPDATE_ME"
TENANT_ID="UPDATE_ME"
TOKEN_ENDPOINT="https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token"
```

## 4. Fetch the User List
Run the following script to fetch user details from Azure AD:

```bash
./fetch_contacts.sh
```
> The resulting `all_users.csv` will include all users' contact details.

## 5. Sanitize the CSV
Review and sanitize the `all_users.csv` file to remove any users you don't want synchronized:

1. Open `all_users.csv` and review the data.
2. Remove any rows for users you don’t want to synchronize.
3. Ensure each contact has the following:
- **Email address**
- **Phone number**
> Make sure the relevant fields are populated in Microsoft Entra (Azure AD) before running this step.



## 6. Create user_list.txt
Update a file named `user_list.txt` with the email addresses of the users who will have their Exchange contacts updated:

```bash
user1@example.com
user2@example.com
user3@example.com
```

## 7. Push Contacts to Users
Run the script `push2contacts.sh` to push contacts to the specified users in `user_list.txt'. 

```bash
./push2contacts.sh all_users.csv user_list.txt
```
> This script will read from the `all_users.csv` file and add contacts to the users listed in user_list.txt.






