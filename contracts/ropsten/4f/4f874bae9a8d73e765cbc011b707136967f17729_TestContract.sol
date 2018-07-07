pragma solidity ^0.4.23;

library TestLib {
	function get(uint input) public pure returns (uint) {
    	return input * 30;
	}
	function reverter(uint input) public pure returns (uint) {
        revert();
    	return input * 30;
	}
	function nothing() public pure returns (uint) {
    	return 100;
	}
    
}

library TestLib2 {
	function get(uint input) public pure returns (uint) {
    	return input * 40;
	}
	function reverter(uint input) public pure returns (uint) {
        revert();
    	return input * 40;
	}
	function nothing() public pure returns (uint) {
    	return 200;
	}
    
}

contract TestContract {
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

	function callLib(uint passInt) pure public returns (uint) {
		return TestLib.get(passInt);
	}

	function callLibSet(uint passInt) public returns (bool) {
		data = TestLib.get(passInt);
		return true;
	}
	
	function checkRevert(uint passInt) public returns (bool) {
	    data = TestLib.reverter(passInt);
	    return true;
	}
	
	function nothingLib() pure public returns (uint) {
	    uint nothing = TestLib.nothing();
	    return nothing;
	}
    
	function callLib2(uint passInt) pure public returns (uint) {
		return TestLib2.get(passInt);
	}

	function callLibSet2(uint passInt) public returns (bool) {
		data = TestLib2.get(passInt);
		return true;
	}
	
	function checkRevert2(uint passInt) public returns (bool) {
	    data = TestLib2.reverter(passInt);
	    return true;
	}
	
	function nothingLib2() pure public returns (uint) {
	    uint nothing = TestLib2.nothing();
	    return nothing;
	}
}