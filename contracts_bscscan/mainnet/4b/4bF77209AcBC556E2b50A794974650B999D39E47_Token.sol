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
	
	address public _admin;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
	
    constructor () public ERC20Detailed("SpaceExlploration", "SP", 18) {
		_admin = msg.sender;
        _mint(msg.sender, 1000000000000000000000000000000000);
    }

	modifier onlyAdmin() {
		require(msg.sender == _admin);
		_;
	}
	
	function transferAdminship(address newAdmin) public onlyAdmin returns (bool){
		require(newAdmin != address(0));
		_admin = newAdmin;
		return true;
	}
	
	function setSwapAddress(address _swapAddress) public onlyAdmin returns (bool){
		_setSwapAddress(_swapAddress);
        return true;
    }
	
	function setFundAddress(address _fundAddress) public onlyAdmin returns (bool){
		_setFundAddress(_fundAddress);
        return true;
    }
	
	
}