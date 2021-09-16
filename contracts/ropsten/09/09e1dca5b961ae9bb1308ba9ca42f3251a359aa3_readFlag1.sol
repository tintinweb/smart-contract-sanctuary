/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract readFlag1 {
    // State variable to store a number
    string private flag = "flag{test}";

    // You can read from a state variable without sending a transaction.
    function get() public view returns (string memory) {
        return flag;
    }
}