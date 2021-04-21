// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./erc20.sol";

contract Test is ERC20 {
    constructor() ERC20("Test", "TTK") {
        _mint(msg.sender, 1000);
    }
}