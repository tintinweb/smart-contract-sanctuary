/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

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

// File: localhost/contract/interface/IYouswapInviteV1.sol

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
    
    function inviteBatch(address[] memory) external returns (uint, uint);//注册邀请关系：输入数量，成功数量

}
// File: localhost/contract/implement/YouswapInviteV1.sol

pragma solidity 0.7.4;



contract YouswapInviteV1 is IYouswapInviteV1 {

    address public constant zero = address(0);
    uint256 public startBlock;
    address[] public inviteUserInfoV1;
    mapping(address => UserInfo) public inviteUserInfoV2;

    constructor () {
        startBlock = block.number;
    }
    
    function inviteCount() override external view returns (uint256) {
        return inviteUserInfoV1.length;
    }

    function inviteUpper1(address _owner) override external view returns (address) {
        return inviteUserInfoV2[_owner].upper;
    }

    function inviteUpper2(address _owner) override external view returns (address, address) {
        address upper1 = inviteUserInfoV2[_owner].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfoV2[upper1].upper;
        }

        return (upper1, upper2);
    }

    function inviteLower1(address _owner) override external view returns (address[] memory) {
        return inviteUserInfoV2[_owner].lowers;
    }

    function inviteLower2(address _owner) override external view returns (address[] memory, address[] memory) {
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

    function inviteLower2Count(address _owner) override external view returns (uint256, uint256) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 lowers2Len = 0;
        uint256 len = lowers1.length;
        for (uint256 i = 0; i < len; i++) {
            lowers2Len += inviteUserInfoV2[lowers1[i]].lowers.length;
        }
        
        return (lowers1.length, lowers2Len);
    }

    function register() override external returns (bool) {
        UserInfo storage user = inviteUserInfoV2[tx.origin];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        user.upper = zero;
        user.startBlock = block.number;
        inviteUserInfoV1.push(tx.origin);
        
        emit InviteV1(tx.origin, user.upper, user.startBlock);
        
        return true;
    }

    function acceptInvitation(address _inviter) override external returns (bool) {
        require(msg.sender != _inviter, ErrorCode.FORBIDDEN);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        UserInfo storage upper = inviteUserInfoV2[_inviter];
        if (0 == upper.startBlock) {
            upper.upper = zero;
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

    function inviteBatch(address[] memory _invitees) override external returns (uint, uint) {
        uint len = _invitees.length;
        require(len <= 100, ErrorCode.PARAMETER_TOO_LONG);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        if (0 == user.startBlock) {
            user.upper = zero;
            user.startBlock = block.number;
            inviteUserInfoV1.push(msg.sender);
                        
            emit InviteV1(msg.sender, user.upper, user.startBlock);
        }
        uint count = 0;
        for (uint i = 0; i < len; i++) {
            if ((address(0) != _invitees[i]) && (msg.sender != _invitees[i])) {
                UserInfo storage lower = inviteUserInfoV2[_invitees[i]];
                if (0 == lower.startBlock) {
                    lower.upper = msg.sender;
                    lower.startBlock = block.number;
                    user.lowers.push(_invitees[i]);
                    inviteUserInfoV1.push(_invitees[i]);
                    count++;

                    emit InviteV1(_invitees[i], msg.sender, lower.startBlock);
                }
            }
        }

        return (len, count);
    }

}
// File: localhost/contract/library/ErrorCode.sol

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

}
// File: localhost/contract/interface/IYouswapPoolV1.sol

pragma solidity 0.7.4;

interface IYouswapPoolV1 {

    function initialize(address) external;

}
// File: localhost/contract/implement/YouswapPoolV1.sol

pragma solidity 0.7.4;



contract YouswapPoolV1 is IYouswapPoolV1 {

    address public factory;
    address public pool;
    address public lp;
    
    constructor() {
        factory = msg.sender;
        pool = address(this);
    }

    function initialize(address _lp) override external {
        require(factory == msg.sender, ErrorCode.FORBIDDEN);
        require((factory != _lp) && (pool != _lp), ErrorCode.FORBIDDEN);
        lp = _lp;
    }

}
// File: localhost/contract/interface/ITokenYou.sol

pragma solidity 0.7.4;

interface ITokenYou {
    
    function mint(address recipient, uint256 amount) external;
    
    function decimals() external view returns (uint8);
    
}

// File: localhost/contract/interface/IYouswapFactoryV1.sol

pragma solidity 0.7.4;


