/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
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
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor() internal {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
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

        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        uint newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
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

        bytes memory returndata =
            address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}
}

// File: contracts/protocol/IStrategy.sol

/*
version 1.2.0

Changes

Changes listed here do not affect interaction with other contracts (Vault and Controller)
- removed function assets(address _token) external view returns (bool);
- remove function deposit(uint), declared in IStrategyERC20
- add function setSlippage(uint _slippage);
- add function setDelta(uint _delta);
*/

interface IStrategy {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function vault() external view returns (address);

    /*
    @notice Returns address of underlying asset (ETH or ERC20)
    @dev Must return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH strategy
    */
    function underlying() external view returns (address);

    /*
    @notice Returns total amount of underlying transferred from vault
    */
    function totalDebt() external view returns (uint);

    function performanceFee() external view returns (uint);

    function slippage() external view returns (uint);

    /* 
    @notice Multiplier used to check total underlying <= total debt * delta / DELTA_MIN
    */
    function delta() external view returns (uint);

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setPerformanceFee(uint _fee) external;

    function setSlippage(uint _slippage) external;

    function setDelta(uint _delta) external;

    /*
    @notice Returns amount of underlying asset locked in this contract
    @dev Output may vary depending on price of liquidity provider token
         where the underlying asset is invested
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Withdraw `_amount` underlying asset
    @param amount Amount of underlying asset to withdraw
    */
    function withdraw(uint _amount) external;

    /*
    @notice Withdraw all underlying asset from strategy
    */
    function withdrawAll() external;

    /*
    @notice Sell any staking rewards for underlying and then deposit undelying
    */
    function harvest() external;

    /*
    @notice Increase total debt if profit > 0 and total assets <= max,
            otherwise transfers profit to vault.
    @dev Guard against manipulation of external price feed by checking that
         total assets is below factor of total debt
    */
    function skim() external;

    /*
    @notice Exit from strategy
    @dev Must transfer all underlying tokens back to vault
    */
    function exit() external;

    /*
    @notice Transfer token accidentally sent here to admin
    @param _token Address of token to transfer
    @dev _token must not be equal to underlying token
    */
    function sweep(address _token) external;
}

// File: contracts/protocol/IStrategyETH.sol

interface IStrategyETH is IStrategy {
    /*
    @notice Deposit ETH
    */
    function deposit() external payable;
}

// File: contracts/protocol/IVault.sol

/*
version 1.2.0

Changes
- function deposit(uint) declared in IERC20Vault
*/

interface IVault {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function timeLock() external view returns (address);

    /*
    @notice For EthVault, must return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    */
    function token() external view returns (address);

    function strategy() external view returns (address);

    function strategies(address _strategy) external view returns (bool);

    function reserveMin() external view returns (uint);

    function withdrawFee() external view returns (uint);

    function paused() external view returns (bool);

    function whitelist(address _addr) external view returns (bool);

    function setWhitelist(address _addr, bool _approve) external;

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setTimeLock(address _timeLock) external;

    function setPause(bool _paused) external;

    function setReserveMin(uint _reserveMin) external;

    function setWithdrawFee(uint _fee) external;

    /*
    @notice Returns the amount of asset (ETH or ERC20) in the vault
    */
    function balanceInVault() external view returns (uint);

    /*
    @notice Returns the estimate amount of asset in strategy
    @dev Output may vary depending on price of liquidity provider token
         where the underlying asset is invested
    */
    function balanceInStrategy() external view returns (uint);

    /*
    @notice Returns amount of tokens invested strategy
    */
    function totalDebtInStrategy() external view returns (uint);

    /*
    @notice Returns the total amount of asset in vault + total debt
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Returns minimum amount of tokens that should be kept in vault for
            cheap withdraw
    @return Reserve amount
    */
    function minReserve() external view returns (uint);

    /*
    @notice Returns the amount of tokens available to be invested
    */
    function availableToInvest() external view returns (uint);

    /*
    @notice Approve strategy
    @param _strategy Address of strategy
    */
    function approveStrategy(address _strategy) external;

    /*
    @notice Revoke strategy
    @param _strategy Address of strategy
    */
    function revokeStrategy(address _strategy) external;

    /*
    @notice Set strategy
    @param _min Minimum undelying asset current strategy must return. Prevents slippage
    */
    function setStrategy(address _strategy, uint _min) external;

    /*
    @notice Transfers asset in vault to strategy
    */
    function invest() external;

    /*
    @notice Calculate amount of asset that can be withdrawn
    @param _shares Amount of shares
    @return Amount of asset that can be withdrawn
    */
    function getExpectedReturn(uint _shares) external view returns (uint);

