//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;

import "ccToken.sol";

/// @title ccBTC
contract ccBTC is ccToken {
    constructor() ccToken("Cross-Chain BTC", "ccBTC", 8, (ERC20ControllerViewIf)(0)){}
}