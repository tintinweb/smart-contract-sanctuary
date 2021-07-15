/**
 *Submitted for verification at Etherscan.io on 2021-07-15
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
    string constant MINING_NOT_STARTED = 'YouSwap:MINING_NOT_STARTED';
    string constant END_OF_MINING = 'YouSwap:END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING';
    
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

    address public constant ZERO = address(0);
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
        user.upper = ZERO;
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

    function inviteBatch(address[] memory _invitees) override external returns (uint, uint) {
        uint len = _invitees.length;
        require(len <= 100, ErrorCode.PARAMETER_TOO_LONG);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        if (0 == user.startBlock) {
            user.upper = ZERO;
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
// File: localhost/contract/interface/ITokenYou.sol

 

pragma solidity 0.7.4;

interface ITokenYou {
    
    function mint(address recipient, uint256 amount) external;
    
    function decimals() external view returns (uint8);
    
}

// File: localhost/contract/interface/IYouswapFactoryV2.sol

 

pragma solidity 0.7.4;



/**
挖矿
 */
interface IYouswapFactoryV2 {

    /**
    矿池可视化信息
     */
    struct PoolViewInfo {
        address token;//token合约地址
        string name;//名称
        uint256 multiple;//奖励倍数
        uint256 priority;//排序
    }

    /**
    矿池质押信息
     */
    struct PoolStakeInfo {
        uint256 startBlock;//挖矿开始块高
        address token;//token合约地址
        uint256 amount;//质押数量
        uint256 lastRewardBlock;//最后发放奖励块高
        uint256 totalPower;//总算力
        uint256 powerRatio;//质押数量到算力系数
        uint256 maxStakeAmount;//最大质押数量
        uint256 endBlock;//挖矿结束块高
    }
    
    /**
    矿池奖励信息
     */
    struct PoolRewardInfo {        
        address token;//挖矿奖励币种:A/B/C
        uint256 rewardTotal;//矿池总奖励
        uint256 rewardPerBlock;//单个区块奖励
        uint256 rewardProvide;//矿池已发放奖励
        uint256 rewardPerShare;//单位算力奖励
    }

    /**
    用户质押信息
     */
    struct UserStakeInfo {
        uint256 startBlock;//质押开始块高
        uint256 amount;//质押数量
        uint256 invitePower;//邀请算力
        uint256 stakePower;//质押算力
        uint256[] invitePendingRewards;//待领取奖励
        uint256[] stakePendingRewards;//待领取奖励
        uint256[] inviteRewardDebts;//邀请负债
        uint256[] stakeRewardDebts;//质押负债
    }

    ////////////////////////////////////////////////////////////////////////////////////
    
    /**
    自邀请
    self：Sender地址
     */
    event InviteRegister(address indexed self);

    /**
    更新矿池信息

    action：true(新建矿池)，false(更新矿池)
    poolId：矿池ID
    name：矿池名称
    token：质押token合约地址
    powerRatio：质押数量到算力系数=最小质押数量
    maxStakeAmount：最大质押数量
    startBlock：矿池开始挖矿块高
    multiple：矿池奖励倍数
    priority：矿池排序
    tokens：挖矿奖励token合约地址
    rewardTotal：挖矿总奖励数量
    rewardPerBlock：区块奖励数量
     */
    event UpdatePool(bool action, uint256 poolId, string name, address indexed token, uint256 powerRatio, uint256 maxStakeAmount, uint256 startBlock, uint256 multiple, uint256 priority, address[] tokens, uint256[] _rewardTotals, uint256[] rewardPerBlocks);

    /**
    矿池挖矿结束
    
    poolId：矿池ID
     */
    event EndPool(uint256 poolId);    
    
    /**
    质押

    poolId：矿池ID
    token：token合约地址
    from：质押转出地址
    amount：质押数量
     */
    event Stake(uint256 poolId, address indexed token, address indexed from, uint256 amount);

    /**
    算力

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
    event UpdatePower(uint256 poolId, address token, uint256 totalPower, address indexed owner, uint256 ownerInvitePower, uint256 ownerStakePower, address indexed upper1, uint256 upper1InvitePower, address indexed upper2, uint256 upper2InvitePower);    

    /**
    解质押
    
    poolId：矿池ID
    token：token合约地址
    to：解质押转入地址
    amount：解质押数量
     */
    event UnStake(uint256 poolId, address indexed token, address indexed to, uint256 amount);
    
    /**
    提取奖励

    poolId：矿池ID
    token：token合约地址
    to：奖励转入地址
    inviteAmount：奖励数量
    stakeAmount：奖励数量
     */
    event WithdrawReward(uint256 poolId, address indexed token, address indexed to, uint256 inviteAmount, uint256 stakeAmount);
    
    /**
    挖矿

    poolId：矿池ID
    token：token合约地址
    amount：奖励数量
     */
    event Mint(uint256 poolId, address indexed token, uint256 amount);

    /**
    紧急提取奖励事件

    token：领取token合约地址
    to：领取地址
    amount：领取token数量
     */
    event SafeWithdraw(address indexed token, address indexed to, uint256 amount);
    
