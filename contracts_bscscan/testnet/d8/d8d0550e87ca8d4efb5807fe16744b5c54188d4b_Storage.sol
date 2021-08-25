/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
    string public message;
    constructor (string memory initialMessage) {
        message=initialMessage;
    }
    
    function update (string memory newMsg) public{
        message=newMsg;
    }
}