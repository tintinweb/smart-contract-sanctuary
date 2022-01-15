/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

contract CricStoxRelayer {

    fallback () external {
        emit Logging(msg.sender, msg.data);
    }

    event Logging(address sender, bytes data);
}