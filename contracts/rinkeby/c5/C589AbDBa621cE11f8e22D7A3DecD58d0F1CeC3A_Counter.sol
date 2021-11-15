pragma solidity ^0.8.6;

// No SafeMath needed for Solidity 0.8+

contract Counter { 
   
    uint256 private _count;
	
	function current() public returns (uint256) {
		return _count;
	}

	function increment() public {
		_count += 1;
	}

	function decrement() public {
		_count -= 1;
	}
}

