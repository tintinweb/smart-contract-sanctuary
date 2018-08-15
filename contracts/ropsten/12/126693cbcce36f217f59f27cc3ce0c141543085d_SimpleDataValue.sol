pragma solidity ^0.4.19;

contract SimpleDataValue
{
	int value;
	
	function getValue() public view returns (int)
	{
		return value;
	}
	
	function setValue(int newValue) private
	{
		value = newValue;
	}
}