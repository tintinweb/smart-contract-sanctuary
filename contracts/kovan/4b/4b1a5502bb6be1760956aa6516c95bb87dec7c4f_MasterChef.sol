/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMasterChefMinter {
    /**
     * @dev Returns the result of transOpter.
     */
    function setTransOpter() external view returns (bool);

    /**
     * @dev Returns the result of tokens trans out.
     */
    function transferOut(address token,uint256 amount,address to) external view returns (bool);
   
}


interface IIncomePool {
    //手续费持有账户
    function getFeeOwners() view external returns(address,address,address);

    //增加拥有者卖出手续费
    function addSellOwnerFee(uint256 poolFee,uint256 congressFee,uint256 partnerFee) external;

    //增加卖出手续费
    function addSellFee(uint256 fee) external;

    //获取累计卖出手续费
    function getTotalSellFee() external view returns (uint256);

    //获取日期卖出手续费
    function getDateSellFee(uint date) external view returns (uint256);

    //增加拥有者挖矿手续费
    function addMineOwnerFee(uint256 poolFee,uint256 congressFee,uint256 partnerFee) external;

    //增加挖矿手续费
    function addMineFee(uint256 fee) external;

    //获取累计挖矿手续费
    function getTotalMineFee() external view returns (uint256);

    //获取日期挖矿手续费
    function getDateMineFee(uint date) external view returns (uint256);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/MasterChef.sol


interface IToken {
    function mint(address _to, uint256 _amount) external;
}

// 迁移合约接口
interface IMigratorChef {
    // 执行从旧版UniswapV2到GoSwap的LP令牌迁移
    // Perform LP token migration from legacy UniswapV2 to GoSwap.
    // 获取当前的LP令牌地址并返回新的LP令牌地址
    // Take the current LP token address and return the new LP token address.
    // 迁移者应该对调用者的LP令牌具有完全访问权限
    // Migrator should have full access to the caller's LP token.
    // 返回新的LP令牌地址
    // Return the new LP token address.
    //
    // XXX Migrator必须具有对UniswapV2 LP令牌的权限访问权限
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    //
    // GoSwap必须铸造完全相同数量的GoSwap LP令牌，否则会发生不良情况。
    // 传统的UniswapV2不会这样做，所以要小心！
    // GoSwap must mint EXACTLY the same amount of GoSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef是GoSwap的主人。他可以做RewardToken，而且他是个好人。
//
// 请注意，它是可拥有的，所有者拥有巨大的权力。
// 一旦RewardToken得到充分分配，所有权将被转移到治理智能合约中，
// 并且社区可以展示出自我治理的能力
//
// 祝您阅读愉快。希望它没有错误。上帝保佑。

// MasterChef is the master of GoSwap. He can make GoSwap and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once RewardToken is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // 用户信息
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.用户提供了多少个LP令牌。
        uint256 rewardDebt; // Reward debt. See explanation below.已奖励数额。请参阅下面的说明。
        //
        // 我们在这里做一些有趣的数学运算。基本上，在任何时间点，授予用户但待分配的RewardToken数量为：
        // We do some fancy math here. Basically, any point in time, the amount of RewardTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   待处理的奖励 =（user.amount * pool.accRewardTokenPerShare）-user.rewardDebt
        //   pending reward = (user.amount * pool.accRewardTokenPerShare) - user.rewardDebt
        //
        // 每当用户将lpToken存入到池子中或提取时。这是发生了什么：
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. 池子的每股累积RewardToken(accRewardTokenPerShare)和分配发生的最后一个块号(lastRewardBlock)被更新
        //   1. The pool's `accRewardTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. 用户收到待处理奖励。
        //   2. User receives the pending reward sent to his/her address.
        //   3. 用户的“amount”数额被更新
        //   3. User's `amount` gets updated.
        //   4. 用户的`rewardDebt`已奖励数额得到更新
        //   4. User's `rewardDebt` gets updated.
    }

