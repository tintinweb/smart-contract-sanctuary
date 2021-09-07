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

// File: contracts/interface/IYouswapInviteV1.sol


pragma solidity 0.7.4;

interface IYouswapInviteV1 {

    struct UserInfo {
        address upper;//上级
        address[] lowers;//下级
        uint256 startBlock;//邀请块高
    }

    event InviteV1(address indexed owner, address indexed upper, uint256 indexed height);//被邀请人的地址，邀请人的地址，邀请块高

    function inviteCount() external view returns (uint256);//邀请人数

    function inviteUpper1(address) external view returns (address);//上级邀请

    function inviteUpper2(address) external view returns (address, address);//上级邀请

    function inviteLower1(address) external view returns (address[] memory);//下级邀请

    function inviteLower2(address) external view returns (address[] memory, address[] memory);//下级邀请

    function inviteLower2Count(address) external view returns (uint256, uint256);//下级邀请
    
    function register() external returns (bool);//注册邀请关系

    function acceptInvitation(address) external returns (bool);//注册邀请关系
    
    // function inviteBatch(address[] memory) external returns (uint, uint);//注册邀请关系：输入数量，成功数量
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

// File: contracts/implement/YouswapInviteV1.sol


pragma solidity 0.7.4;



contract YouswapInviteV1 is IYouswapInviteV1 {
    address public constant ZERO = address(0);
    uint256 public startBlock;
    address[] public inviteUserInfoV1;
    mapping(address => UserInfo) public inviteUserInfoV2;

    constructor() {
        startBlock = block.number;
    }

    function inviteCount() external view override returns (uint256) {
        return inviteUserInfoV1.length;
    }

    function inviteUpper1(address _owner) external view override returns (address) {
        return inviteUserInfoV2[_owner].upper;
    }

    function inviteUpper2(address _owner) external view override returns (address, address) {
        address upper1 = inviteUserInfoV2[_owner].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfoV2[upper1].upper;
        }

        return (upper1, upper2);
    }

    function inviteLower1(address _owner) external view override returns (address[] memory) {
        return inviteUserInfoV2[_owner].lowers;
    }

    function inviteLower2(address _owner) external view override returns (address[] memory, address[] memory) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 count = 0;
        uint256 lowers1Len = lowers1.length;
        for (uint256 i = 0; i < lowers1Len; i++) {
            count += inviteUserInfoV2[lowers1[i]].lowers.length;
        }
        address[] memory lowers;
        address[] memory lowers2 = new address[](count);
        count = 0;
        for (uint256 i = 0; i < lowers1Len; i++) {
            lowers = inviteUserInfoV2[lowers1[i]].lowers;
            for (uint256 j = 0; j < lowers.length; j++) {
                lowers2[count] = lowers[j];
                count++;
            }
        }

