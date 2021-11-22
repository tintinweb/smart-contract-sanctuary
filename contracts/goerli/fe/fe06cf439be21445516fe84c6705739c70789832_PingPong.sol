/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract PingPong {
    
    function Ping () payable public {
        payable(msg.sender).transfer(msg.value);
    }
    
}