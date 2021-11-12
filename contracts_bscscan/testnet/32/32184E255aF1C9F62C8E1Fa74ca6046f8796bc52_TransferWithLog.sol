// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// TransferWithLog is a replacement for a standard ETH transfer, with an added
/// log to make it easily searchable.
contract TransferWithLog {
    event LogTransferred(address indexed from, address indexed to, uint256 amount);

    function transferWithLog(address payable to) external payable {
        require(to != address(0x0), "TransferWithLog: invalid empty recipient");
        uint256 amount = msg.value;
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "TransferWithLog: transfer failed");
        emit LogTransferred(msg.sender, to, amount);
    }
}