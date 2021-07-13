// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract LIVTOKEN is ERC20 {
    constructor() ERC20("LIVTOKEN", "LIV") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}