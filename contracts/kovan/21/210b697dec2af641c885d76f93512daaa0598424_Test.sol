/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract Test {
    uint256 public number;

    function increase(uint256 amount) public {
        number += amount;
    }
}