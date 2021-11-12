/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

contract Faucet {
    address owner;
    
    function withdraw() public {
        payable(msg.sender).transfer(300000000000000000);
    }
    
    receive () external payable {}
}