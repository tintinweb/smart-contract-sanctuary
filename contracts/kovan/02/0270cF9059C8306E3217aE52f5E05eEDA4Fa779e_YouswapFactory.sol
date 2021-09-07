/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/interface/ITokenYou.sol


pragma solidity 0.7.4;

interface ITokenYou {
    
    function mint(address recipient, uint256 amount) external;
    
    function decimals() external view returns (uint8);
    
}

// File: contracts/interface/IYouswapFactory.sol


pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;


interface BaseStruct {

    /** 矿池四种类型 */
     enum PoolLockType {
        SINGLE_TOKEN, //单币挖矿
        LP_TOKEN, //lp挖矿
        SINGLE_TOKEN_FIXED, //单币定期挖矿
        LP_TOKEN_FIXED //lp定期挖矿
    }

    /** 矿池可视化信息 */
    struct PoolViewInfo {
        address token; //token合约地址
        string name; //名称，不需要
        uint256 multiple; //奖励倍数
        uint256 priority; //排序
    }

    /** 矿池质押信息 */
    struct PoolStakeInfo {
        uint256 startBlock; //挖矿开始块高
        uint256 startTime; //挖矿开始时间
        bool enableInvite; //是否启用邀请关系
        address token; //token合约地址，单币，lp都是这个
        uint256 amount; //质押数量，这个就是TVL
        uint256 participantCounts; //参与质押玩家数量
        PoolLockType poolType; //单币挖矿，lp挖矿，单币定期，lp定期
        uint256 lockSeconds; //锁仓持续时间
        uint256 lockUntil; //锁仓结束时间（秒单位）
        uint256 lastRewardBlock; //最后发放奖励块高
        uint256 totalPower; //总算力
        uint256 powerRatio; //质押数量到算力系数，数量就是算力吧
        uint256 maxStakeAmount; //最大质押数量
        uint256 endBlock; //挖矿结束块高
        uint256 endTime; //挖矿结束时间
        uint256 selfReward; //质押自奖励
        uint256 invite1Reward; //1级邀请奖励
        uint256 invite2Reward; //2级邀请奖励
        bool isReopen; //是否为重启矿池
    }

    /** 矿池奖励信息 */
    struct PoolRewardInfo {
        address token; //挖矿奖励币种:A/B/C
        uint256 rewardTotal; //矿池总奖励
        uint256 rewardPerBlock; //单个区块奖励
        uint256 rewardProvide; //矿池已发放奖励
        uint256 rewardPerShare; //单位算力奖励
    }

    /** 用户质押信息 */
    struct UserStakeInfo {
        uint256 startBlock; //质押开始块高
        uint256 amount; //质押数量
        uint256 invitePower; //邀请算力
        uint256 stakePower; //质押算力
        uint256[] invitePendingRewards; //待领取奖励
        uint256[] stakePendingRewards; //待领取奖励
        uint256[] inviteRewardDebts; //邀请负债
        uint256[] stakeRewardDebts; //质押负债
        uint256[] inviteClaimedRewards; //已领取邀请奖励
        uint256[] stakeClaimedRewards; //已领取质押奖励
    }
}

////////////////////////////////// 挖矿Core合约 //////////////////////////////////////////////////
interface IYouswapFactoryCore is BaseStruct {
    function initialize(address _owner, address _platform, address _invite) external;

    function getPoolRewardInfo(uint256 poolId) external view returns (PoolRewardInfo[] memory);

    function getUserStakeInfo(uint256 poolId, address user) external view returns (UserStakeInfo memory);

    function getPoolStakeInfo(uint256 poolId) external view returns (PoolStakeInfo memory);

    function getPoolViewInfo(uint256 poolId) external view returns (PoolViewInfo memory);

    function stake(uint256 poolId, uint256 amount, address user) external;

    function _unStake(uint256 poolId, uint256 amount, address user) external;

    function _withdrawReward(uint256 poolId, address user) external;

    function getPoolIds() external view returns (uint256[] memory);

