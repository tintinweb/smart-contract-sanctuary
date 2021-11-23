/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-11-22
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/HubCommon.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;




contract AuthHub is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    // 调用者合约地址
    address public callerAddress;
    // controller 合约地址
    address public controller;
    // 冶理地址
    address public governance;
    //自动触发收益匹配
    bool public paused = false; 

    constructor() public {
        governance = msg.sender;
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function checkGovernance() public view {
        require(governance != address(0), 'governance address is zero');
        require(msg.sender == owner() || msg.sender == governance, 'not allow');
    }

    function checkController() public view {
        require(governance != address(0) && controller != address(0), 'not allow');
        require( msg.sender == governance || msg.sender == controller, 'not allow');
    }

    function checkCaller() public view {
        require(governance != address(0) && callerAddress != address(0), 'Caller is zero address');
        require( msg.sender == governance || msg.sender == callerAddress, 'Caller not allow');
    }

    // 设置权限控制合约
    function setGovernance(address _governance) public {
        require(address(0) != _governance, "governance address is zero");
        require(msg.sender == owner() || msg.sender == governance, 'not allow');
        governance = _governance;
    }

    function setController(address _controller) public {
        require(_controller != address(0), "controller is the zero address");
        require(msg.sender == owner() || msg.sender == governance, 'not allow');
        controller = _controller;
    }

    function setCaller(address addr) public {
        require(addr != address(0), "got zero address");
        require(msg.sender == owner() || msg.sender == governance, 'not allow');
        callerAddress = addr;
    }

    function setPause() public  {
        require(msg.sender == owner() || msg.sender == governance, 'not allow');
        paused = !paused;
    }
}

// Info of each token.
struct TokenInfo {
    // 币种所有策略历史累计收益，用来计算复利本金
    uint256 historyStrategyReward;

    // 币种复利本金
    uint256 totalAmount;     
    // 币种复利负债，这是跟复利结算的CompoundPool的accMdxShare
    uint256 compoundDebt; 
    // 结算币种复利块高
    uint256 lastRewardBlock;
    // 用户的复利收益，币种的复利收益在CompoundPool
    uint256 accMdxPerShare;
    // 用户复利年华
    uint256 lastRewardBlockProfit;  
}

// 复利池子
struct CompoundPool {
    // 上一次结算收益的块高    
    uint256 lastRewardBlock;  
    // 所有币种复利累计收益
    uint256 historyReward;
    // 复利上一次结算的币种总收益占比
    uint256 accMdxPerShare;
    // 所有币种复利质押总数量
    uint256 totalAmount; 
    // mdx 质押年化
    uint256 lastRewardBlockProfit;  
}

// Info of each user.
struct UserInfo {
    // 用户本金
    uint256 amount;     
    // 用户负债
    uint256 rewardDebt; 
    // 平台分成负债
    uint256 govRewardDebt; 
    // 复利负负债，TokenInfo的accMdxPerShare
    uint256 tokenInfoDebt;
    // cow负债
    uint cowDebt;
    uint historyReward;
    //用户分成比例
    uint256 mdxProfit;
    //用户分成比例
    uint256 cowProfit;
    // 待领取mdx
    uint256 mdxReward;
    // 待领取 cow
    uint256 cowReward;
    //最后一次存入块高
    uint256 lastDepostBlock;
}

// Info of each user.
struct UserInfoV2 {
    // 用户本金
    uint256 amount;     
    // 用户负债
    uint256 rewardDebt; 
    // 平台分成负债
    uint256 govRewardDebt; 
    // 复利负负债，TokenInfo的accMdxPerShare
    uint256 tokenInfoDebt;
    // cow负债
    uint cowDebt;
    uint historyReward;
    //用户分成比例
    uint256 mdxProfit;
    //用户分成比例
    uint256 cowProfit;
}

// 每个池子的信息
struct PoolInfo {
    // 用户质押币种
    IERC20 token;     
    // 上一次结算收益的块高    
    uint256 lastRewardBlock;  
    // 上一次结算的用户总收益占比
    uint256 accMdxPerShare;  
    // 上一次结算的平台分润占比
    uint256 govAccMdxPerShare; 
    // 上一次结算累计的mdx收益
    uint256 accMdxShare;
    // 所有用户质押总数量
    uint256 totalAmount;    
    // 所有用户质押总数量上限，0表示不限
    uint256 totalAmountLimit; 
    // 用户收益率，万分之几
    uint256 profit;
    // 赚钱的最低触发额度
    uint256 earnLowerlimit;
    // 池子留下的保留金 min为100 表示 100/10000 = 1/100 = 0.01 表示 0.01%
    uint256 min;
    //单币质押年华
    uint256 lastRewardBlockProfit;
    PoolCowInfo cowInfo;
}

