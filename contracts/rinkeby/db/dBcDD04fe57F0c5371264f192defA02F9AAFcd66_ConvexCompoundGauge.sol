/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

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

// File: contracts/ConvexCompoundGauge.sol



pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;



interface IConvexBooster {
    function liquidate(
        uint256 _pid,
        int128 _coinId,
        address _user,
        uint256 _amount
    ) external returns (address, uint256);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function withdrawFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            uint256 convexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardCrvPool
        );
}

interface ICompoundBooster {
    function liquidate(bytes16 _lendingId) external returns (address);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            address rewardPool,
            address rewardLendflareTokenPool,
            address treasuryFund,
            address rewardInterestPool,
            bool isErc20,
            bool shutdown
        );

    function lendingInfos(bytes16 _lendingId)
        external
        view
        returns (
            uint256 pid,
            address proxyUser,
            uint256 cTokens,
            address underlyToken,
            uint256 amount,
            uint256 borrowNumbers,
            uint256 startedBlock,
            uint256 state
        );

    function borrow(
        uint256 _pid,
        bytes16 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _collateralAmount,
        uint256 _borrowNumbers
    ) external;

    function repayBorrow(
        bytes16 _lendingId,
        address _user,
        uint256 _interestValue
    ) external payable;

    function repayBorrowErc20(
        bytes16 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _interestValue
    ) external;

    function getBorrowRatePerBlock(uint256 _pid)
        external
        view
        returns (uint256);

    function getExchangeRateStored(uint256 _pid)
        external
        view
        returns (uint256);

    function getBlocksPerYears(uint256 _pid, bool isSplit)
        external
        view
        returns (uint256);

    function getUtilizationRate(uint256 _pid) external view returns (uint256);

    function getCollateralFactorMantissa(uint256 _pid)
        external
        view
        returns (uint256);
}

interface ICurveSwap {
    function get_virtual_price() external view returns (uint256);

    // lp to token 68900637075889600000000, 2
    function calc_withdraw_one_coin(uint256 tokenAmount, int128 tokenId)
        external
        view
        returns (uint256);

    // token to lp params: [0,0,70173920000], false
    function calc_token_amount(uint256[] memory amounts, bool deposit)
        external
        view
        returns (uint256);
}

interface ILiquidateSponsor {
    function addSponsor(bytes16 _lendingId, address _user) external payable;

    function requestSponsor(bytes16 _lendingId) external;

    function payFee(
        bytes16 _lendingId,
        address _user,
        uint256 _expendGas
    ) external;
}

