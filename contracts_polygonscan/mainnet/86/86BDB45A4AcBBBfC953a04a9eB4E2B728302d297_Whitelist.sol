// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";

import "./IWhitelist.sol";

contract Whitelist is IWhitelist, Ownable {
	uint8 public whitelistAllocation = 5;

	mapping(address => uint256) public whitelist;
	mapping(address => uint256) public freeFarmers;

	constructor() {}

	/**
	 * Whitelist
	 */
	function addToWhitelist(address _address) external onlyOwner {
		whitelist[_address] = whitelistAllocation;
	}

	function addToWhitelistBatch(address[] memory _addresses)
		external
		onlyOwner
	{
		for (uint256 i = 0; i < _addresses.length; i++) {
			whitelist[_addresses[i]] = whitelistAllocation;
		}
	}

	function removeFromWhitelist(address _address) external onlyOwner {
		whitelist[_address] = 0;
	}

	function removeFromWhitelistBatch(address[] memory _addresses)
		external
		onlyOwner
	{
		for (uint256 i = 0; i < _addresses.length; i++) {
			whitelist[_addresses[i]] = 0;
		}
	}

	function getAllocation(address _address) external view returns (uint256) {
		return whitelist[_address];
	}

	function decreaseAllocation(address _address, uint256 amount)
		external
		onlyOwner
	{
		whitelist[_address] -= amount;
	}

	/**
	 * Free farmers
	 */
	function addFreeFarmerAllocation(address _address, uint256 amount)
		external
		onlyOwner
	{
		freeFarmers[_address] = amount;
	}

	function addFreeFarmerAllocationBatch(
		address[] memory _addresses,
		uint256[] memory amounts
	) external onlyOwner {
		for (uint256 i = 0; i < _addresses.length; i++) {
			freeFarmers[_addresses[i]] = amounts[i];
		}
	}

	function removeFreeFarmerAllocation(address _address) external onlyOwner {
		freeFarmers[_address] = 0;
	}

	function removeFreeFarmerAllocationBatch(address[] memory _addresses)
		external
		onlyOwner
	{
		for (uint256 i = 0; i < _addresses.length; i++) {
			freeFarmers[_addresses[i]] = 0;
		}
	}

	function getFreeFarmerAllocation(address _address)
		external
		view
		returns (uint256)
	{
		return freeFarmers[_address];
	}
}