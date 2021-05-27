/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity 0.6.6;


// SPDX-License-Identifier: MIT
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "REENTRANCY_ERROR");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0-or-later
// Interface declarations
/* solhint-disable func-order */
interface IUniswapRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
interface IHarvestVault {
    function deposit(uint256 amount) external;

    function withdraw(uint256 numberOfShares) external;
}

// SPDX-License-Identifier: MIT
interface IMintNoRewardPool {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function earned(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function userRewardPerTokenPaid(address account)
        external
        view
        returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function getReward() external;
}

interface IHarvest {
    function setHarvestRewardVault(address _harvestRewardVault) external;

    function setHarvestRewardPool(address _harvestRewardPool) external;

    function setHarvestPoolToken(address _harvestfToken) external;

    function setFarmToken(address _farmToken) external;

    function updateReward() external;
}

interface IStrategy {
    function setTreasury(address payable _feeAddress) external;

    function blacklistAddress(address account) external;

    function removeFromBlacklist(address account) external;

    function setCap(uint256 _cap) external;

    function setLockTime(uint256 _lockTime) external;

    function setFeeAddress(address payable _feeAddress) external;

    function setFee(uint256 _fee) external;

    function rescueDust() external;

    function rescueAirdroppedTokens(address _token, address to) external;

