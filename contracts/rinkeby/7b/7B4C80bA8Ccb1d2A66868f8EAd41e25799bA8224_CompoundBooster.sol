/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/compound/CompoundInterfaces.sol


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface ICompound is IERC20 {
    function borrow(uint256 borrowAmount) external returns (uint256);
    // function interestRateModel() external returns (InterestRateModel);
    // function comptroller() external view returns (ComptrollerInterface);
    // function balanceOf(address owner) external view returns (uint256);
    function isCToken(address) external view returns(bool);
    function comptroller() external view returns (ICompoundComptroller);
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external override view returns (uint256);
    function getAccountSnapshot(address account) external view returns ( uint256, uint256, uint256, uint256 );
    function accrualBlockNumber() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function borrowBalanceStored(address user) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function decimals() external view returns (uint256);
}

interface ICompoundCEther is ICompound {
    function repayBorrow() external payable;
    function mint() external payable;
}

interface ICompoundCErc20 is ICompound {
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function underlying() external returns(address); // like usdc usdt
}

interface ICompRewardPool {
    function stakeFor(address _for, uint256 amount) external;
    function withdrawFor(address _for, uint256 amount) external;
    function queueNewRewards(uint256 _rewards) external;
    function rewardToken() external returns(address);
    function rewardConvexToken() external returns(address);

    function getReward(address _account, bool _claimExtras) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256);
}

interface ICompRewardFactory {
    function CreateRewards(address _operator) external returns (address);
}

interface ICompoundTreasuryFund {
    function withdrawTo( address _asset, uint256 _amount, address _to ) external;
    // function borrowTo( address _asset, address _underlyAsset, uint256 _borrowAmount, address _to, bool _isErc20 ) external returns (uint256);
    // function repayBorrow( address _asset, bool _isErc20, uint256 _amount ) external payable;
    function claimComp(address _comp,address _comptroller,address _to) external returns(uint256);
}

interface ICompoundTreasuryFundFactory {
    function CreateTreasuryFund(address _operator) external returns (address);
}

interface ICompoundComptroller {
    /*** Assets You Are In ***/
    // 开启抵押
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    // 关闭抵押
    function exitMarket(address cToken) external returns (uint256);
    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);

    function claimComp(address holder) external;
    function claimComp(address holder, address[] memory cTokens) external;
    function getCompAddress() external view returns (address);
    function getAllMarkets() external view returns (address[] memory);
    function accountAssets(address user) external view returns (address[] memory);
}

interface ICompoundProxyUserTemplate {
    function init( address _op, address user, address _rewardComp ) external;
    function borrow( address _asset, address payable _for, uint256 _amount ) external;
    function borrowErc20( address _asset, address _token, address _for, uint256 _amount ) external;
    function repayBorrowBySelf(address _asset, bool _isErc20) external;
    function repayBorrow(address _asset, address payable _for) external payable;
    function repayBorrowErc20( address _asset, address _token, address _for, uint256 _amount ) external;
    function op() external view returns (address);
    function asset() external view returns (address);
    function user() external view returns (address);
    function recycle(address _asset) external returns (uint256);
}

// File: @openzeppelin/contracts/math/Math.sol



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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



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

// File: contracts/compound/CompoundRewardPool.sol


pragma solidity 0.6.12;






// contract VirtualBalanceWrapper {
//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;

//     IDeposit public deposits;

//     function totalSupply() public view returns (uint256) {
//         return deposits.totalSupply();
//     }

//     function balanceOf(address account) public view returns (uint256) {
//         return deposits.balanceOf(account);
//     }
// }

