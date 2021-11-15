// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UyangData{

	address owner;
	mapping (address=>uint) public uyangOfAmout;
	uint public totalUyangAmout;
	uint public totalAddress;

	mapping (address => bool) public approveContracts;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
    }

	constructor() {
		owner = msg.sender;
	}

	function toApproveContract(address platform, bool isApprove) public onlyOwner{
		approveContracts[platform] = isApprove;
	}

	function increaseUyang(address player, uint amout) public {
		require(approveContracts[msg.sender], "the contract do not approve");
		if (uyangOfAmout[player] == 0) {
			totalAddress ++;
		}
		uyangOfAmout[player] += amout;
	}

	function decreaseUyang(address player, uint amout) public {
		require(approveContracts[msg.sender], "the contract do not approve");
		uyangOfAmout[player] -= amout;
	}

}

