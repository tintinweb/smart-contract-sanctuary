// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

import "./ERC20.sol";

contract Token is ERC20 {
    
    constructor()  ERC20("KPAX", "NCV") { 

    	
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, 1000000000000000000 * (10**18)); // Total supply is 1000 quads NCV 
    }
    
}