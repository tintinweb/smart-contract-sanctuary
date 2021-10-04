// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SHWAToken is ERC20 {
    
    constructor() ERC20("ShibaWallet", "SHWA") {
        uint256 initialSupply = 3000000000000000000000000000; // 3Billions 
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 addedSupply) public onlyOwner {
        _mint(msg.sender, addedSupply);
    }

    function burn(address account, uint256 deductedSupply) public {
        _burn(account, deductedSupply);
    }
    
}