        return (lowers1, lowers2);
    }

    function inviteLower2Count(address _owner) external view override returns (uint256, uint256) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 lowers2Len = 0;
        uint256 len = lowers1.length;
        for (uint256 i = 0; i < len; i++) {
            lowers2Len += inviteUserInfoV2[lowers1[i]].lowers.length;
        }

        return (lowers1.length, lowers2Len);
    }

    function register() external override returns (bool) {
        UserInfo storage user = inviteUserInfoV2[tx.origin];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        user.upper = ZERO;
        user.startBlock = block.number;
        inviteUserInfoV1.push(tx.origin);

        emit InviteV1(tx.origin, user.upper, user.startBlock);

        return true;
    }

    function acceptInvitation(address _inviter) external override returns (bool) {
        require(msg.sender != _inviter, ErrorCode.FORBIDDEN);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        UserInfo storage upper = inviteUserInfoV2[_inviter];
        if (0 == upper.startBlock) {
            upper.upper = ZERO;
            upper.startBlock = block.number;
            inviteUserInfoV1.push(_inviter);

            emit InviteV1(_inviter, upper.upper, upper.startBlock);
        }
        user.upper = _inviter;
        upper.lowers.push(msg.sender);
        user.startBlock = block.number;
        inviteUserInfoV1.push(msg.sender);

        emit InviteV1(msg.sender, user.upper, user.startBlock);

        return true;
    }

    // function inviteBatch(address[] memory _invitees) external override returns (uint256, uint256) {
    //     uint256 len = _invitees.length;
    //     require(len <= 100, ErrorCode.PARAMETER_TOO_LONG);
    //     UserInfo storage user = inviteUserInfoV2[msg.sender];
    //     if (0 == user.startBlock) {
    //         user.upper = ZERO;
    //         user.startBlock = block.number;
    //         inviteUserInfoV1.push(msg.sender);

    //         emit InviteV1(msg.sender, user.upper, user.startBlock);
    //     }
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < len; i++) {
    //         if ((address(0) != _invitees[i]) && (msg.sender != _invitees[i])) {
    //             UserInfo storage lower = inviteUserInfoV2[_invitees[i]];
    //             if (0 == lower.startBlock) {
    //                 lower.upper = msg.sender;
    //                 lower.startBlock = block.number;
    //                 user.lowers.push(_invitees[i]);
    //                 inviteUserInfoV1.push(_invitees[i]);
    //                 count++;

    //                 emit InviteV1(_invitees[i], msg.sender, lower.startBlock);
    //             }
    //         }
    //     }

    //     return (len, count);
    // }
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

// File: contracts/implement/YouswapFactoryCore.sol


pragma solidity 0.7.4;

// import "hardhat/console.sol";




contract YouswapFactoryCore is IYouswapFactoryCore {
    /**
    自邀请
    self：Sender地址
     */
    event InviteRegister(address indexed self);

    /**
    更新矿池信息

    action：true(新建矿池)，false(更新矿池)
    factory：factory合约
    poolId：矿池ID
    name：矿池名称
    token：质押token合约地址
    startBlock：矿池开始挖矿块高
    tokens：挖矿奖励token合约地址
    rewardTotal：挖矿总奖励数量
    rewardPerBlock：区块奖励数量
    enableInvite：是否启用邀请关系
    poolBasicInfos: uint256[] 包含如下：
        multiple：矿池奖励倍数
        priority：矿池排序
        powerRatio：质押数量到算力系数=最小质押数量
        maxStakeAmount：最大质押数量
        poolType：矿池类型(定期，活期): 0,1,2,3
        lockSeconds：定期锁仓时间: 60s
        selfReward：邀请自奖励比例: 5
        invite1Reward：邀请1级奖励比例: 15
        invite2Reward：邀请2级奖励比例: 10
     */
    event UpdatePool(
        bool action,
        address factory,
        uint256 poolId,
        string name,
        address indexed token,
        uint256 startBlock,
        address[] tokens,
        uint256[] _rewardTotals,
        uint256[] rewardPerBlocks,
        bool enableInvite,
        uint256[] poolBasicInfos
    );

    /**
    矿池挖矿结束
    
    factory：factory合约
    poolId：矿池ID
     */
    event EndPool(address factory, uint256 poolId);

    /**
    质押

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    from：质押转出地址
    amount：质押数量
     */
    event Stake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed from,
        uint256 amount
    );

    /**
    算力

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    totalPower：矿池总算力
    owner：用户地址
    ownerInvitePower：用户邀请算力
    ownerStakePower：用户质押算力
    upper1：上1级地址
    upper1InvitePower：上1级邀请算力
    upper2：上2级地址
    upper2InvitePower：上2级邀请算力
     */
    event UpdatePower(
        address factory,
        uint256 poolId,
        address token,
        uint256 totalPower,
        address indexed owner,
        uint256 ownerInvitePower,
        uint256 ownerStakePower,
        address indexed upper1,
        uint256 upper1InvitePower,
        address indexed upper2,
        uint256 upper2InvitePower
    );

    /**
    解质押
    
    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    to：解质押转入地址
    amount：解质押数量
     */
    event UnStake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
    提取奖励

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    to：奖励转入地址
    inviteAmount：奖励数量
    stakeAmount：奖励数量
    benefitAmount: 平台抽成
     */
    event WithdrawReward(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 inviteAmount,
        uint256 stakeAmount,
        uint256 benefitAmount
    );

    /**
    挖矿

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    amount：奖励数量
     */
    event Mint(address factory, uint256 poolId, address indexed token, uint256 amount);

    /**
    当单位算力发放奖励为0时触发
    factory：factory合约
    poolId：矿池ID
    rewardTokens：挖矿奖励币种
    rewardPerShares：单位算力发放奖励数量
     */
    event RewardPerShareEvent(address factory, uint256 poolId, address[] indexed rewardTokens, uint256[] rewardPerShares);

    /**
    紧急提取奖励事件
    token：领取token合约地址
    to：领取地址
    amount：领取token数量
     */
    event SafeWithdraw(address indexed token, address indexed to, uint256 amount);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address internal constant ZERO = address(0);
    address public owner; //所有权限
    YouswapInviteV1 public invite; // contract

    uint256 poolCount; //矿池数量
    uint256[] poolIds; //矿池ID
    address internal platform; //平台，addPool权限
    mapping(uint256 => PoolViewInfo) internal poolViewInfos; //矿池可视化信息，poolID->PoolViewInfo
    mapping(uint256 => PoolStakeInfo) internal poolStakeInfos; //矿池质押信息，poolID->PoolStakeInfo
    mapping(uint256 => PoolRewardInfo[]) internal poolRewardInfos; //矿池奖励信息，poolID->PoolRewardInfo[]
    mapping(uint256 => mapping(address => UserStakeInfo)) internal userStakeInfos; //用户质押信息，poolID->user-UserStakeInfo

    mapping(address => uint256) public tokenPendingRewards; //现存token奖励数量，token-amount
    mapping(address => mapping(address => uint256)) internal userReceiveRewards; //用户已领取数量，token->user->amount
    mapping(uint256 => bool) public withdrawAllowed; //定期矿池能否领取奖励，default: false
    // mapping(uint256 => mapping(address => uint256)) public platformBenefits; //平台抽成数量

    //校验owner权限
    modifier onlyOwner() {
        require(owner == msg.sender, "YouSwapCore:FORBIDDEN_NOT_OWNER");
        _;
    }

    //校验platform权限
    modifier onlyPlatform() {
        require(platform == msg.sender, "YouSwap:FORBIDFORBIDDEN_NOT_PLATFORM");
        _;
    }

    /**
    @notice clone YouswapFactoryCore初始化
    @param _owner YouSwapFactory合约
    @param _platform FactoryCreator平台
    @param _invite clone邀请合约
    */
    function initialize(address _owner, address _platform, address _invite) external override {
        require(!initialized,  "YouSwapCore:ALREADY_INITIALIZED!");
        initialized = true;
        // deployBlock = block.number;
        owner = _owner;
        platform = _platform;
        invite = YouswapInviteV1(_invite);
    }

    /** 获取挖矿奖励结构 */
    function getPoolRewardInfo(uint256 poolId) external view override returns (PoolRewardInfo[] memory) {
        return poolRewardInfos[poolId];
    }

    /** 获取用户质押信息 */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (UserStakeInfo memory) {
        return userStakeInfos[poolId][user];
    }

    /** 获取矿池信息 */
    function getPoolStakeInfo(uint256 poolId) external view override returns (PoolStakeInfo memory) {
        return poolStakeInfos[poolId];
    }

    /** 获取矿池展示信息 */
    function getPoolViewInfo(uint256 poolId) external view override returns (PoolViewInfo memory) {
        return poolViewInfos[poolId];
    }

    /** 质押 */
    function stake(uint256 poolId, uint256 amount, address user) external onlyOwner override {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.add(1);
        }

        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (, uint256 startBlock) = invite.inviteUserInfoV2(user); //sender是否注册邀请关系
            if (0 == startBlock) {
                invite.register(); //sender注册邀请关系
                emit InviteRegister(user);
            }
            (upper1, upper2) = invite.inviteUpper2(user); //获取上2级邀请关系
        }

        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //计算单位算力奖励
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //给sender发放收益，给upper1，upper2增加待领取收益

        addPower(poolId, user, amount, poolStakeInfo.powerRatio, upper1, upper2); //增加sender，upper1，upper2算力
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //重置sender，upper1，upper2负债
        emit Stake(owner, poolId, poolStakeInfo.token, user, amount);
    }

    /** 矿池ID */
    function getPoolIds() external view override returns (uint256[] memory) {
        return poolIds;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    struct addPoolLocalVars {
        uint256 prePoolId;
        uint256 range;
        uint256 poolId;
        // bool action;
        uint256 startBlock;
        string name;
        bool enableInvite;
        address token;
        uint256 poolType;
        uint256 powerRatio;
        uint256 startTimeDelay;
        uint256 startTime;
        uint256 currentTime;
        uint256 priority;
        uint256 maxStakeAmount;
        uint256 lockSeconds;
        uint256 multiple;
        uint256 selfReward;
        uint256 invite1Reward;
        uint256 invite2Reward;
        bool isReopen;
    }

    /**
    新建矿池(prePoolId 为0) 
    重启矿池(prePoolId 非0)
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
    ) external override onlyOwner {
        addPoolLocalVars memory vars;
        vars.currentTime = block.timestamp;
        vars.prePoolId = prePoolId;
        vars.range = range;
        vars.name = name;
        vars.token = token;
        vars.enableInvite = enableInvite;
        vars.poolType = poolParams[0];
        vars.powerRatio = poolParams[1];
        vars.startTimeDelay = poolParams[2];
        vars.startTime = vars.startTimeDelay.add(vars.currentTime);
        vars.priority = poolParams[3];
        vars.maxStakeAmount = poolParams[4];
        vars.lockSeconds = poolParams[5];
        vars.multiple = poolParams[6];
        vars.selfReward = poolParams[7];
        vars.invite1Reward = poolParams[8];
        vars.invite2Reward = poolParams[9];

        if (vars.startTime <= vars.currentTime) { //开始时间是当前
            vars.startTime  = vars.currentTime;
            vars.startBlock = block.number;
        } else { //开始时间在未来
            vars.startBlock =  block.number.add(vars.startTimeDelay.div(3)); //预估的合法开始块高: heco: 3s，eth：13s
        }

        if (vars.prePoolId != 0) { //矿池重启
            vars.poolId = vars.prePoolId;
            vars.isReopen = true;
        } else { //新建矿池
            vars.poolId = poolCount.add(vars.range); //从1w开始
            poolIds.push(vars.poolId); //全部矿池ID
            poolCount = poolCount.add(1); //矿池总数量
            vars.isReopen = false;
        }

        PoolViewInfo storage poolViewInfo = poolViewInfos[vars.poolId]; //矿池可视化信息
        poolViewInfo.token = vars.token; //矿池质押token
        poolViewInfo.name = vars.name; //矿池名称
        poolViewInfo.multiple = vars.multiple; //矿池倍数
        if (0 < vars.priority) {
            poolViewInfo.priority = vars.priority; //矿池优先级
        } else {
            poolViewInfo.priority = poolIds.length.mul(100).add(75); //矿池优先级 //TODO
        }

        /********** 更新矿池质押信息 *********/
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[vars.poolId];
        poolStakeInfo.startBlock = vars.startBlock; //开始块高
        poolStakeInfo.startTime = vars.startTime; //开始时间
        poolStakeInfo.enableInvite = vars.enableInvite; //是否启用邀请关系
        poolStakeInfo.token = vars.token; //矿池质押token
        // poolStakeInfo.amount; //矿池质押数量，不要重置!!!
        // poolStakeInfo.participantCounts; //参与质押玩家数量，不要重置!!!
        poolStakeInfo.poolType = BaseStruct.PoolLockType(vars.poolType); //矿池类型
        poolStakeInfo.lockSeconds = vars.lockSeconds; //挖矿锁仓时间
        poolStakeInfo.lockUntil = vars.startTime.add(vars.lockSeconds); //锁仓持续时间
        poolStakeInfo.lastRewardBlock = vars.startBlock - 1;
        // poolStakeInfo.totalPower = 0; //矿池总算力，不要重置!!!
        poolStakeInfo.powerRatio = vars.powerRatio; //质押数量到算力系数
        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount; //最大质押数量
        poolStakeInfo.endBlock = 0; //矿池结束块高
        poolStakeInfo.endTime = 0; //矿池结束时间
        poolStakeInfo.selfReward = vars.selfReward; //质押自奖励
        poolStakeInfo.invite1Reward = vars.invite1Reward; //1级邀请奖励
        poolStakeInfo.invite2Reward = vars.invite2Reward; //2级邀请奖励
        poolStakeInfo.isReopen = vars.isReopen; //是否为重启矿池
        uint256 minRewardPerBlock = uint256(0) - uint256(1); //最小区块奖励

        bool existFlag;
        PoolRewardInfo[] storage _poolRewardInfosStorage = poolRewardInfos[vars.poolId];//重启后挖矿币种
        PoolRewardInfo[] memory _poolRewardInfosMemory = poolRewardInfos[vars.poolId]; //旧矿池挖矿币种

        for (uint256 i = 0; i < tokens.length; i++) {
            existFlag = false;
            tokenPendingRewards[tokens[i]] = tokenPendingRewards[tokens[i]].add(rewardTotals[i]);
            require(IERC20(tokens[i]).balanceOf(address(this)) >= tokenPendingRewards[tokens[i]], "YouSwapCore:BALANCE_INSUFFICIENT"); //奖励数量是否足额

            //对已有的挖矿奖励币种更新
            for (uint256 j = 0; j < _poolRewardInfosMemory.length; j++) {
                if (tokens[i] == _poolRewardInfosMemory[j].token) {
                    existFlag = true;
                    _poolRewardInfosStorage[j].rewardTotal = rewardTotals[i];
                    _poolRewardInfosStorage[j].rewardPerBlock = rewardPerBlocks[i];
                    _poolRewardInfosMemory[j].rewardPerBlock = rewardPerBlocks[i]; //为了计算最大质押
                    _poolRewardInfosStorage[j].rewardProvide = 0; //重置已发放奖励
                    // _poolRewardInfosStorage[j].rewardPerShare; //不要重置!!!
                }

                if (minRewardPerBlock > _poolRewardInfosMemory[j].rewardPerBlock) {
                    minRewardPerBlock = _poolRewardInfosMemory[j].rewardPerBlock;
                    poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
                    if (vars.maxStakeAmount < poolStakeInfo.maxStakeAmount) {
                        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount;
                    }
                }
            }

            //对新挖矿币种进行添加
            if (!existFlag) {
                PoolRewardInfo memory poolRewardInfo; //矿池奖励信息
                poolRewardInfo.token = tokens[i]; //奖励token
                poolRewardInfo.rewardTotal = rewardTotals[i]; //总奖励
                poolRewardInfo.rewardPerBlock = rewardPerBlocks[i]; //区块奖励，递减模式会每日按比例减少
                // poolRewardInfo.rewardProvide //默认为零
                // poolRewardInfo.rewardPerShare //默认为零
                poolRewardInfos[vars.poolId].push(poolRewardInfo);

                if (minRewardPerBlock > poolRewardInfo.rewardPerBlock) {
                    minRewardPerBlock = poolRewardInfo.rewardPerBlock;
                    poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
                    if (vars.maxStakeAmount < poolStakeInfo.maxStakeAmount) {
                        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount;
                    }
                }
            }
        }

        require(_poolRewardInfosStorage.length <= DefaultSettings.REWARD_TOKENTYPE_MAX, "YouSwap:REWARD_TOKEN_TYPE_REACH_MAX");
        sendUpdatePoolEvent(true, vars.poolId);
    }

    /**设置定期合约领取控制 */
    function setWithdrawAllowed(uint256 _poolId, bool _allowedState) external override onlyPlatform {
        withdrawAllowed[_poolId] = _allowedState;        
        sendUpdatePoolEvent(false, _poolId);//更新矿池信息事件
    }

    /**
    修改矿池名称
     */
    function setName(uint256 poolId, string memory name) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在
        poolViewInfo.name = name;//修改矿池名称
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    /** 修改矿池倍数 */
    function setMultiple(uint256 poolId, uint256 multiple) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在
        poolViewInfo.multiple = multiple;//修改矿池倍数
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    /** 修改矿池排序 */
    function setPriority(uint256 poolId, uint256 priority) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在
        poolViewInfo.priority = priority;//修改矿池排序
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(
        uint256 poolId,
        address token,
        uint256 rewardPerBlock
    ) external override onlyOwner {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        bool existFlag;
        // computeReward(poolId); //计算单位算力奖励
        uint256 minRewardPerBlock = uint256(0) - uint256(1); //最小区块奖励

        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                _poolRewardInfos[i].rewardPerBlock = rewardPerBlock; //修改矿池区块奖励
                sendUpdatePoolEvent(false, poolId); //更新矿池信息事件
                existFlag = true;
            } 
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }

        if (!existFlag) {
            // 新增币种逻辑
            PoolRewardInfo memory poolRewardInfo; //矿池奖励信息
            poolRewardInfo.token = token; //奖励token
            poolRewardInfo.rewardPerBlock = rewardPerBlock; //区块奖励
            _poolRewardInfos.push(poolRewardInfo);
            sendUpdatePoolEvent(false, poolId); //更新矿池信息事件

            if (minRewardPerBlock > rewardPerBlock) {
                minRewardPerBlock = rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
    }

    /** 修改矿池总奖励: 更新总奖励，更新剩余奖励(rewardTotal和rewardPerBlock都是增加，而非替换) */
    function setRewardTotal(
        uint256 poolId,
        address token,
        uint256 rewardTotal
    ) external override onlyOwner {
        // computeReward(poolId);//计算单位算力奖励
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        bool existFlag = false;

        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                existFlag = true;
                require(_poolRewardInfos[i].rewardProvide <= rewardTotal, "YouSwapCore:REWARDTOTAL_LESS_THAN_REWARDPROVIDE");//新总奖励是否超出已发放奖励
                tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal.sub(_poolRewardInfos[i].rewardTotal));//增加新旧差额，新总奖励一定大于旧总奖励
                _poolRewardInfos[i].rewardTotal = rewardTotal;//修改矿池总奖励
            } 
        }

        if (!existFlag) {
            //新币种
            tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal);
            PoolRewardInfo memory newPoolRewardInfo;
            newPoolRewardInfo.token = token;
            newPoolRewardInfo.rewardProvide = 0;
            newPoolRewardInfo.rewardPerShare = 0;
            newPoolRewardInfo.rewardTotal = rewardTotal;
            _poolRewardInfos.push(newPoolRewardInfo);
        }

        require(_poolRewardInfos.length <= DefaultSettings.REWARD_TOKENTYPE_MAX, "YouSwap:REWARD_TOKEN_TYPE_REACH_MAX");
        require(IERC20(token).balanceOf(address(this)) >= tokenPendingRewards[token], "YouSwapCore:BALANCE_INSUFFICIENT");//奖励数量是否足额
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyOwner {
        uint256 _maxStakeAmount;
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        uint256 minRewardPerBlock = uint256(0) - uint256(1);//最小区块奖励

        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                _maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
        require(poolStakeInfo.powerRatio <= maxStakeAmount && poolStakeInfo.amount <= maxStakeAmount && maxStakeAmount <= _maxStakeAmount, "YouSwapCore:MAX_STAKE_AMOUNT_INVALID");
        poolStakeInfo.maxStakeAmount = maxStakeAmount;
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /** 计算单位算力奖励 */
    function computeReward(uint256 poolId) internal returns (uint256[] memory) {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        uint256[] memory rewardPerShares = new uint256[](_poolRewardInfos.length);
        address[] memory rewardTokens = new address[](_poolRewardInfos.length);
        bool rewardPerShareZero;

        if (0 < poolStakeInfo.totalPower) {
            uint256 finishRewardCount;
            uint256 reward;
            uint256 blockCount;
            bool poolFinished;

            //矿池奖励发放完毕，新开一期
            if (block.number < poolStakeInfo.lastRewardBlock) {
                poolFinished = true;
            } else {
                blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //待发放的区块数量
            }
            for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
                PoolRewardInfo storage poolRewardInfo = _poolRewardInfos[i]; //矿池奖励信息
                reward = blockCount.mul(poolRewardInfo.rewardPerBlock); //两次快照之间总奖励

                if (poolRewardInfo.rewardProvide.add(reward) >= poolRewardInfo.rewardTotal) {
                    reward = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //核减超出奖励
                    finishRewardCount = finishRewardCount.add(1); //挖矿结束token计数
                }
                poolRewardInfo.rewardProvide = poolRewardInfo.rewardProvide.add(reward); //更新已发放奖励数量  
                poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(reward.mul(1e24).div(poolStakeInfo.totalPower)); //更新单位算力奖励
                if (0 == poolRewardInfo.rewardPerShare) {
                    rewardPerShareZero = true;
                }
                rewardPerShares[i] = poolRewardInfo.rewardPerShare;
                rewardTokens[i] = poolRewardInfo.token;
                if (0 < reward) {
                    emit Mint(owner, poolId, poolRewardInfo.token, reward); //挖矿事件
                }
            }

            if (!poolFinished) {
                poolStakeInfo.lastRewardBlock = block.number; //更新快照块高
            }

            if (finishRewardCount == _poolRewardInfos.length && !poolFinished) {
                poolStakeInfo.endBlock = block.number; //挖矿结束块高
                poolStakeInfo.endTime = block.timestamp; //结束时间
                emit EndPool(owner, poolId); //挖矿结束事件
            }
        } else {
            //最开始的时候
            for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
                rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
            }
        }

        if (rewardPerShareZero) {
            emit RewardPerShareEvent(owner, poolId, rewardTokens, rewardPerShares);
        }
        return rewardPerShares;
    }    

    /** 增加算力 */
    function addPower(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 powerRatio,
        address upper1,
        address upper2
    ) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //矿池质押信息
        poolStakeInfo.amount = poolStakeInfo.amount.add(amount); //更新矿池质押数量
        poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(power); //更新矿池总算力
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //sender质押信息
        userStakeInfo.amount = userStakeInfo.amount.add(amount); //更新sender质押数量
        userStakeInfo.stakePower = userStakeInfo.stakePower.add(power); //更新sender质押算力
        if (0 == userStakeInfo.startBlock) {
            userStakeInfo.startBlock = block.number; //挖矿开始块高
        }
        uint256 upper1InvitePower = 0; //upper1邀请算力
        uint256 upper2InvitePower = 0; //upper2邀请算力
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(poolStakeInfo.selfReward).div(100); //新增sender自邀请算力
            userStakeInfo.invitePower = userStakeInfo.invitePower.add(inviteSelfPower); //更新sender邀请算力
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(inviteSelfPower); //更新矿池总算力
            uint256 invite1Power = power.mul(poolStakeInfo.invite1Reward).div(100); //新增upper1邀请算力
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1]; //upper1质押信息
            upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.add(invite1Power); //更新upper1邀请算力
            upper1InvitePower = upper1StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite1Power); //更新矿池总算力
            if (0 == upper1StakeInfo.startBlock) {
                upper1StakeInfo.startBlock = block.number; //挖矿开始块高
            }
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(poolStakeInfo.invite2Reward).div(100); //新增upper2邀请算力
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2]; //upper2质押信息
            upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.add(invite2Power); //更新upper2邀请算力
            upper2InvitePower = upper2StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite2Power); //更新矿池总算力
            if (0 == upper2StakeInfo.startBlock) {
                upper2StakeInfo.startBlock = block.number; //挖矿开始块高
            }
        }
        emit UpdatePower(owner, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower); //更新算力事件
    }

    /** 减少算力 */
    function subPower(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 powerRatio,
        address upper1,
        address upper2
    ) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //矿池质押信息
        if (poolStakeInfo.amount <= amount) {
            poolStakeInfo.amount = 0; //减少矿池总质押数量
        } else {
            poolStakeInfo.amount = poolStakeInfo.amount.sub(amount); //减少矿池总质押数量
        }
        if (poolStakeInfo.totalPower <= power) {
            poolStakeInfo.totalPower = 0; //减少矿池总算力
        } else {
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(power); //减少矿池总算力
        }
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //sender质押信息
        userStakeInfo.amount = userStakeInfo.amount.sub(amount); //减少sender质押数量
        if (userStakeInfo.stakePower <= power) {
            userStakeInfo.stakePower = 0; //减少sender质押算力
        } else {
            userStakeInfo.stakePower = userStakeInfo.stakePower.sub(power); //减少sender质押算力
        }
        uint256 upper1InvitePower = 0;
        uint256 upper2InvitePower = 0;
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(poolStakeInfo.selfReward).div(100); //sender自邀请算力
            if (poolStakeInfo.totalPower <= inviteSelfPower) {
                poolStakeInfo.totalPower = 0; //减少矿池sender自邀请算力
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(inviteSelfPower); //减少矿池sender自邀请算力
            }
            if (userStakeInfo.invitePower <= inviteSelfPower) {
                userStakeInfo.invitePower = 0; //减少sender自邀请算力
            } else {
                userStakeInfo.invitePower = userStakeInfo.invitePower.sub(inviteSelfPower); //减少sender自邀请算力
            }
            uint256 invite1Power = power.mul(poolStakeInfo.invite1Reward).div(100); //upper1邀请算力
            if (poolStakeInfo.totalPower <= invite1Power) {
                poolStakeInfo.totalPower = 0; //减少矿池upper1邀请算力
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite1Power); //减少矿池upper1邀请算力
            }
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePower <= invite1Power) {
                upper1StakeInfo.invitePower = 0; //减少upper1邀请算力
            } else {
                upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.sub(invite1Power); //减少upper1邀请算力
            }
            upper1InvitePower = upper1StakeInfo.invitePower;
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(poolStakeInfo.invite2Reward).div(100); //upper2邀请算力
            if (poolStakeInfo.totalPower <= invite2Power) {
                poolStakeInfo.totalPower = 0; //减少矿池upper2邀请算力
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite2Power); //减少矿池upper2邀请算力
            }
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
            if (upper2StakeInfo.invitePower <= invite2Power) {
                upper2StakeInfo.invitePower = 0; //减少upper2邀请算力
            } else {
                upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.sub(invite2Power); //减少upper2邀请算力
            }
            upper2InvitePower = upper2StakeInfo.invitePower;
        }
        emit UpdatePower(owner, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower);
    }

    struct baseLocalVars {
        uint256 poolId;
        address user;
        address upper1;
        address upper2;
        uint256 reward;
        uint256 benefitAmount;
        uint256 remainAmount;
        uint256 newBenefit;
    }

    /** 给sender发放收益，给upper1，upper2增加待领取收益 */
    function provideReward(
        uint256 poolId,
        uint256[] memory rewardPerShares,
        address user,
        address upper1,
        address upper2
    ) internal {
        baseLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        vars.upper1 = upper1;
        vars.upper2 = upper2;
        uint256 inviteReward = 0;
        uint256 stakeReward = 0;
        uint256 rewardPerShare = 0;
        address token;

        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[vars.poolId];
        UserStakeInfo storage userStakeInfo = userStakeInfos[vars.poolId][vars.user];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[vars.poolId];

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            token = _poolRewardInfos[i].token; //挖矿奖励token
            rewardPerShare = rewardPerShares[i]; //单位算力奖励系数

            inviteReward = userStakeInfo.invitePower.mul(rewardPerShare).sub(userStakeInfo.inviteRewardDebts[i]).div(1e24); //邀请奖励
            stakeReward = userStakeInfo.stakePower.mul(rewardPerShare).sub(userStakeInfo.stakeRewardDebts[i]).div(1e24); //质押奖励

            inviteReward = userStakeInfo.invitePendingRewards[i].add(inviteReward); //待领取奖励
            stakeReward = userStakeInfo.stakePendingRewards[i].add(stakeReward); //待领取奖励
            vars.reward = inviteReward.add(stakeReward);

            if (0 < vars.reward) {
                userStakeInfo.invitePendingRewards[i] = 0; //重置待领取奖励
                userStakeInfo.stakePendingRewards[i] = 0; //重置待领取奖励
                userReceiveRewards[token][vars.user] = userReceiveRewards[token][vars.user].add(vars.reward); //增加已领取奖励

                if ((poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED)
                    && (block.timestamp >= poolStakeInfo.startTime && block.timestamp <= poolStakeInfo.lockUntil && !withdrawAllowed[vars.poolId])) {
                        userStakeInfo.invitePendingRewards[i] = inviteReward; //在锁仓阶段，如果不允许领取，不发放奖励
                        userStakeInfo.stakePendingRewards[i] = stakeReward; //在锁仓阶段，如果不允许领取，不发放奖励
                } else {
                    userStakeInfo.inviteClaimedRewards[i] = userStakeInfo.inviteClaimedRewards[i].add(inviteReward);
                    userStakeInfo.stakeClaimedRewards[i] = userStakeInfo.stakeClaimedRewards[i].add(stakeReward);
                    tokenPendingRewards[token] = tokenPendingRewards[token].sub(vars.reward); //减少奖励总额
                    IERC20(token).safeTransfer(vars.user, vars.reward); //发放奖励
                    emit WithdrawReward(owner, vars.poolId, token, vars.user, inviteReward, stakeReward, 0);
                }
            }

            if (ZERO != vars.upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[vars.poolId][vars.upper1];
                if ((0 < upper1StakeInfo.invitePower) || (0 < upper1StakeInfo.stakePower)) {
                    inviteReward = upper1StakeInfo.invitePower.mul(rewardPerShare).sub(upper1StakeInfo.inviteRewardDebts[i]).div(1e24); //邀请奖励
                    stakeReward = upper1StakeInfo.stakePower.mul(rewardPerShare).sub(upper1StakeInfo.stakeRewardDebts[i]).div(1e24); //质押奖励
                    upper1StakeInfo.invitePendingRewards[i] = upper1StakeInfo.invitePendingRewards[i].add(inviteReward); //待领取奖励
                    upper1StakeInfo.stakePendingRewards[i] = upper1StakeInfo.stakePendingRewards[i].add(stakeReward); //待领取奖励
                }
            }
            if (ZERO != vars.upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[vars.poolId][vars.upper2];
                if ((0 < upper2StakeInfo.invitePower) || (0 < upper2StakeInfo.stakePower)) {
                    inviteReward = upper2StakeInfo.invitePower.mul(rewardPerShare).sub(upper2StakeInfo.inviteRewardDebts[i]).div(1e24); //邀请奖励
                    stakeReward = upper2StakeInfo.stakePower.mul(rewardPerShare).sub(upper2StakeInfo.stakeRewardDebts[i]).div(1e24); //质押奖励
                    upper2StakeInfo.invitePendingRewards[i] = upper2StakeInfo.invitePendingRewards[i].add(inviteReward); //待领取奖励
                    upper2StakeInfo.stakePendingRewards[i] = upper2StakeInfo.stakePendingRewards[i].add(stakeReward); //待领取奖励
                }
            }
        }
    }

    /** 重置负债 */
    function setRewardDebt(
        uint256 poolId,
        uint256[] memory rewardPerShares,
        address user,
        address upper1,
        address upper2
    ) internal {
        uint256 rewardPerShare;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];

        for (uint256 i = 0; i < rewardPerShares.length; i++) {
            rewardPerShare = rewardPerShares[i]; //单位算力奖励系数
            userStakeInfo.inviteRewardDebts[i] = userStakeInfo.invitePower.mul(rewardPerShare); //重置sender邀请负债
            userStakeInfo.stakeRewardDebts[i] = userStakeInfo.stakePower.mul(rewardPerShare); //重置sender质押负债

            if (ZERO != upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
                upper1StakeInfo.inviteRewardDebts[i] = upper1StakeInfo.invitePower.mul(rewardPerShare); //重置upper1邀请负债
                upper1StakeInfo.stakeRewardDebts[i] = upper1StakeInfo.stakePower.mul(rewardPerShare); //重置upper1质押负债
                if (ZERO != upper2) {
                    UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                    upper2StakeInfo.inviteRewardDebts[i] = upper2StakeInfo.invitePower.mul(rewardPerShare); //重置upper2邀请负债
                    upper2StakeInfo.stakeRewardDebts[i] = upper2StakeInfo.stakePower.mul(rewardPerShare); //重置upper2质押负债
                }
            }
        }
    }

    /** 矿池信息更新事件 */
    function sendUpdatePoolEvent(bool action, uint256 poolId) internal {
        PoolViewInfo memory poolViewInfo = poolViewInfos[poolId];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        address[] memory tokens = new address[](_poolRewardInfos.length);
        uint256[] memory _rewardTotals = new uint256[](_poolRewardInfos.length);
        uint256[] memory rewardPerBlocks = new uint256[](_poolRewardInfos.length);

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            tokens[i] = _poolRewardInfos[i].token;
            _rewardTotals[i] = _poolRewardInfos[i].rewardTotal;
            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
        }

        uint256[] memory poolBasicInfos = new uint256[](11);
        poolBasicInfos[0] = poolViewInfo.multiple;
        poolBasicInfos[1] = poolViewInfo.priority;
        poolBasicInfos[2] = poolStakeInfo.powerRatio;
        poolBasicInfos[3] = poolStakeInfo.maxStakeAmount;
        poolBasicInfos[4] = uint256(poolStakeInfo.poolType);
        poolBasicInfos[5] = poolStakeInfo.lockSeconds;
        poolBasicInfos[6] = poolStakeInfo.selfReward;
        poolBasicInfos[7] = poolStakeInfo.invite1Reward;
        poolBasicInfos[8] = poolStakeInfo.invite2Reward;
        poolBasicInfos[9] = poolStakeInfo.startTime;
        poolBasicInfos[10] = withdrawAllowed[poolId] ? 1: 0; //是否允许领取奖励

        emit UpdatePool(
            action,
            owner,
            poolId,
            poolViewInfo.name,
            poolStakeInfo.token,
            poolStakeInfo.startBlock,
            tokens,
            _rewardTotals,
            rewardPerBlocks,
            poolStakeInfo.enableInvite,
            poolBasicInfos
        );
    }

    /**
    解质押
     */
    function _unStake(uint256 poolId, uint256 amount, address user) override onlyOwner external {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (upper1, upper2) = invite.inviteUpper2(user);
        }
        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //计算单位算力奖励系数
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //给sender发放收益，给upper1，upper2增加待领取收益
        subPower(poolId, user, amount, poolStakeInfo.powerRatio, upper1, upper2); //减少算力

        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 != poolStakeInfo.startBlock && 0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.sub(1);
        }
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //重置sender，upper1，upper2负债
        IERC20(poolStakeInfo.token).safeTransfer(user, amount); //解质押token
        emit UnStake(owner, poolId, poolStakeInfo.token, user, amount);
    }

    function _withdrawReward(uint256 poolId, address user) override onlyOwner external {
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.startBlock) {
            return; //user未质押，未邀请
        }

        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        // if (poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED) { //锁仓类型
        //     if (block.timestamp <= poolStakeInfo.lockUntil && block.timestamp >= poolStakeInfo.startTime) { //在锁仓阶段，未抛异常，便于一键领取奖励
        //         if (!withdrawAllowed[poolId]) {
        //             return;
        //         }
        //     }
        // }

        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (upper1, upper2) = invite.inviteUpper2(user);
        }

        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //计算单位算力奖励系数
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //给sender发放收益，给upper1，upper2增加待领取收益
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //重置sender，upper1，upper2负债
    }

    function initRewardInfo(
        uint256 poolId,
        address user,
        address upper1,
        address upper2
    ) internal {
        uint256 count = poolRewardInfos[poolId].length;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];

        if (userStakeInfo.invitePendingRewards.length != count) {
            require(count >= userStakeInfo.invitePendingRewards.length, "YouSwap:INITREWARD_INFO_COUNT_ERROR");
            uint256 offset = count.sub(userStakeInfo.invitePendingRewards.length);
            for (uint256 i = 0; i < offset; i++) {
                userStakeInfo.invitePendingRewards.push(0); //初始化待领取数量
                userStakeInfo.stakePendingRewards.push(0); //初始化待领取数量
                userStakeInfo.inviteRewardDebts.push(0); //初始化邀请负债
                userStakeInfo.stakeRewardDebts.push(0); //初始化质押负债
                userStakeInfo.inviteClaimedRewards.push(0); //已领取邀请奖励
                userStakeInfo.stakeClaimedRewards.push(0); //已领取质押奖励
            }
        }
        if (ZERO != upper1) {
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePendingRewards.length != count) {
                uint256 offset = count.sub(upper1StakeInfo.invitePendingRewards.length);
                for (uint256 i = 0; i < offset; i++) {
                    upper1StakeInfo.invitePendingRewards.push(0); //初始化待领取数量
                    upper1StakeInfo.stakePendingRewards.push(0); //初始化待领取数量
                    upper1StakeInfo.inviteRewardDebts.push(0); //初始化邀请负债
                    upper1StakeInfo.stakeRewardDebts.push(0); //初始化质押负债
                    upper1StakeInfo.inviteClaimedRewards.push(0); //已领取邀请奖励
                    upper1StakeInfo.stakeClaimedRewards.push(0); //已领取质押奖励
                }
            }
            if (ZERO != upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                if (upper2StakeInfo.invitePendingRewards.length != count) {
                    uint256 offset = count.sub(upper2StakeInfo.invitePendingRewards.length);
                    for (uint256 i = 0; i < offset; i++) {
                        upper2StakeInfo.invitePendingRewards.push(0); //初始化待领取数量
                        upper2StakeInfo.stakePendingRewards.push(0); //初始化待领取数量
                        upper2StakeInfo.inviteRewardDebts.push(0); //初始化邀请负债
                        upper2StakeInfo.stakeRewardDebts.push(0); //初始化质押负债
                        upper2StakeInfo.inviteClaimedRewards.push(0); //已领取邀请奖励
                        upper2StakeInfo.stakeClaimedRewards.push(0); //已领取质押奖励
                    }
                }
            }
        }
    }

    /**交易矿池id有效性 */
    function checkPIDValidation(uint256 _poolId) external view override {
        PoolStakeInfo memory poolStakeInfo = this.getPoolStakeInfo(_poolId);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START"); //是否开启挖矿
    }

    /** 更新结束时间 */
    function refresh(uint256 _poolId) external override {
        computeReward(_poolId);
    }

    /** 紧急转移token */
    function safeWithdraw(address token, address to, uint256 amount) override external onlyPlatform {
        require(IERC20(token).balanceOf(address(this)) >= amount, "YouSwap:BALANCE_INSUFFICIENT");
        IERC20(token).safeTransfer(to, amount);//紧急转移资产到to地址
        emit SafeWithdraw(token, to, amount);
    }
}