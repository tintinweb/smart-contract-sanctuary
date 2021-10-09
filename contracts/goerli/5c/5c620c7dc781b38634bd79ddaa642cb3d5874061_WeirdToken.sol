// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WeirdToken is ERC20 {
    constructor() ERC20("Weird", "WEIRD") {
        _mint(msg.sender, 401775000e18);
    }
}