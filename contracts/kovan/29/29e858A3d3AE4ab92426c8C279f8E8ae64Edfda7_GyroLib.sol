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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./GyroRouter.sol";
import "./balancer/BPool.sol";
import "./Ownable.sol";

/**
 * @notice This contracts is a very simple router to deposit supported assets and
 * receive Balancer Pool Tokens depositable directly in the Gyro reserve in return
 */
contract BalancerExternalTokenRouter is GyroRouter, Ownable {
    mapping(address => address[]) public pools;
    address[] public tokens;

    event UnderlyingTokensDeposited(address[] indexed bpAddresses, uint256[] indexed bpAmounts);

    /**
     * @notice Deposits `_amountsIn` amounts of `_tokensIn` and receives Balancer Pool tokens
     * in return. `_amountsIn[i]` is the amount of `_tokensIn[i]` token to deposit.
     * @param _tokensIn the tokens to deposit
     * @param _amountsIn the amount to deposit for each token
     * @return the addresses and amounts of the Balancer Pool tokens received
     * The length of the output tokens will be equal to the length of the output tokens
     * and may contain duplicates
     */
    function deposit(address[] memory _tokensIn, uint256[] memory _amountsIn)
        external
        override
        returns (address[] memory, uint256[] memory)
    {
        address[] memory _bpAddresses = new address[](_tokensIn.length);
        uint256[] memory _bpAmounts = new uint256[](_amountsIn.length);

        for (uint256 i = 0; i < _tokensIn.length; i++) {
            address token = _tokensIn[i];
            uint256 amount = _amountsIn[i];
            bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
            require(success, "failed to transfer tokens from sender to GryoRouter");

            BPool pool = BPool(choosePoolToDeposit(token, amount));
            uint256 poolAmountOut = pool.joinswapExternAmountIn(token, amount, 0);
            success = pool.transfer(msg.sender, poolAmountOut);
            require(success, "failed to transfer BPT to sender");

            _bpAmounts[i] = poolAmountOut;
            _bpAddresses[i] = address(pool);
        }

        emit UnderlyingTokensDeposited(_bpAddresses, _bpAmounts);
        return (_bpAddresses, _bpAmounts);
    }

    /**
     * @notice Estimates how many Balancer Pool tokens would be received given
     * `_amountsIn` amounts of `_tokensIn`. See `deposit` for more information
     * @param _tokensIn the tokens to deposit
     * @param _amountsIn the amount to deposit for each token
     * @return the addresses and amounts of the Balancer Pool tokens that would be received
     */
    function estimateDeposit(address[] memory _tokensIn, uint256[] memory _amountsIn)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory _bpAddresses = new address[](_tokensIn.length);
        uint256[] memory _bpAmounts = new uint256[](_amountsIn.length);

        for (uint256 i = 0; i < _tokensIn.length; i++) {
            address token = _tokensIn[i];
            uint256 amount = _amountsIn[i];

            BPool pool = BPool(choosePoolToDeposit(token, amount));
            uint256 poolAmountOut = calcPoolOutGivenSingleIn(pool, token, amount);
            _bpAddresses[i] = address(pool);
            _bpAmounts[i] = poolAmountOut;
        }
        return (_bpAddresses, _bpAmounts);
    }

    /**
     * @notice Withdraws the underlying tokens using `_amountsOut` amounts of `_tokensOut` of underlying tokens.
     * The given tokens should be supported by this router
     * @param _tokensOut the tokens to receive
     * @param _amountsOut the amount to for each token
     * @return the addresses and amounts of the BP tokens used
     * The number of tokens returned will have the same length than the
     * number of pools given and may contain duplicates
     */
    function withdraw(address[] memory _tokensOut, uint256[] memory _amountsOut)
        external
        override
        returns (address[] memory, uint256[] memory)
    {
        address[] memory _bpAddresses = new address[](_tokensOut.length);
        uint256[] memory _bpAmounts = new uint256[](_amountsOut.length);
        for (uint256 i = 0; i < _tokensOut.length; i++) {
            address token = _tokensOut[i];
            uint256 amount = _amountsOut[i];
            BPool pool = BPool(choosePoolToWithdraw(token, amount));
            uint256 poolAmountIn = calcPoolInGivenSingleOut(pool, token, amount);

            bool success = pool.transferFrom(msg.sender, address(this), poolAmountIn);
            require(success, "failed to transfer BPT from sender to GryoRouter");

            pool.exitswapExternAmountOut(token, amount, poolAmountIn);

            success = IERC20(token).transfer(msg.sender, amount);
            require(success, "failed to transfer token to sender");

            _bpAddresses[i] = address(pool);
            _bpAmounts[i] = poolAmountIn;
        }
        return (_bpAddresses, _bpAmounts);
    }

    /**
     * @notice Estimates how many of the underlying tokens would be received given
     * `_amountsOut` amounts of `_tokensOut` of Balancer Pool tokens. See `withdraw` for more information
     * @param _tokensOut the Balancer Pool tokens to use
     * @param _amountsOut the amount to for each token
     * @return the addresses and amounts of the underlying tokens that would be received
     */
    function estimateWithdraw(address[] memory _tokensOut, uint256[] memory _amountsOut)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory _bpAddresses = new address[](_tokensOut.length);
        uint256[] memory _bpAmounts = new uint256[](_amountsOut.length);

        for (uint256 i = 0; i < _tokensOut.length; i++) {
            address token = _tokensOut[i];
            uint256 amount = _amountsOut[i];

            BPool pool = BPool(choosePoolToDeposit(token, amount));
            uint256 poolAmountIn = calcPoolInGivenSingleOut(pool, token, amount);
            _bpAddresses[i] = address(pool);
            _bpAmounts[i] = poolAmountIn;
        }
        return (_bpAddresses, _bpAmounts);
    }

    function calcPoolOutGivenSingleIn(
        BPool pool,
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 tokenBalanceIn = pool.getBalance(_token);
        uint256 tokenWeightIn = pool.getDenormalizedWeight(_token);
        uint256 poolSupply = pool.totalSupply();
        uint256 totalWeight = pool.getTotalDenormalizedWeight();
        uint256 swapFee = pool.getSwapFee();
        return
            pool.calcPoolOutGivenSingleIn(
                tokenBalanceIn,
                tokenWeightIn,
                poolSupply,
                totalWeight,
                _amount,
                swapFee
            );
    }

    function calcPoolInGivenSingleOut(
        BPool pool,
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 tokenBalanceOut = pool.getBalance(_token);
        uint256 tokenWeightOut = pool.getDenormalizedWeight(_token);
        uint256 poolSupply = pool.totalSupply();
        uint256 totalWeight = pool.getTotalDenormalizedWeight();
        uint256 swapFee = pool.getSwapFee();
        return
            pool.calcPoolInGivenSingleOut(
                tokenBalanceOut,
                tokenWeightOut,
                poolSupply,
                totalWeight,
                _amount,
                swapFee
            );
    }

    function choosePoolToDeposit(address _token, uint256 _amount) private view returns (address) {
        address[] storage candidates = pools[_token];
        require(candidates.length > 0, "token not supported");
        // TODO: choose better
        return candidates[_amount % candidates.length];
    }

    function choosePoolToWithdraw(address _token, uint256 _amount) private view returns (address) {
        address[] storage candidates = pools[_token];
        require(candidates.length > 0, "token not supported");
        // TODO: choose better
        return candidates[_amount % candidates.length];
    }

    function addPool(address _poolAddress) public onlyOwner {
        BPool pool = BPool(_poolAddress);
        require(pool.isFinalized(), "can only add finalized pools");
        address[] memory poolTokens = pool.getFinalTokens();
        for (uint256 i = 0; i < poolTokens.length; i++) {
            address tokenAddress = poolTokens[i];
            address[] storage currentPools = pools[tokenAddress];
            if (currentPools.length == 0) {
                tokens.push(tokenAddress);
            }
            bool exists = false;
            for (uint256 j = 0; j < currentPools.length; j++) {
                if (currentPools[j] == _poolAddress) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                currentPools.push(_poolAddress);
                IERC20(tokenAddress).approve(_poolAddress, uint256(-1));
            }
        }
    }

    function allTokens() external view returns (address[] memory) {
        address[] memory _tokens = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i];
        }
        return _tokens;
    }
}

