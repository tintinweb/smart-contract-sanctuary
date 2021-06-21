pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 12345678;
		name = "LittumpCoinBet";
		decimals = 4;
		symbol = "LCB";
		version = "1.0";
		balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
	}
}