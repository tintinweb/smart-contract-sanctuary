pragma solidity ^0.4.23;

contract TestContractSmall {
	function get(uint input) public pure returns (uint) {
    	return input * 30;
	}
	function reverter(uint input) public pure returns (uint) {
        revert();
    	return input * 30;
	}
}

contract TestContract is TestContractSmall {
	uint public data;
	uint public value = 101;

	function set(uint x) public {
    	data = x;
  	}

	function get() public constant returns (uint) {
    	return data;
	}

	function getVal() public view returns (uint) {
		return value;
	}

	function setVal(uint newval) public returns (bool) {
		value = newval;
		return true;
	}
	
	function revertTest() pure public returns (bool) {
        super.reverter(10);
	    return true;
	}
}