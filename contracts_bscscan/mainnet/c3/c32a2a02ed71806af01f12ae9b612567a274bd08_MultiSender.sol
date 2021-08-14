// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IERC20.sol";

contract MultiSender {

     function transferToken(IERC20 token, address[] memory receivers, uint  amounts ) public {
require(receivers.length == amounts, "Receivers and amounts array is not the same length");

        for(uint index = 0; index < amounts; index++) {
            token.transferFrom(msg.sender, receivers[index], amounts);
        }
    }
    

    
}