    function addPool(
        uint256 prePoolId,
        uint256 range,
        string memory name,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external;

    /** 
    修改矿池总奖励
    */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) external;

    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) external;

    /**
    设置定期合约领取控制 
    */
    function setWithdrawAllowed(uint256 _poolId, bool _allowedState) external;

    /**
    修改矿池名称
     */
    function setName(uint256 poolId, string memory name) external;

    /**
    修改矿池倍数
     */
    function setMultiple(uint256 poolId, uint256 multiple) external;

    /**
    修改矿池排序
     */
    function setPriority(uint256 poolId, uint256 priority) external;

    /**
    修改矿池最大可质押数量
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;

    /**
    矿池ID有效性校验
     */
    function checkPIDValidation(uint256 poolId) external view;

    /**
    刷新矿池，确保结束时间被设置
     */
    function refresh(uint256 _poolId) external;

    /** 紧急转移token */
    function safeWithdraw(address token, address to, uint256 amount) external;
}

////////////////////////////////// 挖矿外围合约 //////////////////////////////////////////////////
interface IYouswapFactory is BaseStruct {
    /**
    修改OWNER
     */
    function transferOwnership(address owner) external;

    /**
    质押
    */
    function stake(uint256 poolId, uint256 amount) external;

    /**
    解质押并提取奖励
     */
    function unStake(uint256 poolId, uint256 amount) external;

    /**
    批量解质押并提取奖励
     */
    function unStakes(uint256[] memory _poolIds) external;

    /**
    提取奖励
     */
    function withdrawReward(uint256 poolId) external;

    /**
    批量提取奖励，供平台调用
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external;

    /**
    待领取的奖励
     */
    function pendingRewardV3(uint256 poolId, address user) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    矿池ID
     */
    function poolIds() external view returns (uint256[] memory);

    /**
    质押数量范围
     */
    function stakeRange(uint256 poolId) external view returns (uint256, uint256);

    /**
    设置RewardPerBlock修改最大幅度
     */
    function setChangeRPBRateMax(uint256 _rateMax) external;

    /** 
    调整区块奖励修改周期 
    */
    function setChangeRPBIntervalMin(uint256 _interval) external;

