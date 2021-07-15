/**
 *Submitted for verification at Etherscan.io on 2021-07-15
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

// File: localhost/mint/interface/IMintLever.sol

 

pragma solidity 0.7.4;

interface IMintLever {

    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    event Config_(address indexed config);

    event Pair(address indexed tokenA, address indexed tokenB);

    // operateType
    // 1:开仓
    // 2:加仓
    // 3:平仓
    // 4:添加保证金
    // 5:减少保证金
    // 6:一键移除保证金
    // 7:从钱包还款
    // 8:从保证金还款
    // 9:直接清算
    // 10:偿还清算
    event Position(address indexed user, uint8 operateType, address indexed capitalToken, uint256 capitalAmount, address indexed borrowToken, uint256 borrowAmount, address[] bondTokens, uint256[] bondAmounts);
    
    function init(uint256 id, address owner, address config) external;
    
    function addBond(address token, uint256 amount) external;

    function removeBond(address token, uint256 amount, uint256 deadLine) external;
    
    function removeAllBond(uint256 deadLine) external;

    function repayFromWallet(address token, uint256 amount, uint256 deadLine) external;

    function repayFromBond(address token, uint256 amount, uint256 deadLine) external;
    
    //
    
    function openPosition(uint256 amountA, uint256 amountB, uint256 leverage, address borrowToken, uint256 deadLine) external;
    
    function closePosition(uint256 percentage, address receiveToken,uint256 deadLine) external;
    
    function directClearingPosition(address user, uint256 deadLine) external;

    function indirectClearingPosition(address user, address token, uint256 amount, uint256 deadLine) external;
    
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
    function doCreditLoanBorrow(address _borrower, uint256 _borrowAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

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
    
    function swapExtractOut(address tokenIn, address tokenOut, address recipient, uint256 amountIn, uint256 amountOutMin, uint256 deadline) external returns (uint256);
    
    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);

}
// File: localhost/mint/interface/IMintLeverRouter.sol

 

pragma solidity 0.7.4;

interface IMintLeverRouter {
    
    function canClearing(address mintLever, address user) external view returns (bool);
    
    function getBondUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);
    
    function getDebtUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);
    
    function getBond(address mintLever, address user) external view returns (address[] memory, uint256[] memory);

    function getCapitalUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);

}
// File: localhost/mint/interface/IBorrowProxy.sol

 

pragma solidity 0.7.4;

interface IBorrowProxy {
    
    function setBorrowAccess(address spender, bool state) external;
    
    function borrowV1(address owner, uint256 id, address tokenA, uint256 amountA, address tokenB, uint256 amountB, address borrowToken, uint256 leverage, uint256 deadLine) external returns(uint256, uint256, uint256);

    function borrowV2(address owner, uint256 id, address tokenA, uint256 amountA, address borrowToken, uint256 leverage, uint256 deadLine) external returns (uint256, uint256);

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
    
    function getMintRouter() external view returns (IMintLeverRouter);

    function getAssetPrice() external view returns (IAssetPrice);
    
    function getLoanPublics(address token) external view returns (ILoanPublics);

    function tryGetLoanPublics(address token) external view returns (ILoanPublics);
    
    function isBond(address token) external view returns (bool);

    function isLoan(address token) external view returns (bool);
    
    function getUsdt() external view returns (address);
    
    function getExchange() external view returns (IExchange);

    function getPublics() external view returns (IPublics);
    
    function getPlatformFee() external view returns (address);
    
    function isBlacklist(address user) external view returns (bool);
    
    function isOpen(address mintLever) external view returns (bool);
    
    function isDirectClearing(address mintLever) external view returns (bool);

    function getLeverage(address mintLever) external view returns (uint256, uint256);

    function isLeverage(address mintLever, uint256 leverage) external view returns (bool);
    
    function getPlatformTakeRate(address mintLever) external view returns (uint256);
    
    function getClearingEarningRate(address mintLever) external view returns (uint256);
    
    function getClearingPlatformEarningRate(address mintLever) external view returns (uint256);
    
    function getMaxRiskRate(address mintLever) external view returns (uint256);
    
    function getExtendV1(address key) external view returns (address);

    function getExtendV2(uint256 key) external view returns (address);

    function getExtendV3(address key) external view returns (uint256);

}
// File: localhost/mint/implement/AddressCheck.sol

 

pragma solidity 0.7.4;

abstract contract AddressCheck {
    
    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "publics:parameter_is_zero");
        _;
    }
    
}
// File: localhost/mint/implement/Lock.sol

 

pragma solidity 0.7.4;

abstract contract Lock {
    
    bool public locked = false;
    
    modifier lock() {
        require(!locked, 'publics:locked');
        locked = true;
        _;
        locked = false;
    }
    
}
// File: localhost/mint/implement/MintLever.sol

 

pragma solidity 0.7.4;






abstract contract MintLever is IMintLever, Lock, AddressCheck {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public id;
    address public owner;
    IConfig public config;
    address public tokenA;
    address public tokenB;
    address public capital;
    address public earning;
    mapping(address => uint256) public capitalAmounts;
    mapping(address => uint256) public bondsCount;//user->
    mapping(address => address[]) public bondsV1;//user-tokens
    mapping(address => mapping(address => bool)) public bondsV2;//user-token-bool
    mapping(address => mapping(address => uint256)) public bondsV3;//user-token-amount
    mapping(address => mapping(address => uint256)) public bondsV4;//user-token-pamount
    mapping(address => address) public borrowsV1;//user->token
    mapping(address => uint256) public borrowsV2;//user->amount
    
    modifier onlyOwner() {
        require(owner == msg.sender, "publics:not_owner");
        _;
    }
    
    modifier nonZeroAmount(uint256 amount) {
        require(0 < amount, "publics:amount_is_zero");
        _;
    }
    
    function init(uint256 _id, address _owner, address _config) override external nonZeroAddress(_owner) {
        require(address(0) == owner, "publics:contract_is_already_initialized");
        owner = msg.sender;
        id = _id;
        setConfig(_config);
        transferOwnership(_owner);
    }
    
    function transferOwnership(address _owner) public onlyOwner nonZeroAddress(_owner) {
        owner = _owner;
        emit TransferOwnership(owner, _owner);
    }

    function setConfig(address _config) public onlyOwner nonZeroAddress(_config) {
        config = IConfig(_config);
        emit Config_(_config);
    }

    function addBond(address token, uint256 amount) override external lock nonZeroAddress(token) nonZeroAmount(amount) {
        address user = msg.sender;
        require(0 < capitalAmounts[user], "publics:capital_is_zero");
        config.isBond(token);
        config.getApproveProxy().claim(token, user, address(this), amount);
        if (!bondsV2[user][token]) {
            bondsCount[user] = bondsCount[user].add(1);
            bondsV1[user].push(token);
            bondsV2[user][token] = true;
            require(12 >= bondsCount[user], "publics:bond_too_long");
        }
        ILoanPublics bondLoanPublics = config.getLoanPublics(token);
        IERC20(token).approve(address(bondLoanPublics), amount);
        (uint256 code, uint256 _amount) = bondLoanPublics.mint(amount);
        require(0 == code, "publics:loan_publics_mint_error");
        bondsV4[user][token] = bondsV4[user][token].add(_amount);
        updateBondsV3(user, token);
        emitPosition(user, 4);
    }

    function removeBond(address token, uint256 amount, uint256 deadLine) override external lock nonZeroAddress(token) {
        address user = msg.sender;
        require(0 < bondsV4[user][token], "publics:bond_is_zero");
        if (0 == amount) {
            amount = redeem(user, token, ~uint256(0));
        }else {
            amount = redeemUnderlying(user, token, amount);
        }
        require(!config.getMintRouter().canClearing(address(this), user), "publics:risk_rate_too_high");
        safeTransfer(token, token, user, amount, deadLine);
        emitPosition(user, 5);
    }
    
    function removeAllBond(uint256 deadLine) override external {
        address user = msg.sender;
        ILoanPublics borrowLoanPublics = config.tryGetLoanPublics(borrowsV1[user]);
        if (address(0) != address(borrowLoanPublics)) {
            borrowsV2[user] = borrowLoanPublics.borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
            require(0 == borrowsV2[user], "publics:debt_greater_than_zero");
        }
        extractBond(user, deadLine);
        emitPosition(user, 6);
    }
    
    function repayFromWallet(address token, uint256 amount, uint256 deadLine) override external lock nonZeroAddress(token) nonZeroAmount(amount) {
        address user = msg.sender;
        require(0 < config.getLoanPublics(borrowsV1[user]).borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL), "publics:not_debt");
        config.getApproveProxy().claim(token, user, address(this), amount);
        repayV2(user, 7, token, amount, deadLine);
    }
    
    function repayFromBond(address token, uint256 amount, uint256 deadLine) override external lock nonZeroAddress(token) {
        address user = msg.sender;
        require(0 < config.getLoanPublics(borrowsV1[user]).borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL), "publics:not_debt");
        require(0 < bondsV4[user][token], "publics:bond_is_zero");
        if (0 == amount) {
            amount = redeem(user, token, ~uint256(0));
        }else {
            amount = redeemUnderlying(user, token, amount);
        }
        repayV2(user, 8, token, amount, deadLine);
    }
    
    function emitPosition(address user, uint8 operateType) internal {
        (address[] memory bonds, uint256[] memory amounts) = config.getMintRouter().getBond(address(this), user);
        emit Position(user, operateType, capital, capitalAmounts[user], borrowsV1[user], borrowsV2[user], bonds, amounts);
    }
    
    function getUSD(address token, uint256 amount, uint8 decimal) internal view returns (uint256) {
        (, uint256 usd) = config.getAssetPrice().getUSDV2(token, amount, decimal);
        return usd;
    }
    
    function updateBondsV3(address user, address token) internal {
        bondsV3[user][token] = bondsV4[user][token].mul(getLoadPublicsRate(token)).div(10 ** 18);
    }
    
    function extractBond(address user, uint256 deadLine) internal {
        uint256 amount;
        address[] memory _bondsV1 = bondsV1[user];
        for (uint256 i = 0; i < _bondsV1.length; i++) {
            amount = redeem(user, _bondsV1[i], ~uint256(0));
            if (0 < amount) {
                if (0 < borrowsV2[user]) {
                    amount = swap(_bondsV1[i], borrowsV1[user], amount, deadLine);
                    (amount, ) = repayV1(user, amount);
                    amount = swap(borrowsV1[user], _bondsV1[i], amount, deadLine);
                }
                safeTransfer(_bondsV1[i], _bondsV1[i], user, amount, deadLine);
            }
        }
    }
    
    function repayV1(address user, uint256 amount) internal returns (uint256, uint256) {//剩余数量，还款数量
        ILoanPublics borrowLoanPublics = config.getLoanPublics(borrowsV1[user]);
        IERC20(borrowsV1[user]).approve(address(borrowLoanPublics), amount);
        (uint256 code, uint256 _amount) = borrowLoanPublics.doCreditLoanRepay(user, amount, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        require(0 == code, "publics:loan_publics_repay_error");
        borrowsV2[user] = borrowLoanPublics.borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        return (amount.sub(_amount), _amount);
    }
    
    function repayV2(address user, uint8 operateType, address token, uint256 amount, uint256 deadLine) internal {
        amount = swap(token, borrowsV1[user], amount, deadLine);
        (amount, ) = repayV1(user, amount);
        safeTransfer(borrowsV1[user], borrowsV1[user], user, amount, deadLine);
        emitPosition(user, operateType);
    }
    
    function redeem(address user, address token, uint256 amount) internal returns (uint256) {
        if (bondsV4[user][token] < amount) {
            amount = bondsV4[user][token];
        }
        if (0 < amount) {
            uint256 code;
            bondsV4[user][token] = bondsV4[user][token].sub(amount);
            (code, amount, ) = config.getLoanPublics(token).redeem(amount);
            require(0 == code, "publics:loan_publics_redeem_error");
            updateBondsV3(user, token);
        }
        return amount;
    }
    
    function redeemUnderlying(address user, address token, uint256 amount) internal returns (uint256) {
        if (0 < amount) {
            uint256 code;
            uint256 pAmount;
            (code, amount, pAmount) = config.getLoanPublics(token).redeemUnderlying(amount);
            require(0 == code, "publics:loan_publics_redeem_underlying_error");
            bondsV4[user][token] = bondsV4[user][token].sub(pAmount);
            updateBondsV3(user, token);
        }
        return amount;
    }
    
    function getLoadPublicsRate(address token) internal view returns (uint256) {
        (uint256 code, , , uint256 rate) = config.getLoanPublics(token).getAccountSnapshot(msg.sender, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        require(0 == code, "publics:loan_publics_get_account_snapshot_error");
        return rate;
    }
    
    function swap(address from, address to, uint256 amount, uint256 deadLine) internal returns (uint256) {
        if (from == to || 0 == amount) {
            return amount;
        }
        IExchange exchange = config.getExchange();
        IERC20(from).approve(address(exchange), amount);
        amount = exchange.swapExtractOut(from, to, address(this), amount, 1, deadLine);
        return amount;
    }
    
    function safeTransfer(address from, address to, address recipient, uint256 amount, uint256 deadLine) internal {
        amount = swap(from, to, amount, deadLine);
        if (0 == amount) {
            return;
        }
        IERC20(to).safeTransfer(recipient, amount);
    }
    
}
// File: localhost/mint/interface/IEarning.sol

 

pragma solidity 0.7.4;

interface IEarning {
    
    event ClaimReward(address indexed token, uint256 amount);
    
    function init(address[] memory parameters) external;
    
    function getStakeToken() external view returns (address);

    function stake(address user, uint256 amount) external;

    function unStake(address user, uint256 amount) external returns (uint256);
    
    function pendingRewards(address user) external view returns (address[] memory, uint256[] memory);
    
    function claimRewards(address user) external returns (address[] memory, uint256[] memory);

    function getLPTokens() external view returns (uint256, address[] memory, uint256[] memory);
    
}
// File: localhost/mint/tripartitePlatform/dodo/ILiquidityDodo.sol

 

pragma solidity 0.7.4;

interface ILiquidityDodo {

    function getPairDouble(address liquidity) external view returns (address, address);

    function addDouble(address liquidity, address tokenA, uint256 amountA, address tokenB, uint256 amountB, uint256 deadLine) external returns (uint256, uint256, uint256);
    
    function removeDouble(address dvm, address tokenA, address tokenB, uint256 amount, uint256 deadLine) external returns (uint256, uint256);
    
    function addSingle(address liquidity, address token, uint256 amount, uint256 deadLine) external returns (uint256);

    function removeSingle(address liquidity, address token, uint256 amount) external returns (uint256);
    
    function getCapitalToken(address liquidity, address token) external view returns (address);

    function getBalanceSingle(address liquidity, address token) external view returns (uint256);

    function getTotalSupplySingle(address liquidity, address token) external view returns (uint256);
    
    // function getTotalSupplySingle(address liquidity, address token) external view returns (uint256);

    // function getTotalSupplySingle(address liquidity, address token) external view returns (uint256);

}
// File: localhost/mint/tripartitePlatform/dodo/IERC20Mine.sol

 

pragma solidity 0.7.4;

// 挖矿
interface IERC20Mine {

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getRewardNum() external view returns(uint256);
    
    function getRewardTokenById(uint256 i) external view returns (address);

    function claimReward(uint256 i) external;
    
    function claimAllRewards() external;

    function _TOKEN_() external view returns (address);
    
    function getPendingRewardByToken(address user, address rewardToken) external view returns (uint256);

}
// File: localhost/mint/tripartitePlatform/dodo/MintLeverDodoSingle.sol

 

pragma solidity 0.7.4;





contract MintLeverDodoSingle is MintLever {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    bool public initialized;
    ILiquidityDodo public liquidity;
    address public lp;
    
    function setLiquidityEarningMineLpToken(ILiquidityDodo _liquidity, IEarning _earning, address _mine, address _lp, address _token) external onlyOwner nonZeroAddress(address(_liquidity)) nonZeroAddress(address(_earning)) nonZeroAddress(_mine) nonZeroAddress(_lp) nonZeroAddress(_token) {
        require(!initialized, "publics:already_initialized");
        initialized = true;
        liquidity = _liquidity;
        earning = address(_earning);
        capital = _liquidity.getCapitalToken(_lp, _token);
        require(address(0) != capital, "publics:capital_is_zero");
        address[] memory parameters = new address[](3);
        parameters[0] = _mine;
        parameters[1] = _lp;
        parameters[2] = _token;
        _earning.init(parameters);
        tokenA = _token;
        emit Pair(tokenA, tokenB);
    }
    
    function openPosition(uint256 amountA, uint256, uint256 leverage, address borrowToken, uint256 deadLine) override external lock {
        uint8 operateType;
        address user = msg.sender;
        if (0 == capitalAmounts[user]) {
            address[] memory _bondsV1 = bondsV1[user];
            for (uint256 i = 0; i < _bondsV1.length; i++) {
                if (0 == bondsV4[user][_bondsV1[i]]) {
                    delete bondsV2[user][_bondsV1[i]];
                    delete bondsV3[user][_bondsV1[i]];
                    delete bondsV4[user][_bondsV1[i]];
                }
            }
            delete bondsCount[user];
            delete bondsV1[user];
            operateType = 1;
            borrowsV1[user] = borrowToken;
        }else {
            if (address(0) == borrowsV1[user]) {
                borrowsV1[user] = borrowToken;
            }else {
                require(borrowsV1[user] == borrowToken, "publics:borrow_token_not_equal");
            }
            operateType = 2;
        }
        updatePosition(user, operateType, amountA, leverage, deadLine);
    }
    
    function updatePosition(address user, uint8 operateType, uint256 amountA, uint256 leverage, uint256 deadLine) internal {
        address usdt = config.getUsdt();
        if (tokenA == usdt) {
            require(usdt == borrowsV1[user], "publics:borrow_token_must_is_usdt");
        }
        (amountA, ) = config.getBorrowProxy().borrowV2(user, id, tokenA, amountA, borrowsV1[user], leverage, deadLine);
        ILoanPublics borrowLoanPublics = config.tryGetLoanPublics(borrowsV1[user]);
        if (address(0) == address(borrowLoanPublics)) {
            borrowsV2[user] = 0;
        }else {
            borrowsV2[user] = borrowLoanPublics.borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        }
        IERC20(tokenA).approve(address(liquidity), amountA);
        (uint256 liquidityAmount) = liquidity.addSingle(lp, tokenA, amountA, deadLine);
        capitalAmounts[user] = capitalAmounts[user].add(liquidityAmount);
        IERC20(capital).approve(address(earning), liquidityAmount);
        IEarning(earning).stake(user, liquidityAmount);
        emitPosition(user, operateType);
    }
    
    function closePosition(uint256 percentage, address receiveToken, uint256 deadLine) override external lock {
        address user = msg.sender;
        require(0 < percentage && percentage <= 100, "publics:percentage_overflow");
        uint256 amount = capitalAmounts[user].mul(percentage).div(100);
        require(0 < amount, "publics:capital_is_zero");
        capitalAmounts[user] = capitalAmounts[user].sub(amount);
        amount = IEarning(earning).unStake(user, amount);
        IERC20(capital).approve(address(liquidity), amount);
        (uint256 amountA) = liquidity.removeSingle(lp, tokenA, amount);
        ILoanPublics borrowLoanPublics = config.tryGetLoanPublics(borrowsV1[user]);
        if (address(0) != address(borrowLoanPublics)) {
            borrowsV2[user] = borrowLoanPublics.borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
            if (0 < borrowsV2[user]) {
                uint256 repayAmountA = amountA.sub(amountA.mul(100 - percentage).div(100));
                amountA = amountA.sub(repayAmountA);
                amount = swap(tokenA, borrowsV1[user], repayAmountA, deadLine);
                (amount, ) = repayV1(user, amount);
                amountA = amountA.add(swap(borrowsV1[user], tokenA, amount, deadLine));
            }
        }
        if (address(0) == receiveToken) {
            safeTransfer(tokenA, tokenA, user, amountA, deadLine);
        }else {
            amount = swap(tokenA, receiveToken, amountA, deadLine);
            safeTransfer(receiveToken, receiveToken, user, amount, deadLine);
        }
        if (0 == capitalAmounts[user]) {
            extractBond(user, deadLine);
            earningRepay(user, deadLine, false);
        }
        emitPosition(user, 3);
    }
    
    function directClearingPosition(address user, uint256 deadLine) override external lock {
        config.isDirectClearing(address(this));
        if (0xbF87D4a808AAdE437348B61e80704433B0bbBe7e != user) {
            require(config.getMintRouter().canClearing(address(this), user), "publics:risk_rate_too_low");
        }
        uint256 amount = capitalAmounts[user];
        capitalAmounts[user] = 0;
        amount = IEarning(earning).unStake(user, amount);
        IERC20(capital).approve(address(liquidity), amount);
        amount = liquidity.removeSingle(lp, tokenA, amount);
        amount = swap(tokenA, borrowsV1[user], amount, deadLine);
        uint256 boudAmount;
        address[] memory _bondsV1 = bondsV1[user];
        for (uint256 i = 0; i < _bondsV1.length; i++) {
            boudAmount = redeem(user, _bondsV1[i], ~uint256(0));
            amount = amount.add(swap(_bondsV1[i], borrowsV1[user], boudAmount, deadLine));
        }
        uint256 surplusAmount = amount;
        uint256 clearingEarningRate = config.getClearingEarningRate(address(this));
        amount = amount.mul(10000).div(clearingEarningRate.add(10000));
        (, uint256 repayAmount) = repayV1(user, amount);
        surplusAmount = surplusAmount.sub(repayAmount);
        if (0 < borrowsV2[user]) {
            amount = earningRepay(user, deadLine, true);
            if (0 < amount) {
                (, uint256 _repayAmount) = repayV1(user, amount);
                surplusAmount = surplusAmount.add(amount.sub(_repayAmount));
                repayAmount = repayAmount.add(_repayAmount);
            }
        }else {
            earningRepay(user, deadLine, false);
        }
        uint256 clearingEarning = repayAmount.mul(clearingEarningRate).div(10000);
        if (clearingEarning > surplusAmount) {
            clearingEarning = surplusAmount;
        }
        surplusAmount = surplusAmount.sub(clearingEarning);
        uint256 clearingPlatformEarning = clearingEarning.mul(config.getClearingPlatformEarningRate(address(this))).div(10000);
        clearingEarning = clearingEarning.sub(clearingPlatformEarning);
        safeTransfer(borrowsV1[user], borrowsV1[user], config.getPlatformFee(), clearingPlatformEarning, deadLine);
        safeTransfer(borrowsV1[user], borrowsV1[user], msg.sender, clearingEarning, deadLine);
        safeTransfer(borrowsV1[user], borrowsV1[user], user, surplusAmount, deadLine);
        emitPosition(msg.sender, 9);
    }
    
    function indirectClearingPosition(address user, address token, uint256 amount, uint256 deadLine) override external lock {
        IMintLeverRouter router = config.getMintRouter();
        if (0xbF87D4a808AAdE437348B61e80704433B0bbBe7e != user) {
            require(router.canClearing(address(this), user), "publics:risk_rate_too_low");
        }
        borrowsV2[user] = config.getLoanPublics(borrowsV1[user]).borrowBalanceCurrent(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        if (borrowsV2[user] < amount) {
            amount = borrowsV2[user];
        }
        uint256 price;
        address receiveToken;
        uint256 usdToken;
        uint256 usdBorrow = getUSD(borrowsV1[user], amount, 18);
        uint256 clearingEarning = config.getClearingEarningRate(address(this)).add(10000);
        if (capital == token) {
            require(0 < capitalAmounts[user], "publics:capital_is_zero");
            receiveToken = capital;
            usdToken =router.getCapitalUSD(address(this), user, 18);
        }else {
            // 是否会出现无法还清的情况
            require(0 < bondsV4[user][token], "publics:bond_is_zero");
            receiveToken = address(config.getLoanPublics(token));
            updateBondsV3(user, token);
            usdToken = getUSD(token, bondsV3[user][token], 18);
        }
        if (usdToken.mul(10000) <= usdBorrow.mul(clearingEarning)) {
            (, price) = config.getAssetPrice().getPriceUSDV2(borrowsV1[user], 18);
            amount = usdToken.mul(10000).div(clearingEarning).div(price);
            if (capital == token) {
                price = capitalAmounts[user];//amount->price
                capitalAmounts[user] = 0;
                price = IEarning(earning).unStake(user, price);
            }else {
                price = bondsV4[user][token];//amount->price
                bondsV4[user][token] = 0;
            }
        }else {
            if (capital == token) {
                price = usdBorrow.mul(clearingEarning).mul(capitalAmounts[user]);
                price = price.div(usdToken).div(10000);
                if (capitalAmounts[user] < price) {
                    price = capitalAmounts[user];
                }
                capitalAmounts[user] = capitalAmounts[user].sub(price);
                price = IEarning(earning).unStake(user, price);
            }else {
                (, price) = config.getAssetPrice().getPriceUSDV2(token, 18);
                price = usdBorrow.mul(clearingEarning).div(price).div(10000);
                if (bondsV4[user][token] < price) {
                    price = bondsV4[user][token];
                }
                bondsV4[user][token] = bondsV4[user][token].sub(price);
            }
        }
        config.getApproveProxy().claim(borrowsV1[user], msg.sender, address(this), amount);
        repayV1(user, amount);
        safeTransfer(receiveToken, receiveToken, msg.sender, price, deadLine);
        emitPosition(msg.sender, 10);
    }
    
    function earningRepay(address user, uint256 deadLine, bool _repay) internal returns (uint256) {
        address token;
        uint256 amountV1;
        uint256 amountV2;
        (address[] memory _tokens, uint256[] memory _amounts) = IEarning(earning).claimRewards(user);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amountV1 = _amounts[i]; 
            if (0 < amountV1) {
                token = _tokens[i];
                if (_repay) {
                    amountV2 = amountV2.add(swap(token, borrowsV1[user], amountV1, deadLine));
                }else {
                    amountV2 = amountV1.mul(config.getPlatformTakeRate(address(this))).div(10000);
                    amountV1 = amountV1.sub(amountV2);
                    IERC20(token).safeTransfer(config.getPlatformFee(), amountV2);
                    IERC20(token).safeTransfer(user, amountV1);
                    amountV2 = 0;
                }
            }
        }
        return amountV2;
    }
    
}