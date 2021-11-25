/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract MultisendDescription {
    function description(string calldata _description) external pure returns (string calldata) {
        return _description;
    }
}