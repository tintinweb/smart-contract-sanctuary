// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// using openzeppelin contracts to stay SAFU
import "./ERC20.sol";


/**
 *  
 */

contract IsmaToken is ERC20 {
    
    // MULTI is a token with a capped supply of 31.000.000 (31M), no more tokens will be minted after deployment.
    uint256 private _maxSupply = 31000000 * 10 ** decimals();
    
    // Create the ERC20 Token with MULTI as symbol as name (both will be retriveable from IERC20Metadata functions)
    constructor(uint256 initialSuply) ERC20("IsmaToken", "IsmaToken") {
        _mint(msg.sender, initialSuply); // Mint 31M of tokens and send it to the deployer of the contract.
    }
    
    
     /**
     * @dev Returns the cap on the token's total supply.
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }
    
    // Require that the 
    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= getMaxSupply(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
    
}