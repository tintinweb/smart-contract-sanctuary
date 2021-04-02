// SPDX-License-Identifier: MIT
/*
	Inherits FarmTreasuryV1, but allows for direct ETH deposits & withdraws
*/

pragma solidity ^0.6.11;

import "./IERC20.sol";
import "./SafeERC20.sol"; // call ERC20 safely
import "./SafeMath.sol";
import "./Address.sol";

import "./ReentrancyGuard.sol";

import "./FarmTreasuryV1.sol";
import "./IWETH.sol";

contract FarmTreasuryV1_ETH is ReentrancyGuard, FarmTreasuryV1 {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using Address for address;

	constructor(string memory _nameUnderlying, uint8 _decimalsUnderlying, address _underlying) public FarmTreasuryV1(_nameUnderlying, _decimalsUnderlying, _underlying){
	}

	receive() payable external {
		// ie: not getting sent back WETH from an unwrapping
		if(msg.sender != underlyingContract){
			depositETH(address(0));
		}
	}

	function depositETH(address _referral) public payable nonReentrant {
		require(msg.value > 0, "FARMTREASURYV1: msg.value == 0");
		require(!paused && !pausedDeposits, "FARMTREASURYV1: paused");

		_deposit(msg.value, _referral);

		IWETH(underlyingContract).deposit{value: msg.value}();
	}

	function withdrawETH(uint256 _amountUnderlying) external nonReentrant {
		require(_amountUnderlying > 0, "FARMTREASURYV1: amount == 0");
		require(!paused, "FARMTREASURYV1: paused");

		_withdraw(_amountUnderlying);

		IWETH(underlyingContract).withdraw(_amountUnderlying);
		msg.sender.transfer(_amountUnderlying);
	}
}