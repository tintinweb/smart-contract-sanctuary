// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

contract Guard is PermitERC20UpgradeSafe {
	function __Guard_init(address mine_, address liquidity_) external initializer {
        __Context_init_unchained();
		__ERC20_init_unchained("Helmet.insure on Polygon", "Guard");
		__Guard_init_unchained(mine_, liquidity_);
	}
	
	function __Guard_init_unchained(address mine_, address liquidity_) public initializer {
		_mint(mine_,        4_000_000 * 10 ** uint256(decimals()));
		_mint(liquidity_,   1_000_000 * 10 ** uint256(decimals()));
	}
}