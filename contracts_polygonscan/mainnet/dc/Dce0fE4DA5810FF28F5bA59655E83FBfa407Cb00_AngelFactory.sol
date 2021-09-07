/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// File: contracts/libraries/interfaces/IERC3156.sol



pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// File: contracts/interfaces/IFlashLender.sol



pragma solidity 0.6.12;


interface IFlashLender is IERC3156FlashLender {
    function flashLoanFeeCollector() external view returns (address);
    function setFlashLoanFee(uint256) external;
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


// File: @openzeppelin/contracts/drafts/IERC20Permit.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// File: contracts/ERC20FlashLoan.sol



pragma solidity 0.6.12;




contract ERC20FlashLoan is IFlashLender {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable lendingToken;
    uint256 public flashLoanFee;
    uint256 public constant FEE_BASE = 1e4;
    uint256 public constant FEE_BASE_OFFSET = FEE_BASE / 2;
    bytes32 private constant _RETURN_VALUE =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(IERC20 token, uint256 fee) public {
        require(fee <= FEE_BASE, "fee rate exceeded");
        lendingToken = token;
        flashLoanFee = fee;
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token)
        external
        view
        override
        returns (uint256)
    {
        return
            token == address(lendingToken)
                ? lendingToken.balanceOf(address(this))
                : 0;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        require(token == address(lendingToken), "wrong token");
        // The fee will be rounded half up
        return (amount.mul(flashLoanFee).add(FEE_BASE_OFFSET)).div(FEE_BASE);
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 fee = flashFee(token, amount);
        // send token to receiver
        lendingToken.safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
                _RETURN_VALUE,
            "invalid return value"
        );
        uint256 currentAllowance =
            lendingToken.allowance(address(receiver), address(this));
        uint256 totalDebt = amount.add(fee);
        require(
            currentAllowance >= totalDebt,
            "allowance does not allow refund"
        );
        // get token from receiver
        lendingToken.safeTransferFrom(
            address(receiver),
            address(this),
            totalDebt
        );
        address collector = flashLoanFeeCollector();
        if (collector != address(0)) lendingToken.safeTransfer(collector, fee);
        require(
            IERC20(token).balanceOf(address(this)) >= balance,
            "balance decreased"
        );

        return true;
    }

    function flashLoanFeeCollector()
        public
        view
        virtual
        override
        returns (address)
    {
        this;
        return address(0);
    }

    function setFlashLoanFee(uint256 fee) public virtual override {
        require(fee <= FEE_BASE, "fee rate exceeded");
        flashLoanFee = fee;
    }
}

// File: contracts/utils/ErrorMsg.sol



pragma solidity 0.6.12;

abstract contract ErrorMsg {
    function _requireMsg(
        bool condition,
        string memory functionName,
        string memory reason
    ) internal pure {
        if (!condition) _revertMsg(functionName, reason);
    }

    function _requireMsg(bool condition, string memory functionName)
        internal
        pure
    {
        if (!condition) _revertMsg(functionName);
    }

    function _revertMsg(string memory functionName, string memory reason)
        internal
        pure
    {
        revert(string(abi.encodePacked(functionName, ": ", reason)));
    }

    function _revertMsg(string memory functionName) internal pure {
        _revertMsg(functionName, "Unspecified");
    }
}

// File: contracts/interfaces/IFountain.sol



pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



interface IFountain is IERC20, IERC20Permit {
    // Getter
    function stakingToken() external view returns (address);
    function factory() external view returns (address);
    function archangel() external view returns (address);
    function joinedAngel(address user) external view returns (address[] memory);
    function angelInfo(address angel) external view returns (uint256, uint256);
    function joinTimeLimit(address owner, address sender) external view returns (uint256);
    function joinNonces(address owner) external view returns (uint256);
    function harvestTimeLimit(address owner, address sender) external view returns (uint256);
    function harvestNonces(address owner) external view returns (uint256);

