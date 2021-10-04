// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";

contract SHWAToken is ERC20Pausable {
    
    constructor() ERC20("ShibaWallet", "SHWA") {
        uint256 initialSupply = 9000000000000000000000000000; 
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
    
}