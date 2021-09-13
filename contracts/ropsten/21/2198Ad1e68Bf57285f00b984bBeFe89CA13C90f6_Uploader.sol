/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity 0.4.26;

contract Uploader {
    address public owner;
    struct Record {
        uint64 begin;
        uint64 end;
        uint64 timestamp;
        bytes fingerprint;
    }
    Record[] Records;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        uint64 _begin,
        uint64 _end,
        uint64 _timestamp,
        bytes _fingerprint
    ) public {
        owner = msg.sender;
        Records.push(Record(_begin, _end, _timestamp, _fingerprint));
    }

    /**
     * @dev Function to upload the blockchain fingerprint.
     * @param _begin uint64 The beginning block of the fingerprint.
     * @param _end uint64 The ending block of the fingerprint.
     * @param _timestamp uint64 The uploaded time of the fingerprint
     * @param _fingerprint bytes The fingerprint from the beginning block to the end block
     */
    function uploadNewRecord(
        uint64 _begin,
        uint64 _end,
        uint64 _timestamp,
        bytes _fingerprint
    ) external onlyOwner {
        Records.push(Record(_begin, _end, _timestamp, _fingerprint));
    }

    /**
     * @dev Function to retrieve the record by the block number.
     * @param blockNumber uint64 The block number which is used to retrieve the fingerprint including it.
     * @return (uint64, uint64, uint64, bytes) The latest record.
     */
    function getRecordByBlockNumber(uint64 blockNumber)
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            bytes
        )
    {
        uint256 len = getRecordsLength();
        Record memory record = Records[len - 1];
        uint64 end = record.end;
        require(blockNumber <= end, "The record havn't uploaded yet.");
        uint64 ans = binarySearch(0, uint64(len) - 1, blockNumber);
        Record memory res = Records[ans];
        return (res.begin, res.end, res.timestamp, res.fingerprint);
    }

    function binarySearch(
        uint64 begin,
        uint64 end,
        uint64 value
    ) internal view returns (uint64) {
        uint64 len = end - begin;
        uint64 mid = begin + len / 2;
        Record memory record = Records[mid];
        if (record.begin > value) return binarySearch(begin, mid, value);
        else if (record.end < value) return binarySearch(mid + 1, end, value);
        else return mid;
    }

    /**
     * @dev Function to retrieve the length of the record.
     * @return uint256 The count of the records.
     */
    function getRecordsLength() public view returns (uint256) {
        return Records.length;
    }

    /**
     * @dev Function to retrieve the latest record.
     * @return (uint64, uint64, uint64, bytes) The latest record.
     */
    function getLatestRecord()
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            bytes
        )
    {
        Record memory record = Records[getRecordsLength() - 1];
        return (record.begin, record.end, record.timestamp, record.fingerprint);
    }

    /**
     * @dev Function to retrieve the latest record.
     * @param index uint64 The index of the record which will be retrieved.
     * @return (uint64, uint64, uint64, bytes) The record with the input index.
     */
    function getRecordByIndex(uint256 index)
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            bytes
        )
    {
        require(index <= Records.length, "Out of index");
        Record memory record = Records[index - 1];
        return (record.begin, record.end, record.timestamp, record.fingerprint);
    }
}