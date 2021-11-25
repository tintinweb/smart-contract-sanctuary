// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Locker is Ownable {

	struct S_Lock {
		uint id;
		address userAddress;
		address tokenAddress;
		uint totalLockedTokens;
		uint claimedTokens;
		uint startDay;
		uint numberDays;
	}

	S_Lock[] private lockRequests;
	uint private nbLockRequests;
	mapping(address => uint[]) private addressesLockRequests;

	address[] private whitelist;
	uint private nbWhitelist;

	event AddToWhitelist(address userAddress);
	event RemoveFromWhitelist(address userAddress);
	event LockRequest(address userAddress, address tokenAddress, uint totalLockedTokens, uint numberDays);
	event ClaimLockedTokens(address userAddress, address tokenAddress, uint claimedTokens);

	modifier onlyWhitelist() {
		require(getWhitelistIndex(_msgSender()) != -1, "Address isn't whitelisted.");
		_;
	}

	function getLockInformation(uint id) public view returns (S_Lock memory) {
		return lockRequests[id];
	}

	function getAddressLockRequests(address userAddress) public view returns (uint[] memory) {
		return addressesLockRequests[userAddress];
	}

	function getNbLockRequests() public view returns (uint) {
		return nbLockRequests;
	}

	function getWhitelist() public view returns (address[] memory) {
		return whitelist;
	}

	function getWhitelistIndex(address userAddress) private view returns (int) {
		for (uint i = 0; i < getNbWhitelist(); i++) {
			if (userAddress == whitelist[i]) {
				return int(i);
			}
		}
		return -1;
	}

	function getNbWhitelist() private view returns (uint) {
		return nbWhitelist;
	}

	function getClaimableTokens(uint id) private view returns (uint) {
		uint elapsedDays = block.timestamp / 86400 - lockRequests[id].startDay;
		if (elapsedDays >= lockRequests[id].numberDays)
			return lockRequests[id].totalLockedTokens - lockRequests[id].claimedTokens;
		else
			return (lockRequests[id].totalLockedTokens / lockRequests[id].numberDays * elapsedDays) - lockRequests[id].claimedTokens;
	}

	function addToWhitelist(address userAddress) external onlyOwner {
		require(getWhitelistIndex(userAddress) == -1, "Address is already whitelisted.");
		whitelist.push(userAddress);
		nbWhitelist++;
		emit AddToWhitelist(userAddress);
	}

	function removeFromWhitelist(address userAddress) external onlyOwner {
		int index = getWhitelistIndex(userAddress);
		require(index != -1, "Address isn't whitelisted.");
		whitelist[uint(index)] = whitelist[getNbWhitelist() - 1];
		whitelist.pop();
		nbWhitelist--;
		emit RemoveFromWhitelist(userAddress);
	}

	function lockTokens(address userAddress, address tokenAddress, uint totalTokens, uint numberDays) external onlyWhitelist {
		require(numberDays > 0, "Unable to vest for less than 1 day.");
		require(totalTokens > 0, "Unable to vest 0 tokens.");
		S_Lock memory lockRequest = S_Lock(getNbLockRequests(), userAddress, tokenAddress, totalTokens, 0, block.timestamp / 86400, numberDays);
		IERC20(tokenAddress).transferFrom(_msgSender(), address(this), totalTokens);
		lockRequests.push(lockRequest);
		nbLockRequests++;
		addressesLockRequests[userAddress].push(getNbLockRequests());
		emit LockRequest(userAddress, tokenAddress, totalTokens, numberDays);
	}

	function claimLockedTokens(uint id) external onlyWhitelist {
		require(id <= getNbLockRequests() && id >= 0, "Invalid ID.");
		require(_msgSender() == lockRequests[id].userAddress, "You can't claim tokens you didn't deposit.");
		require(lockRequests[id].claimedTokens != lockRequests[id].totalLockedTokens, "All tokens have already been claimed.");
		uint claimableTokens = getClaimableTokens(id);
		require(claimableTokens > lockRequests[id].claimedTokens, "You have already claimed all your available tokens yet.");
		IERC20(lockRequests[id].tokenAddress).transfer(_msgSender(), claimableTokens);
		lockRequests[id].claimedTokens += claimableTokens;
		emit ClaimLockedTokens(lockRequests[id].userAddress, lockRequests[id].tokenAddress, claimableTokens);
	}
}