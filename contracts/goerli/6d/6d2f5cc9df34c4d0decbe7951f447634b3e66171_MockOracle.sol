/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.5.8;

contract MockOracle
{
	function getBool(bytes32 _oracleId)
	public view returns(bool)
	{
	    return true;
	}
	
	
	function getInt(bytes32 _oracleId)
	public view returns(uint256)
	{
	    return 1234567890;
	}
		
	function getString(bytes32 _oracleId)
	public view returns(string memory)
	{
	    return 'string';
	}
	
	function getRaw(bytes32 _oracleId)
	public view returns(bytes memory)
	{
	    return bytes('bytes');
	}
	
}