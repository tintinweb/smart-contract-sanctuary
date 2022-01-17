/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract TraceFood{
    
    struct userDetails {
        string email;
        string companyName;
        string role; 
    }
    
    
    mapping(string => bytes32)currentOwnerOfBatch;
    mapping(bytes32 => bool)isUserAuthorised;
    //mapping(bytes32 => bool)isAdmin;
    mapping(address => bool) isKeyValid;
    mapping(string => uint)stepId;
    
    mapping(string => bool)batchNameExists;

    event authorizationLog(bytes32 indexed _user, bool _status, uint _timestamp);
    event BatchStatus(string _batchName,
    string indexed _batchNameIndexed,
    bytes32 _email,
    bytes32 indexed _emailIndexed,
    string _data, 
    uint stepId);
    event key(address _key, bool _value);
    
    constructor(address _allowedKey) {
        //isAdmin[_hashOfAdminEmail] = true;
        isKeyValid[_allowedKey] = true;
    }
    
    modifier onlyAuthorized(bytes32 _hashOfEmail){
        require(isUserAuthorised[_hashOfEmail] == true, "Not_authorized");
        _;
    }
    
   /*  modifier onlyAdmin(bytes32 _hashOfAdminEmail){
        require(isAdmin[_hashOfAdminEmail] == true, "Not_an_Admin");
        _;
    } */

    modifier onlyValidKey(){
        require(isKeyValid[msg.sender] == true, "invalid_key");
        _;
    }

    function authorizeUser(bytes32 _hashOfUserEmail, bool _isAuthorized)public  onlyValidKey returns (bool) {
        isUserAuthorised[_hashOfUserEmail] = _isAuthorized;
        emit authorizationLog(_hashOfUserEmail, _isAuthorized, block.timestamp);
        return true;
    }
            
    function updateBatchStatus(bytes32 _hashOfEmail, string memory _data, string memory _batchName)public onlyValidKey returns (bool){
        //require(currentOwnerOfBatch[_batchName] == _hashOfPreviousOwnerEmail, "");
        stepId[_batchName] ++;
        emit BatchStatus(_batchName, _batchName, _hashOfEmail, _hashOfEmail, _data, stepId[_batchName]);
        return true;
    }

    function createBatch(string memory _batchName, string memory _data, bytes32 _hashOfEmail) public onlyValidKey {
        //require(currentOwnerOfBatch[_batchName] == 0x0, "BatchName_Exists");// check
        require(batchNameExists[_batchName] == false, "Batch_exists");
        batchNameExists[_batchName] = true;
        stepId[_batchName]++;
        emit BatchStatus(_batchName, _batchName, _hashOfEmail, _hashOfEmail, _data, stepId[_batchName]);
    }

    function getBatchOwner(string memory _batchName)public view onlyValidKey returns(bytes32){
        return currentOwnerOfBatch[_batchName];
    }

    function isAuthorised(bytes32 _hashOfEmail) public onlyValidKey view returns (bool){
        return isUserAuthorised[_hashOfEmail];
    }

    /* function isAdminUser(bytes32 _adminEmail) public view returns (bool){
        return isAdmin[_adminEmail];
    } */

    function setServerKey(address _serverKey, bool _keyStatus)public onlyValidKey{
        isKeyValid[_serverKey] = _keyStatus;
        emit key(_serverKey, _keyStatus);
    }
}