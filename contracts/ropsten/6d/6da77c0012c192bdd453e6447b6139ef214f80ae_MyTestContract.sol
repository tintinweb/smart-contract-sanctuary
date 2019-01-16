pragma solidity ^0.4.16;
contract MyTestContract {
 
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