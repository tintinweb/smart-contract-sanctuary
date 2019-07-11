/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.25;

contract SkillChain {

  struct UserStruct {
    string skillData;
   
    uint index;
  }
  
  mapping(uint256 => UserStruct) private userStructs;
  uint256[] private userIndex;

  event LogNewUser   (uint256 indexed skillId, uint index, string skillData);
  
  
  function isUser(uint256 skillId)
    public 
    constant
    returns(bool isIndeed) 
  {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[skillId].index] == skillId);
  }

  function insertUser(
    uint256 skillId, 
    string skillData) 
    public
    returns(uint index)
  {
    if(isUser(skillId)) throw; 
    userStructs[skillId].skillData = skillData;
    
    userStructs[skillId].index     = userIndex.push(skillId)-1;
    LogNewUser(
        skillId, 
        userStructs[skillId].index, 
        skillData);
    return userIndex.length-1;
  }

  
  
  function getUser(uint256 skillId)
    public 
    constant
    returns(string skillData,  uint index)
  {
    if(!isUser(skillId)) throw; 
    return(
      userStructs[skillId].skillData, 
      userStructs[skillId].index);
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
    returns(uint256 skillId)
  {
    return userIndex[index];
  }

}