/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title PrivacyPreserving
 * @dev A privacy preserving smart contract
 */
contract PrivacyPreserving {

    event RegisteredHashOfScan(uint256 _hashofScan);
    event StoredRecordLocation(uint256 indexed _transactionID, string _record);
    event CreatedTransaction(uint256 indexed _publicID, uint256 _hashOfRecord);

    struct Transaction {
        uint256 publicID;
        uint256 hashOfRecord;
    }

    uint256[] internal hashOfScans;
    mapping(uint256 => bool) internal isRegistered;
    Transaction[] internal transactions;
    mapping(uint256 => string) internal transactionIDToRecord;

    /**
     * @dev Register the hash of a user's scan
     * @param _hashOfScan LSH of the scan
     */
    function registerHashOfScan(uint256 _hashOfScan) public {
        require(isRegistered[_hashOfScan] == false, "That hash of scan is already registered.");
        hashOfScans.push(_hashOfScan);
        isRegistered[_hashOfScan] = true;
        emit RegisteredHashOfScan(_hashOfScan);
    }
    /**
     * @dev Return hashOfScans 
     * @return value of 'biometricHashes'
     */
    function getHashOfScans() public view returns (uint256[] memory){
        return hashOfScans;
    }
    /**
     * @dev Store a transaction to record the details of a record to store
     * @param _transactionID The transactionID to map the location of the record
     * @param _record The storage location of the encrypted record
     */
    function storeRecordLocation(uint256 _transactionID, string memory _record) public {
        require(keccak256(bytes(transactionIDToRecord[_transactionID])) == keccak256(bytes("")), "That transactionID already exists.");
        transactionIDToRecord[_transactionID] = _record;
        emit StoredRecordLocation(_transactionID, _record);
    }
    /**
     * @dev Store a hash of a record in a mapping from the publicID to the hash of the records 
     * @param _transactionID The transactionID mapping to the location of the encrypted record
     * @return value of the location of the record if it exists
     */
    function retrieveRecordLocation(uint256 _transactionID) public view returns (string memory) {
        string memory recordLocation = transactionIDToRecord[_transactionID];
        require(keccak256(bytes(recordLocation)) != keccak256(bytes("")), "The location of the record is empty.");
        return recordLocation;
    }
    /**
     * @dev Store a transaction to record the details of a record to store
     * @param _publicID The public ID
     * @param _hashOfRecord The hash of the record
     */
    function addTransaction(uint256 _publicID, uint256 _hashOfRecord) public {
        transactions.push(Transaction(_publicID, _hashOfRecord));
        emit CreatedTransaction(_publicID, _hashOfRecord);
    }
    /**
     * @dev Return all transactions 
     * @return value of 'transactions'
     */
    function getTransactions() public view returns (Transaction[] memory){
        return transactions;
    }    
}