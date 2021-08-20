// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IBEP20.sol";

contract BulkSend is Ownable {
    uint256 public txCount = 0;

    event BulkTransferCompleted(
        uint256 indexed total,
        address indexed tokenAddress,
        uint256 indexed transactionId
    );

    function bulkTransfer(
        uint256 transactionId,
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata balances
    ) public payable onlyOwner {
        uint256 total = 0;
        uint256 i = 0;
        IBEP20 token = IBEP20(tokenAddress);

        for (i; i < recipients.length; i++) {
            if (balances.length > 1) {
                require(
                    balances.length == recipients.length,
                    "Specify amount for all the recipients please"
                );
                token.transferFrom(msg.sender, recipients[i], balances[i]);
                total += balances[i];
            } else {
                require(balances.length == 1, "Specify a single amount");
                token.transferFrom(msg.sender, recipients[i], balances[0]);
                total += balances[0];
            }
        }

        txCount++;
        emit BulkTransferCompleted(total, tokenAddress, transactionId);
    }
}