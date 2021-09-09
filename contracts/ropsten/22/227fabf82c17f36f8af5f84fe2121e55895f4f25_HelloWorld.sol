/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: No-license 
pragma solidity 0.8.7; 

contract HelloWorld { 
    uint public age; 

    function setAge(uint ageToBeSet) public { 
        age = ageToBeSet; 
    } 

    function getAge() public view returns (uint) { 
        return age; 
    } 
}