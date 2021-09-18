/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity ^0.4.24;
contract BasicToken {
	mapping(address => uint256) public balanceOf;

	constructor(uint initialSupply) public {
	balanceOf[msg.sender] = initialSupply;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);
		require(balanceOf[_to] + _value >= balanceOf[_to]);
		balanceOf[msg.sender] -=_value;
		balanceOf[_to] +=_value;
		return true;
	}
	


}