/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract Ping {
    
    fallback () external payable {
        (payable(msg.sender)).transfer(address(this).balance);
    }
    
}