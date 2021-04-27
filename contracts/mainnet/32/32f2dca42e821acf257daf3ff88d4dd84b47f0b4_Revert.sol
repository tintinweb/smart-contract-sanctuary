/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: gpl-3.0
pragma solidity >= 0.8.0 < 0.9.0;

contract Revert {
    fallback() external {
        revert(string(msg.data));
    }
}