    function setSushiswapRouter(address _sushiswapRouter) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// This contract is used for printing receipt tokens
// Whenever someone joins a pool, a receipt token will be printed for that person
contract ReceiptToken is ERC20, Ownable {
    ERC20 public underlyingToken;
    address public underlyingStrategy;

    constructor(address underlyingAddress, address strategy)
        public
        ERC20(
            string(abi.encodePacked("pAT-", ERC20(underlyingAddress).name())),
            string(abi.encodePacked("pAT-", ERC20(underlyingAddress).symbol()))
        )
    {
        underlyingToken = ERC20(underlyingAddress);
        underlyingStrategy = strategy;
    }

    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burne
     * @param amount Amount of receipt tokens that will get burned
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
contract StrategyBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapRouter public sushiswapRouter;

    ReceiptToken public receiptToken;

    uint256 internal _minSlippage = 10; //0.1%
    uint256 public fee = uint256(100);
    uint256 constant feeFactor = uint256(10000);
    uint256 public cap;

    /// @notice Event emitted when user makes a deposit and receipt token is minted
    event ReceiptMinted(address indexed user, uint256 amount);
    /// @notice Event emitted when user withdraws and receipt token is burned
    event ReceiptBurned(address indexed user, uint256 amount);

    function _validateCommon(
        uint256 deadline,
        uint256 amount,
        uint256 _slippage
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(amount > 0, "AMOUNT_0");
        require(_slippage >= _minSlippage, "SLIPPAGE_ERROR");
        require(_slippage <= feeFactor, "MAX_SLIPPAGE_ERROR");
    }

    function _validateDeposit(
        uint256 deadline,
        uint256 amount,
        uint256 total,
        uint256 slippage
    ) internal view {
        _validateCommon(deadline, amount, slippage);

        require(total.add(amount) <= cap, "CAP_REACHED");
    }

    function _mintParachainAuctionTokens(uint256 _amount) internal {
        receiptToken.mint(msg.sender, _amount);
        emit ReceiptMinted(msg.sender, _amount);
    }

    function _burnParachainAuctionTokens(uint256 _amount) internal {
        receiptToken.burn(msg.sender, _amount);
        emit ReceiptBurned(msg.sender, _amount);
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _calculatePortion(_amount, fee);
    }

    function _getBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function _increaseAllowance(
        address _token,
        address _contract,
        uint256 _amount
    ) internal {
        IERC20(_token).safeIncreaseAllowance(address(_contract), _amount);
    }

    function _getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function _swapTokenToEth(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1]; //amount of ETH
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice = (exchangeAmount.mul(ethPerToken)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        _increaseAllowance(
            swapPath[0],
            address(sushiswapRouter),
            exchangeAmount
        );
        uint256[] memory tokenSwapAmounts =
            sushiswapRouter.swapExactTokensForETH(
                exchangeAmount,
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );
        return tokenSwapAmounts[tokenSwapAmounts.length - 1];
    }

    function _swapEthToToken(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 tokensPerEth
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1];
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice =
            (exchangeAmount.mul(tokensPerEth)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        uint256[] memory swapResult =
            sushiswapRouter.swapExactETHForTokens{value: exchangeAmount}(
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );

        return swapResult[swapResult.length - 1];
    }

    function _getMinAmount(uint256 amount, uint256 slippage)
        private
        pure
        returns (uint256)
    {
        uint256 portion = _calculatePortion(amount, slippage);
        return amount.sub(portion);
    }

    function _calculatePortion(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        return (_amount.mul(_fee)).div(feeFactor);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
contract HarvestBase is Ownable, StrategyBase, IHarvest, IStrategy {
    address public token;
    address public weth;
    address public farmToken;
    address public harvestfToken;
    address payable public treasuryAddress;
    address payable public feeAddress;
    uint256 public ethDust;
    uint256 public treasueryEthDust;
    uint256 public totalDeposits;
    uint256 public lockTime = 1;

    mapping(address => bool) public blacklisted; //blacklisted users do not receive a receipt token

    IMintNoRewardPool public harvestRewardPool;
    IHarvestVault public harvestRewardVault;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amountEth; //how much ETH the user entered with; should be 0 for HarvestSC
        uint256 amountToken; //how much Token was obtained by swapping user's ETH
        uint256 amountfToken; //how much fToken was obtained after deposit to vault
        uint256 amountReceiptToken; //receipt tokens printed for user; should be equal to amountfToken
        uint256 underlyingRatio; //ratio between obtained fToken and token
        uint256 userTreasuryEth; //how much eth the user sent to treasury
        uint256 userCollectedFees; //how much eth the user sent to fee address
        bool wasUserBlacklisted; //if user was blacklist at deposit time, he is not receiving receipt tokens
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check
        uint256 earnedTokens;
        uint256 earnedRewards; //before fees
        //----
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }
    mapping(address => UserInfo) public userInfo;

    struct UserDeposits {
        uint256 timestamp;
        uint256 amountfToken;
    }
    /// @notice Used internally for avoiding "stack-too-deep" error when depositing
    struct DepositData {
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 obtainedfToken;
        uint256 prevfTokenBalance;
    }

    /// @notice Used internally for avoiding "stack-too-deep" error when withdrawing
    struct WithdrawData {
        uint256 prevDustEthBalance;
        uint256 prevfTokenBalance;
        uint256 prevTokenBalance;
        uint256 obtainedfToken;
        uint256 obtainedToken;
        uint256 feeableToken;
        uint256 feeableEth;
        uint256 totalEth;
        uint256 totalToken;
        uint256 auctionedEth;
        uint256 auctionedToken;
        uint256 rewards;
        uint256 farmBalance;
        uint256 burnAmount;
        uint256 earnedTokens;
        uint256 rewardsInEth;
        uint256 auctionedRewardsInEth;
        uint256 userRewardsInEth;
        uint256 initialAmountfToken;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    event ExtraTokensExchanged(
        address indexed user,
        uint256 tokensAmount,
        uint256 obtainedEth
    );
    event ObtainedInfo(
        address indexed user,
        uint256 underlying,
        uint256 underlyingReceipt
    );

    event RewardsEarned(address indexed user, uint256 amount);
    event ExtraTokens(address indexed user, uint256 amount);

    /// @notice Event emitted when blacklist status for an address changes
    event BlacklistChanged(
        string actionType,
        address indexed user,
        bool oldVal,
        bool newVal
    );

    /// @notice Event emitted when owner makes a rescue dust request
    event RescuedDust(string indexed dustType, uint256 amount);

    /// @notice Event emitted when owner changes any contract address
    event ChangedAddress(
        string indexed addressType,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice Event emitted when owner changes any contract address
    event ChangedValue(
        string indexed valueType,
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Setters -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Update the address of VaultDAI
     * @dev Can only be called by the owner
     * @param _harvestRewardVault Address of VaultDAI
     */
    function setHarvestRewardVault(address _harvestRewardVault)
        external
        override
        onlyOwner
    {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        emit ChangedAddress(
            "VAULT",
            address(harvestRewardVault),
            _harvestRewardVault
        );
        harvestRewardVault = IHarvestVault(_harvestRewardVault);
    }

    /**
     * @notice Update the address of NoMintRewardPool
     * @dev Can only be called by the owner
     * @param _harvestRewardPool Address of NoMintRewardPool
     */
    function setHarvestRewardPool(address _harvestRewardPool)
        external
        override
        onlyOwner
    {
        require(_harvestRewardPool != address(0), "POOL_0x0");
        emit ChangedAddress(
            "POOL",
            address(harvestRewardPool),
            _harvestRewardPool
        );
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
    }

    /**
     * @notice Update the address of Sushiswap Router
     * @dev Can only be called by the owner
     * @param _sushiswapRouter Address of Sushiswap Router
     */
    function setSushiswapRouter(address _sushiswapRouter)
        external
        override
        onlyOwner
    {
        require(_sushiswapRouter != address(0), "0x0");
        emit ChangedAddress(
            "SUSHISWAP_ROUTER",
            address(sushiswapRouter),
            _sushiswapRouter
        );
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
    }

    /**
     * @notice Update the address of Pool's underlying token
     * @dev Can only be called by the owner
     * @param _harvestfToken Address of Pool's underlying token
     */
    function setHarvestPoolToken(address _harvestfToken)
        external
        override
        onlyOwner
    {
        require(_harvestfToken != address(0), "TOKEN_0x0");
        emit ChangedAddress("TOKEN", harvestfToken, _harvestfToken);
        harvestfToken = _harvestfToken;
    }

    /**
     * @notice Update the address of FARM
     * @dev Can only be called by the owner
     * @param _farmToken Address of FARM
     */
    function setFarmToken(address _farmToken) external override onlyOwner {
        require(_farmToken != address(0), "FARM_0x0");
        emit ChangedAddress("FARM", farmToken, _farmToken);
        farmToken = _farmToken;
    }

    /**
     * @notice Update the address for fees
     * @dev Can only be called by the owner
     * @param _feeAddress Fee's address
     */
    function setTreasury(address payable _feeAddress)
        external
        override
        onlyOwner
    {
        require(_feeAddress != address(0), "0x0");
        emit ChangedAddress(
            "TREASURY",
            address(treasuryAddress),
            address(_feeAddress)
        );
        treasuryAddress = _feeAddress;
    }

    /**
     * @notice Blacklist address; blacklisted addresses do not receive receipt tokens
     * @dev Can only be called by the owner
     * @param account User/contract address
     */
    function blacklistAddress(address account) external override onlyOwner {
        require(account != address(0), "0x0");
        emit BlacklistChanged("BLACKLIST", account, blacklisted[account], true);
        blacklisted[account] = true;
    }

    /**
     * @notice Remove address from blacklisted addresses; blacklisted addresses do not receive receipt tokens
     * @dev Can only be called by the owner
     * @param account User/contract address
     */
    function removeFromBlacklist(address account) external override onlyOwner {
        require(account != address(0), "0x0");
        emit BlacklistChanged("REMOVE", account, blacklisted[account], false);
        blacklisted[account] = false;
    }

    /**
     * @notice Set max ETH cap for this strategy
     * @dev Can only be called by the owner
     * @param _cap ETH amount
     */
    function setCap(uint256 _cap) external override onlyOwner {
        emit ChangedValue("CAP", cap, _cap);
        cap = _cap;
    }

    /**
     * @notice Set lock time
     * @dev Can only be called by the owner
     * @param _lockTime lock time in seconds
     */
    function setLockTime(uint256 _lockTime) external override onlyOwner {
        require(_lockTime > 0, "TIME_0");
        emit ChangedValue("LOCKTIME", lockTime, _lockTime);
        lockTime = _lockTime;
    }

    function setFeeAddress(address payable _feeAddress)
        external
        override
        onlyOwner
    {
        emit ChangedAddress("FEE", address(feeAddress), address(_feeAddress));
        feeAddress = _feeAddress;
    }

    function setFee(uint256 _fee) external override onlyOwner {
        require(_fee <= uint256(9000), "FEE_TOO_HIGH");
        emit ChangedValue("FEE", fee, _fee);
    }

    /**
     * @notice Rescue dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueDust() external override onlyOwner {
        if (ethDust > 0) {
            safeTransferETH(treasuryAddress, ethDust);
            treasueryEthDust = treasueryEthDust.add(ethDust);
            emit RescuedDust("ETH", ethDust);
            ethDust = 0;
        }
    }

    /**
     * @notice Rescue any non-reward token that was airdropped to this contract
     * @dev Can only be called by the owner
     */
    function rescueAirdroppedTokens(address _token, address to)
        external
        override
        onlyOwner
    {
        require(_token != address(0), "token_0x0");
        require(to != address(0), "to_0x0");
        require(_token != farmToken, "rescue_reward_error");

        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "balance_0");

        require(IERC20(_token).transfer(to, balanceOfToken), "rescue_failed");
    }

    /// @notice Transfer rewards to this strategy
    function updateReward() external override onlyOwner {
        harvestRewardPool.getReward();
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ View methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Check if user can withdraw based on current lock time
     * @param user Address of the user
     * @return true or false
     */
    function isWithdrawalAvailable(address user) public view returns (bool) {
        if (lockTime > 0) {
            return userInfo[user].timestamp.add(lockTime) <= block.timestamp;
        }
        return true;
    }

    /**
     * @notice View function to see pending rewards for account.
     * @param account user account to check
     * @return pending rewards
     */
    function getPendingRewards(address account) public view returns (uint256) {
        if (account != address(0)) {
            if (userInfo[account].amountfToken == 0) {
                return 0;
            }
            return
                _earned(
                    userInfo[account].amountfToken,
                    userInfo[account].userRewardPerTokenPaid,
                    userInfo[account].rewards
                );
        }
        return 0;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Internal methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function _calculateRewards(
        address account,
        uint256 amount,
        uint256 amountfToken
    ) internal view returns (uint256) {
        uint256 rewards = userInfo[account].rewards;
        uint256 farmBalance = IERC20(farmToken).balanceOf(address(this));

        if (amount == 0) {
            if (rewards < farmBalance) {
                return rewards;
            }
            return farmBalance;
        }

        return (amount.mul(rewards)).div(amountfToken);
    }

    function _updateRewards(address account) internal {
        if (account != address(0)) {
            UserInfo storage user = userInfo[account];

            uint256 _stored = harvestRewardPool.rewardPerToken();

            user.rewards = _earned(
                user.amountfToken,
                user.userRewardPerTokenPaid,
                user.rewards
            );
            user.userRewardPerTokenPaid = _stored;
        }
    }

    function _earned(
        uint256 _amountfToken,
        uint256 _userRewardPerTokenPaid,
        uint256 _rewards
    ) internal view returns (uint256) {
        return
            _amountfToken
                .mul(
                harvestRewardPool.rewardPerToken().sub(_userRewardPerTokenPaid)
            )
                .div(1e18)
                .add(_rewards);
    }

    function _validateWithdraw(
        uint256 deadline,
        uint256 amount,
        uint256 amountfToken,
        uint256 receiptBalance,
        uint256 amountReceiptToken,
        bool wasUserBlacklisted,
        uint256 timestamp,
        uint256 slippage
    ) internal view {
        _validateCommon(deadline, amount, slippage);

        require(amountfToken >= amount, "AMOUNT_GREATER_THAN_BALANCE");

        if (!wasUserBlacklisted) {
            require(receiptBalance >= amountReceiptToken, "RECEIPT_AMOUNT");
        }
        if (lockTime > 0) {
            require(timestamp.add(lockTime) <= block.timestamp, "LOCK_TIME");
        }
    }

    function _depositTokenToHarvestVault(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(token, address(harvestRewardVault), amount);

        uint256 prevfTokenBalance = _getBalance(harvestfToken);
        harvestRewardVault.deposit(amount);
        uint256 currentfTokenBalance = _getBalance(harvestfToken);

        require(
            currentfTokenBalance > prevfTokenBalance,
            "DEPOSIT_VAULT_ERROR"
        );

        return currentfTokenBalance.sub(prevfTokenBalance);
    }

    function _withdrawTokenFromHarvestVault(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(harvestfToken, address(harvestRewardVault), amount);

        uint256 prevTokenBalance = _getBalance(token);
        harvestRewardVault.withdraw(amount);
        uint256 currentTokenBalance = _getBalance(token);

        require(currentTokenBalance > prevTokenBalance, "WITHDRAW_VAULT_ERROR");

        return currentTokenBalance.sub(prevTokenBalance);
    }

    function _stakefTokenToHarvestPool(uint256 amount) internal {
        _increaseAllowance(harvestfToken, address(harvestRewardPool), amount);
        harvestRewardPool.stake(amount);
    }

    function _unstakefTokenFromHarvestPool(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(harvestfToken, address(harvestRewardPool), amount);

        uint256 prevfTokenBalance = _getBalance(harvestfToken);
        harvestRewardPool.withdraw(amount);
        uint256 currentfTokenBalance = _getBalance(harvestfToken);

        require(
            currentfTokenBalance > prevfTokenBalance,
            "WITHDRAW_POOL_ERROR"
        );

        return currentfTokenBalance.sub(prevfTokenBalance);
    }

    function _calculatefTokenRemainings(
        uint256 obtainedfToken,
        uint256 amountfToken,
        bool wasUserBlacklisted,
        uint256 amountReceiptToken
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 burnAmount = 0;
        if (obtainedfToken < amountfToken) {
            amountfToken = amountfToken.sub(obtainedfToken);
            if (!wasUserBlacklisted) {
                amountReceiptToken = amountReceiptToken.sub(obtainedfToken);
                burnAmount = obtainedfToken;
            }
        } else {
            amountfToken = 0;
            if (!wasUserBlacklisted) {
                burnAmount = amountReceiptToken;
                amountReceiptToken = 0;
            }
        }

        return (amountfToken, amountReceiptToken, burnAmount);
    }

    event log(string s);
    event log(uint256 amount);

    function _calculateFeeableTokens(
        uint256 amount,
        uint256 amountfToken,
        uint256 obtainedToken,
        uint256 amountToken,
        uint256 obtainedfToken,
        uint256 underlyingRatio
    ) internal returns (uint256 feeableToken, uint256 earnedTokens) {
        emit log("_calculateFeeableTokens");
        emit log(amount);
        emit log(amountfToken);
        emit log(obtainedToken);
        emit log(amountToken);
        if (amount == amountfToken) {
            //there is no point to do the ratio math as we can just get the difference between current obtained tokens and initial obtained tokens
            if (obtainedToken > amountToken) {
                feeableToken = obtainedToken.sub(amountToken);
            }
        } else {
            uint256 currentRatio = _getRatio(obtainedfToken, obtainedToken, 18);

            if (currentRatio < underlyingRatio) {
                uint256 noOfOriginalTokensForCurrentAmount =
                    (amount.mul(10**18)).div(underlyingRatio);
                if (noOfOriginalTokensForCurrentAmount < obtainedToken) {
                    feeableToken = obtainedToken.sub(
                        noOfOriginalTokensForCurrentAmount
                    );
                }
            }
        }

        emit log("_calculateFeeableTokens end");
        emit log(feeableToken);

        if (feeableToken > 0) {
            uint256 extraTokensFee = _calculateFee(feeableToken);
            emit ExtraTokens(msg.sender, feeableToken.sub(extraTokensFee));
            earnedTokens = feeableToken.sub(extraTokensFee);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
contract HarvestSCBase is StrategyBase, HarvestBase {
    uint256 public totalToken; //total invested eth

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /// @notice Event emitted when rewards are exchanged to ETH or to a specific Token
    event RewardsExchanged(
        address indexed user,
        string exchangeType, //ETH or Token
        uint256 rewardsAmount,
        uint256 obtainedAmount
    );

    /// @notice Event emitted when user makes a deposit
    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken
    );

    /// @notice Event emitted when user withdraws
    event Withdraw(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken,
        uint256 treasuryAmountEth
    );
}

// SPDX-License-Identifier: MIT
/*
  |Strategy Flow| 
      - User shows up with Token and we deposit it in Havest's Vault. 
      - After this we have fToken that we add in Harvest's Reward Pool which gives FARM as rewards

    - Withdrawal flow does same thing, but backwards
        - User can obtain extra Token when withdrawing. 50% of them goes to the user, 50% goes to the treasury in ETH
        - User can obtain FARM tokens when withdrawing. 50% of them goes to the user in Token, 50% goes to the treasury in ETH 
*/
contract HarvestSC is HarvestSCBase, ReentrancyGuard {
    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultDAI  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestfToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    constructor(
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress,
        address payable _feeAddress
    ) public {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        require(_harvestRewardPool != address(0), "POOL_0x0");
        require(_sushiswapRouter != address(0), "ROUTER_0x0");
        require(_harvestfToken != address(0), "fTOKEN_0x0");
        require(_farmToken != address(0), "FARM_0x0");
        require(_token != address(0), "TOKEN_0x0");
        require(_weth != address(0), "WETH_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");

        harvestRewardVault = IHarvestVault(_harvestRewardVault);
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
        harvestfToken = _harvestfToken;
        farmToken = _farmToken;
        token = _token;
        weth = _weth;
        treasuryAddress = _treasuryAddress;
        receiptToken = new ReceiptToken(token, address(this));
        feeAddress = _feeAddress;

        cap = 5000000 * (10 ** 18);
    }

    /**
     * @notice Deposit to this strategy for rewards
     * @param tokenAmount Amount of Token investment
     * @param deadline Number of blocks until transaction expires
     * @return Amount of fToken
     */
    function deposit(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 slippage
    ) public nonReentrant returns (uint256) {
        // -----
        // validate
        // -----
        _validateDeposit(deadline, tokenAmount, totalToken, slippage);

        _updateRewards(msg.sender);

        IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);

        DepositData memory results;
        UserInfo storage user = userInfo[msg.sender];

        if (user.amountfToken == 0) {
            user.wasUserBlacklisted = blacklisted[msg.sender];
        }
        if (user.timestamp == 0) {
            user.timestamp = block.timestamp;
        }

        totalToken = totalToken.add(tokenAmount);
        user.amountToken = user.amountToken.add(tokenAmount);
        results.obtainedToken = tokenAmount;

        // -----
        // deposit Token into harvest and get fToken
        // -----
        results.obtainedfToken = _depositTokenToHarvestVault(
            results.obtainedToken
        );

        // -----
        // stake fToken into the NoMintRewardPool
        // -----
        _stakefTokenToHarvestPool(results.obtainedfToken);
        user.amountfToken = user.amountfToken.add(results.obtainedfToken);

        // -----
        // mint parachain tokens if user is not blacklisted
        // -----
        if (!user.wasUserBlacklisted) {
            user.amountReceiptToken = user.amountReceiptToken.add(
                results.obtainedfToken
            );
            _mintParachainAuctionTokens(results.obtainedfToken);
        }

        emit Deposit(
            msg.sender,
            tx.origin,
            results.obtainedToken,
            results.obtainedfToken
        );


        totalDeposits = totalDeposits.add(results.obtainedfToken);

        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        return results.obtainedfToken;
    }

    /**
     * @notice Withdraw tokens and claim rewards
     * @param deadline Number of blocks until transaction expires
     * @return Amount of ETH obtained
     */
    function withdraw(
        uint256 amount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken,
        uint256 ethPerFarm,
        uint256 tokensPerEth //no of tokens per 1 eth
    ) public nonReentrant returns (uint256) {
        // -----
        // validation
        // -----
        UserInfo storage user = userInfo[msg.sender];
        uint256 receiptBalance = receiptToken.balanceOf(msg.sender);

        _validateWithdraw(
            deadline,
            amount,
            user.amountfToken,
            receiptBalance,
            user.amountReceiptToken,
            user.wasUserBlacklisted,
            user.timestamp,
            slippage
        );

        _updateRewards(msg.sender);

        WithdrawData memory results;
        results.initialAmountfToken = user.amountfToken;
        results.prevDustEthBalance = address(this).balance;

        // -----
        // withdraw from HarvestRewardPool (get fToken back)
        // -----
        results.obtainedfToken = _unstakefTokenFromHarvestPool(amount);

        // -----
        // get rewards
        // -----
        harvestRewardPool.getReward(); //transfers FARM to this contract

        // -----
        // calculate rewards and do the accounting for fTokens
        // -----
        uint256 transferableRewards =
            _calculateRewards(msg.sender, amount, results.initialAmountfToken);

        (
        user.amountfToken,
        user.amountReceiptToken,
        results.burnAmount
        ) = _calculatefTokenRemainings(
            results.obtainedfToken,
            results.initialAmountfToken,
            user.wasUserBlacklisted,
            user.amountReceiptToken
        );
        _burnParachainAuctionTokens(results.burnAmount);

        // -----
        // withdraw from HarvestRewardVault (return fToken and get Token back)
        // -----
        results.obtainedToken = _withdrawTokenFromHarvestVault(
            results.obtainedfToken
        );
        emit ObtainedInfo(
            msg.sender,
            results.obtainedToken,
            results.obtainedfToken
        );
        totalDeposits = totalDeposits.sub(results.obtainedfToken);

        // -----
        // calculate feeable tokens (extra Token obtained by returning fToken)
        //              - feeableToken/2 (goes to the treasury in ETH)
        //              - results.totalToken = obtainedToken + 1/2*feeableToken (goes to the user)
        // -----
        results.auctionedToken = 0;
        (results.feeableToken, results.earnedTokens) = _calculateFeeableTokens(
            amount,
            results.initialAmountfToken,
            results.obtainedToken,
            user.amountToken,
            results.obtainedfToken,
            user.underlyingRatio
        );
        user.earnedTokens = user.earnedTokens.add(results.earnedTokens);
        if (results.obtainedToken <= user.amountToken) {
            user.amountToken = user.amountToken.sub(results.obtainedToken);
        } else {
            user.amountToken = 0;
        }
        results.obtainedToken = results.obtainedToken.sub(results.feeableToken);

        if (results.feeableToken > 0) {
            results.auctionedToken = results.feeableToken.div(2);
            results.feeableToken = results.feeableToken.sub(
                results.auctionedToken
            );
        }
        results.totalToken = results.obtainedToken.add(results.feeableToken);

        // -----
        // swap auctioned Token to ETH
        // -----
        address[] memory swapPath = new address[](2);
        swapPath[0] = token;
        swapPath[1] = weth;

        if (results.auctionedToken > 0) {
            uint256 swapAuctionedTokenResult =
            _swapTokenToEth(
                swapPath,
                results.auctionedToken,
                deadline,
                slippage,
                ethPerToken
            );
            results.auctionedEth.add(swapAuctionedTokenResult);

            emit ExtraTokensExchanged(
                msg.sender,
                results.auctionedToken,
                swapAuctionedTokenResult
            );
        }

        // -----
        // check & swap FARM rewards with ETH (50% for treasury) and with Token by going through ETH first (the other 50% for user)
        // -----

        if (transferableRewards > 0) {
            emit RewardsEarned(msg.sender, transferableRewards);
            user.earnedRewards = user.earnedRewards.add(transferableRewards);

            swapPath[0] = farmToken;

            results.rewardsInEth = _swapTokenToEth(
                swapPath,
                transferableRewards,
                deadline,
                slippage,
                ethPerFarm
            );
            results.auctionedRewardsInEth = results.rewardsInEth.div(2);
            //50% goes to treasury in ETH
            results.userRewardsInEth = results.rewardsInEth.sub(
                results.auctionedRewardsInEth
            );
            //50% goes to user in Token (swapped below)

            results.auctionedEth = results.auctionedEth.add(
                results.auctionedRewardsInEth
            );
            emit RewardsExchanged(
                msg.sender,
                "ETH",
                transferableRewards,
                results.rewardsInEth
            );
        }
        if (results.userRewardsInEth > 0) {
            swapPath[0] = weth;
            swapPath[1] = token;

            uint256 userRewardsEthToTokenResult =
            _swapEthToToken(
                swapPath,
                results.userRewardsInEth,
                deadline,
                slippage,
                tokensPerEth
            );
            results.totalToken = results.totalToken.add(
                userRewardsEthToTokenResult
            );

            emit RewardsExchanged(
                msg.sender,
                "Token",
                transferableRewards.div(2),
                userRewardsEthToTokenResult
            );
        }
        user.rewards = user.rewards.sub(transferableRewards);

        // -----
        // final accounting
        // -----
        if (results.totalToken < totalToken) {
            totalToken = totalToken.sub(results.totalToken);
        } else {
            totalToken = 0;
        }

        if (user.amountfToken == 0) {
            user.amountToken = 0; //1e-18 dust
        }
        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        // -----
        // transfer Token to user, ETH to fee address and ETH to the treasury address
        // -----
        if (fee > 0) {
            uint256 feeToken = _calculateFee(results.totalToken);
            results.totalToken = results.totalToken.sub(feeToken);

            swapPath[0] = token;
            swapPath[1] = weth;

            uint256 feeTokenInEth =
            _swapTokenToEth(
                swapPath,
                feeToken,
                deadline,
                slippage,
                ethPerToken
            );

            safeTransferETH(feeAddress, feeTokenInEth);
            user.userCollectedFees = user.userCollectedFees.add(feeTokenInEth);
        }

        IERC20(token).safeTransfer(msg.sender, results.totalToken);

        safeTransferETH(treasuryAddress, results.auctionedEth);
        user.userTreasuryEth = user.userTreasuryEth.add(results.auctionedEth);

        emit Withdraw(
            msg.sender,
            tx.origin,
            results.obtainedToken,
            results.obtainedfToken,
            results.auctionedEth
        );

        // -----
        // dust check
        // -----
        if (address(this).balance > results.prevDustEthBalance) {
            ethDust = ethDust.add(
                address(this).balance.sub(results.prevDustEthBalance)
            );
        }

        return results.totalToken;
    }
}