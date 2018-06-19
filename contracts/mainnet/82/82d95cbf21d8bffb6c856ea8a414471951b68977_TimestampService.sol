pragma solidity ^0.4.0;

contract TimestampService {

    struct Timestamp {
        uint    timestamp;
        address sender;
    }
    mapping(bytes32 => Timestamp) public timestamps;

    function timestamp(bytes32 hash) public returns (bool) {
        if (timestamps[hash].timestamp != 0) {
            return false;
        }
        timestamps[hash].timestamp = block.timestamp;
        timestamps[hash].sender = msg.sender;
        return true;
    }
    function getTimestamp(bytes32 hash) public constant returns (uint) {
        return timestamps[hash].timestamp;
    }
    function getSender(bytes32 hash) public constant returns (address) {
        return timestamps[hash].sender;
    }

}