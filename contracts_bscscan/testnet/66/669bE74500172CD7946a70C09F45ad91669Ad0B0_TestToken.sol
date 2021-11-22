// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC20.sol";
import "ERC20Burnable.sol";

contract TestToken is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 initialSupply) ERC20("TestTokenMintable", "MTK") {
        _mint(msg.sender, initialSupply);
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}