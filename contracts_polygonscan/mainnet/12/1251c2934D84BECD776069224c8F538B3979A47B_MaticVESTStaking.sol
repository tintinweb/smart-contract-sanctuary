/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// File: contracts/lib/SafeMath.sol

pragma solidity ^0.6.12;

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
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/lib/Address.sol

pragma solidity ^0.6.12;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        uint256 value
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
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/lib/SafeERC20.sol

pragma solidity ^0.6.12;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
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
        uint256 value
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
        uint256 value
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
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
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

// File: contracts/lib/ReentrancyGuard.sol

pragma solidity ^0.6.12;

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
contract ReentrancyGuard {
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

// File: contracts/lib/Context.sol

pragma solidity ^0.6.12;

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

// File: contracts/lib/ERC20.sol

pragma solidity ^0.6.12;

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
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

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
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount)
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
        returns (uint256)
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
    function approve(address spender, uint256 amount)
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
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
    function increaseAllowance(address spender, uint256 addedValue)
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
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
        uint256 amount
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
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
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
        uint256 amount
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
        uint256 amount
    ) internal virtual {}
}

// File: contracts/STARToken.sol

pragma solidity ^0.6.12;

contract STARToken is ERC20 {
    constructor() public ERC20("BSCstarter", "START") {
        _mint(msg.sender, 1000000 * (10**uint256(decimals())));
    }
}

// File: contracts/lib/Ownable.sol

pragma solidity ^0.6.12;

