// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IBEP20.sol";

contract MassTransfer is Ownable {
    function batchTransfer(
        address tokenAddress,
        address[] calldata recipients,
        uint256 balance
    ) external onlyOwner {
        uint256 i;

        IBEP20 token = IBEP20(tokenAddress);

        for (i; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], balance);
        }
    }
}