/**
 *Submitted for verification at hooscan.com on 2021-08-03
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/Context.sol

// 

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// 

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// 

pragma solidity >=0.6.0 <0.8.0;




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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * Requirements:
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
     * Requirements:
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// File: @openzeppelin/contracts/utils/Address.sol

// 

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// 

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

// File: @openzeppelin/contracts/access/Ownable.sol

// 

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
    constructor () internal {
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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

// 

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/multisender/HgtBridge.sol

// File: contracts/multisender/HGTMiner.sol

/**
 *Submitted for verification at hecoinfo.com on 2021-02-04
*/

//
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;








interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

contract HGTBridge is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct DepositInfo {
        uint256 inAmount;
        uint256 inCount;
        uint256 outAmount;
        uint256 outCount;
    }
    struct LiquidityInfo{
        uint256 feeInAmount;
        uint256 feeOutAmount;
        uint256 liquidityInAmount;
        uint256 liquidityOutAmount;
        uint256 liquidityBalance;
    }
    using EnumerableSet for EnumerableSet.AddressSet;
    //Main Asset Liquidity Fee Percent * 1000
    mapping(address => uint256) public mainAsset;
    //Liquidity Asset Map（Token=>User)
    mapping(address => mapping(address=>LiquidityInfo)) public liquidityTokenDepositInfo;
    //Liquidity Users of Token
    mapping(address =>  EnumerableSet.AddressSet) private liquidityUsers;
    //Platform LiquidityFee
    mapping(address => LiquidityInfo) public platformLiquidity;
    //Token Deposit Info
    mapping(address => DepositInfo) public tokenDepositInfo;
    //Token Swap Info
    mapping(address => DepositInfo) public tokenSwapInfo;
    //Token=>Admin
    mapping(address => address) private _tokenAdmin;
    //Admin=>Token
    mapping(address => address) private _adminToken;

    uint256 public nonce = 0;

    mapping(address => bool) private _admins;

    uint256 public userFee = 0.02 ether;
    uint256 public tokenFee = 0.1 ether;  

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    event SetTokenAccount(address indexed account, uint256 chainId, address token);
    event UnsetTokenAccount(address indexed account, uint256 chainId, address token);
    event TokenTransferIn(address indexed from, uint256 chainId, address token,uint256 amount,uint256 fnonce);
    event TokenTransferOut(address indexed from, address to, uint256 fchainId,  address token, uint256 tchainId, uint256 amount,uint256 fnonce);
    event TransferIn(address indexed from, address to, uint256 fchainId, address token, uint256 tchainId, uint256 amount,uint256 fnonce);
    event SwapIn(address indexed from, address to, uint256 fchainId, address token, uint256 tchainId, uint256 amount,uint256 fnonce);
    event TransferOut(address indexed from, address to,uint256 fchainId, uint256 tchainId, address token,  uint256 amount,uint256 fnonce, uint256 tnonce);
    event SwapOut(address indexed from, address to,uint256 fchainId, uint256 tchainId, address token,  uint256 amount,uint256 fnonce, uint256 tnonce);
    event ClaimedFee(address user, uint256 balance);
    event ClaimedLiquidityFee(address token, address user, uint256 balance);
    event SendEther(address user, uint256 balance,uint256 fchainId, uint256 fnonce, uint256 buynonce);

    //address of the uniswap v2 router
    address private dex_router_contract = address(0x0);
    address private wrapped_ether = address(0x0);
    constructor(uint256 _userFee, uint256 _tokenFee) 
    {
        userFee = _userFee;
        tokenFee = _tokenFee;
    }

    function isAdmin(address _account) public view returns (bool) 
    {
        return _admins[_account];
    }

    function getUserToken(address _account) public view returns (address)
    {
        return _adminToken[_account];
    }
    
    function getTokenAdmin(address _token) public view returns (address)
    {
        return _tokenAdmin[_token];
    }

    function addAdmin(address _account) external onlyOwner 
    {
        _admins[_account] = true;
        emit AdminAdded(_account);
    }
    
    function removeAdmin(address _account) external onlyOwner 
    {
        _admins[_account] = false;
        emit AdminRemoved(_account);
    }

    function setTransferFee(uint256 _userFee, uint256 _tokenFee) external onlyOwner
    {
        userFee = _userFee;
        tokenFee = _tokenFee;
    }

    function addMainAsset(address _token, uint256 _fee) external onlyOwner{
        require(_token!=address(0x0) && _fee > 0, "invalid fee amount");
        mainAsset[_token] = _fee;
    }
    function removeMainAsset(address _token) external onlyOwner{
        require(mainAsset[_token]>0, "token is not main asset");
        delete mainAsset[_token];
    }

    function setTokenAccount(address _account, address  _token)  external onlyOwner{
        _adminToken[_account] = address(_token);
        _tokenAdmin[_token] = _account; 
        SetTokenAccount(_account, _getChainID(), _token);
    }

    function removeTokenAccount(address _account, address  _token)  external onlyOwner{
        _adminToken[_account] = address(0x0);
        _tokenAdmin[_token] = address(0x0); 
        UnsetTokenAccount(_account, _getChainID(), _token);
    }

   
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin can call");
        _;
    }


    /**
     * @dev Get the running network chain ID.
     * @return The chain ID
     */
    function _getChainID() private pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    function addLiquidity(address _token, uint256 _amount) payable external{
        require(msg.value>=tokenFee, "Wrong input Fee");

        if(_tokenAdmin[_token] == msg.sender){
            depositIn(_token, _amount);
            return;
        }
        require(mainAsset[_token]>0, "token is not main asset");
        require(_amount > 0, "wrong token amount");
        _depositIn(_token, _amount);
        LiquidityInfo storage liquidityInfo = liquidityTokenDepositInfo[_token][msg.sender];
        if(liquidityInfo.liquidityBalance == 0) {
            EnumerableSet.AddressSet storage users = liquidityUsers[_token];
            users.add(msg.sender);
        }
        liquidityInfo.liquidityInAmount = liquidityInfo.liquidityInAmount.add(_amount);
        liquidityInfo.liquidityBalance = liquidityInfo.liquidityBalance.add(_amount);
    }
    function removeLiquidity(address _token,uint256 _amount, address _toAddr, uint256 _tchainId) payable external{
        require(msg.value>=userFee, "Wrong input Fee");

        if(_tokenAdmin[_token] == msg.sender){
            withdrawOut(_token, _amount, _toAddr, _tchainId);
            return;
        }
        require(mainAsset[_token]>0, "token is not main asset");
        require(_amount > 0, "wrong token amount");
        
        LiquidityInfo storage liquidityInfo = liquidityTokenDepositInfo[_token][msg.sender];
        liquidityInfo.liquidityOutAmount = liquidityInfo.liquidityOutAmount.add(_amount);

        require(liquidityInfo.liquidityBalance >= _amount, "invalid amount");
        liquidityInfo.liquidityBalance = liquidityInfo.liquidityBalance.sub(_amount);
        if(liquidityInfo.liquidityBalance == 0){
            EnumerableSet.AddressSet storage users = liquidityUsers[_token];
            users.remove(msg.sender);
        }
        _withdrawOut(_token, _amount, _toAddr, _tchainId);
    }
    function _depositIn(address _token, uint256 _amount) private{

        DepositInfo storage _tokenDepositInfo = tokenDepositInfo[_token];
        LiquidityInfo storage _platformInfo = platformLiquidity[_token];
        
        require(_amount > 0, "wrong token amount");
       
        // 转币
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);

        _tokenDepositInfo.inAmount = _tokenDepositInfo.inAmount.add(_amount);
        _tokenDepositInfo.inCount = _tokenDepositInfo.inCount.add(1);
        
        _platformInfo.liquidityInAmount = _platformInfo.liquidityInAmount.add(_amount);
        _platformInfo.liquidityBalance = _platformInfo.liquidityBalance.add(_amount);

        nonce = nonce.add(1);
        emit TokenTransferIn(msg.sender, _getChainID(), _token, _amount, nonce);
    }
    //Token admin deposit
    function depositIn(address _token,uint256 _amount) private{
        require(_tokenAdmin[_token] == msg.sender, "wrong token admin");

        _depositIn(_token, _amount);
    }
    function _withdrawOut(address _token,uint256 _amount, address _toAddr, uint256 _tchainId) private
    {
        require(_amount > 0, "wrong token amount");

        LiquidityInfo storage _platformInfo = platformLiquidity[_token];
        _platformInfo.liquidityOutAmount = _platformInfo.liquidityOutAmount.add(_amount);
        _platformInfo.liquidityBalance = _platformInfo.liquidityBalance.sub(_amount);

        nonce = nonce.add(1);
        
        emit TokenTransferOut(msg.sender, _toAddr, _getChainID(), _token,  _tchainId, _amount, nonce);
    }
    //Token admin withdraw
    function withdrawOut(address _token,uint256 _amount, address _toAddr, uint256 _tchainId) private{
        require(_tokenAdmin[_token] == msg.sender, "wrong token admin");
        _withdrawOut(_token, _amount, _toAddr, _tchainId);
    }
    function _transferIn(address _token, uint256 _amount, address _toAddr, uint256 _chainId) private{
        require(_amount > 0, "wrong token amount");
        DepositInfo storage _tokenDepositInfo = tokenDepositInfo[_token];        
        // 转币
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);

        _tokenDepositInfo.inAmount = _tokenDepositInfo.inAmount.add(_amount);
        _tokenDepositInfo.inCount = _tokenDepositInfo.inCount.add(1);
        nonce = nonce.add(1);
        emit TransferIn(msg.sender, _toAddr, _getChainID(), _token, _chainId, _amount, nonce);
    }
    function transferIn(address _token, uint256 _amount, address _toAddr, uint256 _chainId) payable external{
        //Check Fee
        require(msg.value>=userFee, "Wrong input Fee");
        require(_tokenAdmin[_token] != address(0x0) || mainAsset[_token]>0, "wrong token to be bridged");
        _transferIn(_token, _amount, _toAddr, _chainId);
    }
    function _transferOut(address _user, address _toAddr, uint256 _fchainId, uint256 _tchainId, address _token, uint256 _amount,uint256 _fnonce) private
    {
        require(_tchainId == _getChainID(), "wrong chain Id");
        require(_amount > 0, "wrong token amount");

        IERC20 token = IERC20(_token);
        uint256 _tokenBalance = token.balanceOf(address(this));
        require(_amount <= _tokenBalance, "Not enough fund");
        DepositInfo storage _tokenDepositInfo = tokenDepositInfo[_token];
          
        _tokenDepositInfo.outAmount = _tokenDepositInfo.outAmount.add(_amount);
        _tokenDepositInfo.outCount = _tokenDepositInfo.outCount.add(1);

        safeTransfer(IERC20(_token), _toAddr, _amount);
        
        nonce = nonce.add(1);
        emit TransferOut(_user, _toAddr, _fchainId, _getChainID(), _token, _amount, _fnonce, nonce);
    }
    function transferLiquidityOut(address _user, address _toAddr, uint256 _fchainId, uint256 _tchainId, address _token, uint256 _amount,uint256 _fnonce) external onlyAdmin
    {
        _transferOut(_user, _toAddr, _fchainId, _tchainId, _token, _amount, _fnonce);
    }
    function updateLiquidityReward(address _token, uint256 _amount) private returns (uint256)
    {
        EnumerableSet.AddressSet storage users = liquidityUsers[_token];
        uint256 _total = 0;
        {
            LiquidityInfo memory _info;
            address _curruser = address(0x0);
            for(uint256 i=0; i<users.length(); i++){
                _curruser = users.at(i);
                _info = liquidityTokenDepositInfo[_token][_curruser];
                if(_info.liquidityBalance > 0)
                {
                    _total = _total.add(_info.liquidityBalance);
                }
            }
        }
        uint256 _feeAmount = _amount.mul(mainAsset[_token]).div(1000);
        uint256 _userFeeAmount = _feeAmount.mul(80).div(100);

        LiquidityInfo storage _platformInfo = platformLiquidity[_token];
        _platformInfo.feeInAmount = _platformInfo.feeInAmount.add(_feeAmount.mul(20).div(100));

        {
            LiquidityInfo storage _info;
            address _curruser = address(0x0);
            for(uint256 i=0; i<users.length(); i++){
                _curruser = users.at(i);
                _info = liquidityTokenDepositInfo[_token][_curruser];
                if(_info.liquidityBalance > 0)
                {
                    uint256 _currUserFeeAmount = _userFeeAmount.mul(_info.liquidityBalance).div(_total);
                    _info.feeInAmount = _info.feeInAmount.add(_currUserFeeAmount);
                }
            }
        }
        uint256 _outAmount = _amount.sub(_feeAmount);
        return _outAmount;
    }
     function _transferMainOut(address _user, address _toAddr, uint256 _fchainId, uint256 _tchainId, address _token, uint256 _amount,uint256 _fnonce) private
    {
        require(_tchainId == _getChainID(), "wrong chain Id");
        require(_amount > 0, "wrong token amount");
        require(mainAsset[_token]>0, "token is not main asset");

        IERC20 token = IERC20(_token);
        require(_amount <= token.balanceOf(address(this)), "Not enough fund");
        DepositInfo storage _tokenDepositInfo = tokenDepositInfo[_token];
          
        _tokenDepositInfo.outAmount = _tokenDepositInfo.outAmount.add(_amount);
        _tokenDepositInfo.outCount = _tokenDepositInfo.outCount.add(1);
        
        uint256 _outAmount = updateLiquidityReward(_token, _amount);
        safeTransfer(token, _toAddr, _outAmount);
        
        nonce = nonce.add(1);
        emit TransferOut(_user, _toAddr, _fchainId, _getChainID(), _token, _outAmount, _fnonce, nonce);
    }
    function transferOut(address _user, address _toAddr, uint256 _fchainId, uint256 _tchainId, address _token, uint256 _amount,uint256 _fnonce) external onlyAdmin {
        
        require(_tokenAdmin[_token] != address(0x0) || mainAsset[_token]>0, "wrong token to be bridged");
        if(_tokenAdmin[_token] != address(0x0))
        {
            _transferOut(_user, _toAddr, _fchainId, _tchainId, _token, _amount, _fnonce);
        }
        else if(mainAsset[_token]>0)
        {
            _transferMainOut(_user, _toAddr, _fchainId, _tchainId, _token, _amount, _fnonce);
        }
    }

    function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 _tokenBalance = _token.balanceOf(address(this));
        require(_amount <= _tokenBalance, "Not enough fund");
        _token.transfer(_to, _amount);
    }

    function claimFees(address _token) external onlyOwner {
        if(_token == address(0x0))
        {
            uint256 balance = address(this).balance;
            address(uint160(owner())).transfer(balance);
            emit ClaimedFee(owner(), balance);
            return;
        }
        IERC20 token = IERC20(_token);
        LiquidityInfo storage _platformInfo = platformLiquidity[_token];

        require(_platformInfo.feeInAmount > _platformInfo.feeOutAmount, "no need to claim");

        uint256 _amount = _platformInfo.feeInAmount.sub(_platformInfo.feeOutAmount);
        safeTransfer(token, owner(), _amount);

        _platformInfo.feeOutAmount = _platformInfo.feeInAmount; 
        emit ClaimedLiquidityFee(_token, owner(), _amount);
    }
    function claimLiquidityFees(address _token) external{
        require(mainAsset[_token]>0, "token is not main asset");
        LiquidityInfo storage _userInfo = liquidityTokenDepositInfo[_token][msg.sender];

        require(_userInfo.feeInAmount > _userInfo.feeOutAmount, "no need to claim");
        IERC20 token = IERC20(_token);
        uint256 _amount = _userInfo.feeInAmount.sub(_userInfo.feeOutAmount);

        safeTransfer(token, owner(), _amount);
        _userInfo.feeOutAmount = _userInfo.feeInAmount;
        emit ClaimedLiquidityFee(_token, msg.sender, _amount);
    }

    function setSwapRouter(address _router, address _wether) external onlyOwner
    {
        dex_router_contract = _router;
        wrapped_ether = _wether;
    }
    function swapIn(address _token, uint256 _amount, address _toAddr, uint256 _chainId) payable external 
    {
        require(msg.value>=userFee, "Wrong input Fee");
        require(mainAsset[_token]>0, "token is not main asset");
        require(_amount > 0, "wrong token amount");
        DepositInfo storage _tokenSwapInfo = tokenSwapInfo[_token];        
        // 转币
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);

        _tokenSwapInfo.inAmount = _tokenSwapInfo.inAmount.add(_amount);
        _tokenSwapInfo.inCount = _tokenSwapInfo.inCount.add(1);
        nonce = nonce.add(1);

        emit SwapIn(msg.sender, _toAddr, _getChainID(), _token, _chainId, _amount, nonce);   
    }
    function buyEther(address _user, address _toAddr, uint256 _fchainId, uint256 _tchainId, address _token, uint256 _amount,uint256 _fnonce) external onlyAdmin
    {
        require(_tchainId == _getChainID(), "wrong chain Id");
        require(mainAsset[_token]>0, "token is not main asset");
        IERC20 token = IERC20(_token);
        uint256 _tokenBalance = token.balanceOf(address(this));
        require(_tokenBalance > _amount, "Not enough asset to be swapped");

        uint256 _outAmount = updateLiquidityReward(_token, _amount);

        uint256 _outMin = getAmountOutMin(_token, wrapped_ether, _outAmount);
        swap(_token, wrapped_ether, _outAmount, _outMin, msg.sender);
        nonce = nonce.add(1);

        emit SwapOut(_user, _toAddr, _fchainId, _getChainID(), _token, _amount, _fnonce, nonce);
    }
    function sendEther(address _toAddr, uint256 _amount, uint256 _fchainId, uint256 _fnonce, uint256 buynonce) external onlyAdmin
    {
        uint256 balance = address(this).balance;
        require(balance > _amount, "Not enouth Ether");
        address(uint160(_toAddr)).transfer(_amount);
        emit SendEther(_toAddr, _amount, _fchainId, _fnonce, nonce);
    }
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) private {
      
        //first we need to transfer the amount in tokens from the msg.sender to this contract
        //this contract will have the amount of in tokens
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
        IERC20(_tokenIn).approve(dex_router_contract, _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == wrapped_ether || _tokenOut == wrapped_ether) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = wrapped_ether;
            path[2] = _tokenOut;
        }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(dex_router_contract).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
     function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) private view returns (uint256) {
       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == wrapped_ether || _tokenOut == wrapped_ether) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = wrapped_ether;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(dex_router_contract).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  
}