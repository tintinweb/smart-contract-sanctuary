/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PayableContract {
    event ValueReceived(address user, uint amount);
    
    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }
}