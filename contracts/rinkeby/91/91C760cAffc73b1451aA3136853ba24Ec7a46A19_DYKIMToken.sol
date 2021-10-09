// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import './ERC20.sol'; 

contract DYKIMToken is ERC20{ 
	uint public INITIAL_SUPPLY = 3000000000;
	constructor() ERC20("DYKIM Test token","DYKIM") {
		_mint(msg.sender, INITIAL_SUPPLY * (10 ** 18)); 
	} 
}