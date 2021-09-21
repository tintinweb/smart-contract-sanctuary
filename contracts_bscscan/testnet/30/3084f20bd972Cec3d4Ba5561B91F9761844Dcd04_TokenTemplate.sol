pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TokenTemplate is ERC20Burnable, ERC20Detailed, Ownable {

    /**
     * @dev Constructor that gives the specified address all of existing tokens.
     */
    constructor(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        address beneficiary, 
        uint256 supply) 
        ERC20Detailed(name, symbol, decimals) {
        _mint(beneficiary, supply);
        
    }
    
    fallback() external {
        revert();
    }

    function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }

}