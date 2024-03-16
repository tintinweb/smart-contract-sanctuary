// UpStableToken.sol
// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./UstxRoles.sol";


/// @title Up Stable Token eXperiment EVM compatible token
/// @author USTX Team
/// @dev This contract implements the functionality of the USTX token on EVM compatible chains.
contract UpStableToken is UstxRoles,ERC20,ERC20Detailed {
	/**
	* @dev Constructor for UpStableToken, USTX, 6 decimals, 2 administrators
	*
	*
	*/
	constructor()
		public
	    ERC20Detailed("UpStableToken", "USTX", 6)
	    UstxRoles(2)        //at least two administrators always in charge
		{ }


	/**
	* @dev Public function to mint new tokens (only Crosschain bridge)
	* @param account destination account address
	* @param amount new tokens to mint
	* @return true
	*/
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

	/**
	* @dev Public function to burn tokens (from caller's account)
	* @param amount number of tokens to burn
	*
	*/
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

	/**
	* @dev Public function to burn tokens (from third party's account with approval)
	* @param account target account
	* @param amount number of tokens to burn
	*/
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}