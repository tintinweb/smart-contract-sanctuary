// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SHWAToken is ERC20 {
    
    constructor() ERC20("ShibaWallet", "SHWA") {
        uint256 initialSupply = 5000000000000000000000000000; // 5Billions 
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
    
}