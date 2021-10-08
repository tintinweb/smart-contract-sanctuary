pragma solidity 0.4.19;

contract NotASurprise {
 
 struct Camper {
   bool isHappy;
 }
 
 uint public x = 100;
 
 mapping(uint => Camper) public campers;
 
 function setHappy(uint index) public {
   campers[index].isHappy = true;
 }
 
 function surpriseTwo() public {
   Camper storage c;
   c.isHappy = false;
 }
}