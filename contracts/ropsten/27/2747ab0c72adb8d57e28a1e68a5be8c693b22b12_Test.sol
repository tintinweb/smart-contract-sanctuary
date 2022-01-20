/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Test {
    function willRevert() pure external {
        revert("hello");
    }
}