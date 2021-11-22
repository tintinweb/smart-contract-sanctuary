/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract PingPong {
    
    constructor () payable {}
    
    function Ping () payable public {
        payable(msg.sender).transfer(msg.value + 0.01 ether);
    }
    
}