    // 池子信息
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.LP代币合约的地址
        uint256 allocPoint; // How many allocation points assigned to this pool. RewardTokens to distribute per block.分配给该池的分配点数。 RewardToken按块分配
        uint256 lastRewardBlock; // Last block number that RewardTokens distribution occurs.RewardTokens分配发生的最后一个块号
        uint256 accRewardTokenPerShare; // Accumulated RewardTokens per share, times 1e12. See below.每股累积RewardToken乘以1e12。见下文
    }

    // The RewardToken TOKEN!
    address public constant rewardToken = 0x0338fE2461c966d15F700B926E6BE6f0EdC15694;
     //收入统计合约 
    address public constant incomePool = 0x8911fD220256493a43f7D734722f3158A53c1943;
    address public poolOwner; //分红池地址
    uint256 public poolRatio=15; //分红池比率
    address public congressOwner; //国会手续费地址
    uint256 public congressRatio=6; //国会手续费比率
    address public partnerOwner; //合伙人地址
    uint256 public partnerRatio=9; //合伙人比率
   
    // 奖励周期区块数量
    uint256 public constant EPOCH_PERIOD = 1;
    // 奖金乘数
    uint256 public constant BONUS_MULTIPLIER = 1;
    // 奖励结束块号
    // Block number when bonus Token period ends.
    uint256 public bonusEndBlock;
    // RewardToken tokens created per block.
    uint256 public rewardPerBlock;
    // 迁移者合同。它具有很大的力量。只能通过治理（所有者）进行设置
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // 池子信息数组
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // 池子ID=>用户地址=>用户信息 的映射
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // 总分配点。必须是所有池中所有分配点的总和
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // RewardToken挖掘开始时的块号
    // The block number when RewardToken mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    ); //紧急情况
    event SetMigrator(address indexed migrator);
    event SetRewardPerBlock(uint256 amount);

    /**
     * @dev 构造函数
     * @param _startBlock RewardToken挖掘开始时的块号
     * @param _rewardPerBlock 每个块奖励数
     */
    constructor(uint256 _startBlock,uint256 _rewardPerBlock) public {
        startBlock = _startBlock;
        bonusEndBlock = startBlock.add(EPOCH_PERIOD);
        rewardPerBlock=_rewardPerBlock;
    }

    //设置比率
    function setRatios(uint256 _poolRatio,uint256 _congressRatio,uint256 _partnerRatio)  public onlyOwner
    {
        poolRatio=_poolRatio;
        partnerRatio=_partnerRatio;
        congressRatio=_congressRatio;
        if (poolRatio+partnerRatio+congressRatio>50){
            revert("The total ratio cannot exceed 50% .");
        }
    }

    /**
     * @dev 返回池子数量
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev 将新的lp添加到池中,只能由所有者调用
     * @param _allocPoint 分配给该池的分配点数。 RewardToken按块分配
     * @param _lpToken LP代币合约的地址
     * @param _withUpdate 触发更新所有池的奖励变量。注意gas消耗！
     */
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX请勿多次添加同一LP令牌。如果您这样做，奖励将被搞砸
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 分配发生的最后一个块号 = 当前块号 > RewardToken挖掘开始时的块号 > 当前块号 : RewardToken挖掘开始时的块号
        uint256 lastRewardBlock =
        block.number > startBlock ? block.number : startBlock;
        // 总分配点添加分配给该池的分配点数
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // 池子信息推入池子数组
        poolInfo.push(
            PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accRewardTokenPerShare: 0
        })
        );
    }

    /**
     * @dev 更新给定池的RewardToken分配点。只能由所有者调用
     * @param _pid 池子ID,池子数组中的索引
     * @param _allocPoint 新的分配给该池的分配点数。 RewardToken按块分配
     * @param _withUpdate 触发更新所有池的奖励变量。注意gas消耗！
     */
    // Update the given pool's RewardToken allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 总分配点 = 总分配点 - 池子数组[池子id].分配点数 + 新的分配给该池的分配点数
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        // 池子数组[池子id].分配点数 = 新的分配给该池的分配点数
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev 将lp令牌迁移到另一个lp合约。可以被任何人呼叫。我们相信迁移合约是正确的
     * @param _pid 池子id,池子数组中的索引
     */
    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) external onlyOwner{
        // 确认迁移合约已经设置
        require(address(migrator) != address(0), "migrate: no migrator");
        // 实例化池子信息构造体
        PoolInfo storage pool = poolInfo[_pid];
        // 实例化LP token
        IERC20 lpToken = pool.lpToken;
        // 查询LP token的余额
        uint256 bal = lpToken.balanceOf(address(this));
        // LP token 批准迁移合约控制余额数量
        lpToken.safeApprove(address(migrator), bal);
        // 新LP token地址 = 执行迁移合约的迁移方法
        IERC20 newLpToken = migrator.migrate(lpToken);
        // 确认余额 = 新LP token中的余额
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        // 修改池子信息中的LP token地址为新LP token地址
        pool.lpToken = newLpToken;
    }

    /**
     * @dev 给出from和to的块号,返回奖励乘积
     * @param _from from块号
     * @param _to to块号
     * @return multiplier 奖励乘数
     */
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
    public
    view
    returns (uint256 multiplier)
    {
        // 如果to块号 <= 奖励结束块号
        if (_to <= bonusEndBlock) {
            // 返回 (to块号 - from块号) * 奖金乘数
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
            // 否则如果 from块号 >= 奖励结束块号
        } else if (_from >= bonusEndBlock) {
            // 返回to块号 - from块号
            return _to.sub(_from);
            // 否则
        } else {
            // 返回 (奖励结束块号 - from块号) * 奖金乘数 + (to块号 - 奖励结束块号)
            return
            bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    /**
     * @dev 查看功能以查看用户的处理中尚未领取的RewardToken
     * @param _pid 池子id
     * @param _user 用户地址
     * @return 处理中尚未领取的RewardToken数额
     */
    // View function to see pending RewardTokens on frontend.
    function pendingRewardToken(uint256 _pid, address _user)
    external
    view
    returns (uint256)
    {
        require(_pid < poolInfo.length, "Invalid pool pid!");
        require(_user != address(0), "Invalid user address!");
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][_user];
        if (user.amount == 0) return 0;
        // 每股累积RewardToken
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        // LPtoken的供应量 = 当前合约在`池子信息.lpToken地址`的余额
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // 如果当前区块号 > 池子信息.分配发生的最后一个块号 && LPtoken的供应量 != 0
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // 奖金乘积 = 获取奖金乘积(分配发生的最后一个块号, 当前块号)
            uint256 multiplier =
            getMultiplier(pool.lastRewardBlock, block.number);
            // RewardToken奖励 = 奖金乘积 * 每块创建的RewardToken令牌 * 池子分配点数 / 总分配点数
            uint256 tokenReward = multiplier
            .mul(rewardPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            // 每股累积RewardToken = 每股累积RewardToken + RewardToken奖励 * 1e12 / LPtoken的供应量
            accRewardTokenPerShare = accRewardTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        // 返回 用户.已添加的数额 * 每股累积RewardToken / 1e12 - 用户.已奖励数额
        return user.amount.mul(accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev 更新所有池的奖励变量。注意汽油消耗
     */
    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public onlyOwner{
        // 池子数量
        uint256 length = poolInfo.length;
        // 遍历所有池子
        for (uint256 pid = 0; pid < length; ++pid) {
            // 升级池子(池子id)
            _updatePool(pid);
        }
    }

    /**
     * @dev 将给定池的奖励变量更新为最新
     * @param _pid 池子id
     */
    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) private {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 如果当前区块号 <= 池子信息.分配发生的最后一个块号
        if (block.number <= pool.lastRewardBlock) {
            // 直接返回
            return;
        }
        // LPtoken的供应量 = 当前合约在`池子信息.lotoken地址`的余额
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // 如果 LPtoken的供应量 == 0
        if (lpSupply == 0) {
            // 池子信息.分配发生的最后一个块号 = 当前块号
            pool.lastRewardBlock = block.number;
            // 返回
            return;
        }
        // 奖金乘积 = 获取奖金乘积(分配发生的最后一个块号, 当前块号)
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // 池子信息.分配发生的最后一个块号 = 当前块号
        pool.lastRewardBlock = block.number;
        if(multiplier == 0) return;
        // RewardToken奖励 = 奖金乘积 * 每块创建的RewardToken令牌 * 池子分配点数 / 总分配点数
        uint256 tokenReward =
        multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
            totalAllocPoint
        );
        if (tokenReward>0){
           IToken(rewardToken).mint(address(this), tokenReward);
        }
        // 每股累积RewardToken = 每股累积RewardToken + RewardToken奖励 * 1e12 / LPtoken的供应量
        pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
    }

    /**
     * @dev 将LP令牌存入MasterChef进行RewardToken分配
     * @param _pid 池子id
     * @param _amount 数额
     */
    // Deposit LP tokens to MasterChef for RewardToken allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 将给定池的奖励变量更新为最新
        _updatePool(_pid);
        // 如果用户已添加的数额>0
        if (user.amount > 0) {
            // 待定数额 = 用户.已添加的数额 * 池子.每股累积RewardToken / 1e12 - 用户.已奖励数额
            uint256 pending =
            user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                // 向当前用户安全发送待定数额的RewardToken
                safeRewardTokenTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            //有效性判断
            if (_amount>pool.lpToken.balanceOf(msg.sender)){
                //如果存入量大于用户资产，全部存入，避免小数精度问题
                _amount=pool.lpToken.balanceOf(msg.sender);
            }
            // 调用池子.lptoken的安全发送方法,将_amount数额的lp token从当前用户发送到当前合约
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            // 用户.已添加的数额  = 用户.已添加的数额 + _amount数额
            user.amount = user.amount.add(_amount);
        }
        // 用户.已奖励数额 = 用户.已添加的数额 * 池子.每股累积RewardToken / 1e12
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(1e12);
        // 触发存款事件
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev 私有方法从MasterChef提取指定数量的LP令牌和收益
     * @param _pid 池子id
     * @param _amount lp数额
     */
    function _withdraw(uint256 _pid, uint256 _amount) private{
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 确认用户.已添加数额 >= _amount数额
        if(user.amount < _amount){
            _amount=user.amount;
        }
        // 将给定池的奖励变量更新为最新
        _updatePool(_pid);
        // 待定数额 = 用户.已添加的数额 * 池子.每股累积RewardToken / 1e12 - 用户.已奖励数额
        uint256 pending = user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            // 向当前用户安全发送待定数额的RewardToken
            safeRewardTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            // 用户.已添加的数额  = 用户.已添加的数额 - _amount数额
            user.amount = user.amount.sub(_amount);
            // 调用池子.lptoken的安全发送方法,将_amount数额的lp token从当前合约发送到当前用户
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        // 用户.已奖励数额 = 用户.已添加的数额 * 池子.每股累积RewardToken / 1e12
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(1e12);
        // 触发提款事件
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev 从MasterChef提取收益
     * @param _pid 池子id
     */
    // Withdraw RewardToken tokens from MasterChef.
    function harvest(uint256 _pid) public {
        _withdraw(_pid, 0);
    }

    /**
     * @dev 从MasterChef提取指定数量的LP令牌和收益
     * @param _pid 池子id
     * @param _amount lp数额
     */
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {
        _withdraw(_pid, _amount);
    }

    /**
     * @dev 从MasterChef提取全部LP令牌和收益
     * @param _pid 池子id
     */
    // Withdraw LP tokens from MasterChef.
    function exit(uint256 _pid) external {
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 确认用户.已添加数额 >0
        require(user.amount > 0, "withdraw: not good");
        // 数量为用户的全部数量
        uint256 amount = user.amount;
        // 调用私有取款
        _withdraw(_pid, amount);
    }

    /**
     * @dev 提款而不关心奖励。仅紧急情况
     * @param _pid 池子id
     */
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_pid];
        // 根据池子id和当前用户地址,实例化用户信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        // 用户.已添加数额 = 0
        user.amount = 0;
        // 用户.已奖励数额 = 0
        user.rewardDebt = 0;
        // 调用池子.lptoken的安全发送方法,将_amount数额的lp token从当前合约发送到当前用户
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        // 触发紧急提款事件
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @dev 安全的RewardToken转移功能，以防万一舍入错误导致池中没有足够的RewardToken
     * @param _to to地址
     * @param _amount 数额
     */
    // Safe RewardToken transfer function, just in case if rounding error causes pool to not have enough RewardTokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        // RewardToken余额 = 当前合约在RewardToken的余额
        uint256 rewardTokenBal = IERC20(rewardToken).balanceOf(address(this));
        // 如果数额 > RewardToken余额
        if (_amount > rewardTokenBal) {
            _amount=rewardTokenBal;
        }  
        uint256 onePercent = _amount.mul(1).div(100);
        if(onePercent > 0){
          (poolOwner,congressOwner,partnerOwner)= IIncomePool(incomePool).getFeeOwners();
          uint256 totalRatio=congressRatio+partnerRatio+poolRatio;
          uint256 p = onePercent.mul(totalRatio);
          _amount=_amount.sub(p);//扣除部分奖励   
          uint256 poolAmount=onePercent.mul(poolRatio);
          IERC20(rewardToken).safeTransfer(poolOwner, poolAmount);
          uint256 congressAmount=onePercent.mul(congressRatio);
          IERC20(rewardToken).safeTransfer(congressOwner, congressAmount);
          uint256 partnerAmount=onePercent.mul(partnerRatio);
          IERC20(rewardToken).safeTransfer(partnerOwner, partnerAmount);
          IIncomePool(incomePool).addMineFee(p);
          IIncomePool(incomePool).addMineOwnerFee(poolAmount,congressAmount,partnerAmount);
        }
        IERC20(rewardToken).safeTransfer(_to, _amount);
    }

    /**
     * @dev 设置迁移合约地址,只能由所有者调用
     * @param _migrator 合约地址
     */
    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) external onlyOwner {
        migrator = _migrator;
        emit SetMigrator(address(_migrator));
    }

    /**
     * @dev 设置每个块奖励数量
     * @param _rewardPerBlock 奖励数量
     */
    // Set Reward Per Block. Can only be called by the owner.
    function setRewardPerBlock(uint256 _rewardPerBlock) public  onlyOwner{
        require(_rewardPerBlock>=0,"set block reward error");
        massUpdatePools();
        rewardPerBlock=_rewardPerBlock;
        emit SetRewardPerBlock(rewardPerBlock);
    }
}