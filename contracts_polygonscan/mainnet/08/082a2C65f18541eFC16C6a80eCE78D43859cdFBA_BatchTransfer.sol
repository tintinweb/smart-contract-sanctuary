/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract BatchTransfer {
    function sendBal(address payable[] memory receiver) payable external {
        uint amount = msg.value / receiver.length;
        
        for (uint i = 0; i < receiver.length; i++) {
            receiver[i].transfer(amount);
        }
    }
}