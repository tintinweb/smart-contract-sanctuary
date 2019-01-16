pragma solidity ^0.4.20;

contract InsCoinPolicyManager {
    
    struct Policy {
        string serialNumber;
        string costumerCode;
        string issuer;
        string beneficiary;
        string amount;
        string tenderCode;
        string startDate;
        string endDate;
    }
    
    address private _owner;
    mapping(string => Policy) private _policies;
    mapping(string => string[]) private _index;
    
    constructor() public {
        _owner = msg.sender;
    }
    
    function submitNewPolicy(
        string serialNumber, string costumerCode, string issuer, string beneficiary, string amount, 
        string tenderCode, string startDate, string endDate) public returns (string) {
        require(msg.sender == _owner, "Unauthorized Contract Access");
        require(bytes(_policies[serialNumber].serialNumber).length == 0, "Serial Number is already Taken");
        require(bytes(issuer).length == 5, "Costumer Code must be 5 characters long");
        require(bytes(beneficiary).length == 5, "Issuer Code must be 5 characters long");
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
        _index[issuer].push(serialNumber);
        if(keccak256(bytes(issuer)) != keccak256(bytes(beneficiary))) {
            _index[beneficiary].push(serialNumber);
        }
        return serialNumber;
    }
    
    function serialNumberIsUsed(string serialNumber) public view returns (bool) {
        return bytes(_policies[serialNumber].serialNumber).length != 0;
    }

    function getPolicyByTaxCode(string taxCode, uint index) public view returns (string) {
        return _index[taxCode][index];
    }
    
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