// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IBEP20.sol";

contract MassSend is Ownable {
    uint256 public txCount = 0;

    function bulkTransfer(
        address tokenAddress,
        address[] calldata recipients,
        uint256 balance
    ) public onlyOwner {
        uint256 total = 0;
        uint256 i = 0;
        uint256 decimal = 10**18;

        uint256 amountToSend = balance * decimal;

        IBEP20 token = IBEP20(tokenAddress);

        for (i; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amountToSend);
            total += balance;
        }

        txCount++;
    }
}