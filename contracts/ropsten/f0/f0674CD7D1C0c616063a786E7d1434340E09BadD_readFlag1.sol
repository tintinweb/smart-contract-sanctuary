/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract readFlag1 {
    string private flag = "flag{etherscan_S0urc3_c0de}";

    function get() public view returns (string memory) {
        return flag;
    }
}