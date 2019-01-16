pragma solidity ^0.4.25;

contract Test {
    string public name;
   function setName(string _name) public {
       name = _name;
   }
   function getName() public returns(string){
       return name;
   }
}