/**
 * @title Owned
 * @dev Basic contract for authorization control.
 * @author dicether
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event LogOwnerShipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}

// File: contracts/interfaces/IWETH.sol

pragma solidity ^0.6.12;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/interfaces/IUniswap.sol

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/lib/Math.sol

pragma solidity ^0.6.12;

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/polygon/MaticStarterFarming.sol

pragma solidity ^0.6.12;

contract MaticStarterFarming is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amountETH, uint256 amountLP);
    event Withdrawn(address indexed to, uint256 amountETH, uint256 amountLP);
    event Claimed(address indexed to, uint256 amount);
    event Halving(uint256 amount);
    event Received(address indexed from, uint256 amount);

    STARToken public startToken;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    address payable public devAddress;
    address public pairAddress;

    struct AccountInfo {
        // Staked LP token balance
        uint256 balance;
        uint256 peakBalance;
        uint256 withdrawTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }
    mapping(address => AccountInfo) public accountInfos;

    mapping(address => bool) public bscsDevs;

    // Staked LP token total supply
    uint256 private _totalSupply = 0;

    uint256 public rewardDuration = 7 days;
    uint256 public rewardAllocation = 1000 * 1e18;
    uint256 public halvingTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored = 0;

    // Farming will be open on this timestamp
    uint256 public farmingStartTimestamp = 1625097600; // Thursday, July 1, 2021 12:00:00 AM
    bool public farmingStarted = false;

    // Max 25% / day LP withdraw
    uint256 public withdrawLimit = 25;
    uint256 public withdrawCycle = 24 hours;

    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnFeeX100 = 300;

    modifier onlyBscsDev() {
        require(
            owner == msg.sender || bscsDevs[msg.sender],
            "You are not dev."
        );
        _;
    }

    constructor(address _startToken) public {
        startToken = STARToken(address(_startToken));

        router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        factory = IUniswapV2Factory(router.factory());
        weth = router.WETH();
        devAddress = msg.sender;
        pairAddress = factory.getPair(address(startToken), weth);

        // Calc reward rate
        rewardRate = rewardAllocation.div(rewardDuration);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stake() external payable nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        //_halving();

        require(msg.value > 0, "Cannot stake 0");
        require(
            !address(msg.sender).isContract(),
            "Please use your individual account"
        );

        // 50% used to buy START
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(weth);
        swapPath[1] = address(startToken);
        IERC20(startToken).safeApprove(address(router), 0);
        IERC20(startToken).safeApprove(address(router), msg.value.div(2));
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: msg.value.div(2)
        }(uint256(0), swapPath, address(this), block.timestamp + 1 days);
        uint256 boughtStart = amounts[amounts.length - 1];

        // Add liquidity
        uint256 amountETHDesired = msg.value.sub(msg.value.div(2));
        IERC20(startToken).approve(address(router), boughtStart);
        (, , uint256 liquidity) = router.addLiquidityETH{
            value: amountETHDesired
        }(
            address(startToken),
            boughtStart,
            1,
            1,
            address(this),
            block.timestamp + 1 days
        );

        // Add LP token to total supply
        _totalSupply = _totalSupply.add(liquidity);

        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(
            liquidity
        );
        // Set peak balance
        if (
            accountInfos[msg.sender].balance >
            accountInfos[msg.sender].peakBalance
        ) {
            accountInfos[msg.sender].peakBalance = accountInfos[msg.sender]
                .balance;
        }

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[msg.sender].withdrawTimestamp == 0) {
            accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        }

        emit Staked(msg.sender, msg.value, liquidity);
    }

    function withdraw() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        //_halving();

        require(
            accountInfos[msg.sender].withdrawTimestamp + withdrawCycle <=
                block.timestamp,
            "You must wait more time since your last withdraw or stake"
        );
        require(accountInfos[msg.sender].balance > 0, "Cannot withdraw 0");

        // Limit withdraw LP token
        uint256 amount = accountInfos[msg.sender]
            .peakBalance
            .mul(withdrawLimit)
            .div(100);
        if (accountInfos[msg.sender].balance < amount) {
            amount = accountInfos[msg.sender].balance;
        }

        // Reduce total supply
        _totalSupply = _totalSupply.sub(amount);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(
            amount
        );
        if (accountInfos[msg.sender].balance == 0) {
            accountInfos[msg.sender].peakBalance = 0;
        }
        // Set timestamp
        accountInfos[msg.sender].withdrawTimestamp = block.timestamp;

        // Remove liquidity in uniswap
        IERC20(pairAddress).approve(address(router), amount);
        (uint256 tokenAmount, uint256 bnbAmount) = router.removeLiquidity(
            address(startToken),
            weth,
            amount,
            0,
            0,
            address(this),
            block.timestamp + 1 days
        );

        // Burn 3% START, send balance to sender
        uint256 burnAmount = tokenAmount.mul(burnFeeX100).div(10000);
        if (burnAmount > 0) {
            tokenAmount = tokenAmount.sub(burnAmount);
            startToken.transfer(address(BURN_ADDRESS), burnAmount);
        }
        startToken.transfer(msg.sender, tokenAmount);

        // Withdraw BNB and send to sender
        IWETH(weth).withdraw(bnbAmount);
        msg.sender.transfer(bnbAmount);

        emit Withdrawn(msg.sender, bnbAmount, amount);
    }

    function claim() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        //_halving();

        uint256 reward = accountInfos[msg.sender].reward;
        require(reward > 0, "There is no reward to claim");

        if (reward > 0) {
            // Reduce first
            accountInfos[msg.sender].reward = 0;
            // Apply tax
            uint256 taxDenominator = claimTaxDenominator();
            uint256 tax = taxDenominator > 0 ? reward.div(taxDenominator) : 0;
            uint256 net = reward.sub(tax);

            // Send reward
            startToken.transfer(msg.sender, net);
            if (tax > 0) {
                // Burn taxed token
                startToken.transfer(BURN_ADDRESS, tax);
            }

            emit Claimed(msg.sender, reward);
        }
    }

    function withdrawStart() external onlyOwner {
        startToken.transfer(devAddress, startToken.balanceOf(address(this)));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    function burnedTokenAmount() public view returns (uint256) {
        return startToken.balanceOf(BURN_ADDRESS);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored.add(
                lastRewardTimestamp()
                    .sub(lastUpdateTimestamp)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTimestamp);
    }

    function rewardEarned(address account) public view returns (uint256) {
        return
            accountInfos[account]
                .balance
                .mul(
                    rewardPerToken().sub(
                        accountInfos[account].rewardPerTokenPaid
                    )
                )
                .div(1e18)
                .add(accountInfos[account].reward);
    }

    // Token price in eth
    function tokenPrice() public view returns (uint256) {
        uint256 bnbAmount = IERC20(weth).balanceOf(pairAddress);
        uint256 tokenAmount = IERC20(startToken).balanceOf(pairAddress);
        return bnbAmount.mul(1e18).div(tokenAmount);
    }

    function claimTaxDenominator() public view returns (uint256) {
        if (block.timestamp < farmingStartTimestamp + 7 days) {
            return 4;
        } else if (block.timestamp < farmingStartTimestamp + 14 days) {
            return 5;
        } else if (block.timestamp < farmingStartTimestamp + 30 days) {
            return 10;
        } else if (block.timestamp < farmingStartTimestamp + 45 days) {
            return 20;
        } else {
            return 0;
        }
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTimestamp = lastRewardTimestamp();
        if (account != address(0)) {
            accountInfos[account].reward = rewardEarned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    // Do halving when timestamp reached
    function _halving() internal {
        if (block.timestamp >= halvingTimestamp) {
            rewardAllocation = rewardAllocation.div(2);

            rewardRate = rewardAllocation.div(rewardDuration);
            halvingTimestamp = halvingTimestamp.add(rewardDuration);

            _updateReward(msg.sender);
            emit Halving(rewardAllocation);
        }
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(
            farmingStartTimestamp <= block.timestamp,
            "Please wait until farming started"
        );
        if (!farmingStarted) {
            farmingStarted = true;
            halvingTimestamp = block.timestamp.add(rewardDuration);
            lastUpdateTimestamp = block.timestamp;
        }
    }

    function addDevAddress(address _devAddr) external onlyOwner {
        bscsDevs[_devAddr] = true;
    }

    function deleteDevAddress(address _devAddr) external onlyOwner {
        bscsDevs[_devAddr] = false;
    }

    function setFarmingStartTimestamp(
        uint256 _farmingTimestamp,
        bool _farmingStarted
    ) external onlyBscsDev {
        farmingStartTimestamp = _farmingTimestamp;
        farmingStarted = _farmingStarted;
    }

    function setBurnFee(uint256 _burnFee) external onlyBscsDev {
        burnFeeX100 = _burnFee;
    }

    function setWithdrawInfo(uint256 _withdrawLimit, uint256 _withdrawCycle)
        external
        onlyBscsDev
    {
        withdrawLimit = _withdrawLimit;
        withdrawCycle = _withdrawCycle;
    }
}

// File: contracts/polygon/MaticStarterInfo.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMaticStarterStaking {
    function accountLpInfos(address, address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IMaticExternalStaking {
    function balanceOf(address) external view returns (uint256);
}

contract MaticStarterInfo is Ownable {
    using SafeMath for uint256;

    uint256[] private devFeePercentage = [5, 2, 2];
    uint256 private minDevFeeInWei = 5 ether; // min fee amount going to dev AND BSCS hodlers
    address[] private presaleAddresses; // track all presales created

    mapping(address => uint256) private minInvestorBSCSBalance; // min amount to investors HODL BSCS balance
    mapping(address => uint256) private minInvestorGuaranteedBalance;

    uint256 private minStakeTime = 1 minutes;
    uint256 private minUnstakeTime = 3 days;
    uint256 private creatorUnsoldClaimTime = 3 days;

    address[] private swapRouters = [
        address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff),
        address(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429)
    ]; // Array of Routers
    address[] private swapFactorys = [
        address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32),
        address(0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B)
    ]; // Array of Factorys

    mapping(address => bytes32) private initCodeHash; // Mapping of INIT_CODE_HASH

    mapping(address => address) private lpAddresses; // TOKEN + START Pair Addresses

    address private starterSwapRouter =
        address(0x0000000000000000000000000000000000000000); // StarterSwap Router
    address private starterSwapFactory =
        address(0x0000000000000000000000000000000000000000); // StarterSwap Factory
    bytes32 private starterSwapICH =
        0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5; // StarterSwap InitCodeHash

    uint256 private starterSwapLPPercent = 0; // Liquidity will go StarterSwap

    address private wmatic =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address private quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);

    address private startFactoryAddress;
    mapping(address => uint256) private investmentLimit;

    mapping(address => bool) private starterDevs;
    mapping(address => bool) private presaleCreatorDevs;

    address private startVestingAddress =
        address(0x0000000000000000000000000000000000000000);

    mapping(address => uint256) private minYesVotesThreshold; // minimum number of yes votes needed to pass

    mapping(address => uint256) private minCreatorStakedBalance;

    mapping(address => bool) private blacklistedAddresses;

    mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audits

    IMaticStarterStaking public starterStakingPool;
    MaticStarterFarming public starterLPFarm;
    IMaticExternalStaking public starterExternalStaking;

    uint256 private devPresaleTokenFee = 2;
    address private devPresaleAllocationAddress =
        address(0x0000000000000000000000000000000000000000);

    constructor(
        address _starterStakingPool,
        address payable _starterLPFarm,
        address _starterExternalStaking
    ) public {
        starterStakingPool = IMaticStarterStaking(_starterStakingPool);
        starterLPFarm = MaticStarterFarming(_starterLPFarm);
        starterExternalStaking = IMaticExternalStaking(_starterExternalStaking);

        starterDevs[address(0xf7e925818a20E5573Ee0f3ba7aBC963e17f2c476)] = true; // Chef
        starterDevs[address(0xcc887c71ABeB5763E896859B11530cc7942c7Bd5)] = true; // Cocktologist

        initCodeHash[
            address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32)
        ] = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f; //QuickSwap INIT_CODE_HASH

        initCodeHash[
            address(0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B)
        ] = 0xf187ed688403aa4f7acfada758d8d53698753b998a3071b06f1b777f4330eaf3; // DYFN INIT_CODE_HASH

        lpAddresses[quick] = address(
            0x9E2B254c7D6AD24aFb334A75cE21e216A9AA25fc
        ); // QUICK -> QUICK+START LP Address

        lpAddresses[wmatic] = address(
            0x9E2B254c7D6AD24aFb334A75cE21e216A9AA25fc
        ); // WMATIC -> QUICK+START LP Addresses

        lpAddresses[
            address(0x6Ccf12B480A99C54b23647c995f4525D544A7E72)
        ] = address(0x6Ccf12B480A99C54b23647c995f4525D544A7E72); // START => START address

        minYesVotesThreshold[wmatic] = 1000 * 1e18;
        minYesVotesThreshold[quick] = 1000 * 1e18;

        minInvestorBSCSBalance[wmatic] = 3.5 * 1e18;
        minInvestorBSCSBalance[quick] = 3.5 * 1e18;

        minInvestorGuaranteedBalance[wmatic] = 35 * 1e18;
        minInvestorGuaranteedBalance[quick] = 35 * 1e18;

        investmentLimit[wmatic] = 1000 * 1e18;
        investmentLimit[quick] = 100 * 1e18;

        minCreatorStakedBalance[wmatic] = 3.5 * 1e18;
        minCreatorStakedBalance[quick] = 3.5 * 1e18;
    }

    modifier onlyFactory() {
        require(
            startFactoryAddress == msg.sender ||
                owner == msg.sender ||
                starterDevs[msg.sender],
            "onlyFactoryOrDev"
        );
        _;
    }

    modifier onlyStarterDev() {
        require(
            owner == msg.sender || starterDevs[msg.sender],
            "onlyStarterDev"
        );
        _;
    }

    function getCakeV2LPAddress(
        address tokenA,
        address tokenB,
        uint256 swapIndex
    ) public view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        swapFactorys[swapIndex],
                        keccak256(abi.encodePacked(token0, token1)),
                        initCodeHash[swapFactorys[swapIndex]] // init code hash
                    )
                )
            )
        );
    }

    function getStarterSwapLPAddress(address tokenA, address tokenB)
        public
        view
        returns (address pair)
    {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        starterSwapFactory,
                        keccak256(abi.encodePacked(token0, token1)),
                        starterSwapICH // init code hash
                    )
                )
            )
        );
    }

    function getStarterDev(address _dev) external view returns (bool) {
        return starterDevs[_dev];
    }

    function setStarterDevAddress(address _newDev) external onlyOwner {
        starterDevs[_newDev] = true;
    }

    function removeStarterDevAddress(address _oldDev) external onlyOwner {
        starterDevs[_oldDev] = false;
    }

    function getPresaleCreatorDev(address _dev) external view returns (bool) {
        return presaleCreatorDevs[_dev];
    }

    function setPresaleCreatorDevAddress(address _newDev)
        external
        onlyStarterDev
    {
        presaleCreatorDevs[_newDev] = true;
    }

    function removePresaleCreatorDevAddress(address _oldDev)
        external
        onlyStarterDev
    {
        presaleCreatorDevs[_oldDev] = false;
    }

    function getBscsFactoryAddress() external view returns (address) {
        return startFactoryAddress;
    }

    function setBscsFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        startFactoryAddress = _newFactoryAddress;
    }

    function getBscsStakingPool() external view returns (address) {
        return address(starterStakingPool);
    }

    function setBscsStakingPool(address _starterStakingPool)
        external
        onlyStarterDev
    {
        starterStakingPool = IMaticStarterStaking(_starterStakingPool);
    }

    function setStarterLPFarmPool(address payable _starterLPFarm)
        external
        onlyStarterDev
    {
        starterLPFarm = MaticStarterFarming(_starterLPFarm);
    }

    function setStarterExternalStaking(address _starterExternalStaking)
        external
        onlyStarterDev
    {
        starterExternalStaking = IMaticExternalStaking(_starterExternalStaking);
    }

    function addPresaleAddress(address _presale)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(_presale);
        return presaleAddresses.length - 1;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 bscsId) external view returns (address) {
        return presaleAddresses[bscsId];
    }

    function setPresaleAddress(uint256 bscsId, address _newAddress)
        external
        onlyStarterDev
    {
        presaleAddresses[bscsId] = _newAddress;
    }

    function getDevFeePercentage(uint256 presaleType)
        external
        view
        returns (uint256)
    {
        return devFeePercentage[presaleType];
    }

    function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
        external
        onlyStarterDev
    {
        devFeePercentage[presaleType] = _devFeePercentage;
    }

    function getMinDevFeeInWei() external view returns (uint256) {
        return minDevFeeInWei;
    }

    function setMinDevFeeInWei(uint256 _minDevFeeInWei)
        external
        onlyStarterDev
    {
        minDevFeeInWei = _minDevFeeInWei;
    }

    function getMinInvestorBSCSBalance(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minInvestorBSCSBalance[tokenAddress];
    }

    function setMinInvestorBSCSBalance(
        address tokenAddress,
        uint256 _minInvestorBSCSBalance
    ) external onlyStarterDev {
        minInvestorBSCSBalance[tokenAddress] = _minInvestorBSCSBalance;
    }

    function getMinYesVotesThreshold(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minYesVotesThreshold[tokenAddress];
    }

    function setMinYesVotesThreshold(
        address tokenAddress,
        uint256 _minYesVotesThreshold
    ) external onlyStarterDev {
        minYesVotesThreshold[tokenAddress] = _minYesVotesThreshold;
    }

    function getMinCreatorStakedBalance(address fundingTokenAddress)
        external
        view
        returns (uint256)
    {
        return minCreatorStakedBalance[fundingTokenAddress];
    }

    function setMinCreatorStakedBalance(
        address fundingTokenAddress,
        uint256 _minCreatorStakedBalance
    ) external onlyStarterDev {
        minCreatorStakedBalance[fundingTokenAddress] = _minCreatorStakedBalance;
    }

    function getMinInvestorGuaranteedBalance(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minInvestorGuaranteedBalance[tokenAddress];
    }

    function setMinInvestorGuaranteedBalance(
        address tokenAddress,
        uint256 _minInvestorGuaranteedBalance
    ) external onlyStarterDev {
        minInvestorGuaranteedBalance[
            tokenAddress
        ] = _minInvestorGuaranteedBalance;
    }

    function getMinStakeTime() external view returns (uint256) {
        return minStakeTime;
    }

    function setMinStakeTime(uint256 _minStakeTime) external onlyStarterDev {
        minStakeTime = _minStakeTime;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function setMinUnstakeTime(uint256 _minUnstakeTime)
        external
        onlyStarterDev
    {
        minUnstakeTime = _minUnstakeTime;
    }

    function getCreatorUnsoldClaimTime() external view returns (uint256) {
        return creatorUnsoldClaimTime;
    }

    function setCreatorUnsoldClaimTime(uint256 _creatorUnsoldClaimTime)
        external
        onlyStarterDev
    {
        creatorUnsoldClaimTime = _creatorUnsoldClaimTime;
    }

    function getSwapRouter(uint256 index) external view returns (address) {
        return swapRouters[index];
    }

    function setSwapRouter(uint256 index, address _swapRouter)
        external
        onlyStarterDev
    {
        swapRouters[index] = _swapRouter;
    }

    function addSwapRouter(address _swapRouter) external onlyStarterDev {
        swapRouters.push(_swapRouter);
    }

    function getSwapFactory(uint256 index) external view returns (address) {
        return swapFactorys[index];
    }

    function setSwapFactory(uint256 index, address _swapFactory)
        external
        onlyStarterDev
    {
        swapFactorys[index] = _swapFactory;
    }

    function addSwapFactory(address _swapFactory) external onlyStarterDev {
        swapFactorys.push(_swapFactory);
    }

    function getInitCodeHash(address _swapFactory)
        external
        view
        returns (bytes32)
    {
        return initCodeHash[_swapFactory];
    }

    function setInitCodeHash(address _swapFactory, bytes32 _initCodeHash)
        external
        onlyStarterDev
    {
        initCodeHash[_swapFactory] = _initCodeHash;
    }

    function getStarterSwapRouter() external view returns (address) {
        return starterSwapRouter;
    }

    function setStarterSwapRouter(address _starterSwapRouter)
        external
        onlyStarterDev
    {
        starterSwapRouter = _starterSwapRouter;
    }

    function getStarterSwapFactory() external view returns (address) {
        return starterSwapFactory;
    }

    function setStarterSwapFactory(address _starterSwapFactory)
        external
        onlyStarterDev
    {
        starterSwapFactory = _starterSwapFactory;
    }

    function getStarterSwapICH() external view returns (bytes32) {
        return starterSwapICH;
    }

    function setStarterSwapICH(bytes32 _initCodeHash) external onlyStarterDev {
        starterSwapICH = _initCodeHash;
    }

    function getStarterSwapLPPercent() external view returns (uint256) {
        return starterSwapLPPercent;
    }

    function setStarterSwapLPPercent(uint256 _starterSwapLPPercent)
        external
        onlyStarterDev
    {
        starterSwapLPPercent = _starterSwapLPPercent;
    }

    function getWMATIC() external view returns (address) {
        return wmatic;
    }

    function setWMATIC(address _wmatic) external onlyStarterDev {
        wmatic = _wmatic;
    }

    function getVestingAddress() external view returns (address) {
        return startVestingAddress;
    }

    function setVestingAddress(address _newVesting) external onlyStarterDev {
        startVestingAddress = _newVesting;
    }

    function getInvestmentLimit(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return investmentLimit[tokenAddress];
    }

    function setInvestmentLimit(address tokenAddress, uint256 _limit)
        external
        onlyStarterDev
    {
        investmentLimit[tokenAddress] = _limit;
    }

    function getLpAddress(address tokenAddress) public view returns (address) {
        return lpAddresses[tokenAddress];
    }

    function setLpAddress(address tokenAddress, address lpAddress)
        external
        onlyStarterDev
    {
        lpAddresses[tokenAddress] = lpAddress;
    }

    function getStartLpStaked(address lpAddress, address payable sender)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        (balance, lastStakedTimestamp, ) = starterStakingPool.accountLpInfos(
            lpAddress,
            address(sender)
        );
        uint256 totalHodlerBalance = 0;
        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            totalHodlerBalance = totalHodlerBalance.add(balance);
        }

        // add LP farm mining to balance
        balance = 0;

        (balance, , , , ) = starterLPFarm.accountInfos(address(sender));

        uint256 externalBalance = starterExternalStaking.balanceOf(
            address(sender)
        );

        return totalHodlerBalance + balance + externalBalance;
    }

    function getTotalStartLpStaked(address lpAddress)
        public
        view
        returns (uint256)
    {
        return ERC20(lpAddress).balanceOf(address(starterStakingPool));
    }

    function getStaked(address fundingTokenAddress, address payable sender)
        public
        view
        returns (uint256)
    {
        return getStartLpStaked(getLpAddress(fundingTokenAddress), sender);
    }

    function getTotalStaked(address fundingTokenAddress)
        public
        view
        returns (uint256)
    {
        return getTotalStartLpStaked(getLpAddress(fundingTokenAddress));
    }

    function getDevPresaleTokenFee() public view returns (uint256) {
        return devPresaleTokenFee;
    }

    function setDevPresaleTokenFee(uint256 _devPresaleTokenFee)
        external
        onlyStarterDev
    {
        devPresaleTokenFee = _devPresaleTokenFee;
    }

    function getDevPresaleAllocationAddress() public view returns (address) {
        return devPresaleAllocationAddress;
    }

    function setDevPresaleAllocationAddress(
        address _devPresaleAllocationAddress
    ) external onlyStarterDev {
        devPresaleAllocationAddress = _devPresaleAllocationAddress;
    }

    function isBlacklistedAddress(address _sender) public view returns (bool) {
        return blacklistedAddresses[_sender];
    }

    function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
        external
        onlyStarterDev
    {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = true;
        }
    }

    function removeBlacklistedAddresses(
        address[] calldata _blacklistedAddresses
    ) external onlyStarterDev {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = false;
        }
    }

    function isAuditorWhitelistedAddress(address _sender)
        public
        view
        returns (bool)
    {
        return auditorWhitelistedAddresses[_sender];
    }

    function addAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyStarterDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function removeAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyStarterDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = false;
        }
    }
}

// File: contracts/polygon/MaticVESTStaking.sol

pragma solidity 0.6.12;

contract MaticVESTStaking is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    STARToken public bscsToken;
    MaticStarterInfo public starterInfo;

    event Staked(address indexed from, uint256 amount);
    event Unstaked(address indexed from, uint256 amount);

    struct AccountInfo {
        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
    }
    mapping(address => AccountInfo) public accountInfos;

    uint256[] public burnFees = [5000, 700, 500, 200, 50];
    uint256[] public feeCycle = [3 days, 7 days, 14 days, 30 days];
    uint256 public minStakeTimeForDiamond = 30 days;

    modifier onlyDev() {
        require(
            msg.sender == starterInfo.owner() ||
                starterInfo.getStarterDev(msg.sender),
            "Only Bscs Dev"
        );
        _;
    }

    constructor(address _bscsToken, address _starterInfo) public {
        bscsToken = STARToken(_bscsToken);
        starterInfo = MaticStarterInfo(_starterInfo);
    }

    function stake(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Invalid amount");
        require(bscsToken.balanceOf(msg.sender) >= _amount, "Invalid balance");

        AccountInfo storage account = accountInfos[msg.sender];
        bscsToken.transferFrom(msg.sender, address(this), _amount);
        account.balance = account.balance.add(_amount);
        if (account.lastUnstakedTimestamp == 0) {
            account.lastUnstakedTimestamp = block.timestamp;
        }
        account.lastStakedTimestamp = block.timestamp;
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        AccountInfo storage account = accountInfos[msg.sender];
        require(
            !address(msg.sender).isContract(),
            "Please use your individual account"
        );

        require(account.balance > 0, "Nothing to unstake");
        require(_amount > 0, "Invalid amount");
        if (account.balance < _amount) {
            _amount = account.balance;
        }
        account.balance = account.balance.sub(_amount);

        uint256 burnAmount = _amount.mul(getBurnFee(msg.sender)).div(10000);
        if (burnAmount > 0) {
            _amount = _amount.sub(burnAmount);
            bscsToken.transfer(
                address(0x000000000000000000000000000000000000dEaD),
                burnAmount
            );
        }

        account.lastStakedTimestamp = block.timestamp;
        account.lastUnstakedTimestamp = block.timestamp;

        if (account.balance == 0) {
            account.lastStakedTimestamp = 0;
            account.lastUnstakedTimestamp = 0;
        }
        bscsToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function getBurnFee(address _staker) public view returns (uint256) {
        AccountInfo memory account = accountInfos[_staker];
        for (uint256 i = 0; i < feeCycle.length; i++) {
            if (block.timestamp < account.lastUnstakedTimestamp + feeCycle[i]) {
                return burnFees[i];
            }
        }
        return burnFees[feeCycle.length];
    }

    function setBurnFee(uint256 _index, uint256 fee) external onlyDev {
        burnFees[_index] = fee;
    }

    function setBurnCycle(uint256 _index, uint256 _cycle) external onlyDev {
        feeCycle[_index] = _cycle;
    }

    function setStarterInfo(address _starterInfo) external onlyDev {
        starterInfo = MaticStarterInfo(_starterInfo);
    }
}