// 每个池子的信息
struct PoolCowInfo {
    //cow 收益数据
    uint256 accCowPerShare;
    // cow累计收益
    uint256 accCowShare;
    //每个块奖励cow
    uint256 blockCowReward;
    //每个块奖励mdx
    uint256 blockMdxReward;
}

struct RateAndTvl {
    address token;
    uint rate;
    uint tvl;
}

interface IHubPool {
    function liquidityDeposit(address _token, uint _amount, bool _triggerEarn) external;
    function liquidityWithdraw(address _token, uint _amount) external;
    function earn(address token) external;
    function poolLength() external view returns (uint256);
    function poolInfo(uint index) view external returns (PoolInfo memory);
    function TokenOfPid(address token) view external returns (uint);
    function controller() view external returns (address);
    function governance() view external returns (address) ;
    function govTotalProfit() view external returns(uint);
    function govTotalSendProfit() view external returns(uint);
    function owner()external view returns (address) ;
    function getPoolId(address token) external view returns (uint256) ;
    function pending(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);
    function getMdxBlockReward(address token) external view returns (uint256);
    function userInfo(uint pid, address user) external view returns (UserInfo memory);
    function withdraw(address token, uint amount) external ;
    function deposit(address token, uint amount) external ;
    function available(address token) view external returns (uint);
    function withdrawAll(address token) external;
    function depositAll(address token) external;
    function withdrawWithPid(uint256 pid, uint256 amount) external;
}

