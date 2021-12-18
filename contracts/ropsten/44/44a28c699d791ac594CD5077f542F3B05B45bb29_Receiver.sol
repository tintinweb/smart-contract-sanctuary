/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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