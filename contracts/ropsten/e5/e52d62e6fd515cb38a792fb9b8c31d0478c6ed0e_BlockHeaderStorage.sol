pragma solidity ^0.4.0;

contract BlockHeaderStorage {
    mapping(uint => bytes32) public blocks;

    function update(uint blockNumber, bytes32 blockHeader) public {
        blocks[blockNumber] = blockHeader; 
    }

    function getHeader(uint blockNumber) public view returns (bytes32) {
        return blocks[blockNumber];
    }
}