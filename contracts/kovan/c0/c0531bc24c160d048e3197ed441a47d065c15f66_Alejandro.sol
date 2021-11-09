/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Alejandro {
    
    string public name = 'AlejandroGuay';
    
function suma(uint256 a, uint256 b) 
    external 
    view 
    returns (uint256) {
    return a + b;
}

function setName(string calldata newName) external {
    name = newName;
}
    
}