contract CompoundRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public constant duration = 7 days;

    address public operator;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public newRewardRatio = 830;
    uint256 private _totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _reward, address _op) public {
        rewardToken = IERC20(_reward);
        operator = _op;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _for) public view returns (uint256) {
        return _balances[_for];
    }

    modifier updateReward(address _for) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_for != address(0)) {
            rewards[_for] = earned(_for);
            userRewardPerTokenPaid[_for] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _for) public view returns (uint256) {
        /* return
            balanceOf(_for)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_for]))
                .div(1e18)
                .add(rewards[_for]); */
        return balanceOf(_for).mul(1 days).div(1e18).add(rewards[_for]);
    }

    function stakeFor(address _for, uint256 _amount) public updateReward(_for) {
        require(msg.sender == operator, "!authorized");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_for] = _balances[_for].add(_amount);

        emit Staked(_for, _amount);
    }

    function withdrawFor(address _for, uint256 _amount)
        public
        updateReward(_for)
    {
        require(msg.sender == operator, "!authorized");

        _totalSupply = _totalSupply.sub(_amount);
        _balances[_for] = _balances[_for].sub(_amount);

        emit Withdrawn(_for, _amount);
    }

    function getReward(address _for) public updateReward(_for) {
        uint256 reward = earned(_for);
        if (reward > 0) {
            rewards[_for] = 0;
            rewardToken.safeTransfer(_for, reward);

            emit RewardPaid(_for, reward);
        }
    }

    function getReward() external {
        getReward(msg.sender);
    }

    function donate(uint256 _amount) external returns (bool) {
        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        queuedRewards = queuedRewards.add(_amount);
    }

    function queueNewRewards(uint256 _rewards) external {
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(_reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);

            _reward = _reward.add(leftover);
            rewardRate = _reward.div(duration);
        }

        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(_reward);
    }
}

// File: contracts/compound/CompoundInterestRewardPool.sol


pragma solidity 0.6.12;






contract CompoundInterestRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public constant duration = 7 days;

    address public operator;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public newRewardRatio = 830;
    uint256 private _totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _reward, address _op) public {
        rewardToken = IERC20(_reward);
        operator = _op;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _for) public view returns (uint256) {
        return _balances[_for];
    }

    modifier updateReward(address _for) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_for != address(0)) {
            rewards[_for] = earned(_for);
            userRewardPerTokenPaid[_for] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _for) public view returns (uint256) {
        /* return
            balanceOf(_for)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_for]))
                .div(1e18)
                .add(rewards[_for]); */
        return balanceOf(_for).mul(1 days).div(1e18).add(rewards[_for]);
    }

    function stakeFor(address _for, uint256 _amount) public updateReward(_for) {
        require(msg.sender == operator, "!authorized");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_for] = _balances[_for].add(_amount);

        emit Staked(_for, _amount);
    }

    function withdrawFor(address _for, uint256 _amount)
        public
        updateReward(_for)
    {
        require(msg.sender == operator, "!authorized");

        _totalSupply = _totalSupply.sub(_amount);
        _balances[_for] = _balances[_for].sub(_amount);

        emit Withdrawn(_for, _amount);
    }

    function getReward(address _for) public updateReward(_for) {
        uint256 reward = earned(_for);
        if (reward > 0) {
            rewards[_for] = 0;
            rewardToken.safeTransfer(_for, reward);

            emit RewardPaid(_for, reward);
        }
    }

    function getReward() external {
        getReward(msg.sender);
    }

    function donate(uint256 _amount) external returns (bool) {
        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        queuedRewards = queuedRewards.add(_amount);
    }

    function queueNewRewards(uint256 _rewards) external {
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(_reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);

            _reward = _reward.add(leftover);
            rewardRate = _reward.div(duration);
        }

        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(_reward);
    }
}

// File: contracts/compound/CompoundTreasuryFund.sol


pragma solidity 0.6.12;




