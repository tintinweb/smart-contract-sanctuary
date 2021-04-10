/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: Toknify

pragma solidity 0.6.12;

contract Payer {
    constructor(address payable[] memory clients, uint256[] memory amounts) public payable {
        uint256 length = clients.length;
        require(length == amounts.length);

        for (uint256 i = 0; i < length; i++)
            clients[i].transfer(amounts[i]);

        msg.sender.transfer(address(this).balance);
    }
}