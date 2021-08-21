/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.7.0;

contract devAddresses {
	address public owner = 0x3f119Cef08480751c47a6f59Af1AD2f90b319d44;
	mapping (address => bool) _isDev;
	event DevStatusChanged(address indexed dev, bool indexed status);
	
	function addDev(address guy) public {
		require(msg.sender == owner);
		_isDev[guy] = true;
		emit DevStatusChanged(guy, true);
	}
	
	function removeDev(address guy) public {
		require(msg.sender == owner);
		_isDev[guy] = false;
		emit DevStatusChanged(guy, true);
	}
	
	function isDev(address guy) public view returns (bool) {
		return (_isDev[guy] || (guy == owner));
	}
}