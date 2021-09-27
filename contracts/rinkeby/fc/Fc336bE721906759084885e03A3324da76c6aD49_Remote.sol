/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Remote {
    function getSender() external view returns(address) {
        return msg.sender;
    }
    
        
    function getString123() external pure returns (string memory) {
        return "123123";
    }
}