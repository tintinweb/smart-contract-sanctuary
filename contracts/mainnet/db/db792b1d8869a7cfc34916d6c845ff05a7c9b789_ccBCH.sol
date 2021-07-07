//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;

import "ccToken.sol";

/// @title ccBCH
contract ccBCH is ccToken {
    constructor() ccToken("Cross-Chain BCH", "ccBCH", 8, (ERC20ControllerViewIf)(0)){}
}