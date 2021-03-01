/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract ConfigNames {
	//GOVERNANCE
	bytes32 public constant STAKE_LOCK_TIME = bytes32("STAKE_LOCK_TIME");
	bytes32 public constant CHANGE_PRICE_DURATION = bytes32("CHANGE_PRICE_DURATION");
	bytes32 public constant CHANGE_PRICE_PERCENT = bytes32("CHANGE_PRICE_PERCENT"); // POOL
	bytes32 public constant POOL_BASE_INTERESTS = bytes32("POOL_BASE_INTERESTS");
	bytes32 public constant POOL_MARKET_FRENZY = bytes32("POOL_MARKET_FRENZY");
	bytes32 public constant POOL_PLEDGE_RATE = bytes32("POOL_PLEDGE_RATE");
	bytes32 public constant POOL_LIQUIDATION_RATE = bytes32("POOL_LIQUIDATION_RATE");
	bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32("POOL_MINT_BORROW_PERCENT");
	bytes32 public constant POOL_MINT_POWER = bytes32("POOL_MINT_POWER");
	bytes32 public constant POOL_REWARD_RATE = bytes32("POOL_REWARD_RATE");
	bytes32 public constant POOL_ARBITRARY_RATE = bytes32("POOL_ARBITRARY_RATE");

	//NOT GOVERNANCE
	bytes32 public constant DEPOSIT_ENABLE = bytes32("DEPOSIT_ENABLE");
	bytes32 public constant WITHDRAW_ENABLE = bytes32("WITHDRAW_ENABLE");
	bytes32 public constant BORROW_ENABLE = bytes32("BORROW_ENABLE");
	bytes32 public constant REPAY_ENABLE = bytes32("REPAY_ENABLE");
	bytes32 public constant LIQUIDATION_ENABLE = bytes32("LIQUIDATION_ENABLE");
	bytes32 public constant REINVEST_ENABLE = bytes32("REINVEST_ENABLE");
	bytes32 public constant POOL_PRICE = bytes32("POOL_PRICE"); //wallet
}