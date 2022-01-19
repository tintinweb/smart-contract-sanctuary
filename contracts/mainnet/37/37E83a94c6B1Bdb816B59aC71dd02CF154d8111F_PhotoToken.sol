// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PhotoToken is ERC20 {
    uint8 private _decimals = 0;
    
    /**
     * @dev Sets the values for {initialMintAddress}, {initialSupply} and {dec}.
     *
     */
    constructor(address initialMintAddress) ERC20("PhotoChromic", "PHCR") {
        _decimals = 18;
        _mint(initialMintAddress, 15000000000*(10**_decimals));
    }
    
    
    /**
    * @dev returns how many decimals. 
    */
    function decimals() public override view returns (uint8){
         return _decimals;
    }
}