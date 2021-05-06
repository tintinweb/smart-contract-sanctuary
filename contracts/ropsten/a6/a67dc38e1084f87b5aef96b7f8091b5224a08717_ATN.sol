// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract ATN is ERC20 {

	constructor(uint256 initialSupply) ERC20("ATN", "ATN") {
        _mint(msg.sender, initialSupply);
    }
}