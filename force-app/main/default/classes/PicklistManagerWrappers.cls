/**
 * @description       : Wrappers for picklist manager
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 09-11-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public class PicklistManagerWrappers {
    public class CreateOrUpdatePicklistFieldResponse{
        @AuraEnabled public String message;
        @AuraEnabled public String variant = 'info';
        @AuraEnabled public String fieldURL;
        @AuraEnabled public List<Object> messageData;
    }

    public class ToolingAPIQueryResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<Record> records;
    }

    public class Record{
        public Attribute attributes;
        public Metadata Metadata;
        public String Id;
        public String Name;
        public String FullName;
        public String EntityDefinitionId;
        public String Label;
        public String QualifiedApiName;
        public String MasterLabel;
        public String DeveloperName;
    }

    public class Metadata{
        public Boolean active;
        public String businessProcess;
        public String compactLayoutAssignment;
        public String description;
        public String label;
        public List<PicklistValue> picklistValues;
        public List<CustomValue> customValue;
    }

    public class CustomValue{
        public String color;
        public Boolean default_x;
        public String description;
        public Boolean isActive;
        public String label;
        public String urls;
        public String valueName;
    }

    public class PicklistValue{
        public String picklist;
        public List<Value> values;
    }

    public class Value{
        public Boolean allowEmail = null;
        public Boolean closed = null;
        public String color = null;
        public String controllingFieldValues = null;
        public Boolean converted = null;
        public Boolean cssExposed = null;
        public Boolean default_x = false;
        public String description = null;
        public String forecastCategory = null;
        public Boolean highPriority = null;
        public Boolean isActive = null;
        public Integer probability = null;
        public String reverseRole = null;
        public Boolean reviewed = null;
        public String urls = null;
        public String valueName = null;
        public Boolean won = null;
    }

    public class Attribute{
        public String type;
        public String url;
    }

    public class ObjectResponse{
        @AuraEnabled public List<SelectOption> objectOptions;
        @AuraEnabled public List<SelectOption> globalValueSetOptions;
        @AuraEnabled public Map<String, String> standardValueSetMap;
    }

    public class SelectedObjectResponse{
        @AuraEnabled public String existingFieldNames = ';';
        @AuraEnabled public List<SelectOption> rtInfo =
            new List<SelectOption>();
        @AuraEnabled public List<SelectOption> businessProcessInfo =
            new List<SelectOption>();
        @AuraEnabled public List<SelectOption> existingPicklistFields =
            new List<SelectOption>();
        @AuraEnabled public List<ProfileFLSDetails> eligibleProfiles =
            new List<ProfileFLSDetails>();
    }

    public class SelectOption implements Comparable{
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public SelectOption(String label, String value){
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo) {
            SelectOption option = (SelectOption)compareTo;
            if (label == option.label) {
                return 0;
            }
            if (label > option.label) {
                return 1;
            }

            return -1;
        }
    }

    public class RecordTypeOrBusinessProcessInfo{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public List<SelectOption> selectedValues;
    }

    public class AdditionalPicklistInfo{
        @AuraEnabled public String globalValueSetName;
        @AuraEnabled public List<StandardValueColumnStructure> columnStructure =
            new List<StandardValueColumnStructure>();
        @AuraEnabled public List<SelectOption> existingPicklistValues =
            new List<SelectOption>();
        @AuraEnabled public List<SelectOption> forecastCategories =
            new List<SelectOption>();
        @AuraEnabled public List<SelectOption> additionalRecordTypesToDisplay =
            new List<SelectOption>();
    }

    public class StandardValueColumnStructure{
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean editable = true;

        public StandardValueColumnStructure(
            String label, String fieldName, String type
        ){
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
    }

    public class ProfileFLSDetails{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean readable = true;
        @AuraEnabled public Boolean readOnly = false;

        public ProfileFLSDetails(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}