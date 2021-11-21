// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AffToken is ERC20 {
    
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        _mint(owner_, totalSupply_);
    }
}