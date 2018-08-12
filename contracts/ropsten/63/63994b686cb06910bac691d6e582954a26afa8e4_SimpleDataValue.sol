pragma solidity ^0.4.19;

contract SimpleDataValue
{
	int value;
	
	function setValue(int newValue) private
	{
		value = newValue;
	}
	
	function getValue() public view returns (int)
	{
		return value;
	}
}