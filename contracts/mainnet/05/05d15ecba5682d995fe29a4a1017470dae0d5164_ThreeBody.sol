// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ThreeBody is ERC20 {
    constructor() ERC20("Three-Body", "TBD") {
        _mint(msg.sender, 13800000000 * 10 ** decimals());
    }
}