/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataRetrieve{
    mapping(string => string) public currentData;
    
    function setData(string memory _key,string memory _data) public {
        currentData[_key] = _data;
    }
    function getData(string memory _key) view public returns (string memory){
        return currentData[_key];
    }
    
    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
        
    }
    
    function isUsed(string memory _key) view public returns (bool){
        return !(compareStrings(currentData[_key],""));
    }
}