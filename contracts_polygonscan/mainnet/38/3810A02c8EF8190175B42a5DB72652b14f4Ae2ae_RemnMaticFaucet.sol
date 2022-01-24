// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RemnMaticFaucet {
    address public owner;
    uint public faucetAmount = 0.05 ether;

	constructor() payable {
		owner = msg.sender;
	}

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }

    // Change owner
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    // Change faucet (airdrop) amount
    function setFaucetAmount(uint newAmountAllowed) public onlyOwner {
        faucetAmount = newAmountAllowed;
    }

    // ETH donations open
	function donateTofaucet() public payable {
	}

    // Send ETH to any address
    function sendTokens(address payable _requestor) public payable onlyOwner {
        require(address(this).balance > faucetAmount, "Not enough funds in the faucet. Please donate");
        _requestor.transfer(faucetAmount);        
    }
}