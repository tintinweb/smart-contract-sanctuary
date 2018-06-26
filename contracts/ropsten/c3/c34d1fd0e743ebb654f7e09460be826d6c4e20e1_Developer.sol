pragma solidity ^0.4.21;

/*
* @title-Developer
* @dev Developer sets name and age of developer
*/
contract Developer {
  string name;
  uint age;

/*
* @dev function setDeveloper sets name and age of Developer.
* @param _name as name of developer.
* @param _age age of developer.
* @returns result name in bytes32 returns by function.
*/
 function setDeveloper(string _name, uint _age) public returns (bytes32 result, uint) {
   name = _name;
   age = _age;
   bytes memory name32 = bytes(name);
   assembly {
     result := mload(add(name32, 32))
   }
   return (result, age);
 }

/*
* @dev function getDeveloper returns name and age of developer.
* @returns name and age of developer.
*/
 function getDeveloper() public view returns(string,uint) {
   return (name, age);
 }
}