// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.0;


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
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
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

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.6.0;


/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

pragma solidity ^0.6.12;

/// @title Drakoin
/// @author Drakons Team
/// @dev The main token contract for Drakons Utility token

contract Drakoin is ERC20Burnable, ERC20Pausable {

    uint256 private _fractionMultiplier;
    uint256 private _valuePerStakedToken;
    uint256 private _maximumSupply;

    uint256 public burnRate;
    uint256 public minimumSupply;
    uint256 public minStakeAmount;
    uint256 public minStakeDays;
    uint256 public bonusBalance;
    uint256 public maxHolderBonusCount;
    uint256 public bonusDuedays;

    address public CEOAddress;
    address public CIOAddress;
    address public COOAddress;

    address[] internal stakeholders;
    mapping(address => uint256) internal bonus;
    mapping(address => uint256) internal duedate;
    mapping(address => uint256) internal holderBonusCount;
    mapping(address => uint256) internal holderBonusDue;
    mapping(address => uint256) internal rewards;
    mapping(address => uint256) internal rewardsForClaiming;
    mapping(address => uint256) internal rewardsWithdrawn;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal stakedDays;
    mapping(address => bool) internal stakeholder;
    mapping(address => uint256) internal stakerValuePerStakedToken;
    mapping(uint256 => uint256) internal tierDayRate;
    mapping(address => bool) internal whitelisted;

    event BurnTokens(address _address, uint256 _amount);
    event CEOAddressUpdated(address newAddress);
    event CIOAddressUpdated(address newAddress);
    event COOAddressUpdated(address newAddress);
    event CreateStake(address _address, uint256 _amount, uint256 _numberOfDays);
    event RemoveStake(address _address, uint256 _amount);
    event ClaimRewards(address _address, uint256 _amount);
    event UpdateBurnRate(uint256 _newRate);
    event UpdateMinStakeAmount(uint256 _amount);
    event UpdateMinStakeDays(uint256 _amount);
    event UpdateTierDayRate(uint256 _newNumberOfDays, uint256 _newRate);
    event UpdateBonusBalance(uint256 bonusBalance, uint256 _addValue);
    event UpdateBonusDuedays(uint256 _newValue);
    event UpdateMaxHolderBonusCount(uint256 _newValue);

    modifier onlyCEO() {
        require(msg.sender == CEOAddress, "Only the CEO is allowed to call this function.");
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == CEOAddress ||
            msg.sender == CIOAddress ||
            msg.sender == COOAddress
        , "Only accounts with C-Level admin rights are allowed to call this function.");
        _;
    }

    constructor (address _cooAddress, address _cioAddress) public ERC20("Drakoin", "DRK") {
        _fractionMultiplier = 1e18;

        burnRate = 500; // 5.0% per tx of non-whitelisted address

        _maximumSupply = 500000000;
        minimumSupply = 250000000 * (10 ** 18);
        minStakeAmount = 1e21;
        minStakeDays = 5;
        maxHolderBonusCount = 5;
        bonusDuedays = 5;

        tierDayRate[5] = 10;     //5 days - 0.1%
        tierDayRate[10] = 30;    //10 days - 0.3%
        tierDayRate[30] = 100;   //30 days - 1.0%
        tierDayRate[90] = 350;   //90 days - 3.5%
        tierDayRate[180] = 750;  //180 days - 7.5%

        COOAddress = _cooAddress;
        CIOAddress = _cioAddress;
        CEOAddress = msg.sender;

        whitelisted[_cooAddress] = true;
        whitelisted[_cioAddress] = true;
        whitelisted[msg.sender] = true;

        _mint(msg.sender, _maximumSupply * (10 ** uint256(decimals())));
    }

    function transfer(address to, uint256 _amount) public virtual override returns (bool) {
        return super.transfer(to, _partialBurn(msg.sender, _amount));
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        return super.transferFrom(_from, _to, _partialBurn(_from, _amount));
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override (ERC20, ERC20Pausable) {
        return super._beforeTokenTransfer(_from, _to, _amount);
    }

    function _partialBurn(address _from, uint256 _amount) internal returns (uint256) {
        uint256 _burnAmount = _calculateBurnAmount(_amount);

        if (_burnAmount > 0) {
            // Calculate rewarwds
            uint256 _currentTotalStakes = _totalStakes();
            if (_currentTotalStakes > 0) {
                uint256 _stakeAmount = (_burnAmount.mul(2)).div(5);
                _valuePerStakedToken = _valuePerStakedToken.add((_stakeAmount.mul(_fractionMultiplier)).div(_currentTotalStakes));
            }

            _transfer(_from, address(this), _burnAmount);
            _burn(address(this), ((_burnAmount.mul(3)).div(5)));
            //_burn(_from, ((_burnAmount.mul(3)).div(5)));
            //_transfer(_from, address(this), ((_burnAmount.mul(2)).div(5)));

        }

        return _amount.sub(_burnAmount);
    }

    function _calculateBurnAmount(uint256 _amount) internal view returns (uint256) {
        if (whitelisted[msg.sender]) return 0;
        uint256 _burnAmount = 0;

        //Calculate tokens to be burned
        if (totalSupply() > minimumSupply) {
            _burnAmount = _amount.mul(burnRate).div(10000);
            uint256 _tryToBurn = totalSupply().sub(minimumSupply);
            if (_burnAmount > _tryToBurn) {
                _burnAmount = _tryToBurn;
            }
        }

        return _burnAmount;
    }

    function setCEOAddress(address _address) external onlyCEO() {
        whitelisted[CEOAddress] = false;
        CEOAddress = _address;
        whitelisted[_address] = true;
        emit CEOAddressUpdated(_address);
    }

    function setCIOAddress(address _address) external onlyCEO() {
        if (CEOAddress != CIOAddress)
        {
            whitelisted[CIOAddress] = false;
        }
        CIOAddress = _address;
        whitelisted[_address] = true;
        emit CIOAddressUpdated(_address);
    }

    function setCOOAddress(address _address) external onlyCEO() {
        if (CEOAddress != COOAddress)
        {
            whitelisted[COOAddress] = false;
        }
        COOAddress = _address;
        whitelisted[_address] = true;
        emit COOAddressUpdated(_address);
    }

    function pause() external onlyCEO() {
        super._pause();
    }

    function unpause() external onlyCEO() {
        super._unpause();
    }

    function burnTokens(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Drakoin: Amount must be equal or greater than the account balance.");

        if (totalSupply() > minimumSupply) {
            uint256 _burnAmount = _amount;
            uint256 _tryToBurn = totalSupply().sub(minimumSupply);
            if (_burnAmount > _tryToBurn) {
                _burnAmount = _tryToBurn;
            }

            uint256 _currentTotalStakes = _totalStakes();
            if (_currentTotalStakes > 0) {
                uint256 _stakeAmount = (_burnAmount.mul(3)).div(5);
                _valuePerStakedToken = _valuePerStakedToken.add((_stakeAmount.mul(_fractionMultiplier)).div(_currentTotalStakes));
            }

            _burn(msg.sender, ((_burnAmount.mul(2)).div(5)));
            _transfer(msg.sender, address(this), ((_burnAmount.mul(3)).div(5)));

        }
        emit BurnTokens(msg.sender, _amount);
    }

    function updateBurnRate(uint256 _newRate) external onlyCEO() {
        require(_newRate >= 500, "Drakoin: Burn rate must be equal or greater than 500.");
        require(_newRate <= 800, "Drakoin: Burn rate must be equal or less than 800.");
        burnRate = _newRate;

        emit UpdateBurnRate(burnRate);
    }

    function isStakeholder(address _address) public view returns(bool) {
        return stakeholder[_address];
    }

    function _isStakeholder(address _address) internal view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function _addStakeholder(address _address) internal {
        (bool _isAddressStakeholder, ) = _isStakeholder(_address);
        if(!_isAddressStakeholder) stakeholders.push(_address);

        stakeholder[_address] = true;
    }

    function _removeStakeholder(address _address) internal {
        (bool _isAddressStakeholder, uint256 s) = _isStakeholder(_address);
        if(_isAddressStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }

        stakeholder[_address] = false;
    }

    function stakeOf(address _stakeholder) public view returns(uint256) {
        return stakes[_stakeholder];
    }

    function _totalStakes() internal view returns(uint256) {
        uint256 _stakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            _stakes = _stakes.add(stakes[stakeholders[s]]);
        }
        return _stakes;
    }

    function totalStakes() public view returns(uint256) {
        return _totalStakes();
    }

    function _calculateBonus(uint256 _amount, uint256 _numberOfDays) internal returns (uint256) {
        if (bonusBalance == 0) {
            return 0;
        }

        uint256 _bonus = _amount.mul(tierDayRate[_numberOfDays]).div(10000);

        if (_bonus > bonusBalance) {
            _bonus = bonusBalance;
            bonusBalance = 0;
            return _bonus;
        }

        bonusBalance = bonusBalance.sub(_bonus);
        return _bonus;
    }

    function createStake(uint256 _amount, uint256 _numberOfDays) public {
        require(_numberOfDays >= minStakeDays, "Drakoin: Number of days must be >= than 5.");
        require(balanceOf(msg.sender) >= _amount, "Drakoin: Amount must be <= account balance.");
        require(stakes[msg.sender] + _amount >= minStakeAmount, "Drakoin: Total stake >= minimum allowed value.");
        require(tierDayRate[_numberOfDays] > 0, "Drakoin: Invalid number of days.");

        if (stakeholder[msg.sender]) {
            require(_numberOfDays >= stakedDays[msg.sender], "Drakoin: Stake days cannot be lowered.");
        }
        stakedDays[msg.sender] = _numberOfDays;

        rewardsForClaiming[msg.sender] = rewardOf(msg.sender);
        stakerValuePerStakedToken[msg.sender] = _valuePerStakedToken;

        _transfer(msg.sender, address(this), _amount);
        if(!stakeholder[msg.sender]) {
            _addStakeholder(msg.sender);
        }
        stakes[msg.sender] = stakes[msg.sender].add(_amount);

        if (holderBonusCount[msg.sender] < maxHolderBonusCount) {
            holderBonusCount[msg.sender]++;

            if (now >= holderBonusDue[msg.sender]) {
                bonus[msg.sender] = 0;
            }
            bonus[msg.sender] = bonus[msg.sender].add(_calculateBonus(_amount, _numberOfDays));

            holderBonusDue[msg.sender] = now.add((bonusDuedays.mul(1 days)));
        }

        duedate[msg.sender] = now.add((_numberOfDays.mul(1 days)));
        emit CreateStake(msg.sender, _amount, _numberOfDays);
    }

    function removeStake(uint256 _amount) public {
        require(now >= duedate[msg.sender], "Drakoin: Current time is before due date.");
        require(stakes[msg.sender] >= _amount, "Drakoin: No current stake for this account.");

        rewardsForClaiming[msg.sender] = rewardOf(msg.sender);
        stakerValuePerStakedToken[msg.sender] = _valuePerStakedToken;

        stakes[msg.sender] = stakes[msg.sender].sub(_amount);
        if(stakes[msg.sender] == 0) _removeStakeholder(msg.sender);
        stakedDays[msg.sender] = 5;

        uint256 _burnAmount = _calculateBurnAmount(_amount);
        if (_burnAmount > 0) {
            uint256 _currentTotalStakes = _totalStakes();
            _burn(address(this), ((_burnAmount.mul(3)).div(5)));

            if (_currentTotalStakes > 0) {
                uint256 _stakeAmount = (_burnAmount.mul(2)).div(5);
                _valuePerStakedToken = _valuePerStakedToken.add((_stakeAmount.mul(_fractionMultiplier)).div(_currentTotalStakes));
            }
        }

        if (now >= holderBonusDue[msg.sender]) {
            bonus[msg.sender] = 0;
        }

        _transfer(address(this), msg.sender, _amount.sub(_burnAmount));
        emit RemoveStake(msg.sender, _amount);
    }

    function updateMinStakeAmount(uint256 _newAmount) external onlyCEO() {
        require(_newAmount >= 1e20, "Drakoin: Value must be more than 1000.");
        minStakeAmount = _newAmount;

        emit UpdateMinStakeAmount(minStakeAmount);
    }

    function updateMinStakeDays(uint256 _newStakeDays) external onlyCEO() {
        require(_newStakeDays > 0, "Drakoin: Value must be more than 0.");
        minStakeDays = _newStakeDays;

        emit UpdateMinStakeDays(minStakeDays);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelisted[_address];
    }

    function addWhitelisted(address _whitelisted) external onlyCEO() {
        whitelisted[_whitelisted] = true;
    }

    function removeWhitelisted(address _whitelisted) external onlyCEO() {
        whitelisted[_whitelisted] = false;
    }

    function updateTierDayRate(uint256 _newNumberOfDays, uint256 _newRate) external onlyCEO() {
        require(_newNumberOfDays > 0, "Drakoin: Number of days must be more than 0.");
        require(_newRate >= 0, "Drakoin: Rate must be more than 0.");
        tierDayRate[_newNumberOfDays] = _newRate;

        emit UpdateTierDayRate(_newNumberOfDays, _newRate);
    }

    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewardsForClaiming[stakeholders[s]]);
        }

        return _totalRewards;
    }

    function rewardOf(address _address) public view returns(uint256) {
        uint256 _bonus = 0;
        uint256 _additionalRewards = ((_valuePerStakedToken.sub(stakerValuePerStakedToken[_address])).mul(stakes[_address])).div(_fractionMultiplier);

        if (now >= holderBonusDue[_address]) {
            _bonus = bonus[_address];
        }

        return rewardsForClaiming[_address].add(_bonus.add(_additionalRewards));
    }

    function claimRewards() external returns (uint256) {
        uint256 _rewards = rewardOf(msg.sender);
        require(_rewards > 0);

        if (now >= holderBonusDue[msg.sender]) {
            bonus[msg.sender] = 0;
        }

        rewardsForClaiming[msg.sender] = 0;
        stakerValuePerStakedToken[msg.sender] = _valuePerStakedToken;

        _transfer(address(this), msg.sender, _rewards);
        emit ClaimRewards(msg.sender, _rewards);
        return _rewards;
    }

    function bonusOf(address _address) public view returns(uint256) {
        return bonus[_address];
    }

    function updateBonusBalance(uint256 _addValue) external onlyCEO() {
        require(_addValue > 0, "Drakoin: Value must be more than 0.");
        bonusBalance = bonusBalance.add(_addValue);

        _transfer(msg.sender, address(this), _addValue);

        emit UpdateBonusBalance(bonusBalance, _addValue);
    }


    function updateMaxHolderBonusCount(uint256 _newValue) external onlyCEO() {
        require(_newValue > 5, "Drakoin: Value must be more than 5.");
        maxHolderBonusCount = _newValue;

        emit UpdateMaxHolderBonusCount(_newValue);
    }

    function updateBonusDuedays(uint256 _newValue) external onlyCEO() {
        require(_newValue > 5, "Drakoin: Value must be more than 5.");
        bonusDuedays = _newValue;

        emit UpdateBonusDuedays(_newValue);
    }

    function get_valuePerStakedToken() external view onlyCLevel returns(uint256) {
        return _valuePerStakedToken;
    }

    function getReleaseDateOf(address _addresss) public view returns(uint256) {
        return duedate[_addresss];
    }

    function get_stakedDays(address _addresss) public view returns(uint256) {
        return stakedDays[_addresss];
    }

    function get_holderBonusCount(address _addresss) public view returns(uint256) {
        return holderBonusCount[_addresss];
    }

    function get_holderBonusDue(address _addresss) public view returns(uint256) {
        return holderBonusDue[_addresss];
    }

}