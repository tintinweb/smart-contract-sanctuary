/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Receiver {
    uint public x;
    event Received(address caller, uint amount, string message);

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

    function foo(string memory _message, uint _x) public payable returns (uint) {
        emit Received(msg.sender, msg.value, _message);
        x += _x;

        return _x + 1;
    }
}