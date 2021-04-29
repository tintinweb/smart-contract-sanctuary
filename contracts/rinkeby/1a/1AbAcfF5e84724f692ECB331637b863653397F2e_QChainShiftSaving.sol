/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.5.0;

contract QChainShiftSaving{

  struct UserStruct {
    string idUser;
    string jsonData;
    uint index;
  }
  
  mapping(address => UserStruct) private userStructs;
  address[] private userIndex;

  event LogNewUser   (address indexed userAddress, uint index, string idUser, string jsonData);
  event LogUpdateUser(address indexed userAddress, uint index, string idUser, string jsonData);
  
  function isUser(address userAddress)
    public 
    constant
    returns(bool isIndeed) 
  {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }

  function insertShiftData(
    address userAddress, 
    string idUser,
    string jsonData) 
    public
    returns(uint index)
  {
    if(isUser(userAddress)) throw; 
    userStructs[userAddress].idUser = idUser;
    userStructs[userAddress].jsonData   = jsonData;
    userStructs[userAddress].index     = userIndex.push(userAddress)-1;
    LogNewUser(
        userAddress, 
        userStructs[userAddress].index, 
        idUser, 
        jsonData);
    return userIndex.length-1;
  }
  
  function getUser(address userAddress)
    public 
    constant
    returns(string idUser, string jsonData, uint index)
  {
    if(!isUser(userAddress)) throw; 
    return(
      userStructs[userAddress].idUser, 
      userStructs[userAddress].jsonData,
      userStructs[userAddress].index);
  } 
  
  function updateJsonData(address userAddress, string jsonData) 
    public
    returns(bool success) 
  {
    if(!isUser(userAddress)) throw; 
    userStructs[userAddress].jsonData = jsonData;
    LogUpdateUser(
      userAddress, 
      userStructs[userAddress].index,
      jsonData, 
      userStructs[userAddress].idUser);
    return true;
  }
  

  function getUserCount() 
    public
    constant
    returns(uint count)
  {
    return userIndex.length;
  }

  function getUserAtIndex(uint index)
    public
    constant
    returns(address userAddress)
  {
    return userIndex[index];
  }

}