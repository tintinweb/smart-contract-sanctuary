pragma solidity ^0.4.0;
contract BCMtest{
	/*public variables of the token*/
	string public standard="Token 0.1";
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public initialSupply;
	uint256 public totalSupply;
	
	/*This creates an array with all balances*/
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;
	
	/*Initializes contract with initial supply tokens to the creator of the contract*/
	
	function BCMtest(){
	
		initialSupply=1000000;
		name= "bcmtest";
		decimals=0;
		symbol="B";
		
		balanceOf[msg.sender] = initialSupply;
		totalSupply = initialSupply;
		
		
	}
	/*Send Coins*/
	
	function transfer(address _to, uint256 _value){
		if(balanceOf[msg.sender]<_value) throw;
		if(balanceOf[_to]+_value<balanceOf[_to]) throw; 
		balanceOf[msg.sender]-=_value;
		balanceOf[_to]+=_value;
		
	}
	
	/*This unnamed function is called whenever someone tries to send ether to it*/
	function(){
		throw; //Prevent accidental sending of ether
		
	}
}