/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

 contract Test{
     string public name;
     int public score;
     
     constructor(){
      name="logan";
      score=123;
     }
     
  
  event Logs(string name,int score);
  event LogsIndex(string indexed name,int indexed scroe);
  
  
  function show() public{
      emit  Logs(name,score);
      emit  LogsIndex(name,score);
      
  }
     
 }