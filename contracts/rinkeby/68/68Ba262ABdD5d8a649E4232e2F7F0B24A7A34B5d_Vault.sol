// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Vault is IERC20, ReentrancyGuard, Ownable {
	using Math for uint256;
	event EmergencyShutdown(bool active);
	event SwapIn(bytes32 txhash, address sender, uint256 amount);
	event SwapOut(address sender, uint256 amount);

	string public name;
	string public symbol;
	uint256 public decimals;

	uint256 public override totalSupply;
	uint256 public currentSupply;
	uint256 public vaultBalance;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	bool public emergencyShutdown;
	IERC20Metadata public token;
	address public treasury;
	address public bridge;

	uint256 public swapFee; // Basis point 10_000=100%
	uint256 public treasuryFee = 5_000;
	uint256 constant BASIS_POINT = 10_000;

	modifier onlyBridge() {
		require(msg.sender == bridge);
		_;
	}

	modifier notLocked() {
		require(!emergencyShutdown, "Deposits are locked out");
		_;
	}

	constructor(
		string memory _name,
		string memory _symbol,
		address _token,
		address _treasury,
		uint256 _swapFee
	) {
		require(_treasury != address(0));
		name = _name;
		symbol = _symbol;
		decimals = 18;
		token = IERC20Metadata(_token);
		treasury = _treasury;
		token.approve(address(this), type(uint256).max);
		swapFee = _swapFee;
	}

	function deposit(uint256 _amount, address recipient) public nonReentrant notLocked returns (uint256) {
		require(recipient != address(0));
		require(recipient != address(this));

		uint256 amount = _amount;

		// If _amount not specified, transfer the full token balance,
		// up to deposit limit
		if (amount == type(uint256).max) amount = token.balanceOf(msg.sender);

		// Ensure we are depositing something
		require(amount > 0);

		// Issue new shares (needs to be done before taking deposit to be accurate)
		// Shares are issued to recipient (may be different from msg.sender)
		// See @dev note, above.
		uint256 shares = _issueSharesForAmount(recipient, amount);

		// Tokens are transferred from msg.sender (may be different from _recipient)
		token.transferFrom(msg.sender, address(this), amount);

		return shares; // Just in case someone wants them
	}

	function withdraw(uint256 shares, address recipient) external nonReentrant notLocked returns (uint256) {
		// If _shares not specified, transfer full share balance
		if (shares == type(uint256).max) shares = _balances[msg.sender];
		else shares = (shares * currentSupply) / totalSupply; // calculate real share

		// Limit to only the shares they own
		require(shares <= _balances[msg.sender]);

		// Ensure we are withdrawing something
		require(shares > 0);

		// Burn shares (full value of what is being withdrawn)
		uint256 burnAmount = (shares * totalSupply) / currentSupply;

		currentSupply -= shares;
		totalSupply -= burnAmount;
		_balances[msg.sender] -= shares;
		emit Transfer(msg.sender, address(0), burnAmount);

		// Withdraw remaining balance to _recipient (may be different to msg.sender) (minus fee)
		token.transfer(recipient, (burnAmount * 10**token.decimals()) / (10**decimals));

		return shares;
	}

	function _issueSharesForAmount(address to, uint256 amount) internal returns (uint256) {
		// Issues `amount` Vault shares to `to`.
		// Shares must be issued prior to taking on new collateral, or
		// calculation will be wrong. This means that only *trusted* tokens
		// (with no capability for exploitative behavior) can be used.
		uint256 shares = 0;
		// HACK: Saves 2 SLOADs (~200 gas, post-Berlin)

		shares = (amount * (10**decimals)) / 10**token.decimals();
		require(shares != 0); // dev: division rounding resulted in zero

		uint256 newSupply = shares;
		if (totalSupply > 0) {
			newSupply = (newSupply * currentSupply) / totalSupply;
		}

		// Mint new shares
		totalSupply += shares;
		currentSupply += newSupply;
		_balances[to] += newSupply;
		emit Transfer(address(0), to, shares);

		return shares;
	}

	function _totalAssets() internal view returns (uint256) {
		// See note on `totalAssets()`.
		return token.balanceOf(address(this));
	}

	/// @notice Returns the total quantity of all assets under control of this
	/// Vault, whether they're loaned out to a Strategy, or currently held in
	/// the Vault.
	/// @return The total assets under control of this Vault.
	function totalAssets() external view returns (uint256) {
		return _totalAssets();
	}

	function setEmergencyShutdown(bool active) external onlyOwner {
		emergencyShutdown = active;
		emit EmergencyShutdown(active);
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return (_balances[account] * totalSupply) / currentSupply;
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[sender] = senderBalance - amount;
		}
		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}
		return true;
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}
		return true;
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function swapIn(
		bytes32 txhash,
		address account,
		uint256 amount
	) external onlyBridge notLocked returns (bool) {
		require(amount <= token.balanceOf(address(this)), "Transfer amount exceeds vault balance");
		IERC20Metadata(token).transfer(account, amount);
		emit SwapIn(txhash, account, amount);
		vaultBalance -= amount;
		return true;
	}

	function swapOut(address account, uint256 amount) external notLocked {
		uint256 fee = (amount * swapFee) / BASIS_POINT;
		uint256 output = amount - fee;

		uint256 adminFee = (fee * treasuryFee) / BASIS_POINT;
		IERC20Metadata(token).transferFrom(msg.sender, address(this), amount - adminFee);
		IERC20Metadata(token).transferFrom(msg.sender, address(treasury), adminFee); // transfer treasury fee

		totalSupply += ((fee - adminFee) * (10**decimals)) / 10**token.decimals();

		emit SwapOut(account, output);
		vaultBalance += output;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}