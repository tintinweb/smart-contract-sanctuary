/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: @openzeppelin\contracts\math\Math.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin\contracts\math\SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol


pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\LPTokenWrapper.sol


pragma solidity 0.6.12;



abstract contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    uint256 public immutable devFee;

    address public treasury;
    // Returns the total staked tokens within the contract
    uint256 public totalSupply;
    uint256 public boostedTotalSupply;
    uint256 public startTime;
    uint256 public burnFee;

    struct Balance {
        uint256 balance;
        uint256 boostedBalance;
    }

    mapping(address => Balance) internal _balances;

    constructor(
        uint256 _devFee,
        address _stakingToken,
        address _treasury,
        uint256 _burnFee
    ) public {
        devFee = _devFee;
        stakingToken = IERC20(_stakingToken);
        treasury = _treasury;
        burnFee = _burnFee;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].balance;
    }

    function boostedBalanceOf(address account) public view returns (uint256) {
        return _balances[account].boostedBalance;
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        if (burnFee > 0 ) {
            uint tokenBurnBalance = amount.mul(burnFee).div(10000);
            uint stakedBalance = amount.sub(tokenBurnBalance);
            _balances[msg.sender].balance = _balances[msg.sender].balance.add(
            stakedBalance
           );
            totalSupply = totalSupply.add(stakedBalance);
            return;
        }
         // Increment sender's balances and total supply
        _balances[msg.sender].balance = _balances[msg.sender].balance.add(
            amount
        );
        totalSupply = totalSupply.add(amount);

    }

    // Subtract balances withdrawn from the user
    function withdraw(uint256 amount) public virtual {
        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender].balance = _balances[msg.sender].balance.sub(
            amount
        );

        // Calculate the withdraw tax (it's 1.5% of the amount)
        uint256 tax = amount.mul(devFee).div(1000);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount - tax);
        // Tax to treasury
        stakingToken.safeTransfer(treasury, tax);
    }
}

// File: contracts\interfaces\IDeflector.sol


pragma solidity ^0.6.0;

interface IDeflector {
    function calculateBoostedBalance(address _user, uint256 _balance)
        external
        view
        returns (uint256);

    function calculateCost(
        address _user,
        address _token,
        uint256 _nextLevel
    ) external view returns (uint256);

    function updateLevel(
        address _user,
        address _token,
        uint256 _nextLevel,
        uint256 _balance
    ) external returns (uint256);
}

// File: contracts\interfaces\IERC20Metadata.sol


pragma solidity 0.6.12;


interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

// File: contracts\DeflectPool.sol


pragma solidity 0.6.12;

/*
    ▓█████▄ ▓█████   ████ ▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓   ██▓███   ▒█████   ▒█████   ██▓
    ▒██▀ ██▌▓█   ▀  ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒   ▓██░  ██▒▒██▒  ██▒▒██▒  ██▒ ▓██▒
    ░██   █▌▒███    ▒████ ░▒██░    ▒███   ▒▓█    ▄    ██░ ▒    ▓██░ ██▓▒▒██   ██▒▒██░  ██▒ ▒██░
    ░▓█▄   ▌▒▓█  ▄ ░ ▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░  ██ ░    ▒██▄█▓▒ ▒▒██   ██░▒██   ██░ ▒██░
    ░▒████▓ ░▒████▒░ ▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒     ▒██▒ ░  ░░ ████▓▒░░ ████▓▒░░██████▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░        ▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░▓  ░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░          ░▒ ░       ░ ▒ ▒░   ░ ▒ ▒░ ░ ░ ▒  ░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░             ░             ░░         ░ ░ ░ ▒  ░ ░ ░ ▒


*/






/**
 * @title DeflectPool
 * @author DEFLECT PROTOCOL
 * @dev This contract is a time-based yield farming pool with effective-staking multiplier mechanics.
 *
 * * * NOTE: A withdrawal fee of 1.5% is included which is sent to the treasury address. * * *
 */

