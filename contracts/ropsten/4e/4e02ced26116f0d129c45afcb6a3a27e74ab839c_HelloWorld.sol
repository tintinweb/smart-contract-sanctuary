pragma solidity ^0.4.16;
contract HelloWorld {
 
 uint256 counter = 5; //state variable we assigned earlier
 address owner = msg.sender;
function add() public {  //increases counter by 1
  counter++;
 }
 
 function subtract() public { //decreases counter by 1
  counter--;
 }
 function getCounter() public constant returns (uint256) {
  return counter;
    } 
    
    function kill() public { //self-destruct function, 
   if(msg.sender == owner) {
    selfdestruct(owner); 
        }
    }
}