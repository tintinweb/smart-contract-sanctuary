/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Impl {
    
    event LOG(bytes indexed log);
 
    
    function log() public {
        emit LOG(msg.data);
    }
}