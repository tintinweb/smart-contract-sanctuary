// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

// BconContract represents a single legal contractual relation between "client" (Auftraggeber) and "contractor" (Auftragnehmer)
// with multiple BillingUnits (Abrechnungseinheiten) which consists of multiple BillingUnitItems (LV-Positionen)
contract Documents {    
    // required legal documents as the base for this contract
    string public billOfQuantitiesDocument;
    string public billingPlan;
    string public bimModel;
    string public paperContract;

    constructor(string memory _billOfQuantitiesDocument,string memory _billingPlan,string memory _bimModel,string memory _paperContract) {
        billOfQuantitiesDocument = _billOfQuantitiesDocument;
        billingPlan = _billingPlan;
        bimModel = _bimModel;
        paperContract = _paperContract;
    }

    function getDocuments() public view returns(string memory, string memory, string memory, string memory) {
        return (billOfQuantitiesDocument,billingPlan,bimModel,paperContract);
    }

    function setBillOfQuantitiesDocument(string calldata _billOfQuantitiesDocument) public {
        billOfQuantitiesDocument = _billOfQuantitiesDocument;
    }
    function setBillingPlan(string calldata _billingPlan) public {
        billingPlan = _billingPlan;
    }
    function setBimModel(string calldata _bimModel) public {
        bimModel = _bimModel;
    }
    function setPaperContract(string calldata _paperContract) public {
        paperContract = _paperContract;
    }
}