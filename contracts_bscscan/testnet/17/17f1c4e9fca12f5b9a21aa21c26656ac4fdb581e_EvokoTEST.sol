// SPDX-License-Identifier: Unlisensed
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract EvokoTEST is ERC20 {
    constructor (uint256 initialSupply) ERC20("EvokoTEST", "EVT") {
        _mint(msg.sender, initialSupply);
    }
}