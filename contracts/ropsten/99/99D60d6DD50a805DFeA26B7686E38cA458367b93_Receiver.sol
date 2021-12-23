/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Receiver {
    event Received(address caller, uint amount, string message);

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

    function foo(string memory _message, uint _x) public payable returns (uint) {
        emit Received(msg.sender, msg.value, _message);

        return _x + 1;
    }
}