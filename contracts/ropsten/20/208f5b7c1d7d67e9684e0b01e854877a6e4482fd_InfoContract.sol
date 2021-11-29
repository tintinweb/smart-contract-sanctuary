/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract InfoContract {

   string fName;
   uint   age;




   function setInfo(string memory _fName, uint _age) public  {
       fName = _fName;
       age = _age;
   }
    function getInfo() public view returns (string memory,uint) {
        return (fName,age);
    }

}