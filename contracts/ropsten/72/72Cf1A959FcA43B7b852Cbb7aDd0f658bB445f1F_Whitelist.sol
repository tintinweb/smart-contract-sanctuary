// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./Ownable.sol";

contract Whitelist is Ownable { //0x72Cf1A959FcA43B7b852Cbb7aDd0f658bB445f1F
	mapping(address => bool) whitelist;
	uint256 public totalTokens;

	uint256 public whitelistPrice = 0.017 ether;
	event AddedToWhitelist(address indexed account);
	event RemovedFromWhitelist(address indexed account);
	event WithDraw(address indexed account);

	modifier onlyWhitelisted() {
		require(isWhitelisted(msg.sender));
		_;
	}

	function add(address _address) public payable {
		require(whitelistPrice == msg.value, "Invalid payment amount");
		whitelist[_address] = true;
		emit AddedToWhitelist(_address);
	}

	function _add(address _address) public onlyOwner {
		whitelist[_address] = true;
		emit AddedToWhitelist(_address);
	}

	function remove(address _address) public onlyOwner {
		whitelist[_address] = false;
		emit RemovedFromWhitelist(_address);
	}

	function isWhitelisted(address _address) public view returns(bool) {
		return whitelist[_address];
	}

	function withdraw() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
	// Function to receive Ether. msg.data must be empty
	receive() external payable {}

	// Fallback function is called when msg.data is not empty
	fallback() external payable {}
}