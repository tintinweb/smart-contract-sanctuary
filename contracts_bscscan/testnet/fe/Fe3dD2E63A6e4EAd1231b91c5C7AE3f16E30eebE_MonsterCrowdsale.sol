// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Crowdsale.sol";
import "./AllowanceCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./CappedCrowdsale.sol";
import "./WhitelistCrowdsale.sol";

contract MonsterCrowdsale is AllowanceCrowdsale, TimedCrowdsale, CappedCrowdsale, WhitelistCrowdsale {
	constructor(
		uint256 _rate,
		address payable _wallet,
		ERC20 _token,
		address _tokenWallet,
		uint256 _openingTime,
		uint256 _closingTime,
		uint256 _cap
	)
		Crowdsale(_rate, _wallet, _token)
		AllowanceCrowdsale(_tokenWallet)
		TimedCrowdsale(_openingTime, _closingTime)
		CappedCrowdsale(_cap)
	{}

	/**
	 * @dev Extend parent behavior requiring to be within contributing period.
	 * @param beneficiary Token purchaser
	 * @param weiAmount Amount of wei contributed
	 */
	function _preValidatePurchase(address beneficiary, uint256 weiAmount)
		internal
		view
		override(Crowdsale, TimedCrowdsale, WhitelistCrowdsale, CappedCrowdsale)
		onlyWhileOpen
	{
		super._preValidatePurchase(beneficiary, weiAmount);
	}

	/**
	 * @dev Overrides parent behavior by transferring tokens from wallet.
	 * @param beneficiary Token purchaser
	 * @param tokenAmount Amount of tokens purchased
	 */
	function _deliverTokens(address beneficiary, uint256 tokenAmount)
		internal
		override(Crowdsale, AllowanceCrowdsale)
	{
		super._deliverTokens(beneficiary, tokenAmount);
	}
}