/**
挖矿
 */
interface IYouswapFactoryV1 {
    
    /**
    质押用户信息
     */
    struct UserInfo {
        uint256 startBlock;//质押开始块高
        uint256 amount;//质押数量
        uint256 invitePower;//邀请算力
        uint256 pledgePower;//质押算力
        uint256 inviteReward;//总邀请奖励
        uint256 pledgeReward;//总质押奖励
        uint256 inviteRewardDebt;//邀请负债
        uint256 pledgeRewardDebt;//质押负债
    }

    /**
    矿池信息（可视化）
     */
    struct PoolViewInfo {
        address lp;//LP地址
        string name;//名称
        uint256 multiple;//奖励倍数
        uint256 sort;//排序
    }

    /**
    矿池信息
     */
    struct PoolInfo {
        uint256 startBlock;//挖矿开始块高
        uint256 rewardTotal;//矿池总奖励
        uint256 rewardProvide;//矿池已发放奖励
        address lp;//LP地址
        uint256 amount;//质押数量
        uint256 lastRewardBlock;//最后发放奖励块高
        uint256 inviteSelfReward;//邀请自奖励
        uint256 invite1Reward;//1级邀请奖励系数
        uint256 invite2Reward;//2级邀请奖励系数
        uint256 rewardPerBlock;//单个区块奖励
        uint256 totalPower;//总算力
        uint256 endBlock;//挖矿结束块高
        uint256 rewardPerShare;//单位算力奖励
    }

    ////////////////////////////////////////////////////////////////////////////////////
    
    /**
    更新矿池信息

    action：true(新建矿池)，false(更新矿池)
    pool：矿池合约地址
    lp：lp合约地址
    name：矿池名称
    startBlock：矿池开始挖矿块高
    rewardTotal：矿池总奖励
    rewardPerBlock：区块奖励
    multiple：矿池奖励倍数
    sort：矿池排序
     */
    event UpdatePool(bool action, address pool, address lp, string name, uint256 startBlock, uint256 rewardTotal, uint256 rewardPerBlock, uint256 multiple, uint256 sort);

    /**
    矿池挖矿结束
    
    pool：矿池合约地址
    lp：lp合约地址
     */
    event EndPool(address pool, address lp);
    
    /**
    质押

    pool：矿池合约地址
    lp：lp合约地址
    from：质押转出地址
    to：质押转入地址
    amount：质押数量
     */
    event Stake(address pool, address lp, address from, address to, uint256 amount);
    
    /**
    解质押
    
    pool：矿池合约地址
    lp：lp合约地址
    from：解质押转出地址
    to：解质押转入地址
    amount：解质押数量
     */
    event WithdrawLP(address pool, address lp, address from, address to, uint256 amount);
    
    /**
    提取奖励

    pool：矿池合约地址
    lp：lp合约地址
    token：奖励合约地址
    from：奖励转出地址
    to：奖励转入地址
    amount：奖励数量
     */
    event WithdrawReward(address pool, address lp, address token, address from, address to, uint256 amount);
    
    /**
    挖矿

    pool：矿池合约地址    
    lp：lp合约地址
    token：奖励合约地址
    amount：奖励数量
     */
    event Mint(address pool, address lp, address token, uint256 amount);
    
    ////////////////////////////////////////////////////////////////////////////////////

    /**
    修改OWNER
     */
    function transferOwnership(address) external;

    /**
    设置YOU
     */
    function setYou(ITokenYou) external;
    
    /**
    矿池数量
     */
    function poolCount() external view returns (uint256);

    /**
    质押
    */
    function deposit(address, uint256) external;
    
    /**
    解质押、提取奖励
     */
    function withdraw(address, uint256) external;

    /**
    矿池质押地址
     */
    function poolPledgeAddresss(address) external view returns (address[] memory);

    /**
    矿池地址
     */
    function getPoolAddress() external view returns (address[] memory);

    /**
    计算奖励
     */
    function computeReward(address) external;

    /**
    算力占比
     */
    function powerScale(address, address) external view returns (uint256);

    /**
    设置运营权限
     */
    function setOperateOwner(address, bool) external;

    ////////////////////////////////////////////////////////////////////////////////////    
    
    /**
    新建矿池
     */
    function addPool(string memory, address, uint256, uint256) external returns (address);
    
    /**
    修改矿池邀请自奖励系数
     */
    function setInviteSelfReward(address, uint256) external;
    