    /*
    矿池名称，质押币种，是否启用邀请，总锁仓，地址数，矿池类型，锁仓时间，最大质押数量，开始时间，结束时间
    */
    function getPoolStakeDetail(uint256 poolId) external view returns (string memory, address, bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    /**
    用户质押详情 
    */
    function getUserStakeInfo(uint256 poolId, address user) external view returns (uint256, uint256, uint256, uint256);

    /**
    用户奖励详情 
    */
    function getUserRewardInfo(uint256 poolId, address user, uint256 index) external view returns ( uint256, uint256, uint256, uint256);

    /**
    获取矿池奖励详情 
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    矿池奖励详情 
    */
    function getPoolRewardInfo(uint poolId) external view returns (PoolRewardInfo[] memory);

    /**
    增加奖励APR 
    */
    function addRewardThroughAPR(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals, uint256[] memory addRewardPerBlocks) external;
    
    /**
    延长矿池奖励时间 
    */
    function addRewardThroughTime(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals) external;

    /** 
    设置运营权限 
    */
    function setOperateOwner(address user, bool state) external;

    /** 
    新建矿池 
    */
    function addPool(
        uint256 prePoolId,
        uint256 range,
        string memory name,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external;

    /**
    修改矿池区块奖励
     */
    function updateRewardPerBlock(uint256 poolId, bool increaseFlag, uint256 percent) external;

    /**
    修改矿池最大可质押数量
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;
}

// File: contracts/utils/constant.sol


pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'YouSwap:FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'YouSwap:IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'YouSwap:ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'YouSwap:INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'YouSwap:BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'YouSwap:REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'YouSwap:PARAMETER_TOO_LONG';
    string constant REGISTERED = 'YouSwap:REGISTERED';
    string constant MINING_NOT_STARTED = 'YouSwap:MINING_NOT_STARTED';
    string constant END_OF_MINING = 'YouSwap:END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING';
    
}

library DefaultSettings {
    uint256 constant BENEFIT_RATE_MIN = 0; // 0% 平台抽成最小比例, 10: 0.1%, 100: 1%, 1000: 10%, 10000: 100%
    uint256 constant BENEFIT_RATE_MAX = 10000; //100% 平台抽成最大比例
    uint256 constant TEN_THOUSAND = 10000; //100% 平台抽成最大比例
    uint256 constant EACH_FACTORY_POOL_MAX = 10000; //每个矿池合约创建合约上限
    uint256 constant CHANGE_RATE_MAX = 30; //调整区块发放数量幅度单次最大30%
    uint256 constant DAY_INTERVAL_MIN = 7; //调整单个区块奖励数量频率
    uint256 constant SECONDS_PER_DAY = 86400; //每天秒数
    uint256 constant REWARD_TOKENTYPE_MAX = 10; //奖励币种最大数量
}

// File: contracts/implement/YouswapFactory.sol


pragma solidity 0.7.4;

// import "hardhat/console.sol";




contract YouswapFactory is IYouswapFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address private constant ZERO = address(0);

    address public owner; //所有权限
    address internal platform; //平台，addPool权限

    IYouswapFactoryCore public core; //core合约
    mapping(address => bool) public operateOwner; //运营权限
    mapping(uint256 => uint256) public lastSetRewardPerBlockTime; //最后一次设置区块奖励数时间，poolid->timestamp

    uint256 public changeRewardPerBlockRateMax; //调整区块最大比例，default: 30%
    uint256 public changeRewardPerBlockIntervalMin; //调整区块最小时间间隔，default: 7 days
    uint256 public benefitRate; //平台抽成比例

    //校验owner权限
    modifier onlyOwner() {
        require(owner == msg.sender, "YouSwap:FORBIDDEN_NOT_OWNER");
        _;
    }

    //校验platform权限
    modifier onlyPlatform() {
        require(platform == msg.sender, "YouSwap:FORBIDFORBIDDEN_NOT_PLATFORM");
        _;
    }

    //校验运营权限
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_OPERATER");
        _;
    }

    /**
    @notice clone YouSwapFactory初始化
    @param _owner 项目方
    @param _platform FactoryCreator平台
    @param _benefitRate 抽成比例
    @param _invite 邀请合约，直接透传
    @param _core clone核心合约
    */
    function initialize(address _owner, address _platform, uint256 _benefitRate, address _invite, address _core) external {
        require(!initialized,  "YouSwap:ALREADY_INITIALIZED!");
        initialized = true;
        core = IYouswapFactoryCore(_core);
        core.initialize(address(this), _platform, _invite);

        owner = _owner; //owner权限
        platform = _platform; //平台权限
        benefitRate = _benefitRate;

        changeRewardPerBlockRateMax = DefaultSettings.CHANGE_RATE_MAX; //默认值设置
        changeRewardPerBlockIntervalMin = DefaultSettings.DAY_INTERVAL_MIN;
        _setOperateOwner(_owner, true); 
    }

    /**
     @notice 转移owner权限
     @param oldOwner：旧Owner
     @param newOwner：新Owner
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /**
    @notice 领取定期矿池收益时触发
    @param poolId 矿池id
    @param isAllowed 是否允许领取
     */
    event WithdrawRewardAllowedEvent(uint256 poolId, bool isAllowed);

    /**
    @notice 调整单块奖励调整比例
    @param poolId 矿池id
    @param increaseFlag 是否增加
    @param percent 调整比例
     */
    event UpdateRewardPerBlockEvent(uint256 poolId, bool increaseFlag, uint256 percent);

    /**
    @notice 加奖励APR
    @param poolId 矿池id
    @param tokens 调整奖励币种
    @param addRewardTotals 增加奖励币种总量
    @param addRewardPerBlocks 增加单块奖励数量
     */
    event AddRewardThroughAPREvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals, uint256[]addRewardPerBlocks);

    /**
    @notice 加奖励APR
    @param poolId 矿池id
    @param tokens 调整奖励币种
    @param addRewardTotals 增加奖励币种总量
     */
    event AddRewardThroughTimeEvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals);

    /**
     @notice 修改OWNER
     @param _owner：新Owner
     */
    function transferOwnership(address _owner) external override onlyOwner {
        require(ZERO != _owner, "YouSwap:INVALID_ADDRESSES");
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }

    /**
    设置运营权限
     */
    function setOperateOwner(address user, bool state) external override onlyOwner {
        _setOperateOwner(user, state);
    }

    /**
     @notice 设置运营权限
     @param user 运营地址
     @param state 权限状态
     */
    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; //设置运营权限
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /**
    @notice 质押
    @param poolId 质押矿池
    @param amount 质押数量
    */
    function stake(uint256 poolId, uint256 amount) external override {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        // console.log("poolStakeInfo.startTime:", poolStakeInfo.startTime, block.timestamp);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START"); //是否开启挖矿
        require((poolStakeInfo.powerRatio <= amount) && (poolStakeInfo.amount.add(amount) <= poolStakeInfo.maxStakeAmount), "YouSwap:STAKE_AMOUNT_TOO_SMALL_OR_TOO_LARGE");

        IERC20(poolStakeInfo.token).safeTransferFrom(msg.sender, address(core), amount); //转移sender的质押资产到this
        core.stake(poolId, amount, msg.sender);
    }

