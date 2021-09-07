/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.5.0;

contract Simplestorage {
	uint data;
	
	function updateData(uint _data) external {
	  data = _data;
	}

	function readData() external view returns(uint) {
	return data;
	}
	}