    /**
    修改矿池1级邀请奖励系数
     */
    function setInvite1Reward(address, uint256) external;

    /**
    修改矿池2级邀请奖励系数
     */
    function setInvite2Reward(address, uint256) external;
    
    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(address, uint256) external;

    /**
    修改矿池总奖励
     */
    function setRewardTotal(address, uint256) external;

    /**
    修改矿池名称
     */
    function setName(address, string memory) external;
    
    /**
    修改矿池倍数
     */
    function setMultiple(address, uint256) external;
    
    /**
    修改矿池排序
     */
    function setSort(address, uint256) external;
    
    ////////////////////////////////////////////////////////////////////////////////////
    
    /**
    当前块高
     */
    function blockNumber() external view returns (uint256);

    function erc20Allowance(address, address, address) external returns (uint256);

    function erc20Balance(address, address) external view returns (uint256);

    function erc20Supply(address) external view returns (uint256);

    ////////////////////////////////////////////////////////////////////////////////////
}
// File: localhost/contract/implement/YouswapFactoryV1.sol

pragma solidity 0.7.4;







contract YouswapFactoryV1 is IYouswapFactoryV1 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant zero = address(0);
    address public owner;//所有权限
    address public thisAddress = address(0);//this contract address
    mapping(address => bool) public operateOwner;//运营权限
    ITokenYou public you;//you contract
    address public youAddress;//you contract address
    YouswapInviteV1 public invite;//invite contract

    address[] public poolAddress;//矿池地址
    mapping(address => PoolInfo) public poolInfo;//矿池信息
    mapping(address => PoolViewInfo) public poolViewInfo;//矿池信息
    mapping(address => address[]) public pledgeAddresss;//矿池质押地址
    mapping(address => mapping(address => UserInfo)) public pledgeUserInfo;//矿池质押用户信息

    uint256 public inviteSelfReward = 5;//质押资奖励，5%
    uint256 public invite1Reward = 15;//1级邀请奖励，15%
    uint256 public invite2Reward = 10;//2级邀请奖励，10%
    uint256 public rewardPerBlock = 0;//块奖励，40个you
    uint256 public rewardTotal = 0;//总挖矿奖励

    constructor (ITokenYou _you, YouswapInviteV1 _invite) {
        owner = msg.sender;
        thisAddress = address(this);
        invite = _invite;
        _setOperateOwner(owner, true);
        _setYou(_you);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function transferOwnership(address _owner) override external {
        require(owner == msg.sender, ErrorCode.FORBIDDEN);
        require((address(0) != _owner) && (owner != _owner), ErrorCode.INVALID_ADDRESSES);
        address oldOwner = owner;
        owner = _owner;
        _setOperateOwner(oldOwner, false);
        _setOperateOwner(owner, true);
    }

    function setYou(ITokenYou _you) override external {
        _setYou(_you);
    }
    
    function _setYou(ITokenYou _you) internal {
        require(owner == msg.sender, ErrorCode.FORBIDDEN);
        you = _you;
        youAddress = address(_you);
        rewardPerBlock = 40*(10**_you.decimals());
    }        

    function poolCount() override external view returns (uint256) {
        return poolAddress.length;
    }

    function deposit(address _pool, uint256 _amount) override external {
        require(0 < _amount, ErrorCode.FORBIDDEN);
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (_poolInfo.startBlock <= block.number)) {
            (address up, uint256 startBlock) = invite.inviteUserInfoV2(msg.sender);
            if (0 == startBlock) {
                invite.register();
                up = address(0);
            }

            IERC20(_poolInfo.lp).safeTransferFrom(msg.sender, thisAddress, _amount);

            (address _upper1, address _upper2) = invite.inviteUpper2(msg.sender);

            this.computeReward(_pool);

            provideReward(_pool, msg.sender, _upper1, _upper2);

            addPower(_pool, msg.sender, _amount, _upper1, _upper2);

            resetRewardDebt(_pool, msg.sender, _upper1, _upper2);

            emit Stake(_pool, _poolInfo.lp, msg.sender, thisAddress, _amount);
        }
    }

    function withdraw(address _pool, uint256 _amount) override external {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (_poolInfo.startBlock <= block.number)) {                        
            if (0 < _amount) {
                UserInfo storage _userInfo = pledgeUserInfo[_pool][msg.sender];
                require(_amount <= _userInfo.amount, ErrorCode.BALANCE_INSUFFICIENT);
                IERC20(_poolInfo.lp).safeTransfer(msg.sender, _amount);

                emit WithdrawLP(_pool, _poolInfo.lp, thisAddress, msg.sender, _amount);
            }

            (address _upper1, address _upper2) = invite.inviteUpper2(msg.sender);

            this.computeReward(_pool);

            provideReward(_pool, msg.sender, _upper1, _upper2);
            
            subPower(_pool, msg.sender, _amount, _upper1, _upper2);

            resetRewardDebt(_pool, msg.sender, _upper1, _upper2);
        }
    }

    function poolPledgeAddresss(address _pool) override external view returns (address[] memory) {
        return pledgeAddresss[_pool];
    }

    function getPoolAddress() override external view returns (address[] memory) {
        return poolAddress;
    }

    function computeReward(address _pool) override external {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (_poolInfo.lastRewardBlock < block.number) && (0 < _poolInfo.totalPower) && (_poolInfo.rewardProvide < _poolInfo.rewardTotal)) {
            uint256 reward = (block.number - _poolInfo.lastRewardBlock).mul(_poolInfo.rewardPerBlock);
            if ((_poolInfo.rewardTotal.sub(_poolInfo.rewardProvide)) < reward) {
                reward = _poolInfo.rewardTotal.sub(_poolInfo.rewardProvide);
                _poolInfo.endBlock = block.number;

                emit EndPool(_pool, _poolInfo.lp);
            }

            rewardTotal = rewardTotal.add(reward);
            _poolInfo.rewardProvide = _poolInfo.rewardProvide.add(reward);
            _poolInfo.rewardPerShare = _poolInfo.rewardPerShare.add(reward.mul(1e12).div(_poolInfo.totalPower));
            _poolInfo.lastRewardBlock = block.number;

            emit Mint(_pool, _poolInfo.lp, youAddress, reward);
        }
    }

    function addPower(address _pool, address _user, uint256 _amount, address _upper1, address _upper2) internal {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if (address(0) != _poolInfo.lp && (_poolInfo.startBlock <= block.number)) {
            _poolInfo.amount = _poolInfo.amount.add(_amount);

            uint256 pledgePower = _amount;
            uint256 inviteSelfPower = pledgePower.mul(_poolInfo.inviteSelfReward).div(100);
            UserInfo storage _userInfo = pledgeUserInfo[_pool][_user];            
            _userInfo.amount = _userInfo.amount.add(_amount);
            _userInfo.invitePower = _userInfo.invitePower.add(inviteSelfPower);
            _userInfo.pledgePower = _userInfo.pledgePower.add(pledgePower);
            _poolInfo.totalPower = _poolInfo.totalPower.add(inviteSelfPower);
            _poolInfo.totalPower = _poolInfo.totalPower.add(pledgePower);
            if (0 == _userInfo.startBlock) {
                _userInfo.startBlock = block.number;
                pledgeAddresss[_pool].push(msg.sender);
            }
            
            if (address(0) != _upper1) {
                uint256 invite1Power = pledgePower.mul(_poolInfo.invite1Reward).div(100);
                UserInfo storage _upper1Info = pledgeUserInfo[_pool][_upper1];            
                _upper1Info.invitePower = _upper1Info.invitePower.add(invite1Power);
                _poolInfo.totalPower = _poolInfo.totalPower.add(invite1Power);
                if (0 == _upper1Info.startBlock) {
                    _upper1Info.startBlock = block.number;
                    pledgeAddresss[_pool].push(_upper1);
                }
                
                if (address(0) != _upper2) {
                    uint256 invite2Power = pledgePower.mul(_poolInfo.invite2Reward).div(100);
                    UserInfo storage _upper2Info = pledgeUserInfo[_pool][_upper2];            
                    _upper2Info.invitePower = _upper2Info.invitePower.add(invite2Power);
                    _poolInfo.totalPower = _poolInfo.totalPower.add(invite2Power);
                    if (0 == _upper2Info.startBlock) {
                        _upper2Info.startBlock = block.number;
                        pledgeAddresss[_pool].push(_upper2);
                    }
                }
            }
        }
    }

    function subPower(address _pool, address _user, uint256 _amount, address _upper1, address _upper2) internal {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if (address(0) != _poolInfo.lp && (_poolInfo.startBlock <= block.number)) {
            UserInfo storage _userInfo = pledgeUserInfo[_pool][_user];            
            if (0 < _userInfo.startBlock) {
                _poolInfo.amount = _poolInfo.amount.sub(_amount);

                uint256 pledgePower = _amount.mul(100);
                uint256 inviteSelfPower = pledgePower.mul(_poolInfo.inviteSelfReward).div(100);
                _userInfo.amount = _userInfo.amount.sub(_amount);
                _userInfo.invitePower = _userInfo.invitePower.sub(inviteSelfPower);
                _userInfo.pledgePower = _userInfo.pledgePower.sub(pledgePower);
                _poolInfo.totalPower = _poolInfo.totalPower.sub(inviteSelfPower);
                _poolInfo.totalPower = _poolInfo.totalPower.sub(pledgePower);

                if (address(0) != _upper1) {
                    UserInfo storage _upper1Info = pledgeUserInfo[_pool][_upper1];
                    if (0 < _upper1Info.startBlock) {
                        uint256 invite1Power = pledgePower.mul(_poolInfo.invite1Reward).div(100);
                        _upper1Info.invitePower = _upper1Info.invitePower.sub(invite1Power);
                        _poolInfo.totalPower = _poolInfo.totalPower.sub(invite1Power);

                        if (address(0) != _upper2) {
                            UserInfo storage _upper2Info = pledgeUserInfo[_pool][_upper2];
                            if (0 < _upper2Info.startBlock) {
                                uint256 invite2Power = pledgePower.mul(_poolInfo.invite2Reward).div(100);
                                _upper2Info.invitePower = _upper2Info.invitePower.sub(invite2Power);
                                _poolInfo.totalPower = _poolInfo.totalPower.sub(invite2Power);
                            }
                        }
                    }
                }
            }
        }
    }

    function provideReward(address _pool, address _user, address _upper1, address _upper2) internal {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if (address(0) != _poolInfo.lp && (_poolInfo.startBlock <= block.number)) {
            uint256 reward = 0;
            uint256 inviteReward = 0;
            uint256 pledgeReward = 0;
            UserInfo storage _userInfo = pledgeUserInfo[_pool][_user];
            if ((0 < _userInfo.invitePower) || (0 < _userInfo.pledgePower)) {
                inviteReward = _userInfo.invitePower.mul(_poolInfo.rewardPerShare).sub(_userInfo.inviteRewardDebt).div(1e12);
                pledgeReward = _userInfo.pledgePower.mul(_poolInfo.rewardPerShare).sub(_userInfo.pledgeRewardDebt).div(1e12);
                
                _userInfo.inviteReward = _userInfo.inviteReward.add(inviteReward);
                _userInfo.pledgeReward = _userInfo.pledgeReward.add(pledgeReward);

                _userInfo.inviteRewardDebt = 0;
                _userInfo.pledgeRewardDebt = 0;

                reward = inviteReward.add(pledgeReward);
                if (0 < reward) {
                    you.mint(_user, reward);

                    emit WithdrawReward(_pool, _poolInfo.lp, youAddress, zero, _user, reward);
                }
            }

            if (address(0) != _upper1) {
                UserInfo storage _upper1Info = pledgeUserInfo[_pool][_upper1];
                if ((0 < _upper1Info.invitePower) || (0 < _upper1Info.pledgePower)) {
                    inviteReward = _upper1Info.invitePower.mul(_poolInfo.rewardPerShare).sub(_upper1Info.inviteRewardDebt).div(1e12);
                    pledgeReward = _upper1Info.pledgePower.mul(_poolInfo.rewardPerShare).sub(_upper1Info.pledgeRewardDebt).div(1e12);

                    _upper1Info.inviteReward = _upper1Info.inviteReward.add(inviteReward);
                    _upper1Info.pledgeReward = _upper1Info.pledgeReward.add(pledgeReward);
                    
                    _upper1Info.inviteRewardDebt = 0;
                    _upper1Info.pledgeRewardDebt = 0;
                
                    reward = inviteReward.add(pledgeReward);
                    if (0 < reward) {
                        you.mint(_upper1, reward);

                        emit WithdrawReward(_pool, _poolInfo.lp, youAddress, zero, _upper1, reward);
                    }
                }

                if (address(0) != _upper2) {
                    UserInfo storage _upper2Info = pledgeUserInfo[_pool][_upper2];
                    if ((0 < _upper2Info.invitePower) || (0 < _upper2Info.pledgePower)) {
                        inviteReward = _upper2Info.invitePower.mul(_poolInfo.rewardPerShare).sub(_upper2Info.inviteRewardDebt).div(1e12);
                        pledgeReward = _upper2Info.pledgePower.mul(_poolInfo.rewardPerShare).sub(_upper2Info.pledgeRewardDebt).div(1e12);

                        _upper2Info.inviteReward = _upper2Info.inviteReward.add(inviteReward);
                        _upper2Info.pledgeReward = _upper2Info.pledgeReward.add(pledgeReward);
                        
                        _upper2Info.inviteRewardDebt = 0;
                        _upper2Info.pledgeRewardDebt = 0;
                    
                        reward = inviteReward.add(pledgeReward);
                        if (0 < reward) {
                            you.mint(_upper2, reward);

                            emit WithdrawReward(_pool, _poolInfo.lp, youAddress, zero, _upper2, reward);
                        }
                    }
                }
            }
        }
    }

    function resetRewardDebt(address _pool, address _user, address _upper1, address _upper2) internal {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if (address(0) != _poolInfo.lp && (_poolInfo.startBlock <= block.number)) {
            UserInfo storage _userInfo = pledgeUserInfo[_pool][_user];
            _userInfo.inviteRewardDebt = _userInfo.invitePower.mul(_poolInfo.rewardPerShare);
            _userInfo.pledgeRewardDebt = _userInfo.pledgePower.mul(_poolInfo.rewardPerShare);

            if (address(0) != _upper1) {
                UserInfo storage _upper1Info = pledgeUserInfo[_pool][_upper1];
                _upper1Info.inviteRewardDebt = _upper1Info.invitePower.mul(_poolInfo.rewardPerShare);
                _upper1Info.pledgeRewardDebt = _upper1Info.pledgePower.mul(_poolInfo.rewardPerShare);

                if (address(0) != _upper2) {
                    UserInfo storage _upper2Info = pledgeUserInfo[_pool][_upper2];
                    _upper2Info.inviteRewardDebt = _upper2Info.invitePower.mul(_poolInfo.rewardPerShare);
                    _upper2Info.pledgeRewardDebt = _upper2Info.pledgePower.mul(_poolInfo.rewardPerShare);
                }
            }
        }
    }
    
    function powerScale(address _pool, address _address) override external view returns (uint256) {
        PoolInfo memory _poolInfo = poolInfo[_pool];
        if (0 == _poolInfo.totalPower) {
            return 0;
        }

        UserInfo memory _userInfo = pledgeUserInfo[_pool][_address];
        return (_userInfo.invitePower.add(_userInfo.pledgePower).mul(1000)).div(_poolInfo.totalPower);
    }

    function setOperateOwner(address _address, bool _bool) override external {
        _setOperateOwner(_address, _bool);
    }
    
    function _setOperateOwner(address _address, bool _bool) internal {
        require(owner == msg.sender, ErrorCode.FORBIDDEN);
        operateOwner[_address] = _bool;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function addPool(string memory _name, address _lp, uint256 _startBlock, uint256 _rewardTotal) override external returns (address) {
        require(operateOwner[msg.sender] && (address(0) != _lp) && (thisAddress != _lp), ErrorCode.FORBIDDEN);
        _startBlock = _startBlock < block.number ? block.number : _startBlock;
        address _pool = address(0);
        bytes32 salt = keccak256(abi.encodePacked(poolAddress.length));
        bytes memory bytecode = type(YouswapPoolV1).creationCode;
        assembly {
            _pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        YouswapPoolV1(_pool).initialize(_lp);
        poolAddress.push(_pool);

        PoolViewInfo storage _poolViewInfo = poolViewInfo[_pool];
        _poolViewInfo.lp = _lp;
        _poolViewInfo.name = _name;
        _poolViewInfo.multiple = 0;
        _poolViewInfo.sort = poolAddress.length.mul(100);
        
        PoolInfo storage _poolInfo = poolInfo[_pool];
        _poolInfo.startBlock = _startBlock;
        _poolInfo.rewardTotal = _rewardTotal;
        _poolInfo.rewardProvide = 0;
        _poolInfo.lp = _lp;
        _poolInfo.amount = 0;
        _poolInfo.lastRewardBlock = _startBlock.sub(1);
        _poolInfo.inviteSelfReward = inviteSelfReward;
        _poolInfo.invite1Reward = invite1Reward;
        _poolInfo.invite2Reward = invite2Reward;
        _poolInfo.rewardPerBlock = rewardPerBlock;
        _poolInfo.totalPower = 0;
        _poolInfo.endBlock = 0;
        _poolInfo.rewardPerShare = 0;
        
        emit UpdatePool(true, _pool, _poolInfo.lp, _poolViewInfo.name, _poolInfo.startBlock, _poolInfo.rewardTotal, _poolInfo.rewardPerBlock, _poolViewInfo.multiple, _poolViewInfo.sort);

        return _pool;
    }    

    function setInviteSelfReward(address _pool, uint256 _inviteSelf) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (0 == _poolInfo.endBlock)) {
            _poolInfo.inviteSelfReward = _inviteSelf;
        }
    }

    function setInvite1Reward(address _pool, uint256 _invite1Reward) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (0 == _poolInfo.endBlock)) {
            _poolInfo.invite1Reward = _invite1Reward;
        }
    }

    function setInvite2Reward(address _pool, uint256 _invite2Reward) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (0 == _poolInfo.endBlock)) {
            _poolInfo.invite2Reward = _invite2Reward;
        }
    }

   function setRewardPerBlock(address _pool, uint256 _rewardPerBlock) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (0 == _poolInfo.endBlock)) {
            _poolInfo.rewardPerBlock = _rewardPerBlock;
        }
    }

   function setRewardTotal(address _pool, uint256 _rewardTotal) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((address(0) != _poolInfo.lp) && (0 == _poolInfo.endBlock)) {
            require(_poolInfo.rewardProvide < _rewardTotal, ErrorCode.REWARDTOTAL_LESS_THAN_REWARDPROVIDE);
            _poolInfo.rewardTotal = _rewardTotal;

            PoolViewInfo memory _poolViewInfo = poolViewInfo[_pool];

            emit UpdatePool(false, _pool, _poolInfo.lp, _poolViewInfo.name, _poolInfo.startBlock, _poolInfo.rewardTotal, _poolInfo.rewardPerBlock, _poolViewInfo.multiple, _poolViewInfo.sort);
        }
   }
   function setName(address _pool, string memory _name) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolViewInfo storage _poolViewInfo = poolViewInfo[_pool];
        if (address(0) != _poolViewInfo.lp) {
            _poolViewInfo.name = _name;

            PoolInfo memory _poolInfo = poolInfo[_pool];

            emit UpdatePool(false, _pool, _poolInfo.lp, _poolViewInfo.name, _poolInfo.startBlock, _poolInfo.rewardTotal, _poolInfo.rewardPerBlock, _poolViewInfo.multiple, _poolViewInfo.sort);
        }
   }

   function setMultiple(address _pool, uint256 _multiple) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolViewInfo storage _poolViewInfo = poolViewInfo[_pool];
        if (address(0) != _poolViewInfo.lp) {
            _poolViewInfo.multiple = _multiple;

            PoolInfo memory _poolInfo = poolInfo[_pool];

            emit UpdatePool(false, _pool, _poolInfo.lp, _poolViewInfo.name, _poolInfo.startBlock, _poolInfo.rewardTotal, _poolInfo.rewardPerBlock, _poolViewInfo.multiple, _poolViewInfo.sort);
        }
    }

    function setSort(address _pool, uint256 _sort) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolViewInfo storage _poolViewInfo = poolViewInfo[_pool];
        if (address(0) != _poolViewInfo.lp) {
            _poolViewInfo.sort = _sort;

            PoolInfo memory _poolInfo = poolInfo[_pool];

            emit UpdatePool(false, _pool, _poolInfo.lp, _poolViewInfo.name, _poolInfo.startBlock, _poolInfo.rewardTotal, _poolInfo.rewardPerBlock, _poolViewInfo.multiple, _poolViewInfo.sort);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////
    
    function blockNumber() override external view returns (uint256) {
        return block.number;
    }

    function erc20Allowance(address _token, address _owner, address _spender) override external view returns (uint256) {
        return IERC20(_token).allowance(_owner, _spender);
    }

    function erc20Balance(address _token, address _address) override external view returns (uint256) {
        return IERC20(_token).balanceOf(_address);
    }

    function erc20Supply(address _token) override external view returns (uint256) {
        return IERC20(_token).totalSupply();
    }

    ////////////////////////////////////////////////////////////////////////////////////

}