/**
 *Submitted for verification at polygonscan.com on 2021-07-10
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

contract Test {
    
   string private data;
   string[] private stringList = new string[](1);
 
 
    function sendTextMessage(string memory message) public {
        data = message;
    }
    
    function addToArray(string memory message) public {
        stringList.push(message);
    }
    
    
    function getString() public view returns (string memory){
        return data;
    }
    
    
    function getLastPos(uint256 pos) public view returns (string memory){
        return stringList[pos];
    }
    
    function getArrayLength() public view returns (uint256){
        return stringList.length-1;
    }
    
    function getLatestMessage() public view returns (string memory){
        return stringList[stringList.length-1];
    }
    
    
    
    
    
}