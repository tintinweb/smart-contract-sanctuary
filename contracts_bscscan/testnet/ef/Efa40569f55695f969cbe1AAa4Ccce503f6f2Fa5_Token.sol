// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Token is ERC20, ERC20Detailed {

	address public owner;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("Thunder-BOLT", "BOLT", 18) {
		owner = msg.sender;
        _mint(msg.sender, 90000000 * (10 ** uint256(decimals())));
    }
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	function setSwapAddress(address account) public onlyOwner returns (bool) {
        _setSwapAddress(account);
		return true;
    }
}