/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract testProject{
 uint public age;

 function setAge() public {
     age = 38;
 }

function getAge()public view returns(uint Age){
    return age;
}

}