contract BalancerTokenRouter is GyroRouter, Ownable {
    function deposit(address[] memory _tokensIn, uint256[] memory _amountsIn)
        external
        pure
        override
        returns (address[] memory, uint256[] memory)
    {
        return (_tokensIn, _amountsIn);
    }

    function withdraw(address[] memory _tokensOut, uint256[] memory _amountsOut)
        external
        pure
        override
        returns (address[] memory, uint256[] memory)
    {
        return (_tokensOut, _amountsOut);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./abdk/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @notice This contract contains math related utilities that allows to
 * compute fixed-point exponentiation or perform scaled arithmetic operations
 */
library ExtendedMath {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using SafeMath for uint256;

    uint256 constant decimals = 18;
    uint256 constant decimalScale = 10**decimals;

    /**
     * @notice Computes x**y where both `x` and `y` are fixed-point numbers
     */
    function powf(int128 _x, int128 _y) internal pure returns (int128 _xExpy) {
        // 2^(y * log2(x))
        return _y.mul(_x.log_2()).exp_2();
    }

    /**
     * @notice Computes `value * base ** exponent` where all of the parameters
     * are fixed point numbers scaled with `decimal`
     */
    function mulPow(
        uint256 value,
        uint256 base,
        uint256 exponent,
        uint256 decimal
    ) internal pure returns (uint256) {
        int128 basef = base.fromScaled(decimal);
        int128 expf = exponent.fromScaled(decimal);
        return powf(basef, expf).mulu(value);
    }

    /**
     * @notice Multiplies `a` and `b` scaling the result down by `_decimals`
     * `scaledMul(a, b, 18)` with an initial scale of 18 decimals for `a` and `b`
     * would keep the result to 18 decimals
     * The result of the computation is floored
     */
    function scaledMul(
        uint256 a,
        uint256 b,
        uint256 _decimals
    ) internal pure returns (uint256) {
        return a.mul(b).div(10**_decimals);
    }

    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return scaledMul(a, b, decimals);
    }

    /**
     * @notice Divides `a` and `b` scaling the result up by `_decimals`
     * `scaledDiv(a, b, 18)` with an initial scale of 18 decimals for `a` and `b`
     * would keep the result to 18 decimals
     * The result of the computation is floored
     */
    function scaledDiv(
        uint256 a,
        uint256 b,
        uint256 _decimals
    ) internal pure returns (uint256) {
        return a.mul(10**_decimals).div(b);
    }

    /**
     * @notice See `scaledDiv(uint256 a, uint256 b, uint256 _decimals)`
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return scaledDiv(a, b, decimals);
    }

    /**
     * @notice Computes a**b where a is a scaled fixed-point number and b is an integer
     * This keeps a scale of `_decimals` for `a`
     * The computation is performed in O(log n)
     */
    function scaledPow(
        uint256 base,
        uint256 exp,
        uint256 _decimals
    ) internal pure returns (uint256) {
        uint256 result = 10**_decimals;

        while (exp > 0) {
            if (exp % 2 == 1) {
                result = scaledMul(result, base, _decimals);
            }
            exp /= 2;
            base = scaledMul(base, base, _decimals);
        }
        return result;
    }

    /**
     * @notice See `scaledPow(uint256 base, uint256 exp, uint256 _decimals)`
     */
    function scaledPow(uint256 base, uint256 exp) internal pure returns (uint256) {
        return scaledPow(base, exp, decimals);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./GyroPriceOracle.sol";
import "./GyroRouter.sol";
import "./Ownable.sol";
import "./abdk/ABDKMath64x64.sol";

/**
 * GyroFund contains the public interface of the Gyroscope Reserve
 * Its main functionality include minting and redeeming Gyro dollars
 * using supported tokens, which are currently only Balancer Pool Tokens.
 * To mint and redeem against other type of assets, please see the `GyroLib` contract
 * which contains helpers and uses a basic router to do so.
 */
interface GyroFund is IERC20Upgradeable {
    event Mint(address indexed minter, uint256 indexed amount);
    event Redeem(address indexed redeemer, uint256 indexed amount);

    /**
     * Mints GYD in return for user-input tokens
     * @param _tokensIn = array of pool token addresses, in the same order as stored in the contract
     * @param _amountsIn = user-input pool token amounts, in same order as _tokensIn
     * @param _minGyroMinted = slippage parameter for min GYD to mint or else revert
     * Returns amount of GYD to mint and emits a Mint event
     */
    function mint(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted
    ) external returns (uint256);

    /**
     * Same as `mint` but the minted tokens are received by `_onBehalfOf`
     */
    function mintFor(
        address[] memory _BPTokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted,
        address _onBehalfOf
    ) external returns (uint256 amountToMint);

    /**
     * Redeems GYD in return for user-specified token amounts from the reserve
     * @param _BPTokensOut = array of pool token addresses, in the same order as stored in the contract
     * @param _amountsOut = user-specified pool token amounts to redeem for, in same order as _BPTokensOut
     * @param _maxGyroRedeemed = slippage parameter for max GYD to redeem or else revert
     * Returns amount of GYD to redeem and emits Redeem event
     */
    function redeem(
        address[] memory _BPTokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxGyroRedeemed
    ) external returns (uint256);

    /**
     * Takes in the same parameters as mint and returns whether the
     * mint will succeed or not as well as the estimated mint amount
     * @param _BPTokensIn addresses of the input balancer pool tokens
     * @param _amountsIn amounts of the input balancer pool tokens
     * @param _minGyroMinted mininum amount of gyro to mint
     * @return errorCode of 0 is no error happens or a value described in errors.json
     */
    function mintChecksPass(
        address[] memory _BPTokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted
    ) external view returns (uint256 errorCode, uint256 estimatedAmount);

    /**
     * Takes in the same parameters as redeem and returns whether the
     * redeem will succeed or not as well as the estimated redeem amount
     * @param _BPTokensOut = array of pool token addresses, in the same order as stored in the contract
     * @param _amountsOut = user-specified pool token amounts to redeem for, in same order as _BPTokensOut
     * @param _maxGyroRedeemed = slippage parameter for max GYD to redeem or else revert
     * @return errorCode of 0 is no error happens or a value described in errors.json
     */
    function redeemChecksPass(
        address[] memory _BPTokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxGyroRedeemed
    ) external view returns (uint256 errorCode, uint256 estimatedAmount);

    /**
     * Gets the current values in the reserve pools
     * @return errorCode of 0 is no error happens or a value described in errors.json
     * @return BPTokenAddresses = array of pool token addresses, in the right order
     * @return BPReserveDollarValues = dollar-value held by the reserve in each pool, in same order
     */
    function getReserveValues()
        external
        view
        returns (
            uint256 errorCode,
            address[] memory BPTokenAddresses,
            uint256[] memory BPReserveDollarValues
        );
}

/**
 * GyroFundV1 contains the logic for the Gyroscope Reserve
 * The storage of this contract should be empty, as the Gyroscope storage will be
 * held in the proxy contract.
 * GyroFundV1 contains the mint and redeem functions for GYD and interacts with the
 * GyroPriceOracle for the P-AMM functionality.
 */
contract GyroFundV1 is GyroFund, Ownable, ERC20Upgradeable {
    using ExtendedMath for int128;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using ExtendedMath for uint256;

    GyroPriceOracle public gyroPriceOracle;
    GyroRouter public gyroRouter;
    PriceOracle public priceOracle;

    struct TokenProperties {
        address oracleAddress;
        string tokenSymbol;
        uint16 tokenIndex;
    }

    struct PoolProperties {
        address poolAddress;
        uint256 initialPoolWeight;
        uint256 initialPoolPrice;
    }

    struct PoolStatus {
        bool _allPoolsHealthy;
        bool _allPoolsWithinEpsilon;
        bool[] _inputPoolHealth;
        bool[] _poolsWithinEpsilon;
    }

    struct Weights {
        uint256[] _idealWeights;
        uint256[] _currentWeights;
        uint256[] _hypotheticalWeights;
        uint256 _nav;
        uint256 _dollarValue;
        uint256 _totalPortfolioValue;
        uint256[] _zeroArray;
        uint256 gyroAmount;
    }

    struct FlowLogger {
        uint256 inflowHistory;
        uint256 outflowHistory;
        uint256 currentBlock;
        uint256 lastSeenBlock;
    }

    PoolProperties[] public poolProperties;

    mapping(address => TokenProperties) _tokenAddressToProperties;
    mapping(address => bool) _checkPoolIsValid;

    mapping(address => bool) _checkIsStablecoin;

    address[] underlyingTokenAddresses;

    uint256 public portfolioWeightEpsilon;
    uint256 lastSeenBlock;
    uint256 inflowHistory;
    uint256 outflowHistory;
    uint256 memoryParam;

    uint256 constant WOULD_UNBALANCE_GYROSCOPE = 1;
    uint256 constant TOO_MUCH_SLIPPAGE = 2;

    function initialize(
        uint256 _portfolioWeightEpsilon,
        address _priceOracleAddress,
        address _routerAddress,
        uint256 _memoryParam
    ) public initializer {
        __ERC20_init("Gyro Dollar", "GYD");
        gyroPriceOracle = GyroPriceOracle(_priceOracleAddress);
        gyroRouter = GyroRouter(_routerAddress);

        lastSeenBlock = block.number;
        memoryParam = _memoryParam;

        portfolioWeightEpsilon = _portfolioWeightEpsilon;
    }

    function addToken(
        address tokenAddress,
        address oracleAddress,
        bool isStable
    ) external onlyOwner {
        for (uint256 i = 0; i < underlyingTokenAddresses.length; i++) {
            require(underlyingTokenAddresses[i] != tokenAddress, "this token already exists");
        }

        _checkIsStablecoin[tokenAddress] = isStable;
        string memory tokenSymbol = ERC20(tokenAddress).symbol();
        _tokenAddressToProperties[tokenAddress] = TokenProperties({
            oracleAddress: oracleAddress,
            tokenSymbol: tokenSymbol,
            tokenIndex: uint16(underlyingTokenAddresses.length)
        });
        underlyingTokenAddresses.push(tokenAddress);
    }

    function addPool(address _bpoolAddress, uint256 _initialPoolWeight) external onlyOwner {
        // check we do not already have this pool
        for (uint256 i = 0; i < poolProperties.length; i++) {
            require(poolProperties[i].poolAddress != _bpoolAddress, "this pool already exists");
        }

        BPool _bPool = BPool(_bpoolAddress);
        _checkPoolIsValid[_bpoolAddress] = true;

        // get the addresses of the underlying tokens
        address[] memory _bPoolUnderlyingTokens = _bPool.getFinalTokens();

        // fill the underlying token prices array
        uint256[] memory _bPoolUnderlyingTokenPrices = new uint256[](_bPoolUnderlyingTokens.length);
        for (uint256 i = 0; i < _bPoolUnderlyingTokens.length; i++) {
            address tokenAddress = _bPoolUnderlyingTokens[i];
            string memory tokenSymbol = ERC20(tokenAddress).symbol();
            _bPoolUnderlyingTokenPrices[i] = getPrice(tokenAddress, tokenSymbol);
        }

        // Calculate BPT price for the pool
        uint256 initialPoolPrice =
            gyroPriceOracle.getBPTPrice(_bpoolAddress, _bPoolUnderlyingTokenPrices);

        poolProperties.push(
            PoolProperties({
                poolAddress: _bpoolAddress,
                initialPoolWeight: _initialPoolWeight,
                initialPoolPrice: initialPoolPrice
            })
        );
    }

    function calculateImpliedPoolWeights(uint256[] memory _BPTPrices)
        internal
        view
        returns (uint256[] memory)
    {
        // order of _BPTPrices must be same as order of poolProperties
        uint256[] memory _newWeights = new uint256[](_BPTPrices.length);
        uint256[] memory _weightedReturns = new uint256[](_BPTPrices.length);

        uint256[] memory _initPoolPrices = new uint256[](_BPTPrices.length);
        uint256[] memory _initWeights = new uint256[](_BPTPrices.length);

        for (uint256 i = 0; i < poolProperties.length; i++) {
            _initPoolPrices[i] = poolProperties[i].initialPoolPrice;
            _initWeights[i] = poolProperties[i].initialPoolWeight;
        }

        for (uint256 i = 0; i < _BPTPrices.length; i++) {
            _weightedReturns[i] = _BPTPrices[i].scaledDiv(_initPoolPrices[i]).scaledMul(
                _initWeights[i]
            );
        }

        uint256 _returnsSum = 0;
        for (uint256 i = 0; i < _BPTPrices.length; i++) {
            _returnsSum = _returnsSum.add(_weightedReturns[i]);
        }

        for (uint256 i = 0; i < _BPTPrices.length; i++) {
            _newWeights[i] = _weightedReturns[i].scaledDiv(_returnsSum);
        }

        return _newWeights;
    }

    function nav(uint256 _totalPortfolioValue) internal view returns (uint256 _nav) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            _nav = _totalPortfolioValue.scaledDiv(totalSupply());
        } else {
            _nav = 1e18;
        }

        return _nav;
    }

    function calculatePortfolioWeights(uint256[] memory _BPTAmounts, uint256[] memory _BPTPrices)
        internal
        pure
        returns (uint256[] memory, uint256)
    {
        uint256[] memory _weights = new uint256[](_BPTPrices.length);
        uint256 _totalPortfolioValue = 0;

        for (uint256 i = 0; i < _BPTAmounts.length; i++) {
            _totalPortfolioValue = _totalPortfolioValue.add(
                _BPTAmounts[i].scaledMul(_BPTPrices[i])
            );
        }

        if (_totalPortfolioValue == 0) {
            return (_weights, _totalPortfolioValue);
        }

        for (uint256 i = 0; i < _BPTAmounts.length; i++) {
            _weights[i] = _BPTAmounts[i].scaledMul(_BPTPrices[i]).scaledDiv(_totalPortfolioValue);
        }

        return (_weights, _totalPortfolioValue);
    }

    function checkStablecoinHealth(uint256 stablecoinPrice, address stablecoinAddress)
        internal
        view
        returns (bool)
    {
        // TODO: revisit
        //Price
        bool _stablecoinHealthy = true;

        uint256 decimals = ERC20(stablecoinAddress).decimals();

        uint256 maxDeviation = 5 * 10**(decimals - 2);
        uint256 idealPrice = 10**decimals;

        if (stablecoinPrice >= idealPrice + maxDeviation) {
            _stablecoinHealthy = false;
        } else if (stablecoinPrice <= idealPrice - maxDeviation) {
            _stablecoinHealthy = false;
        }

        //Volume (to do)

        return _stablecoinHealthy;
    }

    function absValueSub(uint256 _number1, uint256 _number2) internal pure returns (uint256) {
        if (_number1 >= _number2) {
            return _number1.sub(_number2);
        } else {
            return _number2.sub(_number1);
        }
    }

    function getPrice(address _token, string memory _tokenSymbol) internal view returns (uint256) {
        return PriceOracle(_tokenAddressToProperties[_token].oracleAddress).getPrice(_tokenSymbol);
    }

    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function getAllTokenPrices() public view returns (uint256[] memory) {
        uint256[] memory _allUnderlyingPrices = new uint256[](underlyingTokenAddresses.length);
        for (uint256 i = 0; i < underlyingTokenAddresses.length; i++) {
            address _tokenAddress = underlyingTokenAddresses[i];
            string memory _tokenSymbol =
                _tokenAddressToProperties[underlyingTokenAddresses[i]].tokenSymbol;
            uint256 _tokenPrice = getPrice(_tokenAddress, _tokenSymbol);
            _allUnderlyingPrices[i] = _tokenPrice;
        }
        return _allUnderlyingPrices;
    }

    function mintTest(address[] memory _BPTokensIn, uint256[] memory _amountsIn)
        public
        onlyOwner
        returns (uint256)
    {
        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            bool success =
                ERC20(_BPTokensIn[i]).transferFrom(msg.sender, address(this), _amountsIn[i]);
            require(success, "failed to transfer tokens, check allowance");
        }
        uint256[] memory _allUnderlyingPrices = getAllTokenPrices();
        uint256[] memory _currentBPTPrices = calculateAllPoolPrices(_allUnderlyingPrices);
        uint256 _dollarValue = 0;

        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            _dollarValue = _dollarValue.add(_amountsIn[i].scaledMul(_currentBPTPrices[i]));
        }

        uint256 _gyroToMint = gyroPriceOracle.getAmountToMint(_dollarValue, 0, 1e18);

        _mint(msg.sender, _gyroToMint);
        return _gyroToMint;
    }

    function calculateAllPoolPrices(uint256[] memory _allUnderlyingPrices)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _currentBPTPrices = new uint256[](poolProperties.length);

        // Calculate BPT prices for all pools
        for (uint256 i = 0; i < poolProperties.length; i++) {
            BPool _bPool = BPool(poolProperties[i].poolAddress);

            address[] memory _bPoolUnderlyingTokens = _bPool.getFinalTokens();

            //For each pool fill the underlying token prices array
            uint256[] memory _bPoolUnderlyingTokenPrices =
                new uint256[](underlyingTokenAddresses.length);
            for (uint256 j = 0; j < _bPoolUnderlyingTokens.length; j++) {
                _bPoolUnderlyingTokenPrices[j] = _allUnderlyingPrices[
                    _tokenAddressToProperties[_bPoolUnderlyingTokens[j]].tokenIndex
                ];
            }

            // Calculate BPT price for the pool
            _currentBPTPrices[i] = gyroPriceOracle.getBPTPrice(
                poolProperties[i].poolAddress,
                _bPoolUnderlyingTokenPrices
            );
        }

        return _currentBPTPrices;
    }

    function poolHealthHelper(uint256[] memory _allUnderlyingPrices, uint256 _poolIndex)
        internal
        view
        returns (bool)
    {
        bool _poolHealthy = true;

        BPool _bPool = BPool(poolProperties[_poolIndex].poolAddress);
        address[] memory _bPoolUnderlyingTokens = _bPool.getFinalTokens();

        //Go through the underlying tokens within the pool
        for (uint256 j = 0; j < _bPoolUnderlyingTokens.length; j++) {
            if (_checkIsStablecoin[_bPoolUnderlyingTokens[j]]) {
                uint256 _stablecoinPrice =
                    _allUnderlyingPrices[
                        _tokenAddressToProperties[_bPoolUnderlyingTokens[j]].tokenIndex
                    ];

                if (!checkStablecoinHealth(_stablecoinPrice, _bPoolUnderlyingTokens[j])) {
                    _poolHealthy = false;
                    break;
                }
            }
        }

        return _poolHealthy;
    }

    function checkPoolsWithinEpsilon(
        address[] memory _BPTokensIn,
        uint256[] memory _hypotheticalWeights,
        uint256[] memory _idealWeights
    ) internal view returns (bool, bool[] memory) {
        bool _allPoolsWithinEpsilon = true;
        bool[] memory _poolsWithinEpsilon = new bool[](_BPTokensIn.length);

        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            // Check 1: check whether hypothetical weight will be within epsilon
            _poolsWithinEpsilon[i] = true;
            if (_hypotheticalWeights[i] >= _idealWeights[i].add(portfolioWeightEpsilon)) {
                _allPoolsWithinEpsilon = false;
                _poolsWithinEpsilon[i] = false;
            } else if (_hypotheticalWeights[i].add(portfolioWeightEpsilon) <= _idealWeights[i]) {
                _allPoolsWithinEpsilon = false;
                _poolsWithinEpsilon[i] = false;
            }
        }

        return (_allPoolsWithinEpsilon, _poolsWithinEpsilon);
    }

    function checkAllPoolsHealthy(
        address[] memory _BPTokensIn,
        uint256[] memory _hypotheticalWeights,
        uint256[] memory _idealWeights,
        uint256[] memory _allUnderlyingPrices
    )
        internal
        view
        returns (
            bool,
            bool,
            bool[] memory,
            bool[] memory
        )
    {
        // Check safety of input tokens
        bool _allPoolsWithinEpsilon;
        bool[] memory _poolsWithinEpsilon = new bool[](_BPTokensIn.length);
        bool[] memory _inputPoolHealth = new bool[](_BPTokensIn.length);
        bool _allPoolsHealthy = true;

        (_allPoolsWithinEpsilon, _poolsWithinEpsilon) = checkPoolsWithinEpsilon(
            _BPTokensIn,
            _hypotheticalWeights,
            _idealWeights
        );

        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            _inputPoolHealth[i] = poolHealthHelper(_allUnderlyingPrices, i);
            _allPoolsHealthy = _allPoolsHealthy && _inputPoolHealth[i];
        }

        return (_allPoolsHealthy, _allPoolsWithinEpsilon, _inputPoolHealth, _poolsWithinEpsilon);
    }

    function safeToMintOutsideEpsilon(
        address[] memory _BPTokensIn,
        bool[] memory _inputPoolHealth,
        uint256[] memory _inputBPTWeights,
        uint256[] memory _idealWeights,
        uint256[] memory _hypotheticalWeights,
        uint256[] memory _currentWeights,
        bool[] memory _poolsWithinEpsilon
    ) internal pure returns (bool _anyCheckFail) {
        //Check that amount above epsilon is decreasing
        //Check that unhealthy pools have input weight below ideal weight
        //If both true, then mint
        //note: should always be able to mint at the ideal weights!
        _anyCheckFail = false;
        for (uint256 i; i < _BPTokensIn.length; i++) {
            if (!_inputPoolHealth[i]) {
                if (_inputBPTWeights[i] > _idealWeights[i]) {
                    _anyCheckFail = true;
                    break;
                }
            }

            if (!_poolsWithinEpsilon[i]) {
                // check if _hypotheticalWeights[i] is closer to _idealWeights[i] than _currentWeights[i]
                uint256 _distanceHypotheticalToIdeal =
                    absValueSub(_hypotheticalWeights[i], _idealWeights[i]);
                uint256 _distanceCurrentToIdeal = absValueSub(_currentWeights[i], _idealWeights[i]);

                if (_distanceHypotheticalToIdeal >= _distanceCurrentToIdeal) {
                    _anyCheckFail = true;
                    break;
                }
            }
        }

        if (!_anyCheckFail) {
            return true;
        }
    }

    function checkBPTokenOrder(address[] memory _BPTokensIn) internal view returns (bool _correct) {
        require(
            _BPTokensIn.length == poolProperties.length,
            "bptokens do not have the correct number of addreses"
        );
        _correct = true;

        for (uint256 i = 0; i < poolProperties.length; i++) {
            if (poolProperties[i].poolAddress != _BPTokensIn[i]) {
                _correct = false;
                break;
            }
        }

        return _correct;
    }

    function checkUnhealthyMovesToIdeal(
        address[] memory _BPTokensIn,
        bool[] memory _inputPoolHealth,
        uint256[] memory _inputBPTWeights,
        uint256[] memory _idealWeights
    ) internal pure returns (bool _launch) {
        bool _unhealthyMovesTowardIdeal = true;
        for (uint256 i; i < _BPTokensIn.length; i++) {
            if (!_inputPoolHealth[i]) {
                if (_inputBPTWeights[i] > _idealWeights[i]) {
                    _unhealthyMovesTowardIdeal = false;
                    break;
                }
            }
        }

        if (_unhealthyMovesTowardIdeal) {
            _launch = true;
        }
    }

    function safeToMint(
        address[] memory _BPTokensIn,
        uint256[] memory _hypotheticalWeights,
        uint256[] memory _idealWeights,
        uint256[] memory _allUnderlyingPrices,
        uint256[] memory _amountsIn,
        uint256[] memory _currentBPTPrices,
        uint256[] memory _currentWeights
    ) internal view returns (bool _launch) {
        _launch = false;

        PoolStatus memory poolStatus;

        (
            poolStatus._allPoolsHealthy,
            poolStatus._allPoolsWithinEpsilon,
            poolStatus._inputPoolHealth,
            poolStatus._poolsWithinEpsilon
        ) = checkAllPoolsHealthy(
            _BPTokensIn,
            _hypotheticalWeights,
            _idealWeights,
            _allUnderlyingPrices
        );

        // if check 1 succeeds and all pools healthy, then proceed with minting
        if (poolStatus._allPoolsHealthy) {
            if (poolStatus._allPoolsWithinEpsilon) {
                _launch = true;
            }
        } else {
            // calculate proportional values of assets user wants to pay with
            (uint256[] memory _inputBPTWeights, uint256 _totalPortfolioValue) =
                calculatePortfolioWeights(_amountsIn, _currentBPTPrices);
            if (_totalPortfolioValue == 0) {
                _inputBPTWeights = _idealWeights;
            }

            //Check that unhealthy pools have input weight below ideal weight. If true, mint
            if (poolStatus._allPoolsWithinEpsilon) {
                _launch = checkUnhealthyMovesToIdeal(
                    _BPTokensIn,
                    poolStatus._inputPoolHealth,
                    _inputBPTWeights,
                    _idealWeights
                );
            }
            //Outside of the epsilon boundary
            else {
                _launch = safeToMintOutsideEpsilon(
                    _BPTokensIn,
                    poolStatus._inputPoolHealth,
                    _inputBPTWeights,
                    _idealWeights,
                    _hypotheticalWeights,
                    _currentWeights,
                    poolStatus._poolsWithinEpsilon
                );
            }
        }

        return _launch;
    }

    function safeToRedeem(
        address[] memory _BPTokensOut,
        uint256[] memory _hypotheticalWeights,
        uint256[] memory _idealWeights,
        uint256[] memory _currentWeights
    ) internal view returns (bool) {
        bool _launch = false;
        bool _allPoolsWithinEpsilon;
        bool[] memory _poolsWithinEpsilon = new bool[](_BPTokensOut.length);

        (_allPoolsWithinEpsilon, _poolsWithinEpsilon) = checkPoolsWithinEpsilon(
            _BPTokensOut,
            _hypotheticalWeights,
            _idealWeights
        );
        if (_allPoolsWithinEpsilon) {
            _launch = true;
            return _launch;
        }

        // check if weights that are beyond epsilon boundary are closer to ideal than current weights
        bool _checkFail = false;
        for (uint256 i; i < _BPTokensOut.length; i++) {
            if (!_poolsWithinEpsilon[i]) {
                // check if _hypotheticalWeights[i] is closer to _idealWeights[i] than _currentWeights[i]
                uint256 _distanceHypotheticalToIdeal =
                    absValueSub(_hypotheticalWeights[i], _idealWeights[i]);
                uint256 _distanceCurrentToIdeal = absValueSub(_currentWeights[i], _idealWeights[i]);

                if (_distanceHypotheticalToIdeal >= _distanceCurrentToIdeal) {
                    _checkFail = true;
                    break;
                }
            }
        }

        if (!_checkFail) {
            _launch = true;
        }

        return _launch;
    }

    function calculateAllWeights(
        uint256[] memory _currentBPTPrices,
        address[] memory _BPTokens,
        uint256[] memory _amountsIn,
        uint256[] memory _amountsOut
    )
        internal
        view
        returns (
            uint256[] memory _idealWeights,
            uint256[] memory _currentWeights,
            uint256[] memory _hypotheticalWeights,
            uint256 _nav,
            uint256 _totalPortfolioValue
        )
    {
        //Calculate the up to date ideal portfolio weights
        _idealWeights = calculateImpliedPoolWeights(_currentBPTPrices);

        //Calculate the hypothetical weights if the new BPT tokens were added
        uint256[] memory _BPTNewAmounts = new uint256[](_BPTokens.length);
        uint256[] memory _BPTCurrentAmounts = new uint256[](_BPTokens.length);

        for (uint256 i = 0; i < _BPTokens.length; i++) {
            BPool _bPool = BPool(_BPTokens[i]);
            _BPTCurrentAmounts[i] = _bPool.balanceOf(address(this));
            _BPTNewAmounts[i] = _BPTCurrentAmounts[i].add(_amountsIn[i]).sub(_amountsOut[i]);
        }

        (_currentWeights, _totalPortfolioValue) = calculatePortfolioWeights(
            _BPTCurrentAmounts,
            _currentBPTPrices
        );
        if (_totalPortfolioValue == 0) {
            _currentWeights = _idealWeights;
        }

        _nav = nav(_totalPortfolioValue);

        (_hypotheticalWeights, ) = calculatePortfolioWeights(_BPTNewAmounts, _currentBPTPrices);

        return (_idealWeights, _currentWeights, _hypotheticalWeights, _nav, _totalPortfolioValue);
    }

    //_amountsIn in should have a zero index if nothing has been submitted for a particular token
    // _BPTokensIn and _amountsIn should have same indexes as poolProperties
    function mint(
        address[] memory _BPTokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted
    ) public override returns (uint256 amountToMint) {
        return mintFor(_BPTokensIn, _amountsIn, _minGyroMinted, msg.sender);
    }

    function mintFor(
        address[] memory _BPTokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted,
        address _onBehalfOf
    ) public override returns (uint256 amountToMint) {
        (uint256 errorCode, Weights memory weights, FlowLogger memory flowLogger) =
            mintChecksPassInternal(_BPTokensIn, _amountsIn, _minGyroMinted);
        require(errorCode == 0, errorCodeToString(errorCode));

        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            bool success =
                ERC20(_BPTokensIn[i]).transferFrom(msg.sender, address(this), _amountsIn[i]);
            require(success, "failed to transfer tokens, check allowance");
        }

        amountToMint = weights.gyroAmount;

        _mint(_onBehalfOf, amountToMint);

        finalizeFlowLogger(
            flowLogger.inflowHistory,
            flowLogger.outflowHistory,
            weights.gyroAmount,
            0,
            flowLogger.currentBlock,
            flowLogger.lastSeenBlock
        );

        emit Mint(_onBehalfOf, amountToMint);

        return amountToMint;
    }

    function mintChecksPass(
        address[] memory _BPTokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted
    ) public view override returns (uint256 errorCode, uint256 estimatedMint) {
        (uint256 _errorCode, Weights memory weights, ) =
            mintChecksPassInternal(_BPTokensIn, _amountsIn, _minGyroMinted);

        return (_errorCode, weights.gyroAmount);
    }

    function getReserveValues()
        public
        view
        override
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        address[] memory _BPTokens = new address[](poolProperties.length);
        uint256[] memory _zeroAmounts = new uint256[](poolProperties.length);
        for (uint256 i = 0; i < poolProperties.length; i++) {
            _BPTokens[i] = poolProperties[i].poolAddress;
        }

        (uint256 _errorCode, Weights memory weights, ) =
            mintChecksPassInternal(_BPTokens, _zeroAmounts, uint256(0));

        uint256[] memory _BPReserveDollarValues = new uint256[](_BPTokens.length);

        for (uint256 i = 0; i < _BPTokens.length; i++) {
            _BPReserveDollarValues[i] = weights._currentWeights[i].scaledMul(
                weights._totalPortfolioValue
            );
        }

        return (_errorCode, _BPTokens, _BPReserveDollarValues);
    }

    function mintChecksPassInternal(
        address[] memory _BPTokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted
    )
        internal
        view
        returns (
            uint256 errorCode,
            Weights memory weights,
            FlowLogger memory flowLogger
        )
    {
        require(
            _BPTokensIn.length == _amountsIn.length,
            "tokensIn and valuesIn should have the same number of elements"
        );

        //Filter 1: Require that the tokens are supported and in correct order
        bool _orderCorrect = checkBPTokenOrder(_BPTokensIn);
        require(_orderCorrect, "Input tokens in wrong order or contains invalid tokens");

        uint256[] memory _allUnderlyingPrices = getAllTokenPrices();

        uint256[] memory _currentBPTPrices = calculateAllPoolPrices(_allUnderlyingPrices);

        weights._zeroArray = new uint256[](_BPTokensIn.length);
        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            weights._zeroArray[i] = 0;
        }

        (
            weights._idealWeights,
            weights._currentWeights,
            weights._hypotheticalWeights,
            weights._nav,
            weights._totalPortfolioValue
        ) = calculateAllWeights(_currentBPTPrices, _BPTokensIn, _amountsIn, weights._zeroArray);

        bool _safeToMint =
            safeToMint(
                _BPTokensIn,
                weights._hypotheticalWeights,
                weights._idealWeights,
                _allUnderlyingPrices,
                _amountsIn,
                _currentBPTPrices,
                weights._currentWeights
            );

        if (!_safeToMint) {
            errorCode |= WOULD_UNBALANCE_GYROSCOPE;
        }

        weights._dollarValue = 0;

        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            weights._dollarValue = weights._dollarValue.add(
                _amountsIn[i].scaledMul(_currentBPTPrices[i])
            );
        }

        flowLogger = initializeFlowLogger();

        weights.gyroAmount = gyroPriceOracle.getAmountToMint(
            weights._dollarValue,
            flowLogger.inflowHistory,
            weights._nav
        );

        if (weights.gyroAmount < _minGyroMinted) {
            errorCode |= TOO_MUCH_SLIPPAGE;
        }

        return (errorCode, weights, flowLogger);
    }

    function redeemChecksPass(
        address[] memory _BPTokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxGyroRedeemed
    ) public view override returns (uint256 errorCode, uint256 estimatedAmount) {
        (uint256 _errorCode, Weights memory weights, ) =
            redeemChecksPassInternal(_BPTokensOut, _amountsOut, _maxGyroRedeemed);
        return (_errorCode, weights.gyroAmount);
    }

    function redeemChecksPassInternal(
        address[] memory _BPTokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxGyroRedeemed
    )
        internal
        view
        returns (
            uint256 errorCode,
            Weights memory weights,
            FlowLogger memory flowLogger
        )
    {
        require(
            _BPTokensOut.length == _amountsOut.length,
            "tokensIn and valuesIn should have the same number of elements"
        );

        //Filter 1: Require that the tokens are supported and in correct order
        require(
            checkBPTokenOrder(_BPTokensOut),
            "Input tokens in wrong order or contains invalid tokens"
        );

        weights._zeroArray = new uint256[](_BPTokensOut.length);
        for (uint256 i = 0; i < _BPTokensOut.length; i++) {
            weights._zeroArray[i] = 0;
        }

        uint256[] memory _allUnderlyingPrices = getAllTokenPrices();

        uint256[] memory _currentBPTPrices = calculateAllPoolPrices(_allUnderlyingPrices);

        (
            weights._idealWeights,
            weights._currentWeights,
            weights._hypotheticalWeights,
            weights._nav,
            weights._totalPortfolioValue
        ) = calculateAllWeights(_currentBPTPrices, _BPTokensOut, weights._zeroArray, _amountsOut);

        bool _safeToRedeem =
            safeToRedeem(
                _BPTokensOut,
                weights._hypotheticalWeights,
                weights._idealWeights,
                weights._currentWeights
            );

        if (!_safeToRedeem) {
            errorCode |= WOULD_UNBALANCE_GYROSCOPE;
        }

        weights._dollarValue = 0;

        for (uint256 i = 0; i < _BPTokensOut.length; i++) {
            weights._dollarValue = weights._dollarValue.add(
                _amountsOut[i].scaledMul(_currentBPTPrices[i])
            );
        }

        flowLogger = initializeFlowLogger();

        weights.gyroAmount = gyroPriceOracle.getAmountToRedeem(
            weights._dollarValue,
            flowLogger.outflowHistory,
            weights._nav
        );

        if (weights.gyroAmount > _maxGyroRedeemed) {
            errorCode |= TOO_MUCH_SLIPPAGE;
        }

        return (errorCode, weights, flowLogger);
    }

    function redeem(
        address[] memory _BPTokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxGyroRedeemed
    ) public override returns (uint256 _gyroRedeemed) {
        (uint256 errorCode, Weights memory weights, FlowLogger memory flowLogger) =
            redeemChecksPassInternal(_BPTokensOut, _amountsOut, _maxGyroRedeemed);
        require(errorCode == 0, errorCodeToString(errorCode));

        _gyroRedeemed = weights.gyroAmount;

        _burn(msg.sender, _gyroRedeemed);

        gyroRouter.withdraw(_BPTokensOut, _amountsOut);

        for (uint256 i = 0; i < _amountsOut.length; i++) {
            bool success =
                ERC20(_BPTokensOut[i]).transferFrom(address(this), msg.sender, _amountsOut[i]);
            require(success, "failed to transfer tokens");
        }

        emit Redeem(msg.sender, _gyroRedeemed);
        finalizeFlowLogger(
            flowLogger.inflowHistory,
            flowLogger.outflowHistory,
            0,
            _gyroRedeemed,
            flowLogger.currentBlock,
            flowLogger.lastSeenBlock
        );
        return _gyroRedeemed;
    }

    function initializeFlowLogger() internal view returns (FlowLogger memory flowLogger) {
        flowLogger.lastSeenBlock = lastSeenBlock;
        flowLogger.currentBlock = block.number;
        flowLogger.inflowHistory = inflowHistory;
        flowLogger.outflowHistory = outflowHistory;

        uint256 _memoryParam = memoryParam;

        if (flowLogger.lastSeenBlock < flowLogger.currentBlock) {
            flowLogger.inflowHistory = flowLogger.inflowHistory.scaledMul(
                _memoryParam.scaledPow(flowLogger.currentBlock.sub(flowLogger.lastSeenBlock))
            );
            flowLogger.outflowHistory = flowLogger.outflowHistory.scaledMul(
                _memoryParam.scaledPow(flowLogger.currentBlock.sub(flowLogger.lastSeenBlock))
            );
        }

        return flowLogger;
    }

    function finalizeFlowLogger(
        uint256 _inflowHistory,
        uint256 _outflowHistory,
        uint256 _gyroMinted,
        uint256 _gyroRedeemed,
        uint256 _currentBlock,
        uint256 _lastSeenBlock
    ) internal {
        if (_gyroMinted > 0) {
            inflowHistory = _inflowHistory.add(_gyroMinted);
        }
        if (_gyroRedeemed > 0) {
            outflowHistory = _outflowHistory.add(_gyroRedeemed);
        }
        if (_lastSeenBlock < _currentBlock) {
            lastSeenBlock = _currentBlock;
        }
    }

    function poolAddresses() public view returns (address[] memory) {
        address[] memory _addresses = new address[](poolProperties.length);
        for (uint256 i = 0; i < poolProperties.length; i++) {
            _addresses[i] = poolProperties[i].poolAddress;
        }
        return _addresses;
    }

    function getUnderlyingTokenAddresses() external view returns (address[] memory) {
        address[] memory _addresses = new address[](underlyingTokenAddresses.length);
        for (uint256 i = 0; i < underlyingTokenAddresses.length; i++) {
            _addresses[i] = underlyingTokenAddresses[i];
        }
        return _addresses;
    }

    function errorCodeToString(uint256 errorCode) public pure returns (string memory) {
        if ((errorCode & WOULD_UNBALANCE_GYROSCOPE) != 0) {
            return "ERR_WOULD_UNBALANCE_GYROSCOPE";
        } else if ((errorCode & TOO_MUCH_SLIPPAGE) != 0) {
            return "ERR_TOO_MUCH_SLIPPAGE";
        } else {
            return "ERR_UNKNOWN";
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./BalancerGyroRouter.sol";
import "./GyroFund.sol";
import "./Ownable.sol";

/**
 * @notice GyroLib is a contract used to add functionality around the GyroFund
 * to allow users to exchange assets for Gyro rather than having
 * to use already minted Balancer Pool Tokens
 */
contract GyroLib is Ownable {
    event Mint(address indexed minter, uint256 indexed amount);
    event Redeem(address indexed redeemer, uint256 indexed amount);

    GyroFundV1 public fund;
    BalancerExternalTokenRouter public externalTokensRouter;

    constructor(address gyroFundAddress, address externalTokensRouterAddress) {
        fund = GyroFundV1(gyroFundAddress);
        externalTokensRouter = BalancerExternalTokenRouter(externalTokensRouterAddress);
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fund = GyroFundV1(_fundAddress);
    }

    function setRouterAddress(address _routerAddress) external onlyOwner {
        externalTokensRouter = BalancerExternalTokenRouter(_routerAddress);
    }

    /**
     * @notice Mints at least `_minAmountOut` Gyro dollars by using the tokens and amounts
     * passed in `_tokensIn` and `_amountsIn`. `_tokensIn` and `_amountsIn` must
     * be the same length and `_amountsIn[i]` is the amount of `_tokensIn[i]` to
     * use to mint Gyro dollars.
     * This contract should be approved to spend at least the amount given
     * for each token of `_tokensIn`
     *
     * @param _tokensIn a list of tokens to use to mint Gyro dollars
     * @param _amountsIn the amount of each token to use
     * @param _minAmountOut the minimum number of Gyro dollars wanted, used to prevent against slippage
     * @return the amount of Gyro dollars minted
     */
    function mintFromUnderlyingTokens(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256 _minAmountOut
    ) public returns (uint256) {
        for (uint256 i = 0; i < _tokensIn.length; i++) {
            bool success =
                IERC20(_tokensIn[i]).transferFrom(msg.sender, address(this), _amountsIn[i]);
            require(success, "failed to transfer tokens from GyroFund to GryoRouter");
            IERC20(_tokensIn[i]).approve(address(externalTokensRouter), _amountsIn[i]);
        }
        (address[] memory bptTokens, uint256[] memory amounts) =
            externalTokensRouter.deposit(_tokensIn, _amountsIn);

        (address[] memory sortedAddresses, uint256[] memory sortedAmounts) =
            sortBPTokenstoPools(bptTokens, amounts);

        for (uint256 i = 0; i < sortedAddresses.length; i++) {
            IERC20(sortedAddresses[i]).approve(address(fund), sortedAmounts[i]);
        }

        uint256 minted = fund.mint(sortedAddresses, sortedAmounts, _minAmountOut);
        require(fund.transfer(msg.sender, minted), "failed to send back gyro");
        emit Mint(msg.sender, minted);
        return minted;
    }

    /**
     * @notice Redeems at most `_maxRedeemed` to receive exactly `_amountsOut[i]`
     * of each `_tokensOut[i]`.
     * `_tokensOut[i]` and  `_amountsOut[i]` must be the same length and `_amountsOut[i]`
     * is the amount desired of `_tokensOut[i]`
     * This contract should be allowed to spend the amount of Gyro dollars redeemed
     * which is at most `_maxRedeemed`
     *
     * @param _tokensOut the tokens to receive in exchange for redeeming Gyro dollars
     * @param _amountsOut the amount of each token to receive
     * @param _maxRedeemed the maximum number of Gyro dollars to redeem
     * @return the amount of Gyro dollar redeemed
     */
    function redeemToUnderlyingTokens(
        address[] memory _tokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxRedeemed
    ) public returns (uint256) {
        (address[] memory _BPTokensIn, uint256[] memory _BPAmountsIn) =
            externalTokensRouter.estimateWithdraw(_tokensOut, _amountsOut);

        (address[] memory _sortedAddresses, uint256[] memory _sortedAmounts) =
            sortBPTokenstoPools(_BPTokensIn, _BPAmountsIn);

        (uint256 errorCode, uint256 _amountToRedeem) =
            fund.redeemChecksPass(_sortedAddresses, _sortedAmounts, _maxRedeemed);

        require(errorCode == 0, fund.errorCodeToString(errorCode));
        require(_amountToRedeem <= _maxRedeemed, "too much slippage");

        require(
            fund.transferFrom(msg.sender, address(this), _amountToRedeem),
            "failed to send gyro to lib"
        );

        uint256 _amountRedeemed = fund.redeem(_sortedAddresses, _sortedAmounts, _maxRedeemed);

        for (uint256 i = 0; i < _sortedAddresses.length; i++) {
            require(
                IERC20(_sortedAddresses[i]).approve(
                    address(externalTokensRouter),
                    _sortedAmounts[i]
                ),
                "failed to approve BPTokens"
            );
        }

        externalTokensRouter.withdraw(_tokensOut, _amountsOut);

        for (uint256 i = 0; i < _tokensOut.length; i++) {
            IERC20(_tokensOut[i]).transfer(msg.sender, _amountsOut[i]);
        }

        emit Redeem(msg.sender, _amountRedeemed);
        return _amountRedeemed;
    }

    /**
     * @notice This functions approximates how many Gyro dollars would be minted given
     * `_tokensIn` and `_amountsIn`. See the documentation of `mintFromUnderlyingTokens`
     * for more details about these parameters
     * @param _tokensIn the tokens to use for minting
     * @param _amountsIn the amount of each token to use
     * @return the estimated amount of Gyro dolars minted
     */
    function estimateMintedGyro(address[] memory _tokensIn, uint256[] memory _amountsIn)
        public
        view
        returns (uint256)
    {
        (address[] memory bptTokens, uint256[] memory amounts) =
            externalTokensRouter.estimateDeposit(_tokensIn, _amountsIn);

        (address[] memory _sortedAddresses, uint256[] memory _sortedAmounts) =
            sortBPTokenstoPools(bptTokens, amounts);

        (, uint256 _amountToMint) = fund.mintChecksPass(_sortedAddresses, _sortedAmounts, 10);

        return _amountToMint;
    }

    /**
     * @notice This functions approximates how many Gyro dollars would be redeemed given
     * `_tokensOut` and `_amountsOut`. See the documentation of `redeemToUnderlyingTokens`
     * for more details about these parameters
     * @param _tokensOut the tokens receive back
     * @param _amountsOut the amount of each token to receive
     * @return the estimated amount of Gyro dolars redeemed
     */
    function estimateRedeemedGyro(address[] memory _tokensOut, uint256[] memory _amountsOut)
        public
        view
        returns (uint256)
    {
        (address[] memory bptTokens, uint256[] memory amounts) =
            externalTokensRouter.estimateWithdraw(_tokensOut, _amountsOut);

        (address[] memory _sortedAddresses, uint256[] memory _sortedAmounts) =
            sortBPTokenstoPools(bptTokens, amounts);

        (, uint256 _amountToRedeem) = fund.redeemChecksPass(_sortedAddresses, _sortedAmounts, 10);

        return _amountToRedeem;
    }

    /**
     * @notice Checks if a call to `mintFromUnderlyingTokens` with the given
     * `_tokensIn`, `_amountsIn and `_minGyroMinted` would succeed or not,
     * and returns the potential error code
     * @param _tokensIn a list of tokens to use to mint Gyro dollars
     * @param _amountsIn the amount of each token to use
     * @param _minGyroMinted the minimum number of Gyro dollars wanted
     * @return an error code if the call would fail, otherwise 0
     * See GyroFundV1 for the meaning of each error code
     */
    function wouldMintChecksPass(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256 _minGyroMinted
    ) public view returns (uint256) {
        (address[] memory bptTokens, uint256[] memory amounts) =
            externalTokensRouter.estimateDeposit(_tokensIn, _amountsIn);

        (address[] memory sortedAddresses, uint256[] memory sortedAmounts) =
            sortBPTokenstoPools(bptTokens, amounts);

        (uint256 errorCode, ) = fund.mintChecksPass(sortedAddresses, sortedAmounts, _minGyroMinted);

        return errorCode;
    }

    /**
     * @notice Checks if a call to `redeemToUnderlyingTokens` with the given
     * `_tokensOut`, `_amountsOut and `_maxGyroRedeemed` would succeed or not,
     * and returns the potential error code
     * @param _tokensOut the tokens to receive in exchange for redeeming Gyro dollars
     * @param _amountsOut the amount of each token to receive
     * @param _maxGyroRedeemed the maximum number of Gyro dollars to redeem
     * @return an error code if the call would fail, otherwise 0
     */
    function wouldRedeemChecksPass(
        address[] memory _tokensOut,
        uint256[] memory _amountsOut,
        uint256 _maxGyroRedeemed
    ) public view returns (uint256) {
        (address[] memory bptTokens, uint256[] memory amounts) =
            externalTokensRouter.estimateDeposit(_tokensOut, _amountsOut);

        (address[] memory sortedAddresses, uint256[] memory sortedAmounts) =
            sortBPTokenstoPools(bptTokens, amounts);

        (uint256 errorCode, ) =
            fund.redeemChecksPass(sortedAddresses, sortedAmounts, _maxGyroRedeemed);

        return errorCode;
    }

    /**
     * @return the list of tokens supported by the Gyro fund
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return fund.getUnderlyingTokenAddresses();
    }

    /**
     * @return the list of Balance pools supported by the Gyro fund
     */
    function getSupportedPools() external view returns (address[] memory) {
        return fund.poolAddresses();
    }

    /**
     * @return the current values of the Gyro fund's reserve
     */
    function getReserveValues()
        external
        view
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        return fund.getReserveValues();
    }

    function sortBPTokenstoPools(address[] memory _BPTokensIn, uint256[] memory amounts)
        internal
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory sortedAddresses = fund.poolAddresses();
        uint256[] memory sortedAmounts = new uint256[](sortedAddresses.length);

        for (uint256 i = 0; i < _BPTokensIn.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < sortedAddresses.length; j++) {
                if (sortedAddresses[j] == _BPTokensIn[i]) {
                    sortedAmounts[j] += amounts[i];
                    found = true;
                    break;
                }
            }
            require(found, "could not find valid pool");
        }

        return (sortedAddresses, sortedAmounts);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./balancer/BPool.sol";
import "./abdk/ABDKMath64x64.sol";
import "./compound/UniswapAnchoredView.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ExtendedMath.sol";

/**
 * PriceOracle is the interface for asset price oracles
 * Currently used with a proxy for the Compound oracle on testnet
 */
interface PriceOracle {
    function getPrice(string memory tokenSymbol) external view returns (uint256);
}

/**
 * GyroPriceOracle is the P-AMM implementation described here:
 * https://docs.gyro.finance/learn/gyro-amms/p-amm
 * The testnet implementation (GyroPriceOracleV1) simplifications are detailed here:
 * https://docs.gyro.finance/testnet-alpha/gyroscope-amm
 */
interface GyroPriceOracle {
    function getAmountToMint(
        uint256 _dollarValueIn,
        uint256 _inflowHistory,
        uint256 _nav
    ) external view returns (uint256);

    function getAmountToRedeem(
        uint256 _dollarValueOut,
        uint256 _outflowHistory,
        uint256 _nav
    ) external view returns (uint256 _gyroAmount);

    function getBPTPrice(address _bPoolAddress, uint256[] memory _underlyingPrices)
        external
        view
        returns (uint256 _bptPrice);
}

contract GyroPriceOracleV1 is GyroPriceOracle {
    using ExtendedMath for int128;
    using ExtendedMath for uint256;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;

    uint256 constant bpoolDecimals = 18;

    /**
     * Calculates the offer price to mint a new Gyro Dollar in the P-AMM.
     * @param _dollarValueIn = dollar value of user-provided input assets
     * @param _inflowHistory = current state of Gyroscope inflow history
     * @param _nav = current reserve value per Gyro Dollar
     * Returns the amount of GYD that the protocol will offer to mint in return
     * for the input assets.
     */
    function getAmountToMint(
        uint256 _dollarValueIn,
        uint256 _inflowHistory,
        uint256 _nav
    ) external pure override returns (uint256 _gyroAmount) {
        uint256 _one = 1e18;
        if (_nav < _one) {
            _gyroAmount = _dollarValueIn;
        } else {
            // gyroAmount = dollarValueIn * (1 - eps_inflowHistory) or min of 0
            uint256 _eps = 1e11;
            uint256 _scaling = _eps.scaledMul(_inflowHistory);
            if (_scaling >= _one) {
                _gyroAmount = 0;
            } else {
                _gyroAmount = _dollarValueIn.scaledMul(_one.sub(_scaling));
            }
        }
        _gyroAmount = _dollarValueIn;
        return _gyroAmount;
    }

    /**
     * Calculates the offer price to redeem a Gyro Dollar in the P-AMM.
     * @param _dollarValueOut = dollar-value of user-requested outputs, to redeem from reserve
     * @param _outflowHistory = current state of Gyroscope outflow history
     * @param _nav = current reserve value per Gyro Dollar
     * Returns the amount of GYD the protocol will ask to redeem to fulfill the requested asset outputs
     */
    function getAmountToRedeem(
        uint256 _dollarValueOut,
        uint256 _outflowHistory,
        uint256 _nav
    ) external pure override returns (uint256 _gyroAmount) {
        if (_nav < 1e18) {
            // gyroAmount = dollarValueOut * (1 + eps*outflowHistory)
            uint256 _eps = 1e11;
            uint256 _scaling = _eps.scaledMul(_outflowHistory).add(1e18);
            _gyroAmount = _dollarValueOut.scaledMul(_scaling);
        } else {
            _gyroAmount = _dollarValueOut;
        }

        return _gyroAmount;
    }

    /**
     * Calculates the value of Balancer pool tokens using the logic described here:
     * https://docs.gyro.finance/learn/oracles/bpt-oracle
     * This is robust to price manipulations within the Balancer pool.
     * @param _bPoolAddress = address of Balancer pool
     * @param _underlyingPrices = array of prices for underlying assets in the pool, in the same
     * order as _bPool.getFinalTokens() will return
     */
    function getBPTPrice(address _bPoolAddress, uint256[] memory _underlyingPrices)
        public
        view
        override
        returns (uint256 _bptPrice)
    {
        /* calculations:
            bptSupply = # of BPT tokens
            bPoolWeights = array of pool weights (require _underlyingPrices comes in same order)
            k = constant = product of reserves^weight
            bptPrice = (k * product of (p_i / w_i)^w_i ) / bptSupply

            functions from ABDKMath64x64 library
            -- exp_2 = binary exponent
            -- log_2 = binary logarithm
            -- mul = calculate x*y

            x^y = 2^(y log_2 x)
            exp_2( mul(y, log_2(x)) )
        */
        BPool _bPool = BPool(_bPoolAddress);
        uint256 _bptSupply = _bPool.totalSupply();
        address[] memory _tokens = _bPool.getFinalTokens();

        uint256 _k = uint256(1e18); // check that these are the right to get value 1
        uint256 _weightedProd = uint256(1e18);

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _weight = _bPool.getNormalizedWeight(_tokens[i]);
            uint256 _price = _underlyingPrices[i];
            uint256 _tokenBalance = _bPool.getBalance(_tokens[i]);
            uint256 _decimals = ERC20(_tokens[i]).decimals();

            if (_decimals < bpoolDecimals) {
                _tokenBalance = _tokenBalance.mul(10**(bpoolDecimals - _decimals));
                _price = _price.mul(10**(bpoolDecimals - _decimals));
            }

            _k = _k.mulPow(_tokenBalance, _weight, bpoolDecimals);

            _weightedProd = _weightedProd.mulPow(
                _price.scaledDiv(_weight, bpoolDecimals),
                _weight,
                bpoolDecimals
            );
        }

        uint256 result = _k.scaledMul(_weightedProd).scaledDiv(_bptSupply);
        return result;
    }
}

