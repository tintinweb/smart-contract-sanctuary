// SPDX-License-Identifier: Unlisensed
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract JobbyCoin is ERC20 {
    constructor (uint256 initialSupply) public ERC20("JobbyCoin", "AMK") {
        _mint(msg.sender, initialSupply);
    }
}