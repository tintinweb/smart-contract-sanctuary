// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract KYC is Ownable {

    event AdminAdded(address);
    event AdminRemoved(address);
    event RecordAdded(string indexed, string indexed, uint8, string);
    event RecordsAdded(Records[]);
    
    struct Record {
        string kycID;
        uint8 kycLevel;
        bool exist;
        string recordType;
    }
    
    struct Records{
        string _recordID;
        string _kycID;
        uint8 _kycLevel;
        string _recordType;
       
    }

    mapping (address => bool) private isAdmin;
    mapping (string => Record) private addressRecord;

    constructor() Ownable() {
        isAdmin[_msgSender()] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    function addAdmin(address _address) public onlyOwner {
        isAdmin[_address] = true;
        emit AdminAdded(_address);
    }

    function removeAdmin(address _address) public onlyOwner {
        isAdmin[_address] = false;
        emit AdminRemoved(_address);
    }

    function register(string memory _recordID, string memory _kycID, uint8 _kycLevel, string memory _recordType) public onlyAdmin {
        addressRecord[_recordID] = Record(_kycID, _kycLevel, true, _recordType);
        emit RecordAdded(_recordID, _kycID, _kycLevel, _recordType);
    }

     function registerMultiple(Records[] memory _records) public onlyAdmin { 
        for(uint i=0; i< _records.length; i++){
           addressRecord[_records[i]._recordID] = Record(_records[i]._kycID, _records[i]._kycLevel, true, _records[i]._recordType); 
        }
        emit RecordsAdded(_records);
    }
    
    function checkStatus(string memory _recordID) public view returns(string memory, uint8, string memory) {
        require(addressRecord[_recordID].exist == true);
        return (addressRecord[_recordID].kycID, addressRecord[_recordID].kycLevel, addressRecord[_recordID].recordType);
    }
}