pragma solidity ^0.4.25;

contract SkillChain {

  struct UserStruct {
    bytes32 skillData;
   
    uint index;
  }
  
  mapping(uint256 => UserStruct) private userStructs;
  uint256[] private userIndex;

  event LogNewUser   (uint256 indexed userId, uint index, bytes32 skillData);
  
  
  function isUser(uint256 userId)
    public 
    constant
    returns(bool isIndeed) 
  {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userId].index] == userId);
  }

  function insertUser(
    uint256 userId, 
    bytes32 skillData) 
    public
    returns(uint index)
  {
    if(isUser(userId)) throw; 
    userStructs[userId].skillData = skillData;
    
    userStructs[userId].index     = userIndex.push(userId)-1;
    LogNewUser(
        userId, 
        userStructs[userId].index, 
        skillData);
    return userIndex.length-1;
  }

  
  
  function getUser(uint256 userId)
    public 
    constant
    returns(bytes32 skillData,  uint index)
  {
    if(!isUser(userId)) throw; 
    return(
      userStructs[userId].skillData, 
      userStructs[userId].index);
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
    returns(uint256 userId)
  {
    return userIndex[index];
  }

}