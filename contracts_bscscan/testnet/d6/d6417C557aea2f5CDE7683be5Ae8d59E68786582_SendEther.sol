// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract SendEther {
    function sendViaTransfer(address payable _to, uint256 amount) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to, uint256 amount) public {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(amount);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to, uint256 amount) public {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}