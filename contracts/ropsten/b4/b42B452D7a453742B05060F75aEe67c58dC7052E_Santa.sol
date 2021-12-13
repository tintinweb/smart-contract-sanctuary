/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

pragma solidity 0.4.22;

contract Santa {
	uint24 a;
	bytes32 b = 0x0619c10213c814eba28106f6c2472c5853b55a7c25855da514b806efc1128e55;
	bool public isComplete;
	bool c;
	uint256 d;

	constructor() public payable {
		require(msg.value == 0.0000000000000001 ether);
		d = msg.value;
	}

	function e() public {
		if (keccak256(a) == b){
			isComplete = true;
		}
	}
	function f(int24 g) public{
		require(c);
		a = uint24((0xdeadbeef) <<- (-31337) % 1337 >> (188495400 / 314159)) + uint24(g);
	}

	function h() public {
		uint256 i = d - address(this).balance;
		require(i > 0);
		c = true;
	}
}