contract CompoundTreasuryFund {
    using SafeERC20 for IERC20;
    using Address for address;

    address public operator;
    event WithdrawTo(address indexed user, uint256 amount);

    constructor(address _op) public {
        operator = _op;
    }

    function withdrawTo(
        address _asset,
        uint256 _amount,
        address _to
    ) external {
        require(msg.sender == operator, "!authorized");

        IERC20(_asset).safeTransfer(_to, _amount);

        emit WithdrawTo(_to, _amount);
    }

    // function borrowTo(
    //     address _asset,
    //     address _underlyAsset,
    //     uint256 _borrowAmount,
    //     address payable _to,
    //     bool _isErc20
    // ) external returns (uint256) {
    //     uint256 amount = ICompound(_asset).borrow(_borrowAmount);

    //     if (_isErc20) {
    //         IERC20(_underlyAsset).safeTransfer(_to, amount);
    //     } else {
    //         _to.transfer(amount);
    //     }

    //     return amount;
    // }

    // function repayBorrow(
    //     address _asset,
    //     bool _isErc20,
    //     uint256 _amount
    // ) external payable {
    //     if (_isErc20) {
    //         ICompoundCErc20(_asset).repayBorrow(_amount);
    //     } else {
    //         ICompoundCEther(_asset).repayBorrow{value: msg.value}();
    //     }
    // }

    // function redeem(
    //     address _asset,
    //     bool _isErc20,
    //     uint256 _redeemTokens,
    //     address _to
    // ) external returns (uint256) {
    //     ICompound(_asset).redeem(uint256(_redeemTokens));

    //     if (_isErc20) {
    //         address underlyToken = ICompoundCErc20(_asset).underlying();

    //         uint256 redeemTokens = IERC20(underlyToken).balanceOf(
    //             address(this)
    //         );

    //         require(redeemTokens > 0, "redeemTokens = 0");

    //         IERC20(underlyToken).safeTransfer(_to, redeemTokens);
    //     } else {
    //         uint256 redeemTokens = address(this).balance;

    //         payable(_to).transfer(redeemTokens);
    //     }
    // }

    function claimComp(
        address _comp,
        address _comptroller,
        address _to
    ) external returns (uint256) {
        ICompoundComptroller(_comptroller).claimComp(address(this));

        uint256 balanceOfComp = IERC20(_comp).balanceOf(address(this));

        if (balanceOfComp > 0) {
            IERC20(_comp).safeTransfer(_to, balanceOfComp);
        }

        return balanceOfComp;
    }
}

// File: contracts/compound/CompoundProxyUserTemplate.sol


pragma solidity 0.6.12;



