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
    
    mapping(uint256 => string) private _messages;
    
    function setMessage(uint256 messageId, string memory message) public {
        _messages[messageId] = message;
    }
    
    function messageFor(uint256 messageId) public view returns (string memory) {
        string memory message = _messages[messageId];
        return message;
    }
}