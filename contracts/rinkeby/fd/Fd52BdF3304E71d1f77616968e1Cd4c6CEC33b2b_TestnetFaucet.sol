// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TestnetFaucet {
    address public owner;
    uint public amountAllowed = 0.02 ether;
    mapping(address => uint) public lockTime;

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
    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    // ETH donations open
	function donateTofaucet() public payable {
	}

    // Send tokens from faucet to requestor
    function requestTokens(address payable _requestor) public payable {

        require(block.timestamp > lockTime[msg.sender], "lock time has not expired. Please try again later");
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");

        _requestor.transfer(amountAllowed);        
 
        // 1 day lock time for faucet
        lockTime[msg.sender] = block.timestamp + 1 days;
    }
}