contract CompoundProxyUserTemplate {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public op;
    address public compReward;
    address public user;
    bool private inited;

    event Receive(uint256 amount);
    event Borrow(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 returnBorrow,
        uint256 timeAt
    );
    event RepayBorrow(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );
    event RepayBorrowErc20(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );
    event Recycle(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );

    modifier onlyInited() {
        require(inited, "!inited");
        _;
    }

    function init(
        address _op,
        address _user,
        address _compReward
    ) public {
        require(!inited, "inited");

        op = _op;
        user = _user;
        compReward = _compReward;
        inited = true;
    }

    function borrow(
        address _asset,
        address payable _for,
        uint256 _amount
    ) public onlyInited {
        require(op == msg.sender, "!op");

        uint256 borrowLimit = _amount.mul(80).div(100);

        uint256 returnBorrow = ICompoundCEther(_asset).borrow(borrowLimit);

        emit Borrow(_asset, _for, borrowLimit, returnBorrow, block.timestamp);

        _for.transfer(borrowLimit);
    }

    function borrowErc20(
        address _asset,
        address _token,
        address _for,
        uint256 _amount
    ) public onlyInited {
        require(op == msg.sender, "!op");

        this.autoEnterMarkets(_asset);
        this.autoClaimComp(_asset);

        uint256 borrowLimit = _amount.mul(80).div(100);

        uint256 borrowState = ICompoundCErc20(_asset).borrow(borrowLimit);

        // 0 on success, otherwise an Error code

        emit Borrow(_asset, _for, borrowLimit, borrowState, block.timestamp);

        uint256 bal = IERC20(_token).balanceOf(address(this));
        IERC20(address(_token)).safeTransfer(_for, bal);
    }

    function repayBorrowBySelf(address _asset, bool _isErc20)
        public
        onlyInited
    {
        require(op == msg.sender, "!op");

        this.autoClaimComp(_asset);

        uint256 borrows = this.borrowBalanceStored(_asset);

        if (_isErc20) {
            ICompoundCErc20(_asset).repayBorrow(borrows);
        } else {
            ICompoundCEther(_asset).repayBorrow{value: borrows}();
        }
    }

    function repayBorrow(address _asset, address payable _for)
        public
        payable
        onlyInited
    {
        require(op == msg.sender, "!op");

        this.autoClaimComp(_asset);

        uint256 received = msg.value;
        uint256 borrows = this.borrowBalanceStored(_asset);

        if (received > borrows) {
            ICompoundCEther(_asset).repayBorrow{value: borrows}();
            _for.transfer(received - borrows);
        } else {
            ICompoundCEther(_asset).repayBorrow{value: received}();
        }

        emit RepayBorrow(_asset, _for, msg.value, block.timestamp);
    }

    function repayBorrowErc20(
        address _asset,
        address _token,
        address _for,
        uint256 _amount
    ) public onlyInited {
        require(op == msg.sender, "!op");

        uint256 received = _amount;
        uint256 borrows = borrowBalanceStored(_asset);
        if (received > borrows) {
            ICompoundCErc20(_asset).repayBorrow(borrows);
            IERC20(_token).safeTransfer(_for, received - borrows);
        } else {
            ICompoundCErc20(_asset).repayBorrow(received);
        }

        emit RepayBorrowErc20(
            _asset,
            _for,
            received - borrows,
            block.timestamp
        );
    }

    function recycle(address _asset) external returns (uint256) {
        uint256 borrows = borrowBalanceStored(_asset);

        if (borrows == 0) {
            uint256 bal = IERC20(_asset).balanceOf(address(this));
            IERC20(_asset).safeTransfer(op, bal);

            emit Recycle(_asset, user, bal, block.timestamp);

            return bal;
        }

        return 0;
    }

    function autoEnterMarkets(address _asset) public {
        ICompoundComptroller comptroller = ICompound(_asset).comptroller();

        if (!comptroller.checkMembership(user, _asset)) {
            address[] memory cTokens = new address[](1);

            cTokens[0] = _asset;

            comptroller.enterMarkets(cTokens);
        }
    }

    function autoClaimComp(address _asset) public {
        ICompoundComptroller comptroller = ICompound(_asset).comptroller();

        comptroller.claimComp(user);

        address comp = comptroller.getCompAddress();
        uint256 bal = IERC20(comp).balanceOf(address(this));

        IERC20(comp).safeTransfer(compReward, bal);
    }

    receive() external payable {
        emit Receive(msg.value);
    }

    /* views */
    function borrowBalanceStored(address _asset) public view returns (uint256) {
        return ICompound(_asset).borrowBalanceStored(user);
    }

    function getAccountSnapshot(address _asset)
        external
        view
        returns (
            uint256 compoundError,
            uint256 cTokenBalance,
            uint256 borrowBalance,
            uint256 exchangeRateMantissa
        )
    {
        (
            compoundError,
            cTokenBalance,
            borrowBalance,
            exchangeRateMantissa
        ) = ICompound(_asset).getAccountSnapshot(user);
    }

    function getAccountCurrentBalance(address _asset)
        public
        view
        returns (uint256)
    {
        uint256 blocks = block.number.sub(
            ICompound(_asset).accrualBlockNumber()
        );
        uint256 rate = ICompound(_asset).borrowRatePerBlock();
        uint256 borrowBalance = ICompound(_asset).borrowBalanceStored(user);

        return borrowBalance.add(blocks.mul(rate).mul(1e18));
    }

    /* 
        1e18*1e18/297200311178743141766115305/1e8 = 33.64734027477437
        33.64734027477437*1e18*297200311178743141766115305/1e36 = 10000000000
     */
    function getTokenToCToken(address _asset, uint256 _token)
        public
        view
        returns (uint256)
    {
        uint256 exchangeRate = ICompound(_asset).exchangeRateStored();
        uint256 tokens = _token.mul(1e18).mul(exchangeRate).div(
            ICompound(_asset).decimals()
        );

        return tokens;
    }

    function getCTokenToToken(address _asset, uint256 _cToken)
        public
        view
        returns (uint256)
    {
        uint256 exchangeRate = ICompound(_asset).exchangeRateStored();
        uint256 tokens = _cToken
            .mul(ICompound(_asset).decimals())
            .mul(exchangeRate)
            .mul(1e18);

        return tokens;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: @openzeppelin/contracts/proxy/Clones.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// File: contracts/CompoundBooster.sol


pragma solidity 0.6.12;











contract CompoundBooster is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // address public compoundRewardFactory;
    // address public compoundTreasuryFundFactory;
    address public compoundComptroller;
    address public compoundProxyUserTemplate;
    address public rewardComp;
    address public lendflareToken;
    address public lendflareDepositer;
    address public Lending;

    struct PoolInfo {
        address lpToken;
        address rewardPool;
        address rewardLendflareTokenPool;
        address treasuryFund;
        address rewardInterestPool;
        bool isErc20;
        bool shutdown;
    }

    struct Freeze {
        uint256 amount;
    }

    PoolInfo[] public poolInfo;

    // mapping(address => Freeze) public freezes;
    mapping(uint256 => uint256) public poolFreezes;
    mapping(address => address) public proxyUsers;

    event Minted(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    modifier onlyLending() {
        _;
    }

    constructor(
        // address _compoundRewardFactory,
        address _rewardComp, // 0x0000000000000000000000000000000000000000
        address _lendflareToken, // 0x0000000000000000000000000000000000000000
        address _lendflareDepositer // address _compoundTreasuryFundFactory
    ) public {
        // compoundRewardFactory = _compoundRewardFactory;
        rewardComp = _rewardComp;
        lendflareToken = _lendflareToken;
        lendflareDepositer = _lendflareDepositer;
        // compoundTreasuryFundFactory = _compoundTreasuryFundFactory;

        compoundProxyUserTemplate = address(new CompoundProxyUserTemplate());
    }

    function Demo() public {
        this.addPool(0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e, false); //  cEther
        this.addPool(0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1, true); //  cUsdc
        
        this.setComptroller(0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb);
    }

    function addPool(address _lpToken, bool _isErc20)
        external
        onlyOwner
        returns (bool)
    {
        // comp
        // address rewardPool = ICompRewardFactory(compoundRewardFactory)
        //     .CreateRewards(address(this));
        address rewardPool = address(
            new CompoundRewardPool(rewardComp, address(this))
        );
        address rewardLendflareTokenPool = address(
            new CompoundRewardPool(lendflareToken, address(this))
        );
        // 交易手续费
        address interestRewardPool = address(
            new CompoundInterestRewardPool(_lpToken, address(this))
        );
        // aToken
        // address treasuryFund = ICompoundTreasuryFundFactory(
        //     compoundTreasuryFundFactory
        // ).CreateTreasuryFund(address(this));
        // CompoundTreasuryFund treasuryFundPool = new CompoundTreasuryFund(_operator);
        address treasuryFundPool = address(
            new CompoundTreasuryFund(address(this))
        );

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardPool: rewardPool,
                rewardLendflareTokenPool: rewardLendflareTokenPool,
                treasuryFund: treasuryFundPool,
                rewardInterestPool: interestRewardPool,
                isErc20: _isErc20,
                shutdown: false
            })
        );

        return true;
    }

    function _mintEther(address lpToken, uint256 _amount) internal {
        ICompoundCEther(lpToken).mint{value: _amount}();
    }

    function _mintErc20(address lpToken, uint256 _amount) internal {
        ICompoundCErc20(lpToken).mint(_amount);
    }

    /**
        @param _amount 质押金额,将转入treasuryFunds
        @param _isCToken 是否参与转化为cToken,如果开启，_amount 将为 erc20的转化金额
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _isCToken
    ) public payable returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        if (!_isCToken) {
            if (!pool.isErc20) {
                require(msg.value > 0 && _amount == 0);

                _mintEther(pool.lpToken, msg.value);
            } else {
                require(_amount > 0);

                address underlyToken = ICompoundCErc20(pool.lpToken)
                    .underlying();

                IERC20(underlyToken).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    _amount
                );

                IERC20(underlyToken).safeApprove(pool.lpToken, 0);
                IERC20(underlyToken).safeApprove(pool.lpToken, _amount);

                _mintErc20(pool.lpToken, _amount);
            }
        } else {
            IERC20(pool.lpToken).safeTransferFrom(
                _msgSender(),
                address(this),
                _amount
            );
        }

        uint256 mintToken = IERC20(pool.lpToken).balanceOf(address(this));

        require(mintToken > 0, "mintToken = 0");

        IERC20(pool.lpToken).safeTransfer(pool.treasuryFund, mintToken);
        ICompRewardPool(pool.rewardPool).stakeFor(_msgSender(), mintToken);
        ICompRewardPool(pool.rewardLendflareTokenPool).stakeFor(
            _msgSender(),
            mintToken
        );
        ICompRewardPool(pool.rewardInterestPool).stakeFor(
            _msgSender(),
            mintToken
        );

        emit Deposited(_msgSender(), _pid, mintToken);

        return true;
    }

    function withdraw(uint256 _pid, uint256 _amount) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 depositAmount = ICompRewardPool(pool.rewardPool).balanceOf(
            _msgSender()
        );

        require(
            IERC20(pool.lpToken).balanceOf(pool.treasuryFund).sub(
                poolFreezes[_pid]
            ) >= _amount,
            "Insufficient balance"
        );
        require(_amount <= depositAmount, "!depositAmount");

        ICompoundTreasuryFund(pool.treasuryFund).withdrawTo(
            pool.lpToken,
            _amount,
            _msgSender()
        );

        ICompRewardPool(pool.rewardPool).withdrawFor(_msgSender(), _amount);
        ICompRewardPool(pool.rewardLendflareTokenPool).withdrawFor(
            _msgSender(),
            _amount
        );
        ICompRewardPool(pool.rewardInterestPool).withdrawFor(
            _msgSender(),
            _amount
        );

        return true;
    }

    // function borrow(uint256 _pid, uint256 _borrowAmount)
    //     public
    //     onlyLending
    //     returns (uint256)
    // {
    //     PoolInfo storage pool = poolInfo[_pid];

    //     address underlyToken = ICompoundCErc20(pool.lpToken).underlying();
    //     uint256 amount = ICompoundTreasuryFund(pool.treasuryFund).borrowTo(
    //         pool.lpToken,
    //         underlyToken,
    //         _borrowAmount,
    //         msg.sender,
    //         pool.isErc20
    //     );

    //     return amount;
    // }

    // function repayBorrow(uint256 _pid, uint256 _amount)
    //     public
    //     payable
    //     onlyLending
    // {
    //     PoolInfo storage pool = poolInfo[_pid];

    //     ICompoundTreasuryFund(pool.treasuryFund).repayBorrow{value: msg.value}(
    //         pool.lpToken,
    //         pool.isErc20,
    //         _amount
    //     );
    // }

    function earmarkRewards() external returns (bool) {
        address compAddress = ICompoundComptroller(compoundComptroller)
            .getCompAddress();
        uint256 balanceOfComp;

        for (uint256 i = 0; i < this.poolLength(); i++) {
            if (poolInfo[i].shutdown) {
                continue;
            }

            balanceOfComp = balanceOfComp.add(
                ICompoundTreasuryFund(poolInfo[i].treasuryFund).claimComp(
                    compAddress,
                    compoundComptroller,
                    poolInfo[i].rewardPool
                )
            );
        }

        return true;
    }

    function setComptroller(address _v) public onlyOwner {
        compoundComptroller = _v;
    }

    receive() external payable {}

    /* lending interfaces */
    function cloneUserTemplate(address _sender) internal {
        if (proxyUsers[_sender] == address(0)) {
            address payable template = payable(
                Clones.clone(compoundProxyUserTemplate)
            );

            ICompoundProxyUserTemplate(template).init(
                address(this),
                _sender,
                rewardComp
            );

            proxyUsers[_sender] = template;
        }
    }

    function lockToken(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) public {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 bal = IERC20(pool.lpToken).balanceOf(pool.treasuryFund);

        require(bal >= _amount, "Insufficient balance");

        // Freeze storage freeze = freezes[_user];

        // freeze.amount = freeze.amount.add(_amount);

        poolFreezes[_pid] = poolFreezes[_pid].add(_amount);

        cloneUserTemplate(_user);

        address myProxyUser = proxyUsers[_user];

        ICompoundTreasuryFund(pool.treasuryFund).withdrawTo(
            pool.lpToken,
            _amount,
            myProxyUser
        );

        if (pool.isErc20) {
            address underlyingToken = ICompoundCErc20(pool.lpToken)
                .underlying();

            ICompoundProxyUserTemplate(myProxyUser).borrowErc20(
                pool.lpToken,
                underlyingToken,
                _user,
                _amount
            );
        } else {
            ICompoundProxyUserTemplate(myProxyUser).borrow(
                pool.lpToken,
                payable(_user),
                _amount
            );
        }
    }

    function unLockToken(
        uint256 _pid,
        address _user,
        uint256 _amount,
        uint256 _interestValue
    ) external payable {
        PoolInfo memory pool = poolInfo[_pid];

        address myProxyUser = proxyUsers[_user];

        // Freeze storage freeze = freezes[_user];

        // freeze.amount = freeze.amount.sub(_amount);

        poolFreezes[_pid] = poolFreezes[_pid].sub(_amount);

        ICompoundProxyUserTemplate(myProxyUser).repayBorrow{
            value: msg.value.sub(_interestValue)
        }(pool.lpToken, msg.sender);
        ICompoundProxyUserTemplate(myProxyUser).recycle(pool.lpToken);

        if (_interestValue > 0) {
            uint256 exchangeReward = _interestValue.mul(50).div(100);
            uint256 lendflareDeposterReward = _interestValue.mul(50).div(100);

            IERC20(pool.rewardInterestPool).transfer(
                address(this),
                exchangeReward
            );
            IERC20(lendflareDepositer).transfer(
                address(this),
                lendflareDeposterReward
            );
        }
    }

    function unLockTokenErc20(
        uint256 _pid,
        address _user,
        uint256 _unlockAmount,
        uint256 _repayAmount,
        uint256 _interestValue
    ) external {
        PoolInfo memory pool = poolInfo[_pid];

        address myProxyUser = proxyUsers[_user];

        // Freeze storage freeze = freezes[_user];

        // freeze.amount = freeze.amount.sub(_unlockAmount);

        poolFreezes[_pid] = poolFreezes[_pid].sub(_unlockAmount);

        address underlyingToken = ICompoundCErc20(pool.lpToken).underlying();
        IERC20(underlyingToken).safeTransfer(
            myProxyUser,
            _repayAmount.sub(_interestValue)
        );

        ICompoundProxyUserTemplate(myProxyUser).repayBorrowErc20(
            pool.lpToken,
            underlyingToken,
            _user,
            _repayAmount.sub(_interestValue)
        );
        ICompoundProxyUserTemplate(myProxyUser).recycle(pool.lpToken);

        if (_interestValue > 0) {
            uint256 exchangeReward = _interestValue.mul(50).div(100);
            uint256 lendflareDeposterReward = _interestValue.mul(50).div(100);

            IERC20(pool.rewardInterestPool).transfer(
                address(this),
                exchangeReward
            );
            IERC20(lendflareDepositer).transfer(
                address(this),
                lendflareDeposterReward
            );
        }
    }

    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external returns (address) {
        PoolInfo memory pool = poolInfo[_pid];
        address myProxyUser = proxyUsers[_user];

        // Freeze storage freeze = freezes[_user];

        // freeze.amount = freeze.amount.sub(_amount);

        poolFreezes[_pid] = poolFreezes[_pid].sub(_amount);

        ICompoundProxyUserTemplate(myProxyUser).repayBorrowBySelf(
            pool.lpToken,
            pool.isErc20
        );
        ICompoundProxyUserTemplate(myProxyUser).recycle(pool.lpToken);

        // 拍卖的钱由lending专递给myProxyUser,所以直接从主账户里转ctoken去还款
    }

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getRewardInterestPool(uint256 _pid) public view returns (address) {
        PoolInfo memory pool = poolInfo[_pid];

        return pool.rewardInterestPool;
    }

    function totalSupplyOf(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        return IERC20(pool.lpToken).balanceOf(pool.treasuryFund);
    }
}