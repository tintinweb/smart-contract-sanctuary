/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test { // changer nom contrat

	mapping(address => bool) private _whitelistStatus;

	function setWhitelistStatus(address userAddress, bool status) public { // external ?
		_whitelistStatus[userAddress] = status;
	}

	function getWhitelistStatus(address userAddress) public view returns (bool) {
		return _whitelistStatus[userAddress];
	}

	function depositFunds() payable public {
		require(getWhitelistStatus(msg.sender) == true, "Address isn't whitelisted");
		require(msg.value > 0, "Unable to send 0");
	}

	function withdrawFunds(uint256 amount) public {
		require(getWhitelistStatus(msg.sender) == true, "Address isn't whitelisted");
		require(getContractBalance() >= amount, "Contract balance too low");
		payable(msg.sender).transfer(amount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
}