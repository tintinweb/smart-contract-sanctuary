/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

contract Demo1 {
    
    event Received(address, uint);
    
    function addTest (uint256 a, uint256 b) public pure returns (uint256){
        return a + b;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}