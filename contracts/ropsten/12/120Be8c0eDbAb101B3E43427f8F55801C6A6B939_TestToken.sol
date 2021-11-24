// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Ownable.sol";
import "ERC20.sol";
import "ERC20Burnable.sol";

contract TestToken is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 initialSupply) ERC20("RUIORK", "RUK") {
        _mint(msg.sender, initialSupply);
    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}