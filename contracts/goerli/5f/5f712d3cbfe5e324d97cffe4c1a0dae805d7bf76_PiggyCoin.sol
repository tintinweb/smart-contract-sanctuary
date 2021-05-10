// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract PiggyCoin is ERC20 {
    constructor(uint256 initialSupply, uint8 _decimals) public ERC20("PiggyCoin", "PC") {
        _mint(msg.sender, initialSupply);
        _setupDecimals(_decimals);
    }
}