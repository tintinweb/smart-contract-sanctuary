// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./PaymentSplitter.sol";

contract ShibaMonstersMintSplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {}
}