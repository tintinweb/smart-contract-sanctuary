pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract HashToken is ERC20Burnable, Ownable {
	uint256 public constant INITIAL_SUPPLY = 1000000000000000000000000000;

	/**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public ERC20("HASH", "HASH") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
	
	function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }
	
	function issueTokens(uint256 amount) public onlyOwner {
		_mint(owner(), amount);
	}
}