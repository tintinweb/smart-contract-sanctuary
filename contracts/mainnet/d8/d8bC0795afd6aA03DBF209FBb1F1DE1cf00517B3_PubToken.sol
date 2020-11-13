/*

website: pub.finance

PPPPPPPPPPPPPPPPP   UUUUUUUU     UUUUUUUUBBBBBBBBBBBBBBBBB      SSSSSSSSSSSSSSS
P::::::::::::::::P  U::::::U     U::::::UB::::::::::::::::B   SS:::::::::::::::S
P::::::PPPPPP:::::P U::::::U     U::::::UB::::::BBBBBB:::::B S:::::SSSSSS::::::S
PP:::::P     P:::::PUU:::::U     U:::::UUBB:::::B     B:::::BS:::::S     SSSSSSS
  P::::P     P:::::P U:::::U     U:::::U   B::::B     B:::::BS:::::S
  P::::P     P:::::P U:::::D     D:::::U   B::::B     B:::::BS:::::S
  P::::PPPPPP:::::P  U:::::D     D:::::U   B::::BBBBBB:::::B  S::::SSSS
  P:::::::::::::PP   U:::::D     D:::::U   B:::::::::::::BB    SS::::::SSSSS
  P::::PPPPPPPPP     U:::::D     D:::::U   B::::BBBBBB:::::B     SSS::::::::SS
  P::::P             U:::::D     D:::::U   B::::B     B:::::B       SSSSSS::::S
  P::::P             U:::::D     D:::::U   B::::B     B:::::B            S:::::S
  P::::P             U::::::U   U::::::U   B::::B     B:::::B            S:::::S
PP::::::PP           U:::::::UUU:::::::U BB:::::BBBBBB::::::BSSSSSSS     S:::::S
P::::::::P            UU:::::::::::::UU  B:::::::::::::::::B S::::::SSSSSS:::::S
P::::::::P              UU:::::::::UU    B::::::::::::::::B  S:::::::::::::::SS
PPPPPPPPPP                UUUUUUUUU      BBBBBBBBBBBBBBBBB    SSSSSSSSSSSSSSS

*/

pragma solidity ^0.6.12;

