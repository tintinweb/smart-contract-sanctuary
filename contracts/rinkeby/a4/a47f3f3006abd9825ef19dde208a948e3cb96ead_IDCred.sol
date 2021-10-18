/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity ^0.4.6;

contract IDCred {

  struct UserStruct {
    string hashId;
    uint index;
  }
  
  struct HashList {
    string hash;
    uint index;
  }
  
  mapping(address => UserStruct) private userStructs;
  mapping(address => HashList) private hashList;
  address[] private userIndex;

  event LogNewUser   (address indexed userAddress, uint index, string hashId);

  address[] private userIndexText;

  event LogNewUserText   (address indexed userAdd, uint index, string hash);

  function isUser(address userAddress)
    public 
    constant
    returns(bool isIndeed) 
  {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }
  


  function insertID(
    address userAddress, 
    string hashId
    ) 
    public
    returns(uint index)
  {
    if(isUser(userAddress)) return; 
    userStructs[userAddress].hashId = hashId;
    userStructs[userAddress].index     = userIndex.push(userAddress)-1;
    emit LogNewUser(
        userAddress, 
        userStructs[userAddress].index, 
        hashId);
    return userIndex.length-1;
  }
  
   function insertText(
    address userAdd, 
    string hash
    ) 
    public
    returns(uint index)
  {
    if(isUserText(userAdd)) return; 
    hashList[userAdd].hash = hash;
    hashList[userAdd].index     = userIndexText.push(userAdd)-1;
    emit LogNewUserText(
        userAdd, 
        hashList[userAdd].index, 
        hash);
    return userIndexText.length-1;
  }
  
    function isUserText(address userAdd)
    public 
    constant
    returns(bool isIndeed) 
  {
    if(userIndexText.length == 0) return false;
    return (userIndexText[hashList[userAdd].index] == userAdd);
  }
  
  function getText(address userAddress)
    public 
    constant
    returns(string hashId, uint index)
  {
      
    if(!isUser(userAddress)) return; 
    return(
      userStructs[userAddress].hashId, 
      hashList[userAddress].index);
  } 
  
  function getUserText(address userAdd)
    public 
    constant
    returns(string hashId, uint index)
  {
      
    if(!isUserText(userAdd)) return; 
    return(
      hashList[userAdd].hash, 
      hashList[userAdd].index);
  }
  
  


  function getUserCount() 
    public
    constant
    returns(uint count)
  {
    return userIndex.length;
  }
  
  function getUserTextCount() 
    public
    constant
    returns(uint count)
  {
    return userIndexText.length;
  }


}