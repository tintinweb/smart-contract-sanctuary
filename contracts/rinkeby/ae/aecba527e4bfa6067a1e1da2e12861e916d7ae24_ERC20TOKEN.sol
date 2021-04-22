pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

contract ERC20TOKEN is ERC20 {
	
	uint256 public constant INITIAL_SUPPLY = 10 ** 21;
	
	constructor() public ERC20("Test token", "TST") {
		
        _mint(msg.sender, INITIAL_SUPPLY);
		
	}
	
}