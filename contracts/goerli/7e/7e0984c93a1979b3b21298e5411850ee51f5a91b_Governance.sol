/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface IGovernance {
    function requestPermission(address sender, address target) external view;
}

contract Governance is IGovernance {
    function requestPermission(address sender, address target) external view override {

    }
}