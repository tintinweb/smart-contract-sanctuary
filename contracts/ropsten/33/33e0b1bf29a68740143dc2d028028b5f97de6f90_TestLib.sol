pragma solidity ^0.4.23;

library TestLib {
	function get(uint input) public pure returns (uint) {
    	return input * 30;
	}
}