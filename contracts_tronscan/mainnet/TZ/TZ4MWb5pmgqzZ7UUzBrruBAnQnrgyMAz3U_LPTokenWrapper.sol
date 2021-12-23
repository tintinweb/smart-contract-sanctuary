//SourceUnit: 质押到池子.sol

pragma solidity ^0.5.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function burn(address account, uint amount) external;

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

pragma solidity ^0.5.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity 0.5.4;
	interface IJustswapExchange {
	event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
	  event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
	  event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
	  event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

	   /**
	   * @notice Convert TRX to Tokens.
	   * @dev User specifies exact input (msg.value).
	   * @dev User cannot specify minimum output or deadline.
	   */
	  function () external payable;

	 /**
	   * @dev Pricing function for converting between TRX && Tokens.
	   * @param input_amount Amount of TRX or Tokens being sold.
	   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
	   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
	   * @return Amount of TRX or Tokens bought.
	   */
	  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

	 /**
	   * @dev Pricing function for converting between TRX && Tokens.
	   * @param output_amount Amount of TRX or Tokens being bought.
	   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
	   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
	   * @return Amount of TRX or Tokens sold.
	   */
	  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


	  /** 
	   * @notice Convert TRX to Tokens.
	   * @dev User specifies exact input (msg.value) && minimum output.
	   * @param min_tokens Minimum Tokens bought.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @return Amount of Tokens bought.
	   */ 
	  function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

	  /** 
	   * @notice Convert TRX to Tokens && transfers Tokens to recipient.
	   * @dev User specifies exact input (msg.value) && minimum output
	   * @param min_tokens Minimum Tokens bought.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output Tokens.
	   * @return  Amount of Tokens bought.
	   */
	  function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);


	  /** 
	   * @notice Convert TRX to Tokens.
	   * @dev User specifies maximum input (msg.value) && exact output.
	   * @param tokens_bought Amount of tokens bought.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @return Amount of TRX sold.
	   */
	  function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
	  /** 
	   * @notice Convert TRX to Tokens && transfers Tokens to recipient.
	   * @dev User specifies maximum input (msg.value) && exact output.
	   * @param tokens_bought Amount of tokens bought.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output Tokens.
	   * @return Amount of TRX sold.
	   */
	  function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

	  /** 
	   * @notice Convert Tokens to TRX.
	   * @dev User specifies exact input && minimum output.
	   * @param tokens_sold Amount of Tokens sold.
	   * @param min_trx Minimum TRX purchased.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @return Amount of TRX bought.
	   */
	  function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

	  /** 
	   * @notice Convert Tokens to TRX && transfers TRX to recipient.
	   * @dev User specifies exact input && minimum output.
	   * @param tokens_sold Amount of Tokens sold.
	   * @param min_trx Minimum TRX purchased.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output TRX.
	   * @return  Amount of TRX bought.
	   */
	  function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

	  /** 
	   * @notice Convert Tokens to TRX.
	   * @dev User specifies maximum input && exact output.
	   * @param trx_bought Amount of TRX purchased.
	   * @param max_tokens Maximum Tokens sold.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @return Amount of Tokens sold.
	   */
	  function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

	  /**
	   * @notice Convert Tokens to TRX && transfers TRX to recipient.
	   * @dev User specifies maximum input && exact output.
	   * @param trx_bought Amount of TRX purchased.
	   * @param max_tokens Maximum Tokens sold.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output TRX.
	   * @return Amount of Tokens sold.
	   */
	  function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (token_addr).
	   * @dev User specifies exact input && minimum output.
	   * @param tokens_sold Amount of Tokens sold.
	   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
	   * @param min_trx_bought Minimum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param token_addr The address of the token being purchased.
	   * @return Amount of Tokens (token_addr) bought.
	   */
	  function tokenToTokenSwapInput(
		uint256 tokens_sold, 
		uint256 min_tokens_bought, 
		uint256 min_trx_bought, 
		uint256 deadline, 
		address token_addr) 
		external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
	   *         Tokens (token_addr) to recipient.
	   * @dev User specifies exact input && minimum output.
	   * @param tokens_sold Amount of Tokens sold.
	   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
	   * @param min_trx_bought Minimum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output TRX.
	   * @param token_addr The address of the token being purchased.
	   * @return Amount of Tokens (token_addr) bought.
	   */
	  function tokenToTokenTransferInput(
		uint256 tokens_sold, 
		uint256 min_tokens_bought, 
		uint256 min_trx_bought, 
		uint256 deadline, 
		address recipient, 
		address token_addr) 
		external returns (uint256);


	  /**
	   * @notice Convert Tokens (token) to Tokens (token_addr).
	   * @dev User specifies maximum input && exact output.
	   * @param tokens_bought Amount of Tokens (token_addr) bought.
	   * @param max_tokens_sold Maximum Tokens (token) sold.
	   * @param max_trx_sold Maximum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param token_addr The address of the token being purchased.
	   * @return Amount of Tokens (token) sold.
	   */
	  function tokenToTokenSwapOutput(
		uint256 tokens_bought, 
		uint256 max_tokens_sold, 
		uint256 max_trx_sold, 
		uint256 deadline, 
		address token_addr) 
		external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
	   *         Tokens (token_addr) to recipient.
	   * @dev User specifies maximum input && exact output.
	   * @param tokens_bought Amount of Tokens (token_addr) bought.
	   * @param max_tokens_sold Maximum Tokens (token) sold.
	   * @param max_trx_sold Maximum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output TRX.
	   * @param token_addr The address of the token being purchased.
	   * @return Amount of Tokens (token) sold.
	   */
	  function tokenToTokenTransferOutput(
		uint256 tokens_bought, 
		uint256 max_tokens_sold, 
		uint256 max_trx_sold, 
		uint256 deadline, 
		address recipient, 
		address token_addr) 
		external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
	   * @dev Allows trades through contracts that were not deployed from the same factory.
	   * @dev User specifies exact input && minimum output.
	   * @param tokens_sold Amount of Tokens sold.
	   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
	   * @param min_trx_bought Minimum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param exchange_addr The address of the exchange for the token being purchased.
	   * @return Amount of Tokens (exchange_addr.token) bought.
	   */
	  function tokenToExchangeSwapInput(
		uint256 tokens_sold, 
		uint256 min_tokens_bought, 
		uint256 min_trx_bought, 
		uint256 deadline, 
		address exchange_addr) 
		external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
	   *         Tokens (exchange_addr.token) to recipient.
	   * @dev Allows trades through contracts that were not deployed from the same factory.
	   * @dev User specifies exact input && minimum output.
	   * @param tokens_sold Amount of Tokens sold.
	   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
	   * @param min_trx_bought Minimum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output TRX.
	   * @param exchange_addr The address of the exchange for the token being purchased.
	   * @return Amount of Tokens (exchange_addr.token) bought.
	   */
	  function tokenToExchangeTransferInput(
		uint256 tokens_sold, 
		uint256 min_tokens_bought, 
		uint256 min_trx_bought, 
		uint256 deadline, 
		address recipient, 
		address exchange_addr) 
		external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
	   * @dev Allows trades through contracts that were not deployed from the same factory.
	   * @dev User specifies maximum input && exact output.
	   * @param tokens_bought Amount of Tokens (token_addr) bought.
	   * @param max_tokens_sold Maximum Tokens (token) sold.
	   * @param max_trx_sold Maximum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param exchange_addr The address of the exchange for the token being purchased.
	   * @return Amount of Tokens (token) sold.
	   */
	  function tokenToExchangeSwapOutput(
		uint256 tokens_bought, 
		uint256 max_tokens_sold, 
		uint256 max_trx_sold, 
		uint256 deadline, 
		address exchange_addr) 
		external returns (uint256);

	  /**
	   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
	   *         Tokens (exchange_addr.token) to recipient.
	   * @dev Allows trades through contracts that were not deployed from the same factory.
	   * @dev User specifies maximum input && exact output.
	   * @param tokens_bought Amount of Tokens (token_addr) bought.
	   * @param max_tokens_sold Maximum Tokens (token) sold.
	   * @param max_trx_sold Maximum TRX purchased as intermediary.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @param recipient The address that receives output TRX.
	   * @param exchange_addr The address of the exchange for the token being purchased.
	   * @return Amount of Tokens (token) sold.
	   */
	  function tokenToExchangeTransferOutput(
		uint256 tokens_bought, 
		uint256 max_tokens_sold, 
		uint256 max_trx_sold, 
		uint256 deadline, 
		address recipient, 
		address exchange_addr) 
		external returns (uint256);


	  /***********************************|
	  |         Getter Functions          |
	  |__________________________________*/

	  /**
	   * @notice external price function for TRX to Token trades with an exact input.
	   * @param trx_sold Amount of TRX sold.
	   * @return Amount of Tokens that can be bought with input TRX.
	   */
	  function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

	  /**
	   * @notice external price function for TRX to Token trades with an exact output.
	   * @param tokens_bought Amount of Tokens bought.
	   * @return Amount of TRX needed to buy output Tokens.
	   */
	  function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

	  /**
	   * @notice external price function for Token to TRX trades with an exact input.
	   * @param tokens_sold Amount of Tokens sold.
	   * @return Amount of TRX that can be bought with input Tokens.
	   */
	  function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

	  /**
	   * @notice external price function for Token to TRX trades with an exact output.
	   * @param trx_bought Amount of output TRX.
	   * @return Amount of Tokens needed to buy output TRX.
	   */
	  function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

	  /** 
	   * @return Address of Token that is sold on this exchange.
	   */
	  function tokenAddress() external view returns (address);

	  /**
	   * @return Address of factory that created this exchange.
	   */
	  function factoryAddress() external view returns (address);


	  /***********************************|
	  |        Liquidity Functions        |
	  |__________________________________*/

	  /** 
	   * @notice Deposit TRX && Tokens (token) at current ratio to mint UNI tokens.
	   * @dev min_liquidity does nothing when total UNI supply is 0.
	   * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
	   * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @return The amount of UNI minted.
	   */
	  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

	  /**
	   * @dev Burn UNI tokens to withdraw TRX && Tokens at current ratio.
	   * @param amount Amount of UNI burned.
	   * @param min_trx Minimum TRX withdrawn.
	   * @param min_tokens Minimum Tokens withdrawn.
	   * @param deadline Time after which this transaction can no longer be executed.
	   * @return The amount of TRX && Tokens withdrawn.
	   */
	  function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
	}