    function setPoolId(uint256 pid) external;
    function deposit(uint256 amount) external;
    function depositTo(uint256 amount, address to) external;
    function withdraw(uint256 amount) external;
    function withdrawTo(uint256 amount, address to) external;
    function harvest(address angel) external;
    function harvestAll() external;
    function emergencyWithdraw() external;
    function joinAngel(address angel) external;
    function joinAngels(address[] calldata angels) external;
    function quitAngel(address angel) external;
    function rageQuitAngel(address angel) external;
    function quitAllAngel() external;
    function transferFromWithPermit(address owner,
        address recipient,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function joinApprove(address sender, uint256 timeLimit) external returns (bool);
    function joinPermit(
        address user,
        address sender,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function joinAngelFor(address angel, address user) external;
    function joinAngelsFor(address[] calldata angels, address user) external;
    function joinAngelForWithPermit(
        address angel,
        address user,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function joinAngelsForWithPermit(
        address[] calldata angels,
        address user,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function harvestApprove(address sender, uint256 timeLimit) external returns (bool);
    function harvestPermit(
        address owner,
        address sender,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function harvestFrom(address angel, address from, address to) external;
    function harvestAllFrom(address from, address to) external;
    function harvestFromWithPermit(
        address angel,
        address from,
        address to,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function harvestAllFromWithPermit(
        address from,
        address to,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

// File: contracts/interfaces/IArchangel.sol



pragma solidity 0.6.12;

interface IArchangel {
    // Getters
    function angelFactory() external view returns (address);
    function fountainFactory() external view returns (address);
    function defaultFlashLoanFee() external view returns (uint256);
    function getFountain(address token) external view returns (address);

    function rescueERC20(address token, address from) external returns (uint256);
    function setDefaultFlashLoanFee(uint256 fee) external;
}

// File: contracts/interfaces/IAngelFactory.sol



pragma solidity 0.6.12;

interface IAngelFactory {
    // Getters
    function archangel() external view returns (address);
    function isValid(address angel) external view returns (bool);
    function rewardOf(address angel) external view returns (address);

    function create(address rewardToken) external returns (address);
}

// File: contracts/interfaces/IMasterChef.sol


pragma solidity 0.6.12;

interface IMasterChef {
    using BoringERC20 for IERC20;
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid)
        external
        view
        returns (IMasterChef.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
}

// File: contracts/interfaces/IRewarder.sol



pragma solidity 0.6.12;


interface IRewarder {
    using BoringERC20 for IERC20;

    function onGraceReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 graceAmount,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 graceAmount
    ) external view returns (IERC20[] memory, uint256[] memory);
}

// File: contracts/libraries/SignedSafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(
            !(a == -1 && b == _INT256_MIN),
            "SignedSafeMath: multiplication overflow"
        );

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(
            !(b == -1 && a == _INT256_MIN),
            "SignedSafeMath: division overflow"
        );

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "SignedSafeMath: subtraction overflow"
        );

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "SignedSafeMath: addition overflow"
        );

        return c;
    }

    /**
     * @dev Returns the unsigned integer of the positive signed integer,
     * reverting on negative integer.
     * Not from openzeppelin/contracts
     *
     * Requirements:
     *
     * - Integer cannot be negative.
     */
    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}

// File: contracts/libraries/boringcrypto/BoringOwnable.sol


// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File: contracts/libraries/boringcrypto/libraries/BoringERC20.sol


pragma solidity 0.6.12;



library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) =
            address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) =
            address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) =
            address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(0x23b872dd, from, to, amount)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }
}

// File: contracts/libraries/boringcrypto/BoringBatchable.sol


// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;
// solhint-disable avoid-low-level-calls


// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail)
        external
        payable
        returns (bool[] memory successes, bytes[] memory results)
    {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) =
                address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(
        IERC20Permit token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// File: contracts/libraries/boringcrypto/libraries/BoringMath.sol


pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}
// File: @openzeppelin/contracts/math/Math.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/AngelBase.sol



pragma solidity 0.6.12;












