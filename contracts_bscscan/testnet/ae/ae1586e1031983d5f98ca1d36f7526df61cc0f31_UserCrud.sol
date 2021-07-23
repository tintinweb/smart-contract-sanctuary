/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract UserCrud {

  struct UserStruct {
    string  userEmail;
    uint    userAge;
    uint256 index;
    address userAddr; 
  }
  
  mapping(address => UserStruct) private userStructs;
  address[] private userIndex;

  event LogNewUser   (address indexed userAddress, uint index, string userEmail, uint userAge, address userAddr);
  event LogUpdateUser(address indexed userAddress, uint index, string userEmail, uint userAge);
  
  function isUser(address userAddress) public view returns(bool isIndeed) {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }

  /*function insertUser(address userAddress, string memory userEmail, uint userAge) public returns(uint index) {
    require (isUser(userAddress), "User Address Found"); 
    userStructs[userAddress].userEmail = userEmail;
    userStructs[userAddress].userAge   = userAge;
    userIndex.push(userAddress);
    userStructs[userAddress].index     = userIndex.length -1;

    emit LogNewUser(userAddress, userStructs[userAddress].index, userEmail, userAge, msg.sender);
    return userIndex.length -1;
  }*/
  
   function CreatetUser(address userAddress, string memory userEmail, uint userAge) public {
    require (!isUser(userAddress), "User Address Found"); 
    userStructs[userAddress].userEmail = userEmail;
    userStructs[userAddress].userAge   = userAge;
    userStructs[userAddress].userAddr  = msg.sender;
    userIndex.push(userAddress);    
    userStructs[userAddress].index     = userIndex.length -1;
    emit LogNewUser(userAddress, userStructs[userAddress].index, userEmail, userAge, msg.sender);
  }
  
  function getUser(address userAddress) public view returns(string memory userEmail, uint userAge, uint index) {
    require (isUser(userAddress), "User Address Not Found"); 
    return(userStructs[userAddress].userEmail, userStructs[userAddress].userAge, userStructs[userAddress].index);} 
  
  function updateUserEmail(address userAddress, string memory userEmail) public returns(bool success) {
    require (!isUser(userAddress), "User Address Found"); 
    userStructs[userAddress].userEmail = userEmail;
    emit LogUpdateUser(userAddress, userStructs[userAddress].index, userEmail, userStructs[userAddress].userAge);
    return true;
  }
  
  function updateUserAge(address userAddress, uint userAge) public returns(bool success) {
    require (isUser(userAddress), "User Address Not Found"); 
    userStructs[userAddress].userAge = userAge;
    emit LogUpdateUser(userAddress, userStructs[userAddress].index, userStructs[userAddress].userEmail, userAge);
    return true;
  }

  function getUserCount() public view returns(uint count){
    return userIndex.length;
  }

  function getUserAtIndex(uint index) public view returns(address userAddress) {
    return userIndex[index];
  }

}