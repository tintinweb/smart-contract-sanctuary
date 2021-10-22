/**
 *Submitted for verification at arbiscan.io on 2021-10-21
*/

/**
 *Submitted for verification at arbiscan.io on 2021-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Token {
	function mint(address) external payable;

	function safeTransferFrom(
		address,
		address,
		uint256
	) external;

	function getOwnerNFTs(address) external view returns (uint256[] memory);
}

contract Proxy {
	address private owner;
	Token public token;

	mapping(address => uint256) public referrerMap;
	address[] public referrers;

	constructor(address _token) {
		token = Token(_token);
		owner = msg.sender;
	}

	function mint(address ref) external payable {
		if (ref != msg.sender) {
			if (referrerMap[ref] == 0) {
				referrerMap[ref] = msg.value;
				referrers.push(ref);
			} else {
				referrerMap[ref] += msg.value;
			}
		}

		token.mint{value: msg.value}(address(0));
		uint256[] memory ids = token.getOwnerNFTs(address(this));

		for (uint256 i = 0; i < ids.length; i++) {
			token.safeTransferFrom(address(this), msg.sender, ids[i]);
		}
	}

	function pay(uint256 shareBasis) external {
		for (uint256 i = 0; i < referrers.length; i++) {
			bool shouldContinue = _payOne(shareBasis, i);

			if (!shouldContinue) return;
		}
	}

	function _payOne(uint256 shareBasis, uint256 index)
		internal
		returns (bool)
	{
		address referrer = referrers[index];
		uint256 amount = referrerMap[referrer];

		if (amount == 0) {
			return true;
		}

		uint256 toPay = (amount * shareBasis) / 10000;

		if (address(this).balance < toPay) {
			return false;
		} else {
			referrerMap[referrer] = 0;

			payable(referrer).transfer(toPay);

			return true;
		}
	}

	function withdraw() external {
		require(msg.sender == owner);
		payable(msg.sender).transfer(address(this).balance);
	}

	function totalReferredValue() external view returns (uint256 total) {
		for (uint256 i = 0; i < referrers.length; i++) {
			total += referrerMap[referrers[i]];
		}
	}

	receive() external payable {}
}