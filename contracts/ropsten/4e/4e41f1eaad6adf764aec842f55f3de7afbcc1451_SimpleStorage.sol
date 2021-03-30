/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.8.0;

contract SimpleStorage {
	uint storeData;
	function set(uint x) public {
	    
		storeData = x;
		
	}
	
	function setData(uint _data) external {
	    storeData = _data;
	}
	
	
	function get() public view returns (uint) {
	    
		return storeData;
		
	}
}