    /**
    @notice 解质押
    @param poolId 解质押矿池
    @param amount 解质押数量
     */
    function unStake(uint256 poolId, uint256 amount) external override {
        checkOperationValidation(poolId);
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
        require((amount > 0) && (userStakeInfo.amount >= amount), "YouSwap:BALANCE_INSUFFICIENT");
        core._unStake(poolId, amount, msg.sender);
    }

    /**
    @notice 批量解质押并提取奖励
    @param _poolIds 解质押矿池
     */
    function unStakes(uint256[] memory _poolIds) external override {
        require((0 < _poolIds.length) && (50 >= _poolIds.length), "YouSwap:PARAMETER_ERROR_TOO_SHORT_OR_LONG");
        uint256 amount;
        uint256 poolId;
        BaseStruct.UserStakeInfo memory userStakeInfo;

        for (uint256 i = 0; i < _poolIds.length; i++) {
            poolId = _poolIds[i];
            checkOperationValidation(poolId);
            userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
            amount = userStakeInfo.amount; //sender的质押数量

            if (0 < amount) {
                core._unStake(poolId, amount, msg.sender);
            }
        }
    }

    /**
    @notice 提取奖励
    @param poolId 矿池id
     */
    function withdrawReward(uint256 poolId) public override {
        // core.checkPIDValidation(poolId);
        checkOperationValidation(poolId);
        core._withdrawReward(poolId, msg.sender);
    }

