pragma solidity ^0.4.0;

contract BlockHashStorage {
    address public owner;
    mapping(uint => bytes32) public history;

    function BlockHashStorage() public {
        owner = msg.sender;
    }

    // Throws an exception if called by any account other than the `owner`.
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function publish(uint blockNumber, bytes32 blockHeader) public onlyOwner {
        assert(history[blockNumber] > 0);
        history[blockNumber] = blockHeader; 
    }

    function getHash(uint blockNumber) public view returns (bytes32) {
        return history[blockNumber];
    }
}