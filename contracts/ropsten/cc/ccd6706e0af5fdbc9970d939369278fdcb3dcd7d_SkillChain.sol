pragma solidity ^0.4.22;

contract SkillChain {

  struct UserStruct {
    bytes32 skillData;
   
    uint index;
  }
  
  mapping(address => UserStruct) private userStructs;
  address[] private userIndex;

  event LogNewUser   (address indexed userAddress, uint index, bytes32 skillData);
  
  
  function isUser(address userAddress)
    public 
    constant
    returns(bool isIndeed) 
  {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }

  function insertUser(
    address userAddress, 
    bytes32 skillData) 
    public
    returns(uint index)
  {
    if(isUser(userAddress)) throw; 
    userStructs[userAddress].skillData = skillData;
    
    userStructs[userAddress].index     = userIndex.push(userAddress)-1;
    LogNewUser(
        userAddress, 
        userStructs[userAddress].index, 
        skillData);
    return userIndex.length-1;
  }

  
  
  function getUser(address userAddress)
    public 
    constant
    returns(bytes32 skillData,  uint index)
  {
    if(!isUser(userAddress)) throw; 
    return(
      userStructs[userAddress].skillData, 
      userStructs[userAddress].index);
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