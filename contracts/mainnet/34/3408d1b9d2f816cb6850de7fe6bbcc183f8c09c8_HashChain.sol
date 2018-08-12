pragma solidity ^0.4.24;

contract HashChain {
    event Iteration(
        address indexed sender,
        uint256 counter,
        bytes32 hash,
        string message
    );
    uint256 counter;
    bytes32 hash;
    
    constructor(string _msg) public {
        hash = keccak256(
            abi.encodePacked(counter, msg.sender, _msg)
        );
    }
    
    function iterate(string _msg) public returns (uint256, bytes32) {
        counter = ++counter;
        hash = keccak256(
            abi.encodePacked(hash, counter, msg.sender, _msg)
        );
        emit Iteration(msg.sender, counter, hash, _msg);
        return (counter, hash);
    }
    
    function getCounter() public view returns (uint256) {
        return counter;
    }
    
    function getHash() public view returns (bytes32) {
        return hash;
    }
    
    function getState() public view returns (uint256, bytes32) {
        return (getCounter(), getHash());
    }
}