pragma solidity ^0.4.21;

contract TokenERC20
{
	function transfer(address _to, uint256 _value) public returns (bool success);
	function balanceOf(address _owner) public view returns (uint256 balance);
	function setMsg(string _msg) public;
}

contract Exchange 
{

	function deposite(address contractAddr, uint count) public
	{
		TokenERC20 tkn = TokenERC20(contractAddr);
		tkn.transfer(address(this), count);
	}
	
	function getBalance(address contractAddr, address who) view public returns(uint)
	{
		TokenERC20 tkn = TokenERC20(contractAddr);
		return tkn.balanceOf(who);
	}
		

	function setString(address contractAddr, string _msg) public
	{
		TokenERC20 tkn = TokenERC20(contractAddr);
		tkn.setMsg(_msg);
	}
		
}