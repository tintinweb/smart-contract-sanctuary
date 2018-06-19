pragma solidity ^0.4.2;

contract Numa {

    event NewBatch(
        bytes32 indexed ipfsHash
    );

    function Numa() public { }
    
    function newBatch(bytes32 ipfsHash) public {
        NewBatch(ipfsHash);
    }
}