contract ConvexCompoundGauge {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable convexBooster;
    address public immutable compoundBooster;
    address payable public immutable liquidateSponsor;

    uint256 public liquidateThresholdBlockNumbers;

    enum UserLendingState {
        LENDING,
        EXPIRED,
        LIQUIDATED
    }

    struct PoolInfo {
        uint256 convexPid;
        uint256[] supportPids; // compound pool id
        int128[] curveCoinIds; // 跟supportPids对应,curve清算要卖出去的coin id
        uint256 lendingThreshold; // 借款阀值 10%
        uint256 liquidateThreshold; // 5% 清算
        uint256 borrowIndex;
    }

    struct UserLending {
        bytes16 lendingId;
        uint256 token0Value;
        uint256 token0Price;
        uint256 lendingAmount;
        uint256 supportPid;
        int128 curveCoinId;
        uint256 interestValue; // 利息
        uint256 borrowNumbers; // 借款周期
        uint256 borrowBlocksLimit; // 借款周期
    }

    struct LendingInfo {
        address user;
        uint256 pid;
        uint256 userLendingId;
        uint256 borrowIndex;
        uint256 startedBlock; // 创建借贷的区块
        uint256 utilizationRate;
        uint256 compoundRatePerBlock;
        UserLendingState state;
    }

    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 supplyAmount;
    }

    struct Statistic {
        uint256 totalCollateral;
        uint256 totalBorrow;
        uint256 recentRepayAt;
    }

    struct LendingParams {
        uint256 lendingAmount;
        uint256 collateralAmount;
        uint256 interestAmount;
        uint256 borrowRate;
        uint256 utilizationRate;
        uint256 compoundRatePerBlock;
        address lpToken;
        uint256 token0Price;
    }

    PoolInfo[] public poolInfo;

    mapping(address => UserLending[]) public userLendings; // user address => container
    mapping(bytes16 => LendingInfo) public lendings; // lending id => user address
    mapping(uint256 => mapping(uint256 => bytes16)) public poolLending; // pool id => (borrowIndex => user lendingId)
    mapping(uint256 => BorrowInfo) public borrowInfos;
    mapping(address => Statistic) public myStatistics;
    mapping(uint256 => uint256) public borrowNumberLimit; // number => block numbers

    event Borrow(
        bytes16 indexed lendingId,
        address user,
        uint256 token0,
        uint256 token0Price,
        uint256 lendingAmount,
        uint256 borrowBlocksLimit,
        UserLendingState state
    );

    event RepayBorrow(
        bytes16 indexed lendingId,
        address user,
        UserLendingState state
    );

    event Liquidate(
        bytes16 indexed lendingId,
        address user,
        uint256 liquidateAmount,
        uint256 gasSpent,
        UserLendingState state
    );

    // address[] public transformer;

    /* function transformersLength() external view returns (uint256) {
        return transformer.length;
    }

    function addTransformer(address _transformer) external returns (bool) {
        require(_transformer != address(0), "!transformer setting");

        transformer.push(_transformer);

        return true;
    }

    function clearTransformers() external {
        delete transformer;
    } */

    constructor(
        address payable _liquidateSponsor,
        address _convexBooster,
        address _compoundBooster
    ) public {
        liquidateSponsor = _liquidateSponsor;
        convexBooster = _convexBooster;
        compoundBooster = _compoundBooster;

        // dev number
        borrowNumberLimit[8] = 256;
        borrowNumberLimit[19] = 524288;
        borrowNumberLimit[20] = 1048576;
        borrowNumberLimit[21] = 2097152;

        liquidateThresholdBlockNumbers = 50;
    }

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowNumber,
        uint256 _supportPid
    ) public payable {
        require(borrowNumberLimit[_borrowNumber] != 0, "!borrowNumberLimit");
        // 转账给liquidateSponsor
        require(msg.value == 0.1 ether, "!liquidateSponsor");

        LendingParams memory lendingParams = _borrow(
            _pid,
            _supportPid,
            _borrowNumber,
            _token0
        );

        BorrowInfo storage borrowInfo = borrowInfos[_pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.add(
            lendingParams.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.add(
            lendingParams.lendingAmount
        );

        Statistic storage statistic = myStatistics[msg.sender];

        statistic.totalCollateral = statistic.totalCollateral.add(_token0);
        statistic.totalBorrow = statistic.totalBorrow.add(
            lendingParams.lendingAmount
        );
    }

    function _getCurveInfo(
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _token0
    ) internal view returns (address lpToken, uint256 token0Price) {
        // (, address curveSwapAddress, address lpToken, , , , ) = IConvexBooster(
        //     convexBooster
        // ).poolInfo(pool.convexPid);
        // uint256 token0Price = ICurveSwap(curveSwapAddress)
        //     .calc_withdraw_one_coin(_token0, curveCoinId);
        address curveSwapAddress;
        (, curveSwapAddress, lpToken, , , , ) = IConvexBooster(convexBooster)
            .poolInfo(_convexPid);
        token0Price = ICurveSwap(curveSwapAddress).calc_withdraw_one_coin(
            _token0,
            _curveCoinId
        );
    }

    function _borrow(
        uint256 _pid,
        uint256 _supportPid,
        uint256 _borrowNumber,
        uint256 _token0
    ) internal returns (LendingParams memory) {
        PoolInfo storage pool = poolInfo[_pid];

        pool.borrowIndex++;

        bytes16 lendingId = generateId(msg.sender, _pid, pool.borrowIndex * 2);

        LendingParams memory lendingParams = getLendingInfo(
            _token0,
            pool.convexPid,
            pool.curveCoinIds[_supportPid],
            pool.supportPids[_supportPid],
            pool.lendingThreshold,
            pool.liquidateThreshold,
            _borrowNumber
        );

        IERC20(lendingParams.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _token0
        );

        // deposit
        // 授权
        IERC20(lendingParams.lpToken).safeApprove(convexBooster, 0);
        IERC20(lendingParams.lpToken).safeApprove(convexBooster, _token0);

        ICompoundBooster(compoundBooster).borrow(
            pool.supportPids[_supportPid],
            lendingId,
            msg.sender,
            lendingParams.lendingAmount,
            lendingParams.collateralAmount,
            _borrowNumber
        );

        IConvexBooster(convexBooster).depositFor(
            pool.convexPid,
            _token0,
            msg.sender
        );

        userLendings[msg.sender].push(
            UserLending({
                lendingId: lendingId,
                token0Value: _token0,
                token0Price: lendingParams.token0Price,
                lendingAmount: lendingParams.lendingAmount,
                supportPid: pool.supportPids[_supportPid],
                curveCoinId: pool.curveCoinIds[_supportPid],
                interestValue: lendingParams.interestAmount,
                borrowNumbers: _borrowNumber,
                borrowBlocksLimit: borrowNumberLimit[_borrowNumber]
            })
        );

        lendings[lendingId] = LendingInfo({
            user: msg.sender,
            pid: _pid,
            borrowIndex: pool.borrowIndex,
            userLendingId: userLendings[msg.sender].length - 1,
            startedBlock: block.number,
            utilizationRate: lendingParams.utilizationRate,
            compoundRatePerBlock: lendingParams.compoundRatePerBlock,
            state: UserLendingState.LENDING
        });

        poolLending[_pid][pool.borrowIndex] = lendingId;

        ILiquidateSponsor(liquidateSponsor).addSponsor{value: msg.value}(
            lendingId,
            msg.sender
        );

        emit Borrow(
            lendingId,
            msg.sender,
            _token0,
            lendingParams.token0Price,
            lendingParams.lendingAmount,
            borrowNumberLimit[_borrowNumber],
            UserLendingState.LENDING
        );

        return lendingParams;
    }

    function _repayBorrow(
        bytes16 _lendingId,
        uint256 _amount,
        bool isErc20
    ) internal {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];
        PoolInfo memory pool = poolInfo[lendingInfo.pid];
        uint256 payAmount = userLending.lendingAmount.add(
            userLending.interestValue
        );

        uint256 maxAmount = payAmount.add(payAmount.mul(5).div(1000));

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );
        require(
            block.number <=
                lendingInfo.startedBlock.add(userLending.borrowBlocksLimit),
            "Expired"
        );

        require(
            _amount >= payAmount && _amount <= maxAmount,
            "amount range error"
        );

        lendingInfo.state = UserLendingState.EXPIRED;

        // withdraw
        IConvexBooster(convexBooster).withdrawFor(
            pool.convexPid,
            userLending.token0Value,
            lendingInfo.user
        );

        BorrowInfo storage borrowInfo = borrowInfos[lendingInfo.pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Value
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[lendingInfo.user];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0Value
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );
        statistic.recentRepayAt = block.timestamp;

        // struct LendingInfo {
        //     uint256 pid;
        //     address proxyUser;
        //     uint256 cTokens;
        //     address underlyToken;
        //     uint256 amount;
        //     uint256 borrowNumbers; // 借款周期 区块长度
        //     uint256 startedBlock; // 创建借贷的区块
        //     LendingInfoState state;
        // }

        if (isErc20) {
            // 转钱给proxyUser
            (
                ,
                address proxyUser,
                ,
                address underlyToken,
                ,
                ,
                ,

            ) = ICompoundBooster(compoundBooster).lendingInfos(
                    userLending.lendingId
                );

            IERC20(underlyToken).safeTransfer(
                proxyUser,
                _amount
                // userLending.lendingAmount.add(userLending.interestValue)
            );

            ICompoundBooster(compoundBooster).repayBorrowErc20(
                userLending.lendingId,
                lendingInfo.user,
                // userLending.lendingAmount,
                _amount,
                userLending.interestValue
            );
        } else {
            ICompoundBooster(compoundBooster).repayBorrow{value: _amount}(
                userLending.lendingId,
                lendingInfo.user,
                userLending.interestValue
            );
        }

        ILiquidateSponsor(liquidateSponsor).requestSponsor(
            userLending.lendingId
        );

        emit RepayBorrow(
            userLending.lendingId,
            lendingInfo.user,
            lendingInfo.state
        );
        // 分交易手续费
    }

    function repayBorrow(bytes16 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, false);
    }

    function repayBorrow(bytes16 _lendingId, uint256 _amount) public {
        _repayBorrow(_lendingId, _amount, true);
    }

    function liquidate(bytes16 _lendingId) public {
        uint256 gasStart = gasleft();
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            lendingInfo.startedBlock.add(userLending.borrowNumbers).sub(
                liquidateThresholdBlockNumbers
            ) >= block.timestamp,
            "!borrowNumbers"
        );

        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        lendingInfo.state = UserLendingState.LIQUIDATED;

        BorrowInfo storage borrowInfo = borrowInfos[lendingInfo.pid];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Value
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        (, address proxyUser, , , , , , ) = ICompoundBooster(compoundBooster)
            .lendingInfos(userLending.lendingId);

        (address underlyToken, uint256 liquidateAmount) = IConvexBooster(
            convexBooster
        ).liquidate(
                pool.convexPid,
                userLending.curveCoinId,
                lendingInfo.user,
                userLending.token0Value
            );

        if (underlyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(proxyUser).transfer(liquidateAmount);
        } else {
            IERC20(underlyToken).safeTransfer(proxyUser, liquidateAmount);
        }

        ICompoundBooster(compoundBooster).liquidate(userLending.lendingId);

        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);

        ILiquidateSponsor(liquidateSponsor).payFee(
            userLending.lendingId,
            lendingInfo.user,
            gasSpent
        );

        emit Liquidate(
            userLending.lendingId,
            lendingInfo.user,
            liquidateAmount,
            gasSpent,
            lendingInfo.state
        );
    }

    function setBorrowNumberLimit(uint256 _number, uint256 _blockNumbers)
        public
    {
        borrowNumberLimit[_number] = _blockNumbers;
    }

    receive() external payable {}

    function addPool(
        uint256 _convexPid,
        uint256[] memory _supportPids,
        int128[] memory _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) public {
        poolInfo.push(
            PoolInfo({
                convexPid: _convexPid,
                supportPids: _supportPids,
                curveCoinIds: _curveCoinIds,
                lendingThreshold: _lendingThreshold,
                liquidateThreshold: _liquidateThreshold,
                borrowIndex: 0
            })
        );
    }

    function setLiquidateThresholdBlockNumbers(uint256 _blockNumbers) public {
        liquidateThresholdBlockNumbers = _blockNumbers;
    }

    function DemoAddPool() public {
        uint256[] memory dai_usdc_supportPids = new uint256[](2);
        dai_usdc_supportPids[0] = 2;
        dai_usdc_supportPids[1] = 1;

        int128[] memory cusdc_cdai_curveCoinIds = new int128[](2);
        cusdc_cdai_curveCoinIds[0] = 0;
        cusdc_cdai_curveCoinIds[1] = 1;

        addPool(0, dai_usdc_supportPids, cusdc_cdai_curveCoinIds, 100, 50);

        uint256[] memory eth_supportPids = new uint256[](1);
        eth_supportPids[0] = 0;

        int128[] memory ceth_curveCoinIds = new int128[](1);
        cusdc_cdai_curveCoinIds[0] = 0;

        addPool(1, eth_supportPids, ceth_curveCoinIds, 100, 50);
    }

    function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    }

    function generateId(
        address x,
        uint256 y,
        uint256 z
    ) public pure returns (bytes16 b) {
        b = toBytes16(uint256(keccak256(abi.encodePacked(x, y, z))));
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function cursor(
        uint256 _pid,
        uint256 _offset,
        uint256 _size
    ) public view returns (bytes16[] memory, uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 size = _offset + _size > pool.borrowIndex
            ? pool.borrowIndex - _offset
            : _size;
        uint256 index;

        bytes16[] memory userLendingIds = new bytes16[](size);

        for (uint256 i = 0; i < size; i++) {
            bytes16 userLendingId = poolLending[_pid][_offset + i];

            userLendingIds[index] = userLendingId;
            index++;
        }

        return (userLendingIds, pool.borrowIndex);
    }

    function calculateRepayAmount(bytes16 _lendingId)
        public
        view
        returns (uint256)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        if (lendingInfo.state == UserLendingState.LIQUIDATED) return 0;

        return userLending.lendingAmount.add(userLending.interestValue);
    }

    function getPoolSupportPids(uint256 _pid)
        public
        view
        returns (uint256[] memory)
    {
        PoolInfo memory pool = poolInfo[_pid];

        return pool.supportPids;
    }

    function getCurveCoinId(uint256 _pid, uint256 _supportPid)
        public
        view
        returns (int128)
    {
        PoolInfo memory pool = poolInfo[_pid];

        return pool.curveCoinIds[_supportPid];
    }

    function getUserLendingState(bytes16 _lendingId)
        public
        view
        returns (UserLendingState)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        return lendingInfo.state;
    }

    function getLendingInfo(
        uint256 _token0,
        uint256 _convexPid,
        int128 _curveId,
        uint256 _compoundPid,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold,
        uint256 _borrowBlocks
    ) public view returns (LendingParams memory) {
        /* 
        
        //放大系数
        X:使用率；Y:倍数
        //90%>=X>=0
        Y=10/9*X+1
        //100%>=X>=90%
        Y=20X-16

        //LF区块利率
        区块利率 = Compound区块利率 * 放大系数


        //借款规格
        591,300 block ≈ 3个月
        1,182,600 block ≈ 6个月
        2,365,200 block ≈ 12个月

        //LendFlare借款
        借款数 = 抵押品价值 * 0.85 / (1 + LF区块利率 * 借款规格)
        //展开公式
        if (0.9>=使用率>=0)
        借款数 = 抵押品价值 * 0.85 / {1 + [Compound区块利率* （10 / 9 * 使用率 + 1)] * 借款规格}
        if (1>=使用率>0.9)
        借款数 = 抵押品价值 * 0.85 / {1 + [Compound区块利率 * （20 * 使用率 - 16)] * 借款规格}
        A = 借款数 * (1 + Compound区块利率 * 借款规格) / 0.8

        //Compound借款
        抵押数 = A / 抵押品因素

        //验证1
        条件：
        抵押品价值 = 0.9 eth
        使用率 = 0.5
        抵押品因素 = 0.75
        Compound区块利率 = 0.0000002
        借款规格 = 1,182,600 block ≈ 6个月
        结果：
        借款数 = 0.559243 eth
        抵押数 = 0.932072 eth

        //验证2
        条件：
        抵押品价值 = 0.9 eth
        使用率 = 0.95
        抵押品因素 = 0.75
        Compound区块利率 = 0.0000002
        借款规格 = 1,182,600 block ≈ 6个月
        结果：
        借款数 = 0.447483 eth
        抵押数 = 0.745805 eth

        总利息 = LF区块利率 * 借款数量 * 借款规格
        Compound利息 = Compound区块利息 * 借款数量 * 借款规格

         */
        (address lpToken, uint256 token0Price) = _getCurveInfo(
            _convexPid,
            _curveId,
            _token0
        );

        uint256 collateralFactorMantissa = ICompoundBooster(compoundBooster)
            .getCollateralFactorMantissa(_compoundPid);
        uint256 utilizationRate = ICompoundBooster(compoundBooster)
            .getUtilizationRate(_compoundPid);
        // uint256 borrowRate = getBorrowRate(
        //     utilizationRate,
        //     _compoundPid,
        //     _borrowBlocks
        // );
        uint256 compoundRatePerBlock = ICompoundBooster(compoundBooster)
            .getBorrowRatePerBlock(_compoundPid);
        uint256 compoundRate = getCompoundRate(
            compoundRatePerBlock,
            _borrowBlocks
        );
        uint256 amplificationFactor = getAmplificationFactor(utilizationRate);
        uint256 lendFlareRate;

        if (utilizationRate > 0) {
            lendFlareRate = getLendFlareRate(compoundRate, amplificationFactor);
        } else {
            lendFlareRate = compoundRate.sub(1e18);
        }

        uint256 lendingAmount = (token0Price *
            1e18 *
            (1000 - _lendingThreshold - _liquidateThreshold)) /
            (1e18 + lendFlareRate) /
            1000;

        // uint256 blocksRate = compoundRatePerBlock.add(1e18);
        uint256 collateralAmount = lendingAmount
            .mul(compoundRate)
            .mul(1000)
            .div(800)
            .div(collateralFactorMantissa);

        uint256 interestAmount = lendingAmount.mul(lendFlareRate).div(1e18);

        return
            LendingParams({
                lendingAmount: lendingAmount,
                collateralAmount: collateralAmount,
                interestAmount: interestAmount,
                borrowRate: lendFlareRate,
                utilizationRate: utilizationRate,
                compoundRatePerBlock: compoundRatePerBlock,
                lpToken: lpToken,
                token0Price: token0Price
            });
        // return (lendingAmount, collateralAmount, borrowRate);
    }

    function getUserLendingsLength(address _user)
        public
        view
        returns (uint256)
    {
        return userLendings[_user].length;
    }

    // function getBorrowRate(
    //     uint256 _utilizationRate,
    //     uint256 _supportPid,
    //     uint256 _blockNumbers
    // ) public view returns (uint256) {
    //     if (_blockNumbers == 0) _blockNumbers = 1;

    //     if (_utilizationRate <= 0.9 * 1e18) {
    //         return
    //             uint256(10)
    //                 .mul(_utilizationRate)
    //                 .div(9)
    //                 .add(1e18)
    //                 .mul(
    //                     ICompoundBooster(compoundBooster).getBorrowRatePerBlock(
    //                         _supportPid
    //                     )
    //                 )
    //                 .div(1e18)
    //                 .mul(_blockNumbers);
    //     }

    //     return
    //         uint256(20)
    //             .mul(_utilizationRate)
    //             .sub(16 * 1e18)
    //             .mul(
    //                 ICompoundBooster(compoundBooster).getBorrowRatePerBlock(
    //                     _supportPid
    //                 )
    //             )
    //             .div(1e18)
    //             .mul(_blockNumbers);
    // }

    function getCompoundRate(uint256 _compoundBlockRate, uint256 n)
        public
        pure
        returns (uint256)
    {
        _compoundBlockRate = _compoundBlockRate + (10**18);

        for (uint256 i = 1; i <= n; i++) {
            _compoundBlockRate = (_compoundBlockRate**2) / (10**18);
        }

        return _compoundBlockRate;
    }

    function getAmplificationFactor(uint256 _utilizationRate)
        public
        pure
        returns (uint256)
    {
        if (_utilizationRate <= 0.9 * 1e18) {
            return uint256(10).mul(_utilizationRate).div(9).add(1e18);
        }

        return uint256(20).mul(_utilizationRate).sub(16 * 1e18);
    }

    function getLendFlareRate(
        uint256 _compoundRate,
        uint256 _amplificationFactor
    ) public pure returns (uint256) {
        return _compoundRate.sub(1e18).mul(_amplificationFactor).div(1e18);
    }
}