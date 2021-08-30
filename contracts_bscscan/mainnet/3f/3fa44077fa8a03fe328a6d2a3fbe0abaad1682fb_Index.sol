/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IBEP20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Index {
	address public owner;
	address public credit;

	mapping (address => bool) public isDev; // 100%
	mapping (address => bool) public isL3; // 75%
	mapping (address => bool) public isL2; // 50%
	mapping (address => bool) public isL1; // 25%
	uint256 public baseRate = 500;

	modifier onlyOwner() {
		require(owner == msg.sender, "Caller is not the owner.");
		_;
	}

	constructor () {
		owner = msg.sender;
		credit = address(0);
		isDev[owner] = true;
	}

	function setOwner(address _owner) external onlyOwner {
		owner = _owner;
	}

	function setCredit(address _credit) external onlyOwner {
		credit = _credit;
	}

	function setIsDev(address account, bool status) external onlyOwner {
		isDev[account] = status;
	}

	function setIsL3(address account, bool status) external onlyOwner {
		isL3[account] = status;
	}

	function setIsL2(address account, bool status) external onlyOwner {
		isL2[account] = status;
	}

	function setIsL1(address account, bool status) external onlyOwner {
		isL1[account] = status;
	}

	function setBaseRate(uint256 rate) external onlyOwner {
		baseRate = rate;
	}

	function getBaseRate(address account) external view returns (uint256) {
		if (isDev[account]) return baseRate - (baseRate * 100 / 100);
		if (isL3[account]) return baseRate - (baseRate * 75 / 100);
		if (isL2[account]) return baseRate - (baseRate * 50 / 100);
		if (isL1[account]) return baseRate - (baseRate * 25 / 100);
		return baseRate;
	}

	function withdrawToken(IBEP20 token) external onlyOwner {
		token.transfer(owner, token.balanceOf(address(this)));
	}
}