pragma solidity ^0.4.23;

contract Token {
	uint8 public decimals;

  	constructor (uint8 _decimals) public {
		decimals = _decimals;
  	}
}