    /**
    转移Owner

    oldOwner：旧Owner
    newOwner：新Owner
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);
    
    ////////////////////////////////////////////////////////////////////////////////////

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
    批量提取奖励
     */
    function withdrawRewards(uint256[] memory _poolIds) external;

    /**
    紧急转移token
    */
    function safeWithdraw(address token, address to, uint256 amount) external;
        
    /**
    算力占比
     */
    function powerScale(uint256 poolId, address user) external view returns (uint256, uint256);
    
    /**
    待领取的奖励
     */
    function pendingRewardV2(uint256 poolId, address user) external view returns (address[] memory, uint256[] memory);
    
    function pendingRewardV3(uint256 poolId, address user) external view returns (address[] memory, uint256[] memory, uint256[] memory);
    
    /**
    通过token查询矿池编号
     */
    function poolNumbers(address token) external view returns (uint256[] memory);

    /**
    矿池ID
     */
    function poolIdsV2() external view returns (uint256[] memory);
    
    /**
    质押数量范围
     */
    function stakeRange(uint256 poolId) external view returns (uint256, uint256);
    
    /**
    质押数量到算力系数
     */
    function getPowerRatio(uint256 poolId) external view returns (uint256);

    function getRewardInfo(uint256 poolId, address user, uint256 index) external view returns (uint256, uint256, uint256, uint256);
    
    /**
    设置运营权限
     */
    function setOperateOwner(address user, bool state) external;

    ////////////////////////////////////////////////////////////////////////////////////
    
    /**
    新建矿池
     */
    function addPool(string memory name, address token, uint256 powerRatio, uint256 startBlock, uint256 multiple, uint256 priority, address[] memory tokens, uint256[] memory rewardTotals, uint256[] memory rewardPerBlocks) external;
        
    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) external;

    /**
    修改矿池总奖励
     */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) external;

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
    
    ////////////////////////////////////////////////////////////////////////////////////
    
}
// File: localhost/contract/implement/YouswapFactoryV2.sol

 

pragma solidity 0.7.4;




