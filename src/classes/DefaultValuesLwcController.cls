/**
 * Author       : Kevin Antonioli (braveitnow@pm.me)
 * Description  : apex controller for navToNewRecCreateModalWithDefaults lightning web component
 *  that auto populates desired default values on record creation modals invoked from quick actions or flows.
 *  Example: Auto populate Name, Phone Number, and several custom fields from Account to Opportunity
 *   record creation screen, invoked from a quick action or flow on the Account layout.
 * Created      : 03.02.2023
 *
 * Note: this gives us more flexibility than the out of box way of populating defaults via formula.
 *  Such as: we can run custom validations on quick action button click before the record creation modal
 *  even loads. We can also invoke record creation modal screens from flows
 */
public class DefaultValuesLwcController {
  private static String sourceApiName;
  private static String parentObjectName;

  /**
   * @description: singleton variable to query default values
   * @return defaultValueFieldMappings (List<Default_Value_Field_Mapping__mdt>: a list of default value pairs
   *  defined in a Default Value Field Mapping record
   */
  private static List<Default_Value_Field_Mapping__mdt> defaultValueFieldMappings {
    get {
      if (defaultValueFieldMappings == null) {
        defaultValueFieldMappings = !Test.isrunningTest()
          ? [
              SELECT Parent_Object_Field__c, Target_Object_Field__c
              FROM Default_Value_Field_Mapping__mdt
              WHERE
                Source_Key__c = :sourceApiName
                AND Parent_Object_Name__c = :parentObjectName
            ]
          : new List<Default_Value_Field_Mapping__mdt>{
              new Default_Value_Field_Mapping__mdt(
                Source_Key__c = sourceApiName,
                Parent_Object_Name__c = parentObjectName,
                Parent_Object_Field__c = 'Id',
                Target_Object_field__c = 'AccountId'
              )
            };
      }
      return defaultValueFieldMappings;
    }
    set;
  }

  /**
   * @description: method to query custom fields, since the out-of-box lwc getRecords can't do it effectively
   * @param   recordId      Id of the record to query
   * @param   sourceApiName For quick action use case, the API name of the quick action. For flow use case, the flow variable value
   * @return  the queried   record
   */
  @AuraEnabled
  public static Map<String, String> retrieveDefaultValues(
    Id recordId,
    String sourceKeyParam
  ) {
    try {
      sourceApiName = sourceKeyParam;
      parentObjectName = String.valueOf(recordId.getSobjectType());
      List<String> fieldsToQuery = new List<String>();
      for (Default_Value_Field_Mapping__mdt dvfm : defaultValueFieldMappings) {
        fieldsToQuery.add(dvfm.Parent_Object_Field__c);
      }

      String queryString =
        'SELECT ' +
        String.join(fieldsToQuery, ', ') +
        ' FROM ' +
        parentObjectName +
        ' WHERE Id = :recordId';

      SObject record = Database.query(queryString);
      Map<String, String> defaultValuesFieldMap = getDefaultValuesFieldMap(
        record,
        sourceApiName
      );
      return defaultValuesFieldMap;
    } catch (Exception e) {
      System.debug(
        'DefaultValuesLwcController.retrieveDefaultValues exception, message: ' +
        e.getMessage() +
        ', stack trace: ' +
        e.getStackTraceString()
      );
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description: method to map the target field to the associated queried value from the parent object
   * @param   record                The queried parent record
   * @param   sourceApiName         The name of the quick action interfacing with this controller
   * @return  defaultValuesFieldMap Target object field value to parent object field value
   */
  private static Map<String, String> getDefaultValuesFieldMap(
    SObject record,
    String sourceApiName
  ) {
    try {
      Map<String, String> defaultValuesFieldMap = new Map<String, String>();
      for (Default_Value_Field_Mapping__mdt dvfm : defaultValueFieldMappings) {
        Object fieldValueObj = record.get(dvfm.Parent_Object_Field__c);
        String parentObjFieldValue;
        if (fieldValueObj instanceof Date) {
          parentObjFieldValue = String.valueOf(
            (Date) record.get(dvfm.Parent_Object_Field__c)
          );
        } else {
          parentObjFieldValue = String.valueOf(
            record.get(dvfm.Parent_Object_Field__c)
          );
        }
        defaultValuesFieldMap.put(
          dvfm.Target_Object_Field__c,
          parentObjFieldValue
        );
      }
      return defaultValuesFieldMap;
    } catch (Exception e) {
      System.debug(
        'DefaultValuesLwcController.getDefaultValuesFieldMap exception, message: ' +
        e.getMessage() +
        ', stack trace: ' +
        e.getStackTraceString()
      );
      throw new AuraHandledException(e.getMessage());
    }
  }
}