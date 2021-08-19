/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity 0.6.11;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


pragma solidity 0.6.11;

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


pragma solidity 0.6.11;

// Due to compiling issues, _name, _symbol, and _decimals were removed


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20Custom is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
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
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


pragma solidity 0.6.11;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
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
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


pragma solidity 0.6.11;

interface IBUCKPool {
    function collatDollarBalance() external view returns (uint256);
    // function availableExcessCollatDV() external view returns (uint256);
    function getCollateralPrice() external view returns (uint256);
    function sendExcessCollatToTreasury(uint256 _amount) external;
}


// pragma solidity 0.6.11;

// interface IUniswapV2Factory {
//     event PairCreated(address indexed token0, address indexed token1, address pair, uint);

//     function feeTo() external view returns (address);
//     function feeToSetter() external view returns (address);

//     function getPair(address tokenA, address tokenB) external view returns (address pair);
//     function allPairs(uint) external view returns (address pair);
//     function allPairsLength() external view returns (uint);

//     function createPair(address tokenA, address tokenB) external returns (address pair);

//     function setFeeTo(address) external;
//     function setFeeToSetter(address) external;
// }


// pragma solidity 0.6.11;

// interface IUniswapV2Pair {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external pure returns (string memory);
//     function symbol() external pure returns (string memory);
//     function decimals() external pure returns (uint8);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address owner) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);
//     function transfer(address to, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);
//     function PERMIT_TYPEHASH() external pure returns (bytes32);
//     function nonces(address owner) external view returns (uint);

//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//     event Mint(address indexed sender, uint amount0, uint amount1);
//     event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
//     event Swap(
//         address indexed sender,
//         uint amount0In,
//         uint amount1In,
//         uint amount0Out,
//         uint amount1Out,
//         address indexed to
//     );
//     event Sync(uint112 reserve0, uint112 reserve1);

//     function MINIMUM_LIQUIDITY() external pure returns (uint);
//     function factory() external view returns (address);
//     function token0() external view returns (address);
//     function token1() external view returns (address);
//     function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
//     function price0CumulativeLast() external view returns (uint);
//     function price1CumulativeLast() external view returns (uint);
//     function kLast() external view returns (uint);

//     function mint(address to) external returns (uint liquidity);
//     function burn(address to) external returns (uint amount0, uint amount1);
//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
//     function skim(address to) external;
//     function sync() external;

//     function initialize(address, address) external;
// }


pragma solidity 0.6.11;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}


// pragma solidity 0.6.11;

// // a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// library FixedPoint {
//     // range: [0, 2**112 - 1]
//     // resolution: 1 / 2**112
//     struct uq112x112 {
//         uint224 _x;
//     }

//     // range: [0, 2**144 - 1]
//     // resolution: 1 / 2**112
//     struct uq144x112 {
//         uint _x;
//     }

//     uint8 private constant RESOLUTION = 112;
//     uint private constant Q112 = uint(1) << RESOLUTION;
//     uint private constant Q224 = Q112 << RESOLUTION;

//     // encode a uint112 as a UQ112x112
//     function encode(uint112 x) internal pure returns (uq112x112 memory) {
//         return uq112x112(uint224(x) << RESOLUTION);
//     }

//     // encodes a uint144 as a UQ144x112
//     function encode144(uint144 x) internal pure returns (uq144x112 memory) {
//         return uq144x112(uint256(x) << RESOLUTION);
//     }

//     // divide a UQ112x112 by a uint112, returning a UQ112x112
//     function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
//         require(x != 0, 'FixedPoint: DIV_BY_ZERO');
//         return uq112x112(self._x / uint224(x));
//     }

//     // multiply a UQ112x112 by a uint, returning a UQ144x112
//     // reverts on overflow
//     function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
//         uint z;
//         require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
//         return uq144x112(z);
//     }

//     // returns a UQ112x112 which represents the ratio of the numerator to the denominator
//     // equivalent to encode(numerator).div(denominator)
//     function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
//         require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
//         return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
//     }

//     // decode a UQ112x112 into a uint112 by truncating after the radix point
//     function decode(uq112x112 memory self) internal pure returns (uint112) {
//         return uint112(self._x >> RESOLUTION);
//     }

//     // decode a UQ144x112 into a uint144 by truncating after the radix point
//     function decode144(uq144x112 memory self) internal pure returns (uint144) {
//         return uint144(self._x >> RESOLUTION);
//     }

//     // take the reciprocal of a UQ112x112
//     function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
//         require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
//         return uq112x112(uint224(Q224 / self._x));
//     }

//     // square root of a UQ112x112
//     function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
//         return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
//     }
// }


// pragma solidity 0.6.11;

// // library with helper methods for oracles that are concerned with computing average prices
// library UniswapV2OracleLibrary {
//     using FixedPoint for *;

//     // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
//     function currentBlockTimestamp() internal view returns (uint32) {
//         return uint32(block.timestamp % 2 ** 32);
//     }

//     // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
//     function currentCumulativePrices(
//         address pair
//     ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
//         blockTimestamp = currentBlockTimestamp();
//         price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
//         price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

//         // if time has elapsed since the last update on the pair, mock the accumulated price values
//         (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
//         if (blockTimestampLast != blockTimestamp) {
//             // subtraction overflow is desired
//             uint32 timeElapsed = blockTimestamp - blockTimestampLast;
//             // addition overflow is desired
//             // counterfactual
//             price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
//             // counterfactual
//             price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
//         }
//     }
// }


// pragma solidity 0.6.11;

