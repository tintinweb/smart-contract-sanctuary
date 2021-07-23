/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

pragma solidity ^0.7.6;

contract CompanyRegistrar {
    
    struct Details {
        string ownerName;
        address owner;
        string cin;
        bool status;
        string otherDetails;
    }
    
    mapping(string => Details) private details;
    string[] public companies;

    function setCompanyDetails(string memory companyName, string memory ownerName, string memory cin, bool status, string memory otherDetails) public returns (bool) {
        // Company with same name should not exist
        require(details[companyName].owner == address(0), "Company with same name exists.");
        details[companyName].owner = msg.sender;
        details[companyName].ownerName = ownerName;
        details[companyName].cin = cin;
        details[companyName].status = status;
        details[companyName].otherDetails = otherDetails;
        companies.push(companyName);
        return true;
    }
    
    function getCompanyDetails(string memory companyName) public view returns (string memory retOwnerName,
        address retOwner,
        string memory retCin,
        bool retStatus,
        string memory retOtherDetails) {
       return (details[companyName].ownerName,
        details[companyName].owner,
        details[companyName].cin,
        details[companyName].status,
        details[companyName].otherDetails);
    }
    
    function editCompanyDetails(string memory companyName, string memory ownerName, string memory cin, bool status, string memory otherDetails) public returns (bool) {
        // Check if company exists first
        require(details[companyName].owner != address(0), "Company doesn't exist");
        // Only the company owner can edit company details
        require(details[companyName].owner == msg.sender, "Only company owner can edit");
        details[companyName].owner = msg.sender;
        details[companyName].ownerName = ownerName;
        details[companyName].cin = cin;
        details[companyName].status = status;
        details[companyName].otherDetails = otherDetails;
        return true;
    }
    
    
}