pragma solidity ^0.8.0;

contract Test{
  struct Tier {
    address user;
    uint value;
    string sign;
  }

  Tier userTier;
  
  constructor(Tier memory tier){
    userTier = tier;
  } 

  function getTier() public view returns(Tier memory){
    return userTier;
  }
}