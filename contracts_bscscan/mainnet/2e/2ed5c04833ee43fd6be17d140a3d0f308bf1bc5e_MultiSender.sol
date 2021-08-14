// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IERC20.sol";

contract MultiSender {




    function transferToken(IERC20 token, address[] memory holders, uint256 amounts ) public {
               require(holders.length == amounts, "Receivers and amounts array is not the same length");

        for(uint256 i = 0; i < amounts; i++) {
            token.transferFrom(msg.sender, holders[i], amounts);
        }
    }
}