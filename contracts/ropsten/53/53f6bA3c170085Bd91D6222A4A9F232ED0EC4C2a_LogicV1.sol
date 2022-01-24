pragma solidity ^0.8.0;

contract LogicV1 {
	bool initialized;
	address public owner;
  address private tokenAddress;
  uint private crossFee = 1; // in gwei

	modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

	function crossSend(
    address recipient,
    uint tokenAmount,
    uint nonce) external payable {
    // check fee
    require(msg.value >= crossFee, "Insufficient fee.");
		crossFee = 2;
	}

	function crossRecv(
    address sender,
    address recipient, 
    uint tokenAmount,
    uint nonce) external onlyOwner {
		crossFee = 3;
	}

	function setOwner(address owner_) external onlyOwner {
    require(owner_ != address(0), "Owner can not be null.");
    owner = owner_;
  }
}