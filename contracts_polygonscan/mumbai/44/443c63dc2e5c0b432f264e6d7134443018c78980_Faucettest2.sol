/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Faucettest2 {
	

    //state variable to keep track of owner and amount of ETHER to dispense
    address public owner;
    uint public amountAllowed = 1000000000000000000;


    //constructor to set the owner
	constructor() payable {
		owner = msg.sender;
	}

    //function modifier
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }


    //function to change the owner.  Only the owner of the contract can call this function
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }


    //function to set the amount allowable to be claimed. Only the owner can call this function
    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }


    //function to donate funds to the faucet contract
	function donateTofaucet() public payable {
	}


    //function to send tokens from faucet to an address
    function requestTokens(address payable _requestor) public payable {

        //perform a few checks to make sure function can execute
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");

        //if the balance of this contract is greater then the requested amount send funds
        _requestor.transfer(amountAllowed);        
 
    }
}