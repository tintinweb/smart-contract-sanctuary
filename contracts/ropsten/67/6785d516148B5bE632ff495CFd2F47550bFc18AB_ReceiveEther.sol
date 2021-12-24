/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract ReceiveEther {
    // log
    event Received(string func, bytes data);

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        emit Received("fallback()" ,msg.data);
    }

    function getBalance() public view returns (uint) {
    }
}