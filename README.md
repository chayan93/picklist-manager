### CREATE OR EDIT PICKLISTS WHERE THE VALUES' LABEL DIFFERS FROM THE API-NAME

#### PROBLEM STATEMENT:
Many times, we have a requirement to create/update picklist fields wherein the label of an entry differs from the API Name of the entry, e.g. the label of an entry might be India whereas the API Name might be IN. In such situations, there's no one-stop shop where you can edit all the entries at once, and therefore the only viable option is to create a picklist field with all the given entries and then edit each entry - ONE BY ONE which I believe quite a time taking process if there are more than just a few entries.


#### To overcome this problem, here's a Salesforce App - Picklist Manager that'll help you to:

    1. Create a new picklist field on any SObject.
    2. Add new entries to any existing picklist field of any SObject.


#### While creating a new picklist field, below are a few notable features:

    1. When you type in the Label, the API Name will automatically be populated if it does not already exist.
    2. You can either select an existing Global Value Set or enter values(same as in the standard process).
    3. Options to create both types of picklist fields(Single-Select & Multi-Select).
    4. Standard options like (Description, HelpText, Sorted, Restricted, etc.) are available.
    5. Duplicate values/labels aren't allowed.
    6. Add the values to the Selected SObject's Record Types and also choose the default values for each of them.
    7. Set Field Level security of the new field for the available profiles.


#### While adding new entries to any existing picklist field, below are a few notable features:

    1. All the Standard/Custom SObjects along with all their Standard/Custom Picklist fields are available to choose from.
    2. You can only add those values that don't already exist.
    3. Add the values to the Selected SObject's Record Types or Business Process and also choose the default values for each of them.
    4. Standard options like Probability, ForecastCategory, High Priority, Closed, Won, etc. are available only for a few standard picklists are available here too.


> [NOTE]: As picklist values are added to the record types asynchronously(separately through batch class), there's a separate object(Record Type Update Detail) to keep a track of the progress - the tab for this object has been added to the Salesforce app as well. You might need to keep a track of that and upon failure, you should manually update the record type(s).



> POST-DEPLOYMENT STEP:
Assign the Picklist_Manager permission set to any System Admin user and this app will be ready to be used by them.


__Probable Future Enhancements:__

    1. Logger facility to log each of the errors faced while using the app.
    2. While creating a picklist field, availability to add FLS to the available permission sets too.
    3. Retry mechanism to add values to Record Types upon failure.
    
    
# Screenshots

<img width="960" alt="Screenshot 2022-09-11 at 7 41 44 PM" src="https://user-images.githubusercontent.com/31616825/189613348-ee9d1bb4-282d-4e09-a1d2-2b69ead9bc67.png">
<img width="960" alt="Screenshot 2022-09-11 at 7 42 16 PM" src="https://user-images.githubusercontent.com/31616825/189613404-15eeeb71-2558-419b-abee-c25570104ee5.png">
<img width="960" alt="Screenshot 2022-09-11 at 7 48 43 PM" src="https://user-images.githubusercontent.com/31616825/189613443-6a59f1ed-ccad-41a6-8695-fc5ecc5a54a2.png">
<img width="960" alt="Screenshot 2022-09-11 at 7 49 28 PM" src="https://user-images.githubusercontent.com/31616825/189613482-9a4c01b7-f8de-44ef-adbe-5d10b28c6d9a.png">
<img width="960" alt="Screenshot 2022-09-11 at 7 50 24 PM" src="https://user-images.githubusercontent.com/31616825/189613520-f2de303b-69dc-46f7-8315-92091903f177.png">
<img width="960" alt="Screenshot 2022-09-11 at 7 50 46 PM" src="https://user-images.githubusercontent.com/31616825/189613563-e676977a-7306-4247-9e11-61547a9769bd.png">
<img width="960" alt="Screenshot 2022-09-11 at 9 48 21 PM" src="https://user-images.githubusercontent.com/31616825/189613874-b8c47dcd-6e1b-4859-8640-2ee03a347eb5.png">
