// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./WTF.sol";
import "./StakingRewards.sol";


contract FeeManager {

	WTF private wtf;

	constructor() {
		wtf = WTF(msg.sender);
	}

	function disburse() external {
		wtf.claimRewards();
		uint256 _balance = wtf.balanceOf(address(this));
		if (_balance > 0) {
			uint256 _oneFifth = _balance / 5;
			Treasury(payable(wtf.treasuryAddress())).collect();
			wtf.transfer(wtf.treasuryAddress(), _oneFifth); // 20%
			StakingRewards(wtf.stakingRewardsAddress()).disburse(_oneFifth); // 20%
			StakingRewards(wtf.lpStakingRewardsAddress()).disburse(3 * _oneFifth); // 60%
		}
	}


	function wtfAddress() external view returns (address) {
		return address(wtf);
	}
}


contract TeamReferral {
	receive() external payable {}
	function release() external {
		address _this = address(this);
		require(_this.balance > 0);
		payable(0x6129E7bCb71C0d7D4580141C4E6a995f16293F42).transfer(_this.balance / 10); // 10%
		payable(0xc9AebdD8fD0d52c35A32fD9155467Cf28Ce474c3).transfer(_this.balance / 3); // 30%
		payable(0xdEE79eD62B42e30EA7EbB6f1b7A3f04143D18b7F).transfer(_this.balance / 2); // 30%
		payable(0x575446Aa9E9647C40edB7a467e45C5916add1538).transfer(_this.balance); // 30%
	}
}


contract Treasury {

	address public owner;
	uint256 public lockedUntil;
	WTF private wtf;

	modifier _onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	constructor() {
		owner = 0x65dd4990719bE9B20322e4E8D3Bd77a4401a0357;
		lockedUntil = block.timestamp + 30 days;
		wtf = WTF(msg.sender);
	}

	receive() external payable {}

	function setOwner(address _owner) external _onlyOwner {
		owner = _owner;
	}

	function transferETH(address payable _destination, uint256 _amount) external _onlyOwner {
		require(isUnlocked());
		_destination.transfer(_amount);
	}

	function transferTokens(ERC20 _token, address _destination, uint256 _amount) external _onlyOwner {
		require(isUnlocked());
		_token.transfer(_destination, _amount);
	}

	function collect() external {
		wtf.claimRewards();
	}


	function isUnlocked() public view returns (bool) {
		return block.timestamp > lockedUntil;
	}

	function wtfAddress() external view returns (address) {
		return address(wtf);
	}
}