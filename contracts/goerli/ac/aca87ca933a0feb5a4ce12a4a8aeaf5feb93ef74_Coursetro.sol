/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity ^0.4.18;
contract Coursetro {
    
   string fName;
   uint age;
   
   function setInstructor(string _fName, uint _age) public {
       fName = _fName;
       age = _age;
   }
   
   function getInstructor() public constant returns (string, uint) {
       return (fName, age);
   }
    
}