contract YouswapFactoryV2 is IYouswapFactoryV2 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public constant ZERO = address(0);
    uint256 public constant INVITE_SELF_REWARD = 5;//质押自奖励，5%
    uint256 public constant INVITE1_REWARD = 15;//1级邀请奖励，15%
    uint256 public constant INVITE2_REWARD = 10;//2级邀请奖励，10%
    
    uint256 public deployBlock;//合约部署块高
    address public owner;//所有权限
    mapping(address => bool) public operateOwner;//运营权限
    ITokenYou public you;//you contract
    YouswapInviteV1 public invite;//invite contract

    uint256 public poolCount = 0;//矿池数量
    uint256[] public poolIds;//矿池ID
    mapping(uint256 => PoolViewInfo) public poolViewInfos;//矿池可视化信息，poolID->PoolViewInfo
    mapping(uint256 => PoolStakeInfo) public poolStakeInfos;//矿池质押信息，poolID->PoolStakeInfo
    mapping(uint256 => PoolRewardInfo[]) public poolRewardInfos;//矿池奖励信息，poolID->PoolRewardInfo[]
    mapping(uint256 => mapping(address => UserStakeInfo)) public userStakeInfos;//用户质押信息，poolID->user-UserStakeInfo
    mapping(address => uint256) public tokenPendingRewards;//现存token奖励数量，token-amount
    mapping(address => mapping(address => uint256)) public userReceiveRewards;//用户已领取数量，token->user->amount
    
    modifier onlyOwner() {//校验owner权限
        require(owner == msg.sender, "YouSwap:FORBIDDEN_NOT_OWNER");
        _;
    }

    modifier onlyOperater() {//校验运营权限
        require(operateOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_OPERATER");
        _;
    }

    constructor (ITokenYou _you, YouswapInviteV1 _invite) {
        deployBlock = block.number;
        owner = msg.sender;
        invite = _invite;
        you = _you;
        _setOperateOwner(owner, true);//给owner授权运营权限
    }

    /**
    修改OWNER
     */
    function transferOwnership(address _owner) override external onlyOwner {
        require(ZERO != _owner, "YouSwap:INVALID_ADDRESSES");
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
    
    /**
    质押
    */
    function stake(uint256 poolId, uint256 amount) override external {
        require(0 < amount, "YouSwap:PARAMETER_ERROR");
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START");//是否开启挖矿
        require((poolStakeInfo.powerRatio <= amount) && (poolStakeInfo.amount.add(amount) < poolStakeInfo.maxStakeAmount), "YouSwap:STAKE_AMOUNT_TOO_SMALL_OR_TOO_LARGE");
        (, uint256 startBlock) = invite.inviteUserInfoV2(msg.sender);//sender是否注册邀请关系
        if (0 == startBlock) {
            invite.register();//sender注册邀请关系
            emit InviteRegister(msg.sender);
        }
        IERC20(poolStakeInfo.token).safeTransferFrom(msg.sender, address(this), amount);//转移sender的质押资产到this
        (address upper1, address upper2) = invite.inviteUpper2(msg.sender);//获取上2级邀请关系
        initRewardInfo(poolId, msg.sender, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId);//计算单位算力奖励
        provideReward(poolId, rewardPerShares, msg.sender, upper1, upper2);//给sender发放收益，给upper1，upper2增加待领取收益
        addPower(poolId, msg.sender, amount, poolStakeInfo.powerRatio, upper1, upper2);//增加sender，upper1，upper2算力
        setRewardDebt(poolId, rewardPerShares, msg.sender, upper1, upper2);//重置sender，upper1，upper2负债
        emit Stake(poolId, poolStakeInfo.token, msg.sender, amount);
    }
    
    /**
    解质押并提取奖励
     */
    function unStake(uint256 poolId, uint256 amount) override external {
        _unStake(poolId, amount);
    }
    
    /**
    批量解质押并提取奖励
     */
    function unStakes(uint256[] memory _poolIds) override external {
        require((0 < _poolIds.length) && (50 >= _poolIds.length), "YouSwap:PARAMETER_ERROR_TOO_SHORT_OR_LONG");
        uint256 amount;
        uint256 poolId;
        for(uint i = 0; i < _poolIds.length; i++) {
            poolId = _poolIds[i];
            amount = userStakeInfos[poolId][msg.sender].amount;//sender的质押数量
            if (0 < amount) {
                _unStake(poolId, amount);
            }
        }
    }
    
    /**
    提取奖励
     */
    function withdrawReward(uint256 poolId) override external {
        _withdrawReward(poolId);
    }

    /**
    批量提取奖励
     */
    function withdrawRewards(uint256[] memory _poolIds) override external {
        require((0 < _poolIds.length) && (50 >= _poolIds.length), "YouSwap:PARAMETER_ERROR_TOO_SHORT_OR_LONG");
        for(uint i = 0; i < _poolIds.length; i++) {
            _withdrawReward(_poolIds[i]);
        }
    }

    /**
    紧急转移token
    */
    function safeWithdraw(address token, address to, uint256 amount) override external onlyOwner {
        require((ZERO != token) && (ZERO != to) && (0 < amount), "YouSwap:ZERO_ADDRESS_OR_ZERO_AMOUNT");
        require(IERC20(token).balanceOf(address(this)) >= amount, "YouSwap:BALANCE_INSUFFICIENT");
        IERC20(token).safeTransfer(to, amount);//紧急转移资产到to地址
        emit SafeWithdraw(token, to, amount);
    }
    
    /**
    算力占比
     */
    function powerScale(uint256 poolId, address user) override external view returns (uint256, uint256) {
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        if (0 == poolStakeInfo.totalPower) {
            return (0, 0);
        }
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        return (userStakeInfo.invitePower.add(userStakeInfo.stakePower), poolStakeInfo.totalPower);
    }
    
    /**
    待领取的奖励
     */
    function pendingRewardV2(uint256 poolId, address user) override external view returns (address[] memory, uint256[] memory) {
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        address[] memory tokens = new address[](_poolRewardInfos.length);
        uint256[] memory pendingRewards = new uint256[](_poolRewardInfos.length);
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        if (ZERO != poolStakeInfo.token) {
            uint256 totalReward = 0;
            uint256 rewardPre;
            UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
            for(uint i = 0; i < _poolRewardInfos.length; i++) {
                PoolRewardInfo memory poolRewardInfo = _poolRewardInfos[i];
                if (poolStakeInfo.startBlock <= block.number) {
                    totalReward = 0;
                    if (userStakeInfo.invitePendingRewards.length == _poolRewardInfos.length) {
                        if (0 < poolStakeInfo.totalPower) {
                            rewardPre = block.number.sub(poolStakeInfo.lastRewardBlock).mul(poolRewardInfo.rewardPerBlock);//待快照奖励
                            if (poolRewardInfo.rewardProvide.add(rewardPre) >= poolRewardInfo.rewardTotal) {//是否超出总奖励
                                rewardPre = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide);//核减超出奖励
                            }
                            poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(rewardPre.mul(1e24).div(poolStakeInfo.totalPower));//累加待快照的单位算力奖励
                        }
                        totalReward = userStakeInfo.invitePendingRewards[i];//待领取奖励
                        totalReward = totalReward.add(userStakeInfo.stakePendingRewards[i]);//待领取奖励
                        totalReward = totalReward.add(userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.inviteRewardDebts[i]).div(1e24));//待快照的邀请奖励
                        totalReward = totalReward.add(userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.stakeRewardDebts[i]).div(1e24));//待快照的质押奖励
                    }
                    pendingRewards[i] = totalReward;
                }
                tokens[i] = poolRewardInfo.token;
            }
        }

        return (tokens, pendingRewards);
    }

    /**
    待领取的奖励
     */
    function pendingRewardV3(uint256 poolId, address user) override external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        address[] memory tokens = new address[](_poolRewardInfos.length);
        uint256[] memory invitePendingRewards = new uint256[](_poolRewardInfos.length);
        uint256[] memory stakePendingRewards = new uint256[](_poolRewardInfos.length);
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        if (ZERO != poolStakeInfo.token) {
            uint256 inviteReward = 0;
            uint256 stakeReward = 0;
            uint256 rewardPre;
            UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
            for(uint i = 0; i < _poolRewardInfos.length; i++) {
                PoolRewardInfo memory poolRewardInfo = _poolRewardInfos[i];
                if (poolStakeInfo.startBlock <= block.number) {
                    inviteReward = 0;
                    stakeReward = 0;
                    if (userStakeInfo.invitePendingRewards.length == _poolRewardInfos.length) {
                        if (0 < poolStakeInfo.totalPower) {
                            rewardPre = block.number.sub(poolStakeInfo.lastRewardBlock).mul(poolRewardInfo.rewardPerBlock);//待快照奖励
                            if (poolRewardInfo.rewardProvide.add(rewardPre) >= poolRewardInfo.rewardTotal) {//是否超出总奖励
                                rewardPre = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide);//核减超出奖励
                            }
                            poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(rewardPre.mul(1e24).div(poolStakeInfo.totalPower));//累加待快照的单位算力奖励
                        }
                        inviteReward = userStakeInfo.invitePendingRewards[i];//待领取奖励
                        stakeReward = userStakeInfo.stakePendingRewards[i];//待领取奖励
                        inviteReward = inviteReward.add(userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.inviteRewardDebts[i]).div(1e24));//待快照的邀请奖励
                        stakeReward = stakeReward.add(userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.stakeRewardDebts[i]).div(1e24));//待快照的质押奖励
                    }
                    invitePendingRewards[i] = inviteReward;
                    stakePendingRewards[i] = stakeReward;
                }
                tokens[i] = poolRewardInfo.token;
            }
        }

        return (tokens, invitePendingRewards, stakePendingRewards);
    }
    
    /**
    通过token查询矿池编号
     */
    function poolNumbers(address token) override external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < poolIds.length; i++) {
            if (poolViewInfos[poolIds[i]].token == token) {
                count = count.add(1);
            }
        }
        uint256[] memory ids = new uint256[](count);
        count = 0;
        for (uint i = 0; i < poolIds.length; i++) {
            if (poolViewInfos[poolIds[i]].token == token) {
                ids[count] = poolIds[i];
                count = count.add(1);
            }
        }
        return ids;
    }

    /**
    矿池ID
     */
    function poolIdsV2() override external view returns (uint256[] memory) {
        return poolIds;
    }

    /**
    质押数量范围
     */    
    function stakeRange(uint256 poolId) override external view returns (uint256, uint256) {
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        if (ZERO == poolStakeInfo.token) {
            return (0, 0);
        }
        return (poolStakeInfo.powerRatio, poolStakeInfo.maxStakeAmount.sub(poolStakeInfo.amount));
    }
    
    /**
    质押数量到算力系数
     */
    function getPowerRatio(uint256 poolId) override external view returns (uint256) {
        return poolStakeInfos[poolId].powerRatio;
    }
    
    function getRewardInfo(uint256 poolId, address user, uint256 index) override external view returns (uint256, uint256, uint256, uint256) {
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        return (userStakeInfo.invitePendingRewards[index], userStakeInfo.stakePendingRewards[index], userStakeInfo.inviteRewardDebts[index], userStakeInfo.stakeRewardDebts[index]);
    }

    /**
    设置运营权限
     */
    function setOperateOwner(address user, bool state) override external onlyOwner {
        _setOperateOwner(user, state);
    }

    ////////////////////////////////////////////////////////////////////////////////////    
    
    /**
    新建矿池
     */
    function addPool(string memory name, address token, uint256 powerRatio, uint256 startBlock, uint256 multiple, uint256 priority, address[] memory tokens, uint256[] memory _rewardTotals, uint256[] memory rewardPerBlocks) override external onlyOperater {
        require((ZERO != token) && (address(this) != token), "YouSwap:PARAMETER_ERROR_TOKEN");
        require(0 < powerRatio, "YouSwap:POWERRATIO_MUST_GREATER_THAN_ZERO");
        require((0 < tokens.length) && (10 >= tokens.length) && (tokens.length == _rewardTotals.length) && (tokens.length == rewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        startBlock = startBlock < block.number ? block.number : startBlock;//合法开始块高
        uint256 poolId = poolCount.add(20000000);//矿池ID，偏移20000000，与v1区分开
        poolIds.push(poolId);//全部矿池ID
        poolCount = poolCount.add(1);//矿池总数量
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];//矿池可视化信息
        poolViewInfo.token = token;//矿池质押token
        poolViewInfo.name = name;//矿池名称
        poolViewInfo.multiple = multiple;//矿池倍数
        if (0 < priority) {
            poolViewInfo.priority = priority;//矿池优先级
        }else {
            poolViewInfo.priority = poolIds.length.mul(100).add(75);//矿池优先级
        }
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];//矿池质押信息
        poolStakeInfo.startBlock = startBlock;//开始块高
        poolStakeInfo.token = token;//矿池质押token
        poolStakeInfo.amount = 0;//矿池质押数量
        poolStakeInfo.lastRewardBlock = startBlock.sub(1);//矿池上次快照块高
        poolStakeInfo.totalPower = 0;//矿池总算力
        poolStakeInfo.powerRatio = powerRatio;//质押数量到算力系数
        poolStakeInfo.maxStakeAmount = 0;//最大质押数量
        poolStakeInfo.endBlock = 0;//矿池结束块高
        uint256 minRewardPerBlock = uint256(0) - uint256(1);//最小区块奖励
        for(uint i = 0; i < tokens.length; i++) {
            require((ZERO != tokens[i]) && (address(this) != tokens[i]), "YouSwap:PARAMETER_ERROR_TOKEN");
            require(0 < _rewardTotals[i], "YouSwap:PARAMETER_ERROR_REWARD_TOTAL");
            require(0 < rewardPerBlocks[i], "YouSwap:PARAMETER_ERROR_REWARD_PER_BLOCK");
            if (address(you) != tokens[i]) {//非you奖励
                tokenPendingRewards[tokens[i]] = tokenPendingRewards[tokens[i]].add(_rewardTotals[i]);
                require(IERC20(tokens[i]).balanceOf(address(this)) >= tokenPendingRewards[tokens[i]], "YouSwap:BALANCE_INSUFFICIENT");//奖励数量是否足额
            }
            PoolRewardInfo memory poolRewardInfo;//矿池奖励信息
            poolRewardInfo.token = tokens[i];//奖励token
            poolRewardInfo.rewardTotal = _rewardTotals[i];//总奖励
            poolRewardInfo.rewardPerBlock = rewardPerBlocks[i];//区块奖励
            poolRewardInfo.rewardProvide = 0;//已发放奖励
            poolRewardInfo.rewardPerShare = 0;//单位算力简历
            poolRewardInfos[poolId].push(poolRewardInfo);
            if (minRewardPerBlock > poolRewardInfo.rewardPerBlock) {
                minRewardPerBlock = poolRewardInfo.rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
        sendUpdatePoolEvent(true, poolId);
    }

    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) override external onlyOperater {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        require((ZERO != poolStakeInfo.token) && (0 == poolStakeInfo.endBlock), "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在、是否结束
        computeReward(poolId);//计算单位算力奖励
        uint256 minRewardPerBlock = uint256(0) - uint256(1);//最小区块奖励
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                _poolRewardInfos[i].rewardPerBlock = rewardPerBlock;//修改矿池区块奖励
                sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
            }
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
    }

    /**
    修改矿池总奖励
     */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) override external onlyOperater {
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        require((ZERO != poolStakeInfo.token) && (0 == poolStakeInfo.endBlock), "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在、是否结束
        computeReward(poolId);//计算单位算力奖励
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                require(_poolRewardInfos[i].rewardProvide <= rewardTotal, "YouSwap:REWARDTOTAL_LESS_THAN_REWARDPROVIDE");//新总奖励是否超出已发放奖励
                if (address(you) != token) {//非you
                    if (_poolRewardInfos[i].rewardTotal > rewardTotal) {//新总奖励小于旧总奖励
                        tokenPendingRewards[token] = tokenPendingRewards[token].sub(_poolRewardInfos[i].rewardTotal.sub(rewardTotal));//减少新旧差额
                    }else {//新总奖励大于旧总奖励
                        tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal.sub(_poolRewardInfos[i].rewardTotal));//增加新旧差额
                    }
                    require(IERC20(token).balanceOf(address(this)) >= tokenPendingRewards[token], "YouSwap:BALANCE_INSUFFICIENT");//奖励数量是否足额
                }
                _poolRewardInfos[i].rewardTotal = rewardTotal;//修改矿池总奖励
                sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
            }
        }
    }

    /**
    修改矿池名称
     */
    function setName(uint256 poolId, string memory name) override external onlyOperater {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在
        poolViewInfo.name = name;//修改矿池名称
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }
    
    /**
    修改矿池倍数
     */
    function setMultiple(uint256 poolId, uint256 multiple) override external onlyOperater {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在
        poolViewInfo.multiple = multiple;//修改矿池倍数
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }
    
    /**
    修改矿池排序
     */
    function setPriority(uint256 poolId, uint256 priority) override external onlyOperater {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在
        poolViewInfo.priority = priority;//修改矿池排序
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }
    
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) override external onlyOperater {
        uint256 _maxStakeAmount;
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        require((ZERO != poolStakeInfo.token) && (0 == poolStakeInfo.endBlock), "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//矿池是否存在、是否结束
        uint256 minRewardPerBlock = uint256(0) - uint256(1);//最小区块奖励
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                _maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
        require(poolStakeInfo.powerRatio <= maxStakeAmount && poolStakeInfo.amount <= maxStakeAmount && maxStakeAmount <= _maxStakeAmount, "YouSwap:MAX_STAKE_AMOUNT_INVALID");
        poolStakeInfo.maxStakeAmount = maxStakeAmount;
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    
    ////////////////////////////////////////////////////////////////////////////////////
    
    function _setOperateOwner(address user, bool state) internal onlyOwner {
        operateOwner[user] = state;//设置运营权限
    }

    /**
    计算单位算力奖励
     */
    function computeReward(uint256 poolId) internal returns (uint256[] memory) {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        uint256[] memory rewardPerShares = new uint256[](_poolRewardInfos.length);
        if (0 < poolStakeInfo.totalPower) {//有算力才能发奖励
            uint finishRewardCount = 0;
            uint256 reward = 0;
            uint256 blockCount = block.number.sub(poolStakeInfo.lastRewardBlock);//待发放的区块数量
            for(uint i = 0; i < _poolRewardInfos.length; i++) {
                PoolRewardInfo storage poolRewardInfo = _poolRewardInfos[i];//矿池奖励信息
                reward = blockCount.mul(poolRewardInfo.rewardPerBlock);//两次快照之间总奖励
                if (poolRewardInfo.rewardProvide.add(reward) >= poolRewardInfo.rewardTotal) {//是否超出总奖励数量
                    reward = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide);//核减超出奖励
                    finishRewardCount = finishRewardCount.add(1);//挖矿结束token计数
                }
                poolRewardInfo.rewardProvide = poolRewardInfo.rewardProvide.add(reward);//更新已发放奖励数量
                poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(reward.mul(1e24).div(poolStakeInfo.totalPower));//更新单位算力奖励
                rewardPerShares[i] = poolRewardInfo.rewardPerShare;
                if (0 < reward) {
                    emit Mint(poolId, poolRewardInfo.token, reward);//挖矿事件
                }
            }
            poolStakeInfo.lastRewardBlock = block.number;//更新快照块高
            if (finishRewardCount == _poolRewardInfos.length) {//是否挖矿结束
                poolStakeInfo.endBlock = block.number;//挖矿结束块高
                emit EndPool(poolId);//挖矿结束事件
            }
        }else {
            for(uint i = 0; i < _poolRewardInfos.length; i++) {
                rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
            }
        }
        return rewardPerShares;
    }
    
    /**
    增加算力
     */
    function addPower(uint256 poolId, address user, uint256 amount, uint256 powerRatio, address upper1, address upper2) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];//矿池质押信息
        poolStakeInfo.amount = poolStakeInfo.amount.add(amount);//更新矿池质押数量
        poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(power);//更新矿池总算力
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];//sender质押信息
        userStakeInfo.amount = userStakeInfo.amount.add(amount);//更新sender质押数量
        userStakeInfo.stakePower = userStakeInfo.stakePower.add(power);//更新sender质押算力
        if (0 == userStakeInfo.startBlock) {
            userStakeInfo.startBlock = block.number;//挖矿开始块高
        }
        uint256 upper1InvitePower = 0;//upper1邀请算力
        uint256 upper2InvitePower = 0;//upper2邀请算力
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(INVITE_SELF_REWARD).div(100);//新增sender自邀请算力
            userStakeInfo.invitePower = userStakeInfo.invitePower.add(inviteSelfPower);//更新sender邀请算力
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(inviteSelfPower);//更新矿池总算力
            uint256 invite1Power = power.mul(INVITE1_REWARD).div(100);//新增upper1邀请算力
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];//upper1质押信息
            upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.add(invite1Power);//更新upper1邀请算力
            upper1InvitePower = upper1StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite1Power);//更新矿池总算力
            if (0 == upper1StakeInfo.startBlock) {
                upper1StakeInfo.startBlock = block.number;//挖矿开始块高
            }
            
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(INVITE2_REWARD).div(100);//新增upper2邀请算力
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];//upper2质押信息
            upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.add(invite2Power);//更新upper2邀请算力
            upper2InvitePower = upper2StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite2Power);//更新矿池总算力
            if (0 == upper2StakeInfo.startBlock) {
                upper2StakeInfo.startBlock = block.number;//挖矿开始块高
            }
        }
        emit UpdatePower(poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower);//更新算力事件
    }

    /**
    减少算力
     */
    function subPower(uint256 poolId, address user, uint256 amount, uint256 powerRatio, address upper1, address upper2) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];//矿池质押信息
        if (poolStakeInfo.amount <= amount) {
            poolStakeInfo.amount = 0;//减少矿池总质押数量
        }else {
            poolStakeInfo.amount = poolStakeInfo.amount.sub(amount);//减少矿池总质押数量
        }
        if (poolStakeInfo.totalPower <= power) {
            poolStakeInfo.totalPower = 0;//减少矿池总算力
        }else {
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(power);//减少矿池总算力
        }
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];//sender质押信息
        userStakeInfo.amount = userStakeInfo.amount.sub(amount);//减少sender质押数量
        if (userStakeInfo.stakePower <= power) {
            userStakeInfo.stakePower = 0;//减少sender质押算力
        }else {
            userStakeInfo.stakePower = userStakeInfo.stakePower.sub(power);//减少sender质押算力
        }
        uint256 upper1InvitePower = 0;
        uint256 upper2InvitePower = 0;
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(INVITE_SELF_REWARD).div(100);//sender自邀请算力
            if (poolStakeInfo.totalPower <= inviteSelfPower) {
                poolStakeInfo.totalPower = 0;//减少矿池sender自邀请算力
            }else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(inviteSelfPower);//减少矿池sender自邀请算力
            }
            if (userStakeInfo.invitePower <= inviteSelfPower) {
                userStakeInfo.invitePower = 0;//减少sender自邀请算力
            }else {
                userStakeInfo.invitePower = userStakeInfo.invitePower.sub(inviteSelfPower);//减少sender自邀请算力
            }
            uint256 invite1Power = power.mul(INVITE1_REWARD).div(100);//upper1邀请算力
            if (poolStakeInfo.totalPower <= invite1Power) {
                poolStakeInfo.totalPower = 0;//减少矿池upper1邀请算力
            }else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite1Power);//减少矿池upper1邀请算力
            }
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePower <= invite1Power) {
                upper1StakeInfo.invitePower = 0;//减少upper1邀请算力
            }else {
                upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.sub(invite1Power);//减少upper1邀请算力
            }
            upper1InvitePower = upper1StakeInfo.invitePower;
        }
        if (ZERO != upper2) {
                uint256 invite2Power = power.mul(INVITE2_REWARD).div(100);//upper2邀请算力
                if (poolStakeInfo.totalPower <= invite2Power) {
                    poolStakeInfo.totalPower = 0;//减少矿池upper2邀请算力
                }else {
                    poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite2Power);//减少矿池upper2邀请算力
                }
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                if (upper2StakeInfo.invitePower <= invite2Power) {
                    upper2StakeInfo.invitePower = 0;//减少upper2邀请算力
                }else {
                    upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.sub(invite2Power);//减少upper2邀请算力
                }
                upper2InvitePower = upper2StakeInfo.invitePower;
        }
        emit UpdatePower(poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower);
    }
    
    /**
    //给sender发放收益，给upper1，upper2增加待领取收益
     */
    function provideReward(uint256 poolId, uint256[] memory rewardPerShares, address user, address upper1, address upper2) internal {
        uint256 reward = 0;
        uint256 inviteReward = 0;
        uint256 stakeReward = 0;
        uint256 rewardPerShare = 0;
        address token;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            token = _poolRewardInfos[i].token;//挖矿奖励token
            rewardPerShare = rewardPerShares[i];//单位算力奖励系数
            if ((0 < userStakeInfo.invitePower) || (0 < userStakeInfo.stakePower)) {
                inviteReward = userStakeInfo.invitePower.mul(rewardPerShare).sub(userStakeInfo.inviteRewardDebts[i]).div(1e24);//邀请奖励
                stakeReward = userStakeInfo.stakePower.mul(rewardPerShare).sub(userStakeInfo.stakeRewardDebts[i]).div(1e24);//质押奖励
                inviteReward = userStakeInfo.invitePendingRewards[i].add(inviteReward);//待领取奖励
                stakeReward = userStakeInfo.stakePendingRewards[i].add(stakeReward);//待领取奖励
                reward = inviteReward.add(stakeReward);
            }
            if (0 < reward) {
                userStakeInfo.invitePendingRewards[i] = 0;//重置待领取奖励
                userStakeInfo.stakePendingRewards[i] = 0;//重置待领取奖励
                userReceiveRewards[token][user] = userReceiveRewards[token][user].add(reward);//增加已领取奖励
                if (address(you) == token) {//you
                    you.mint(user, reward);//挖you
                }else {//非you
                    tokenPendingRewards[token] = tokenPendingRewards[token].sub(reward);//减少奖励总额
                    IERC20(token).safeTransfer(user, reward);//发放奖励
                }
                emit WithdrawReward(poolId, token, user, inviteReward, stakeReward);
            }
            if (ZERO != upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
                if ((0 < upper1StakeInfo.invitePower) || (0 < upper1StakeInfo.stakePower)) {
                    inviteReward = upper1StakeInfo.invitePower.mul(rewardPerShare).sub(upper1StakeInfo.inviteRewardDebts[i]).div(1e24);//邀请奖励
                    stakeReward = upper1StakeInfo.stakePower.mul(rewardPerShare).sub(upper1StakeInfo.stakeRewardDebts[i]).div(1e24);//质押奖励
                    upper1StakeInfo.invitePendingRewards[i] = upper1StakeInfo.invitePendingRewards[i].add(inviteReward);//待领取奖励
                    upper1StakeInfo.stakePendingRewards[i] = upper1StakeInfo.stakePendingRewards[i].add(stakeReward);//待领取奖励
                }
            }
            if (ZERO != upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                if ((0 < upper2StakeInfo.invitePower) || (0 < upper2StakeInfo.stakePower)) {
                    inviteReward = upper2StakeInfo.invitePower.mul(rewardPerShare).sub(upper2StakeInfo.inviteRewardDebts[i]).div(1e24);//邀请奖励
                    stakeReward = upper2StakeInfo.stakePower.mul(rewardPerShare).sub(upper2StakeInfo.stakeRewardDebts[i]).div(1e24);//质押奖励
                    upper2StakeInfo.invitePendingRewards[i] = upper2StakeInfo.invitePendingRewards[i].add(inviteReward);//待领取奖励
                    upper2StakeInfo.stakePendingRewards[i] = upper2StakeInfo.stakePendingRewards[i].add(stakeReward);//待领取奖励
                }
            }
        }
    }

    /**
    重置负债
     */
    function setRewardDebt(uint256 poolId, uint256[] memory rewardPerShares, address user, address upper1, address upper2) internal {
        uint256 rewardPerShare = 0;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];
        for(uint i = 0; i < rewardPerShares.length; i++) {
            rewardPerShare = rewardPerShares[i];//单位算力奖励系数
            userStakeInfo.inviteRewardDebts[i] = userStakeInfo.invitePower.mul(rewardPerShare);//重置sender邀请负债
            userStakeInfo.stakeRewardDebts[i] = userStakeInfo.stakePower.mul(rewardPerShare);//重置sender质押负债
            if (ZERO != upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
                upper1StakeInfo.inviteRewardDebts[i] = upper1StakeInfo.invitePower.mul(rewardPerShare);//重置upper1邀请负债
                upper1StakeInfo.stakeRewardDebts[i] = upper1StakeInfo.stakePower.mul(rewardPerShare);//重置upper1质押负债
                if (ZERO != upper2) {
                    UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                    upper2StakeInfo.inviteRewardDebts[i] = upper2StakeInfo.invitePower.mul(rewardPerShare);//重置upper2邀请负债
                    upper2StakeInfo.stakeRewardDebts[i] = upper2StakeInfo.stakePower.mul(rewardPerShare);//重置upper2质押负债
                }
            }
        }
    }

    /**
    矿池信息更新事件
     */
    function sendUpdatePoolEvent(bool action, uint256 poolId) internal {
        PoolViewInfo memory poolViewInfo = poolViewInfos[poolId];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        address[] memory tokens = new address[](_poolRewardInfos.length);
        uint256[] memory _rewardTotals = new uint256[](_poolRewardInfos.length);
        uint256[] memory rewardPerBlocks = new uint256[](_poolRewardInfos.length);
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            tokens[i] = _poolRewardInfos[i].token;
            _rewardTotals[i] = _poolRewardInfos[i].rewardTotal;
            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
        }
        emit UpdatePool(action, poolId, poolViewInfo.name, poolStakeInfo.token, poolStakeInfo.powerRatio, poolStakeInfo.maxStakeAmount, poolStakeInfo.startBlock, poolViewInfo.multiple, poolViewInfo.priority, tokens, _rewardTotals, rewardPerBlocks);
    }

    /**
    解质押
     */
    function _unStake(uint256 poolId, uint256 amount) internal {        
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINING_NOT_START");
        require((0 < amount) && (userStakeInfos[poolId][msg.sender].amount >= amount), "YouSwap:BALANCE_INSUFFICIENT");
        (address upper1, address upper2) = invite.inviteUpper2(msg.sender);
        initRewardInfo(poolId, msg.sender, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId);//计算单位算力奖励系数
        provideReward(poolId, rewardPerShares, msg.sender, upper1, upper2);//给sender发放收益，给upper1，upper2增加待领取收益
        subPower(poolId, msg.sender, amount, poolStakeInfo.powerRatio, upper1, upper2);//减少算力
        setRewardDebt(poolId, rewardPerShares, msg.sender, upper1, upper2);//重置sender，upper1，upper2负债
        IERC20(poolStakeInfo.token).safeTransfer(msg.sender, amount);//解质押token
        emit UnStake(poolId, poolStakeInfo.token, msg.sender, amount);
    }    

    function _withdrawReward(uint256 poolId) internal {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINING_NOT_START");
        (address upper1, address upper2) = invite.inviteUpper2(msg.sender);
        initRewardInfo(poolId, msg.sender, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId);//计算单位算力奖励系数
        provideReward(poolId, rewardPerShares, msg.sender, upper1, upper2);//给sender发放收益，给upper1，upper2增加待领取收益
        setRewardDebt(poolId, rewardPerShares, msg.sender, upper1, upper2);//重置sender，upper1，upper2负债
    }
    
    function initRewardInfo(uint256 poolId, address user, address upper1, address upper2) internal {
        uint count = poolRewardInfos[poolId].length;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.invitePendingRewards.length) {
            for(uint i = 0; i < count; i++) {
                userStakeInfo.invitePendingRewards.push(0);//初始化待领取数量
                userStakeInfo.stakePendingRewards.push(0);//初始化待领取数量
                userStakeInfo.inviteRewardDebts.push(0);//初始化邀请负债
                userStakeInfo.stakeRewardDebts.push(0);//初始化质押负债
            }
        }
        if (ZERO != upper1) {
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (0 == upper1StakeInfo.invitePendingRewards.length) {
                for(uint i = 0; i < count; i++) {
                    upper1StakeInfo.invitePendingRewards.push(0);//初始化待领取数量
                    upper1StakeInfo.stakePendingRewards.push(0);//初始化待领取数量
                    upper1StakeInfo.inviteRewardDebts.push(0);//初始化邀请负债
                    upper1StakeInfo.stakeRewardDebts.push(0);//初始化质押负债
                }
            }
            if (ZERO != upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                if (0 == upper2StakeInfo.invitePendingRewards.length) {
                    for(uint i = 0; i < count; i++) {
                        upper2StakeInfo.invitePendingRewards.push(0);//初始化待领取数量
                        upper2StakeInfo.stakePendingRewards.push(0);//初始化待领取数量
                        upper2StakeInfo.inviteRewardDebts.push(0);//初始化邀请负债
                        upper2StakeInfo.stakeRewardDebts.push(0);//初始化质押负债
                    }
                }
            }
        }
    }

}