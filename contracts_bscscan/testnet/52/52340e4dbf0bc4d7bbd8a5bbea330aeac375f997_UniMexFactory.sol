/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Uniswap.sol



pragma solidity 0.6.12;


interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 r0, uint112 r1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address a, address b) external view returns (address p);
}

interface IUniswapV2Router02 {
    function WETH() external returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UV2: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UV2: ZERO_ADDRESS');
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UV2: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UV2: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

// File: @openzeppelin/contracts/math/SignedSafeMath.sol

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/IUniMexFactory.sol


pragma solidity 0.6.12;

interface IUniMexFactory {
  function getPool(address) external returns(address);
  function getMaxLeverage(address) external returns(uint256);
  function allowedMargins(address) external returns (bool);
  function utilizationScaled(address token) external pure returns(uint256);
}

// File: contracts/UniMexPool.sol

pragma solidity 0.6.12;






contract UniMexPool {
	using SignedSafeMath for int256;
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 private constant FLOAT_SCALAR = 2**64;
	IERC20 public WETH;

	struct User {
		uint256 balance;
		int256 scaledPayout;
		int256 balanceCorrection;
	}

	mapping(address => User) public users;

	IERC20 public token;
	address public factory;
	uint256 public divPerShare;
	uint256 public outstandingLoans;
	uint256 public corrPerShare;

	event OnDeposit(address indexed from, uint256 amount);
	event OnWithdraw(address indexed from, uint256 amount);
	event OnClaim(address indexed from, uint256 amount);
	event OnForceCorrection(address indexed from, uint256 amount);
	event OnTransfer(address indexed from, address indexed to, uint256 amount);
	event OnDistribute(address indexed from, uint256 amount);
	event OnBalanceCorrection(address indexed from, uint256 amount);
	event OnBorrow(address indexed from, uint256 amount);
	event OnRepay(address indexed from, uint256 amount);

	modifier onlyMargin() {
		require(IUniMexFactory(factory).allowedMargins(msg.sender), "ONLY_MARGIN_CONTRACT");
		_;
	}

	constructor() public {
		factory = msg.sender;
	}

	function totalSupply() private view returns (uint256) {
		return token.balanceOf(address(this)).add(outstandingLoans);
	}

	function initialize(address _token, address _WETH) external returns (bool) {
		require(msg.sender == factory, "ONLY_FACTORY_CONTRACT");
		token = IERC20(_token);
		WETH = IERC20(_WETH);
		return true;
	}

	/**
	 * @notice division by zero is avoided, since with an empty pool there can be no loans
	 * @notice restricted calling to margin contract
	 */
	function distribute(uint256 _amount) external onlyMargin returns (bool) {
		WETH.safeTransferFrom(address(msg.sender), address(this), _amount);
		divPerShare = divPerShare.add(
			(_amount.mul(FLOAT_SCALAR)).div(totalSupply())
		);
		emit OnDistribute(msg.sender, _amount);
		return true;
	}

	function distributeCorrection(uint256 _amount) external onlyMargin returns (bool) {
		corrPerShare = corrPerShare.add(_amount.mul(FLOAT_SCALAR).div(totalSupply()));
		emit OnBalanceCorrection(msg.sender, _amount);
		return true;
	}

	function deposit(uint256 _amount) external returns (bool) {
		token.safeTransferFrom(msg.sender, address(this), _amount);
		users[msg.sender].balance = users[msg.sender].balance.add(_amount);
		users[msg.sender].scaledPayout = users[msg.sender].scaledPayout.add(
			int256(_amount.mul(divPerShare))
		);
		users[msg.sender].balanceCorrection = users[msg.sender].balanceCorrection.add(int256(_amount.mul(corrPerShare)));
		emit OnDeposit(msg.sender, _amount);
		return true;
	}

	function withdraw(uint256 _amount) external returns (bool) {
		uint256 _balance = correctedBalanceOf(msg.sender);
		require(_balance >= _amount, "WRONG AMOUNT: CHECK CORRECTED BALANCE");
		if (outstandingLoans > 0) {
			uint256 currentUtilization =
				(outstandingLoans.mul(FLOAT_SCALAR)).div(
					(totalSupply().sub(_amount)).add(outstandingLoans)
				);
			require(
				(currentUtilization <=
					IUniMexFactory(factory).utilizationScaled(address(token))),
				"NO_LIQUIDITY"
			);
		}
		users[msg.sender].balance = users[msg.sender].balance.sub(_amount);
		users[msg.sender].scaledPayout = users[msg.sender].scaledPayout.sub(
			int256(_amount.mul(divPerShare))
		);
		users[msg.sender].balanceCorrection = users[msg.sender].balanceCorrection.sub(int256(_amount.mul(corrPerShare)));
		token.safeTransfer(msg.sender, _amount);
		emit OnWithdraw(msg.sender, _amount);
		return true;
	}

	function claim() external returns (bool) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0);
		users[msg.sender].scaledPayout = users[msg.sender].scaledPayout.add(
			int256(_dividends.mul(FLOAT_SCALAR))
		);
		WETH.safeTransfer(address(msg.sender), _dividends);
		emit OnClaim(msg.sender, _dividends);
		return true;
	}

