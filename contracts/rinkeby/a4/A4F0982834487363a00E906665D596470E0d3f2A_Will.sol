/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import './IToken.sol';
// import './TransferHelper.sol';

contract Will {


    struct Record
    {
        string recordMsg;  //message encrypted with beneficiary publick key
        string checkingMsg; //message encrypted with 
        uint lockedUntil;
    }

    struct BeneficiaryRecord
    {
        mapping(uint => Record) recordStructs;
        uint recordCount;
        bool choosed;
        string publicKey;
    }

    struct Letter
    {
        mapping(address => BeneficiaryRecord) BeneficiaryRecordStructs; // Beneficiary record
    }

    mapping(address => Letter) Letters; // Owner of will

    // Record added
    event addedLetterRecord (
        // Record _record,
        address _willOwner,
        address _beneficiary
    );

    // Record uodated
    event updatedLetterRecord (
        // Record _record,
        address _willOwner,
        address _beneficiary
    );

    // Beneficiary choosed
    event namedBenificiary (
        address _willOwner,
        address _beneficiary
    );

    //Beneficiary acceptance
    event beneficiaryAcceptance (
        address _willOwner,
        address _beneficiary
    );

    uint public minimunLockAllowed;
    uint32 public dayCosts;

    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() {
        minimunLockAllowed = 5;
        dayCosts = 1000; //in wei
        admin = msg.sender;
    }

    function setMinimunLockAllowed (uint value) public onlyAdmin {
        require(value>0);
        minimunLockAllowed = value;
    } 

    function setDayCost (uint32 value) public onlyAdmin {
        require(value>0);
        dayCosts = value;
    }

    function changeAdmin (address _newAdmin) public onlyAdmin {
        require(_newAdmin != msg.sender, "New admin is equal of previous");
        admin = _newAdmin;
    }

    // function addBeneficiaryRecord (address _beneficiary, string memory _msg, string memory _chkMsg, uint _lockDays) external payable 
    function addLetterRecord (address _beneficiary, string memory _msg, string memory _chkMsg, uint _lockDays) public 
    {
        // must send ether to calculate lock days
        // require(msg.value > dayCosts, "Some ETH are required to set the number of days the record will be blocked."); 
        // require beneficiary to be invited
        require (Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].choosed == true, "Beneficiary has not yet invited.");
        // require a valid public key from beneficiary
        require(bytes(Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].publicKey).length > 0, "Beneficiary haven't provide the publick key.");
        // require at least minimun days of lock
        require(_lockDays >= minimunLockAllowed, "The lock days are less than minumun lock allowed");
        
        uint recordCount = Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordCount;
        recordCount ++;
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[recordCount].recordMsg = _msg;
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[recordCount].checkingMsg = _chkMsg;
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[recordCount].lockedUntil = _calculateLockedUntil(_lockDays);
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordCount = recordCount;
        //return (true, recordCount);
        // emit addedBeneficiaryRecord (Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[recordCount], _beneficiary);
        emit addedLetterRecord (msg.sender, _beneficiary);
    }

    function updateLetterRecord (address _beneficiary, string memory _msg, string memory _chkMsg, uint _recordNum) public 
    {
        // require a valid record
        require(bytes(Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[_recordNum].recordMsg).length > 0, "There is no record to update.");
        
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[_recordNum].recordMsg = _msg;
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[_recordNum].checkingMsg = _chkMsg;
        // emit updatedLetterRecord (Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[_recordNum], _beneficiary);
        emit updatedLetterRecord (msg.sender, _beneficiary);
    }

    function nameBenificiary (address _beneficiary) public {
        require (Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].choosed == false, "Beneficiary already choosen");
        Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].choosed = true;
        emit namedBenificiary(msg.sender, _beneficiary);
    }

    function acceptWill (address _willOwner, string memory _publicKey) public {
        require (Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].choosed == true, "You are not been choosed as beneficiary.");
        require(bytes(Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].publicKey).length == 0, "Public key already privided.");
        Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].publicKey = _publicKey;
        emit beneficiaryAcceptance(_willOwner, msg.sender);
    }
    
    // //return Array of owned Record
    // function getOwnedRecord(address _beneficiary) public view returns(string[] memory) {
    //     string[] memory records = new string[](_getOwnedRecordNum(_beneficiary));
    //     for (uint i = 0; i < _getOwnedRecordNum(_beneficiary); i++) {
    //         records[i] = Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[i+1].checkingMsg;
    //         // logic goes here
    //     }
    //     return records;
    // }

    //return Array of owned Record
    function getOwnedRecord(address _beneficiary) public view returns (Record[] memory){
        Record[] memory records = new Record[](_getOwnedRecordNum(_beneficiary));
        for (uint i = 0; i < _getOwnedRecordNum(_beneficiary); i++) {
            Record storage record = Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordStructs[i+1];
            records[i] = record;
        }
        return records;
    }
    
    function _getOwnedRecordNum(address _beneficiary) private view returns(uint recordCount) {
        return Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].recordCount;
    }
    
    // function getMyRecord(address _willOwner) public view returns(string[] memory) {
    //     // require(now >= unlockDate);
    //     string[] memory records = new string[](_getMyRecordNum(_willOwner));
    //     for (uint i = 0; i < _getMyRecordNum(_willOwner); i++) {
    //         if (block.timestamp > Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].recordStructs[i+1].lockedUntil) {
    //             records[i] = Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].recordStructs[i+1].recordMsg;
    //         }
    //         // logic goes here
    //     }
    //     return records;
    // }

    //return Array of beneficiary Record
    function getMyRecord(address _willOwner) public view returns (Record[] memory){
        Record[] memory records = new Record[](_getMyRecordNum(_willOwner));
        for (uint i = 0; i < _getMyRecordNum(_willOwner); i++) {
            if (block.timestamp > Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].recordStructs[i+1].lockedUntil) {
                Record storage record = Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].recordStructs[i+1];
                records[i] = record;
            }
        }
        return records;
    }

    function AmIBeneficiary(address _willOwner) public view returns(bool) {
        return Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].choosed;
    }
    
    function getPublicKey(address _beneficiary) public view returns(string memory) {
        // require(bytes(Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].publicKey).length > 0, "Beneficiary haven't provide the publick key.");
        return Letters[msg.sender].BeneficiaryRecordStructs[_beneficiary].publicKey;
    }
    
    function _getMyRecordNum(address _willOwner) private view returns(uint recordCount) {
        return Letters[_willOwner].BeneficiaryRecordStructs[msg.sender].recordCount;
    }

    function _calculateLockedUntil (uint _days) private view returns(uint validUntil) {
        // uint validUntil = 0;
        validUntil = block.timestamp + (_days * 1 days);
        return validUntil;
    }
}