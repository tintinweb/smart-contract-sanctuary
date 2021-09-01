/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract InfoContract {

   string fName;
   uint age;

   function setInfo(string memory _fName, uint _age) public {
       fName = _fName;
       age = _age;
   }

   function getInfo() public view returns (string memory, uint) {
       return (fName, age);
   }
}