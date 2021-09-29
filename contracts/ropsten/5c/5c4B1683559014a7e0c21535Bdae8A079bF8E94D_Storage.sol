/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    event Transfer(address indexed from, address indexed to, int value);
    event NI_Transfer(address, address, int);
    
    function act(address to, int amount) public {
        emit Transfer(msg.sender, to, amount);
        emit NI_Transfer(msg.sender, to, amount);
    }

}