// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ReentrancyGuard } from "./lib/ReentrancyGuard.sol";
import { SafeERC20 } from "./lib/SafeERC20.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IToken } from  "./interfaces/IToken.sol";
import { IStoppable } from  "./interfaces/IStoppable.sol";

contract ReservePool is ReentrancyGuard {
	using SafeERC20 for address;

	// Contract address of the Token contract sends out for In Token transfers
	address public immutable outToken;
	// Contract address of the Token contract accepts
	address public immutable inToken;
	// VolatilePool address
	address public immutable volatilePool;

	event Exchanged(address indexed user, uint256 amount);

	/** 
	* @dev Exchange constructor
	* @param outToken_ Out Token contract address
	* @param inToken_ In Token contract address
	*/
	constructor (
		address outToken_,
		address inToken_,
		address volatilePool_
	)
	{
		outToken = outToken_;
		inToken = inToken_;
		volatilePool = volatilePool_;
	} 

	/***************************************
					ACTIONS
	****************************************/

	/**
	 * @dev Can be caled only by ElasticPool, stops VolatilePool and transfers 
	 * whole outToken balance to VolatilePool 
	 */
	function stop()
		external
	{
		require(msg.sender == inToken, "forbidden");
		IStoppable(volatilePool).stop();
		uint256 _balance = IERC20(outToken).balanceOf(address(this));
		if(_balance != 0)
			outToken.safeTransfer(volatilePool, _balance);
	}

	/***************************************
					ACTIONS
	****************************************/
	
	/**
	 * @dev Transfers In Tokens preapproved by sender to contract and burns them, 
	 * transfers Out Tokens 1 to 1 to sender if there is balance of Out Tokens available
	 * @param amount_ of In Tokens
	 */
	function receiveInToken (uint256 amount_)
		external
		nonReentrant
	{
		require(amount_ != 0, "amount is 0");
		require(IERC20(outToken).balanceOf(address(this)) >= amount_, "not enough Out Tokens available");
		IToken(inToken).burnFrom(msg.sender, amount_);
		outToken.safeTransfer(msg.sender, amount_);
		emit Exchanged(msg.sender, amount_);
	}

	/***************************************
					GETTERS
	****************************************/

	/**
	* @dev Returns Out Tokens balance
	*/
	function getOutTokenBalance()
		external
		view
		returns(uint256) 
	{
		return IERC20(outToken).balanceOf(address(this));
	}
		
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeERC20 {
    
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes('approve(address,uint256)')));

    function safeTransfer(address token, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FROM_FAILED');
    }

    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: APPROVE_FAILED');
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "./IERC20.sol";

/**
 * @dev Interface of the IToken Extends IERC20.
 */
interface IToken is IERC20 {

    /**
     * @dev Destroys tokens from msg.sender account
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys tokens from account, allowance checked
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

/**
 * @dev Interface of the Stopable
 */
interface IStoppable {
	function stop() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Minimal Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}