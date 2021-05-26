/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.16;
contract HelloWorld {
 
 uint256 counter = 5; //state variable we assigned earlier
function add() public {  //increases counter by 1
  counter++;
 }
 
 function subtract() public { //decreases counter by 1
  counter--;
 }
 function getCounter() public constant returns (uint256) {
  return counter;
    } 
}