/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract SavePortfolioData {

  struct UserStruct {
    string coinString;
    uint index;
  }
  
  mapping(address => UserStruct) private userStructs;
  address[] private userIndex;

  event LogNewUser   (address indexed userAddress, uint index, string coinString);
  event LogUpdateUser(address indexed userAddress, uint index, string coinString);
  
  
  function isUser(address userAddress) public view returns(bool isIndeed) {
    if(userIndex.length == 0) return false;
    
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }


  function insertUser(address userAddress, string memory coinString) public payable returns(uint index) {
    if(isUser(userAddress)) revert(); 
    userStructs[userAddress].coinString = coinString;
    userStructs[userAddress].index = userIndex.length;
    
    userIndex.push(userAddress);
    
    emit LogNewUser(
        userAddress, 
        userStructs[userAddress].index, 
        coinString);
        
    return userIndex.length-1;
  }
  
  
  function getUser(address userAddress) public view returns(string memory coinString, uint index) {
    if(!isUser(userAddress)) revert(); 
    
    return(
      userStructs[userAddress].coinString, 
      userStructs[userAddress].index );
  } 
  
  
  function updateUsercoinString(address userAddress, string memory coinString) public payable returns(bool success) {
    if(!isUser(userAddress)) revert(); 
    userStructs[userAddress].coinString  = coinString;
    
    emit LogUpdateUser(
      userAddress, 
      userStructs[userAddress].index,
      coinString);
      
    return true;
  }


  function getUserCount() public view returns(uint count) {
    return userIndex.length;
  }


  function getUserAtIndex(uint index) public view returns(address userAddress) {
    return userIndex[index];
  }


}