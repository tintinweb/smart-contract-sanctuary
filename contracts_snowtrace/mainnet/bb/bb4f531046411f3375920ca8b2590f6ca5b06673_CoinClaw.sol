// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "Pausable.sol";


contract CoinClaw is ERC20, Pausable, Ownable{
	constructor() ERC20("CoinClaw", "CLAW") {
		_mint(msg.sender, 1000000000 * 10 ** decimals());
	}

	/**
	 * @dev Destroys `amount` tokens from the caller.
	 *
	 * See {ERC20-_burn}.
	 */
	function burn(uint256 amount) public virtual{
		_burn(_msgSender(), amount);
	}
	/**
	 * @dev Destroys `amount` tokens from `account`, deducting from the caller's
	 * allowance.
	 *
	 * See {ERC20-_burn} and {ERC20-allowance}.
	 *
	 * Requirements:
	 *
	 * - the caller must have allowance for ``accounts``'s tokens of at least
	 * `amount`.
	 */
	function burnFrom(address account, uint256 amount) public virtual{
		uint256 currentAllowance = allowance(account, _msgSender());
		require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
		unchecked {
			_approve(account, _msgSender(), currentAllowance - amount);
		}
		_burn(account, amount);
	}

	/**
	 * @dev See {ERC20-_beforeTokenTransfer}.
	 *
	 * Requirements:
	 *
	 * - the contract must not be paused.
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		super._beforeTokenTransfer(from, to, amount);
		require(!paused(), "ERC20Pausable: token transfer while paused");
	}

	/**
	 * Terminates token contract wiping any ethers stored in it.
	 */
	function shutdown() external onlyOwner{
		selfdestruct(payable(0));
	}
}