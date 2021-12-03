/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract TestContract {

    function sendViaTransfer(address payable _to) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);

        emit TransferSendExecuted(msg.value, tx.gasprice, msg.data);
    }

    function sendViaSend(address payable _to) public payable {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");

        emit TransferSendExecuted(msg.value, tx.gasprice, msg.data);
    }

    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");

        emit CallExecuted(msg.value, tx.gasprice, msg.data, data);
        require(sent, "Failed to send Ether");
    }

    event TransferSendExecuted(uint msgValue, uint gasPrice, bytes msgData);

    event CallExecuted(uint msgValue, uint gasPrice, bytes msgData, bytes callData);
}