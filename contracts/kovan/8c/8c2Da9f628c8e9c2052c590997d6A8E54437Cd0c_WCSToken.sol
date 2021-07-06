// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WCSToken is ERC20{
    
    constructor(uint256 initialSupply) ERC20("EduToken","WCS") {
        _mint(msg.sender, initialSupply);
    }
    
}