// library UniswapV2Library {
//     using SafeMath for uint;

//     // returns sorted token addresses, used to handle return values from pairs sorted in this order
//     function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
//         require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
//         (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
//         require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
//     }

//     // Less efficient than the CREATE2 method below
//     function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
//         (address token0, address token1) = sortTokens(tokenA, tokenB);
//         pair = IUniswapV2Factory(factory).getPair(token0, token1);
//     }

//     // calculates the CREATE2 address for a pair without making any external calls
//     function pairForCreate2(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
//         (address token0, address token1) = sortTokens(tokenA, tokenB);
//         pair = address(uint(keccak256(abi.encodePacked(
//                 hex'ff',
//                 factory,
//                 keccak256(abi.encodePacked(token0, token1)),
//                 hex'be5f45c18decae5efcc7ed7cd2084d9ec19d11a86d2566a8ee202504b65b9a64' // init code hash
//             )))); // this matches the CREATE2 in UniswapV2Factory.createPair
//     }

//     // fetches and sorts the reserves for a pair
//     function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
//         (address token0,) = sortTokens(tokenA, tokenB);
//         (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
//         (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
//     }

//     // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
//     function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
//         require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
//         require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
//         amountB = amountA.mul(reserveB) / reserveA;
//     }

//     // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
//     function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
//         require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
//         require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
//         uint amountInWithFee = amountIn.mul(997);
//         uint numerator = amountInWithFee.mul(reserveOut);
//         uint denominator = reserveIn.mul(1000).add(amountInWithFee);
//         amountOut = numerator / denominator;
//     }

//     // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
//     function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
//         require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
//         require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
//         uint numerator = reserveIn.mul(amountOut).mul(1000);
//         uint denominator = reserveOut.sub(amountOut).mul(997);
//         amountIn = (numerator / denominator).add(1);
//     }

//     // performs chained getAmountOut calculations on any number of pairs
//     function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
//         require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
//         amounts = new uint[](path.length);
//         amounts[0] = amountIn;
//         for (uint i; i < path.length - 1; i++) {
//             (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
//             amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
//         }
//     }

//     // performs chained getAmountIn calculations on any number of pairs
//     function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
//         require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
//         amounts = new uint[](path.length);
//         amounts[amounts.length - 1] = amountOut;
//         for (uint i = path.length - 1; i > 0; i--) {
//             (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
//             amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
//         }
//     }
// }

// pragma solidity 0.6.11;

// // Fixed window oracle that recomputes the average price for the entire period once every period
// // Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
// contract UniswapPairOracle {
//     using FixedPoint for *;
    
//     address owner_address;
//     address timelock_address;

//     uint public PERIOD = 3600; // 1 hour TWAP (time-weighted average price)

//     IUniswapV2Pair public immutable pair;
//     address public immutable token0;
//     address public immutable token1;

//     uint    public price0CumulativeLast;
//     uint    public price1CumulativeLast;
//     uint32  public blockTimestampLast;
//     FixedPoint.uq112x112 public price0Average;
//     FixedPoint.uq112x112 public price1Average;

//     modifier onlyByOwnerOrGovernance() {
//         require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
//         _;
//     }

//     constructor(address factory, address tokenA, address tokenB, address _owner_address, address _timelock_address) public {
//         IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
//         pair = _pair;
//         token0 = _pair.token0();
//         token1 = _pair.token1();
//         price0CumulativeLast = _pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
//         price1CumulativeLast = _pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
//         uint112 reserve0;
//         uint112 reserve1;
//         (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
//         require(reserve0 != 0 && reserve1 != 0, 'UniswapPairOracle: NO_RESERVES'); // Ensure that there's liquidity in the pair

//         owner_address = _owner_address;
//         timelock_address = _timelock_address;
//     }

//     function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
//         owner_address = _owner_address;
//     }

//     function setTimelock(address _timelock_address) external onlyByOwnerOrGovernance {
//         timelock_address = _timelock_address;
//     }

//     function setPeriod(uint _period) external onlyByOwnerOrGovernance {
//         PERIOD = _period;
//     }

//     function update() external {
//         (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
//             UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
//         uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

//         // Ensure that at least one full period has passed since the last update
//         require(timeElapsed >= PERIOD, 'UniswapPairOracle: PERIOD_NOT_ELAPSED');

//         // Overflow is desired, casting never truncates
//         // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
//         price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
//         price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

//         price0CumulativeLast = price0Cumulative;
//         price1CumulativeLast = price1Cumulative;
//         blockTimestampLast = blockTimestamp;
//     }

//     // Note this will always return 0 before update has been called successfully for the first time.
//     function consult(address token, uint amountIn) external view returns (uint amountOut) {
//         if (token == token0) {
//             amountOut = price0Average.mul(amountIn).decode144();
//         } else {
//             require(token == token1, 'UniswapPairOracle: INVALID_TOKEN');
//             amountOut = price1Average.mul(amountIn).decode144();
//         }
//     }
// }


pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// pragma solidity 0.6.11;

// contract ChainlinkETHUSDPriceConsumer {

//     AggregatorV3Interface internal priceFeed;


//     constructor() public {
//         priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//     }

//     /**
//      * Returns the latest price
//      */
//     function getLatestPrice() public view returns (int) {
//         (
//             , 
//             int price,
//             ,
//             ,
            
//         ) = priceFeed.latestRoundData();
//         return price;
//     }

//     function getDecimals() public view returns (uint8) {
//         return priceFeed.decimals();
//     }
// }


pragma solidity 0.6.11;
interface ITreasury {
    function withdraw(uint) external;
}


