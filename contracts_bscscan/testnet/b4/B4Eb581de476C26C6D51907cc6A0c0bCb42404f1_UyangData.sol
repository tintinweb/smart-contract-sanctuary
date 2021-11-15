// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UyangData{

	address owner;
	mapping (address=>uint) public uyangOfAmout;
	uint public totalUyangAmout;
	uint public totalAddress;
    bool public close;

	mapping (address => bool) public approveContracts;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
    }

    modifier onlyOpen() {
		require(!close);
		_;
    }

	constructor() {
		owner = msg.sender;
	}

    function setClose(bool _close) public onlyOwner {
        close = _close;
    }

	function toApproveContract(address platform, bool isApprove) public onlyOwner{
		approveContracts[platform] = isApprove;
	}

	function increaseUyang(address player, uint amout) public onlyOpen {
		require(approveContracts[msg.sender], "the contract do not approve");
		if (uyangOfAmout[player] == 0) {
			totalAddress ++;
		}
		uyangOfAmout[player] += amout;
        totalUyangAmout += amout;
	}

	function decreaseUyang(address player, uint amout) public onlyOpen {
		require(approveContracts[msg.sender], "the contract do not approve");
		uyangOfAmout[player] -= amout;
        totalUyangAmout -= amout;
	}

}

