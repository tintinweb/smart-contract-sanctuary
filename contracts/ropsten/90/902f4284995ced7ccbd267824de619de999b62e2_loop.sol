pragma solidity ^0.4.24;

contract loop {
	uint i = 0;
	event Yes(uint indexed _i);
	function myLoop() public {
		while(true) {
			i++;
			if(i == 100000000000) {
				emit Yes(i);
				break;
			}
		}
	}
}