// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Ownable } from "./lib/Ownable.sol";
import { ReentrancyGuard } from "./lib/ReentrancyGuard.sol";
import { ERC20 } from "./lib/ERC20.sol";
import { Stoppable } from "./lib/Stoppable.sol";
import { SafeERC20 } from "./lib/SafeERC20.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

contract VolatilePool is Ownable, ReentrancyGuard, ERC20, Stoppable {
	using SafeERC20 for address;

	uint256 constant public COEFFICIENT_PRECISION = 1e6;	// Coefficients precision (parts per million, ppm)
	string public constant name = 'VolatilePoolToken';		// Internal token name
    string public constant symbol = 'VPT';					// Internal token symbol
	address public immutable inToken;		// Contract address of the Token contract accepts
	address public immutable reservePool;	// ReservePool contract address where contract will send inTokens
	address public immutable vpStorage;		// VPStorage contract address allowed to burn VPT without approval
	uint256 public coefficient;				// Coefficient in ppm (parts per million)

	/** 
	* @dev Lender constructor
	* @param inToken_ In Token contract address
	* @param coefficient_ Coefficient ratio
	*/
	constructor (
		address owner_,
		uint8 decimals_,
		address inToken_,
		address reservePool_,
		address vpStorage_,
		uint256 coefficient_
	)
		Ownable(owner_)
		ERC20(decimals_)
	{
		inToken = inToken_;
		reservePool = reservePool_;
		vpStorage = vpStorage_;
		_setCoefficient(coefficient_);
	} 

	/***************************************
					PRIVATE
	****************************************/

	/** 
	* @dev Sets Coefficient
	* @param coefficient_ Coefficient
	*/
	function _setCoefficient (
		uint256 coefficient_
	)
		private
	{
		coefficient = coefficient_;
	}

	function _calcEmergencyWithdraw(address address_)
		private
		view
		whenStopped
		returns(uint256 amount_)
	{
		uint256 _totalSupply = totalSupply;
		if(_totalSupply != 0) {
			uint256 _balance = balanceOf[address_];
			uint256 _inTokenBalance = IERC20(inToken).balanceOf(address(this));
			amount_ =  _inTokenBalance * _balance * COEFFICIENT_PRECISION / coefficient / _totalSupply;
		}
	}

	/***************************************
					ADMIN
	****************************************/

	/** 
	* @dev Sets Coefficient
	* @param coefficient_ Coefficient
	*/
	function setCoefficient (
		uint256 coefficient_
	)
		external
		onlyOwner
	{
		_setCoefficient(coefficient_);
	}

	/**
	 * @dev Triggers stopped state, can be called only from ReservePool
	 */
	function stop() external {
		require(msg.sender == reservePool, "forbidden");
		_stop();
	}

	/***************************************
					ACTIONS
	****************************************/

	 /**
	 * Override transferFrom to allow VPT transfers by VPStorage without approval\allowance
	 */
	function transferFrom(address sender_, address recipient_, uint256 amount_) 
		external
		override
		returns (bool) 
	{
		if(msg.sender == vpStorage) {
			_transfer(sender_, recipient_, amount_);
		}else{
			if (allowance[sender_][msg.sender] != type(uint).max) {
            	allowance[sender_][msg.sender] -= amount_;
        	}
			super._transfer(sender_, recipient_, amount_);
		}
		return true;
	}

	/**
	 * @dev Destroys tokens from account
	 * @param amount_ amount of tokens
	 */
	function burn(uint256 amount_)  
		external 
	{
		_burn(msg.sender, amount_);
	}
	
	/**
	 * @dev Transfers In Tokens preapproved by sender to worker contract, 
	 * mints VPT Tokens amount * coefficient to sender
	 * @param inAmount_ of In Tokens
	 */
	function receiveInToken (uint256 inAmount_)
		external
		whenNotStopped
		nonReentrant
	{
		require(inAmount_ != 0, "in amount is 0");
		inToken.safeTransferFrom(msg.sender, reservePool, inAmount_);
		uint256 _outAmount = inAmount_ * coefficient / COEFFICIENT_PRECISION;
		_mint(msg.sender, _outAmount);
	}

	function emergencyWithdraw()
		external
		nonReentrant
	{
		uint256 _amount = _calcEmergencyWithdraw(msg.sender);
		require(_amount != 0, "nothing to withdraw");
		_burn(msg.sender, _amount);
		inToken.safeTransfer(msg.sender, _amount);
	}

	/***************************************
					GETTERS
	****************************************/

	function calcEmergencyWithdraw(address address_)
		external
		view
		returns(uint256)
	{
		return _calcEmergencyWithdraw(address_);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotStopped` and `whenStopped`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Stoppable {
	/**
	 * @dev Emitted when the stop is triggered by `account`.
	 */
	event Stopped(address account);

	bool public stopped;

	/**
	 * @dev Modifier to make a function callable only when the contract is not stopped.
	 *
	 * Requirements:
	 *
	 * - The contract must not be stopped.
	 */
	modifier whenNotStopped() {
		require(!stopped, "Stoppable: stopped");
		_;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is stopped.
	 *
	 * Requirements:
	 *
	 * - The contract must be stopped.
	 */
	modifier whenStopped() {
		require(stopped, "Stoppable: not stopped");
		_;
	}

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be stopped.
	 */
	function _stop() internal whenNotStopped {
		stopped = true;
		emit Stopped(msg.sender);
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address owner_) {
        owner = owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

contract ERC20 {
    // string public virtual constant name = 'Token';
    // string public virtual constant symbol = 'TKN';
    uint8 public immutable decimals;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor (uint8 decimals_) {
        decimals = decimals_;
    }

    function _mint(address to, uint value) internal virtual {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal virtual {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal virtual {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal virtual {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

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