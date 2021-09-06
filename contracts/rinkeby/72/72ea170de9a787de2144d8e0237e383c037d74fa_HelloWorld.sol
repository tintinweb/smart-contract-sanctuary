/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract HelloWorld {
    string public message;
    
    function update(string memory newMessage) public {
        message = newMessage;
    }

    
}