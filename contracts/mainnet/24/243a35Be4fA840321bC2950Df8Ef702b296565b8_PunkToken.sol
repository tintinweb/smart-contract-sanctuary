// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract PunkToken is ERC20 {
    constructor() public ERC20("Punk", "PUNK") {
        _mint(msg.sender, 10000 * 10**18);
    }
}
