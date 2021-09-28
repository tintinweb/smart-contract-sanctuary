// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract KYC is Ownable {

    event AdminAdded(address);
    event AdminRemoved(address);
    event RecordAdded(string indexed, string indexed, uint8, string);
    event RecordsAdded(RecordsStruct[]);
    
    struct Record {
        string uuidv4;
        uint8 level;
        bool exist;
        string recordType;
    }
    
    struct RecordsStruct {
        string _recordID;
        string _uuidv4;
        uint8 _level;
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

    function register(string memory _recordID, string memory _uuidv4, uint8 _level, string memory _recordType) public onlyAdmin {
        addressRecord[_recordID] = Record(_uuidv4, _level, true, _recordType);
        emit RecordAdded(_recordID, _uuidv4, _level, _recordType);
    }

     function registerMultiple(RecordsStruct[] memory _records) public onlyAdmin { 
        for(uint i=0; i< _records.length; i++){
           addressRecord[_records[i]._recordID] = Record(_records[i]._uuidv4, _records[i]._level, true, _records[i]._recordType); 
        }
        emit RecordsAdded(_records);
    }
    
    function checkStatus(string memory _recordID) public view returns(uint8, string memory) {
        require(addressRecord[_recordID].exist == true);
        return (addressRecord[_recordID].level, addressRecord[_recordID].recordType);
    }
}