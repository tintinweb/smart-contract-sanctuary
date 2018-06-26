pragma solidity ^0.4.21;

contract Developer {

   string name;
   uint age;

   function setDeveloper(string _name, uint _age) public {
       name = _name;
       age = _age;
   }

   function getDeveloper() public view returns (string, uint) {
       return (name, age);
   }

}