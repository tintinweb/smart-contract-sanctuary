/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity ^0.8.0;

contract Record {
    mapping(uint => bytes32) public messageHash;
    uint i;
    function addHash(string memory message) public {
        messageHash[i] = keccak256(abi.encode(message));
        i++;
    }
}