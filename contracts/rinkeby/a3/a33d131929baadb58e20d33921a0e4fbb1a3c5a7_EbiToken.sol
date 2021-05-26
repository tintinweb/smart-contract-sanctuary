/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract EbiToken {

	string public name = 'EbiToken';
	string public symbol = 'EBI';
    string public standard = 'EbiToken V1.0';
    
    address public owner; 
    uint256 public totalSupply = 1e16;

	event Transfer (address indexed _from, address indexed _to,	uint256 _value);
	mapping(address => uint256) public balanceOf;

	constructor() {
		owner = msg.sender;
	}
	
	 // Creates an amount of new tokens and sends them to an address.
    function mint(address receiver, uint256 amount) public{
    //     // Only the contract owner can call this function
       require(msg.sender == owner, "You are not the owner.");

    //     // Ensures a maximum amount of tokens
        require(amount < totalSupply, "Maximum issuance succeeded");

        // Increases the balance of `receiver` by `amount`
        balanceOf[receiver] += amount;
    }
    
	
	 // Sends an amount of existing tokens from any caller to an address.
    function transfer(address receiver, uint256 amount) public {
        // The sender must have enough tokens to send
       require(amount <= balanceOf[msg.sender], "Insufficient balance.");

        // Adjusts token balances of the two addresses
        balanceOf[msg.sender] -= amount;
        balanceOf[receiver] += amount;

        // Emits the event defined earlier
        emit Transfer(msg.sender, receiver, amount);
    }

}