    /**
    批量提取奖励，供平台使用
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external onlyPlatform override {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(_poolIds[i]);
            if (poolStakeInfo.startTime > block.timestamp && !poolStakeInfo.isReopen) {
                continue;
            }
            core._withdrawReward(_poolIds[i], user);
        }
    }

    /**
    校验重&&开锁仓有效性
     */
     function checkOperationValidation(uint256 poolId) internal view {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != poolStakeInfo.token), "YouSwap:POOL_NOT_EXIST"); //是否开启挖矿
        if (!poolStakeInfo.isReopen) {
            require((poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_START"); //是否开启挖矿
            if (poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED) {
                require(block.timestamp >= poolStakeInfo.lockUntil, "YouSwap:POOL_NONE_REOPEN_LOCKED_DENIED!");
            }
        } else {
            //重开
            if ((poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number)) {
                if (poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED) {
                    require(block.timestamp >= poolStakeInfo.lockUntil, "YouSwap:POOL_REOPEN_LOCKED_DENIED!");
                }
            }
        }
     }

    struct PendingLocalVars {
        uint256 poolId;
        address user;
        uint256 inviteReward;
        uint256 stakeReward;
        uint256 rewardPre;
    }

    /**
    待领取的奖励: tokens，invite待领取，质押待领取，invite已领取，质押已领取
     */
    function pendingRewardV3(uint256 poolId, address user) external view override returns (
                            address[] memory tokens, 
                            uint256[] memory invitePendingRewardsRet, 
                            uint256[] memory stakePendingRewardsRet, 
                            uint256[] memory inviteClaimedRewardsRet, 
                            uint256[] memory stakeClaimedRewardsRet) {
        PendingLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(vars.poolId);
        tokens = new address[](_poolRewardInfos.length);
        invitePendingRewardsRet = new uint256[](_poolRewardInfos.length);
        stakePendingRewardsRet = new uint256[](_poolRewardInfos.length);
        inviteClaimedRewardsRet = new uint256[](_poolRewardInfos.length);
        stakeClaimedRewardsRet = new uint256[](_poolRewardInfos.length);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(vars.poolId);
        if (ZERO != poolStakeInfo.token) {
            BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(vars.poolId,vars.user);

            uint256 i = userStakeInfo.invitePendingRewards.length;
            for (uint256 j = 0; j < _poolRewardInfos.length; j++) {
                BaseStruct.PoolRewardInfo memory poolRewardInfo = _poolRewardInfos[j];
                // if (poolStakeInfo.startBlock <= block.number && poolStakeInfo.startTime <= block.timestamp) {
                    vars.inviteReward = 0;
                    vars.stakeReward = 0;

                    if (0 < poolStakeInfo.totalPower) {
                        if (block.number > poolStakeInfo.lastRewardBlock) {
                            vars.rewardPre = block.number.sub(poolStakeInfo.lastRewardBlock).mul(poolRewardInfo.rewardPerBlock); //待快照奖励
                            if (poolRewardInfo.rewardProvide.add(vars.rewardPre) >= poolRewardInfo.rewardTotal) {
                                vars.rewardPre = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //核减超出奖励
                            }
                            poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(vars.rewardPre.mul(1e24).div(poolStakeInfo.totalPower)); //累加待快照的单位算力奖励
                        }
                    }

                    if (i > j) {
                        //统计旧奖励币种
                        vars.inviteReward = userStakeInfo.invitePendingRewards[j]; //待领取奖励
                        vars.stakeReward = userStakeInfo.stakePendingRewards[j]; //待领取奖励
                        vars.inviteReward = vars.inviteReward.add(userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.inviteRewardDebts[j]).div(1e24)); //待快照的邀请奖励
                        vars.stakeReward = vars.stakeReward.add(userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.stakeRewardDebts[j]).div(1e24)); //待快照的质押奖励
                        inviteClaimedRewardsRet[j] = userStakeInfo.inviteClaimedRewards[j]; //已领取邀请奖励(累计)
                        stakeClaimedRewardsRet[j] = userStakeInfo.stakeClaimedRewards[j]; //已领取质押奖励(累计)
                    } else {
                        // 统计新奖励币种
                        vars.inviteReward = userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).div(1e24); //待快照的邀请奖励
                        vars.stakeReward = userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).div(1e24); //待快照的质押奖励
                    }

                    invitePendingRewardsRet[j] = vars.inviteReward;
                    stakePendingRewardsRet[j] = vars.stakeReward;
                // }
                tokens[j] = poolRewardInfo.token;
            }
        }
    }

    /**
    矿池ID
     */
    function poolIds() external view override returns (uint256[] memory poolIDs) {
        poolIDs = core.getPoolIds();
    }

    /**
    质押数量范围
     */
    function stakeRange(uint256 poolId) external view override returns (uint256 powerRatio, uint256 maxStakeAmount) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        if (ZERO == poolStakeInfo.token) {
            return (0, 0);
        }
        powerRatio = poolStakeInfo.powerRatio;
        maxStakeAmount = poolStakeInfo.maxStakeAmount.sub(poolStakeInfo.amount);
    }

    /*
    矿池名称，质押币种，是否启用邀请，总锁仓，地址数，矿池类型，锁仓时间，最大质押数量，开始时间，结束时间
    */
    function getPoolStakeDetail(uint256 poolId) external view override returns (
                        string memory name, 
                        address token, 
                        bool enableInvite, 
                        uint256 stakeAmount, 
                        uint256 participantCounts, 
                        uint256 poolType, 
                        uint256 lockSeconds, 
                        uint256 maxStakeAmount, 
                        uint256 startTime, 
                        uint256 endTime) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        BaseStruct.PoolViewInfo memory poolViewInfo = core.getPoolViewInfo(poolId);

        name = poolViewInfo.name;
        token = poolStakeInfo.token;
        enableInvite = poolStakeInfo.enableInvite;
        stakeAmount = poolStakeInfo.amount;
        participantCounts = poolStakeInfo.participantCounts;
        poolType = uint256(poolStakeInfo.poolType); 
        lockSeconds = poolStakeInfo.lockSeconds;
        maxStakeAmount = poolStakeInfo.maxStakeAmount;
        startTime = poolStakeInfo.startTime;
        endTime = poolStakeInfo.endTime;
    }

    /**用户质押详情 */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (
                        uint256 startBlock, 
                        uint256 stakeAmount, 
                        uint256 invitePower,
                        uint256 stakePower) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        startBlock = userStakeInfo.startBlock;
        stakeAmount = userStakeInfo.amount;
        invitePower = userStakeInfo.invitePower;
        stakePower = userStakeInfo.stakePower;
    }

    /*
    获取奖励详情
    */
    function getUserRewardInfo(uint256 poolId, address user, uint256 index) external view override returns (
                        uint256 invitePendingReward,
                        uint256 stakePendingReward, 
                        uint256 inviteRewardDebt, 
                        uint256 stakeRewardDebt) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        invitePendingReward = userStakeInfo.invitePendingRewards[index];
        stakePendingReward = userStakeInfo.stakePendingRewards[index];
        inviteRewardDebt = userStakeInfo.inviteRewardDebts[index];
        stakeRewardDebt = userStakeInfo.stakeRewardDebts[index];
    }

    /**
    获取挖矿奖励详情 
    */
    function getPoolRewardInfo(uint poolId) external view override returns (PoolRewardInfo[] memory) {
        return core.getPoolRewardInfo(poolId);
    }

    /* 
    获取多挖币种奖励详情 
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view override returns (
                        address[] memory tokens, 
                        uint256[] memory rewardTotals, 
                        uint256[] memory rewardProvides, 
                        uint256[] memory rewardPerBlocks,
                        uint256[] memory rewardPerShares) {
        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(poolId);
        tokens = new address[](_poolRewardInfos.length);
        rewardTotals = new uint256[](_poolRewardInfos.length);
        rewardProvides = new uint256[](_poolRewardInfos.length);
        rewardPerBlocks = new uint256[](_poolRewardInfos.length);
        rewardPerShares = new uint256[](_poolRewardInfos.length);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        uint256 newRewards;
        uint256 blockCount;
        if(block.number > poolStakeInfo.lastRewardBlock) { //矿池未开始情况
            blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //待发放的区块数量
        }

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            newRewards = blockCount.mul(_poolRewardInfos[i].rewardPerBlock); //两次快照之间总奖励
            tokens[i] = _poolRewardInfos[i].token;
            rewardTotals[i] = _poolRewardInfos[i].rewardTotal;

            if (_poolRewardInfos[i].rewardProvide.add(newRewards) > rewardTotals[i]) {
                rewardProvides[i] = rewardTotals[i];
            } else {
                rewardProvides[i] = _poolRewardInfos[i].rewardProvide.add(newRewards);
            }

            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
            rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
        }
    }

    /** 
    新建矿池 
    */
    function addPool(
        uint256 prePoolId,
        uint256 range,
        string memory name,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external override onlyPlatform {
        require((0 < tokens.length) && (DefaultSettings.REWARD_TOKENTYPE_MAX >= tokens.length) && (tokens.length == rewardTotals.length) && (tokens.length == rewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        require(core.getPoolIds().length < DefaultSettings.EACH_FACTORY_POOL_MAX, "YouSwap:FACTORY_CREATE_MINING_POOL_MAX_REACHED");
        core.addPool(prePoolId, range, name, token, enableInvite, poolParams, tokens, rewardTotals, rewardPerBlocks); 
    }

    /**
    @notice 修改矿池区块奖励，限7天设置一次，不转入资金
    @param poolId 矿池ID
    @param increaseFlag 是否增加
    @param percent 调整比例
     */
    function updateRewardPerBlock(uint256 poolId, bool increaseFlag, uint256 percent) external override onlyOperater {
        require(percent <= changeRewardPerBlockRateMax, "YouSwap:CHANGE_RATE_INPUT_TOO_BIG");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        uint256 lastTime = lastSetRewardPerBlockTime[poolId];
        require(block.timestamp >= lastTime.add(DefaultSettings.SECONDS_PER_DAY.mul(changeRewardPerBlockIntervalMin)), "YouSwap:SET_REWARD_PER_BLOCK_NOT_READY!");
        lastSetRewardPerBlockTime[poolId] = block.timestamp;

        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(poolId);
        for (uint i = 0; i < _poolRewardInfos.length; i++) {
            uint256 preRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
            uint256 newRewardPerBlock;

            if (increaseFlag) {
                newRewardPerBlock = preRewardPerBlock.add(preRewardPerBlock.mul(percent).div(100));
            } else {
                newRewardPerBlock = preRewardPerBlock.sub(preRewardPerBlock.mul(percent).div(100));
            }

            core.setRewardPerBlock(poolId, _poolRewardInfos[i].token, newRewardPerBlock);
        }
        emit UpdateRewardPerBlockEvent(poolId, increaseFlag, percent);
    }

    /** 
    调整区块奖励最大调整幅度 
    */
    function setChangeRPBRateMax(uint256 _rateMax) external override onlyPlatform {
        require(_rateMax <= 100, "YouSwap:SET_CHANGE_REWARD_PER_BLOCK_RATE_MAX_TOO_BIG");
        changeRewardPerBlockRateMax = _rateMax;
    }

    /** 
    调整区块奖励修改周期 
    */
    function setChangeRPBIntervalMin(uint256 _interval) external override onlyPlatform {
        changeRewardPerBlockIntervalMin = _interval;
    }

    /**
    修改矿池最大可质押数量
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyOperater {
        core.checkPIDValidation(poolId);
        core.setMaxStakeAmount(poolId, maxStakeAmount);
    }

    /** 
    @notice 增加奖励APR 两种模式：1. 已有资产 2. 新增币种
    @param poolId uint256, 矿池ID
    @param tokens address[] 奖励币种
    @param addRewardTotals uint256[] 挖矿总奖励，total是新增加数量
    @param addRewardPerBlocks uint256[] 单个区块奖励，rewardPerBlock是增加数量
    */
    function addRewardThroughAPR(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals, uint256[] memory addRewardPerBlocks) external override onlyOperater {
        require((0 < tokens.length) && (DefaultSettings.REWARD_TOKENTYPE_MAX >= tokens.length) && (tokens.length == addRewardTotals.length) && (tokens.length == addRewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        BaseStruct.PoolRewardInfo[] memory poolRewardInfos = core.getPoolRewardInfo(poolId);
        uint256 _newRewardTotal;
        uint256 _newRewardPerBlock;
        bool _existFlag;

        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ZERO != tokens[i], "YouSwap:INVALID_TOKEN_ADDRESS");
            _newRewardTotal = 0;
            _newRewardPerBlock = 0;
            _existFlag = false;

            uint256 benefitAmount = addRewardTotals[i].div(DefaultSettings.TEN_THOUSAND).mul(benefitRate);
            if (benefitAmount > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(platform), benefitAmount);
            }
            newTotals[i] = addRewardTotals[i].sub(benefitAmount);
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(core), newTotals[i]);
            }

            for (uint256 j = 0; j < poolRewardInfos.length; j++) {
                if (tokens[i] == poolRewardInfos[j].token) {
                    _newRewardTotal = poolRewardInfos[j].rewardTotal.add(newTotals[i]);
                    _newRewardPerBlock = poolRewardInfos[j].rewardPerBlock.add(addRewardPerBlocks[i]);
                    _existFlag = true;
                    //break; 不提前break
                }
            }

            if (!_existFlag) {
               _newRewardTotal = newTotals[i];
               _newRewardPerBlock = addRewardPerBlocks[i];
            }

            core.setRewardTotal(poolId, tokens[i], _newRewardTotal);
            core.setRewardPerBlock(poolId, tokens[i], _newRewardPerBlock);
        }
        emit AddRewardThroughAPREvent(poolId, tokens, addRewardTotals, addRewardPerBlocks);
    }

    /** 
    @notice 通过延长时间，设置矿池总奖励，同时转入代币，需要获取之前币种的数量，加上增加数量，然后设置新的Totals
    @param poolId uint256, 矿池ID
    @param tokens address[] 奖励币种
    @param addRewardTotals uint256[] 挖矿总奖励
    */
    function addRewardThroughTime(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals) external override onlyOperater {
        require((0 < tokens.length) && (10 >= tokens.length) && (tokens.length == addRewardTotals.length), "YouSwap:PARAMETER_ERROR_REWARD");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        BaseStruct.PoolRewardInfo[] memory poolRewardInfos = core.getPoolRewardInfo(poolId);
        uint256 _newRewardTotal;
        bool _existFlag;

        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ZERO != tokens[i], "YouSwap:INVALID_TOKEN_ADDRESS");
            require(addRewardTotals[i] > 0, "YouSwap:ADD_REWARD_AMOUNT_SHOULD_GT_ZERO");
            _newRewardTotal = 0;
            _existFlag = false;

            uint256 benefitAmount = addRewardTotals[i].div(DefaultSettings.TEN_THOUSAND).mul(benefitRate);
            if (benefitAmount > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(platform), benefitAmount);
            }
            newTotals[i] = addRewardTotals[i].sub(benefitAmount);
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(core), newTotals[i]);
            }

            for (uint256 j = 0; j < poolRewardInfos.length; j++) {
                if (tokens[i] == poolRewardInfos[j].token) {
                    _newRewardTotal = poolRewardInfos[j].rewardTotal.add(newTotals[i]);
                    _existFlag = true;
                    //break; 不提前break
                }
            }

            require(_existFlag, "YouSwap:REWARD_TOKEN_NOT_EXIST");
            core.setRewardTotal(poolId, tokens[i], _newRewardTotal);
        }
        emit AddRewardThroughTimeEvent(poolId, tokens, addRewardTotals);
    }
}