// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract SuezToken is ERC20 {
    constructor() public ERC20("Suez Token", "SUEZ") {
        _setupDecimals(0);
        _mint(msg.sender, 20210401 * (10 ** uint256(decimals())));
    }
}