/// @notice Angel is a forked version of MiniChefV2 from SushiSwap with
/// minimal modifications to interact with fountain in Trevi. The staking
/// tokens are managed in fountain instead of here. Migrate related functions
/// withdrawAndHarvest are removed.
contract AngelBase is BoringOwnable, BoringBatchable, ErrorMsg {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of GRACE entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of GRACE to distribute per block.
    struct PoolInfo {
        uint128 accGracePerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    /// @notice Address of GRACE contract.
    IERC20 public immutable GRACE;
    // @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public gracePerSecond;
    uint256 private constant ACC_GRACE_PRECISION = 1e12;

    ////////////////////////// New
    IArchangel public immutable archangel;
    IAngelFactory public immutable factory;
    uint256 public endTime;
    uint256 private _skipOwnerMassUpdateUntil;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        IRewarder indexed rewarder
    );
    event LogSetPool(
        uint256 indexed pid,
        uint256 allocPoint,
        IRewarder indexed rewarder,
        bool overwrite
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardTime,
        uint256 lpSupply,
        uint256 accGracePerShare
    );
    event LogGracePerSecondAndEndTime(uint256 gracePerSecond, uint256 endTime);

    modifier onlyFountain(uint256 pid) {
        _requireMsg(
            msg.sender == archangel.getFountain(address(lpToken[pid])),
            "General",
            "not called by correct fountain"
        );
        _;
    }

    modifier ownerMassUpdate() {
        if (block.timestamp > _skipOwnerMassUpdateUntil)
            massUpdatePoolsNonZero();
        _;
        _skipOwnerMassUpdateUntil = block.timestamp;
    }

    /// @param _grace The GRACE token contract address.
    constructor(IERC20 _grace) public {
        GRACE = _grace;
        IAngelFactory _f = IAngelFactory(msg.sender);
        factory = _f;
        archangel = IArchangel(_f.archangel());
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, endTime);
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(
        uint256 allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder
    ) external onlyOwner ownerMassUpdate {
        uint256 pid = lpToken.length;

        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(
            PoolInfo({
                allocPoint: allocPoint.to64(),
                lastRewardTime: block.timestamp.to64(),
                accGracePerShare: 0
            })
        );
        emit LogPoolAddition(pid, allocPoint, _lpToken, _rewarder);

        ////////////////////////// New
        // Update pid in fountain
        IFountain fountain =
            IFountain(archangel.getFountain(address(_lpToken)));
        fountain.setPoolId(pid);
    }

    /// @notice Update the given pool's GRACE allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite
    ) external onlyOwner ownerMassUpdate {
        updatePool(_pid);
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        if (overwrite) {
            rewarder[_pid] = _rewarder;
        }
        emit LogSetPool(
            _pid,
            _allocPoint,
            overwrite ? _rewarder : rewarder[_pid],
            overwrite
        );
    }

    /// @notice Add extra amount of GRACE to be distributed and the end time. Can only be called by the owner.
    /// @param _amount The extra amount of GRACE to be distributed.
    /// @param _endTime UNIX timestamp that indicates the end of the calculating period.
    function addGraceReward(uint256 _amount, uint256 _endTime)
        external
        onlyOwner
        ownerMassUpdate
    {
        _requireMsg(
            _amount > 0,
            "addGraceReward",
            "grace amount should be greater than 0"
        );
        _requireMsg(
            _endTime > block.timestamp,
            "addGraceReward",
            "end time should be in the future"
        );

        uint256 duration = _endTime.sub(block.timestamp);
        uint256 newGracePerSecond;
        if (block.timestamp >= endTime) {
            newGracePerSecond = _amount / duration;
        } else {
            uint256 remaining = endTime.sub(block.timestamp);
            uint256 leftover = remaining.mul(gracePerSecond);
            newGracePerSecond = leftover.add(_amount) / duration;
        }
        _requireMsg(
            newGracePerSecond <= type(uint128).max,
            "addGraceReward",
            "new grace per second exceeds uint128"
        );
        gracePerSecond = newGracePerSecond;
        endTime = _endTime;
        emit LogGracePerSecondAndEndTime(gracePerSecond, endTime);

        GRACE.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Set the grace per second to be distributed. Can only be called by the owner.
    /// @param _gracePerSecond The amount of Grace to be distributed per second.
    function setGracePerSecond(uint256 _gracePerSecond, uint256 _endTime)
        external
        onlyOwner
        ownerMassUpdate
    {
        _requireMsg(
            _gracePerSecond <= type(uint128).max,
            "setGracePerSecond",
            "new grace per second exceeds uint128"
        );
        _requireMsg(
            _endTime > block.timestamp,
            "setGracePerSecond",
            "end time should be in the future"
        );

        uint256 duration = _endTime.sub(block.timestamp);
        uint256 rewardNeeded = _gracePerSecond.mul(duration);
        uint256 shortage;
        if (block.timestamp >= endTime) {
            shortage = rewardNeeded;
        } else {
            uint256 remaining = endTime.sub(block.timestamp);
            uint256 leftover = remaining.mul(gracePerSecond);
            if (rewardNeeded > leftover) shortage = rewardNeeded.sub(leftover);
        }
        gracePerSecond = _gracePerSecond;
        endTime = _endTime;
        emit LogGracePerSecondAndEndTime(gracePerSecond, endTime);

        if (shortage > 0)
            GRACE.safeTransferFrom(msg.sender, address(this), shortage);
    }

    /// @notice View function to see pending GRACE on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending GRACE reward for a given user.
    function pendingGrace(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGracePerShare = pool.accGracePerShare;
        ////////////////////////// New
        // uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        // Need to get the lpSupply from fountain
        IFountain fountain =
            IFountain(archangel.getFountain(address(lpToken[_pid])));
        (, uint256 lpSupply) = fountain.angelInfo(address(this));
        uint256 _lastTimeRewardApplicable = lastTimeRewardApplicable();
        if (
            lpSupply != 0 &&
            pool.allocPoint > 0 &&
            _lastTimeRewardApplicable > pool.lastRewardTime
        ) {
            uint256 time = _lastTimeRewardApplicable.sub(pool.lastRewardTime);
            uint256 graceReward =
                time.mul(gracePerSecond).mul(pool.allocPoint) / totalAllocPoint;
            accGracePerShare = accGracePerShare.add(
                graceReward.mul(ACC_GRACE_PRECISION) / lpSupply
            );
        }
        pending = int256(
            user.amount.mul(accGracePerShare) / ACC_GRACE_PRECISION
        )
            .sub(user.rewardDebt)
            .toUInt256();
    }

    /// @notice Update reward variables for all pools with non-zero allocPoint.
    /// Be careful of gas spending!
    function massUpdatePoolsNonZero() public {
        uint256 len = poolLength();
        for (uint256 i = 0; i < len; ++i) {
            if (poolInfo[i].allocPoint > 0) updatePool(i);
        }
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] memory pids) public {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables for all pools and set the expire time for skipping `massUpdatePoolsNonZero()`.
    /// Be careful of gas spending! Can only be called by the owner.
    /// DO NOT use this function until `massUpdatePoolsNonZero()` reverts because of out of gas.
    /// If that is the case, try to update all pools first and then call onlyOwner function to set a correct state.
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePoolsAndSet(uint256[] calldata pids) external onlyOwner {
        massUpdatePools(pids);
        // Leave an hour for owner to be able to skip `massUpdatePoolsNonZero()`
        _skipOwnerMassUpdateUntil = block.timestamp.add(3600);
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            ////////////////////////// New
            // uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            // Need to get the lpSupply from fountain
            IFountain fountain =
                IFountain(archangel.getFountain(address(lpToken[pid])));
            (, uint256 lpSupply) = fountain.angelInfo(address(this));
            uint256 _lastTimeRewardApplicable = lastTimeRewardApplicable();
            // Only accumulate reward before end time
            if (
                lpSupply > 0 &&
                pool.allocPoint > 0 &&
                _lastTimeRewardApplicable > pool.lastRewardTime
            ) {
                uint256 time =
                    _lastTimeRewardApplicable.sub(pool.lastRewardTime);
                uint256 graceReward =
                    time.mul(gracePerSecond).mul(pool.allocPoint) /
                        totalAllocPoint;
                pool.accGracePerShare = pool.accGracePerShare.add(
                    (graceReward.mul(ACC_GRACE_PRECISION) / lpSupply).to128()
                );
            }
            pool.lastRewardTime = block.timestamp.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(
                pid,
                pool.lastRewardTime,
                lpSupply,
                pool.accGracePerShare
            );
        }
    }

    /// @notice Deposit LP tokens to MCV2 for GRACE allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external onlyFountain(pid) {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            int256(amount.mul(pool.accGracePerShare) / ACC_GRACE_PRECISION)
        );

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onGraceReward(pid, to, to, 0, user.amount);
        }

        ////////////////////////// New
        // Handle in fountain
        // lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        // emit Deposit(msg.sender, pid, amount, to);
        emit Deposit(to, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external onlyFountain(pid) {
        PoolInfo memory pool = updatePool(pid);
        ////////////////////////// New
        // Delegate by fountain
        // UserInfo storage user = userInfo[pid][msg.sender];
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(
            int256(amount.mul(pool.accGracePerShare) / ACC_GRACE_PRECISION)
        );
        user.amount = user.amount.sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            ////////////////////////// New
            // Delegate by fountain
            // _rewarder.onGraceReward(pid, msg.sender, to, 0, user.amount);
            _rewarder.onGraceReward(pid, to, to, 0, user.amount);
        }

        ////////////////////////// New
        // Handle in fountain
        // lpToken[pid].safeTransfer(to, amount);

        // emit Withdraw(msg.sender, pid, amount, to);
        emit Withdraw(to, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of GRACE rewards.
    function harvest(
        uint256 pid,
        address from,
        address to
    ) external onlyFountain(pid) {
        PoolInfo memory pool = updatePool(pid);
        ////////////////////////// New
        // Delegate by fountain
        // UserInfo storage user = userInfo[pid][msg.sender];
        UserInfo storage user = userInfo[pid][from];
        int256 accumulatedGrace =
            int256(
                user.amount.mul(pool.accGracePerShare) / ACC_GRACE_PRECISION
            );
        uint256 _pendingGrace =
            accumulatedGrace.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedGrace;

        // Interactions
        if (_pendingGrace != 0) {
            GRACE.safeTransfer(to, _pendingGrace);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onGraceReward(
                pid,
                ////////////////////////// New
                // Delegate by fountain
                // msg.sender,
                from,
                to,
                _pendingGrace,
                user.amount
            );
        }

        ////////////////////////// New
        // emit Harvest(msg.sender, pid, _pendingGrace);
        emit Harvest(from, pid, _pendingGrace);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to)
        external
        onlyFountain(pid)
    {
        ////////////////////////// New
        // Delegate by fountain
        // UserInfo storage user = userInfo[pid][msg.sender];
        UserInfo storage user = userInfo[pid][to];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            ////////////////////////// New
            // Delegate by fountain
            // _rewarder.onGraceReward(pid, msg.sender, to, 0, 0);
            // Execution of emergencyWithdraw should never fail. Considering
            // the possibility of failure caused by rewarder execution, use
            // try/catch on rewarder execution with limited gas
            try
                _rewarder.onGraceReward{gas: 1000000}(pid, to, to, 0, 0)
            {} catch {
                // Do nothing
            }
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        ////////////////////////// New
        // Handle in fountain
        // lpToken[pid].safeTransfer(to, amount);
        // emit EmergencyWithdraw(msg.sender, pid, amount, to);
        emit EmergencyWithdraw(to, pid, amount, to);
    }

    /// @notice Fetch the token from angel. Can only be called by owner.
    /// @param token The token address.
    /// @param amount The amount of token to be rescued. Replace by current balance if uint256(-1).
    /// @param to The receiver.
    /// @return The transferred amount.
    function rescueERC20(
        IERC20 token,
        uint256 amount,
        address to
    ) external onlyOwner returns (uint256) {
        if (amount == type(uint256).max) {
            amount = token.balanceOf(address(this));
        }
        token.safeTransfer(to, amount);

        return amount;
    }
}

// File: contracts/Angel.sol



pragma solidity 0.6.12;



/// @title Manage the rewards and configuration.
contract Angel is AngelBase, ERC20FlashLoan {
    modifier onlyArchangel() {
        _requireMsg(
            msg.sender == address(archangel),
            "general",
            "not from archangel"
        );
        _;
    }

    constructor(IERC20 token, uint256 flashLoanFee)
        public
        AngelBase(token)
        ERC20FlashLoan(token, flashLoanFee)
    {}

    /// @notice Set the fee rate for flash loan. can only be set by Archangel.
    /// @param fee The fee rate.
    function setFlashLoanFee(uint256 fee) public override onlyArchangel {
        super.setFlashLoanFee(fee);
    }

    /// @notice Set the fee collector. Fee are transferred to Archangel after
    /// flash loan execution.
    function flashLoanFeeCollector() public view override returns (address) {
        return address(archangel);
    }
}

// File: contracts/AngelFactory.sol



pragma solidity 0.6.12;




/// @title The factory of angel.
contract AngelFactory is ErrorMsg {
    using BoringERC20 for IERC20;
    using BoringMath for uint256;

    IArchangel public immutable archangel;
    mapping(Angel => IERC20) private _rewards;

    event Created(address to);

    constructor() public {
        archangel = IArchangel(msg.sender);
    }

    // Getters
    /// @notice Check if angel is valid.
    /// @param angel The angel to be verified.
    /// @return Is valid or not.
    function isValid(Angel angel) external view returns (bool) {
        return (address(_rewards[angel]) != address(0));
    }

    /// @notice Get the reward token of angel.
    /// @param angel The angel address.
    /// @return The reward token address.
    function rewardOf(Angel angel) external view returns (IERC20) {
        return _rewards[angel];
    }

    /// @notice Create the angel of given token as reward. Multiple angels for
    /// the same token is possible. Notice that angel with tokens that has
    /// floating amount (including Inflationary/Deflationary tokens, Interest
    /// tokens, Rebase tokens), might leads to error according to the design
    /// policy of angel.
    function create(IERC20 reward) external returns (Angel) {
        _requireMsg(
            address(reward) != address(0),
            "create",
            "reward is zero address"
        );
        Angel newAngel = new Angel(reward, archangel.defaultFlashLoanFee());
        _rewards[newAngel] = reward;
        newAngel.transferOwnership(msg.sender, true, false);

        emit Created(address(newAngel));

        return newAngel;
    }
}