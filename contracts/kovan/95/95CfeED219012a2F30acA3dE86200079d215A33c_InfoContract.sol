/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract InfoContract {

   string public fName;
   uint public age;

    event Instructor(
       string indexed name,
       uint age
    );
    
   function setInfo(string memory _fName, uint _age) public {
       fName = _fName;
       age = _age;
       emit Instructor(_fName, _age);
   }
}