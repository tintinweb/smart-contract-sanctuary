pragma solidity ^0.4.24;

contract GasTest {
	mapping (uint256 => uint256) b_int;
	mapping (address => uint256) b_addr;
	
	
	constructor() public {
		
	}

	
	
	
	
	// Set one balance
	function setIBalance(uint256 to, uint256 val) public returns (bool) {
		b_int[to] = val;
	}
	
	// Set multiple balances
	function setIBalances(uint256[] tos, uint256[] vals) public returns (bool) {
		uint len = tos.length;
		require(len == vals.length);
		for (uint i = 0; i < len; i++) {
			b_int[tos[i]] = vals[i];
		}
	}
	
	// Set multiple balances (and fuck around with local vars)
	function setIBalances2(uint256[] tos, uint256[] vals) public returns (bool) {
		uint256 i1;
		uint256 i2;
		uint len = tos.length;
		require(len == vals.length);
		for (uint i = 0; i < len; i++) {
			i1 = tos[i];
			i2 = vals[i];
			b_int[i1] = i2;
		}
	}
	
	// Set a balance multiple times
	function setIBalance3(uint256 to, uint256 val, uint mul) public returns (bool) {
		for (uint i = 0; i < mul; i++) {
			b_int[to] += val;
		}
	}
	
	// Set a balance multiple times (using local var)
	function setIBalance4(uint256 to, uint256 val, uint mul) public returns (bool) {
		uint256 tot = 0;
		for (uint i = 0; i < mul; i++) {
			tot += val;
		}
		b_int[to] = tot;
	}
	
	// Set a balance multiple times (using multiplication)
	function setIBalance5(uint256 to, uint256 val, uint mul) public returns (bool) {
		b_int[to] = val * mul;
	}
	
	
	
	
	
	
	
	
	// Set one balance
	function setABalance(address to, uint256 val) public returns (bool) {
		b_addr[to] = val;
	}
	
	// Set multiple balances
	function setABalances(address[] tos, uint256[] vals) public returns (bool) {
		uint len = tos.length;
		require(len == vals.length);
		for (uint i = 0; i < len; i++) {
			b_addr[tos[i]] = vals[i];
		}
	}
}