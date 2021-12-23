/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Notary {

    struct NotaryData{
        string dataUrl;         // URI of the document
        bytes32 dataHash;       // Hash of the document
        uint256 dataTimestamp;  // Notarization unix time
    }

    mapping (uint256 => NotaryData) public notaryDataLedger;
    mapping (bytes32 => bool) private notaryHashes;
    uint256 public dataCounter;

    address public admin;

    event DocHashAdded(uint256 indexed num,
        string docuri,
        bytes32 dochash);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin () {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    /**
     * @dev add 2 numbers avoiding overflow
     * @param a first addendum
     * @param b second addendum
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    /**
     * @dev set a new admin for this contract
     * @param _newAdmin new admin address
     */
    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Address not allowed");
        admin = _newAdmin;
    }

    /**
     * @dev chack if an hash has been already registered or not
     * @param _hash data hash to search
     * @return true or false
     */
    function isHashAlreadyPresent(bytes32 _hash) public view returns(bool) {
        return notaryHashes[_hash];
    }

    /**
     * @dev set a new document structure to store in the list, queueing it if others exist and incremetning documents counter
     * @param _dataUri string for document URL
     * @param _dataHash bytes32 Hash to add to list
     */
    function addNewData(string memory _dataUri, bytes32 _dataHash) external onlyAdmin {
        require(isHashAlreadyPresent(_dataHash) == false, "Data hash already notarized");
        notaryDataLedger[dataCounter] = NotaryData({dataUrl: _dataUri, dataHash: _dataHash, dataTimestamp: block.timestamp});
        notaryHashes[_dataHash] = true;
        emit DocHashAdded(dataCounter, _dataUri, _dataHash);
        dataCounter = add(dataCounter, 1); //prepare for next data to add
    }

    /**
     * @dev get a hash in the _num place
     * @param _num uint256 Place of the hash to return
     * @return string name, bytes32 hash, uint256 datetime
     */
    function getDataInfo(uint256 _num) external view returns (string memory, bytes32, uint256) {
        return (notaryDataLedger[_num].dataUrl, notaryDataLedger[_num].dataHash, notaryDataLedger[_num].dataTimestamp);
    }

    /**
     * @dev get the hash list length
     * @return number of data already registered
     */
    function getDataCount() external view returns (uint256) {
        return dataCounter;
    }

}