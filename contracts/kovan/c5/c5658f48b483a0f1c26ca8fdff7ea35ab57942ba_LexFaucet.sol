/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.8.0;

contract LexFaucet {
    function claimETH() external {
        (bool success, ) = msg.sender.call{value: 1 ether / 1000}(""); 
        require(success, "!payable");
    }
    
    receive() external payable {} 
}