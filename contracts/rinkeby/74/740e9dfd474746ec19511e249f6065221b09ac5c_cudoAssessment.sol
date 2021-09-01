/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract cudoAssessment {

    uint256 public number;

    function callMe() external {
        number = number + 1;
    }
}