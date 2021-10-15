// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";

contract Grow is ERC20, Ownable, ERC20Burnable, ERC20Pausable
{
	/**
	 * Send Name, Symbol, Decimals to the ERC20 constructor
	 */
	constructor() ERC20("Grow House", "GROW", 0)
	{
        _mint(msg.sender, 100000000);
    }

    /**
      * @dev Creates `amount` new tokens for `to`.
      * See {ERC20-_mint}.
      *
      * Modifier "onlyOwner" accepts this only for the contract owner
      */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Modifier "onlyOwner" accepts this only for the contract owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Modifier "onlyOwner" accepts this only for the contract owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}