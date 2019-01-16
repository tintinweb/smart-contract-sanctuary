pragma solidity ^0.4.25;

//string可能導致web3接收問題

contract InfoContract {

   uint fName;
   uint age;

   function setInfo(uint _fName, uint _age) public {
       fName = _fName;
       age = _age;
   }

   function getInfo() public constant returns (uint, uint) {
       return (fName, age);
   }
}