// File: contracts/CurveRewards.sol

pragma solidity ^0.5.0;


contract LPTokenWrapper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public y = IERC20(0x41d062a4f45ee803b7fb93ca8d83860e9730bb35e0); // Stake Token address
	IERC20 public y2 = IERC20(0x411b9297b628294ff2ede3385f14e5cf187f67a54a); // Stake Token address
    uint256 private _totalSupply;
	uint256 private _num=1;
    mapping(address => uint256) private _balances;
	mapping(address => uint256) private _balances2;
	uint256 public ethBurn  = 100 * 10 ** 6;
	address payable public backAddr=address(0x419E1D445505E6ACEA6372C69C4AFBE6C0C76F8587);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
	
	function getMaxHoldAMount(address payable exchange_addr,uint256 tokens_bought) public view returns(uint256){
        uint256 trx_bought = IJustswapExchange(exchange_addr).getTrxToTokenInputPrice(tokens_bought);

        return trx_bought;
    }

    
	function balanceOf2(address account) public view returns (uint256) {
        return _balances2[account];
    }
	
	function setnum(uint256 num) public returns (bool) {
		require(owner() == msg.sender, "Address: insufficient balance");
    	_num=num;
        return true;
    }
	
	function setaddr(address account,address account2) public returns (bool) {
		require(owner() == msg.sender, "Address: insufficient balance");
		y = IERC20(account);
		y2 = IERC20(account2);
        return true;
    }
	
	function getnum() public view returns (uint256) {
        return _num;
    }

    function stake(uint256 amount) public payable{
		require(msg.value >= ethBurn);
		backAddr.transfer(msg.value);
        _totalSupply = _totalSupply.add(amount);
		uint256 amount2=amount.mul(_num);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
		_balances2[msg.sender] = _balances2[msg.sender].add(amount2);
        //y.safeTransferFrom(msg.sender, address(this), amount);
		y2.safeTransferFrom(msg.sender, address(this), amount2);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
		uint256 amount2=amount.mul(_num);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
		_balances2[msg.sender] = _balances2[msg.sender].sub(amount2);
        y.safeTransfer(msg.sender, amount);
		y2.safeTransfer(msg.sender, amount2);
    }
	
}