pragma solidity 0.6.11;
interface v3oracle {
    function ethToAsset(address, uint, uint) external view returns (uint);
}


pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// contract BUCKStablecoin is ERC20Custom, AccessControl {
contract BUCKStablecoin is ERC20Custom {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { BUCK, BEVY }
    // ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    AggregatorV3Interface private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    // UniswapPairOracle private buckEthOracle;
    // UniswapPairOracle private bevyEthOracle;
    ERC20 public collateral_token;
    v3oracle public oracle;
    ITreasury public treasury;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public owner_address;
    // address public creator_address;
    address public timelock_address; // Governance timelock address
    address public controller_address; // Controller contract to dynamically adjust system parameters automatically
    address public bevy_address;
    // address public buck_eth_oracle_address;
    // address public bevy_eth_oracle_address;
    address public weth_address;
    address public eth_usd_consumer_address;
    uint256 public constant genesis_supply = 2000000e18; // 2M BUCK (only for testing, genesis supply will be 5k on Mainnet). This is to help with establishing the Uniswap pools, as they need liquidity

    // The addresses in this array are added by the oracle and these contracts are able to mint buck
    address[] public buck_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public buck_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public redemption_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public minting_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public buck_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of BUCK at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio
    uint256 public twap_period; // The twap period in seconds

    // address public DEFAULT_ADMIN_ADDRESS;
    // bytes32 public constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
    bool public collateral_ratio_paused = false;

    /* ========== MODIFIERS ========== */

    // modifier onlyCollateralRatioPauser() {
    //     require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender));
    //     _;
    // }

    modifier onlyPools() {
       require(buck_pools[msg.sender] == true, "Only buck pools can call this function");
        _;
    } 
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address || msg.sender == controller_address, "You are not the owner, controller, or the governance timelock");
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == owner_address 
            || msg.sender == timelock_address 
            || buck_pools[msg.sender] == true, 
            "You are not the owner, the governance timelock, or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        // address _creator_address,
        address _oracle,
        address _collateral_token,
        address _treasury,
        address _eth_usd_pricer,
        address _timelock_address
    ) public {
        name = _name;
        symbol = _symbol;
        collateral_token = ERC20(_collateral_token);
        oracle = v3oracle(_oracle);
        treasury = ITreasury(_treasury);
        // creator_address = _creator_address;
        timelock_address = _timelock_address;
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // DEFAULT_ADMIN_ADDRESS = _msgSender();
        owner_address = msg.sender;
        // _mint(creator_address, genesis_supply);
        _mint(owner_address, genesis_supply);
        // grantRole(COLLATERAL_RATIO_PAUSER, creator_address);
        // grantRole(COLLATERAL_RATIO_PAUSER, timelock_address);
        buck_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // BUCK system starts off fully collateralized (6 decimals of precision)
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
        twap_period = 3600; // default 3600 seconds (1 hour) twap period
        eth_usd_pricer = AggregatorV3Interface(_eth_usd_pricer); // Chainlink ETH/USD Price Feed
    }

    // FOR TEST ONLY! REMOVE WHEN MAINNET!!!
    function setCR(uint256 _cr) external onlyByOwnerOrGovernance {
        global_collateral_ratio = _cr;
    }

    /* ========== VIEWS ========== */

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = eth_usd_pricer.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return eth_usd_pricer.decimals();
    }

    // Choice = 'BUCK' or 'BEVY' for now
    function oracle_price(PriceChoice choice) internal view returns (uint256) {
        require(address(oracle) != address(0), "Oracle address have not set yet");
        require(bevy_address != address(0), "BEVY address have not set yet");

        // Get the ETH / USD price first, and cut it down to 1e6 precision
        // uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        uint256 eth_usd_price = uint256(getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth;

        if (choice == PriceChoice.BUCK) {
            // price_vs_eth = uint256(buckEthOracle.consult(weth_address, PRICE_PRECISION)); // How much BUCK if you put in PRICE_PRECISION WETH
            price_vs_eth = uint256(oracle.ethToAsset(address(this), PRICE_PRECISION, twap_period)); // How much BUCK if you put in PRICE_PRECISION WETH
        } else if (choice == PriceChoice.BEVY) {
            // price_vs_eth = uint256(bevyEthOracle.consult(weth_address, PRICE_PRECISION)); // How much BEVY if you put in PRICE_PRECISION WETH
            price_vs_eth = uint256(oracle.ethToAsset(bevy_address, PRICE_PRECISION, twap_period)); // How much BEVY if you put in PRICE_PRECISION WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (BUCK) or 1 (BEVY)");

        // Will be in 1e6 format
        return eth_usd_price.mul(PRICE_PRECISION).div(price_vs_eth);
    }

    // Returns X BUCK = 1 USD
    function buck_price() public view returns (uint256) {
        return oracle_price(PriceChoice.BUCK);
    }

    // Returns X BEVY = 1 USD
    function bevy_price()  public view returns (uint256) {
        return oracle_price(PriceChoice.BEVY);
    }

    function eth_usd_price() public view returns (uint256) {
        // return uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        return uint256(getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function buck_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            oracle_price(PriceChoice.BUCK), // buck_price()
            oracle_price(PriceChoice.BEVY), // bevy_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            minting_fee, // minting_fee()
            redemption_fee, // redemption_fee()
            // uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
            uint256(getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // Iterate through all buck pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < buck_pools_array.length; i++){ 
            // Exclude null addresses
            if (buck_pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(IBUCKPool(buck_pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        require(address(treasury) != address(0), "Treasury have not set yet");
        uint256 buck_price_cur = buck_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setBUCKStep()) 
        
        if (buck_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= buck_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(buck_step);
            }
        } else if (buck_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(buck_step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(buck_step);
            }
        }

        last_call_time = block.timestamp; // Set the time of the last expansion
        
        // Check if collateral is excess and send it to treasury
        if(availableExcessCollatDV() > 0){
            IBUCKPool(buck_pools_array[0]).sendExcessCollatToTreasury(availableExcessCollatDV());
        } else{
            // Check if collateral is sufficient and withdraw it from treasury to Pool
            uint256 effective_collateral_ratio = globalCollateralValue().mul(1e6).div(totalSupply());
            if(global_collateral_ratio > effective_collateral_ratio){
                uint256 recollat_possible = (global_collateral_ratio.mul(totalSupply()).sub(totalSupply().mul(effective_collateral_ratio))).div(1e6);
                uint256 treasuryCollateralBalance = collateral_token.balanceOf(address(treasury));
                if(treasuryCollateralBalance >= recollat_possible){
                    treasury.withdraw(recollat_possible);
                } else{
                    treasury.withdraw(treasuryCollateralBalance);
                }
            }
        }
    }

    // Returns the value of excess collateral held in this Buck pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 globalCollateralRatio = global_collateral_ratio;

        if (globalCollateralRatio > COLLATERAL_RATIO_PRECISION) globalCollateralRatio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (totalSupply().mul(globalCollateralRatio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 BUCK with $1 of collateral at current collat ratio
        if (globalCollateralValue() > required_collat_dollar_value_d18) return globalCollateralValue().sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit BUCKBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other buck pools will call to mint new BUCK 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit BUCKMinted(msg.sender, m_address, m_amount);
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerOrGovernance {
        require(buck_pools[pool_address] == false, "address already exists");
        buck_pools[pool_address] = true; 
        buck_pools_array.push(pool_address);
    }

    // Change collateral address on specific index
    function changePool(uint index, address new_pool_address) public onlyByOwnerOrGovernance {
        require(index < buck_pools_array.length, "index not found");
        require(buck_pools[buck_pools_array[index]] == true, "old address doesn't exist");

        // Delete from the mapping
        delete buck_pools[buck_pools_array[index]];

        // Update to new pool
        buck_pools[new_pool_address] = true; 
        buck_pools_array[index] = new_pool_address;
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerOrGovernance {
        require(buck_pools[pool_address] == true, "address doesn't exist already");
        
        // Delete from the mapping
        delete buck_pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < buck_pools_array.length; i++){ 
            if (buck_pools_array[i] == pool_address) {
                buck_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setRedemptionFee(uint256 red_fee) public onlyByOwnerOrGovernance {
        redemption_fee = red_fee;
    }

    function setMintingFee(uint256 min_fee) public onlyByOwnerOrGovernance {
        minting_fee = min_fee;
    }
    
    function setTreasury(address _treasury) public onlyByOwnerOrGovernance {
        treasury = ITreasury(_treasury);
    }

    function setAssetEthOracle(address _oracle) public onlyByOwnerOrGovernance{
        oracle = v3oracle(_oracle);
    }

    function setBUCKStep(uint256 _new_step) public onlyByOwnerOrGovernance {
        buck_step = _new_step;
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerOrGovernance {
        price_target = _new_price_target;
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerOrGovernance {
    	refresh_cooldown = _new_cooldown;
    }

    function setTwapPeriod(uint256 _new_twap_period) public onlyByOwnerOrGovernance {
    	twap_period = _new_twap_period;
    }

    function setBEVYAddress(address _bevy_address) public onlyByOwnerOrGovernance {
        bevy_address = _bevy_address;
    }

    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyByOwnerOrGovernance {
        eth_usd_consumer_address = _eth_usd_consumer_address;
        // eth_usd_pricer = ChainlinkETHUSDPriceConsumer(eth_usd_consumer_address);
        eth_usd_pricer = AggregatorV3Interface(eth_usd_consumer_address);
        // eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
        eth_usd_pricer_decimals = getDecimals();
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setController(address _controller_address) external onlyByOwnerOrGovernance {
        controller_address = _controller_address;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerOrGovernance {
        price_band = _price_band;
    }

    function setWETH(address _weth_address) public onlyByOwnerOrGovernance {
        weth_address = _weth_address;
    }

    // Sets the BUCK_ETH Uniswap oracle address 
    // function setBUCKEthOracle(address _buck_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
    //     buck_eth_oracle_address = _buck_oracle_addr;
    //     buckEthOracle = UniswapPairOracle(_buck_oracle_addr); 
    //     weth_address = _weth_address;
    // }

    // Sets the BEVY_ETH Uniswap oracle address 
    // function setBEVYEthOracle(address _bevy_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
    //     bevy_eth_oracle_address = _bevy_oracle_addr;
    //     bevyEthOracle = UniswapPairOracle(_bevy_oracle_addr);
    //     weth_address = _weth_address;
    // }

    // function toggleCollateralRatio() public onlyCollateralRatioPauser {
    function toggleCollateralRatio() public onlyByOwnerOrGovernance {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    /* ========== EVENTS ========== */

    // Track BUCK burned
    event BUCKBurned(address indexed from, address indexed to, uint256 amount);

    // Track BUCK minted
    event BUCKMinted(address indexed from, address indexed to, uint256 amount);
}


pragma solidity 0.6.11;

// contract BEVY is ERC20Custom, AccessControl {
contract BEVYCoin is ERC20Custom {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    // address public BUCKStablecoinAdd;
    
    uint256 public constant genesis_supply = 100000000e18; // 100M is printed upon genesis
    uint256 public BEVY_DAO_min; // Minimum BEVY required to join DAO groups 

    address public owner_address;
    address public oracle_address;
    address public timelock_address; // Governance timelock address
    BUCKStablecoin private BUCK;

    bool public trackingVotes = true; // Tracking votes (only change if need to disable votes)

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(BUCK.buck_pools(msg.sender) == true, "Only buck pools can mint new BEVY");
        _;
    }
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol, 
        address _oracle_address,
        // address _owner_address,
        address _timelock_address
    ) public {
        name = _name;
        symbol = _symbol;
        // owner_address = _owner_address;
        owner_address = msg.sender;
        oracle_address = _oracle_address;
        timelock_address = _timelock_address;
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(owner_address, genesis_supply);

        // Do a checkpoint for the owner
        _writeCheckpoint(owner_address, 0, 0, uint96(genesis_supply));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOracle(address new_oracle) external onlyByOwnerOrGovernance {
        oracle_address = new_oracle;
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }
    
    function setBUCKAddress(address buck_contract_address) external onlyByOwnerOrGovernance {
        BUCK = BUCKStablecoin(buck_contract_address);
    }

    function setBEVYMinDAO(uint256 min_BEVY) external onlyByOwnerOrGovernance {
        BEVY_DAO_min = min_BEVY;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
    }
    
    // This function is what other buck pools will call to mint new BEVY (similar to the BUCK mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools {        
        if(trackingVotes){
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = add96(srcRepOld, uint96(m_amount), "pool_mint new votes overflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // mint new votes
            trackVotes(address(this), m_address, uint96(m_amount));
        }
        
        super._mint(m_address, m_amount);
        emit BEVYMinted(address(this), m_address, m_amount);
    }

    // This function is what other buck pools will call to burn BEVY 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {
        if(trackingVotes){
            trackVotes(b_address, address(this), uint96(b_amount));
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = sub96(srcRepOld, uint96(b_amount), "pool_burn_from new votes underflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // burn votes
        }
        
        super._burnFrom(b_address, b_amount);
        emit BEVYBurned(b_address, address(this), b_amount);
    }

    function toggleVotes() external onlyByOwnerOrGovernance {
        trackingVotes = !trackingVotes;
    }

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(_msgSender(), recipient, uint96(amount));
        }
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(sender, recipient, uint96(amount));
        }
        
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "BEVY::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // From compound's _moveDelegates
    // Keep track of votes. "Delegates" is a misnomer here
    function trackVotes(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "BEVY::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "BEVY::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address voter, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BEVY::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[voter][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[voter][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[voter][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[voter] = nCheckpoints + 1;
      }

      emit VoterVotesChanged(voter, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /* ========== EVENTS ========== */
    
    /// @notice An event thats emitted when a voters account's vote balance changes
    event VoterVotesChanged(address indexed voter, uint previousBalance, uint newBalance);

    // Track BEVY burned
    event BEVYBurned(address indexed from, address indexed to, uint256 amount);

    // Track BEVY minted
    event BEVYMinted(address indexed from, address indexed to, uint256 amount);

}


pragma solidity ^0.6.0;

library BuckPoolLibrary {
    using SafeMath for uint256;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // ================ Structs ================
    // Needed to lower stack size
    struct MintFF_Params {
        uint256 bevy_price_usd; 
        uint256 col_price_usd;
        uint256 bevy_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackBEVY_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 bevy_price_usd;
        uint256 col_price_usd;
        uint256 BEVY_amount;
    }

    // ================ Functions ================

    function calcMint1t1BUCK(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18.mul(col_price)).div(1e6);
    }

    function calcMintAlgorithmicBUCK(uint256 bevy_price_usd, uint256 bevy_amount_d18) public pure returns (uint256) {
        return bevy_amount_d18.mul(bevy_price_usd).div(1e6);
    }

    // Must be internal because of the struct
    function calcMintFractionalBUCK(MintFF_Params memory params) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint BUCK. We do this by seeing the minimum mintable BUCK based on each amount 
        uint256 bevy_dollar_value_d18;
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the BEVY
            bevy_dollar_value_d18 = params.bevy_amount.mul(params.bevy_price_usd).div(1e6);
            c_dollar_value_d18 = params.collateral_amount.mul(params.col_price_usd).div(1e6);

        }
        uint calculated_bevy_dollar_value_d18 = 
                    (c_dollar_value_d18.mul(1e6).div(params.col_ratio))
                    .sub(c_dollar_value_d18);

        uint calculated_bevy_needed = calculated_bevy_dollar_value_d18.mul(1e6).div(params.bevy_price_usd);

        return (
            c_dollar_value_d18.add(calculated_bevy_dollar_value_d18),
            calculated_bevy_needed
        );
    }

    function calcRedeem1t1BUCK(uint256 col_price_usd, uint256 BUCK_amount) public pure returns (uint256) {
        return BUCK_amount.mul(1e6).div(col_price_usd);
    }

    // Must be internal because of the struct
    function calcBuyBackBEVY(BuybackBEVY_Params memory params) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible BEVY with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 bevy_dollar_value_d18 = params.BEVY_amount.mul(params.bevy_price_usd).div(1e6);
        require(bevy_dollar_value_d18 <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of BEVY provided 
        uint256 collateral_equivalent_d18 = bevy_dollar_value_d18.mul(1e6).div(params.col_price_usd);
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));

        return (
            collateral_equivalent_d18
        );

    }

    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = total_supply.mul(global_collateral_ratio).div(1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value.sub(global_collat_value); // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }

    function calcRecollateralizeBUCKInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 buck_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = collateral_amount.mul(col_price).div(1e6);
        uint256 effective_collateral_ratio = global_collat_value.mul(1e6).div(buck_total_supply); //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio.mul(buck_total_supply).sub(buck_total_supply.mul(effective_collateral_ratio))).div(1e6);

        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }

        return (amount_to_recollat.mul(1e6).div(col_price), amount_to_recollat);

    }

}


pragma solidity 0.6.11;

// contract BuckPool is AccessControl {
contract BuckPool {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    address private collateral_address;
    address private owner_address;
    // address private oracle_address;
    address private buck_contract_address;
    address private bevy_contract_address;
    address private timelock_address; // Timelock address for the governance contract
    BEVYCoin private BEVY;
    BUCKStablecoin private BUCK;
    // UniswapPairOracle private oracle;
    // UniswapPairOracle private collatEthOracle;
    v3oracle public oracle;
    address public collat_eth_oracle_address;
    address private weth_address;
    address public treasury;

    // uint256 public minting_fee;
    // uint256 public redemption_fee;
    // uint256 public buyback_fee;
    uint256 public recollat_fee;

    mapping (address => uint256) public redeemBEVYBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolBEVY;
    mapping (address => uint256) public lastRedeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    // uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // The twap period in seconds
    uint256 public twap_period;

    // Number of decimals needed to get to 18
    uint256 private immutable missing_decimals;
    
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pool_ceiling = 0;

    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;

    // Bonus rate on BEVY minted during recollateralizeBUCK(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
        _;
    }

    modifier onlyGov(){
        require(msg.sender == timelock_address, "You are not the governance timelock");
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        _;
    }

    modifier onlyBUCK() {
        require(msg.sender == buck_contract_address, "Must from BUCK Contract");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address _buck_contract_address,
        address _bevy_contract_address,
        address _collateral_address,
        address _treasury,
        address _oracle,
        // address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) public {
        BUCK = BUCKStablecoin(_buck_contract_address);
        BEVY = BEVYCoin(_bevy_contract_address);
        buck_contract_address = _buck_contract_address;
        bevy_contract_address = _bevy_contract_address;
        collateral_address = _collateral_address;
        treasury = _treasury;
        oracle = v3oracle(_oracle);
        timelock_address = _timelock_address;
        // owner_address = _creator_address;
        owner_address = msg.sender;
        collateral_token = ERC20(_collateral_address);
        pool_ceiling = _pool_ceiling;
        twap_period = 3600; // default 3600 seconds (1 hour) twap period
        missing_decimals = uint(18).sub(collateral_token.decimals());
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this Buck pool
    function collatDollarBalance() public view returns (uint256) {
        if(collateralPricePaused == true){
            return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(pausedPrice).div(PRICE_PRECISION);
        } else {
            uint256 eth_usd_price = BUCK.eth_usd_price();
            // uint256 eth_collat_price = collatEthOracle.consult(weth_address, (PRICE_PRECISION * (10 ** missing_decimals)));
            uint256 eth_collat_price = oracle.ethToAsset(buck_contract_address, (PRICE_PRECISION * (10 ** missing_decimals)), twap_period);

            uint256 collat_usd_price = eth_usd_price.mul(PRICE_PRECISION).div(eth_collat_price);
            return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
        }
    }

    // Returns the value of excess collateral held in this Buck pool, compared to what is needed to maintain the global collateral ratio
    // function availableExcessCollatDV() public view returns (uint256) {
    //     // uint256 total_supply = BUCK.totalSupply();
    //     // uint256 global_collateral_ratio = BUCK.global_collateral_ratio();
    //     // uint256 global_collat_value = BUCK.globalCollateralValue();
    //     (,,uint256 total_supply,uint256 global_collateral_ratio,uint256 global_collat_value,,,) = BUCK.buck_info();

    //     if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
    //     uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 BUCK with $1 of collateral at current collat ratio
    //     if (global_collat_value > required_collat_dollar_value_d18) return global_collat_value.sub(required_collat_dollar_value_d18);
    //     else return 0;
    // }

    /* ========== PUBLIC FUNCTIONS ========== */

    function sendExcessCollatToTreasury(uint256 _amount) public onlyBUCK {
        require(treasury != address(0), "Treasury hasn't set yet");
        collateral_token.transfer(treasury, _amount.div(collateral_token.decimals()));
    }
    
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else {
            uint256 eth_usd_price = BUCK.eth_usd_price();
            // return eth_usd_price.mul(PRICE_PRECISION).div(collatEthOracle.consult(weth_address, PRICE_PRECISION * (10 ** missing_decimals)));
            return eth_usd_price.mul(PRICE_PRECISION).div(oracle.ethToAsset(buck_contract_address, PRICE_PRECISION * (10 ** missing_decimals), twap_period));
        }
    }

    // function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external onlyByOwnerOrGovernance {
    //     collat_eth_oracle_address = _collateral_weth_oracle_address;
    //     collatEthOracle = UniswapPairOracle(_collateral_weth_oracle_address);
    //     weth_address = _weth_address;
    // }

    function setWETH(address _weth_address) public onlyByOwnerOrGovernance {
        weth_address = _weth_address;
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1BUCK(uint256 collateral_amount, uint256 BUCK_out_min) external notMintPaused {
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        (,,,uint256 global_collateral_ratio,,uint256 minting_fee,,) = BUCK.buck_info();
        
        require(global_collateral_ratio >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require((collateral_token.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        
        (uint256 buck_amount_d18) = BuckPoolLibrary.calcMint1t1BUCK(
            getCollateralPrice(),
            collateral_amount_d18
        ); //1 BUCK for each $1 worth of collateral

        buck_amount_d18 = (buck_amount_d18.mul(uint(1e6).sub(minting_fee))).div(1e6); //remove precision at the end
        require(BUCK_out_min <= buck_amount_d18, "Slippage limit reached");

        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        BUCK.pool_mint(msg.sender, buck_amount_d18);
    }

    // 0% collateral-backed
    function mintAlgorithmicBUCK(uint256 bevy_amount_d18, uint256 BUCK_out_min) external notMintPaused {
        // uint256 bevy_price = BUCK.bevy_price();
        (,uint256 bevy_price,,uint256 global_collateral_ratio,,uint256 minting_fee,,) = BUCK.buck_info();

        // require(BUCK.global_collateral_ratio() == 0, "Collateral ratio must be 0");
        require(global_collateral_ratio == 0, "Collateral ratio must be 0");
        
        (uint256 buck_amount_d18) = BuckPoolLibrary.calcMintAlgorithmicBUCK(
            bevy_price, // X BEVY / 1 USD
            bevy_amount_d18
        );

        buck_amount_d18 = (buck_amount_d18.mul(uint(1e6).sub(minting_fee))).div(1e6);
        require(BUCK_out_min <= buck_amount_d18, "Slippage limit reached");

        BEVY.pool_burn_from(msg.sender, bevy_amount_d18);
        BUCK.pool_mint(msg.sender, buck_amount_d18);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalBUCK(uint256 collateral_amount, uint256 bevy_amount, uint256 BUCK_out_min) external notMintPaused {
        // uint256 bevy_price = BUCK.bevy_price();        
        // uint256 global_collateral_ratio = BUCK.global_collateral_ratio();
        (,uint256 bevy_price,,uint256 global_collateral_ratio,,uint256 minting_fee,,) = BUCK.buck_info();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more BUCK can be minted with this collateral");

        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        BuckPoolLibrary.MintFF_Params memory input_params = BuckPoolLibrary.MintFF_Params(
            bevy_price,
            getCollateralPrice(),
            bevy_amount,
            collateral_amount_d18,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 bevy_needed) = BuckPoolLibrary.calcMintFractionalBUCK(input_params);

        mint_amount = (mint_amount.mul(uint(1e6).sub(minting_fee))).div(1e6);
        require(BUCK_out_min <= mint_amount, "Slippage limit reached");
        require(bevy_needed <= bevy_amount, "Not enough BEVY inputted");

        BEVY.pool_burn_from(msg.sender, bevy_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        BUCK.pool_mint(msg.sender, mint_amount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1BUCK(uint256 BUCK_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
        (,,,uint256 global_collateral_ratio,,,uint256 redemption_fee,) = BUCK.buck_info();
        require(global_collateral_ratio == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");

        // Need to adjust for decimals of collateral
        uint256 BUCK_amount_precision = BUCK_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = BuckPoolLibrary.calcRedeem1t1BUCK(
            getCollateralPrice(),
            BUCK_amount_precision
        );

        collateral_needed = (collateral_needed.mul(uint(1e6).sub(redemption_fee))).div(1e6);
        require(collateral_needed <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
        lastRedeemed[msg.sender] = block.number;
        
        // Move all external functions to the end
        BUCK.pool_burn_from(msg.sender, BUCK_amount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem BUCK for collateral and BEVY. > 0% and < 100% collateral-backed
    function redeemFractionalBUCK(uint256 BUCK_amount, uint256 BEVY_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
        // uint256 bevy_price = BUCK.bevy_price();
        // uint256 global_collateral_ratio = BUCK.global_collateral_ratio();
        (,uint256 bevy_price,,uint256 global_collateral_ratio,,,uint256 redemption_fee,) = BUCK.buck_info();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        uint256 col_price_usd = getCollateralPrice();

        uint256 BUCK_amount_post_fee = (BUCK_amount.mul(uint(1e6).sub(redemption_fee))).div(PRICE_PRECISION);

        uint256 bevy_dollar_value_d18 = BUCK_amount_post_fee.sub(BUCK_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION));
        uint256 bevy_amount = bevy_dollar_value_d18.mul(PRICE_PRECISION).div(bevy_price);

        // Need to adjust for decimals of collateral
        uint256 BUCK_amount_precision = BUCK_amount_post_fee.div(10 ** missing_decimals);
        uint256 collateral_dollar_value = BUCK_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
        uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(col_price_usd);


        require(collateral_amount <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(BEVY_out_min <= bevy_amount, "Slippage limit reached [BEVY]");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);

        redeemBEVYBalances[msg.sender] = redeemBEVYBalances[msg.sender].add(bevy_amount);
        unclaimedPoolBEVY = unclaimedPoolBEVY.add(bevy_amount);

        lastRedeemed[msg.sender] = block.number;
        
        // Move all external functions to the end
        BUCK.pool_burn_from(msg.sender, BUCK_amount);
        BEVY.pool_mint(address(this), bevy_amount);
    }

    // Redeem BUCK for BEVY. 0% collateral-backed
    function redeemAlgorithmicBUCK(uint256 BUCK_amount, uint256 BEVY_out_min) external notRedeemPaused {
        // uint256 bevy_price = BUCK.bevy_price();
        // uint256 global_collateral_ratio = BUCK.global_collateral_ratio();
        (,uint256 bevy_price,,uint256 global_collateral_ratio,,,uint256 redemption_fee,) = BUCK.buck_info();

        require(global_collateral_ratio == 0, "Collateral ratio must be 0"); 
        uint256 bevy_dollar_value_d18 = BUCK_amount;

        bevy_dollar_value_d18 = (bevy_dollar_value_d18.mul(uint(1e6).sub(redemption_fee))).div(PRICE_PRECISION); //apply fees

        uint256 bevy_amount = bevy_dollar_value_d18.mul(PRICE_PRECISION).div(bevy_price);
        
        redeemBEVYBalances[msg.sender] = redeemBEVYBalances[msg.sender].add(bevy_amount);
        unclaimedPoolBEVY = unclaimedPoolBEVY.add(bevy_amount);
        
        lastRedeemed[msg.sender] = block.number;
        
        require(BEVY_out_min <= bevy_amount, "Slippage limit reached");
        // Move all external functions to the end
        BUCK.pool_burn_from(msg.sender, BUCK_amount);
        BEVY.pool_mint(address(this), bevy_amount);
    }

    // After a redemption happens, transfer the newly minted BEVY and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out BUCK/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendBEVY = false;
        bool sendCollateral = false;
        uint BEVYAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemBEVYBalances[msg.sender] > 0){
            BEVYAmount = redeemBEVYBalances[msg.sender];
            redeemBEVYBalances[msg.sender] = 0;
            unclaimedPoolBEVY = unclaimedPoolBEVY.sub(BEVYAmount);

            sendBEVY = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

            sendCollateral = true;
        }

        if(sendBEVY == true){
            BEVY.transfer(msg.sender, BEVYAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
    }


    // When the protocol is recollateralizing, we need to give a discount of BEVY to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get BEVY for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of BEVY + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra BEVY value from the bonus rate as an arb opportunity
    function recollateralizeBUCK(uint256 collateral_amount, uint256 BEVY_out_min) external {
        require(recollateralizePaused == false, "Recollateralize is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        // uint256 bevy_price = BUCK.bevy_price();
        // uint256 buck_total_supply = BUCK.totalSupply();
        // uint256 global_collateral_ratio = BUCK.global_collateral_ratio();
        // uint256 global_collat_value = BUCK.globalCollateralValue();
        (,uint256 bevy_price,uint256 buck_total_supply,uint256 global_collateral_ratio,uint256 global_collat_value,,,) = BUCK.buck_info();

        (uint256 collateral_units, uint256 amount_to_recollat) = BuckPoolLibrary.calcRecollateralizeBUCKInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            buck_total_supply,
            global_collateral_ratio
        ); 

        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);

        uint256 bevy_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate).sub(recollat_fee)).div(bevy_price);

        require(BEVY_out_min <= bevy_paid_back, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        BEVY.pool_mint(msg.sender, bevy_paid_back);
        
    }

    // Function can be called by an BEVY holder to have the protocol buy back BEVY with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    // function buyBackBEVY(uint256 BEVY_amount, uint256 COLLATERAL_out_min) external {
    //     require(buyBackPaused == false, "Buyback is paused");
    //     uint256 bevy_price = BUCK.bevy_price();
    
    //     BuckPoolLibrary.BuybackBEVY_Params memory input_params = BuckPoolLibrary.BuybackBEVY_Params(
    //         availableExcessCollatDV(),
    //         bevy_price,
    //         getCollateralPrice(),
    //         BEVY_amount
    //     );

    //     (uint256 collateral_equivalent_d18) = (BuckPoolLibrary.calcBuyBackBEVY(input_params)).mul(uint(1e6).sub(buyback_fee)).div(1e6);
    //     uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);

    //     require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
    //     // Give the sender their desired collateral and burn the BEVY
    //     BEVY.pool_burn_from(msg.sender, BEVY_amount);
    //     collateral_token.transfer(msg.sender, collateral_precision);
    // }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // EMERGENCY ONLY FOR SAVE ASSETS
    function emergencyTransfer(address _target) public onlyGov{
        collateral_token.transfer(_target, collateral_token.balanceOf(address(this)));
    }

    function toggleMinting() external onlyByOwnerOrGovernance{
        mintPaused = !mintPaused;
    }

    function toggleRedeeming() external onlyByOwnerOrGovernance{
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external onlyByOwnerOrGovernance{
        recollateralizePaused = !recollateralizePaused;
    }
    
    function toggleBuyBack() external onlyByOwnerOrGovernance{
        buyBackPaused = !buyBackPaused;
    }

    function toggleCollateralPrice(uint256 _new_price) external onlyByOwnerOrGovernance{
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = _new_price;
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;
    }

    // Combined into one function due to 24KiB contract memory limit
    // function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnerOrGovernance {
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_recollat_fee) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        // minting_fee = new_mint_fee;
        // redemption_fee = new_redeem_fee;
        // buyback_fee = new_buyback_fee;
        recollat_fee = new_recollat_fee;
    }

    function setAssetEthOracle(address _oracle) public onlyByOwnerOrGovernance{
        oracle = v3oracle(_oracle);
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setTreasury(address _treasury) public onlyByOwnerOrGovernance {
        treasury = _treasury;
    }

    function setTwapPeriod(uint256 _new_twap_period) public onlyByOwnerOrGovernance {
    	twap_period = _new_twap_period;
    }

    /* ========== EVENTS ========== */

}