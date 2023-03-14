// LWC used to prepopulate values on a record creation modal, invoked from a Quick Action or Screen Flow
// Author: Kevin Antonioli : 04.29.2022
// Useful for when the out-of-box formula technique on button/link doesn't quite cut it
// Default values defined
//
// Define your default values in the Default Value Mappings custom metadata type
//
// This is an alternative to using '/lightning/o/ObjectName/new?defaultFieldValues' with a button/link
//  but with greater customizability like validating on quick action button click
//
// Note: for the Quick Action use case, this LWC depends on the quick action API name being in the following format:
//  ObjectName_XXXXX_QuickActionName
//  Standard object example: Opportunity_XXXXX_New_Opp
//  Custom object example: Quote_Request_c_XXXXX_New_Quote_Request
//
// Note: for the Quick Action use case, if dealing with custom object, you cannot use __c in the quick action
//  naming convention above due to Salesforce system limitation.
//  You must use _c, and then the Javascript in this LWC will fix it to reflect __c.
//  Do not use _c in any other part of the name
//
// Note: for Screen Flow use case, there are no such restrictions on the naming convention of the source key,
//  but you must pass recordId from the lightning layout in which the flow is defined

import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { CurrentPageReference } from "lightning/navigation";
import retrieveDefaultValues from "@salesforce/apex/DefaultValuesLwcController.retrieveDefaultValues";

/**
 * default LWC main class
 */
export default class DefaultValuesComponent extends NavigationMixin(
  LightningElement
) {
  @api sourceDfKeyFromFlow; // default values key defined in Screen Flow definition (for Screen Flow use case)
  @api recordIdFromFlow; // record id passed in from Screen Flow within Lightning Layout (for Screen Flow use case)
  @api sObjNameFromFlow; // sobject name defined in Screen Flow definition (for Screen Flow use case)

  // private properties:
  sObjectApiName = "";
  sourceKey = ""; // source API name could come from quick action API Name, or Screen Flow
  _recordId;
  retrievedRecordId = false;

  /**
   * @description: wire method to get the source key and set instance variables
   * @param {*} currentPageReference
   */
  @wire(CurrentPageReference)
  getQuickActionApiName(currentPageReference) {
    // if the page is a quick action, get quick action API name
    if (currentPageReference.type === "standard__quickAction") {
      let quickActionPath = currentPageReference.attributes.apiName;
      let firstSplit = quickActionPath.split(".")[1];
      let sObjectApiName = firstSplit.split("_XXXXX_")[0];
      if (sObjectApiName.includes("_c")) {
        sObjectApiName = sObjectApiName.replace("_c", "__c");
      }
      this.sObjectApiName = sObjectApiName;
      this.sourceKey = firstSplit;
    } else if (currentPageReference.type === "standard__recordPage") {
      this.sourceKey = this.sourceDfKeyFromFlow;
      this.sObjectApiName = this.sObjNameFromFlow;
      this._recordId = this.recordIdFromFlow;
      this.retrieveDefaultValuesMethod();
    }
  }

  @api set recordId(value) {
    this._recordId = value;
  }

  get recordId() {
    return this._recordId;
  }

  /**
   * @description: retrieve default values once the component has rendered
   * @param null
   * @return void
   */
  renderedCallback() {
    if (!this.retrievedRecordId && this.recordId) {
      this.retrievedRecordId = true; // Escape case from recursion
      this.retrieveDefaultValuesMethod();
    }
  }

  /**
   * @description: perform the retrieval of default values from parent record and populate
   *  those into the fields on the record creation modal
   * @param null
   * @return void
   */
  retrieveDefaultValuesMethod() {
    const sourceKey = String(this.sourceKey);
    // call apex controller method to retrieve the default values:
    retrieveDefaultValues({
      recordId: this.recordId,
      sourceKeyParam: sourceKey
    })
      .then((result) => {
        const defaultValues = encodeDefaultFieldValues(result);

        // navigate to record creation modal
        this[NavigationMixin.Navigate]({
          type: "standard__objectPage",
          attributes: {
            objectApiName: this.sObjectApiName,
            actionName: "new"
          },
          state: {
            defaultFieldValues: defaultValues
          }
        });
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error retrieving default values",
            message: error.body.message,
            variant: "error",
            mode: "sticky"
          })
        );
      });
  }
}