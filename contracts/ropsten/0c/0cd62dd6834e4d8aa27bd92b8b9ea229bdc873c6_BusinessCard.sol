/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.4.13;
 
contract BusinessCard {
    
    mapping (bytes32 => string) data;
    
    function setData(string key, string value) public {
        data[keccak256(key)] = value;
    }
    
    function getData(string key) public constant returns(string) {
        return data[keccak256(key)];
    }
 
}