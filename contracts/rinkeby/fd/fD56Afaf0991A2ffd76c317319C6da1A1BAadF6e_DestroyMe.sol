/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract DestroyMe {
    
    bool public isAlive = true;
    
    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
    
    function setAliveTrue() external {
        isAlive = true;
    }
}