    /*
    @notice Withdraw asset
    @param _shares Amount of shares to burn
    @param _min Minimum amount of asset expected to return
    */
    function withdraw(uint _shares, uint _min) external;

    /*
    @notice Transfer asset in vault to admin
    @param _token Address of asset to transfer
    @dev _token must not be equal to vault asset
    */
    function sweep(address _token) external;
}

// File: contracts/protocol/IETHVault.sol

interface IETHVault is IVault {
    /*
    @notice Deposit ETH into this vault
    */
    function deposit() external payable;
}

// File: contracts/protocol/IController.sol

interface IController {
    function ADMIN_ROLE() external view returns (bytes32);

    function HARVESTER_ROLE() external view returns (bytes32);

    function admin() external view returns (address);

    function treasury() external view returns (address);

    function setAdmin(address _admin) external;

    function setTreasury(address _treasury) external;

    function grantRole(bytes32 _role, address _addr) external;

    function revokeRole(bytes32 _role, address _addr) external;

    /*
    @notice Set strategy for vault
    @param _vault Address of vault
    @param _strategy Address of strategy
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    */
    function setStrategy(
        address _vault,
        address _strategy,
        uint _min
    ) external;

    // calls to strategy
    /*
    @notice Invest token in vault into strategy
    @param _vault Address of vault
    */
    function invest(address _vault) external;

    function harvest(address _strategy) external;

    function skim(address _strategy) external;

    /*
    @notice Withdraw from strategy to vault
    @param _strategy Address of strategy
    @param _amount Amount of underlying token to withdraw
    @param _min Minimum amount of underlying token to withdraw
    */
    function withdraw(
        address _strategy,
        uint _amount,
        uint _min
    ) external;

    /*
    @notice Withdraw all from strategy to vault
    @param _strategy Address of strategy
    @param _min Minimum amount of underlying token to withdraw
    */
    function withdrawAll(address _strategy, uint _min) external;

    /*
    @notice Exit from strategy
    @param _strategy Address of strategy
    @param _min Minimum amount of underlying token to withdraw
    */
    function exit(address _strategy, uint _min) external;
}

// File: contracts/ETHVault.sol

/*
version 1.2.0
*/