/**
 * Proxy contract for Compound asset price oracle, used in testnet implementation
 */
contract CompoundPriceWrapper is PriceOracle {
    using SafeMath for uint256;

    uint256 public constant oraclePriceScale = 1000000;
    address public compoundOracle;

    constructor(address _compoundOracle) {
        compoundOracle = _compoundOracle;
    }

    function getPrice(string memory tokenSymbol) public view override returns (uint256) {
        bytes32 symbolHash = keccak256(bytes(tokenSymbol));
        // Compound oracle uses "ETH", so change "WETH" to "ETH"
        if (symbolHash == keccak256(bytes("WETH"))) {
            tokenSymbol = "ETH";
        }

        if (symbolHash == keccak256(bytes("sUSD")) || symbolHash == keccak256(bytes("BUSD"))) {
            tokenSymbol = "DAI";
        }
        UniswapAnchoredView oracle = UniswapAnchoredView(compoundOracle);
        uint256 unscaledPrice = oracle.price(tokenSymbol);
        TokenConfig memory tokenConfig = oracle.getTokenConfigBySymbol(tokenSymbol);
        return unscaledPrice.mul(tokenConfig.baseUnit).div(oraclePriceScale);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./GyroFund.sol";
import "./Ownable.sol";
import "./abdk/ABDKMath64x64.sol";

interface GyroRouter {
    function deposit(address[] memory _tokensIn, uint256[] memory _amountsIn)
        external
        returns (address[] memory, uint256[] memory);

    function withdraw(address[] memory _tokensOut, uint256[] memory _amountsOut)
        external
        returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function initializeOwner() external {
        require(_owner == address(0), "owner already initialized");
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(
            x <= 0x7FFFFFFFFFFFFFFF,
            "value is too high to be transformed in a 64.64-bit number"
        );
        return int128(x << 64);
    }

    /**
     * Convert unsigned 256-bit integer number scaled with 10^decimals into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @param decimal scale of the number
     * @return signed 64.64-bit fixed point number
     */
    function fromScaled(uint256 x, uint256 decimal) internal pure returns (int128) {
        uint256 scale = 10**decimal;
        int128 wholeNumber = fromUInt(x / scale);
        int128 decimalNumber = div(fromUInt(x % scale), fromUInt(scale));
        return add(wholeNumber, decimalNumber);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0);
        return uint64(x >> 64);
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(
                y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                    y <= 0x1000000000000000000000000000000000000000000000000
            );
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(
                    absoluteResult <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(absoluteResult); // We rely on overflow behavior here
            } else {
                require(
                    absoluteResult <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0);

        uint256 lo = (uint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(x) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0);
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = -x; // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y; // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return -int128(absoluteResult); // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0);
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64));
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0);
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0);
        require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        uint256 absoluteResult;
        bool negativeResult = false;
        if (x >= 0) {
            absoluteResult = powu(uint256(x) << 63, y);
        } else {
            // We rely on overflow behavior here
            absoluteResult = powu(uint256(uint128(-x)) << 63, y);
            negativeResult = y & 1 > 0;
        }

        absoluteResult >>= 63;

        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return -int128(absoluteResult); // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0);
        return int128(sqrtu(uint256(x) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return int128((uint256(log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128);
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "exponent too large"); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0)
            result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0)
            result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0)
            result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0)
            result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0)
            result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0)
            result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0)
            result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0)
            result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0)
            result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0)
            result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0)
            result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= uint256(63 - (x >> 64));
        require(result <= uint256(MAX_64x64));

        return int128(result);
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128(result);
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
     * number and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x unsigned 129.127-bit fixed point number
     * @param y uint256 value
     * @return unsigned 129.127-bit fixed point number
     */
    function powu(uint256 x, uint256 y) private pure returns (uint256) {
        if (y == 0) return 0x80000000000000000000000000000000;
        else if (x == 0) return 0;
        else {
            int256 msb = 0;
            uint256 xc = x;
            if (xc >= 0x100000000000000000000000000000000) {
                xc >>= 128;
                msb += 128;
            }
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 xe = msb - 127;
            if (xe > 0) x >>= uint256(xe);
            else x <<= uint256(-xe);

            uint256 result = 0x80000000000000000000000000000000;
            int256 re = 0;

            while (y > 0) {
                if (y & 1 > 0) {
                    result = result * x;
                    y -= 1;
                    re += xe;
                    if (
                        result >= 0x8000000000000000000000000000000000000000000000000000000000000000
                    ) {
                        result >>= 128;
                        re += 1;
                    } else result >>= 127;
                    if (re < -127) return 0; // Underflow
                    require(re < 128); // Overflow
                } else {
                    x = x * x;
                    y >>= 1;
                    xe <<= 1;
                    if (x >= 0x8000000000000000000000000000000000000000000000000000000000000000) {
                        x >>= 128;
                        xe += 1;
                    } else x >>= 127;
                    if (xe < -127) return 0; // Underflow
                    require(xe < 128); // Overflow
                }
            }

            if (re > 0) result <<= uint256(re);
            else if (re < 0) result >>= uint256(-re);

            return result;
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

abstract contract BColor {
    function getColor() external view virtual returns (bytes32);
}

contract BBronze is BColor {
    function getColor() external pure override returns (bytes32) {
        return bytes32("BRONZE");
    }
}

// SPDX-License-Identifier: UNLICENSED
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./BColor.sol";

contract BConst is BBronze {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    uint256 public constant EXIT_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**12;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: UNLICENSED
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./BNum.sol";

contract BMath is BBronze, BConst, BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint256 ratio = bdiv(numer, denom);
        uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
        return (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint256 y = bdiv(tokenBalanceOut, diff);
        uint256 foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountOut) {
        // Charge the trading fee for the proportion of tokenAi
        // which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);

        uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint256 newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint256 boo = bdiv(BONE, normalizedWeight);
        uint256 tokenInRatio = bpow(poolRatio, boo);
        uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee =
            bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
        uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint256 tokenAmountOutBeforeSwapFee =
            bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountIn) {
        // charge swap fee on the output token side
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint256 zoo = bsub(BONE, normalizedWeight);
        uint256 zar = bmul(zoo, swapFee);
        uint256 tokenAmountOutBeforeSwapFee =
            bdiv(tokenAmountOut, bsub(BONE, zar));

        uint256 newTokenBalanceOut =
            bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint256 newPoolSupply = bmul(poolRatio, poolSupply);
        uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
        return poolAmountIn;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./BConst.sol";

contract BNum is BConst {
    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./BToken.sol";
import "./BMath.sol";

contract BPool is BBronze, BToken, BMath {
    struct Record {
        bool bound; // is token bound to pool
        uint256 index; // private
        uint256 denorm; // denormalized weight
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256 tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut
    );

    event LOG_CALL(
        bytes4 indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    address private _factory; // BFactory address to push token exitFee to
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint256 private _swapFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint256 private _totalWeight;

    constructor() {
        _controller = msg.sender;
        _factory = msg.sender;
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap() external view returns (bool) {
        return _publicSwap;
    }

    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function getNumTokens() external view returns (uint256) {
        return _tokens.length;
    }

    function getCurrentTokens()
        external
        view
        _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    function getFinalTokens()
        external
        view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight()
        external
        view
        _viewlock_
        returns (uint256)
    {
        return _totalWeight;
    }

    function getNormalizedWeight(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint256 denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token)
        external
        view
        _viewlock_
        returns (uint256)
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee() external view _viewlock_ returns (uint256) {
        return _swapFee;
    }

    function getController() external view _viewlock_ returns (address) {
        return _controller;
    }

    function setSwapFee(uint256 swapFee) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _controller = manager;
    }

    function setPublicSwap(bool public_) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    function finalize() external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    )
        external
        _logs_
    // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0, // balance and denorm will be validated
            balance: 0 // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) public _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint256 oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint256 oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
            uint256 tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
            _pushUnderlying(
                token,
                msg.sender,
                bsub(tokenBalanceWithdrawn, tokenExitFee)
            );
            _pushUnderlying(token, _factory, tokenExitFee);
        }
    }

    function unbind(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint256 tokenBalance = _records[token].balance;
        uint256 tokenExitFee = bmul(tokenBalance, EXIT_FEE);

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint256 index = _records[token].index;
        uint256 last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            index: 0,
            denorm: 0,
            balance: 0
        });

        _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
        _pushUnderlying(token, _factory, tokenExitFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token) external _logs_ _lock_ {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = BIERC20(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external
        view
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return
            calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                _swapFee
            );
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external
        view
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return
            calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                0
            );
    }

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        _logs_
        _lock_
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        _logs_
        _lock_
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_factory, exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external
        _logs_
        _lock_
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(
            tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        uint256 spotPriceBefore =
            calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                _swapFee
            );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            _swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(
            spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
            "ERR_MATH_APPROX"
        );

        emit LOG_SWAP(
            msg.sender,
            tokenIn,
            tokenOut,
            tokenAmountIn,
            tokenAmountOut
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
        external
        _logs_
        _lock_
        returns (uint256 tokenAmountIn, uint256 spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(
            tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        uint256 spotPriceBefore =
            calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                _swapFee
            );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            _swapFee
        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(
            spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
            "ERR_MATH_APPROX"
        );

        emit LOG_SWAP(
            msg.sender,
            tokenIn,
            tokenOut,
            tokenAmountIn,
            tokenAmountOut
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountIn, spotPriceAfter);
    }

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external _logs_ _lock_ returns (uint256 poolAmountOut) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountIn,
            _swapFee
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return poolAmountOut;
    }

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external _logs_ _lock_ returns (uint256 tokenAmountIn) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");

        Record storage inRecord = _records[tokenIn];

        tokenAmountIn = calcSingleInGivenPoolOut(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountOut,
            _swapFee
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(
            tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return tokenAmountIn;
    }

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external _logs_ _lock_ returns (uint256 tokenAmountOut) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            _swapFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        require(
            tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external _logs_ _lock_ returns (uint256 poolAmountIn) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(
            tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        Record storage outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountOut,
            _swapFee
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return poolAmountIn;
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        bool xfer = BIERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        bool xfer = BIERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint256 amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount) internal {
        _burn(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./BNum.sol";

// Highly opinionated token implementation

interface BIERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst)
        external
        view
        returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);
}

contract BTokenBase is BNum {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract BToken is BTokenBase, BIERC20 {
    string private _name = "Balancer Pool Token";
    string private _symbol = "BPT";
    uint8 private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst)
        external
        view
        override
        returns (uint256)
    {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt)
        external
        override
        returns (bool)
    {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt)
        external
        returns (bool)
    {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt)
        external
        returns (bool)
    {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt)
        external
        override
        returns (bool)
    {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external override returns (bool) {
        require(
            msg.sender == src || amt <= _allowance[src][msg.sender],
            "ERR_BTOKEN_BAD_CALLER"
        );
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(
                _allowance[src][msg.sender],
                amt
            );
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../Ownable.sol";

enum PriceSource {
    FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
    FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
    REPORTER /// implies the price is set by the reporter
}

struct TokenConfig {
    address cToken;
    address underlying;
    bytes32 symbolHash;
    uint256 baseUnit;
    PriceSource priceSource;
    uint256 fixedPrice;
    address uniswapMarket;
    bool isUniswapReversed;
}

interface UniswapAnchoredView {
    function price(string calldata symbol) external view returns (uint256);

    function getTokenConfigBySymbol(string memory symbol)
        external
        view
        returns (TokenConfig memory);
}

contract DummyUniswapAnchoredView is Ownable, UniswapAnchoredView {
    mapping(string => uint256) private prices;
    mapping(string => TokenConfig) private tokenConfigs;
    mapping(string => bool) public tokenRegistered;

    function addToken(string memory symbol, TokenConfig memory config) public onlyOwner {
        tokenRegistered[symbol] = true;
        tokenConfigs[symbol] = config;
    }

    function setPrice(string memory symbol, uint256 _price) public onlyOwner {
        require(tokenRegistered[symbol], "symbol not registered");
        prices[symbol] = _price;
    }

    function price(string calldata symbol) external view override returns (uint256) {
        return prices[symbol];
    }

    function getTokenConfigBySymbol(string memory symbol)
        external
        view
        override
        returns (TokenConfig memory)
    {
        return tokenConfigs[symbol];
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}