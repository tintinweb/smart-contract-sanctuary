// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";

contract MlibreToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Mlibre", "MLB") {
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
    }
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}