pragma solidity ^0.4.20;

/*
* InsCoin Smart Policy Contract
* Performance Bond
* V 1.0 - October 21th, 2018
* 
* Written By Marco Vasapollo (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f89b9d97b8959d8c998a91969fd69b9795">[email&#160;protected]</a>)
* for InsCoin
*/
contract InsCoinPolicyManager {
    
    /*
    * Policy Structure
    */
    struct Policy {
        string serialNumber; //Identifies a Smart Policy
        string costumerCode; //Identifyies the contractor
        string issuer;       //Contractor Tax Code FingerPrint
        string beneficiary;  //Beneficiary Tax Code FingerPrint
        string amount;       //Tender amount to guarantee
        string tenderCode;   //Tender Code (description of project to guarantee)
        string startDate;    //Start Date (date of commencement of insurance cover)
        string endDate;      //End Date (date of end of insurance cover)
    }
    
    address private _owner;                                   // Identifies the InsCoin Enterprise Wallet
    mapping(string => Policy) private _policies;              // Database of all issued policies
    mapping(string => string[]) private _taxCodeIndex;        // Database of all policies involving a specified Tax Code (Issuer or Beneficiary)
    mapping(string => string[]) private _costumerCodeIndex;   // Database of all policies issued by a specified Customer Code
    
    // Called when contract is sealed into the Blockchain
    constructor() public {
        //Just Set the Owner of the Contract (InsCoin)
        _owner = msg.sender;
    }
    
    // Called to submit a new policy
    function submitNewPolicy(
        string serialNumber, string costumerCode, string issuer, string beneficiary, string amount, 
        string tenderCode, string startDate, string endDate) public returns (string) {
            
        // Only InsCoin wallet can submit policies
        require(msg.sender == _owner, "Unauthorized Contract Access");
        
        // A policy with a specific serial number can be added just one time
        require(bytes(_policies[serialNumber].serialNumber).length == 0, "Serial Number is already Taken");
        
        // Tax Codes must be partial, for privacy reasons
        require(bytes(issuer).length == 5, "Costumer Code must be 5 characters long");
        require(bytes(beneficiary).length == 5, "Issuer Code must be 5 characters long");
        
        // Save Policy data into Database
        _policies[serialNumber] = Policy(
            serialNumber,
            costumerCode,
            issuer,
            beneficiary,
            amount,
            tenderCode,
            startDate,
            endDate
        );
        // Attribute policy to the specified customer, for search reasons
        _costumerCodeIndex[costumerCode].push(serialNumber);
        
        // Attribute policy to the specified Tax Codes (both issuer and beneficiary), for search reasons
        _taxCodeIndex[issuer].push(serialNumber);
        if(keccak256(bytes(issuer)) != keccak256(bytes(beneficiary))) {
            //Check because someone can attribute the policy to himself
            _taxCodeIndex[beneficiary].push(serialNumber);
        }
        
        // Prints on video the Serial Number
        return serialNumber;
    }
    
    // Called to check if a Policy Serial Number is already saved into Blockchain
    function serialNumberIsUsed(string serialNumber) public view returns (bool) {
        return bytes(_policies[serialNumber].serialNumber).length != 0;
    }

    // Called to get all policies (by iterating index) by specied Tax Code FingerPrint (as issuer or beneficiary)
    function getPolicyByTaxCode(string taxCode, uint index) public view returns (string) {
        return _taxCodeIndex[taxCode][index];
    }
    
    // Called to get all policies (by iterating index) by specied Costumer Code
    function getPolicyByCostumerCode(string costumerCode, uint index) public view returns (string) {
        return _costumerCodeIndex[costumerCode][index];
    }
    
    // Get all policy info by its Serial Number
    function getPolicy(string serialNumber) public view returns (string, string, string, string, string, string, string) {
        Policy storage policy = _policies[serialNumber];
        return (
            policy.costumerCode,
            policy.issuer,
            policy.beneficiary,
            policy.amount,
            policy.tenderCode,
            policy.startDate,
            policy.startDate
        );
    }
}