/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract dev_voting {
    
    address[] devArray;
    
    function addDevTeam(address _dev) public {
        devArray.push(_dev);
    }
    
    function displayDevArray() public returns (address[] memory){
        return devArray;
    }
}