/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.7;


contract Locker0 {
    
    string private masterKey;
    string[] private keysStored;
    mapping(string => string) private keysStore;
    
    constructor(string memory _masterKey) {
        masterKey = _masterKey;
    }
    
    function addData(string memory _key, string memory _data, string memory _masterKey) public {
        require(keccak256(bytes(_masterKey)) == keccak256(bytes(masterKey)), "Wrong Master Key");
        keysStore[_key] = _data;
        keysStored.push(_key);
    }
    
    function getData(string memory _key, string memory _masterKey) public view returns(string memory) {
        require(keccak256(bytes(_masterKey)) == keccak256(bytes(masterKey)), "Wrong Master Key");
        return keysStore[_key];
    }
    
    function totalStored(string memory _masterKey) public view returns (string [] memory) {
        require(keccak256(bytes(_masterKey)) == keccak256(bytes(masterKey)), "Wrong Master Key");
        return keysStored;
    }
    
}