interface IHubPoolV2 {
    function userInfo(uint pid, address user) external view returns (UserInfoV2 memory);
    function getPoolId(address token) external view returns (uint256) ;
    function poolInfo(uint index) view external returns (PoolInfo memory);
    function pending(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);
    function pendingCow(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function migrateUser(uint _pid, address _user, uint amount, uint mdxReward, uint cowReward) external;
}

interface IController {
    // 获取mdex中token数量
    function balanceOfToken(address _token) external view returns (uint);
    // 获取token累计的mdx收益 
    function accTotalMdx(address token) external view returns (uint256);
    // 获取所有策略累计的mdx收益
    function accTotalStrategyMdx() external view returns (uint, address);
    // 释放投资本金，用于提现 
    function withdrawLp(address token, uint _amount) external;
    // 触发投资
    function earn(address token) external;
    // 触发发收益
    function withdrawPending(address token, address user, uint256 userPending, uint256 govPending) external returns (bool);
    // 获取策略
    function strategyLength() external view returns (uint) ;
    function strategieList(uint id) external view returns (address) ;
    function governance() external view returns (address) ;
    function mdxToken() external view returns (address) ;
    function owner() external view returns (address) ;
    function vaults() external view returns (address) ;
    function updateCompoundPool(uint256 pid) external;
    function checkCompound(address token, address user) external view returns (bool) ;
    function getTokenCompoundDebt(address token) external view returns (uint256);
    function withdrawGovReward(uint amount) external;
}

interface IStrategy {
    function paused() external returns(bool);
    function want() external view returns (address, address);
    function contain(address) external view returns (bool);
    function deposit() external;
    function withdraw(address, uint) external returns (uint);
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
    function balanceOfToken(address) external view returns (uint);
    function accTotalMdx() external view returns (uint);
    function withdrawMDXReward() external;
    function getReserves() external view returns (uint, uint);
    function governance()external view returns (address) ;
    function owner()external view returns (address) ;
    function pid()external view returns (uint);
    function queryRewardByUser(uint mdxPid, address user) external view returns (uint, uint) ;
    function mdexRouter() external view returns (address) ;
    function strategyName() external view returns (string memory) ;
    function accHistoryMDXReward() external view returns (uint256);
}

interface ISwapMining {
    function getQuantity(address outputToken, uint256 outputAmount, address anchorToken) external view returns (uint256);
}

interface ICompoundStorageHub {
    function tokenInfo(address token) external view returns (TokenInfo memory);
    function updateCompoundPool(CompoundPool memory compoundPool) external;
    function compoundPool() external view returns (CompoundPool memory);
    function setCompoundTotalAmount(uint256 amount) external;
    function updateTokenInfo(address token, TokenInfo memory _info) external;
    function decCompoundAmount(address token, uint256 amount) external ;
    function incCompoundAmount(address token, uint256 amount) external ;
}

interface ICompoundHub {
    function paused() external view returns(bool);
    function pending(address token, address user, address vault) external view returns (uint256);
    function massUpdatePools(address vault) external;
    function decLp(address token, uint256 amount) external ;
    function withdrawLp(address vault, uint256 amount) external ;
    function depositLp(address vault, uint256 amount) external ;
    function balanceOf() external view returns (uint256);
    function compoundStrategy() view external returns (address);
    function getTokenCompoundDebt(address token) view external returns (uint256);
    function updateCompoundPool(address vault) external;
    function updatePool(uint256 hpoolId, address vault) external;
}

interface IHubPoolExtend {
    function deposit(uint _pid, uint _amount, address user) external;
    function withdraw(uint _pid, uint _amount, address user) external returns(uint);
    function emergencyWithdraw(uint _pid, uint _amount, address user) external returns(uint);
}

interface ICowRouter {
    function token() external view returns (address);
    function allowance() external view returns (uint256);
    function gain(uint256 _amount) external;
}

interface ICompoundStrategy {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external returns (uint256);
    function withdrawAll() external;
    function balanceOf() external view returns (uint256);
    function accTotalMdx() external view returns (uint256);
}

interface IMigrator {
    function needMigrator(address user) external view returns (bool);
    function initNewUser(address user) external returns (bool);
}


// File contracts/HubPoolStorage.sol

pragma solidity 0.6.12;

contract HubPoolStorage is AuthHub {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // 池子信息列表
    PoolInfo[] public poolInfo;

    // token对应的 poolInfo索引
    mapping(address => uint256) public TokenOfPid;

    // 每个池子的用户数量
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // 万分比的分母
    uint256 constant public max = 10000; 

    // 扩展合约，预留
    address public hupPoolExtend;

    //平台累计收益
    uint256 public govTotalProfit;

    //平台已发放收益
    uint256 public govTotalSendProfit;

    // 用户总收益
    uint256 public userTotalProfit;

    // 用户已发放收益
    uint256 public userTotalSendProfit;

    // 用户总cow收益
    uint256 public userTotalCowProfit;

    // 用户已发放cow收益
    uint256 public userTotalSendCowProfit;
    
    /**
     * @notice migrator contract
     */
     address public migratorHub;

    /**
    * @notice Active brains 
    */
    address[] public implementations;

    modifier checkToken(address token) {
        require(token != address(0) && address(poolInfo[TokenOfPid[token]].token) == token, "token not exists");
        _;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    } 

    function getPoolInfo(address token) internal view checkToken(token) returns(PoolInfo storage) {
        return poolInfo[TokenOfPid[token]];
    }

    function getPoolId(address token) public view checkToken(token) returns (uint256){
        return TokenOfPid[token];
    } 

    // 计算用户的mdx收益
    function countPending(PoolInfo storage pool, UserInfo storage user, uint blockReward) internal view returns (uint) {
        uint256 accMdxPerShare;
        if(user.mdxProfit > 0) {
            //用户已禁止收益
            accMdxPerShare = user.mdxProfit;
        }else{
            // 每个质押量 获取收益
            accMdxPerShare = pool.accMdxPerShare.add(blockReward);
        }

        uint pendingAmount = 0;
        uint256 totalDebt =  user.amount.mul(accMdxPerShare).div(1e18);
        if(totalDebt >= user.rewardDebt){
            pendingAmount = totalDebt.sub(user.rewardDebt);
        }
        return pendingAmount.add(user.mdxReward);
    }

    // 计算用户的cow收益
    function countCowPending(PoolInfo storage pool, UserInfo storage user, uint blockReward) internal view returns (uint) {
        uint256 accCowPerShare;
        if(user.cowProfit > 0){
            //用户已禁止收益
            accCowPerShare = user.cowProfit;
        }else{
            accCowPerShare = pool.cowInfo.accCowPerShare.add(blockReward);
        }

        uint pendingCowAmount = 0;
        uint256 totalDebt =  user.amount.mul(accCowPerShare).div(1e18);
        if(totalDebt >= user.cowDebt){
            pendingCowAmount = totalDebt.sub(user.cowDebt);
        }
        return pendingCowAmount.add(user.cowReward);
    }
}


// File contracts/HubPool2.sol

pragma solidity 0.6.12;

/**
 * @notice view interface for web3j
 */
contract HubPool2 is HubPoolStorage{

    // 设置扩展合约
    function setHupPoolExtend(address _hupPoolExtend) public  {
        checkGovernance();
        hupPoolExtend = _hupPoolExtend;
    }

    /**
     * @notice set migrator address
     */
    function setMigrator(address _migrator) public  {
        checkGovernance();
        migratorHub = _migrator;
    }

    function setEarnLowerlimit(address token, uint256 _earnLowerlimit) public  {
        checkGovernance();
        PoolInfo storage pool = getPoolInfo(token);
        pool.earnLowerlimit = _earnLowerlimit;
    }

    function setMin(address token, uint256 _min) public  {
        require(_min <= max && _min >= 0, "min must (0~10000]");
        checkGovernance();
        PoolInfo storage pool = getPoolInfo(token);
        pool.min = _min;
    }

    function setTotalAmountLimit(address token, uint256 _limit) public  {
        checkGovernance();
        PoolInfo storage pool = getPoolInfo(token);
        pool.totalAmountLimit = _limit;
    }

    // 设置单个用户分成比例
    function setUserProfit(address token, address _user, bool _mdxProfit, bool _cowProfit) public {
        checkGovernance();
        uint _pid = getPoolId(token);
        
        //updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_user];

        if(_mdxProfit){
            //开启用户收益
            user.mdxProfit = 0;
        }else{
            // 关闭用户收益
            PoolInfo storage pool = poolInfo[_pid];
            user.mdxProfit = pool.accMdxPerShare;
        }

        if(_cowProfit){
            //开启用户收益
            user.cowProfit = 0;
        }else{
            // 关闭用户收益
            PoolInfo storage pool = poolInfo[_pid];
            user.cowProfit = pool.cowInfo.accCowPerShare;
        }
    }

    // 设置单个用户分成比例
    function setUserAllProfit(address _user, bool _mdxProfit, bool _cowProfit) public {
        checkGovernance();
        for(uint _pid=0; _pid < poolInfo.length; _pid++){
            //updatePool(_pid);
            UserInfo storage user = userInfo[_pid][_user];

            if(_mdxProfit){
                //开启用户收益
                user.mdxProfit = 0;
            }else{
                // 关闭用户收益
                PoolInfo storage pool = poolInfo[_pid];
                user.mdxProfit = pool.accMdxPerShare;
            }

            if(_cowProfit){
                //开启用户收益
                user.cowProfit = 0;
            }else{
                // 关闭用户收益
                PoolInfo storage pool = poolInfo[_pid];
                user.cowProfit = pool.cowInfo.accCowPerShare;
            }
        }
    }

    // 查询用户收益，返回用户收益,本金
    function pending(uint256 _pid, address _user) public view returns (uint256, uint256, uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        if (user.amount == 0 || pool.totalAmount == 0 ) {
            return (0, 0, user.historyReward);
        } 

        // 增量收益
        uint256 blockReward = pool.cowInfo.blockMdxReward.mul(block.number.sub(pool.lastRewardBlock));
        uint256 reward = countPending(pool, user, blockReward.mul(1e18).div(pool.totalAmount));
        return (reward, user.amount, user.historyReward);
    }

    // 查询用户收益，返回用户收益,本金
    function pendingCow(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        if (user.amount == 0 || pool.totalAmount == 0 ) {
            return 0;
        }

        // 增量收益
        uint256 blockReward = pool.cowInfo.blockCowReward.mul(block.number.sub(pool.lastRewardBlock));
        return countCowPending(pool, user, blockReward.mul(1e18).div(pool.totalAmount));
    }

    // 获取token累计的mdx收益，调用controller获取
    function getMdxBlockReward(address token) public view returns (uint256) {
        PoolInfo storage pool = getPoolInfo(token);
        return pool.accMdxShare;
    }

    function getBlockReward (uint pid) public view returns (uint256, uint256) {
        return (poolInfo[pid].cowInfo.blockMdxReward, poolInfo[pid].cowInfo.blockCowReward);
    }
     
    /*********************** 封装给web3j调用的接口 ********************/
    // 查询币种对应年化收益率
    function getApy(address token) external view returns (uint256) {
        PoolInfo storage pool = getPoolInfo(token);
        //计算年化利率万分比，按3秒一个块算 *86400*365/3/1e18
        return pool.cowInfo.blockMdxReward.mul(max).mul(10512000).div(pool.totalAmount.add(1));
    }

    // 查询币种对应年化收益率
    function getCowApy(address token) external view returns (uint256) {
        PoolInfo storage pool = getPoolInfo(token);
        //计算年化利率万分比，按3秒一个块算 *86400*365/3
        return pool.cowInfo.blockCowReward.mul(max).mul(10512000).div(pool.totalAmount.add(1));
    }

    // 查询用户已收益
    function earned(address token, address userAddress) external view returns (uint256) {
        (uint256 reward,,) = pending(getPoolId(token), userAddress);
        return reward;
    }

    // 查询用户已存入资金
    function getDepositAsset(address token, address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[getPoolId(token)][userAddress];
        return user.amount;
    }
}