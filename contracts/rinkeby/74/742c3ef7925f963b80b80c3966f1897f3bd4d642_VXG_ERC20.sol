/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.10;

struct option {
	uint value;
	uint fee;
}

struct forcedWithdrawal {
	uint40 timestamp;
	uint216 amount;
}

struct balanceChange {
	uint40 id;
	int216 balanceChange;
}

struct withdrawal {
	uint40 id;
	uint216 withdrawingBalance;
}




/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/
            
//    WORK IN PROGRESS

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.10;

////import "./Structs.sol";
////import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
////import "../node_modules/@openzeppelin/contracts/proxy/Proxy.sol";

interface IOwnable {
	function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IVXG_ERC20 is IERC20 {
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function increaseAllowance(address _spender, uint _value) external returns (uint finalAllowance);
	function decreaseAllowance(address _spender, uint _value) external returns (uint finalAllowance);
	function minters(address minter) external returns (bool isMinter);
	function mint(address _to, uint _value) external;
	function burn(uint _value) external;
	function addMinter(address minter) external;
	function removeMinter(address minter) external;
}

interface IPresale {
    function getTokens(uint amountPaid) external;
}

interface IGamePoolUSDC {
	// function addFundsERC20(uint _value) external;
	// function prepareWithdrawal(uint amount) external;
	// function withdrawFundsERC20() external;
	// function logGame(address playerWinner, address playerLoser, uint8 stake) external;
}


/** 
 *  SourceUnit: /home/czarek/Desktop/blockchain/contracts/VXG_ERC20.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity 0.8.10;

////import "./Interfaces.sol";

contract VXG_ERC20 is IVXG_ERC20 {
	address public owner;

	uint public totalSupply;

	mapping (address => uint) private balances;
	mapping (address => mapping (address => uint)) private allowances;
	mapping (address => bool) public minters;

	constructor() {}

	modifier onlyOwner() {
		require(msg.sender == owner, "VXG Token: You must be the contract owner to use this function!");
		_;
	}

	// INTERNAL FUNCTIONS

	function _transfer(address _from, address _to, uint _value) internal {
		balances[_from] -= _value;
		balances[_to] += _value;
		emit Transfer(_from, _to, _value);
	}

	function _approve(address _owner, address _spender, uint _value) internal {
		allowances[_owner][_spender] = _value;
		emit Approval(_owner, _spender, _value);
	}

	function _mint(address _to, uint _amount) internal {
		balances[_to] += _amount;
		totalSupply += _amount;
		emit Transfer(address(0), _to, _amount);
	}

	function _burn(address _from, uint _amount) internal {
		balances[_from] -= _amount;
		totalSupply -= _amount;
		emit Transfer(_from, address(0), _amount);
	}

	// EXTERNAL FUNCTIONS

	function name() external pure returns (string memory) {
		return "Venture X Gaming testet token 0x0000";
	}

	function symbol() external pure returns (string memory) {
		return "VXG-0x0000";
	}

	function decimals() external pure returns (uint8) {
		return 18;
	}

	function balanceOf(address _owner) external view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) external returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
		_approve(_from, _to, allowances[_from][msg.sender] - _value);
		_transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) external returns (bool success) {
		_approve(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	function increaseAllowance(address _spender, uint _value) external returns (uint finalAllowance) {
		finalAllowance = allowances[msg.sender][_spender] + _value;
		_approve(msg.sender, _spender, finalAllowance);
	}

	function decreaseAllowance(address _spender, uint _value) external returns (uint finalAllowance) {
		uint _allowance = allowances[msg.sender][_spender];
		unchecked {
			finalAllowance = _allowance > _value ? _allowance - _value : 0;
		}
		_approve(msg.sender, _spender, finalAllowance);
		return finalAllowance;
	}

	function mint(address _to, uint _value) external {
		require(minters[msg.sender], "VXG Token: You need to be a minter to use this function!");
		_mint(_to, _value);
	}

	function burn(uint _value) external {
		_burn(msg.sender, _value);
	}

	// MODERATOR FUNCTIONS

	function transferOwnership(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function addMinter(address minter) onlyOwner external {
		minters[minter] = true;
	}

	function removeMinter(address minter) onlyOwner external {
		minters[minter] = false;
	}
}