/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity ^0.4.21;

contract InfoContract {
    
   string fName;
   uint age;
   
   function setInfo(string _fName, uint _age) public {
       fName = _fName;
       age = _age;
   }
   
   function getInfo() public constant returns (string, uint) {
       return (fName, age);
   }   
}