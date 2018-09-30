pragma solidity ^0.4.0;

contract BlockHashStorage {
    address public owner;
    mapping(uint => bytes32) public history;

    constructor() public {
        owner = msg.sender;
    }

    function publish(uint blockNumber, bytes32 blockHash) public {
        require(history[blockNumber] >= 0, "This blocknumber has already had a hash written ");
        require(owner == msg.sender, "This method can only be invoked by contract owner");
        history[blockNumber] = blockHash; 
    }

    function getHash(uint blockNumber) public view returns (bytes32) {
        return history[blockNumber];
    }
}