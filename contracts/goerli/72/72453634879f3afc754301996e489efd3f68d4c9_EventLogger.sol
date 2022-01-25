/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventLogger {
    event Consumed(address indexed _consumer, uint256 _consumableId, uint256 _ballmanId);
    event Transferred(address indexed _from, address indexed _to, uint256 _consumableId);

    function consume() external {
        emit Consumed(msg.sender, 1, 5);
    }

    function transfer() external {
        emit Transferred(msg.sender, address(0), 1);
    }
}