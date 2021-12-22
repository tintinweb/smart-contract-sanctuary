// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SyloToken is ERC20 {
    constructor() ERC20("Sylo", "SYLO") {
        _mint(msg.sender, 10_000_000_000 ether);
    }
}