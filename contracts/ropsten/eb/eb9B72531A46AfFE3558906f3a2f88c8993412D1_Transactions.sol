/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transactions {

    uint256 transactionCounter;

    event Transfer(address sender, address receiver, uint256 amount, string message, uint256 timestamp, string keyword);

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] transactions;

    function msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function sendTransaction(address payable receiver, uint256 amount, string memory message, string memory keyword) public {
        require(msgSender() != receiver, "Cannot send to the same address");
        transactionCounter++;
        transactions.push(TransferStruct(msgSender(), receiver, amount, message, block.timestamp, keyword));
        emit Transfer(msgSender(), receiver, amount, message, block.timestamp, keyword);
    }

    function allTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function transactionCount() public view returns (uint256) {
        return transactionCounter;
    }

}