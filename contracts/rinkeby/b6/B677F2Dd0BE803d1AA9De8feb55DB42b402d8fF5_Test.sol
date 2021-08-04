/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.4.23;
contract Test {
	int x = 5;	
	function getX() public view returns (int) {	
		return x;
	}
	function setX(int _x) public {
		x = _x;
	}
}