/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL
pragma solidity ^0.4.25;

contract Disperse {
    function disperseEther(
        address[] recipients,
        uint256 value
    ) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(value);

        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }
}