contract ETHVault is IETHVault, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event SetStrategy(address strategy);
    event ApproveStrategy(address strategy);
    event RevokeStrategy(address strategy);
    event SetWhitelist(address addr, bool approved);

    // WARNING: not address of ETH, used as placeholder
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public override admin;
    address public override controller;
    address public override timeLock;
    address public constant override token = ETH;
    address public override strategy;

    // mapping of approved strategies
    mapping(address => bool) public override strategies;

    // percentange of ETH reserved in vault for cheap withdraw
    uint public override reserveMin = 500;
    uint private constant RESERVE_MAX = 10000;

    // Denominator used to calculate fees
    uint private constant FEE_MAX = 10000;

    uint public override withdrawFee;
    uint private constant WITHDRAW_FEE_CAP = 500; // upper limit to withdrawFee

    bool public override paused;

    // whitelisted addresses
    // used to prevent flash loah attacks
    mapping(address => bool) public override whitelist;

    constructor(address _controller, address _timeLock)
        public
        ERC20("unagii_ETH", "uETH")
    {
        require(_controller != address(0), "controller = zero address");
        require(_timeLock != address(0), "time lock = zero address");

        // ETH decimals = 18 and ERC20 defaults to 18 decimals

        admin = msg.sender;
        controller = _controller;
        timeLock = _timeLock;
    }

    /*
    @dev Only allow ETH from current strategy
    @dev EOA cannot accidentally send ETH into this vault
    */
    receive() external payable {
        require(msg.sender == strategy, "msg.sender != strategy");
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    modifier onlyTimeLock() {
        require(msg.sender == timeLock, "!time lock");
        _;
    }

    modifier onlyAdminOrController() {
        require(msg.sender == admin || msg.sender == controller, "!authorized");
        _;
    }

    modifier whenStrategyDefined() {
        require(strategy != address(0), "strategy = zero address");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /*
    @dev modifier to prevent flash loan
    @dev caller is restricted to EOA or whitelisted contract
    @dev Warning: Users can have their funds stuck if shares is transferred to a contract
    */
    modifier guard() {
        require((msg.sender == tx.origin) || whitelist[msg.sender], "!whitelist");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    function setController(address _controller) external override onlyAdmin {
        require(_controller != address(0), "controller = zero address");
        controller = _controller;
    }

    function setTimeLock(address _timeLock) external override onlyTimeLock {
        require(_timeLock != address(0), "time lock = zero address");
        timeLock = _timeLock;
    }

    function setPause(bool _paused) external override onlyAdmin {
        paused = _paused;
    }

    function setWhitelist(address _addr, bool _approve) external override onlyAdmin {
        whitelist[_addr] = _approve;
        emit SetWhitelist(_addr, _approve);
    }

    function setReserveMin(uint _reserveMin) external override onlyAdmin {
        require(_reserveMin <= RESERVE_MAX, "reserve min > max");
        reserveMin = _reserveMin;
    }

    function setWithdrawFee(uint _fee) external override onlyAdmin {
        require(_fee <= WITHDRAW_FEE_CAP, "withdraw fee > cap");
        withdrawFee = _fee;
    }

    function _balanceInVault() private view returns (uint) {
        return address(this).balance;
    }

    /*
    @notice Returns balance of ETH in vault
    @return Amount of ETH in vault
    */
    function balanceInVault() external view override returns (uint) {
        return _balanceInVault();
    }

    function _balanceInStrategy() private view returns (uint) {
        if (strategy == address(0)) {
            return 0;
        }

        return IStrategyETH(strategy).totalAssets();
    }

    /*
    @notice Returns the estimate amount of ETH in strategy
    @dev Output may vary depending on price of liquidity provider token
         where ETH is invested
    */
    function balanceInStrategy() external view override returns (uint) {
        return _balanceInStrategy();
    }

    function _totalDebtInStrategy() private view returns (uint) {
        if (strategy == address(0)) {
            return 0;
        }
        return IStrategyETH(strategy).totalDebt();
    }

    /*
    @notice Returns amount of ETH invested strategy
    */
    function totalDebtInStrategy() external view override returns (uint) {
        return _totalDebtInStrategy();
    }

    function _totalAssets() private view returns (uint) {
        return _balanceInVault().add(_totalDebtInStrategy());
    }

    /*
    @notice Returns the total amount of ETH in vault + total debt
    @return Total amount of ETH in vault + total debt
    */
    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    function _minReserve() private view returns (uint) {
        return _totalAssets().mul(reserveMin) / RESERVE_MAX;
    }

    /*
    @notice Returns minimum amount of ETH that should be kept in vault for
            cheap withdraw
    @return Reserve amount
    */
    function minReserve() external view override returns (uint) {
        return _minReserve();
    }

    function _availableToInvest() private view returns (uint) {
        if (strategy == address(0)) {
            return 0;
        }

        uint balInVault = _balanceInVault();
        uint reserve = _minReserve();

        if (balInVault <= reserve) {
            return 0;
        }

        return balInVault - reserve;
    }

    /*
    @notice Returns amount of ETH available to be invested into strategy
    @return Amount of ETH available to be invested into strategy
    */
    function availableToInvest() external view override returns (uint) {
        return _availableToInvest();
    }

    /*
    @notice Approve strategy
    @param _strategy Address of strategy to revoke
    */
    function approveStrategy(address _strategy) external override onlyTimeLock {
        require(_strategy != address(0), "strategy = zero address");
        strategies[_strategy] = true;

        emit ApproveStrategy(_strategy);
    }

    /*
    @notice Revoke strategy
    @param _strategy Address of strategy to revoke
    */
    function revokeStrategy(address _strategy) external override onlyAdmin {
        require(_strategy != address(0), "strategy = zero address");
        strategies[_strategy] = false;

        emit RevokeStrategy(_strategy);
    }

    /*
    @notice Set strategy to approved strategy
    @param _strategy Address of strategy used
    @param _min Minimum ETH current strategy must return. Prevents slippage
    */
    function setStrategy(address _strategy, uint _min)
        external
        override
        onlyAdminOrController
    {
        require(strategies[_strategy], "!approved");
        require(_strategy != strategy, "new strategy = current strategy");
        require(
            IStrategyETH(_strategy).underlying() == ETH,
            "strategy.underlying != ETH"
        );
        require(
            IStrategyETH(_strategy).vault() == address(this),
            "strategy.vault != vault"
        );

        // withdraw from current strategy
        if (strategy != address(0)) {
            uint balBefore = _balanceInVault();
            IStrategyETH(strategy).exit();
            uint balAfter = _balanceInVault();

            require(balAfter.sub(balBefore) >= _min, "withdraw < min");
        }

        strategy = _strategy;

        emit SetStrategy(strategy);
    }

    /*
    @notice Invest ETH from vault into strategy.
            Some ETH are kept in vault for cheap withdraw.
    */
    function invest()
        external
        override
        whenStrategyDefined
        whenNotPaused
        onlyAdminOrController
    {
        uint amount = _availableToInvest();
        require(amount > 0, "available = 0");

        IStrategyETH(strategy).deposit{value: amount}();
    }

    /*
    @notice Deposit ETH into vault
    */
    function deposit() external payable override whenNotPaused nonReentrant guard {
        require(msg.value > 0, "deposit = 0");

        /*
        need to subtract msg.value to get total ETH before deposit
        totalAssets >= msg.value, since address(this).balance >= msg.value
        */
        uint totalEth = _totalAssets() - msg.value;
        uint totalShares = totalSupply();

        /*
        s = shares to mint
        T = total shares before mint
        d = deposit amount
        A = total ETH in vault + strategy before deposit

        s / (T + s) = d / (A + d)
        s = d / A * T
        */
        uint shares;
        if (totalShares == 0) {
            shares = msg.value;
        } else {
            shares = msg.value.mul(totalShares).div(totalEth);
        }

        _mint(msg.sender, shares);
    }

    function _getExpectedReturn(
        uint _shares,
        uint _balInVault,
        uint _balInStrat
    ) private view returns (uint) {
        /*
        s = shares
        T = total supply of shares
        w = amount of ETH to withdraw
        E = total amount of redeemable ETH in vault + strategy

        s / T = w / E
        w = s / T * E
        */

        /*
        total ETH = ETH in vault + min(total debt, ETH in strat)
        if ETH in strat > total debt, redeemable = total debt
        else redeemable = ETH in strat
        */
        uint totalDebt = _totalDebtInStrategy();
        uint totalEth;
        if (_balInStrat > totalDebt) {
            totalEth = _balInVault.add(totalDebt);
        } else {
            totalEth = _balInVault.add(_balInStrat);
        }

        uint totalShares = totalSupply();
        if (totalShares > 0) {
            return _shares.mul(totalEth) / totalShares;
        }
        return 0;
    }

    /*
    @notice Calculate amount of ETH that can be withdrawn
    @param _shares Amount of shares
    @return Amount of ETH that can be withdrawn
    */
    function getExpectedReturn(uint _shares) external view override returns (uint) {
        uint balInVault = _balanceInVault();
        uint balInStrat = _balanceInStrategy();

        return _getExpectedReturn(_shares, balInVault, balInStrat);
    }

    /*
    @dev WARNING check `_to` is not zero address before calling this function
    */
    function _sendEth(address payable _to, uint _amount) private {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Send ETH failed");
    }

    /*
    @notice Withdraw ETH
    @param _shares Amount of shares to burn
    @param _min Minimum amount of ETH to return
    @dev Keep `guard` modifier, else attacker can deposit and then use smart
         contract to attack from withdraw
    */
    function withdraw(uint _shares, uint _min) external override nonReentrant guard {
        require(_shares > 0, "shares = 0");

        uint balInVault = _balanceInVault();
        uint balInStrat = _balanceInStrategy();
        uint withdrawAmount = _getExpectedReturn(_shares, balInVault, balInStrat);

        // Must burn after calculating withdraw amount
        _burn(msg.sender, _shares);

        if (balInVault < withdrawAmount) {
            // maximize withdraw amount from strategy
            uint amountFromStrat = withdrawAmount;
            if (balInStrat < withdrawAmount) {
                amountFromStrat = balInStrat;
            }

            IStrategyETH(strategy).withdraw(amountFromStrat);

            uint balAfter = _balanceInVault();
            uint diff = balAfter.sub(balInVault);

            if (diff < amountFromStrat) {
                // withdraw amount - withdraw amount from strat = amount to withdraw from vault
                // diff = actual amount returned from strategy
                // NOTE: withdrawAmount >= amountFromStrat
                withdrawAmount = (withdrawAmount - amountFromStrat).add(diff);
            }

            // transfer to treasury
            uint fee = withdrawAmount.mul(withdrawFee) / FEE_MAX;
            if (fee > 0) {
                // treasury must be able to receive ETH
                address treasury = IController(controller).treasury();
                require(treasury != address(0), "treasury = zero address");

                withdrawAmount = withdrawAmount - fee;
                _sendEth(payable(treasury), fee);
            }
        }

        require(withdrawAmount >= _min, "withdraw < min");

        _sendEth(msg.sender, withdrawAmount);
    }

    /*
    @notice Transfer token in vault to admin
    @param _token Address of token to transfer
    @dev Used to transfer token that was accidentally sent to this vault
    */
    function sweep(address _token) external override onlyAdmin {
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}