/*	function correctMyBalance() external returns (bool) {
		require(balanceOf(msg.sender) > 0);
		uint256 _newBalance = correctedBalanceOf(msg.sender);
		users[msg.sender].balance = _newBalance;
		users[msg.sender].balanceCorrection = 0;
		emit OnForceCorrection(msg.sender, _newBalance);
		return true;
	}*/

	function transfer(address _to, uint256 _amount) external returns (bool) {
		return _transfer(msg.sender, _to, _amount);
	}

	function borrow(uint256 _amount) external onlyMargin returns (bool) {
		uint256 currentUtilization =
			(outstandingLoans.add(_amount).mul(FLOAT_SCALAR)).div(
				totalSupply().add(outstandingLoans)
			);
		require(
			currentUtilization <=
				IUniMexFactory(factory).utilizationScaled(address(token)),
			"POOL:NO_LIQUIDITY"
		);
		outstandingLoans = outstandingLoans.add(_amount);
		token.safeTransfer(msg.sender, _amount);
		emit OnBorrow(msg.sender, _amount);
		return true;
	}

	function repay(uint256 _amount) external onlyMargin returns (bool) {
		token.safeTransferFrom(msg.sender, address(this), _amount);
		outstandingLoans = outstandingLoans.sub(_amount);
		emit OnRepay(msg.sender, _amount);
		return true;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return users[_user].balance;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return
			uint256(
				int256(divPerShare.mul(balanceOf(_user))).sub(
					users[_user].scaledPayout
				)
			)
				.div(FLOAT_SCALAR);
	}

	function correctedBalanceOf(address _user) public view returns (uint256) {
		uint256 _balance = balanceOf(_user);
		return _balance.sub(uint256(int256(corrPerShare.mul(_balance)).sub(users[_user].balanceCorrection))
					.div(FLOAT_SCALAR));
	}

	function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
		require(users[_from].balance >= _amount);
		users[_from].balance = users[_from].balance.sub(_amount);
		users[_from].scaledPayout = users[_from].scaledPayout.sub(
			int256(_amount.mul(divPerShare))
		);
		users[_from].balanceCorrection = users[_from].balanceCorrection.sub(
			int256(_amount.mul(corrPerShare))
		);
		users[_to].balance = users[_to].balance.add(_amount);
		users[_to].scaledPayout = users[_to].scaledPayout.add(
			int256(_amount.mul(divPerShare))
		);
		users[_to].balanceCorrection = users[_to].balanceCorrection.add(
			int256(_amount.mul(corrPerShare))
		);
		emit OnTransfer(msg.sender, _to, _amount);
		return true;
	}
}

// File: contracts/UniMexFactory.sol


pragma solidity 0.6.12;





contract UniMexFactory is Ownable {
    using SafeMath for uint256;

    address public margin;
    address[] public allPools;

    address public WETH;
    IUniswapV2Factory public UNISWAP_FACTORY;
    uint256 constant private FLOAT_SCALAR = 2**64;

    struct Pool {
        address ethAddr;
        uint256 maxLeverage;
        uint256 utilizationScaled;
    }

    mapping(address => Pool) public poolInfo;
    mapping(address => bool) public allowed;
    mapping(address => bool) public allowedMargins;

    event OnPoolCreated(address indexed pair, address pool, uint256 poolLength);

    constructor(address _WETH, address _UNISWAP) public {
        WETH = _WETH;
        UNISWAP_FACTORY = IUniswapV2Factory(_UNISWAP);
        allowed[WETH] = true;
    }

    function setMarginAllowed(address _margin, bool _allowed) external onlyOwner {
        require(_margin != address(0));
        allowedMargins[_margin] = _allowed;
    }

    function setUtilizationScaled(address _token, uint256 _utilizationScaled) external onlyOwner returns(uint256) {
        require(allowed[_token] = true);
        require(_utilizationScaled < FLOAT_SCALAR);
        poolInfo[_token].utilizationScaled = _utilizationScaled;
    }

    function setMaxLeverage(address _token, uint256 _leverage) external onlyOwner returns(uint256) {
        require(allowed[_token] = true);
        require(_leverage >= 1 && _leverage <= 5);
        poolInfo[_token].maxLeverage = _leverage;
    }

    function addPool(address _token) external onlyOwner {
        address token0;
        address token1;
        (token0, token1) = UniswapV2Library.sortTokens(_token, WETH);
        require(UNISWAP_FACTORY.getPair(token0, token1) != address(0) , 'INVALID_UNISWAP_PAIR');
        allowed[_token] = true;
    }

    function utilizationScaled(address _token) external view returns(uint256) {
        return poolInfo[_token].utilizationScaled;
    }

    function getMaxLeverage(address _token) external view returns(uint256) {
        return poolInfo[_token].maxLeverage;
    }

    function getPool(address _token) external view returns(address) {
        return poolInfo[_token].ethAddr;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(address _token) public returns (address) {
        require(allowed[_token] == true, 'POOL_NOT_ALLOWED');
        require(poolInfo[_token].ethAddr == address(0), 'POOL_ALREADY_CREATED');
        address pool;
        bytes memory bytecode = type(UniMexPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniMexPool(pool).initialize(_token, WETH);
        poolInfo[_token].ethAddr = pool;
        allPools.push(pool);
        emit OnPoolCreated(_token, pool, allPools.length);
        return pool;
    }

}