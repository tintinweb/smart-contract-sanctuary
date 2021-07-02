// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./ERC20.sol";

contract WCS_Token is ERC20 {
    constructor() ERC20("Name", "TRIGRAMM") {
        _mint(msg.sender,  1000000000000000000000000);
    }
}