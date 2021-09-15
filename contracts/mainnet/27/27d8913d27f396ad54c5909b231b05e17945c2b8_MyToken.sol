// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20.sol"; 

contract MyToken is ERC20{ 
    uint public INITIAL_SUPPLY = 1000000000000000000000000000; 
    
    constructor() public ERC20("Baop_nft","BAOPNFT"){
        _mint(msg.sender, INITIAL_SUPPLY); } 
    
}