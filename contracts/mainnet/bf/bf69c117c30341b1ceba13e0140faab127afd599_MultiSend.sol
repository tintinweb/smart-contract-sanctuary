/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

interface IMaidCoin {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract MultiSend {
    function send(IMaidCoin token, address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }
}