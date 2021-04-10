// SPDX-License-Identifier: MIT
/*
	Deployment with zero first farms, for deployment on a testnet.
*/

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeERC20.sol"; // call ERC20 safely
import "./SafeMath.sol";
import "./Address.sol";

import "./FarmBossV1.sol";

contract FarmBossV1_TEST is FarmBossV1 {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using Address for address;

	constructor(address payable _governance, address _daoMultisig, address _treasury, address _underlying) public FarmBossV1(_governance, _daoMultisig, _treasury, _underlying){
	}

	// no first farms, this is just for testing 
	function _initFirstFarms() internal override {
		return;
	}
}