library BasisPoints {
    using SafeMath for uint;

   uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * after an initial amount of tokens are minted when the token is created,
     * the _mint() function will be locked until this time (set upon creation).
     */
    //    uint private _mintLockedUntilTimestamp;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    // constructor (string memory name, string memory symbol, uint256 amountToMintOnCreation, uint256 mintLockedDays) public {
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        //
        //        // mint to creator
        //        _mint(msg.sender, amountToMintOnCreation);
        //
        //        // now lock minting for X days,
        //        // by setting `_mintLockedUntilTimestamp` to prevent _mint()'ing until future time
        //        _mintLockedUntilTimestamp = now.add(mintLockedDays.mul(1 days));
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


// PUBS
contract PubToken is ERC20("PUB.finance","PUBS"), Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public burnBP;
    uint public taxBP;
    Bartender private bartender;


    mapping(address => bool) public taxExempt;
    mapping(address => bool) public fromOnlyTaxExempt;
    mapping(address => bool) public toOnlyTaxExempt;


    constructor(uint _taxBP, uint _burnBP, address _bartender, address owner) public { 
        bartender = Bartender(_bartender);
        taxBP = _taxBP;
        burnBP = _burnBP;
        setTaxExemptStatus(address(bartender), true);
        transferOwnership(owner); 
    }
    modifier onlyBartender {
        require(msg.sender == address(bartender), "Can only be called by Bartender contract.");
        _;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (Bartender).
    function mint(address _to, uint256 _amount) public onlyBartender {
        _mint(_to, _amount);
    }


    function setFromOnlyTaxExemptStatus(address account, bool status) external onlyOwner {
        fromOnlyTaxExempt[account] = status;
    }

    function setToOnlyTaxExemptStatus(address account, bool status) external onlyOwner {
        fromOnlyTaxExempt[account] = status;
    }

    function setTaxExemptStatus(address account, bool status) public onlyOwner {
        taxExempt[account] = status;
    }


    function transfer(address recipient, uint amount) public override returns (bool) {
        (
        !taxExempt[msg.sender] && !taxExempt[recipient] &&
        !toOnlyTaxExempt[recipient] && !fromOnlyTaxExempt[msg.sender]
        ) ?
        _transferWithTax(msg.sender, recipient, amount) :
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        (
        !taxExempt[sender] && !taxExempt[recipient] &&
        !toOnlyTaxExempt[recipient] && !fromOnlyTaxExempt[sender]
        ) ?
        _transferWithTax(sender, recipient, amount) :
        _transfer(sender, recipient, amount);

        approve(
            msg.sender,
            allowance(
                sender,
                msg.sender
            ).sub(amount, "Transfer amount exceeds allowance")
        );
        return true;
    }

    function findTaxAmount(uint value) public view returns (uint tax, uint devTax) {
        tax = value.mulBP(taxBP);
        devTax = value.mulBP(burnBP);
    }

    function _transferWithTax(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        (uint tax, uint devTax) = findTaxAmount(amount);
        uint tokensToTransfer = amount.sub(tax).sub(devTax);

        _transfer(sender, address(bartender), tax);
        _transfer(sender, address(bartender), devTax);

        _transfer(sender, recipient, tokensToTransfer);
        bartender.handleTaxDistribution(tax, devTax);
    }

}

contract Bartender is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // the lockup type for staked LP. affects the withdraw tax.
    enum LockType { None, ThreeDays, Week, Month, Forever}

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        LockType lockType;
        uint256 unlockDate;
        uint256 taxRewardDebt; // Reward debt. See explanation below.
        uint256 lpTaxRewardDebt; // Reward debt. See explanation below.

        //
        // We do some fancy math here. Basically, any point in time, the amount of PUBs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPubPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPubPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PUBs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PUBs distribution occurs.
        uint256 accPubPerShare;   // Accumulated PUBs per share, times 1e12. See below.
        uint256 accTaxPubPerShare;   // Accumulated PUBs per share, times 1e12. For Taxes
        uint256 accLPTaxPubPerShare;   // Accumulated PUBs per share, times 1e12. For LP Taxes
        uint256 accTokensForTax;
        uint256 accTokensForLPTax;

    }

    // The [new] PUB token
    PubToken public pub;
    // PUB tokens created per block.
    uint256 public pubPerBlock;
    // numerator of the owner fee
    uint256 public constant OWNER_FEE_NUMERATOR = 50;
    // denominator of the owner fee
    uint256 public constant OWNER_FEE_DENOMINATOR = 10000;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo[])) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PUB mining starts.
    uint256 public startBlock;

    // accumulated tax amount
    uint256 public accumulatedTax = 0;

    // address of the old PUB token that can be 1:1 exchanged for new PUB
    IERC20 oldPub;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        uint256 _startBlock,
        address _oldPub
    ) public {
        // we are going to deploy the token from within this
        // constructor to grant onlyOwner just to this contract so only Bartender can mint() tokens.
        // mint a couple tokens for the express purpose of creating the Uniswap LPs
        pub = new PubToken(250, 250, address(this), msg.sender);
        oldPub = IERC20(_oldPub);

        // in order to create the Uni Liquidity Pools we mint 5 tokens to the owner on creation.
        pub.mint(msg.sender, 5 * 10**18);

        pubPerBlock = 0; // initial value
        startBlock = _startBlock;
    }
    modifier onlyPubToken {
        require(msg.sender == address(pub), "Can only be called by PubToken contract.");
        _;
    }

    // method to return the balance of an address of the pub erc20 token associated wtih this contract
    function pubBalance(address a) external view returns (uint256){
        return pub.balanceOf(a);
    }

    // return the address of the erc20 token that gets harvested
    function pubToken() external view returns (address) {
        return address(pub);
    }

    // get the number of farms
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // get the owner of the PUB token
    function pubOwner() external view returns (address) {
        return pub.owner();
    }

    // get the PUB balance of the caller
    function myPubTokenBalance() external view returns (uint256) {
        return pub.balanceOf(msg.sender);
    }

    // view to see the pending tokens for a pool and an address
    function getUserInfo(uint256 _pid, address _address) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][_address];

        uint256 length = userInfoArr.length;
        uint totalAmount = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            totalAmount = totalAmount.add(userInfoArr[userInfoIndex].amount);

        }
        return totalAmount;
    }

    function getUserInfoLocked(uint256 _pid, address _address) external view returns (uint256) {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][_address];


        uint256 length = userInfoArr.length;
        uint totalAmount = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user =userInfoArr[userInfoIndex];
            if (user.amount > 0 && user.unlockDate > now) {

                totalAmount = totalAmount.add(user.amount);
            }
        }
        return totalAmount;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPubPerShare: 0,
            accTaxPubPerShare:0,
            accLPTaxPubPerShare:0,
            accTokensForTax:0,
            accTokensForLPTax:0
            }));
    }

    // get the current number of PUB per block
    function getPubPerBlock() public view returns (uint256){
        return pubPerBlock;
    }

    // update the number of PUB per block, with a value in wei
    function setPubPerBlock(uint256 _pubPerBlock) public onlyOwner {
        require(_pubPerBlock > 0, "_pubPerBlock must be non-zero");

        // update all pools prior to changing the block rewards
        massUpdatePools();

        // update the block rewards
        pubPerBlock = _pubPerBlock;
    }

    // Update the given pool's PUB allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending PUBs on frontend.
    function pendingPubs(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now) {
                uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                totalPubToTransfer = totalPubToTransfer.add(pending);

                //Distribute taxes
                if (user.lockType >= LockType.Week) {
                    uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }
                //Distribute lp taxes
                if (user.lockType >= LockType.Month) {
                    uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }
            }
        }
        return totalPubToTransfer;
    }

    // View function to see pending PUBs on frontend.
    function pendingLockedPubs(uint256 _pid, address _user) external view returns (uint256) {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];


        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate > now) {
                uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                totalPubToTransfer = totalPubToTransfer.add(pending);

                //Distribute taxes
                if (user.lockType >= LockType.Week) {
                    uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }
                //Distribute lp taxes
                if (user.lockType >= LockType.Month) {
                    uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }
            }
        }
        return totalPubToTransfer;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // anyone can call this to update the tax distribution and gets a 1% caller bonus
    function massUpdateTaxAllocationForPools() public {
        uint callerBonus = accumulatedTax.mul(100).div(10000); // 1%
        pub.transfer(msg.sender, callerBonus);
        accumulatedTax = accumulatedTax.sub(callerBonus);
        if (accumulatedTax == 0) {
            return;
        }
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 lpSupply = pool.accTokensForTax;

            //handle tax distribution
            uint256 taxPubReward = accumulatedTax.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accTaxPubPerShare = pool.accTaxPubPerShare.add(taxPubReward.mul(1e12).div(lpSupply));

        }
        accumulatedTax = 0;
    }

    function massUpdateLPTaxAllocationForPools(uint _amount) public {
        pub.transferFrom(msg.sender, address(this), _amount);

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 lpSupply = pool.accTokensForLPTax;

            //handle tax distribution
            uint256 lpTaxPubReward = _amount.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accLPTaxPubPerShare = pool.accLPTaxPubPerShare.add(lpTaxPubReward.mul(1e12).div(lpSupply));
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    // updates starting with the 0 index
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 pubReward = pubPerBlock.mul(pool.allocPoint).div(totalAllocPoint);

        if(pubReward > 0){
            pub.mint(address(this), pubReward);
        }
        pool.accPubPerShare = pool.accPubPerShare.add(pubReward.mul(1e12).div(lpSupply));

        pool.lastRewardBlock = block.number;
    }

    // claim pending yield
    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now) {
                uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                totalPubToTransfer = totalPubToTransfer.add(pending);
                user.rewardDebt = user.amount.mul(pool.accPubPerShare).div(1e12);

                //Distribute taxes
                if (user.lockType >= LockType.Week) {
                    uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                    user.taxRewardDebt = user.amount.mul(pool.accTaxPubPerShare).div(1e12);
                }
                //Distribute lp taxes
                if (user.lockType >= LockType.Month) {
                    uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                    user.lpTaxRewardDebt = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12);
                }
            }
        }
        safePubTransfer(msg.sender, totalPubToTransfer);
    }

    // Deposit LP tokens to Bartender for PUB allocation.
    function deposit(uint256 _pid, uint256 _amount, LockType lockType) public {
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        if (_amount > 0) {

            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

            UserInfo memory user = UserInfo(_amount,0,lockType,0,0,0);
            user.amount = _amount;
            user.rewardDebt = user.amount.mul(pool.accPubPerShare).div(1e12);
            user.lockType = lockType;
            user.taxRewardDebt = user.amount.mul(pool.accTaxPubPerShare).div(1e12);
            user.lpTaxRewardDebt = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12);

            if(lockType == LockType.ThreeDays){
                user.unlockDate = now + 3 days;
            }
            else if(lockType == LockType.Week){
                user.unlockDate = now + 1 weeks;
                pool.accTokensForTax = pool.accTokensForTax.add(_amount);

            }
            else if(lockType == LockType.Month){
                user.unlockDate = now + 30 days;
                pool.accTokensForLPTax = pool.accTokensForLPTax.add(_amount);
                pool.accTokensForTax = pool.accTokensForTax.add(_amount);
            }
            else if(lockType == LockType.Forever){
                user.unlockDate = now;
                pool.accTokensForLPTax = pool.accTokensForLPTax.add(_amount);
                pool.accTokensForTax = pool.accTokensForTax.add(_amount);
            }
            else {
                user.unlockDate = now;
            }
            userInfo[_pid][msg.sender].push(user);
            emit Deposit(msg.sender, _pid, _amount);
        }
    }

    // withdraw all unlocked tokens
    function withdrawMax(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        uint totalLPToTransfer = 0;
        uint totalLPFee = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now && user.lockType != LockType.Forever) {
                    uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pending);
                    uint256 amount  = user.amount;

                    //Distribute taxes
                    if (user.lockType >= LockType.Week) {
                        uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                        totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                        user.taxRewardDebt = user.amount.mul(pool.accTaxPubPerShare).div(1e12);
                    }

                    //Distribute lp taxes
                    if (user.lockType >= LockType.Month) {
                        uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                        totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                        user.lpTaxRewardDebt = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12);
                    }

                    // lock type >= Month is 0 fee
                    uint256 fee = 0;
                    if(user.lockType == LockType.None){
                        fee = 100;
                    }
                    else if(user.lockType == LockType.ThreeDays){
                        fee = 50;
                    }
                    else if(user.lockType == LockType.Week){
                        fee = 25;
                        pool.accTokensForTax = pool.accTokensForTax.sub(amount);
                    }
                    else if(user.lockType == LockType.Month){
                        pool.accTokensForLPTax = pool.accTokensForLPTax.sub(amount);
                        pool.accTokensForTax = pool.accTokensForTax.sub(amount);
                    }

                    uint256 feeAmount = amount.mul(fee).div(OWNER_FEE_DENOMINATOR);
                    amount = amount.sub(feeAmount);
                    totalLPFee = totalLPFee.add(feeAmount);

                    totalLPToTransfer = totalLPToTransfer.add(amount);

                    user.rewardDebt = 0;
                    user.amount = 0;
                }

        }
        // surgically collapse the array
        for (uint256 userInfoIndex = 0; userInfoIndex < length;) {
            UserInfo storage user = userInfoArr[userInfoIndex];
            if(user.amount == 0){
                for (uint256 idx = userInfoIndex; idx < length-1; ++idx) {
                    userInfoArr[idx] = userInfoArr[idx+1];
                }
                length = length.sub(1);
                delete userInfoArr[length];
            }
            else{
                userInfoIndex++;
            }
        }

        // transfer all tokens that we withdrew LP from
        safePubTransfer(msg.sender, totalPubToTransfer);

        // transfer the feeAmount to the owner using deposit
        pool.lpToken.safeTransfer(address(owner()), totalLPFee);

        // withdraw, using safeTransfer
        pool.lpToken.safeTransfer(address(msg.sender), totalLPToTransfer);

        emit Withdraw(msg.sender, _pid, totalLPToTransfer);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        uint totalLPToTransfer = 0;
        uint totalLPFee = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now && user.lockType != LockType.Forever) {
                uint256 amount  = user.amount;


                // lock type >= Month is 0 fee
                uint256 fee = 0;
                if(user.lockType == LockType.None){
                    fee = 100;
                }
                else if(user.lockType == LockType.ThreeDays){
                    fee = 50;
                }
                else if(user.lockType == LockType.Week){
                    fee = 25;
                    pool.accTokensForTax = pool.accTokensForTax.sub(amount);

                }
                else if(user.lockType == LockType.Month){
                    pool.accTokensForLPTax = pool.accTokensForLPTax.sub(amount);
                    pool.accTokensForTax = pool.accTokensForTax.sub(amount);

                }

                uint256 feeAmount = amount.mul(fee).div(OWNER_FEE_DENOMINATOR);
                amount = amount.sub(feeAmount);
                totalLPFee = totalLPFee.add(feeAmount);

                totalLPToTransfer = totalLPToTransfer.add(amount);
            }
        }

        // transfer the feeAmount to the owner using deposit
        pool.lpToken.safeTransfer(address(owner()), totalLPFee);

        // withdraw, using safeTransfer
        pool.lpToken.safeTransfer(address(msg.sender), totalLPToTransfer);

        emit EmergencyWithdraw(msg.sender, _pid, totalLPToTransfer);
    }

    // Safe pub transfer function, just in case if rounding error causes pool to not have enough PUBs.
    function safePubTransfer(address _to, uint256 _amount) internal {
        uint256 pubBal = pub.balanceOf(address(this));
        if (_amount > pubBal) {
            pub.transfer(_to, pubBal);
        } else {
            pub.transfer(_to, _amount);
        }
    }

    function handleTaxDistribution(uint _tax,uint _devTax) external onlyPubToken{
        accumulatedTax = accumulatedTax.add(_tax);
        // transfers the dev tax to the owner
        pub.transfer(address(owner()), _devTax);
    }

    // exchange original PUB token for new PUB
    function swapPubForPub2(uint _amount) public{
        oldPub.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _amount);
        pub.mint(msg.sender, _amount);
    }

}