/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.5.12;
contract SimpleStorage {
	uint storedData;

	function  set(uint x) public {
		storedData = x;
	}

	function get() public view returns (uint) {
		return storedData;
	}
}