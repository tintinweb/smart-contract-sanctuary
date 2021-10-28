/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

pragma solidity >=0.6.12;


// 
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// 
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

// 
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

// 
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

// 
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

// Inspired by https://github.com/deepyr/DutchSwap
// Inspired by https://github.com/sushiswap/miso
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// ---------------------------------------------------------------------
interface IERC20Details {
    function decimals() external view returns (uint256);
}

contract DutchAuction is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0);
    uint256 private constant COLLATERAL_FINE_RATE = 50000000000000000; //5%

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalAmount;
    uint256 public targetAmount;
    uint256 public initialPrice;
    uint256 public reservePrice;
    uint256 public commitmentsTotal;
    address public auctionToken;
    address public paymentToken;
    address public collateralToken;
    uint256 public collateralAmount;
    uint256 public minimumAuctionAmount;
    uint256 public maximumAuctionAmount;
    uint256 public depositExpired;
    address payable public owner;

    bool public isDepositCollaterals;
    bool public isWithdrawCollaterals;
    bool public isDepositTokens;
    bool public isWithdrawTokens;
    bool public finalizedAndSuccessful;
    bool public finalized;

    /// @notice The commited amount of accounts.
    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    // event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    // event AuctionPriceUpdated(uint256 initialPrice, uint256 reservePrice);
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    // event AuctionWalletUpdated(address wallet);
    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    /// @notice Event for cancellation of the auction.
    event AuctionCancelled();

    event WithdrawTokens(address indexed sender, address indexed token, uint256 amount);
    event DepositTokens(address indexed sender, address indexed token, uint256 amount);
    event DepositCollaterals(address indexed sender, address indexed token, uint256 amount);
    event WithdrawCollaterals(address indexed sender, address indexed token, uint256 amount);
    event WithdrwaPayments(address indexed sender, address indexed token, uint256 amount);
    event AuctionFinalized(bool finalizedAndSuccessful, uint256 commitmentsTotal, uint256 clearingPrice, uint256 time);

    function initAuction(
        address _auctionToken,
        address _paymentToken,
        uint256 _totalAmount,
        uint256 _targetAmount,
        uint256 _minimumAuctionAmount,
        uint256 _maximumAuctionAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _initialPrice,
        uint256 _reservePrice,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _depositExpired,
        address payable _owner
    ) internal {
        require(
            _startTime < 10000000000,
            "DutchAuction: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _endTime < 10000000000,
            "DutchAuction: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _startTime >= block.timestamp,
            "DutchAuction: start time is before current time"
        );
        require(
            _endTime > _startTime,
            "DutchAuction: end time must be older than start price"
        );
        require(
            _totalAmount > 0,
            "DutchAuction: total tokens must be greater than zero"
        );
        require(
            _initialPrice > _reservePrice,
            "DutchAuction: start price must be higher than minimum price"
        );
        require(
            _reservePrice > 0,
            "DutchAuction: minimum price must be greater than 0"
        );
        require(
            IERC20Details(_auctionToken).decimals() == 18,
            "DutchAuction: Token does not have 18 decimals"
        );
        if (_paymentToken != ETH_ADDRESS) {
            require(
                IERC20Details(_paymentToken).decimals() > 0,
                "DutchAuction: Payment currency is not ERC20"
            );
        }

        owner = _owner;

        startTime = _startTime;
        endTime = _endTime;
        totalAmount = _totalAmount;

        initialPrice = _initialPrice;
        reservePrice = _reservePrice;

        auctionToken = _auctionToken;
        paymentToken = _paymentToken;

        collateralToken = _collateralToken;
        collateralAmount = _collateralAmount;

        targetAmount = _targetAmount;
        minimumAuctionAmount = _minimumAuctionAmount;
        maximumAuctionAmount = _maximumAuctionAmount;

        depositExpired = _depositExpired;

        // initAccessControls(_admin);
        // _safeTransferFrom(_token, _funder, _totalTokens);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "DutchAuction: ");
        _;
    }

    /**
     Dutch Auction Price Function
     ============================
     
     Start Price -----
                      \
                       \
                        \
                         \ ------------ Clearing Price
                        / \            = AmountRaised/TokenSupply
         Token Price  --   \
                     /      \
                   --        ----------- Minimum Price
     Amount raised /          End Time
    */

    /**
     * @notice Calculates the average price of each token from all commitments.
     * @return Average token price.
     */
    function tokenPrice() public view returns (uint256) {
        return uint256(commitmentsTotal).mul(1e18).div(uint256(totalAmount));
    }

    /**
     * @notice Returns auction price in any time.
     * @return Fixed start price or minimum price if outside of auction time, otherwise calculated current price.
     */
    function priceFunction() public view returns (uint256) {
        /// @dev Return Auction Price
        if (block.timestamp <= uint256(startTime)) {
            return uint256(initialPrice);
        }
        if (block.timestamp >= uint256(endTime)) {
            return uint256(reservePrice);
        }

        return _currentPrice();
    }

    function clearingPrice() public view returns (uint256) {
        if (tokenPrice() > priceFunction()) {
            return tokenPrice();
        }
        return priceFunction();
    }

    receive() external payable {
        revert("");
    }

    function commitEth(address payable _beneficiary) public payable {
        require(isDepositCollaterals, "");
        require(paymentToken == ETH_ADDRESS, "Payment currency is not ETH address");
        uint256 ethToTransfer = calculateCommitment(msg.value);
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_beneficiary, ethToTransfer);
        }
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }
    }

    function commitTokens(uint256 _amount) public {
        require(isDepositCollaterals, "isDepositCollaterals");
        require(address(paymentToken) != ETH_ADDRESS, "Payment currency is not a token");
        uint256 tokensToTransfer = calculateCommitment(_amount);
        if (tokensToTransfer > 0) {
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), tokensToTransfer);
            _addCommitment(msg.sender, tokensToTransfer);
        }
    }

    function priceDrop() public view returns (uint256) {
        uint256 numerator = initialPrice.sub(reservePrice);
        uint256 denominator = endTime.sub(startTime);
        return numerator / denominator;
    }

    function tokensClaimable(address _user)
        public
        view
        returns (uint256 claimerCommitment)
    {
        if (commitments[_user] == 0) return 0;
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));

        claimerCommitment = commitments[_user].mul(uint256(totalAmount)).div(
            uint256(commitmentsTotal)
        );
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    function totalTokensCommitted() public view returns (uint256) {
        return commitmentsTotal.mul(1e18).div(clearingPrice());
    }

    function calculateCommitment(uint256 _commitment) public view returns (uint256 committed)
    {
        uint256 maxCommitment = totalAmount.mul(clearingPrice()).div(1e18);
        if (commitmentsTotal.add(_commitment) > maxCommitment)
            return maxCommitment.sub(commitmentsTotal);
        return _commitment;
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= uint256(startTime) && block.timestamp <= uint256(endTime);
    }

    function auctionSuccessful() public view returns (bool) {
        return tokenPrice() >= clearingPrice();
    }

    function auctionEnded() public view returns (bool) {
        return auctionSuccessful() || block.timestamp > uint256(endTime);
    }

    function _currentPrice() internal view returns (uint256) {
        uint256 priceDiff = block.timestamp.sub(uint256(startTime)).mul(priceDrop());
        return uint256(initialPrice).sub(priceDiff);
    }

    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(block.timestamp >= uint256(startTime) && block.timestamp <= uint256(endTime), "Outside auction hours");
        uint256 newCommitment = commitments[_addr].add(_commitment);
        commitments[_addr] = newCommitment;
        commitmentsTotal = commitmentsTotal.add(_commitment);
        emit AddedCommitment(_addr, _commitment);
    }

    function finalize() public nonReentrant {
        require(!finalized, "!finalize");
        finalized = true;
        if (auctionSuccessful()) {
            finalizedAndSuccessful = true;
        } else {
            require(block.timestamp > endTime, "Auction has not finished yet");
            if (commitmentsTotal >= targetAmount.mul(clearingPrice()).div(1e18))
                finalizedAndSuccessful = true;
        }
        emit AuctionFinalized(finalizedAndSuccessful, commitmentsTotal, clearingPrice(), block.timestamp);
    }

    function depositTokens() external onlyOwner {
        require(finalizedAndSuccessful && !isDepositTokens && block.timestamp <= depositExpired, "!depositTokens");
        isDepositTokens = true;
        IERC20(auctionToken).safeTransferFrom(msg.sender, address(this), totalTokensCommitted());
        emit DepositTokens(msg.sender, auctionToken, totalTokensCommitted());
    }

    function withdrwaPayments() external onlyOwner {
        require(finalizedAndSuccessful && isDepositTokens && !isWithdrawTokens, "!withdrwaPayments");
        isWithdrawTokens = true;
        IERC20(paymentToken).safeTransfer(msg.sender, commitmentsTotal);
        emit WithdrwaPayments(msg.sender, paymentToken, commitmentsTotal);
    }

    function withdrawTokens() public nonReentrant {
        if (isDepositTokens) {
            uint256 tokensToClaim = tokensClaimable(msg.sender);
            require(tokensToClaim > 0, "No tokens to claim");
            claimed[msg.sender] = claimed[msg.sender].add(tokensToClaim);
            IERC20(auctionToken).safeTransfer(msg.sender, tokensToClaim);
            emit WithdrawTokens(msg.sender, auctionToken, tokensToClaim);
        } else {
            require(block.timestamp > depositExpired, "Auction has not finished yet");
            uint256 fundsCommitted = commitments[msg.sender];
            commitments[msg.sender] = 0;
            IERC20(paymentToken).safeTransfer(msg.sender, fundsCommitted);
            emit WithdrawTokens(msg.sender, paymentToken, fundsCommitted);
        }
    }

    function depositCollaterals() external onlyOwner {
        require(!isDepositCollaterals && block.timestamp < startTime, "!depositCollaterals");
        isDepositCollaterals = true;
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateralAmount);
        emit DepositCollaterals(msg.sender, collateralToken, collateralAmount);
    }

    function withdrawCollaterals() external onlyOwner {
        require(finalized && isDepositCollaterals && !isWithdrawCollaterals, "!withdrawCollaterals");
        isWithdrawCollaterals = true;
        if (finalizedAndSuccessful) {
            if (isDepositTokens) {
                IERC20(collateralToken).safeTransfer(msg.sender, collateralAmount);
                emit WithdrawCollaterals(msg.sender, collateralToken, collateralAmount);
            } else {
                require(block.timestamp > depositExpired, "depositExpired");
                uint256 _collateralAmount = collateralAmount.sub(collateralAmount.mul(COLLATERAL_FINE_RATE).div(1e18));
                IERC20(collateralToken).safeTransfer(msg.sender, _collateralAmount);
                emit WithdrawCollaterals(msg.sender, collateralToken, _collateralAmount);
            }
        } else {
            IERC20(collateralToken).safeTransfer(msg.sender, collateralAmount);
            emit WithdrawCollaterals(msg.sender, collateralToken, collateralAmount);
        }
    }

    function initialize(bytes calldata _data) external payable {
        (
            address _auctionToken,
            address _paymentToken,
            uint256 _totalAmount,
            uint256 _targetAmount,
            uint256 _minimumAuctionAmount,
            uint256 _maximumAuctionAmount,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _initialPrice,
            uint256 _reservePrice,
            address _collateralToken,
            uint256 _collateralAmount,
            uint256 _depositExpired,
            address payable _owner
        ) = abi.decode(
                _data,
                (
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    uint256,
                    uint256,
                    address
                )
            );

        initAuction(
            _auctionToken,
            _paymentToken,
            _totalAmount,
            _targetAmount,
            _minimumAuctionAmount,
            _maximumAuctionAmount,
            _startTime,
            _endTime,
            _initialPrice,
            _reservePrice,
            _collateralToken,
            _collateralAmount,
            _depositExpired,
            _owner
        );
    }
}