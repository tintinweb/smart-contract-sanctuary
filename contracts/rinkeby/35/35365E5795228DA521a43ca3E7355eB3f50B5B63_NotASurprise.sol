pragma solidity 0.4.19;

contract NotASurprise {
 
 struct Camper {
   bool isHappy;
 }
 
 mapping(uint => Camper) public campers;
 
 function setHappy(uint index) public {
   campers[index].isHappy = true;
 }
 function surpriseOne(uint index) public {
   Camper c = campers[index];
   c.isHappy = false;
 }
 
}