/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// File: localhost/mint/openzeppelin/contracts/utils/Address.sol

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

// File: localhost/mint/openzeppelin/contracts/math/SafeMath.sol

 

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

// File: localhost/mint/openzeppelin/contracts/token/ERC20/SafeERC20.sol

 

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
            "PSafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "PSafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "PSafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "PSafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: localhost/mint/interface/IOracle.sol

 

pragma solidity 0.7.4;

interface IOracle {

    function getPrice(address quote, address base, address extend, uint8 decimal) external view returns (uint8, uint256);

}
// File: localhost/mint/openzeppelin/contracts/utils/Context.sol

 

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

// File: localhost/mint/openzeppelin/contracts/access/Ownable.sol

 

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
    //constructor () internal {
    constructor () {
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
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

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

// File: localhost/mint/tripartitePlatform/publics/ILoanTypeBase.sol

 

pragma solidity 0.7.4;

interface ILoanTypeBase {
    enum LoanType {NORMAL, MARGIN_SWAP_PROTOCOL, MINNING_SWAP_PROTOCOL}
}
// File: localhost/mint/tripartitePlatform/publics/ILoanPublics.sol

 

pragma solidity 0.7.4;


interface ILoanPublics {

    /**
     *@notice 获取依赖资产地址
     *@return (address): 地址
     */
    // function underlying() external view returns (address);

    /**
     *@notice 真实借款数量（本息)
     *@param _account:实际借款人地址
     *@param _loanType:借款类型
     *@return (uint256): 错误码(0表示正确)
     */
    function borrowBalanceCurrent(address _account, uint256 id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

    /**
     *@notice 用户存款
     *@param _mintAmount: 存入金额
     *@return (uint256, uint256): 错误码(0表示正确), 获取pToken数量
     */
    function mint(uint256 _mintAmount) external returns (uint256, uint256);

    /**
     *@notice 用户指定pToken取款
     *@param _redeemTokens: pToken数量
     *@return (uint256, uint256): 错误码(0表示正确), 获取Token数量，对应pToken数量
     */
    function redeem(uint256 _redeemTokens) external returns (uint256, uint256, uint256);

    /**
     *@notice 用户指定Token取款
     *@param _redeemAmount: Token数量
     *@return (uint256, uint256, uint256): 错误码(0表示正确), 获取Token数量，对应pToken数量
     */
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256, uint256, uint256);

    /**
     *@notice 获取用户的资产快照信息
     *@param _account: 用户地址
     *@param _id: 仓位id
     *@param _loanType: 借款类型
     *@return (uint256, uint256, uint256, uint256): 错误码(0表示正确), pToken数量, 借款(快照)数量, 兑换率
     */
    function getAccountSnapshot(address _account, uint256 _id, ILoanTypeBase.LoanType _loanType) external view returns (uint256, uint256, uint256, uint256);

    /**
     *@notice 信用贷借款
     *@param _borrower:实际借款人的地址
     *@param _borrowAmount:实际借款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256): 错误码
     */
    function doCreditLoanBorrow( address payable _borrower, uint256 _borrowAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

    /**
     *@notice 信用贷还款
     *@param _payer:实际还款人的地址
     *@param _repayAmount:实际还款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256, uint256): 错误码, 实际还款数量
     */
    function doCreditLoanRepay(address _payer, uint256 _repayAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256, uint256);

}

// File: localhost/mint/openzeppelin/contracts/token/ERC20/IERC20.sol

 

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
    自行加入
     */
    function decimals() external view returns (uint8);

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

// File: localhost/mint/tripartitePlatform/publics/IPublics.sol

 

pragma solidity 0.7.4;


interface IPublics is IERC20 {

    function claimComp(address holder) external returns (uint256);
    
}
// File: localhost/mint/interface/IAssetPrice.sol

 

pragma solidity 0.7.4;

/**
资产价格
 */
interface IAssetPrice {
    
    /**
    查询资产价格
    
    quote:报价资产合约地址
    base:计价资产合约地址

    code:1
    price:价格
    decimal:精度
     */
    function getPriceV1(address quote, address base) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产价格
    
    quote:报价资产合约地址
    base:计价资产合约地址
    decimal:精度
    
    code:1
    price:价格
     */
    function getPriceV2(address quote, address base, uint8 decimal) external view returns (uint8, uint256);

    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    
    code:1
    price:价格
    decimal:精度
     */
    function getPriceUSDV1(address token) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    decimal:精度
    
    code:1
    price:价格
     */
    function getPriceUSDV2(address token, uint8 decimal) external view returns (uint8, uint256);

    /**
    查询资产价值

    token:报价资产合约地址
    amount:数量
    
    code:1
    usd:USD
    decimal:精度
     */
    function getUSDV1(address token, uint256 amount) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产价值

    token:报价资产合约地址
    amount:数量
    decimal:精度

    code:1
    usd:USD
     */
    function getUSDV2(address token, uint256 amount, uint8 decimal) external view returns (uint8, uint256);
    
}
// File: localhost/mint/interface/IExchange.sol

 

pragma solidity 0.7.4;

interface IExchange {
    
    /**
     * 兑换
     * 
     * from:from
     * to:to
     * amount:amount
     * deadLine:deadLine
     * 
     * return:兑换数量
     */
    function swap(address from, address to, uint256 amount, uint256 deadLine) external returns (uint256);
    
    
    /**
     * 预估兑换
     * 
     * from:from
     * to:to
     * amount:amount
     * 
     * return:预估兑换数量
     */
    function swapEstimate(address from, address to, uint256 amount) external view returns (uint256);

}
// File: localhost/mint/interface/IMintLeverRouter.sol

 

pragma solidity 0.7.4;

interface IMintLeverRouter {
    
    function canClearing(address mintLever, address user) external view returns (bool);

}
// File: localhost/mint/interface/IBorrowProxy.sol

 

pragma solidity 0.7.4;

interface IBorrowProxy {
    
    function setBorrowAccess(address spender, bool state) external;
    
    function borrow(address owner, uint256 id, address tokenA, uint256 amountA, address tokenB, uint256 amountB, address borrowToken, uint256 leverage, uint256 deadLine) external returns(uint256, uint256, uint256);

}
// File: localhost/mint/interface/IApproveProxy.sol

 

pragma solidity 0.7.4;

interface IApproveProxy {
    
    function setClaimAccess(address spender, bool state) external;
    
    function claim(address token, address owner, address spender, uint256 amount) external;
        
}
// File: localhost/mint/interface/IConfig.sol

 

pragma solidity 0.7.4;









interface IConfig {
    
    function getOracleDecimal(address quote, address base) external view returns (uint8, uint8);
    
    function getOracleSources(address quote, address base) external view returns (uint8, address[] memory, uint8[] memory, address[] memory);
    
    function getApproveProxy() external view returns (IApproveProxy);
    
    function getBorrowProxy() external view returns (IBorrowProxy);
    
    function getRouter() external view returns (IMintLeverRouter);

    function getAssetPrice() external view returns (IAssetPrice);
    
    function getLoanPublics(address token) external view returns (ILoanPublics);

    function tryGetLoanPublics(address token) external view returns (ILoanPublics);
    
    function isBond(address token) external view returns (bool);

    function isLoan(address token) external view returns (bool);

    function getExchange() external view returns (IExchange);

    function getPublics() external view returns (IPublics);
    
    function getPlatformFee() external view returns (address);
    
    function getSlippage() external view returns (uint256);

    function isBlacklist(address user) external view returns (bool);
    
    function isOpen(address mintLever) external view returns (bool);
    
    function isDirectClearing(address mintLever) external view returns (bool);

    function getLeverage(address mintLever) external view returns (uint256, uint256);

    function isLeverage(address mintLever, uint256 leverage) external view returns (bool);
    
    function getPlatformTakeRate(address mintLever) external view returns (uint256);
    
    function getClearingEarningRate(address mintLever) external view returns (uint256);
    
    function getClearingPlatformEarningRate(address mintLever) external view returns (uint256);
    
    function getMaxRiskRate(address mintLever) external view returns (uint256);

}
// File: localhost/mint/implement/ConfigBase.sol

 

pragma solidity 0.7.4;



contract ConfigBase is Ownable {
    
    event Config_(address indexed config);
    
    IConfig public config;
    
    constructor (IConfig _config) {
        require(address(0) != address(_config), "publics:config_is_zero");
        config = _config;
        emit Config_(address(_config));
    }
    
    function setConfig(IConfig _config) external onlyOwner {
        require(address(0) != address(_config), "publics:config_is_zero");
        config = _config;
        emit Config_(address(_config));
    }
    
}
// File: localhost/mint/implement/AssetPrice.sol

 

pragma solidity 0.7.4;






contract AssetPrice is IAssetPrice, ConfigBase {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public constant USD = address(1);
    
    constructor (IConfig _config) ConfigBase(_config) {
    }
    
    function getPriceV1(address quote, address base) override external view returns (uint8, uint256, uint8) {
        return _getPrice(quote, base);
    }
    
    function getPriceV2(address quote, address base, uint8 decimal) override external view returns (uint8, uint256) {
        return _getPrice(quote, base, decimal);
    }
    
    function getPriceUSDV1(address token) override external view returns (uint8, uint256, uint8) {
        return _getPrice(token, USD);
    }
    
    function getPriceUSDV2(address token, uint8 decimal) override external view returns (uint8, uint256) {
        return _getPrice(token, USD, decimal);
    }
    
    function getUSDV1(address token, uint256 amount) override external view returns (uint8, uint256, uint8) {
        return _getUSD(token, amount);
    }

    function getUSDV2(address token, uint256 amount, uint8 decimal) override external view returns (uint8, uint256) {
        return _getUSD(token, amount, decimal);
    }
    
    function _getPrice(address quote, address base) internal view returns (uint8, uint256, uint8) {
        (uint8 code, uint8 decimal) = config.getOracleDecimal(quote, base);
        require(1 == code, "publics:get_oracle_decimal_error");
        uint256 price;
        (code, price) = _getPrice(quote, base, decimal);
        return (code, price, decimal);
    }
    
    function _getPrice(address quote, address base, uint8 decimal) internal view returns (uint8, uint256) {
        uint8 code;
        address[] memory oracles;
        uint8[] memory ratios;
        address[] memory extends;
        (code, oracles, ratios, extends) = config.getOracleSources(quote, base);
        require(1 == code, "publics:get_oracle_sources_error");
        uint256[] memory prices = new uint256[](oracles.length);
        uint256 price;
        uint256 ratio;
        for (uint256 i = 0; i < oracles.length; i++) {
            if (0 < ratios[i]) {
                (code, price) = IOracle(oracles[i]).getPrice(quote, base, extends[i], decimal);
                require(1 == code, "publics:get_price_error");
                prices[i] = price;
                ratio = ratio.add(ratios[i]);
            }else {
                prices[i] = 0;
            }
        }
        require(0 < ratio, "publics:price_data_source_invalid");
        price = 0;
        for (uint256 i = 0; i < ratios.length; i++) {
            price = price.add(prices[i].mul(ratio).mul(ratios[i]).div(ratio));
        }
        return (1, price.div(ratio));
    }
    
    function _getUSD(address token, uint256 amount) internal view returns (uint8, uint256, uint8) {
        (uint8 code, uint8 decimal) = config.getOracleDecimal(token, USD);
        require(1 == code, "publics:get_oracle_decimal_error");
        uint256 usd;
        (code, usd) = _getUSD(token, amount, decimal);
        return (code, usd, decimal);
    }
    
    function _getUSD(address token, uint256 amount, uint8 decimal) internal view returns (uint8, uint256) {
        (uint8 code, uint256 price) = _getPrice(token, USD, decimal);
        require(1 == code, "publics:get_price_error");
        uint256 usd = price.mul(amount);
        decimal = IERC20(token).decimals();
        if (0 < decimal) {
            usd = usd.div(10 ** decimal);
        }
        return (1, usd);
    }

}