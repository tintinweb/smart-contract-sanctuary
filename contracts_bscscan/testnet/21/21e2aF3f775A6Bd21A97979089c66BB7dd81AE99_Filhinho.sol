// SPDX-License-Identifier: GPL-3.0+
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Filhinho is ERC20 {
    
    constructor (uint256 initialSupply) ERC20 ("Filhinho", "FLH"){
        _mint(msg.sender, initialSupply);
    }
    
    
    
    
    
}