contract DeflectPool is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable rewardToken;
    uint256 public immutable stakingTokenMultiplier;
    IDeflector public immutable deflector;
    uint256 public immutable duration;
    uint256 public immutable deployedTime;
    address public immutable devFund;

    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    struct RewardInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    mapping(address => RewardInfo) public rewards;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(address _token, uint256 level);

    // Set the staking token for the contract
    constructor(
        uint256 _duration,
        address _stakingToken,
        IERC20Metadata _rewardToken,
        address _deflector,
        address _treasury,
        address _devFund,
        uint256 _devFee,
        uint256 _burnFee
    ) public LPTokenWrapper(_devFee, _stakingToken, _treasury, _burnFee) Ownable() {
        require(_duration != 0 && _stakingToken != address(0) && _rewardToken != IERC20Metadata(0) && _deflector != address(0) && _treasury != address(0) && _devFund != address(0), "!constructor");
        deflector = IDeflector(_deflector);
        stakingTokenMultiplier = 10**uint256(IERC20Metadata(_stakingToken).decimals());
        rewardToken = _rewardToken;
        duration = _duration;
        deployedTime = block.timestamp;
        devFund = _devFund;
    }

    function setNewTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }

    function lastTimeRewardsActive() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /* @dev Returns the current rate of rewards per token (doh) */
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before startTime.
        if (block.timestamp < startTime) {
            return 0;
        }

        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // Effective total supply takes into account all the multipliers bought by userbase.
        uint256 effectiveTotalSupply = totalSupply.add(boostedTotalSupply);
        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return rewardPerTokenStored
        .add(
            lastTimeRewardsActive()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(stakingTokenMultiplier)
            .div(effectiveTotalSupply)
        );
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account) public view returns (uint256) {
        uint256 effectiveBalance = _balances[account].balance.add(_balances[account].boostedBalance);
        RewardInfo memory userRewards = rewards[account];
        return effectiveBalance.mul(rewardPerToken().sub(userRewards.userRewardPerTokenPaid)).div(stakingTokenMultiplier).add(userRewards.rewards);
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override {
        require(amount > 0, "Cannot stake 0");
        updateReward(msg.sender);

        // Call the parent to adjust the balances.
        super.stake(amount);

        // Adjust the bonus effective stake according to the multiplier.
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        adjustBoostedBalance(boostedBalance);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);

        // Adjust regular balances
        super.withdraw(amount);

        // And the bonus balances
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        adjustBoostedBalance(boostedBalance);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Adjust the bonus effective stakee for user and whole userbase */
    function adjustBoostedBalance(uint256 _boostedBalance) private {
        Balance storage balances = _balances[msg.sender];
        uint256 previousBoostedBalance = balances.boostedBalance;
        if (_boostedBalance < previousBoostedBalance) {
            uint256 diffBalancesAccounting = previousBoostedBalance.sub(_boostedBalance);
            boostedTotalSupply = boostedTotalSupply.sub(diffBalancesAccounting);
        } else if (_boostedBalance > previousBoostedBalance) {
            uint256 diffBalancesAccounting = _boostedBalance.sub(previousBoostedBalance);
            boostedTotalSupply = boostedTotalSupply.add(diffBalancesAccounting);
        }
        balances.boostedBalance = _boostedBalance;
    }

    // Ease-of-access function for user to remove assets from the pool.
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender].rewards = 0;
            emit RewardPaid(msg.sender, reward);
            rewardToken.safeTransfer(msg.sender, reward);
        }
    }

    // Called to start the pool.
    // Owner must send rewards to the contract and the balance of this token is used as the reward to account for fee on transfer tokens.
    // The reward period will be the duration of the pool.
    function notifyRewardAmount() external onlyOwner() {
        uint256 reward = rewardToken.balanceOf(address(this));
        require(reward > 0, "!reward added");
        // Update reward values
        updateRewardPerTokenStored();

        // Rewardrate must stay at a constant since it's used by end-users claiming rewards after the reward period has finished.
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            // Remaining time for the pool
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            // And the rewards
            uint256 rewardsRemaining = remainingTime.mul(rewardRate);
            // Set the current rate
            rewardRate = reward.add(rewardsRemaining).div(duration);
        }

        // Set the last updated
        lastUpdateTime = block.timestamp;
        startTime = block.timestamp;
        // Add the period to be equal to duration set.s
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(address _token, uint256 _newLevel) external {
        require(block.timestamp < periodFinish, "cannot buy after pool ends");

        updateReward(msg.sender);
        
        // Calculates cost, ensures it is a new level too
        uint256 cost = deflector.calculateCost(msg.sender, _token, _newLevel);
        require(cost > 0, "cost cannot be 0");

        // Update level in multiplier contract
        uint256 newBoostedBalance = deflector.updateLevel(msg.sender, _token, _newLevel, _balances[msg.sender].balance);

        // Adjust new level
        adjustBoostedBalance(newBoostedBalance);

        emit Boost(_token, _newLevel);

        uint256 actualCost = cost.mul(periodFinish - block.timestamp).div(duration);

        uint256 devPortion = actualCost.mul(25) / 100;

        // Transfer the bonus cost into the treasury and dev fund.
        IERC20Metadata(_token).safeTransferFrom(msg.sender, devFund, devPortion);
        IERC20Metadata(_token).safeTransferFrom(msg.sender, treasury, actualCost - devPortion);
    }

    // Sync after minting more prism
    function sync() external {
        updateReward(msg.sender);

        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        require(boostedBalance > _balances[msg.sender].boostedBalance, "DeflectPool::sync: Invalid sync invocation");
        // Adjust new level
        adjustBoostedBalance(boostedBalance);
    }

    // Returns the multiplier for user.
    function getUserMultiplier() external view returns (uint256) {
         // And the bonus balances
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        
        if (boostedBalance == 0) return 0;

        return boostedBalance * 100 / _balances[msg.sender].balance;
    }

    function getLevelCost(address _token, uint256 _level) external view returns (uint256) {
        return deflector.calculateCost(msg.sender, _token, _level);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner() {
        require(block.timestamp >= periodFinish + 12 hours, "Cannot eject before period finishes or pool has started");
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner() {
        periodFinish = block.timestamp;
    }

    // Callable only after the pool has started and the pools reward distribution period has finished.
    function emergencyWithdraw() external {
        require(block.timestamp >= periodFinish + 12 hours, "DeflectPool::emergencyWithdraw: Cannot emergency withdraw before period finishes or pool has started");
        uint256 fullWithdrawal = balanceOf(msg.sender);
        require(fullWithdrawal > 0, "DeflectPool::emergencyWithdraw: Cannot withdraw 0");
        super.withdraw(fullWithdrawal);
        emit Withdrawn(msg.sender, fullWithdrawal);
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardsActive();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account].rewards = earned(account);
        rewards[account].userRewardPerTokenPaid = rewardPerTokenStored;
    }
}