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

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

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
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Libraries
import {BokkyPooBahsDateTimeLibrary} from './libraries/BokkyPooBahsDateTimeLibrary.sol';

// Interfaces
import {IOptionsFactory} from './options/interfaces/IOptionsFactory.sol';
import {IERC20} from './interfaces/IERC20.sol';

contract Dopex {
  using BokkyPooBahsDateTimeLibrary for uint256;

  /*==== PLATFORM CONTRACT ADDRESSES ====*/

  address public governance;

  /*==== EPOCH INIT TIME ====*/

  uint256 public epochInitTime;

  /*==== ADDRESS LIST ====*/

  mapping(bytes32 => address) public addresses;

  /*==== TOKEN LISTS ====*/

  mapping(address => bool) public baseTokensList;
  mapping(address => bool) public quoteTokensList;

  /*==== EVENTS ====*/

  event AddressImported(bytes32 indexed name, address indexed destination);
  event GovernanceAddressUpdated(address indexed governance);
  event AssetAdded(address indexed asset, bool isQuote);
  event AssetRemoved(address indexed asset, bool isQuote);
  event EpochInitTimeUpdated(uint256 indexed value);

  /*==== MODIFIERS ====*/

  modifier onlyGov() {
    require(msg.sender == governance, 'Sender is not governance');
    _;
  }

  modifier noZeroAddress(address addr) {
    require(addr != address(0), 'Address cannot be the zero address');
    _;
  }

  /*==== CONSTRUCTOR ====*/

  constructor() {
    governance = msg.sender;
    emit GovernanceAddressUpdated(msg.sender);
  }

  /*==== GOVERNANCE FUNCTIONS ====*/

  /// @notice Imports (adds) a list of addresses to the address list
  /// @param names Names of the contracts
  /// @param destinations Addresses of the contract
  /// @return Whether the addresses were imported
  function importAddresses(bytes32[] calldata names, address[] calldata destinations)
    external
    onlyGov
    returns (bool)
  {
    require(names.length == destinations.length, 'Input lengths must match');
    for (uint256 i = 0; i < names.length; i++) {
      bytes32 name = names[i];
      address destination = destinations[i];
      addresses[name] = destination;
      emit AddressImported(name, destination);
    }
    return true;
  }

  /// @notice Adds an asset to the supported token list
  /// @dev Also adds it inside of the OptionsContractFactory contract
  /// @param asset Address of the asset
  /// @param isQuote Whether the asset is a quote asset
  /// @return Whether the asset was added successfully
  function addAsset(address asset, bool isQuote) external onlyGov returns (bool) {
    require(isERC20(asset), 'Invalid ERC20 token address');

    if (isQuote) {
      quoteTokensList[asset] = true;
    } else {
      baseTokensList[asset] = true;
    }
    IOptionsFactory(addresses['OptionsFactory']).addAsset(IERC20(asset).symbol(), asset);

    emit AssetAdded(asset, isQuote);

    return true;
  }

  /// @notice Removes an asset from the supported token list
  /// @dev Also removes it from inside of the OptionsContractFactory contract
  /// @param asset Address of the asset
  /// @param isQuote Whether the asset is a quote asset
  /// @return Whether the asset was removed successfully
  function removeAsset(address asset, bool isQuote) external onlyGov returns (bool) {
    require(isERC20(asset), 'Invalid ERC20 token address');

    if (isQuote) {
      quoteTokensList[asset] = false;
    } else {
      baseTokensList[asset] = false;
    }
    IOptionsFactory(addresses['OptionsFactory']).deleteAsset(IERC20(asset).symbol());

    emit AssetRemoved(asset, isQuote);

    return true;
  }

  /// @notice Updates the governance contract address
  /// @param _governance Address
  /// @return Whether the address was set correctly
  function setGovernanceAddress(address _governance)
    external
    onlyGov
    noZeroAddress(_governance)
    returns (bool)
  {
    governance = _governance;

    emit GovernanceAddressUpdated(_governance);

    return true;
  }

  /// @notice Sets the initial epoch time
  /// @param _epochInitTime The epoch init time
  /// @return Whether the address was set correctly
  function setInitialEpochTime(uint256 _epochInitTime) external onlyGov returns (bool) {
    require(block.timestamp < _epochInitTime, 'Epoch time must be after block timestamp');
    require(epochInitTime == 0, 'Epoch time cannot be modified once it has elapsed');

    epochInitTime = _epochInitTime;

    emit EpochInitTimeUpdated(_epochInitTime);

    return true;
  }

  /*=== VIEWS ====*/

  /**
   * @notice Gets the address of an imported contract
   * @param name Name of the contract
   * @return The address of the contract
   */
  function getAddress(bytes32 name) external view returns (address) {
    return addresses[name];
  }

  /**
   * @notice Checks if address is ERC20, returns true otherwise false
   * @param erc20 The address of the erc20 contract
   * @return Whether the contract is erc20
   */
  function isERC20(address erc20) public view returns (bool) {
    return IERC20(erc20).totalSupply() > 0;
  }

  /**
   * @notice Returns the current global epoch based on the epoch init time and a 1 week time period
   * @dev Epochs are 1-indexed
   * @return Current weekly global epoch number
   */
  function getCurrentGlobalWeeklyEpoch() external view returns (uint256) {
    if (block.timestamp < epochInitTime) return 0;
    /**
     * Weekly Epoch = ((Current time - Init time) / 7 days) + 1
     * The current time is adjusted to account for any 'init time' by adding to it the difference
     * between the init time and the first expiry.
     * Current time = block.timestamp - (7 days - (The first expiry - init time))
     */
    return
      (((block.timestamp +
        (7 days - (getWeeklyExpiryFromTimestamp(epochInitTime) - epochInitTime))) - epochInitTime) /
        (7 days)) + 1;
  }

  /**
   * Returns start and end times for an epoch
   * @param epoch Target epoch
   */
  function getWeeklyEpochTimes(uint256 epoch) external view returns (uint256 start, uint256 end) {
    if (epoch == 1) {
      return (epochInitTime, getWeeklyExpiryFromTimestamp(epochInitTime));
    } else {
      uint256 _start = getWeeklyExpiryFromTimestamp(epochInitTime) + (7 days * (epoch - 2));
      return (_start, _start + 7 days);
    }
  }

  /**
   * Returns start and end times for an epoch
   * @param epochStartTime Time period of the epoch (7 days or 28 days)
   */
  function getMonthlyEpochTimes(uint256 epochStartTime)
    external
    pure
    returns (uint256 start, uint256 end)
  {
    return (epochStartTime, getMonthlyExpiryFromTimestamp(epochStartTime));
  }

  /*=== PURE FUNCTIONS ====*/

  /// @notice Calculates next available Friday expiry from a solidity date
  /// @param timestamp Timestamp from which the friday expiry is to be calculated
  /// @return The friday expiry
  function getWeeklyExpiryFromTimestamp(uint256 timestamp) public pure returns (uint256) {
    // Use friday as 1-index
    uint256 dayOfWeek = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp, 6);
    // If the day is already friday then check if expiry has passed. If yes then proceed with adding 7 days for the next expiry otherwise return the same friday with the 8am expiry.
    if (dayOfWeek == 1) {
      uint256 timestampAtExpiryTime = BokkyPooBahsDateTimeLibrary.timestampFromDateTime(
        timestamp.getYear(),
        timestamp.getMonth(),
        timestamp.getDay(),
        8,
        0,
        0
      );
      if (timestampAtExpiryTime > timestamp) {
        return timestampAtExpiryTime;
      }
    }
    uint256 nextFriday = timestamp + ((7 - dayOfWeek + 1) * 1 days);
    return
      BokkyPooBahsDateTimeLibrary.timestampFromDateTime(
        nextFriday.getYear(),
        nextFriday.getMonth(),
        nextFriday.getDay(),
        8,
        0,
        0
      );
  }

  /// @notice Calculates the monthly expiry from a solidity date
  /// @param timestamp Timestamp from which the monthly expiry is to be calculated
  /// @return The monthly expiry
  function getMonthlyExpiryFromTimestamp(uint256 timestamp) public pure returns (uint256) {
    uint256 lastDay = BokkyPooBahsDateTimeLibrary.timestampFromDate(
      timestamp.getYear(),
      timestamp.getMonth() + 1,
      0
    );

    if (lastDay.getDayOfWeek() < 5) {
      lastDay = BokkyPooBahsDateTimeLibrary.timestampFromDate(
        lastDay.getYear(),
        lastDay.getMonth(),
        lastDay.getDay() - 7
      );
    }

    uint256 lastFridayOfMonth = BokkyPooBahsDateTimeLibrary.timestampFromDateTime(
      lastDay.getYear(),
      lastDay.getMonth(),
      lastDay.getDay() - (lastDay.getDayOfWeek() - 5),
      8,
      0,
      0
    );

    if (lastFridayOfMonth <= timestamp) {
      uint256 temp = BokkyPooBahsDateTimeLibrary.timestampFromDate(
        timestamp.getYear(),
        timestamp.getMonth() + 2,
        0
      );

      if (temp.getDayOfWeek() < 5) {
        temp = BokkyPooBahsDateTimeLibrary.timestampFromDate(
          temp.getYear(),
          temp.getMonth(),
          temp.getDay() - 7
        );
      }

      lastFridayOfMonth = BokkyPooBahsDateTimeLibrary.timestampFromDateTime(
        temp.getYear(),
        temp.getMonth(),
        temp.getDay() - (temp.getDayOfWeek() - 5),
        8,
        0,
        0
      );
    }
    return lastFridayOfMonth;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

/// @title AssetSwapper Interface
/// @author Dopex
interface IAssetSwapper {
  /// @dev Swaps between given `from` and `to` assets
  /// @param from From token address
  /// @param to To token address
  /// @param amount From token amount
  /// @param minAmountOut Minimum token amount to receive out
  /// @return To token amuount received
  function swapAsset(
    address from,
    address to,
    uint256 amount,
    uint256 minAmountOut
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 constant SECONDS_PER_HOUR = 60 * 60;
  uint256 constant SECONDS_PER_MINUTE = 60;
  int256 constant OFFSET19700101 = 2440588;

  uint256 constant DOW_MON = 1;
  uint256 constant DOW_TUE = 2;
  uint256 constant DOW_WED = 3;
  uint256 constant DOW_THU = 4;
  uint256 constant DOW_FRI = 5;
  uint256 constant DOW_SAT = 6;
  uint256 constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 _days) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days =
      _day -
        32075 +
        (1461 * (_year + 4800 + (_month - 14) / 12)) /
        4 +
        (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
        12 -
        (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
        4 -
        OFFSET19700101;

    _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (uint256 timestamp) {
    timestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      hour *
      SECONDS_PER_HOUR +
      minute *
      SECONDS_PER_MINUTE +
      second;
  }

  function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
    (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
    (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month)
    internal
    pure
    returns (uint256 daysInMonth)
  {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp, uint256 index)
    internal
    pure
    returns (uint256 dayOfWeek)
  {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + index) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
    (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
    uint256 secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(uint256 timestamp, uint256 _months)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(uint256 timestamp, uint256 _hours)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(uint256 timestamp, uint256 _minutes)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds)
    internal
    pure
    returns (uint256 newTimestamp)
  {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 _years)
  {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 _months)
  {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 _days)
  {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 _hours)
  {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 _minutes)
  {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 _seconds)
  {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {BokkyPooBahsDateTimeLibrary} from './BokkyPooBahsDateTimeLibrary.sol';

library OptionPoolHelper {
  using BokkyPooBahsDateTimeLibrary for uint256;
  using SafeMath for uint256;

  /**
   * @dev Generates an option contract id given it's type, expiry and strike
   * @param isPut is put option
   * @param expiry Expiry timestamp
   * @param strike Strike price
   * @param optionPoolAddress Address of the option pool creating the options contract
   * @return Option contract ID
   */
  function generateOptionContractId(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    address optionPoolAddress
  ) internal pure returns (bytes32) {
    bytes32 optionContractId = keccak256(
      abi.encodePacked(expiry, strike, isPut, optionPoolAddress)
    );
    return optionContractId;
  }

  /**
   * @dev Generates an option pool id given it's base and quote asset addresses
   * @param baseAsset Base asset address
   * @param quoteAsset Quote asset address
   * @param timePeriod Option pool time period
   * @return Option pool ID
   */
  function generateOptionPoolId(
    address baseAsset,
    address quoteAsset,
    bytes32 timePeriod
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(baseAsset, quoteAsset, timePeriod));
  }

  /**
   * @dev Checks whether a given timestamp is at 8 AM
   * @param timestamp The timestamp to be checked
   * @return Returns true if timestamp is 8 AM otherwise false
   */
  function isAt8Am(uint256 timestamp) internal pure returns (bool) {
    uint256 timestampAt8Am = BokkyPooBahsDateTimeLibrary.timestampFromDateTime(
      timestamp.getYear(),
      timestamp.getMonth(),
      timestamp.getDay(),
      8,
      0,
      0
    );
    return timestampAt8Am == timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

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
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance =
      token.allowance(address(this), spender).sub(
        value,
        'SafeERC20: decreased allowance below zero'
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

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;
pragma abicoder v2;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '../libraries/SafeERC20.sol';
import {OptionPoolHelper} from '../libraries/OptionPoolHelper.sol';

// Interfaces
import {IERC20} from '../interfaces/IERC20.sol';
import {InterestRateModel} from './compound/interfaces/InterestRateModel.sol';
import {IDopexOracle} from '../oracle/interfaces/IDopexOracle.sol';
import {IOptionsFactory} from '../options/interfaces/IOptionsFactory.sol';
import {IAssetSwapper} from '../asset-swapper/interfaces/IAssetSwapper.sol';

// Contracts
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {JumpRateModelV2} from './compound/JumpRateModelV2.sol';
import {Dopex} from '../Dopex.sol';
import {OptionPoolFactory} from '../pools/OptionPoolFactory.sol';
import {OptionPoolBroker} from '../pools/OptionPoolBroker/OptionPoolBroker.sol';
import {OptionPool} from '../pools/OptionPool.sol';

/// @title This contract facilitates margin based trading on the Dopex Platform
/// @author Dopex
/// @notice Allows the opening of margin positions (up to a certain leverage) by providing collateral
contract Margin is ERC20 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /*==== STRUCTS ====*/

  /// @dev Struct for storing data for each collateral type
  /// @param collateralizationRatio Minimum ratio between collateral value and debt value
  /// @param liquidationRatio Ratio between collateral value and debt value at which the position becomes eligible for liquidation
  struct Collateral {
    uint256 collateralizationRatio;
    uint256 liquidationRatio;
  }

  /// @dev Struct for each margin position
  /// @param collateralAmount Amount of collateral in the position
  /// @param amount Amount of options purchased
  /// @param leverage The leverage of the position
  /// @param borrowed Amount of USDT used to purchase the options
  /// @param borrowIndex Borrow index at position creation
  struct MarginPosition {
    uint256 collateralAmount;
    uint256 amount;
    uint256 leverage;
    uint256 borrowed;
    uint256 borrowIndex;
  }

  /*==== EVENTS ====*/

  /// @notice Emitted on each update to a collateral
  /// @param asset Collateral address
  /// @param collateralizationRatio Collateral factor
  /// @param liquidationRatio Liquidation factor where position becomes eligible for liquidation
  event UpdateCollateral(
    address indexed asset,
    uint256 collateralizationRatio,
    uint256 liquidationRatio
  );

  /// @notice Emitted on each update to the max leverage
  /// @param maxLeverage New max leverage
  event SetMaxLeverage(uint256 maxLeverage);

  /// @notice Emitted on each update to the reserve factor
  /// @param reserveFactor New reserve factor
  event SetReserveFactor(uint256 reserveFactor);

  /// @notice Emitted on each update to the interest rate model
  /// @param interestRateModel New interest rate model
  event SetInterestRateModel(address interestRateModel);

  /// @notice Emitted on each update to the liquidation incentive
  /// @param liquidationIncentive New liquidation incentive
  event SetLiquidationIncentive(uint256 liquidationIncentive);

  /// @notice Emitted each time a position is created
  /// @param sender Creator of the position
  /// @param optionPool Option pool address
  /// @param positionId ID of the position created
  /// @param collateral Address of the collateral asset
  /// @param isPut Whether put/call options are to be purchased
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  event NewMarginPosition(
    address indexed sender,
    address optionPool,
    bytes32 positionId,
    address collateral,
    bool isPut,
    uint256 strike,
    uint256 expiry
  );

  /// @notice Emitted each time collateral is added/withdrawn from a position
  /// @param sender Creator of the position
  /// @param optionPool Option pool address
  /// @param positionId ID of the position created
  /// @param collateral Address of the collateral asset
  /// @param newCollateralAmount New collateral amount for the position
  event UpdatedPositionCollateral(
    address indexed sender,
    address optionPool,
    bytes32 positionId,
    address collateral,
    uint256 newCollateralAmount
  );

  /*==== PUBLIC VARS ====*/

  /// @dev Minimum leverage allowed (1x)
  uint256 public constant minLeverage = 100;

  /// @dev Minimum collateral factor (100%)
  uint256 public constant minCollateralizationRatio = 100;

  /// @dev Maximum liquidation incentive (100%)
  uint256 public constant maxLiquidationIncentive = 100;

  /// @dev The precision in which the strike price is received
  uint256 public constant strikePrecision = 1e8;

  /// @dev The Dopex master contract
  Dopex public immutable dopex;

  /// @dev USDT contract
  IERC20 public immutable usdt;

  /// @dev Total USDT deposited as collateral
  uint256 public totalUsdtCollateral;

  /// @dev Currently lent funds from pool
  uint256 public totalBorrows;

  /// @dev USDT fee accrual
  uint256 public totalReserves;

  /// @dev Last timestamp interest was accrued
  uint256 public accrualTimestamp;

  /// @dev Accumulator of the total earned interest
  uint256 public borrowIndex;

  /// @dev Maximum leverage allowed
  uint256 public maxLeverage;

  /// @dev Fee taken from borrows and put into reserves
  uint256 public reserveFactor;

  /// @dev Discount on collateral to incentivize liquidations
  uint256 public liquidationIncentive;

  /// @dev Interest rate model contract
  InterestRateModel public interestRateModel;

  /// @dev List of supported collaterals
  address[] public collaterals;

  /// @dev Data for each collateral
  mapping(address => Collateral) public collateralAssets;

  /// @dev User margin positions (user => (positionId => marginPosition))
  mapping(address => mapping(bytes32 => MarginPosition)) public marginPositions;

  /*==== CONSTRUCTOR ====*/

  /// @notice Constructor
  /// @param _dopex Dopex master contract address
  constructor(address _dopex, address _usdt) ERC20('Margin Pool USDT', 'mpUSDT') {
    Dopex dopexContract = Dopex(_dopex);
    dopex = dopexContract;
    // Caches USDT contract address on deploy to save gas
    usdt = IERC20(_usdt);
    accrualTimestamp = block.timestamp;
    borrowIndex = 1e18; // 1
    maxLeverage = 500; // 5x
    reserveFactor = 100000000000000000; // 10%
    liquidationIncentive = 90; // 90%
    interestRateModel = InterestRateModel(
      new JumpRateModelV2(
        0, /* Base APR (0%) */
        40000000000000000, /* Rate of interest rate increase (4%) */
        1090000000000000000, /* Rate of interest rate increase after hitting utilization point (109%) */
        800000000000000000 /* Utilization point (80%) */
      )
    );
    emit SetMaxLeverage(maxLeverage);
    emit SetReserveFactor(reserveFactor);
    emit SetLiquidationIncentive(liquidationIncentive);
    emit SetInterestRateModel(address(interestRateModel));

    collateralAssets[_usdt] = Collateral({
      collateralizationRatio: 100,
      liquidationRatio: 100
    });
    collaterals.push(_usdt);
    emit UpdateCollateral(_usdt, 100, 100);
  }

  /*==== MODIFIERS ====*/

  modifier onlyGov() {
    require(msg.sender == dopex.governance(), 'E18');
    _;
  }

  /*==== GOVERNANCE FUNCTIONS ====*/

  /// @notice Add a collateral type
  /// @dev Can only be called by governance
  /// @param asset collateral token address
  /// @param _collateralizationRatio Minimum ratio between collateral value and debt value
  /// @param _liquidationRatio Ratio between collateral value and debt value at which the position becomes eligible for liquidation
  function addCollateral(
    address asset,
    uint256 _collateralizationRatio,
    uint256 _liquidationRatio
  ) external onlyGov {
    require(collateralAssets[asset].collateralizationRatio == 0, 'Margin: Asset is already listed');
    require(
      _collateralizationRatio >= minCollateralizationRatio &&
        _liquidationRatio >= minCollateralizationRatio &&
        _liquidationRatio <= _collateralizationRatio,
      'Margin: Invalid params'
    );
    collateralAssets[asset] = Collateral({
      collateralizationRatio: _collateralizationRatio,
      liquidationRatio: _liquidationRatio
    });
    collaterals.push(asset);
    emit UpdateCollateral(asset, _collateralizationRatio, _liquidationRatio);
  }

  /// @notice Update a collateral assets data
  /// @dev Can only be called by governance
  /// @param asset collateral token address
  /// @param _collateralizationRatio Minimum ratio between collateral value and debt value
  /// @param _liquidationRatio Ratio between collateral value and debt value at which the position becomes eligible for liquidation
  function updateCollateral(
    address asset,
    uint256 _collateralizationRatio,
    uint256 _liquidationRatio
  ) external onlyGov {
    require(collateralAssets[asset].collateralizationRatio > 0, 'Margin: Asset must be listed');
    require(
      _collateralizationRatio >= minCollateralizationRatio &&
        _liquidationRatio >= minCollateralizationRatio &&
        _liquidationRatio <= _collateralizationRatio,
      'Margin: Invalid params'
    );
    collateralAssets[asset].collateralizationRatio = _collateralizationRatio;
    collateralAssets[asset].liquidationRatio = _liquidationRatio;
    emit UpdateCollateral(asset, _collateralizationRatio, _liquidationRatio);
  }

  /// @notice Remove a collateral asset
  /// @dev Can only be called by governance
  /// @param asset Collateral token address
  /// @param assetIndex Index of asset in collaterals array
  function removeCollateral(address asset, uint256 assetIndex) external onlyGov {
    require(collateralAssets[asset].collateralizationRatio > 0, 'Margin: Asset must be listed');
    require(collaterals[assetIndex] == asset, 'Margin: Invalid index');
    collateralAssets[asset] = Collateral({collateralizationRatio: 0, liquidationRatio: 0});
    collaterals[assetIndex] = collaterals[collaterals.length - 1];
    collaterals.pop();
    emit UpdateCollateral(asset, 0, 0);
  }

  /// @notice Updates maximum leverage allowed
  /// @dev Can only be called by governance
  /// @param _maxLeverage Maximum leverage in terms of minLeverage
  function setMaxLeverage(uint256 _maxLeverage) external onlyGov {
    require(_maxLeverage >= minLeverage, 'Margin: Invalid leverage');
    maxLeverage = _maxLeverage;
    emit SetMaxLeverage(_maxLeverage);
  }

  /// @notice Updates the reserve factor
  /// @dev Can only be called by governance
  /// @param _reserveFactor New reserve factor
  function setReserveFactor(uint256 _reserveFactor) external onlyGov {
    require(_reserveFactor <= 1e18, 'Margin: Invalid reserveFactor');
    reserveFactor = _reserveFactor;
    emit SetReserveFactor(_reserveFactor);
  }

  /// @notice Updates the interest rate model
  /// @dev Can only be called by governance
  /// @param _interestRateModel Interest rate model address
  function setInterestRateModel(address _interestRateModel) external onlyGov {
    require(_interestRateModel != address(0), 'Margin: Invalid interestRateModel');
    interestRateModel = InterestRateModel(_interestRateModel);
    emit SetInterestRateModel(_interestRateModel);
  }

  /// @notice Updates the liquidation incentive
  /// @dev Can only be called by governance
  /// @param _liquidationIncentive New liquidation incentive
  function setLiquidationIncentive(uint256 _liquidationIncentive) external onlyGov {
    require(
      _liquidationIncentive <= maxLiquidationIncentive,
      'Margin: Invalid liquidationIncentive'
    );
    liquidationIncentive = _liquidationIncentive;
    emit SetLiquidationIncentive(_liquidationIncentive);
  }

  /// @notice Withdraws USDT reserves from this contract
  /// @dev Can only be called by governance
  /// @param amount Amount of reserves to withdraw
  /// @param to Address to withdraw reserves to
  function withdrawReserves(uint256 amount, address to) external onlyGov {
    accrueInterest();
    totalReserves = totalReserves.sub(amount);
    require(amount <= freeFunds(), 'Margin: No funds available for withdrawals');
    usdt.safeTransfer(to, amount);
  }

  /*==== EXTERNAL FUNCTIONS ====*/

  /// @notice Deposits USDT to the margin pool to earn yield
  /// @dev Mints a pool share to the sender
  /// @param amount Amount of USDT to deposit
  /// @return Amount of shares user received
  function deposit(uint256 amount) external returns (uint256) {
    accrueInterest();
    uint256 totalShares = totalSupply();
    uint256 funds = totalFunds();
    uint256 mintAmount;
    if (totalShares == 0 || funds == 0) {
      mintAmount = amount;
    } else {
      mintAmount = amount.mul(totalShares).div(funds);
    }
    _mint(msg.sender, mintAmount);
    usdt.safeTransferFrom(msg.sender, address(this), amount);
    return mintAmount;
  }

  /// @notice Withdraws USDT from the margin pool
  /// @dev Burns the pool shares owned by sender
  /// @param shares Amount of pool shares to redeem for withdrawing USDT
  /// @return Amount of USDT user received
  function withdraw(uint256 shares) external returns (uint256) {
    accrueInterest();
    uint256 withdrawAmount = shares.mul(totalFunds()).div(totalSupply());
    require(withdrawAmount <= freeFunds(), 'Margin: No funds available for withdrawals');
    _burn(msg.sender, shares);
    usdt.safeTransfer(msg.sender, withdrawAmount);
    return withdrawAmount;
  }

  /// @dev Params for opening a new margin position
  /// @param isPut Whether put/call options are to be purchased
  /// @param amount Amount of options to purchase
  /// @param leverage Leverage to purchase at
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  /// @param collateralAmount Amount of collateral to deposit
  /// @param collateral Collateral type
  /// @param optionPoolId ID of option pool
  struct OpenMarginPosition {
    bool useVolumePoolFunds;
    bool isPut;
    uint256 amount;
    uint256 leverage;
    uint256 strike;
    uint256 expiry;
    uint256 collateralAmount;
    address collateral;
    bytes32 optionPoolId;
  }

  /// @notice Opens a new margin position
  /// @param params Params for opening a position
  /// @return USDT cost of purchasing options
  function openMarginPosition(OpenMarginPosition calldata params) external returns (uint256) {
    accrueInterest();
    require(
      collateralAssets[params.collateral].collateralizationRatio > 0,
      'Margin: Invalid collateral'
    );
    require(
      (params.leverage > minLeverage) && (params.leverage <= maxLeverage),
      'Margin: Invalid leverage'
    );
    OptionPool optionPool = OptionPool(
      OptionPoolFactory(dopex.getAddress('OptionPoolFactory')).optionPools(params.optionPoolId)
    );
    bytes32 positionId = generatePositionId(
      params.isPut,
      params.strike,
      params.expiry,
      address(optionPool),
      params.collateral
    );
    require(marginPositions[msg.sender][positionId].amount == 0, 'Margin: Position already opened');
    uint256 funds = freeFunds();
    OptionPoolBroker optionPoolBroker = OptionPoolBroker(dopex.getAddress('OptionPoolBroker'));
    usdt.approve(address(optionPoolBroker), funds);
    optionPoolBroker.purchaseOptionOnBehalfOf(
      params.useVolumePoolFunds,
      params.isPut,
      params.strike,
      params.expiry,
      params.amount,
      optionPool.timePeriod(),
      address(optionPool.baseAsset()),
      address(usdt),
      msg.sender
    );
    uint256 usdtAmount = funds.sub(freeFunds());
    require(usdtAmount <= funds, 'Margin: No funds available');
    uint256 debt = usdtAmount.mul(minLeverage).div(params.leverage);
    uint256 collateralUsdtAmount = _getCollateralUsdtAmount(
      params.collateral,
      params.collateralAmount
    );
    require(
      collateralUsdtAmount.mul(minCollateralizationRatio).div(debt) >=
        collateralAssets[params.collateral].collateralizationRatio,
      'Margin: Invalid collateral amount'
    );
    marginPositions[msg.sender][positionId] = MarginPosition({
      collateralAmount: params.collateralAmount,
      amount: params.amount,
      leverage: params.leverage,
      borrowed: usdtAmount,
      borrowIndex: borrowIndex
    });
    totalBorrows = totalBorrows.add(usdtAmount);
    _transferCollateralIn(msg.sender, params.collateral, params.collateralAmount);
    emit NewMarginPosition(
      msg.sender,
      address(optionPool),
      positionId,
      params.collateral,
      params.isPut,
      params.strike,
      params.expiry
    );
    return usdtAmount;
  }

  /// @dev Params for adding/withdrawing collateral to a margin position
  /// @param isPut Whether put/call options are to be purchased
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  /// @param collateralAmount Amount of collateral to add/withdraw
  /// @param optionPool Address of option pool
  /// @param collateral Collateral type
  struct UpdatePosition {
    bool isPut;
    uint256 strike;
    uint256 expiry;
    uint256 collateralAmount;
    address optionPool;
    address collateral;
  }

  /// @notice Adds collateral to a margin position
  /// @param params Params for adding collateral to a position
  function addToMarginPosition(UpdatePosition calldata params) external {
    accrueInterest();
    bytes32 positionId = generatePositionId(
      params.isPut,
      params.strike,
      params.expiry,
      params.optionPool,
      params.collateral
    );
    MarginPosition storage marginPosition = marginPositions[msg.sender][positionId];
    require(marginPosition.amount > 0, 'Margin: Position must be opened');
    uint256 newCollateralAmount = marginPosition.collateralAmount.add(params.collateralAmount);
    marginPosition.collateralAmount = newCollateralAmount;
    _transferCollateralIn(msg.sender, params.collateral, params.collateralAmount);
    emit UpdatedPositionCollateral(
      msg.sender,
      params.optionPool,
      positionId,
      params.collateral,
      newCollateralAmount
    );
  }

  /// @notice Withdraws collateral to a margin position
  /// @param params Params for withdrawing collateral from a position
  function withdrawFromMarginPosition(UpdatePosition calldata params) external {
    accrueInterest();
    bytes32 positionId = generatePositionId(
      params.isPut,
      params.strike,
      params.expiry,
      params.optionPool,
      params.collateral
    );
    MarginPosition storage marginPosition = marginPositions[msg.sender][positionId];
    require(marginPosition.amount > 0, 'Margin: Position must be opened');
    uint256 newCollateralAmount = marginPosition.collateralAmount.sub(params.collateralAmount);
    (bool invalid, ) = _getPositionLosses(
      _getOptionCost(
        params.isPut,
        params.strike,
        params.expiry,
        marginPosition.amount,
        OptionPool(params.optionPool),
        OptionPoolBroker(dopex.getAddress('OptionPoolBroker'))
      ),
      params.collateral,
      _getCollateralUsdtAmount(params.collateral, newCollateralAmount),
      marginPosition.borrowed.mul(borrowIndex).div(marginPosition.borrowIndex),
      _getDebt(marginPosition.borrowed, marginPosition.leverage, marginPosition.borrowIndex)
    );
    require(!invalid, 'Margin: Invalid position');
    marginPosition.collateralAmount = newCollateralAmount;
    _transferCollateralOut(msg.sender, params.collateral, params.collateralAmount);
    emit UpdatedPositionCollateral(
      msg.sender,
      params.optionPool,
      positionId,
      params.collateral,
      newCollateralAmount
    );
  }

  /// @dev Params for exiting a margin position
  /// @param isPut Whether put/call options are to be purchased
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  /// @param optionPool Address of option pool
  /// @param collateral Collateral type
  struct ExitPosition {
    bool isPut;
    uint256 strike;
    uint256 expiry;
    address optionPool;
    address collateral;
  }

  /// @notice Exits a margin position
  /// @param params Params for exiting a position
  function exitMarginPosition(ExitPosition calldata params) external {
    accrueInterest();
    bytes32 positionId = generatePositionId(
      params.isPut,
      params.strike,
      params.expiry,
      params.optionPool,
      params.collateral
    );
    MarginPosition storage marginPosition = marginPositions[msg.sender][positionId];
    require(marginPosition.amount > 0, 'Margin: Position must be opened');
    IERC20 baseAsset = OptionPool(params.optionPool).baseAsset();
    IERC20 asset = params.isPut ? usdt : baseAsset;
    uint256 pnl = asset.balanceOf(address(this));
    OptionPoolBroker(dopex.getAddress('OptionPoolBroker')).exerciseOption(
      params.isPut,
      params.strike,
      params.expiry,
      marginPosition.amount,
      OptionPool(params.optionPool).timePeriod(),
      address(baseAsset),
      address(usdt)
    );
    pnl = asset.balanceOf(address(this)).sub(pnl);
    IAssetSwapper assetSwapper = IAssetSwapper(dopex.getAddress('AssetSwapper'));
    if (!params.isPut && pnl > 0) {
      baseAsset.safeApprove(address(assetSwapper), pnl);
      pnl = assetSwapper.swapAsset(address(baseAsset), address(usdt), pnl, 0);
    }
    uint256 borrowed = marginPosition.borrowed.mul(borrowIndex).div(marginPosition.borrowIndex);
    if (pnl < borrowed) {
      if (params.collateral == address(usdt)) {
        pnl = pnl.add(marginPosition.collateralAmount);
        totalUsdtCollateral = totalUsdtCollateral.sub(marginPosition.collateralAmount);
      } else {
        IERC20(params.collateral).safeApprove(
          address(assetSwapper),
          marginPosition.collateralAmount
        );
        pnl = pnl.add(
          assetSwapper.swapAsset(
            params.collateral,
            address(usdt),
            marginPosition.collateralAmount,
            0
          )
        );
      }
    } else {
      _transferCollateralOut(msg.sender, params.collateral, marginPosition.collateralAmount);
    }
    if (pnl > borrowed) {
      usdt.safeTransfer(msg.sender, pnl.sub(borrowed));
      totalBorrows = totalBorrows.sub(borrowed);
    } else {
      totalBorrows = totalBorrows.sub(pnl);
    }
    delete marginPositions[msg.sender][positionId];
  }

  /// @dev Params for liquidating a margin position
  /// @param isPut Whether put/call options are to be purchased
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  /// @param optionPool Address of option pool
  /// @param collateral Collateral type
  struct LiquidatePosition {
    bool isPut;
    uint256 strike;
    uint256 expiry;
    address optionPool;
    address collateral;
    address user;
  }

  /// @notice Liquidates a margin position
  /// @param params Params for liquidating a position
  function liquidate(LiquidatePosition calldata params) external {
    bytes32 positionId = generatePositionId(
      params.isPut,
      params.strike,
      params.expiry,
      params.optionPool,
      params.collateral
    );
    MarginPosition storage marginPosition = marginPositions[params.user][positionId];
    require(marginPosition.amount > 0, 'Margin: Position must be opened');
    uint256 collateralUsdtAmount = _getCollateralUsdtAmount(
      params.collateral,
      marginPosition.collateralAmount
    );
    uint256 borrowed = marginPosition.borrowed.mul(borrowIndex).div(marginPosition.borrowIndex);
    (, uint256 losses) = _getPositionLosses(
      _getOptionCost(
        params.isPut,
        params.strike,
        params.expiry,
        marginPosition.amount,
        OptionPool(params.optionPool),
        OptionPoolBroker(dopex.getAddress('OptionPoolBroker'))
      ),
      params.collateral,
      collateralUsdtAmount,
      borrowed,
      _getDebt(marginPosition.borrowed, marginPosition.leverage, marginPosition.borrowIndex)
    );
    require(losses > 0, 'Margin: Position must have losses');
    uint256 repayAmount = collateralUsdtAmount.mul(liquidationIncentive).div(
      maxLiquidationIncentive
    );
    borrowed = repayAmount > borrowed ? 0 : borrowed.sub(repayAmount);
    uint256 liquidated;
    if (borrowed > 0) {
      liquidated = usdt.balanceOf(address(this));
      OptionPoolBroker(dopex.getAddress('OptionPoolBroker')).liquidate(
        params.expiry,
        marginPosition.amount,
        borrowed,
        params.strike,
        OptionPool(params.optionPool).timePeriod(),
        params.isPut,
        address(OptionPool(params.optionPool).baseAsset()),
        address(usdt)
      );
      liquidated = usdt.balanceOf(address(this)).sub(liquidated);
    }
    totalBorrows = totalBorrows.sub(repayAmount.add(liquidated));
    usdt.safeTransferFrom(msg.sender, address(this), repayAmount);
    _transferCollateralOut(msg.sender, params.collateral, marginPosition.collateralAmount);
    delete marginPositions[params.user][positionId];
  }

  /// @notice Accrues interest since the last accrualTimestamp
  /// @dev totalBorrows = previousValue * (1 + borrowRate * seconds)
  function accrueInterest() public {
    if (block.timestamp <= accrualTimestamp) {
      return;
    }
    uint256 simpleInterestFactor = borrowRate().mul(block.timestamp.sub(accrualTimestamp));
    uint256 interestAccumulated = totalBorrows.mul(simpleInterestFactor).div(1e18);
    accrualTimestamp = block.timestamp;
    borrowIndex = borrowIndex.add(simpleInterestFactor.mul(borrowIndex).div(1e18));
    totalBorrows = totalBorrows.add(interestAccumulated);
    totalReserves = totalReserves.add(reserveFactor.mul(interestAccumulated).div(1e18));
  }

  /*==== VIEWS ====*/

  /// @notice USDT balance currently available for withdrawals or purchasing options
  /// @dev Subtracts USDT being used as collateral from the USDT balance
  /// @return USDT amount
  function freeFunds() public view returns (uint256) {
    return usdt.balanceOf(address(this)).sub(totalUsdtCollateral);
  }

  /// @notice Total USDT in the margin pool
  /// @dev Adds amount of USDT lent out to, the available balance and subtracts reserves
  /// @return USDT amount
  function totalFunds() public view returns (uint256) {
    return freeFunds().add(totalBorrows).sub(totalReserves);
  }

  /// @notice Returns the current borrow rate per second
  /// @return Borrow rate
  function borrowRate() public view returns (uint256) {
    return interestRateModel.getBorrowRate(freeFunds(), totalBorrows, totalReserves);
  }

  /// @notice Returns the current supply rate per second
  /// @return Borrow rate
  function supplyRate() public view returns (uint256) {
    return interestRateModel.getSupplyRate(freeFunds(), totalBorrows, totalReserves, reserveFactor);
  }

  /// @notice Returns list of supported collaterals
  /// @return list of collaterals
  function getCollaterals() public view returns (address[] memory) {
    return collaterals;
  }

  /// @notice Generates an ID for a margin position
  /// @param isPut Whether put/call options are to be purchased
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  /// @param optionPool Address of option pool
  /// @param collateral Collateral type
  /// @return ID of margin position
  function generatePositionId(
    bool isPut,
    uint256 strike,
    uint256 expiry,
    address optionPool,
    address collateral
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(isPut, strike, expiry, optionPool, collateral));
  }

  /*==== INTERNAL FUNCTIONS ====*/

  /// @notice Transfer collateral from the user to this contract
  /// @dev Used when opening or adding to a margin position
  /// @param sender msg.sender
  /// @param collateral Asset address
  /// @param collateralAmount Asset amount
  function _transferCollateralIn(
    address sender,
    address collateral,
    uint256 collateralAmount
  ) internal {
    if (collateral == address(usdt)) {
      totalUsdtCollateral = totalUsdtCollateral.add(collateralAmount);
    }
    IERC20(collateral).safeTransferFrom(sender, address(this), collateralAmount);
  }

  /// @notice Transfer collateral from this contract to the user
  /// @dev Used when opening or adding to a margin position
  /// @param to Address to transfer to
  /// @param collateral Asset address
  /// @param collateralAmount Asset amount
  function _transferCollateralOut(
    address to,
    address collateral,
    uint256 collateralAmount
  ) internal {
    if (collateral == address(usdt)) {
      totalUsdtCollateral = totalUsdtCollateral.sub(collateralAmount);
    }
    IERC20(collateral).safeTransfer(to, collateralAmount);
  }

  /// @notice Gets the current value of options
  /// @param isPut Whether put/call options are to be purchased
  /// @param strike Strike price to purchase
  /// @param expiry Expiry timestamp
  /// @param amount Amount of options
  /// @param optionPool Option pool contract
  /// @param optionPoolBroker OptionPoolBroker contract
  /// @return Value of options
  function _getOptionCost(
    bool isPut,
    uint256 strike,
    uint256 expiry,
    uint256 amount,
    OptionPool optionPool,
    OptionPoolBroker optionPoolBroker
  ) internal view returns (uint256) {
    uint256 optionPrice = optionPoolBroker.getOptionPrice(
      isPut,
      expiry,
      strike,
      address(optionPool)
    );
    return
      optionPrice.mul(amount).mul(10**uint256(usdt.decimals())).div(strikePrecision).div(
        optionPool.baseAssetPrecision()
      );
  }

  /// @notice Gets the value of the collateral in terms of USDT
  /// @param collateral Address of asset
  /// @param collateralAmount Amount of asset
  /// @return USDT value of collateral amount
  function _getCollateralUsdtAmount(address collateral, uint256 collateralAmount)
    internal
    view
    returns (uint256)
  {
    if (collateral == address(usdt)) {
      return collateralAmount;
    } else {
      uint256 price = IDopexOracle(dopex.getAddress('DopexOracle')).getLastPrice(
        IERC20(collateral).symbol(),
        usdt.symbol()
      );
      return collateralAmount.mul(price).div(10**uint256(usdt.decimals()));
    }
  }

  /// @notice Gets debt owed on a position
  /// @param borrowed Amount of USDT borrowed for the position
  /// @param leverage Leverage of the position
  /// @param _borrowIndex Borrow index of the position
  /// @return USDT value of collateral amount
  function _getDebt(
    uint256 borrowed,
    uint256 leverage,
    uint256 _borrowIndex
  ) internal view returns (uint256) {
    uint256 debt = borrowed.mul(minLeverage).div(leverage);
    return debt.mul(borrowIndex).div(_borrowIndex);
  }

  function _getPositionLosses(
    uint256 optionCost,
    address collateral,
    uint256 collateralUsdtAmount,
    uint256 borrowed,
    uint256 debt
  ) internal view returns (bool, uint256) {
    uint256 collateralValue = collateralUsdtAmount.mul(minCollateralizationRatio).div(
      collateralAssets[collateral].collateralizationRatio
    );
    uint256 liquidationValue = collateralUsdtAmount.mul(minCollateralizationRatio).div(
      collateralAssets[collateral].liquidationRatio
    );
    bool invalid;
    uint256 losses;
    if (collateralValue < debt) {
      invalid = true;
    }
    if (liquidationValue < debt) {
      invalid = true;
      losses = losses.add(debt.sub(liquidationValue));
    }
    if (optionCost < borrowed) {
      uint256 optionLosses = borrowed.sub(optionCost);
      if (optionLosses > collateralUsdtAmount) {
        invalid = true;
        losses = losses.add(optionLosses.sub(collateralUsdtAmount));
      }
    }
    return (invalid, losses);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

// Interfaces
import {InterestRateModel} from './interfaces/InterestRateModel.sol';

/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2
 */
contract JumpRateModelV2 is InterestRateModel {
  using SafeMath for uint256;

  /**
   * @notice The approximate seconds per year that is assumed by the interest rate model
   */
  uint256 public constant secondsPerYear = 31536000;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public immutable multiplierPerSecond;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public immutable baseRatePerSecond;

  /**
   * @notice The multiplierPerSecond after hitting a specified utilization point
   */
  uint256 public immutable jumpMultiplierPerSecond;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public immutable kink;

  /**
   * @notice Indicator that this is an InterestRateModel contract (for inspection)
   */
  bool public constant override isInterestRateModel = true;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerSecond after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  constructor(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) {
    baseRatePerSecond = baseRatePerYear.div(secondsPerYear);
    multiplierPerSecond = (multiplierPerYear.mul(1e18)).div(secondsPerYear.mul(kink_));
    jumpMultiplierPerSecond = jumpMultiplierPerYear.div(secondsPerYear);
    kink = kink_;
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per second
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per second as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view override returns (uint256) {
    return getBorrowRateInternal(cash, borrows, reserves);
  }

  /**
   * @notice Calculates the current borrow rate per second, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per second as a mantissa (scaled by 1e18)
   */
  function getBorrowRateInternal(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) internal view returns (uint256) {
    uint256 util = utilizationRate(cash, borrows, reserves);

    if (util <= kink) {
      return util.mul(multiplierPerSecond).div(1e18).add(baseRatePerSecond);
    } else {
      uint256 normalRate = kink.mul(multiplierPerSecond).div(1e18).add(baseRatePerSecond);
      uint256 excessUtil = util.sub(kink);
      return excessUtil.mul(jumpMultiplierPerSecond).div(1e18).add(normalRate);
    }
  }

  /**
   * @notice Calculates the current supply rate per second
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per second as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
  /**
   * @notice Indicator that this is an InterestRateModel contract (for inspection)
   */
  function isInterestRateModel() external view returns (bool);

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

// Contracts
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {Dopex} from '../Dopex.sol';

/**
 * @title Dopex Options Contract
 * @author Dopex
 */
contract OptionsContract is ERC20Upgradeable {
  using SafeMath for uint256;

  /// @dev The Dopex master contract
  Dopex public dopex;

  /// @dev Is this a put option contract
  bool public isPut;

  /// @dev The amount of insurance promised per doToken
  uint256 public strikePrice;

  /// @dev UNIX time.
  /// Exercise period starts at `(expiry - windowSize)` and ends at `expiry`
  uint256 internal windowSize;

  /// @dev The time of expiry of the options contract
  uint256 public expiry;

  /// @dev The time period of the option pool creating the contract
  bytes32 public poolTimePeriod;

  /// @dev The address of the base asset for the option (the underlying)
  address public baseAsset;

  /// @dev The address of the quote asset for the option (the asset the base asset is priced against)
  address public quoteAsset;

  /*==== MODIFIERS ====*/

  /**
   * @dev Throws if called Options contract is expired.
   */
  modifier notExpired() {
    require(!hasExpired(), 'Options contract expired');
    _;
  }

  /**
   * @dev Throws if not called by the option pool broker contract.
   */
  modifier onlyBroker() {
    require(
      msg.sender == dopex.getAddress('OptionPoolBroker'),
      'Only the option pool broker can invoke this function'
    );
    _;
  }

  /*==== INITIALIZE FUNCTION ====*/
  
  /**
   * @param _baseAsset The address of the base asset for the option
   * @param _quoteAsset The address of the quote asset for the option
   * @param _isPut Whether the options is a put option
   * @param _strikePrice The amount of strike asset that will be paid out per doToken
   * @param _expiry The time at which the insurance expires
   * @param _windowSize UNIX time. Exercise window is from `expiry - _windowSize` to `expiry`.
   * @param _poolTimePeriod Time period of the option pool minting the options
   * @param _dopexAddress Address of the dopex master contract
   */
  function initialize(
    address _dopexAddress,
    address _baseAsset,
    address _quoteAsset,
    bool _isPut,
    uint256 _strikePrice,
    uint256 _expiry,
    uint256 _windowSize,
    bytes32 _poolTimePeriod,
    string memory _symbol
  ) public initializer {
    require(block.timestamp < _expiry, "Can't deploy an expired contract");
    require(_windowSize <= _expiry, "Exercise window can't be longer than the contract's lifespan");
    dopex = Dopex(_dopexAddress);
    baseAsset = _baseAsset;
    quoteAsset = _quoteAsset;
    isPut = _isPut;
    strikePrice = _strikePrice;
    expiry = _expiry;
    windowSize = _windowSize;
    poolTimePeriod = _poolTimePeriod;

    __ERC20_init('Dopex Option Token', _symbol);
  }

  /*==== VIEWS ====*/

  /**
   * @notice Returns true if the doToken contract has expired
   */
  function hasExpired() public view returns (bool) {
    return (block.timestamp >= expiry);
  }

  /**
   * @notice Returns true if exercise can be called
   */
  function isExerciseWindow() external view returns (bool) {
    return ((block.timestamp >= expiry.sub(windowSize)) && (block.timestamp < expiry));
  }

  /**
   * @notice This function calculates and returns the amount of options minted by the vault
   */
  function getDoTokensIssued() external view returns (uint256) {
    return totalSupply();
  }

  /*==== BROKER FUNCTIONS ====*/

  /**
   * @notice allows the OptionPoolBroker to burn doTokens of a user
   * @dev this is used in the event of excersing or a liquidation via the margin contract\
   * NOTE: only want to call this function before expiry. After expiry, no benefit to calling it.
   * @param amtToBurn number of doTokens to burn
   * @param user the address of the user from which the doTokens should be burned from
   * @return boolean which represents whether the operation was successful or not
   */
  function burnDoTokens(uint256 amtToBurn, address user)
    external
    notExpired
    onlyBroker
    returns (bool)
  {
    _burn(user, amtToBurn);

    emit BurnDoTokens(user, amtToBurn);

    return true;
  }

  /**
   * @notice This function is used for issuing new doTokens. Can be only called by the OptionPoolBroker.
   * @param _doTokens The  amount of doTokens that will be minted
   * @param user The address of the user who will recieve the tokens
   * @return boolean which represents whether the operation was successful or not
   */
  function issueDoTokens(uint256 _doTokens, address user)
    external
    notExpired
    onlyBroker
    returns (bool)
  {
    // mint tokens for user
    _mint(user, _doTokens);

    emit IssuedDoTokens(user, _doTokens);

    return true;
  }

  /*==== EVENTS ====*/

  event IssuedDoTokens(address issuedTo, uint256 doTokensIssued);

  event BurnDoTokens(address vaultOwner, uint256 doTokensBurned);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

// Libraries
import {OptionPoolHelper} from '../libraries/OptionPoolHelper.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

// Contracts
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {OptionsContract} from './OptionsContract.sol';
import {Dopex} from '../Dopex.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

contract OptionsFactory is Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  /// @dev The address of the Dopex master contract
  Dopex public dopex;

  address public immutable implementationAddress;

  /// @dev The list of optionsContracts created
  address[] public optionsContracts;

  /// @dev The list of supported tokens
  mapping(string => address) public tokens;

  /// @dev The mapping of optionsContractId to the OptionsContract address
  mapping(bytes32 => address) public optionsContractIdToAddress;

  /// @dev The mapping of the permitted OptionPools (that can create new OptionsContracts)
  mapping(address => bool) public optionPool;

  /*==== MODIFIERS ====*/

  /**
   * @dev Reverts if not called by a whitelisted option pool
   */
  modifier onlyWhitelistedOptionPool() {
    require(optionPool[msg.sender], 'Options pool is not whitelisted');
    _;
  }

  /**
   * @dev Reverts if not called by the dopex contract.
   */
  modifier onlyDopex() {
    require(msg.sender == address(dopex), 'Sender must be dopex');
    _;
  }

  /*==== CONSTRUCTOR ====*/

  constructor(address dopexAddress) {
    dopex = Dopex(dopexAddress);
    implementationAddress = address(new OptionsContract());
  }

  /*==== OWNER FUNCTIONS ====*/

  /**
   * @notice The owner can call this to set the address of the Dopex master contract
   * @param _dopex Address of the Dopex master contract
   */
  function setDopex(address _dopex) external onlyOwner {
    require(_dopex != address(0), 'Invalid address');
    dopex = Dopex(_dopex);
    emit SetDopex(_dopex);
  }

  /*==== ONLY DOPEX FUNCTIONS ====*/

  /**
   * @notice The owner of the Factory Contract can add a new asset to be supported
   * @dev admin don't add ETH. ETH is set to 0x0.
   * @param _asset The ticker symbol for the asset
   * @param _addr The address of the asset
   */
  function addAsset(string memory _asset, address _addr) external onlyDopex {
    require(!supportsAsset(_asset), 'Asset already added');
    require(_addr != address(0), 'Cannot set to address(0)');

    tokens[_asset] = _addr;
    emit AssetAdded(_asset, _addr);
  }

  /**
   * @notice The owner of the Factory Contract can delete an existing asset's address
   * @param _asset The ticker symbol for the asset
   */
  function deleteAsset(string memory _asset) external onlyDopex {
    require(tokens[_asset] != address(0), 'Trying to delete a non-existent asset');

    tokens[_asset] = address(0);
    emit AssetDeleted(_asset);
  }

  /*==== OTHER FUNCTIONS ====*/

  /**
   * @notice Allows owner addresses to add a new OptionPool contract address
   * @dev Reverts if not called by the dopex contract
   * @param _optionPool OptionPool contract address
   * @return Whether the OptionPool contract address was added
   */
  function addOptionPool(address _optionPool) external returns (bool) {
    require(
      msg.sender == dopex.getAddress('OptionPoolFactory'),
      'Sender must be option pool factory.'
    );
    // Do not allow address to be changed
    require(!optionPool[_optionPool], 'Option pool already registered');
    // Set options pool contract
    optionPool[_optionPool] = true;
    // Emit set options pool event
    emit LogNewOptionPool(_optionPool);
    return true;
  }

  /**
   * @notice Creates a new Option Contract
   * @param _baseAssetSymbol The symbol of the base asset for the option
   * @param _quoteAssetSymbol The symbol of the quote asset for the option
   * @param isPut Is put options contract
   * @param _strikePrice The amount of strike asset that will be paid out
   * @param _expiry The time at which the insurance expires
   * @param _windowSize UNIX time. Exercise window is from `expiry - _windowSize` to `expiry`
   * @param _timePeriod Time period of the option pool the options contract belongs to
   */
  function createOptionsContract(
    string memory _baseAssetSymbol,
    string memory _quoteAssetSymbol,
    bool isPut,
    uint256 _strikePrice,
    uint256 _expiry,
    uint256 _windowSize,
    bytes32 _timePeriod
  ) external onlyWhitelistedOptionPool returns (address) {
    require(_expiry > block.timestamp, 'Cannot create an expired option');
    require(_windowSize <= _expiry, 'Invalid _windowSize');
    require(supportsAsset(_baseAssetSymbol), 'Base asset not supported');
    require(supportsAsset(_quoteAssetSymbol), 'Quote asset not supported');

    string memory _symbol = concatenate(_baseAssetSymbol, '-');
    _symbol = concatenate(_symbol, _strikePrice.div(1e8).toString());
    if (isPut) {
      _symbol = concatenate(_symbol, '-PUT-');
    } else {
      _symbol = concatenate(_symbol, '-CALL-');
    }
    _symbol = concatenate(_symbol, _expiry.toString());

    OptionsContract _optionsContract = OptionsContract(Clones.clone(implementationAddress));

    _optionsContract.initialize(
      address(dopex),
      tokens[_baseAssetSymbol],
      tokens[_quoteAssetSymbol],
      isPut,
      _strikePrice,
      _expiry,
      _windowSize,
      _timePeriod,
      _symbol
    );

    optionsContracts.push(address(_optionsContract));

    optionsContractIdToAddress[
      OptionPoolHelper.generateOptionContractId(isPut, _expiry, _strikePrice, msg.sender)
    ] = address(_optionsContract);

    emit OptionsContractCreated(address(_optionsContract));

    return address(_optionsContract);
  }

  /*==== VIEWS ====*/

  /**
   * @notice The number of Option Contracts that the Factory contract has stored
   */
  function getNumberOfOptionsContracts() external view returns (uint256) {
    return optionsContracts.length;
  }

  /**
   * @notice Check if the Factory contract supports a specific asset
   * @param _asset The ticker symbol for the asset
   */
  function supportsAsset(string memory _asset) public view returns (bool) {
    return tokens[_asset] != address(0);
  }

  function concatenate(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }

  /*==== EVENTS ====*/

  event SetDopex(address _dopex);
  event OptionsContractCreated(address addr);
  event AssetAdded(string indexed asset, address indexed addr);
  event AssetDeleted(string indexed asset);
  event LogNewOptionPool(address optionPool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IOptionsFactory {
  function addOptionPool(address _optionPool) external returns (bool);

  function createOptionsContract(
    string memory _baseAssetSymbol,
    string memory _quoteAssetSymbol,
    bool isPut,
    uint256 _strikePrice,
    uint256 _expiry,
    uint256 _windowSize,
    bytes32 _timePeriod
  ) external returns (address);

  function addAsset(string memory _asset, address _addr) external;

  function changeAsset(string memory _asset, address _addr) external;

  function deleteAsset(string memory _asset) external;

  function supportsAsset(string memory _asset) external view returns (bool);

  function optionsContractIdToAddress(bytes32 optionsContractId) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IDopexOracle {
  /**
   * Gets the last price for a base and quote asset pair (using their symbols) via Chainlink nodes
   * @param baseSymbol Base token symbol
   * @param quoteSymbol Quote token symbol
   * @return Last price of base/quote pair
   */
  function getLastPrice(string memory baseSymbol, string memory quoteSymbol)
    external
    view
    returns (uint256);

  /**
   * Gets the price at timestamp for a base and quote asset pair (using their symbols and the timestamp) via Chainlink nodes
   * @param baseSymbol Base token symbol
   * @param quoteSymbol Quote token symbol
   * @param timestamp Timestamp
   * @return Price at timestamp of base/quote pair
   */
  function getPriceAtTime(
    string memory baseSymbol,
    string memory quoteSymbol,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * Gets the implied volatility for the last hour for a base and quote asset pair (using their symbols)
   * via Chainlink nodes
   * @param baseSymbol Base token symbol
   * @param quoteSymbol Quote token symbol
   * @return Implied volatility of base/quote pair for the last hour
   */
  function getImpliedVolatility(string memory baseSymbol, string memory quoteSymbol)
    external
    view
    returns (uint256);

  /**
   * Gets the rDPX price at the epoch expiry timestamp provided
   * @param epochExpiry Timestamp of the epoch expiry
   * @return rDPX price in 1e8 precision
   */
  function getRdpxPrice(uint256 epochExpiry) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '../libraries/SafeERC20.sol';
import {OptionPoolHelper} from '../libraries/OptionPoolHelper.sol';
import {BokkyPooBahsDateTimeLibrary} from '../libraries/BokkyPooBahsDateTimeLibrary.sol';

// Interfaces
import {IERC20} from '../interfaces/IERC20.sol';
import {OptionsContract} from '../options/OptionsContract.sol';
import {IOptionsFactory} from '../options/interfaces/IOptionsFactory.sol';
import {IDopexOracle} from '../oracle/interfaces/IDopexOracle.sol';
import {IAssetSwapper} from '../asset-swapper/interfaces/IAssetSwapper.sol';

// Contracts
import {DopexRewards} from '../rewards/DopexRewards.sol';
import {Dopex} from '../Dopex.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/Initializable.sol';

/// @title The Option Pool template contract of the Dopex Platform.
/// @author Dopex
/// @notice Allows users to deposit/withdraw base & quote assets which can be
/// used for purchaser to buy Call & Put options respectively
contract OptionPool is Initializable {
  using BokkyPooBahsDateTimeLibrary for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @dev The base asset of the pool. Base asset is the asset for which the option is written.
  IERC20 public baseAsset;

  /// @dev The quote asset of the pool. The quote asset is the asset in which the base asset is priced at. For eg a 4000-ETH-CALL option in a ETH (base asset) / USDT (quote asset) asset pair. ETH is priced at 4000 USDT.
  IERC20 public quoteAsset;

  /// @dev The dopex master contract which contains all other addresses constituting the dopex platform.
  Dopex public dopex;

  struct PoolCheckpoint {
    uint256 lastEpochForDeposits;
    uint256 lastEpochForNetTokens;
    mapping(uint256 => uint256) basePoolDeposits;
    mapping(uint256 => uint256) quotePoolDeposits;
    mapping(uint256 => uint256) netBasePoolTokens;
    mapping(uint256 => uint256) netQuotePoolTokens;
  }
  /// @dev PoolCheckpoints
  PoolCheckpoint public poolCheckpoint;

  /// @dev Starting global epoch is the epoch in the dopex master contract when this option pool was created
  uint256 public startingGlobalEpoch;

  /// @dev Time period of the pool is the duration of each epoch in the pool. Currently can be 7 days or 28 days.
  bytes32 public timePeriod;

  /// @dev If the OptionPool is a monthly pool then get the current monthly epoch
  uint256 public monthlyEpochCount;

  /// @dev The precision of the base asset - 10 ^ (decimals of the base asset)
  uint256 public baseAssetPrecision;

  /// @dev The precision of the quote asset - 10 ^ (decimals of the quote asset)
  uint256 public quoteAssetPrecision;

  /// @dev The precision in which the strike price is received
  /// IMPORTANT: This precision is currently used for all pricing related variables
  /// like current price (which we get from the DopexOracle contract), strike price etc
  uint256 public constant strikePrecision = 1e8;

  /// @dev Maximum maxPriceDeviation value allowed
  uint256 public constant MAX_DEVIATION = 1e4;

  /// @dev Whether the pool is shutdown or not.
  /// IMPORTANT: Once a pool is shutdown, all purchasing and depositing is paused and can users can withdraw their funds from the ppol
  bool public isPoolShutdown = false;

  /// @dev The max amount the AssetSwapper swap price is allowed to deviate from the oracle price
  uint256 public maxPriceDeviation;

  /// @dev monthly epoch => the monthly epoch start time
  mapping(uint256 => uint256) public monthlyEpochStartTimes;

  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userBasePoolFunds;

  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userQuotePoolFunds;

  /// @dev epoch => amount
  mapping(uint256 => uint256) public basePoolFunds;

  /// @dev epoch => amount
  mapping(uint256 => uint256) public quotePoolFunds;

  /// @dev epoch => amount
  /// IMPORTANT: basePoolSwaps will represent the total base assets that have been bought back for every
  /// epoch from all the call option exercises and revenue collected (from selling the options)
  mapping(uint256 => uint256) public basePoolSwaps;

  /// @notice Total pool withdrawal requests for an epoch for the base asset
  /// @dev epoch => amount
  mapping(uint256 => uint256) public totalBasePoolWithdrawalRequests;

  /// @notice Total pool withdrawals for an epoch for the base asset
  /// @dev epoch => amount
  mapping(uint256 => uint256) public totalBasePoolWithdrawals;

  /// @notice Base asset withdrawal requests for an epoch
  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userBaseWithdrawalRequests;

  /// @notice Base asset withdrawals by address for an epoch
  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userBaseWithdrawals;

  /// @notice Total pool withdrawal requests for an epoch for the quote asset
  /// @dev epoch => amount
  mapping(uint256 => uint256) public totalQuotePoolWithdrawalRequests;

  /// @notice Total pool withdrawals for an epoch for the quote asset
  /// @dev epoch => amount
  mapping(uint256 => uint256) public totalQuotePoolWithdrawals;

  /// @notice Quote asset withdrawal requests for an epoch
  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userQuoteWithdrawalRequests;

  /// @notice Quote token withdrawals by address for an epoch
  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userQuoteWithdrawals;

  /// @notice Expired epoch settlement prices
  /// @dev epoch => settlement price of base asset
  mapping(uint256 => uint256) public expiredEpochSettlementPrices;

  /// @notice Settlement price of rDPX for epochs
  /// @dev epoch => settlement price of rDPX
  mapping(uint256 => uint256) public expiredEpochRdpxSettlementPrices;

  /// @notice Options contracts by epoch
  /// @dev epoch => array of OptionsContract address
  mapping(uint256 => address[]) public optionsContractsByEpoch;

  /// @notice Total base tokens that were sent back to the buyer when a
  /// call option is exercised without providing the underlying
  /// @dev expiry => amount
  mapping(uint256 => uint256) public totalBaseTokensSentFromCallOptionExercises;

  /// @notice Total quote tokens that were sent back to the buyer when a
  /// put option is exercised (amount of options * strike)
  /// @dev expiry - amount
  mapping(uint256 => uint256) public totalQuoteTokensSentFromPutOptionExercises;

  /// @notice Is pool ready for next epoch
  /// @dev epoch => whether the pool is ready (boostrapped)
  mapping(uint256 => bool) public isPoolReady;

  /// @notice Collateral locked for each OptionsContract
  /// @dev OptionsContract address => collateral locked
  mapping(address => uint256) public collateralLockedForOptionsContract;

  struct OptionsStatistics {
    uint256 expiry;
    uint256 totalExercised;
    uint256 totalBaseAssetsLockedAsCollateral;
    uint256 totalQuoteAssetsLockedAsCollateral;
    uint256 totalCallRevenue;
    uint256 totalCallBaseRevenue; // From (Exercise Fees)
    uint256 totalPutRevenue;
  }

  /// @dev epoch => OptionsStatistics
  mapping(uint256 => OptionsStatistics) public optionsStatistics;

  struct UserCheckpoint {
    uint256 lastEpoch;
    mapping(uint256 => bool) hasCheckpoint;
    mapping(uint256 => uint256) basePoolDeposits;
    mapping(uint256 => uint256) quotePoolDeposits;
  }

  /// @dev user => UserCheckpoint
  mapping(address => UserCheckpoint) public userCheckpoints;

  /*==== INITIALIZE FUNCTION ====*/

  function initialize(
    address _baseAsset,
    address _quoteAsset,
    address _dopex,
    uint256 _startingGlobalEpoch,
    bytes32 _timePeriod
  ) public initializer {
    baseAsset = IERC20(_baseAsset);
    quoteAsset = IERC20(_quoteAsset);
    baseAssetPrecision = 10**uint256(baseAsset.decimals());
    quoteAssetPrecision = 10**uint256(quoteAsset.decimals());
    dopex = Dopex(_dopex);

    require(_timePeriod == keccak256('weekly') || _timePeriod == keccak256('monthly'), 'E0');

    // Starting epoch for pool since Dopex.sol would store global epoch
    require(_startingGlobalEpoch > getCurrentGlobalWeeklyEpoch(), 'E1');

    startingGlobalEpoch = _startingGlobalEpoch;
    timePeriod = _timePeriod;

    uint256 _maxPriceDeviation = 0.99e4; // 1%
    maxPriceDeviation = _maxPriceDeviation;
    SetMaxPriceDevation(_maxPriceDeviation);
  }

  /*==== UTILITY FUNCTIONS ====*/

  /// @notice Changes the pool shutdown status. Can only be called by governance.
  /// @dev Once a pool is shutdown, all purchasing and depositing is paused and can users can withdraw their funds from the pool
  /// @param isShutdown Shutdown status
  /// @return Whether the pool's shutdown was successfully changed
  function changePoolShutdownStatus(bool isShutdown) external returns (bool) {
    require(msg.sender == dopex.governance(), 'E18');
    isPoolShutdown = isShutdown;
    return true;
  }

  /// @notice Changes the max price deviation the swap price can have from the oracle price during bootstrapping
  /// @dev _maxPriceDeviation must be less than or equal to the MAX_DEVIATION
  /// @param _maxPriceDeviation Shutdown status
  /// @return Whether the pool's max price deviatino was successfully changed
  function setMaxPriceDeviation(uint256 _maxPriceDeviation) external returns (bool) {
    require(msg.sender == dopex.governance(), 'E18');
    require(_maxPriceDeviation <= MAX_DEVIATION, 'E60');
    maxPriceDeviation = _maxPriceDeviation;
    SetMaxPriceDevation(_maxPriceDeviation);
    return true;
  }

  /**
   * @notice Checks if the expiry passed is valid for the current epoch
   * @param _expiry Expiry unix timestamp in seconds
   * @return whether expiry is valid
   */
  function isValidExpiry(uint256 _expiry) external view returns (bool) {
    if (
      OptionPoolHelper.isAt8Am(_expiry) &&
      isWithinEpoch(_expiry, getCurrentEpoch()) &&
      (_expiry > block.timestamp)
    ) {
      return true;
    }
    return false;
  }

  /**
   * @notice Returns whether the timestamp passed is in the epoch passed
   * @param timestamp Timestamp
   * @param epoch Epoch
   * @return Whether timestamp is passed is in the epoch passed
   */
  function isWithinEpoch(uint256 timestamp, uint256 epoch) public view returns (bool) {
    (uint256 start, uint256 end) = getEpochTimes(epoch);
    return timestamp > start && timestamp <= end;
  }

  /**
   * @notice Returns whether the epoch passed has expired
   * @param epoch Epoch
   * @return Whether the epoch is expired or not
   */
  function isEpochExpired(uint256 epoch) public view returns (bool) {
    return expiredEpochSettlementPrices[epoch] > 0;
  }

  /**
   * @notice Returns start and end times for an epoch
   * @param epoch Target epoch
   * @return start The start timestamp
   * @return end The end timestamp
   */
  function getEpochTimes(uint256 epoch) public view returns (uint256 start, uint256 end) {
    require(epoch > 0, 'E19');
    if (timePeriod == keccak256('weekly')) {
      uint256 globalIndexedEpoch = startingGlobalEpoch.add(epoch).sub(1);
      return dopex.getWeeklyEpochTimes(globalIndexedEpoch);
    } else {
      return dopex.getMonthlyEpochTimes(monthlyEpochStartTimes[epoch]);
    }
  }

  /**
   * @dev Returns the current pool epoch based on epoch init time
   * IMPORTANT: OptionPool time period and current global epoch are 1-indexed
   * @return Current pool epoch number
   */
  function getCurrentEpoch() public view returns (uint256) {
    if (timePeriod == keccak256('weekly')) {
      uint256 currentGlobalWeeklyEpoch = getCurrentGlobalWeeklyEpoch();
      if (currentGlobalWeeklyEpoch == 0 || startingGlobalEpoch > currentGlobalWeeklyEpoch) return 0;
      else return currentGlobalWeeklyEpoch.sub(startingGlobalEpoch) + 1;
    } else if (timePeriod == keccak256('monthly')) {
      return monthlyEpochCount;
    } else {
      return 0;
    }
  }

  /**
   * @notice Returns an options contract address give it's id
   * @param optionsContractId Options contract ID
   * @return Options contract address
   */
  function getOptionsContractAddress(bytes32 optionsContractId) public view returns (address) {
    return
      IOptionsFactory(dopex.getAddress('OptionsFactory')).optionsContractIdToAddress(
        optionsContractId
      );
  }

  /**
   * @notice Returns the OptionsContract ID address give it's id
   * @param _isPut isPut
   * @param _expiry expiry
   * @param _strike strike
   * @return OptionsContract ID
   */
  function generateOptionContractId(
    bool _isPut,
    uint256 _expiry,
    uint256 _strike
  ) public view returns (bytes32) {
    return OptionPoolHelper.generateOptionContractId(_isPut, _expiry, _strike, address(this));
  }

  /**
   * @dev Helper function to get the current global weekly epoch from the dopex master contract
   * @return The epoch no. of the current global weekly epoch
   */
  function getCurrentGlobalWeeklyEpoch() public view returns (uint256) {
    return dopex.getCurrentGlobalWeeklyEpoch();
  }

  /**
   * ==== BROKER FUNCTIONS ====
   * NOTE: These are functions that will be executed by the OptionPoolBroker contract.
   * These funtions mainly constitute creating OptionsContracts, locking/unlocking collateral
   * , adding/removing revenue and exercising options
   */

  /**
   * @notice Adds a new option contract to the list of options contract for this epoch
   * @param _isPut Call or Put options
   * @param _expiry Expiry timestamp
   * @param _strike Strike price of options contract
   * @return optionsContractAddress Address of deployed options contract
   */
  function getOrAddOptionsContract(
    bool _isPut,
    uint256 _expiry,
    uint256 _strike
  ) external onlyBroker returns (address optionsContractAddress) {
    bytes32 optionsContractId = generateOptionContractId(_isPut, _expiry, _strike);
    address _optionsContractAddress = getOptionsContractAddress(optionsContractId);
    if (_optionsContractAddress == address(0)) {
      optionsContractAddress = IOptionsFactory(dopex.getAddress('OptionsFactory'))
        .createOptionsContract(
          baseAsset.symbol(),
          quoteAsset.symbol(),
          _isPut,
          _strike,
          _expiry,
          1 hours, // Exercise 1 hour before expiry
          timePeriod
        );
      optionsContractsByEpoch[getCurrentEpoch()].push(optionsContractAddress);
      emit NewOptionContract(
        getCurrentEpoch(),
        _expiry,
        _strike,
        optionsContractId,
        _isPut,
        optionsContractAddress
      );
    } else {
      optionsContractAddress = _optionsContractAddress;
    }

    return optionsContractAddress;
  }

  /**
   * @notice Adds to the locked collateral funds value for an OptionsContract
   * @param isPut Call or put pool (base or quote asset)
   * @param optionsContract The OptionsContract address
   * @param amount Amount to transfer and update
   */
  function lockCollateralFunds(
    bool isPut,
    address optionsContract,
    uint256 amount
  ) external onlyBroker {
    uint256 epoch = getCurrentEpoch();
    if (isPut) {
      optionsStatistics[epoch].totalQuoteAssetsLockedAsCollateral = optionsStatistics[epoch]
        .totalQuoteAssetsLockedAsCollateral
        .add(amount);
    } else {
      optionsStatistics[epoch].totalBaseAssetsLockedAsCollateral = optionsStatistics[epoch]
        .totalBaseAssetsLockedAsCollateral
        .add(amount);
    }
    collateralLockedForOptionsContract[optionsContract] = collateralLockedForOptionsContract[
      optionsContract
    ].add(amount);
  }

  /**
   * @notice Removes from the locked collateral funds value for an OptionsContract
   * @param isPut Call or put pool (base or quote asset)
   * @param optionsContract The OptionsContract address
   * @param amount Amount to remove
   */
  function unlockCollateralFunds(
    bool isPut,
    address optionsContract,
    uint256 amount
  ) external onlyBroker {
    uint256 epoch = getCurrentEpoch();
    if (isPut) {
      optionsStatistics[epoch].totalQuoteAssetsLockedAsCollateral = optionsStatistics[epoch]
        .totalQuoteAssetsLockedAsCollateral
        .sub(amount);
    } else {
      optionsStatistics[epoch].totalBaseAssetsLockedAsCollateral = optionsStatistics[epoch]
        .totalBaseAssetsLockedAsCollateral
        .sub(amount);
    }
    collateralLockedForOptionsContract[optionsContract] = collateralLockedForOptionsContract[
      optionsContract
    ].sub(amount);
  }

  /**
   * @notice Adds to the revenue
   * @param isPut Call or put pool (base or quote asset)
   * @param amount Amount to add
   */
  function addRevenue(bool isPut, uint256 amount) external onlyBroker {
    uint256 epoch = getCurrentEpoch();
    if (isPut) {
      optionsStatistics[epoch].totalPutRevenue = optionsStatistics[epoch].totalPutRevenue.add(
        amount
      );
    } else {
      optionsStatistics[epoch].totalCallRevenue = optionsStatistics[epoch].totalCallRevenue.add(
        amount
      );
    }
  }

  /**
   * @notice Removes from the revenue
   * @param isPut Call or put pool (base or quote asset)
   * @param amount Amount to add
   */
  function removeRevenue(bool isPut, uint256 amount) external onlyBroker {
    uint256 epoch = getCurrentEpoch();
    if (isPut) {
      optionsStatistics[epoch].totalPutRevenue = optionsStatistics[epoch].totalPutRevenue.sub(
        amount
      );
    } else {
      optionsStatistics[epoch].totalCallRevenue = optionsStatistics[epoch].totalCallRevenue.sub(
        amount
      );
    }
    quoteAsset.safeTransfer(msg.sender, amount);
  }

  /**
   * @notice Updates the required variable when options are exercised and transfers pnl
   * @param isPut Call or put pool (base or quote asset)
   * @param amount Amount(pnl) to transfer and update
   * @param amountOfOptions No. of options being exercised
   * @param fee Fee
   * @param user Address of the user
   */
  function exercise(
    bool isPut,
    uint256 amount,
    uint256 amountOfOptions,
    uint256 fee,
    address user
  ) external onlyBroker {
    uint256 epoch = getCurrentEpoch();
    if (isPut) {
      // Account for state change
      totalQuoteTokensSentFromPutOptionExercises[
        epoch
      ] = totalQuoteTokensSentFromPutOptionExercises[epoch].add(amount);

      // Transfer PnL to user
      quoteAsset.safeTransfer(user, amount);

      // 70% of fee is re-added to the pool
      uint256 feeCollectedForPool = fee.mul(70).div(100);

      // Update the revenue
      optionsStatistics[epoch].totalPutRevenue = optionsStatistics[epoch].totalPutRevenue.add(
        feeCollectedForPool
      );

      // Transfer fees to governance staking contract, 30% of fee is sent to the FeeDistributor
      quoteAsset.safeTransfer(dopex.getAddress('FeeDistributor'), fee.sub(feeCollectedForPool));
    } else {
      // Account for state change
      totalBaseTokensSentFromCallOptionExercises[
        epoch
      ] = totalBaseTokensSentFromCallOptionExercises[epoch].add(amount);

      // Transfer PnL to user
      baseAsset.safeTransfer(user, amount);

      // 70% of fee is re-added to the pool
      uint256 feeCollectedForPool = fee.mul(70).div(100);

      // Update the revenue
      optionsStatistics[epoch].totalCallBaseRevenue = optionsStatistics[epoch]
        .totalCallBaseRevenue
        .add(feeCollectedForPool);

      // Transfer fees to governance staking contract, 30% of fee is sent to the FeeDistributor
      baseAsset.safeTransfer(dopex.getAddress('FeeDistributor'), fee.sub(feeCollectedForPool));
    }
    optionsStatistics[epoch].totalExercised = optionsStatistics[epoch].totalExercised.add(
      amountOfOptions
    );
  }

  /*==== EXTERNAL UPKEEP FUNCTIONS ====*/

  /// @notice Unlocks the locked collateral for an expired OptionsContract.
  /// This allows more options to be bought once an option expires
  /// @param isPut isPut
  /// @param expiry expiry
  /// @param strike strike
  /// @return The collateral that was unlocked
  function unlockExpiredOptionsContractCollateral(
    bool isPut,
    uint256 expiry,
    uint256 strike
  ) external returns (uint256) {
    bytes32 optionsContractId = generateOptionContractId(isPut, expiry, strike);

    address optionsContractAddress = getOptionsContractAddress(optionsContractId);

    // Check if the OptionsContract exists
    require(optionsContractAddress != address(0), 'E54');

    // Check if the option has expired
    require(OptionsContract(optionsContractAddress).hasExpired(), 'E52');

    uint256 epoch = getCurrentEpoch();

    // Check if the expiry of the option is within the current epoch.
    // One should not be able to unlock collateral for options of a previous epoch.
    require(isWithinEpoch(expiry, epoch), 'E55');

    uint256 collateralLocked = collateralLockedForOptionsContract[optionsContractAddress];

    // Check if the collateral locked is more than 0
    require(collateralLocked > 0, 'E53');

    // Remove the collateral locked from the total collateral locked (this allows more options to be bought)
    if (isPut) {
      optionsStatistics[epoch].totalQuoteAssetsLockedAsCollateral = optionsStatistics[epoch]
        .totalQuoteAssetsLockedAsCollateral
        .sub(collateralLocked);
    } else {
      optionsStatistics[epoch].totalBaseAssetsLockedAsCollateral = optionsStatistics[epoch]
        .totalBaseAssetsLockedAsCollateral
        .sub(collateralLocked);
    }

    // Set the collateral locked for the OptionsContract to 0 so that it cannot be unlocked again
    collateralLockedForOptionsContract[optionsContractAddress] = 0;

    emit CollateralUnlock(isPut, expiry, strike, collateralLocked);

    return collateralLocked;
  }

  /// @notice Sets the previous epoch as expired.
  /// @dev Once expired, the settlement price is saved and individual option contracts can be expired.
  /// @param epoch The epoch to be expired
  /// @return Whether expire was successful
  function expireEpoch(uint256 epoch) external returns (bool) {
    (, uint256 epochExpiry) = getEpochTimes(epoch);

    // Current timestamp should be past expiry
    if (epoch > 0) {
      require((block.timestamp > epochExpiry), 'E3');
    }
    require(expiredEpochSettlementPrices[epoch] == 0, 'E42');
    uint256 settlementPrice = IDopexOracle(dopex.getAddress('DopexOracle')).getPriceAtTime(
      baseAsset.symbol(),
      quoteAsset.symbol(),
      epochExpiry
    );
    expiredEpochSettlementPrices[epoch] = settlementPrice;
    expiredEpochRdpxSettlementPrices[epoch] = IDopexOracle(dopex.getAddress('DopexOracle'))
      .getRdpxPrice(epochExpiry);

    if (timePeriod == keccak256('monthly')) {
      monthlyEpochCount = monthlyEpochCount.add(1);
      monthlyEpochStartTimes[monthlyEpochCount] = block.timestamp;
    }

    // Reward msg.sender
    DopexRewards(dopex.getAddress('DopexRewards')).claimRewardForCall(
      epoch,
      keccak256('expireEpoch'),
      msg.sender
    );

    return true;
  }

  /**
   * @notice Runs necessary functions to make sure the contract is ready for the upcoming epoch
   * @param epoch The epoch to be expired
   * @param minAmountOut Minimum token amount to receive out
   * @return Whether the bootstrapping is successful
   */
  function bootstrapOptionPool(uint256 epoch, uint256 minAmountOut) external returns (bool) {
    // Pool must not be shutdown
    require(!isPoolShutdown, 'E12');
    // Pool must not be ready
    require(!isPoolReady[epoch], 'E13');

    // Pool assets need to be repurchased only after epoch 1
    if (epoch > 1) {
      // Previous epoch must be expired
      require(isEpochExpired(epoch.sub(1)), 'E15');

      // Replenish Base/Call Pool
      replenishPoolDeposits(minAmountOut);

      // Checkpoint pool balances for previous epoch
      poolCheckpointForEpoch(epoch.sub(1));
    }

    uint256 currentEpoch = getCurrentEpoch();
    if (timePeriod == keccak256('monthly') && currentEpoch == 0) {
      monthlyEpochCount = monthlyEpochCount.add(1);
      monthlyEpochStartTimes[monthlyEpochCount] = block.timestamp;
    }

    // Mark pool as ready for epoch
    isPoolReady[epoch] = true;

    if (currentEpoch > 0) {
      // Reward msg.sender if epoch > 0
      // This wont work for epoch 0 since claim reward calculations are made from EpochInitTime which would be epoch 1
      DopexRewards(dopex.getAddress('DopexRewards')).claimRewardForCall(
        currentEpoch,
        keccak256('bootstrapOptionPool'),
        msg.sender
      );
    }

    return true;
  }

  /*==== DEPOSIT/WITHDRAW FUNCTIONS ====*/

  /**
   * @notice Allows users to deposit base/quote tokens in the option pool.
   * This will reflect for the next weekly/monthly epoch
   * @param amount Amount of collateral to add
   * @param isPut whether options are put options
   * @return Whether adding to the option pool was successful
   */
  function addToOptionPool(uint256 amount, bool isPut) external returns (bool) {
    require(isPoolShutdown != true, 'E12');

    // Must be a valid amount
    require(amount > 0, 'E16');

    uint256 nextEpoch = getCurrentEpoch().add(1);

    IERC20 collateral = IERC20(isPut ? quoteAsset : baseAsset);

    if (isPut) {
      // Add to user quote funds
      userQuotePoolFunds[msg.sender][nextEpoch] = userQuotePoolFunds[msg.sender][nextEpoch].add(
        amount
      );

      // Add to quote option pool funds
      quotePoolFunds[nextEpoch] = quotePoolFunds[nextEpoch].add(amount);
    } else {
      // Add to user base funds
      userBasePoolFunds[msg.sender][nextEpoch] = userBasePoolFunds[msg.sender][nextEpoch].add(
        amount
      );

      // Add to base option pool funds
      basePoolFunds[nextEpoch] = basePoolFunds[nextEpoch].add(amount);
    }
    userCheckpointForEpoch(msg.sender, nextEpoch);

    // Transfer tokens to this contract
    collateral.safeTransferFrom(msg.sender, address(this), amount);

    // Emit new option pool deposit event
    emit NewOptionPoolDeposit(nextEpoch, msg.sender, isPut, amount);

    return true;
  }

  /**
   * @notice Allows users to withdraw base or quote tokens for the current epoch.
   * Requires withdrawal requests to be made in the previous epoch.
   * @param isPut Withdraw is from put pool or not
   * @return Whether amount was withdrawn from pool
   */
  function withdrawFromPool(uint256 epoch, bool isPut) external returns (bool) {
    uint256 currentEpoch = getCurrentEpoch();
    require(epoch <= currentEpoch, 'E2');

    // Check if pool is ready (re-purchases have been made) to get correct calculations
    require(isPoolReady[epoch], 'E35');

    uint256 amount;

    if (isPut) {
      amount = userQuoteWithdrawalRequests[msg.sender][epoch];

      // Calculate amount of quote tokens withdraw-able for epoch
      uint256 totalQuoteTokensForWithdrawal = amount
        .mul(getTotalNetQuotePoolTokensUntilEpoch(epoch))
        .div(getTotalQuotePoolDeposits(epoch));

      // Add to user quote withdrawals for current epoch
      userQuoteWithdrawals[msg.sender][epoch] = userQuoteWithdrawals[msg.sender][epoch].add(amount);

      // Remove from user quote withdrawal requests for current epoch
      userQuoteWithdrawalRequests[msg.sender][epoch] = userQuoteWithdrawalRequests[msg.sender][
        epoch
      ].sub(amount);

      // Add to total base withdrawals for current epoch
      totalQuotePoolWithdrawals[epoch] = totalQuotePoolWithdrawals[epoch].add(amount);

      // Remove from total pool base withdrawal requests for current epoch
      totalQuotePoolWithdrawalRequests[epoch] = totalQuotePoolWithdrawalRequests[epoch].sub(amount);
      userCheckpointForEpoch(msg.sender, epoch);

      // Transfer tokens to user
      quoteAsset.safeTransfer(msg.sender, totalQuoteTokensForWithdrawal);
    } else {
      amount = userBaseWithdrawalRequests[msg.sender][epoch];

      // Calculate amount of base token withdraw-able for epoch
      uint256 totalBaseTokensForWithdrawal = amount
        .mul(getTotalNetBasePoolTokensUntilEpoch(epoch))
        .div(getTotalBasePoolDeposits(epoch));

      // Add to user base withdrawals for current epoch
      userBaseWithdrawals[msg.sender][epoch] = userBaseWithdrawals[msg.sender][epoch].add(amount);

      // Remove from user base withdrawal requests for current epoch
      userBaseWithdrawalRequests[msg.sender][epoch] = userBaseWithdrawalRequests[msg.sender][epoch]
        .sub(amount);

      // Add to total base withdrawals for current epoch
      totalBasePoolWithdrawals[epoch] = totalBasePoolWithdrawals[epoch].add(amount);

      // Remove from total pool base withdrawal requests for current epoch
      totalBasePoolWithdrawalRequests[epoch] = totalBasePoolWithdrawalRequests[epoch].sub(amount);
      userCheckpointForEpoch(msg.sender, epoch);

      // Transfer tokens to user
      baseAsset.safeTransfer(msg.sender, totalBaseTokensForWithdrawal);
    }

    // Emit log withdraw from pool event
    emit PoolFundWithdrawal(
      currentEpoch,
      msg.sender,
      amount,
      isPut // isPut
    );

    return true;
  }

  /**
   * @notice Allows users to withdraw all tokens for the current epoch from pool due to shutdown.
   * @return Whether amount was withdrawn from pool
   */
  function emergencyWithdrawFromPool() external returns (bool) {
    require(isPoolShutdown == true, 'E36');
    uint256 epoch = getCurrentEpoch();
    uint256 amount = getUserQuotePoolDepositsUntilEpoch(msg.sender, epoch, true);

    uint256 totalQuoteTokensForWithdrawal = 0;

    uint256 totalNetQuotePoolTokensUntilEpoch = getTotalNetQuotePoolTokensUntilEpoch(epoch);
    uint256 totalQuotePoolDeposits = getTotalQuotePoolDeposits(epoch);
    if (amount > 0 && totalNetQuotePoolTokensUntilEpoch > 0 && totalQuotePoolDeposits > 0) {
      // Calculate amount of quote tokens withdraw-able for epoch
      totalQuoteTokensForWithdrawal = amount.mul(totalNetQuotePoolTokensUntilEpoch).div(
        totalQuotePoolDeposits
      );

      // Add to user quote withdrawals for current epoch
      userQuoteWithdrawals[msg.sender][epoch] = userQuoteWithdrawals[msg.sender][epoch].add(amount);

      // Add to total base withdrawals for current epoch
      totalQuotePoolWithdrawals[epoch] = totalQuotePoolWithdrawals[epoch].add(amount);

      userCheckpointForEpoch(msg.sender, epoch);
    }

    amount = getUserBasePoolDepositsUntilEpoch(msg.sender, epoch, true);

    uint256 totalBaseTokensForWithdrawal = 0;

    uint256 totalNetBasePoolTokensUntilEpoch = getTotalNetBasePoolTokensUntilEpoch(epoch);
    uint256 totalBasePoolDeposits = getTotalBasePoolDeposits(epoch);
    if (amount > 0 && totalNetBasePoolTokensUntilEpoch > 0 && totalBasePoolDeposits > 0) {
      // Calculate amount of base token withdraw-able for epoch
      totalBaseTokensForWithdrawal = amount.mul(totalNetBasePoolTokensUntilEpoch).div(
        totalBasePoolDeposits
      );

      // Add to user base withdrawals for current epoch
      userBaseWithdrawals[msg.sender][epoch] = userBaseWithdrawals[msg.sender][epoch].add(amount);

      // Add to total base withdrawals for current epoch
      totalBasePoolWithdrawals[epoch] = totalBasePoolWithdrawals[epoch].add(amount);

      userCheckpointForEpoch(msg.sender, epoch);
    }

    // Transfer quote tokens to user
    quoteAsset.safeTransfer(msg.sender, totalQuoteTokensForWithdrawal);

    // Transfer base tokens to user
    baseAsset.safeTransfer(msg.sender, totalBaseTokensForWithdrawal);

    // Emit log withdraw from pool event for quote tokens
    emit PoolFundWithdrawal(
      epoch,
      msg.sender,
      totalQuoteTokensForWithdrawal,
      true // isPut
    );

    // Emit log withdraw from pool event for base tokens
    emit PoolFundWithdrawal(
      epoch,
      msg.sender,
      totalBaseTokensForWithdrawal,
      false // isPut
    );

    return true;
  }

  /**
   * @notice Allows users to create a withdraw request for deposited assets from a pool after epoch expiry
   * @param amount Amount of base/quote asset to withdraw (*not* net base/quote asset)
   * @param isPut Whether the withdrawal requests is for the put pool
   * @return Whether withdraw requests were created for next epoch
   */
  function createWithdrawRequestForPool(uint256 amount, bool isPut) external returns (bool) {
    uint256 nextEpoch = getCurrentEpoch().add(1);
    if (isPut) {
      // Get user quote deposits until next epoch
      uint256 userQuotePoolDepositsUntilNextEpoch = getUserQuotePoolDepositsUntilEpoch(
        msg.sender,
        nextEpoch,
        false
      );

      // User must have quote deposits greater than or equal to amount
      require(userQuotePoolDepositsUntilNextEpoch >= amount, 'E37');

      // Add to user quote withdrawal requests for next epoch
      userQuoteWithdrawalRequests[msg.sender][nextEpoch] = userQuoteWithdrawalRequests[msg.sender][
        nextEpoch
      ].add(amount);

      // Add to total pool quote withdrawal requests for next epoch
      totalQuotePoolWithdrawalRequests[nextEpoch] = totalQuotePoolWithdrawalRequests[nextEpoch].add(
        amount
      );
    } else {
      // Get user base deposits until next epoch
      uint256 userBasePoolDepositsUntilNextEpoch = getUserBasePoolDepositsUntilEpoch(
        msg.sender,
        nextEpoch,
        false
      );

      // User must have base deposits greater than or equal to amount
      require(userBasePoolDepositsUntilNextEpoch >= amount, 'E37');

      // Add to user base withdrawal requests for next epoch
      userBaseWithdrawalRequests[msg.sender][nextEpoch] = userBaseWithdrawalRequests[msg.sender][
        nextEpoch
      ].add(amount);

      // Add to total pool base withdrawal requests for next epoch
      totalBasePoolWithdrawalRequests[nextEpoch] = totalBasePoolWithdrawalRequests[nextEpoch].add(
        amount
      );
    }

    // Checkpoint user balances for next epoch
    userCheckpointForEpoch(msg.sender, nextEpoch);

    emit CreatePoolFundWithdrawal(
      nextEpoch.sub(1),
      msg.sender,
      amount,
      nextEpoch,
      isPut // isPut
    );

    return true;
  }

  /*==== INTERNAL FUNCTIONS ====*/

  /**
   * @dev Swaps all quote assets collected by the base pool (from option premiums) to the base asset
   * @param minAmountOut Minimum token amount to receive out
   * @return Whether pool deposits were replenished
   */
  function replenishPoolDeposits(uint256 minAmountOut) internal returns (bool) {
    uint256 epoch = getCurrentEpoch();
    // Calculate amount of quote assets to use for re-purchase
    uint256 totalBasePoolCollectibleQuoteAssets = getTotalBasePoolCollectibleQuoteAssetsForEpoch(
      epoch.sub(1)
    );

    // Purchase assets via asset swapper by passing expected price
    IAssetSwapper assetSwapper = IAssetSwapper(dopex.getAddress('AssetSwapper'));
    quoteAsset.safeApprove(address(assetSwapper), totalBasePoolCollectibleQuoteAssets);

    if (totalBasePoolCollectibleQuoteAssets == 0) return true;

    uint256 assetsPurchased = assetSwapper.swapAsset(
      address(quoteAsset),
      address(baseAsset),
      totalBasePoolCollectibleQuoteAssets,
      minAmountOut
    );

    // Get asset price from price oracle
    uint256 expectedAmount = IDopexOracle(dopex.getAddress('DopexOracle'))
      .getLastPrice(baseAsset.symbol(), quoteAsset.symbol())
      .mul(totalBasePoolCollectibleQuoteAssets)
      .div(quoteAssetPrecision);

    require(assetsPurchased >= expectedAmount.mul(maxPriceDeviation).div(MAX_DEVIATION), 'E59');

    basePoolSwaps[epoch] = assetsPurchased;

    // // Emit log replenish pool deposits event
    emit ReplenishPoolDeposits(epoch, expectedAmount, assetsPurchased);
    return true;
  }

  /*==== POOL STATISTICS FUNCTIONS ====*/

  /**
   * @notice Returns total collectible quote assets for a pool for a target epoch
   * @param epoch Target epoch
   * @return Total collectible quote assets for a pool
   */
  function getTotalBasePoolCollectibleQuoteAssetsForEpoch(uint256 epoch)
    public
    view
    returns (uint256)
  {
    return optionsStatistics[epoch].totalCallRevenue;
  }

  /// @dev Internal function to checkpoint pool deposits
  /// @param epoch epoch till which the checkout point should be made
  function poolCheckpointForEpoch(uint256 epoch) internal {
    poolCheckpoint.basePoolDeposits[epoch] = getTotalBasePoolDeposits(epoch);
    poolCheckpoint.quotePoolDeposits[epoch] = getTotalQuotePoolDeposits(epoch);
    poolCheckpoint.lastEpochForDeposits = epoch;
    poolCheckpoint.netBasePoolTokens[epoch] = getTotalNetBasePoolTokensUntilEpoch(epoch);
    poolCheckpoint.netQuotePoolTokens[epoch] = getTotalNetQuotePoolTokensUntilEpoch(epoch);
    poolCheckpoint.lastEpochForNetTokens = epoch;
  }

  /// @dev Internal function to checkpoint user deposits
  /// @param user address of the user for which the checkpoint should be made
  /// @param epoch epoch till which the checkout point should be made
  function userCheckpointForEpoch(address user, uint256 epoch) internal {
    userCheckpoints[user].basePoolDeposits[epoch] = getUserBasePoolDepositsUntilEpoch(
      user,
      epoch,
      true
    );
    userCheckpoints[user].quotePoolDeposits[epoch] = getUserQuotePoolDepositsUntilEpoch(
      user,
      epoch,
      true
    );
    userCheckpoints[user].hasCheckpoint[epoch] = true;
    userCheckpoints[user].lastEpoch = epoch;
  }

  /**
   * @notice Returns total net pool deposits for a user until a defined epoch
   * @param user Address of user
   * @param epoch Epoch until which to calculate total pool deposits
   * @param isUpdate Ignore checkpoints in case of checkpoints being updated
   * @return Total pool deposits for user
   */
  function getUserBasePoolDepositsUntilEpoch(
    address user,
    uint256 epoch,
    bool isUpdate
  ) public view returns (uint256) {
    if (userCheckpoints[user].hasCheckpoint[epoch] && !isUpdate)
      return userCheckpoints[user].basePoolDeposits[epoch];
    uint256 lastCheckpointEpoch = userCheckpoints[user].lastEpoch;
    uint256 fromEpoch;
    uint256 checkpointBasePoolDeposits;
    if (lastCheckpointEpoch < epoch) {
      fromEpoch = lastCheckpointEpoch;
      checkpointBasePoolDeposits = userCheckpoints[user].basePoolDeposits[fromEpoch];
    }
    uint256 totalDeposits = 0;
    uint256 totalWithdrawals = 0;
    uint256 totalWithdrawalRequests;
    for (uint256 i = fromEpoch + 1; i <= epoch; i++) {
      totalDeposits = totalDeposits.add(userBasePoolFunds[user][i]);
      totalWithdrawals = totalWithdrawals.add(userBaseWithdrawals[user][i]);
      totalWithdrawalRequests = totalWithdrawalRequests.add(userBaseWithdrawalRequests[user][i]);
    }
    return
      checkpointBasePoolDeposits.add(totalDeposits).sub(totalWithdrawals).sub(
        totalWithdrawalRequests
      );
  }

  /**
   * @notice Returns total net pool deposits for a user until a defined epoch
   * @param user Address of user
   * @param epoch Epoch until which to calculate total pool deposits
   * @param isUpdate Ignore checkpoints in case of checkpoints being updated
   * @return Total pool deposits for user
   */
  function getUserQuotePoolDepositsUntilEpoch(
    address user,
    uint256 epoch,
    bool isUpdate
  ) public view returns (uint256) {
    if (userCheckpoints[user].hasCheckpoint[epoch] && !isUpdate) {
      return userCheckpoints[user].quotePoolDeposits[epoch];
    }
    uint256 lastCheckpointEpoch = userCheckpoints[user].lastEpoch;
    uint256 fromEpoch;
    uint256 checkpointQuotePoolDeposits;
    if (lastCheckpointEpoch < epoch) {
      fromEpoch = lastCheckpointEpoch;
      checkpointQuotePoolDeposits = userCheckpoints[user].quotePoolDeposits[fromEpoch];
    }
    uint256 totalDeposits = 0;
    uint256 totalWithdrawals = 0;
    uint256 totalWithdrawalRequests;
    for (uint256 i = fromEpoch + 1; i <= epoch; i++) {
      totalDeposits = totalDeposits.add(userQuotePoolFunds[user][i]);
      totalWithdrawals = totalWithdrawals.add(userQuoteWithdrawals[user][i]);
      totalWithdrawalRequests = totalWithdrawalRequests.add(userQuoteWithdrawalRequests[user][i]);
    }
    return
      checkpointQuotePoolDeposits.add(totalDeposits).sub(totalWithdrawals).sub(
        totalWithdrawalRequests
      );
  }

  /**
   * @notice Returns total net pool deposits from an epoch until a defined epoch
   * @param epoch Epoch until which to calculate total pool deposits
   * @return Total base pool deposits
   */
  function getTotalBasePoolDeposits(uint256 epoch) public view returns (uint256) {
    uint256 fromEpoch = poolCheckpoint.lastEpochForDeposits;
    uint256 checkpointBasePoolDeposits = poolCheckpoint.basePoolDeposits[epoch];
    if (epoch == fromEpoch) return checkpointBasePoolDeposits;
    uint256 totalDeposits = 0;
    uint256 totalWithdrawals = 0;
    uint256 totalWithdrawalRequests = 0;
    for (uint256 i = fromEpoch; i <= epoch; i++) {
      totalDeposits = totalDeposits.add(basePoolFunds[i]);
      if (i != epoch) {
        totalWithdrawals = totalWithdrawals.add(totalBasePoolWithdrawals[i]);
        totalWithdrawalRequests = totalWithdrawalRequests.add(totalBasePoolWithdrawalRequests[i]);
      }
    }
    return
      checkpointBasePoolDeposits.add(
        totalDeposits.sub(totalWithdrawals.add(totalWithdrawalRequests))
      );
  }

  /**
   * @notice Returns total quote pool deposits until a defined epoch
   * @param epoch Epoch until which to calculate total pool deposits
   * @return Total quote pool deposits
   */
  function getTotalQuotePoolDeposits(uint256 epoch) public view returns (uint256) {
    uint256 fromEpoch = poolCheckpoint.lastEpochForDeposits;
    uint256 checkpointQuotePoolDeposits = poolCheckpoint.quotePoolDeposits[epoch];
    if (epoch == fromEpoch) return checkpointQuotePoolDeposits;
    uint256 totalDeposits = 0;
    uint256 totalWithdrawals = 0;
    uint256 totalWithdrawalRequests = 0;
    for (uint256 i = fromEpoch; i <= epoch; i++) {
      totalDeposits = totalDeposits.add(quotePoolFunds[i]);
      if (i != epoch) {
        totalWithdrawals = totalWithdrawals.add(totalQuotePoolWithdrawals[i]);
        totalWithdrawalRequests = totalWithdrawalRequests.add(totalQuotePoolWithdrawalRequests[i]);
      }
    }
    return
      checkpointQuotePoolDeposits.add(
        totalDeposits.sub(totalWithdrawals.add(totalWithdrawalRequests))
      );
  }

  /**
   * @notice Returns the total number of option exercises until a target epoch
   * @param fromEpoch Epoch from which to calculate tokens sent from exercises
   * @param toEpoch Epoch until which to calculate tokens sent from exercises
   * @param isPut Put option or not
   * @return Total number of option exercises until epoch
   */
  function getTokensSentFromExercises(
    uint256 fromEpoch,
    uint256 toEpoch,
    bool isPut
  ) public view returns (uint256) {
    require(fromEpoch <= toEpoch, 'E33');
    uint256 tokensSentFromExercises = 0;
    if (isPut) {
      for (uint256 i = fromEpoch; i <= toEpoch; i++) {
        tokensSentFromExercises = tokensSentFromExercises.add(
          totalQuoteTokensSentFromPutOptionExercises[i]
        );
      }
    } else {
      for (uint256 i = fromEpoch; i <= toEpoch; i++) {
        tokensSentFromExercises = tokensSentFromExercises.add(
          totalBaseTokensSentFromCallOptionExercises[i]
        );
      }
    }
    return tokensSentFromExercises;
  }

  /// @notice Returns the total revenue (via premiums) collected from selling put options
  /// @param fromEpoch Starting epoch
  /// @param toEpoch End epoch
  /// @return Total put revenue in uint256
  function getTotalPutRevenue(uint256 fromEpoch, uint256 toEpoch) public view returns (uint256) {
    require(fromEpoch <= toEpoch, 'E33');
    uint256 totalPutRevenue;
    for (uint256 i = fromEpoch; i <= toEpoch; i++)
      totalPutRevenue = totalPutRevenue.add(optionsStatistics[i].totalPutRevenue);
    return totalPutRevenue;
  }

  /// @notice Returns the total revenue (via exercise fees) collected from call options
  /// @param fromEpoch Starting epoch
  /// @param toEpoch End epoch
  /// @return Total call revenue in uint256
  function getTotalCallBaseRevenue(uint256 fromEpoch, uint256 toEpoch)
    public
    view
    returns (uint256)
  {
    require(fromEpoch <= toEpoch, 'E33');
    uint256 totalCallBaseRevenue;
    for (uint256 i = fromEpoch; i <= toEpoch; i++)
      totalCallBaseRevenue = totalCallBaseRevenue.add(optionsStatistics[i].totalCallBaseRevenue);
    return totalCallBaseRevenue;
  }

  /**
   * @notice Returns the number of net pool base tokens after option writing and repurchases until an epoch
   * @param epoch Target epoch
   * @return Net pool base tokens for target epoch
   */
  function getTotalNetBasePoolTokensUntilEpoch(uint256 epoch) public view returns (uint256) {
    if (poolCheckpoint.lastEpochForNetTokens >= epoch)
      return poolCheckpoint.netBasePoolTokens[epoch];
    else {
      uint256 totalBaseTokensUntilEpoch = getTotalBasePoolDeposits(epoch);
      uint256 totalSwapsUntilEpoch = getTotalSwaps(poolCheckpoint.lastEpochForNetTokens, epoch);
      uint256 totalCallBaseRevenue = getTotalCallBaseRevenue(
        poolCheckpoint.lastEpochForNetTokens,
        epoch
      );
      uint256 tokensSentFromExercises = getTokensSentFromExercises(
        poolCheckpoint.lastEpochForNetTokens,
        epoch,
        false
      );
      return
        (totalBaseTokensUntilEpoch).add(totalSwapsUntilEpoch).sub(tokensSentFromExercises).add(
          totalCallBaseRevenue
        );
    }
  }

  /**
   * @notice Returns the number of net pool base tokens for a user until an epoch
   * @param epoch Target epoch
   * @return Net pool base tokens for user until target epoch
   */
  function getTotalNetUserBasePoolTokensUntilEpoch(address user, uint256 epoch)
    external
    view
    returns (uint256)
  {
    uint256 totalBasePoolDeposits = getTotalBasePoolDeposits(epoch);
    if (totalBasePoolDeposits == 0) {
      return 0;
    }
    return
      getUserBasePoolDepositsUntilEpoch(user, epoch, false)
        .mul(getTotalNetBasePoolTokensUntilEpoch(epoch))
        .div(totalBasePoolDeposits);
  }

  /**
   * @notice Returns the number of net pool base tokens after option writing and repurchases until an epoch
   * @param epoch Target epoch
   * @return Net pool base tokens for target epoch
   */
  function getTotalNetQuotePoolTokensUntilEpoch(uint256 epoch) public view returns (uint256) {
    if (poolCheckpoint.lastEpochForNetTokens >= epoch)
      return poolCheckpoint.netQuotePoolTokens[epoch];
    else {
      uint256 totalQuoteTokensUntilEpoch = getTotalQuotePoolDeposits(epoch);
      uint256 tokensSentFromExercises = getTokensSentFromExercises(
        poolCheckpoint.lastEpochForNetTokens,
        epoch,
        true
      );
      uint256 totalPutRevenue = getTotalPutRevenue(poolCheckpoint.lastEpochForNetTokens, epoch);
      return totalQuoteTokensUntilEpoch.sub(tokensSentFromExercises).add(totalPutRevenue);
    }
  }

  /**
   * @notice Returns the total number of base token repurchases until a target epoch
   * @param fromEpoch From epoch
   * @param toEpoch To epoch
   * @return Total number of base token repurchases until epoch
   */
  function getTotalSwaps(uint256 fromEpoch, uint256 toEpoch) public view returns (uint256) {
    require(fromEpoch <= toEpoch, 'E33');
    uint256 totalSwaps;
    for (uint256 i = fromEpoch; i <= toEpoch; i++) {
      totalSwaps = totalSwaps.add(basePoolSwaps[i]);
    }
    return totalSwaps;
  }

  /**
   * @notice Returns the number of net pool quote tokens for a user until an epoch
   * @param epoch Target epoch
   * @return Net pool quote tokens for user until target epoch
   */
  function getTotalNetUserQuotePoolTokensUntilEpoch(address user, uint256 epoch)
    external
    view
    returns (uint256)
  {
    uint256 totalQuotePoolDeposits = getTotalQuotePoolDeposits(epoch);
    if (totalQuotePoolDeposits == 0) {
      return 0;
    }
    return
      getUserQuotePoolDepositsUntilEpoch(user, epoch, false)
        .mul(getTotalNetQuotePoolTokensUntilEpoch(epoch))
        .div(totalQuotePoolDeposits);
  }

  /**
   * @notice Returns available pool funds for base/quote pools
   * @param _isPut is base/quote pool
   * @return poolFunds Available funds in selected pool
   */
  function getAvailablePoolFunds(bool _isPut) external view returns (uint256 poolFunds) {
    uint256 epoch = getCurrentEpoch();
    if (_isPut) {
      poolFunds = getTotalNetQuotePoolTokensUntilEpoch(epoch).sub(
        optionsStatistics[epoch].totalQuoteAssetsLockedAsCollateral
      );
    } else {
      poolFunds = getTotalNetBasePoolTokensUntilEpoch(epoch).sub(
        optionsStatistics[epoch].totalBaseAssetsLockedAsCollateral
      );
    }
  }

  /*==== MODIFIERS ====*/

  modifier onlyBroker() {
    require(msg.sender == dopex.getAddress('OptionPoolBroker'), 'E38');
    _;
  }

  /*==== EVENTS ====*/

  event CollateralUnlock(bool isPut, uint256 expiry, uint256 strike, uint256 amount);

  event NewOptionPoolDeposit(uint256 indexed epoch, address sender, bool isPut, uint256 amount);

  event PoolFundWithdrawal(uint256 indexed epoch, address sender, uint256 amount, bool isPut);

  event CreatePoolFundWithdrawal(
    uint256 indexed epoch,
    address sender,
    uint256 amount,
    uint256 totalUserWithdrawalRequests,
    bool isPut
  );

  event ReplenishPoolDeposits(
    uint256 indexed epoch,
    uint256 expectedAmount,
    uint256 assetsPurchased
  );

  event NewOptionContract(
    uint256 indexed epoch,
    uint256 expiry,
    uint256 strike,
    bytes32 optionContractId,
    bool isPut,
    address optionContractAddress
  );

  event SetMaxPriceDevation(uint256 indexed maxPriceDeviation);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {OptionPoolBrokerLibrary} from './libraries/OptionPoolBrokerLibrary.sol';
import {OptionPoolHelper} from '../../libraries/OptionPoolHelper.sol';
import {SafeERC20} from '../../libraries/SafeERC20.sol';

// Interfaces
import {IOptionPricing} from '../interfaces/IOptionPricing.sol';
import {IOptionsFactory} from '../../options/interfaces/IOptionsFactory.sol';
import {IDopexOracle} from '../../oracle/interfaces/IDopexOracle.sol';
import {IERC20} from '../../interfaces/IERC20.sol';

// Contracts
import {OptionPool} from '../OptionPool.sol';
import {OptionPoolFactory} from '../OptionPoolFactory.sol';
import {OptionsContract} from '../../options/OptionsContract.sol';
import {OptionsFactory} from '../../options/OptionsFactory.sol';
import {VolumePoolFactory} from '../VolumePoolFactory.sol';
import {VolumePool} from '../VolumePool.sol';
import {Dopex} from '../../Dopex.sol';

contract OptionPoolBroker {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  Dopex public dopex;

  struct OptionPoolVars {
    uint256 strikeRange;
    uint256 liquidityMultiplier;
    address optionPricing;
  }

  mapping(address => OptionPoolVars) public optionPoolVars;

  /// @dev Whitelisted contracts can use a users volume pool funds on behalf of the user
  mapping(address => bool) public whitelistedContracts;

  /*==== FEES ====*/

  bytes32 public constant PURCHASE_FEE = keccak256('purchaseFee');
  bytes32 public constant PURCHASE_FEE_CAP = keccak256('purchaseFeeCap');
  bytes32 public constant EXERCISE_FEE = keccak256('exerciseFee');
  bytes32 public constant EXERCISE_FEE_CAP = keccak256('exerciseFeeCap');
  bytes32 public constant SWAP_FEE = keccak256('swapFee');
  bytes32 public constant SWAP_FEE_CAP = keccak256('swapFeeCap');
  mapping(bytes32 => uint256) public fees; // in strike precision

  uint256 constant strikePrecision = 1e8;

  /*==== MODIFIERS ====*/

  modifier onlyMargin() {
    require(msg.sender == dopex.getAddress('Margin'), 'E43');
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == dopex.governance(), 'E18');
    _;
  }

  /*==== CONSTRUCTOR ====*/

  constructor(address _dopex) {
    dopex = Dopex(_dopex);
    // All fees are in strike precision, (The fee will never be over cap (specified) of the option price)
    fees[PURCHASE_FEE] = uint256(2).mul(strikePrecision).div(100); // 0.02% of the price of the base asset
    fees[PURCHASE_FEE_CAP] = uint256(10).mul(strikePrecision); // 10% of the option price
    fees[EXERCISE_FEE] = uint256(1).mul(strikePrecision).div(100); // 0.01% of the
    fees[EXERCISE_FEE_CAP] = uint256(10).mul(strikePrecision); // 10% of the option price
    fees[SWAP_FEE] = uint256(3).mul(strikePrecision).div(100); // 0.03% of the price of the base asset
    fees[SWAP_FEE_CAP] = uint256(10).mul(strikePrecision); // 10% of the option price
  }

  /*==== SETTER FUNCTIONS ====*/

  /**
   * @notice Function to update the fees
   * @param feeKey The option pool contracts address
   * @param feeAmount The fee amount, should be in strike percentage
   * @return Whether the update was successful
   */
  function updateFees(bytes32 feeKey, uint256 feeAmount) external onlyGovernance returns (bool) {
    fees[feeKey] = feeAmount;
    return true;
  }

  /// @notice Updates strike range for an option pool
  /// @param _optionPool The address of the option pool
  /// @param _strikeRange The new strike range
  function updateStrikeRange(address _optionPool, uint256 _strikeRange) external onlyGovernance {
    optionPoolVars[_optionPool].strikeRange = _strikeRange;
  }

  /// @notice Updates liquidity multiplier for an option pool
  /// @param _optionPool The address of the option pool
  /// @param _liquidityMultiplier The new liquidity multiplier
  function updateLiquidityMultiplier(address _optionPool, uint256 _liquidityMultiplier)
    external
    onlyGovernance
  {
    optionPoolVars[_optionPool].liquidityMultiplier = _liquidityMultiplier;
  }

  /// @notice Updates option pricing contract for an option pool
  /// @param _optionPool The address of the option pool
  /// @param _optionPricing The new option pricing
  function updateOptionPricing(address _optionPool, address _optionPricing)
    external
    onlyGovernance
  {
    require(_optionPool != address(0), 'Address cannot be the zero address');
    optionPoolVars[_optionPool].optionPricing = _optionPricing;
  }

  /// @notice Adds whitelisted contracts
  /// @param contracts List of contracts add to the whitelist
  function addWhitelistedContracts(address[] calldata contracts) external onlyGovernance {
    for (uint256 i = 0; i < contracts.length; i++) {
      whitelistedContracts[contracts[i]] = true;
      emit AddWhitelistedContract(contracts[i]);
    }
  }

  /// @notice Removes whitelisted contracts
  /// @param contracts List of contracts to remove from the whitelist
  function removeWhitelistedContracts(address[] calldata contracts) external onlyGovernance {
    for (uint256 i = 0; i < contracts.length; i++) {
      whitelistedContracts[contracts[i]] = false;
      emit RemoveWhitelistedContract(contracts[i]);
    }
  }

  /*==== VIEWS ====*/

  /**
   * @notice computes the option price
   * @param isPut is put option
   * @param expiry expiry timestamp
   * @param strike strike price
   * @param optionPool the option pool address
   */
  function getOptionPrice(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    address optionPool
  ) public view returns (uint256) {
    return
      IOptionPricing(optionPoolVars[optionPool].optionPricing).getOptionPrice(
        isPut,
        expiry,
        strike,
        optionPool
      );
  }

  /// @notice Computes the liquidity multiplier for a given amount of options being written from the pool
  /// @param isSwap Whether the liquidity multiple is calculated for a swap operation
  /// @param isPut Put or Call options
  /// @param amount Amount of options being written
  /// @param strike Strike price of the option
  /// @param optionPool The OptionPool from which the option is written
  /// @return liquidityMultiple
  function computeLiquidityMultiple(
    bool isSwap,
    bool isPut,
    uint256 amount,
    uint256 strike,
    OptionPool optionPool
  ) public view returns (uint256 liquidityMultiple) {
    /**
     * Initially there is require to check if there is enough funds in the option pool to mint the options.
     * This check is done inside of the purchase but not inside of swap as when computing the liquidity multiple
     * we do not have the correct amount of options that are going to be minted in the swap.
     * This is because the final amount of tokens minted in a swap is the liquidity multiple multiplied with the
     * computed new amount of tokens subtracted from the computed amount of tokens
     * For put, required collateral is: amount * strike
     * For call, required collateral is: amount
     * Liquidity multiple formula:
     * (Collateral Required For Purchase * Liquidity Multiplier) / Available Option Pool Funds
     */
    if (isPut) {
      require(
        amount.mul(strike).mul(optionPool.quoteAssetPrecision()).div(strikePrecision).div(
          optionPool.baseAssetPrecision()
        ) <= optionPool.getAvailablePoolFunds(true),
        'E25'
      );
      // Collateral for puts is amount * strike
      liquidityMultiple = amount.mul(strike).mul(optionPool.quoteAssetPrecision()).mul(
        optionPoolVars[address(optionPool)].liquidityMultiplier
      );
      liquidityMultiple = liquidityMultiple
        .div(optionPool.getAvailablePoolFunds(true))
        .div(strikePrecision)
        .div(optionPool.baseAssetPrecision());
    } else {
      require(amount <= optionPool.getAvailablePoolFunds(false), 'E25');
      liquidityMultiple = amount.mul(optionPoolVars[address(optionPool)].liquidityMultiplier).div(
        optionPool.getAvailablePoolFunds(false)
      );
    }

    /**
     * For swaps the liquidity multiple is used to subtract from the newly computed amount of tokens.
     * For purchases the liquidity multiple is used to multiply the total option cost hence we
     * add 1 (with 1e2) precision to the multiple in purchases and in swaps we don't.
     */
    if (isSwap) {
      return liquidityMultiple;
    } else return liquidityMultiple.add(100);
  }

  /**
   * @notice Util function to calculate the total option cost (including fee) given an
   * amount of options to purchase, option price, baseAssetPrecision and quoteAssetPrecision
   * and the type of transaction(purchase/swap)
   * @param optionPrice Price of one option
   * @param amount Amount of options to be purchased
   * @param optionPool Option pool address
   * @param isSwap If the transaction is a swap. If not then it is assumed that the transaction is a purchase
   * @return returnValues [totalOptionCost, fee]
   * fee (in strike precision) & total option cost (in quote asset precision)
   */
  function getTotalOptionCost(
    uint256 optionPrice,
    uint256 amount,
    address optionPool,
    bool isSwap
  )
    public
    view
    returns (
      uint256[2] memory returnValues /* [totalOptionCost, fee] */
    )
  {
    uint256 lastPrice = IDopexOracle(dopex.getAddress('DopexOracle')).getLastPrice(
      OptionPool(optionPool).baseAsset().symbol(),
      OptionPool(optionPool).quoteAsset().symbol()
    );
    // Getting the fee for either swap or purchase
    bytes32[2] memory feeKeys;
    if (isSwap) {
      feeKeys[0] = keccak256('swapFee');
      feeKeys[1] = keccak256('swapFeeCap');
    } else {
      feeKeys[0] = keccak256('purchaseFee');
      feeKeys[1] = keccak256('purchaseFeeCap');
    }

    // Calculating the totalOptionCost
    returnValues[0] = optionPrice.mul(amount).mul(OptionPool(optionPool).quoteAssetPrecision());
    returnValues[0] = returnValues[0].div(strikePrecision).div(
      OptionPool(optionPool).baseAssetPrecision()
    );

    // Calculating the fee
    returnValues[1] = lastPrice
      .mul(amount)
      .mul(fees[feeKeys[0]].mul(1e8))
      .div(OptionPool(optionPool).baseAssetPrecision())
      .div(1e10)
      .div(strikePrecision);

    uint256 feeCap = returnValues[0].mul(fees[feeKeys[1]].mul(1e8)).div(1e10).div(
      OptionPool(optionPool).quoteAssetPrecision()
    );

    if (returnValues[1] > feeCap) {
      returnValues[1] = feeCap;
    }

    returnValues[1] = returnValues[1].mul(OptionPool(optionPool).quoteAssetPrecision()).div(
      strikePrecision
    );
  }

  /// @notice Function to check if a strike is valid.
  /// @param _strike Strike price
  /// @param _optionPool The option pool address
  /// @return Whether strike is valid
  function isValidStrike(uint256 _strike, address _optionPool) public view returns (bool) {
    uint256 _lastPrice = IDopexOracle(dopex.getAddress('DopexOracle')).getLastPrice(
      OptionPool(_optionPool).baseAsset().symbol(),
      OptionPool(_optionPool).quoteAsset().symbol()
    );

    uint256 minStrike = _lastPrice.sub(
      _lastPrice.mul(optionPoolVars[_optionPool].strikeRange.mul(10e8)).div(10e10)
    );
    uint256 maxStrike = _lastPrice.add(
      _lastPrice.mul(optionPoolVars[_optionPool].strikeRange.mul(10e8)).div(10e10)
    );
    return (minStrike <= _strike) && (_strike <= maxStrike);
  }

  /*==== CONTRACT FUNCTIONS: purchaseOption, purchaseOptionOnBehalfOf, optionSwap, liquidate, exerciseOption ====*/

  /**
   * @notice Purchase option tokens (doTokens) from the option pool.
   * @dev Collateral deposited into the pool are added to vaults and the resulting doTokens are transferred to the option
   * purchaser.
   * @param useVolumePoolFunds Whether to use volume pool funds for purchase
   * @param isPut Whether put/call options are to be purchased
   * @param strike Strike price to purchase
   * @param expiry Expiry timestamp
   * @param amount Amount of option tokens to purchase
   * @param timePeriod Time period of the pool
   * @param baseAssetAddress Address of the base asset
   * @param quoteAssetAddress Address of the quote asset
   */
  function purchaseOption(
    bool useVolumePoolFunds,
    bool isPut,
    uint256 strike,
    uint256 expiry,
    uint256 amount,
    bytes32 timePeriod,
    address baseAssetAddress,
    address quoteAssetAddress
  ) external {
    require(
      _purchase(
        [useVolumePoolFunds, isPut],
        [strike, expiry, amount],
        [baseAssetAddress, quoteAssetAddress, msg.sender],
        timePeriod
      ),
      'E45'
    );
  }

  /**
   * @notice Allows for purchasing options on behalf of a users volume pool funds
   * @dev Can only be called from a whitelisted contract
   * @param useVolumePoolFunds Whether to use volume pool funds for purchase
   * @param isPut Whether put/call options are to be purchased
   * @param strike Strike price to purchase
   * @param expiry Expiry timestamp
   * @param amount Amount of option tokens to purchase
   * @param timePeriod Time period of the pool
   * @param baseAssetAddress Address of the base asset
   * @param quoteAssetAddress Address of the quote asset
   * @param user Address of the user
   */
  function purchaseOptionOnBehalfOf(
    bool useVolumePoolFunds,
    bool isPut,
    uint256 strike,
    uint256 expiry,
    uint256 amount,
    bytes32 timePeriod,
    address baseAssetAddress,
    address quoteAssetAddress,
    address user
  ) external {
    require(whitelistedContracts[msg.sender], 'E56');
    require(
      _purchase(
        [useVolumePoolFunds, isPut],
        [strike, expiry, amount],
        [baseAssetAddress, quoteAssetAddress, user],
        timePeriod
      ),
      'E45'
    );
  }

  /**
   * @dev Internal function to the option purchase
   * @param boolArgs [useVolumePoolFunds, isPut]
   * @param uintArgs [strike, expiry, amount, timePeriod]
   * @param addressArgs [baseAssetAddress, quoteAssetAddress, userAddress]
   * @return whether the purchase was successful or not
   */
  function _purchase(
    bool[2] memory boolArgs, /* [useVolumePoolFunds, isPut] */
    uint256[3] memory uintArgs, /* [strike, expiry, amount] */
    address[3] memory addressArgs, /* [baseAssetAddress, quoteAssetAddress, userAddress] */
    bytes32 timePeriod
  ) internal returns (bool) {
    OptionPool optionPool = OptionPool(
      OptionPoolFactory(dopex.getAddress('OptionPoolFactory')).optionPools(
        OptionPoolHelper.generateOptionPoolId(addressArgs[0], addressArgs[1], timePeriod)
      )
    );

    require(
      isValidStrike(
        uintArgs[0], // Strike Price
        address(optionPool)
      ),
      'E22'
    );

    address optionsContractAddress = optionPool.getOrAddOptionsContract(
      boolArgs[1], // isPut
      uintArgs[1], // expiry
      uintArgs[0] // strike
    );

    IERC20 quoteAsset = IERC20(
      addressArgs[1] // quoteAssetAddress
    );

    require(optionPool.isPoolShutdown() != true, 'E12');

    require(optionPool.isPoolReady(optionPool.getCurrentEpoch()), 'E20');

    require(
      optionPool.isValidExpiry(
        uintArgs[1] // expiry
      ),
      'E21'
    );

    uint256 collateralFunds = OptionPoolBrokerLibrary.computeCollateral(
      boolArgs[1], // isPut
      uintArgs[0], // strike
      uintArgs[2], // amount
      optionPool.quoteAssetPrecision(),
      optionPool.baseAssetPrecision()
    );

    // Check if enough base/quote funds are available as collateral funds in the option pool
    require(
      collateralFunds <=
        optionPool.getAvailablePoolFunds(
          boolArgs[1] // isPut
        ),
      'E25'
    );

    // [totalOptionCost, fee]
    uint256[2] memory returnValues = getTotalOptionCost(
      getOptionPrice(
        boolArgs[1], // isPut
        uintArgs[1], // expiry
        uintArgs[0], // strike
        address(optionPool)
      ),
      uintArgs[2], // amount
      address(optionPool),
      false // isSwap
    );

    uint256 liquidityMultiple = computeLiquidityMultiple(
      false,
      boolArgs[1], // isPut
      uintArgs[2], // amount
      uintArgs[0], // strike
      optionPool
    );

    // Calculating totalOptionCost
    returnValues[0] = returnValues[0].mul(liquidityMultiple).div(
      1e2 /* liquidity multiplier precision */
    );

    // Transfer the totalOptionCost from sender to contract
    if (
      !boolArgs[0] // useVolumePoolFunds
    ) {
      quoteAsset.safeTransferFrom(
        msg.sender,
        address(optionPool),
        returnValues[0] // totalOptionCost
      );
      // Transfer fee to the staking contract
      quoteAsset.safeTransferFrom(
        msg.sender,
        dopex.getAddress('FeeDistributor'),
        // returnValues[1] is the fee, 30% of fee is sent to the FeeDistributor
        returnValues[1].sub(returnValues[1].mul(70).div(100))
      );
    } else {
      address volumePoolAddress = VolumePoolFactory(dopex.getAddress('VolumePoolFactory'))
        .volumePools(addressArgs[1]);
      // Update totalOptionCost to account for the vol pool discount
      returnValues[0] = returnValues[0]
        .mul(uint256(100).sub(VolumePool(volumePoolAddress).volumePoolDiscount()))
        .div(100);
      VolumePool(volumePoolAddress).purchase(
        returnValues[1].sub(returnValues[1].mul(70).div(100)),
        returnValues[0],
        addressArgs[2],
        address(optionPool)
      );
    }

    // Add revenue to the OptionPool
    optionPool.addRevenue(
      boolArgs[1], // isPut
      returnValues[0].add(returnValues[1].mul(70).div(100)) // totalOptionCost + 70% of fee is re-added to the pool
    );

    // Lock collateral in OptionPool
    optionPool.lockCollateralFunds(
      boolArgs[1], // isPut
      optionsContractAddress,
      collateralFunds
    );

    // Issue doTokens to the user
    OptionsContract(optionsContractAddress).issueDoTokens(
      uintArgs[2], // amount
      msg.sender
    );

    emit OptionPurchase(
      boolArgs[1], // isPut
      uintArgs[1], // expiry
      uintArgs[0], // strike
      uintArgs[2], // amount
      returnValues[1], // fee
      returnValues[0], // premium (totalOptionCost),
      optionsContractAddress,
      address(optionPool),
      addressArgs[2] // address of the user
    );

    return true;
  }

  /**
   * @notice Liquidates a leveraged options position via the Margin contract.
   * If value of the options position drops below the user's position margin,
   * this function is called by the Margin contract. Callers receive
   * `liquidateFee` % fees for every successful liquidation.
   * @param expiry Expiry timestamp
   * @param amount Amount of options to liquidate
   * @param borrowedAmount Amount of USD borrowed by user for purchases
   * which is not redeemable from margin. This is re-funded to margin lenders.
   * @param strike Option strike price
   * @param timePeriod Time period of the pool
   * @param isPut Is a put option
   * @param baseAssetAddress Address of the base asset
   * @param quoteAssetAddress Address of the quote asset
   * @return Whether position was liquidated
   */
  function liquidate(
    uint256 expiry,
    uint256 amount,
    uint256 borrowedAmount,
    uint256 strike,
    bytes32 timePeriod,
    bool isPut,
    address baseAssetAddress,
    address quoteAssetAddress
  ) external onlyMargin returns (bool) {
    OptionPool optionPool = OptionPool(
      OptionPoolFactory(dopex.getAddress('OptionPoolFactory')).optionPools(
        OptionPoolHelper.generateOptionPoolId(baseAssetAddress, quoteAssetAddress, timePeriod)
      )
    );
    OptionsContract optionsContract = OptionsContract(
      optionPool.getOrAddOptionsContract(isPut, expiry, strike)
    );
    // Remove revenue from option pool
    optionPool.removeRevenue(isPut, borrowedAmount);
    // Burn doTokens from user
    optionsContract.burnDoTokens(amount, msg.sender);
    // Unlock collateral funds
    optionPool.unlockCollateralFunds(isPut, address(optionsContract), amount);
    // NOTE: Premiums from margin remain with option pools and are accounted for at end of epoch as part of pnl
    // Transfer quote asset to sender
    IERC20(quoteAssetAddress).safeTransfer(msg.sender, borrowedAmount);

    emit Liquidation(isPut, expiry, strike, amount, borrowedAmount);

    return true;
  }

  /**
   * @notice Allows users to swap their options strike prices
   * @param isPut whether options are put options
   * @param oldExpiry the expiry of the option
   * @param newExpiry the new expiry of the option
   * @param oldStrike the current strike price of the option
   * @param newStrike the new wanted strike price of the option
   * @param amount the amount of existing options to swap
   * @param timePeriod Time period of the pool
   * @param baseAssetAddress Address of the base asset
   * @param quoteAssetAddress Address of the quote asset
   */
  function optionSwap(
    bool isPut,
    uint256 oldExpiry,
    uint256 newExpiry,
    uint256 oldStrike,
    uint256 newStrike,
    uint256 amount,
    bytes32 timePeriod,
    address baseAssetAddress,
    address quoteAssetAddress
  ) external returns (uint256, uint256) {
    OptionPool optionPool = OptionPool(
      OptionPoolFactory(dopex.getAddress('OptionPoolFactory')).optionPools(
        OptionPoolHelper.generateOptionPoolId(baseAssetAddress, quoteAssetAddress, timePeriod)
      )
    );

    require(isValidStrike(newStrike, address(optionPool)), 'E22');

    // returnValues = [newDoTokens, fee]
    uint256[2] memory returnValues = _swap(
      isPut,
      [oldExpiry, newExpiry, oldStrike, newStrike, amount],
      [baseAssetAddress, quoteAssetAddress],
      timePeriod
    );

    require(returnValues[0] > 0, 'E45');

    return (returnValues[0], returnValues[1]);
  }

  /**
   * @dev Allows users to swap their options for a different strike/expiry
   * @param isPut whether options are put options
   * @param uintArgs uint arguments: [oldExpiry, newExpiry, oldStrike, newStrike, amount]
   * @param addressArgs address arguments: [baseAssetAddress, quoteAssetAddress]
   * @param timePeriod time period of the OptionPool
   * @return A uint256 array - [newDoTokens, fee]
   */
  function _swap(
    bool isPut,
    uint256[5] memory uintArgs,
    address[2] memory addressArgs,
    bytes32 timePeriod
  ) internal returns (uint256[2] memory) {
    OptionPool optionPool = OptionPool(
      OptionPoolFactory(dopex.getAddress('OptionPoolFactory')).optionPools(
        OptionPoolHelper.generateOptionPoolId(addressArgs[0], addressArgs[1], timePeriod)
      )
    );

    /*
     * assets[0] = BASE ASSET
     * assets[1] = QUOTE ASSET
     */
    IERC20[2] memory assets = [
      IERC20(
        addressArgs[0] // baseAssetAddress
      ),
      IERC20(
        addressArgs[1] // quoteAssetAddress
      )
    ];

    // Requiring that oldExpiry != newExpiry or oldStrike != newStrike to ensure the swap is not happening for the same option
    require(uintArgs[0] != uintArgs[1] || uintArgs[2] != uintArgs[3], 'E28');

    require(optionPool.isPoolShutdown() != true, 'E12');

    require(
      optionPool.isValidExpiry(
        uintArgs[1] // expiry
      ),
      'E32'
    );

    // returns [oldOptionsContractAddress, newOptionsContractAddress]
    address[2] memory optionsContractAddresses = _getSwapOptionsContractAddresses(
      isPut,
      [
        uintArgs[0], // oldExpiry
        uintArgs[1], // newExpiry
        uintArgs[2], // oldStrike
        uintArgs[3] // newStrike
      ],
      optionPool
    );

    uint256 newOptionPrice = getOptionPrice(
      isPut,
      uintArgs[1], // newExpiry
      uintArgs[3], // newStrike
      address(optionPool)
    );

    // returnValues = [totalOptionCost, fee]
    uint256[2] memory returnValues = getTotalOptionCost(
      getOptionPrice(
        isPut,
        uintArgs[0], // oldExpiry
        uintArgs[2], // oldStrike
        address(optionPool)
      ),
      uintArgs[4],
      address(optionPool),
      true
    );

    // 70% of fee is re-added to the pool
    optionPool.addRevenue(isPut, returnValues[1].mul(70).div(100));

    assets[1].safeTransferFrom(
      msg.sender,
      address(optionPool),
      // returnValues[1] = fee, 30% of fee is sent to the FeeDistributor
      returnValues[1].mul(70).div(100)
    );

    // Transferring fee to the staking contract (assets[1] is the quoteAsset, fee is always collected in the quoteAsset in swaps)
    assets[1].safeTransferFrom(
      msg.sender,
      dopex.getAddress('FeeDistributor'),
      // returnValues[1] = fee, 30% of fee is sent to the FeeDistributor
      returnValues[1].sub(returnValues[1].mul(70).div(100))
    );

    require(
      OptionsContract(optionsContractAddresses[0]).balanceOf(msg.sender) >= uintArgs[4], // amount
      'E30'
    );

    // Calculating the new amount of doTokens that will be issued to the user
    uint256 newDoTokens = returnValues[0].mul(optionPool.baseAssetPrecision());

    newDoTokens = newDoTokens.mul(strikePrecision).div(newOptionPrice).div(
      optionPool.quoteAssetPrecision()
    );

    // Directly accounting the liquidity multiplier into new amount of tokens minted
    uint256 liquidityMultiple = computeLiquidityMultiple(
      true,
      isPut,
      newDoTokens,
      uintArgs[3], // newStrike
      optionPool
    );

    newDoTokens = newDoTokens.sub(
      newDoTokens.mul(liquidityMultiple).div(
        1e2 /* liquidity multiplier precision */
      )
    );

    // [oldCollateral, newCollateral]
    uint256[2] memory collaterals = OptionPoolBrokerLibrary.computeSwapCalculations(
      isPut,
      uintArgs[2], // oldStrike
      uintArgs[3], // newStrike
      uintArgs[4], // amount
      newDoTokens,
      optionPool.baseAssetPrecision(),
      optionPool.quoteAssetPrecision()
    );

    // Burn the doTokens from the user
    OptionsContract(
      optionsContractAddresses[0] // oldOptionsContractAddress
    ).burnDoTokens(
        uintArgs[4], // amount
        msg.sender
      );

    optionPool.unlockCollateralFunds(
      isPut,
      optionsContractAddresses[0], // oldOptionsContractAddress
      collaterals[0] // oldCollateral
    );

    // Check if quote tokens are available as collateral funds in option pool
    // based on total quote pool funds minus quote pool funds locked as collateral
    require(
      // newCollateral
      collaterals[1] <= optionPool.getAvailablePoolFunds(isPut),
      'E25'
    );

    optionPool.lockCollateralFunds(
      isPut,
      optionsContractAddresses[1], // newOptionsContractAddress
      collaterals[1] // newCollateral
    );

    // Issue new tokens to user
    OptionsContract(
      optionsContractAddresses[1] // newOptionsContractAddress
    ).issueDoTokens(newDoTokens, msg.sender);

    _emitOptionSwap(
      isPut,
      [
        uintArgs[0],
        uintArgs[1],
        uintArgs[2],
        uintArgs[3],
        uintArgs[4],
        returnValues[1].mul(optionPool.quoteAssetPrecision()).div(strikePrecision),
        newDoTokens
      ],
      [optionsContractAddresses[0], optionsContractAddresses[1], address(optionPool)]
    );

    return [
      newDoTokens,
      returnValues[1].mul(optionPool.quoteAssetPrecision()).div(strikePrecision) // Fee in quote precision
    ];
  }

  /**
   * @dev Internal function to get the OptionsContract addresses for the old and new options in an option swap
   * @param isPut whether options are put options
   * @param uintArgs [oldExpiry, newExpiry, oldStrike, newStrike]
   * @param optionPool the option pool contract
   * @return optionsContractAddresses an array of the option contract addresses - [oldOptionsContractAddress, newOptionsContractAddress]
   */
  function _getSwapOptionsContractAddresses(
    bool isPut,
    uint256[4] memory uintArgs, // [oldExpiry, newExpiry, oldStrike, newStrike]
    OptionPool optionPool
  )
    internal
    returns (
      address[2] memory optionsContractAddresses /* [oldOptionsContractAddress, newOptionsContractAddress] */
    )
  {
    address oldOptionsContractAddress = IOptionsFactory(dopex.getAddress('OptionsFactory'))
      .optionsContractIdToAddress(
        OptionPoolHelper.generateOptionContractId(
          isPut,
          uintArgs[0], // oldExpiry
          uintArgs[2], // oldStrike
          address(optionPool)
        )
      );

    require(oldOptionsContractAddress != address(0), 'E29');

    address newOptionsContractAddress = optionPool.getOrAddOptionsContract(
      isPut,
      uintArgs[1], // newStrike
      uintArgs[3] // newStrike
    );

    return [oldOptionsContractAddress, newOptionsContractAddress];
  }

  /**
   * @dev Internal function to emit the OptionSwap event. Done this way to avoid deep stack errors.
   * @param isPut whether options are put options
   * @param uintArgs [oldExpiry, newExpiry, oldStrike, newStrike, amount, fee, newDoTokens]
   * @param addressArgs [oldOptionsContract, newOptionsContract, optionPool]
   */
  function _emitOptionSwap(
    bool isPut,
    uint256[7] memory uintArgs, // [oldExpiry, newExpiry, oldStrike, newStrike, amount, fee, newDoTokens]
    address[3] memory addressArgs // [oldOptionsContract, newOptionsContract, optionPool]
  ) internal {
    emit OptionSwap(
      isPut,
      uintArgs[0], // oldExpiry
      uintArgs[1], // newExpiry
      uintArgs[2], // oldStrike
      uintArgs[3], // newStrike
      uintArgs[4], // amount
      uintArgs[5], // fee
      uintArgs[6], // newDoTokens issued to the user
      addressArgs[0], // oldOptionsContract
      addressArgs[1], // newOptionsContract
      addressArgs[2], // optionPool
      msg.sender
    );
  }

  /**
   * @notice Allows users to exercise dOTokens they own without supplying underlying.
   * @param _isPut whether the option vault is a put vault
   * @param _strike Strike price
   * @param _expiry Expiry timestamp
   * @param _amount Amount of options to exercise in wei
   * @param timePeriod time period of the OptionPool
   * @param baseAssetAddress Address of the base asset
   * @param quoteAssetAddress Address of the quote asset
   */
  function exerciseOption(
    bool _isPut,
    uint256 _strike,
    uint256 _expiry,
    uint256 _amount,
    bytes32 timePeriod,
    address baseAssetAddress,
    address quoteAssetAddress
  ) external {
    require(
      _exercise(
        _isPut,
        [_strike, _expiry, _amount],
        [baseAssetAddress, quoteAssetAddress],
        timePeriod
      ),
      'E45'
    );
  }

  /**
   * @dev Internal function to handle pnl based exercising of options
   * @param isPut whether the option vault is a put vault
   * @param uintArgs uint arguments: [strike, expiry, amount]
   * @param addressArgs address arguments: [baseAssetAddress, quoteAssetAddress]
   * @param timePeriod time period of the OptionPool
   * @return Whether options were exercised
   */
  function _exercise(
    bool isPut,
    uint256[3] memory uintArgs, // [strike, expiry, amount]
    address[2] memory addressArgs, // [baseAssetAddress, quoteAssetAddress]
    bytes32 timePeriod
  ) internal returns (bool) {
    OptionPool optionPool = OptionPool(
      OptionPoolFactory(dopex.getAddress('OptionPoolFactory')).optionPools(
        OptionPoolHelper.generateOptionPoolId(
          addressArgs[0], // baseAssetAddress
          addressArgs[1], // quoteAssetAddress
          timePeriod
        )
      )
    );

    // Get options contract
    address optionContractAddress = IOptionsFactory(dopex.getAddress('OptionsFactory'))
      .optionsContractIdToAddress(
        OptionPoolHelper.generateOptionContractId(
          isPut,
          uintArgs[1], // expiry
          uintArgs[0], // strike
          address(optionPool)
        )
      );

    require(optionContractAddress != address(0), 'E47');

    OptionsContract options = OptionsContract(optionContractAddress);

    require(
      options.balanceOf(msg.sender) >= uintArgs[2], // amount
      'E48'
    );

    // Check for options exercise window
    require(options.isExerciseWindow(), 'E9');

    // returns [collateral, pnl, fee]
    uint256[3] memory returnValues = _computeExerciseCalculations(
      isPut,
      [
        uintArgs[0], // strike
        uintArgs[1], // expiry
        uintArgs[2] // amount
      ],
      optionPool
    );

    // Burn doTokens from user
    options.burnDoTokens(
      uintArgs[2], // amount
      msg.sender
    );

    // Unlock collateral in the OptionPool
    optionPool.unlockCollateralFunds(isPut, address(options), returnValues[0]);

    emit OptionExercised(
      isPut,
      uintArgs[1], // expiry
      uintArgs[0], // strike
      uintArgs[2], // amount
      returnValues[1], /* PNL before fee */
      returnValues[2],
      address(options),
      address(optionPool),
      msg.sender
    );

    // Subtract the fee from the PnL
    if (isPut) {
      returnValues[1] = returnValues[1].sub(returnValues[2]);
    } else {
      returnValues[1] = returnValues[1].sub(returnValues[2]);
    }

    // Option Pool exercise transfers pnl (after deducting fee from it) to user and updates the stats accordingly
    optionPool.exercise(isPut, returnValues[1], uintArgs[2], returnValues[2], msg.sender);

    return true;
  }

  /**
   * @dev Internal function to compute all calculations for an exercise.
   * @param isPut whether the option vault is a put vault
   * @param uintArgs uint arguments: [strike, expiry, amount]
   * @param optionPool The option pool contract
   */
  function _computeExerciseCalculations(
    bool isPut,
    uint256[3] memory uintArgs, /* [strike, expiry, amount] */
    OptionPool optionPool
  )
    internal
    view
    returns (
      uint256[3] memory returnValues /* [collateral, pnl, fee] */
    )
  {
    uint256 lastPrice = IDopexOracle(dopex.getAddress('DopexOracle')).getLastPrice(
      (optionPool.baseAsset()).symbol(),
      (optionPool.quoteAsset()).symbol()
    );

    uint256 feeCap = getOptionPrice(
      isPut,
      uintArgs[1], // expiry
      uintArgs[0], // strike
      address(optionPool)
    )
      .mul(
        uintArgs[2] // amount
      )
      .div(optionPool.baseAssetPrecision());

    feeCap = feeCap.mul(fees[keccak256('exerciseFeeCap')].mul(1e8)).div(1e10);

    // Calculating Fee
    returnValues[2] = lastPrice
      .mul(
        uintArgs[2] // amount
      )
      .mul(fees[keccak256('exerciseFee')].mul(1e8))
      .div(optionPool.baseAssetPrecision())
      .div(1e10);

    // Fee cannot be higher than feeCap
    if (returnValues[2] > feeCap) {
      returnValues[2] = feeCap;
    }
    returnValues[2] = returnValues[2].div(strikePrecision);

    if (isPut) {
      // Calculating the collateral (Collateral = Strike * Amount)
      returnValues[0] = uintArgs[2] // amount
        .mul(
          uintArgs[0] // strike
        )
        .mul(optionPool.quoteAssetPrecision())
        .div(strikePrecision)
        .div(optionPool.baseAssetPrecision());
      // Intrinsic Value of the option is the total current value of the assets the options represent
      // ie. Intrinsic Value of 2 ETH options = 2 * (Current Price of ETH)
      uint256 intrinsicValue = uintArgs[2] // amount
        .mul(lastPrice)
        .mul(optionPool.quoteAssetPrecision())
        .div(strikePrecision)
        .div(optionPool.baseAssetPrecision());
      // Check if collateral's value is larger than intrinsic value
      require(returnValues[0] > intrinsicValue, 'E10');
      // Calculating PNL in quote asset (PNL = Collateral - Intrinsic Value)
      returnValues[1] = returnValues[0].sub(intrinsicValue);
      returnValues[2] = returnValues[2].mul(optionPool.quoteAssetPrecision()).div(strikePrecision);
    } else {
      returnValues[0] = uintArgs[2]; // collateral's value = amount (as this is a call option)
      // Check if strike price < than current price (for +ve PnL)
      require(lastPrice > uintArgs[0], 'E10');
      // Calculating PNL in base asset (PNL in base asset = ((Last Price - Strike Price) * amount) / Last Price)
      returnValues[1] = (
        lastPrice.sub(
          uintArgs[0] // strike
        )
      )
        .mul(
          uintArgs[2] // amount
        )
        .div(lastPrice);
      returnValues[2] = returnValues[2].mul(optionPool.baseAssetPrecision()).div(lastPrice);
    }
  }

  /*==== EVENTS ====*/

  event OptionPurchase(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    uint256 amount,
    uint256 fee,
    uint256 premium,
    address optionsContract,
    address indexed optionPool,
    address indexed user
  );

  event OptionSwap(
    bool isPut,
    uint256 oldExpiry,
    uint256 newExpiry,
    uint256 oldStrike,
    uint256 newStrike,
    uint256 amount,
    uint256 fee,
    uint256 newDoTokens, // The new amount of option tokens issued to the user
    address oldOptionsContract,
    address newOptionsContract,
    address indexed optionPool,
    address indexed user
  );

  event Liquidation(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    uint256 amount,
    uint256 borrowedAmount
  );

  event OptionExercised(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    uint256 amount,
    uint256 pnl, /* PNL before fee */
    uint256 fee,
    address optionsContract,
    address indexed optionPool,
    address indexed user
  );

  event AddWhitelistedContract(address indexed contractAddress);

  event RemoveWhitelistedContract(address indexed contractAddress);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

library OptionPoolBrokerLibrary {
  using SafeMath for uint256;

  uint256 constant strikePrecision = 1e8;

  function computeCollateral(
    bool isPut,
    uint256 strike,
    uint256 amount,
    uint256 quoteAssetPrecision,
    uint256 baseAssetPrecision
  ) internal pure returns (uint256 collateralFunds) {
    if (isPut) {
      // Calculate the collateral funds for put options
      // strike price * amount
      collateralFunds = strike.mul(amount).mul(quoteAssetPrecision);
      collateralFunds = collateralFunds.div(strikePrecision).div(baseAssetPrecision);
    } else {
      // Calculate the collateral funds for call options == amount
      collateralFunds = amount;
    }
  }

  function computeSwapCalculations(
    bool isPut,
    uint256 oldStrike,
    uint256 newStrike,
    uint256 amount,
    uint256 newDoTokens,
    uint256 baseAssetPrecision,
    uint256 quoteAssetPrecision
  ) internal pure returns (uint256[2] memory returnValues) {
    if (isPut) {
      // Calculate the old collateral locked in (for put options -> strike * amount)
      returnValues[0] = amount.mul(oldStrike).mul(quoteAssetPrecision).div(strikePrecision).div(
        baseAssetPrecision
      );
      // Calculate the new collateral to be locked in (for put options -> strike * amount)
      returnValues[1] = newStrike
        .mul(newDoTokens)
        .mul(quoteAssetPrecision)
        .div(strikePrecision)
        .div(baseAssetPrecision);
    } else {
      returnValues[0] = amount;
      returnValues[1] = newDoTokens;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Libraries
import {OptionPoolHelper} from '../libraries/OptionPoolHelper.sol';

// Interfaces
import {IOptionsFactory} from '../options/interfaces/IOptionsFactory.sol';

// Contracts
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {OptionPool} from './OptionPool.sol';
import {Dopex} from '../Dopex.sol';

contract OptionPoolFactory is Ownable {
  
  mapping(bytes32 => address) public optionPools;
  
  mapping(address => bool) public availableOptionPools;
  
  address public immutable implementationAddress;
  
  address public dopexAddress;

  event OptionPoolCreated(address baseAsset, address quoteAsset, address optionPool, bytes32 id);

  constructor(address _dopexAddress) {
    dopexAddress = _dopexAddress;
    implementationAddress = address(new OptionPool());
  }

  function create(
    address _baseAsset,
    address _quoteAsset,
    uint256 _startingGlobalEpoch,
    bytes32 _timePeriod
  ) external onlyOwner returns (address) {
    bytes32 id = OptionPoolHelper.generateOptionPoolId(_baseAsset, _quoteAsset, _timePeriod);
    require(Dopex(dopexAddress).baseTokensList(_baseAsset), 'E39');
    require(Dopex(dopexAddress).quoteTokensList(_quoteAsset), 'E40');
    require(optionPools[id] == address(0), 'E41');

    OptionPool _optionPool = OptionPool(Clones.clone(implementationAddress));
    _optionPool.initialize(
      _baseAsset,
      _quoteAsset,
      dopexAddress,
      _startingGlobalEpoch,
      _timePeriod
    );

    address optionPoolAddress = address(_optionPool);

    IOptionsFactory(Dopex(dopexAddress).getAddress('OptionsFactory')).addOptionPool(
      optionPoolAddress
    );
    optionPools[id] = optionPoolAddress;
    availableOptionPools[optionPoolAddress] = true;
    emit OptionPoolCreated(_baseAsset, _quoteAsset, optionPoolAddress, id);
    return optionPoolAddress;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '../libraries/SafeERC20.sol';

// Interfaces
import {IERC20} from '../interfaces/IERC20.sol';

// Contracts
import {Dopex} from '../Dopex.sol';
import {OptionPoolFactory} from './OptionPoolFactory.sol';

contract VolumePool {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @dev Whitelisted contracts allowed to add/withdraw to/from volume pool
  mapping(address => bool) public whitelistedContracts;

  /// @notice Total volume pool funds for an epoch
  /// @dev epoch => amount
  mapping(uint256 => uint256) public volumePoolFunds;

  /// @notice Total volume pool dpx deposits
  uint256 public volumePoolDpxDeposits;

  /// @notice User dpx deposit
  /// @dev user => amount
  mapping(address => uint256) public userVolumePoolDpxDeposit;

  /// @notice User volume pool funds for an epoch
  /// @dev user => (epoch => amount)
  mapping(address => mapping(uint256 => uint256)) public userVolumePoolFunds;

  /// @notice Penalties collected for volume pool withdrawals for an epoch
  /// @dev epoch => penalties collected
  mapping(uint256 => uint256) public volumePoolPenalties;

  /// @dev DPX token requirement to deposit funds into volume pools
  uint256 public volumePoolDpxDepositRequired = 100 * 10**18;

  /// @dev % discount while purchasing options in volume pools in 0 precision
  uint256 public volumePoolDiscount = 5;

  /// @dev % penalty for withdrawing funds from volume pools from an elapsed epoch in 0 precision
  uint256 public volumePoolPenalty = 1;

  /// @dev Dopex master contract
  Dopex public dopex;

  /// @dev The quote asset of the volume pool (for eg. USDT, USDC, DAI)
  IERC20 public quoteAsset;

  /*==== CONSTRUCTOR ====*/

  constructor(address _dopex, address _quoteAsset) {
    dopex = Dopex(_dopex);
    quoteAsset = IERC20(_quoteAsset);
  }

  /*==== MODIFIERS ====*/

  modifier onlyGovernance() {
    require(msg.sender == dopex.governance(), 'VolumePool: Sender must be Governance contract');
    _;
  }

  modifier isEligibleSender() {
    if (isContract(msg.sender))
      require(whitelistedContracts[msg.sender], 'VolumePool: Contract must be whitelisted');
    _;
  }

  /*==== GOVERNANCE FUNCTIONS ====*/

  /// @notice Update the volume pool penanlty for not using funds. In 0 precision.
  /// @param _volumePoolPenalty _volumePoolPenalty
  /// @return Whether update was done
  function updateVolumePoolPenalty(uint256 _volumePoolPenalty)
    external
    onlyGovernance
    returns (bool)
  {
    volumePoolPenalty = _volumePoolPenalty;

    emit UpdatePenalty(msg.sender, _volumePoolPenalty);

    return true;
  }

  /// @notice Update the volume pool discount. In 0 precision.
  /// @param _volumePoolDiscount _volumePoolDiscount
  /// @return Whether update was done
  function updateVolumePoolDiscount(uint256 _volumePoolDiscount)
    external
    onlyGovernance
    returns (bool)
  {
    volumePoolDiscount = _volumePoolDiscount;

    emit UpdateDiscount(msg.sender, _volumePoolDiscount);

    return true;
  }

  /// @notice Update the volume pool dpx deposit required for depsoiting to the volume pool. In DPX precision (1e18).
  /// @param _volumePoolDpxDepositRequired _volumePoolDpxDepositRequired
  /// @return Whether update was done
  function updateVolumePoolDpxDepositRequired(uint256 _volumePoolDpxDepositRequired)
    external
    onlyGovernance
    returns (bool)
  {
    volumePoolDpxDepositRequired = _volumePoolDpxDepositRequired;

    emit UpdateDpxDepositRequired(msg.sender, _volumePoolDpxDepositRequired);

    return true;
  }

  /**
   * @notice Add a contract address to whitelisted contracts
   * @param _contract Contract address
   * @return Whether address was added to contract whitelist
   */
  function addToContractWhitelist(address _contract) external onlyGovernance returns (bool) {
    require(isContract(_contract), 'VolumePool: Address must be a contract address');
    require(!whitelistedContracts[_contract], 'VolumePool: Contract already whitelisted');

    whitelistedContracts[_contract] = true;

    emit AddToContractWhitelist(_contract);

    return true;
  }

  /**
   * @notice Removes a contract addresss from whitelisted contracts
   * @param _contract Contract address
   * @return Whether address was removed from contract whitelist
   */
  function removeFromContractWhitelist(address _contract) external onlyGovernance returns (bool) {
    require(whitelistedContracts[_contract], 'VolumePool: Contract not whitelisted');

    whitelistedContracts[_contract] = false;

    emit RemoveFromContractWhitelist(_contract);

    return true;
  }

  /**
   * @notice Withdraw penalties to governance
   * @param epoch Epoch
   * @return Whether penalty was withdrawn
   */
  function withdrawPenalties(uint256 epoch) external onlyGovernance returns (bool) {
    require(epoch < dopex.getCurrentGlobalWeeklyEpoch(), 'VolumePool: Invalid epoch');

    uint256 penaltyForEpoch = volumePoolPenalties[epoch];

    volumePoolPenalties[epoch] = 0;

    quoteAsset.safeTransfer(msg.sender, penaltyForEpoch);

    emit WithdrawPenalties(penaltyForEpoch, epoch, msg.sender);

    return true;
  }

  /*==== EXTERNAL FUNCTIONS ====*/

  /**
   * @notice Adds quote asset to the volume pool for the next epoch.
   * Requires `volumePoolDpxDeposit` DPX tokens as a deposit to participate within volume pools
   * Volume pool participants are able to receive a `volumePoolDiscount` % discount on all option purchases
   * @param _amount Amount of quote asset to add to volume pool
   * @return Whether quote asset was added to volume pool
   */
  function deposit(uint256 _amount) external isEligibleSender returns (bool) {
    uint256 nextEpoch = dopex.getCurrentGlobalWeeklyEpoch() + 1;

    // Account for funds in volume pool for next epoch
    volumePoolFunds[nextEpoch] = volumePoolFunds[nextEpoch].add(_amount);

    userVolumePoolFunds[msg.sender][nextEpoch] = userVolumePoolFunds[msg.sender][nextEpoch].add(
      _amount
    );

    if (userVolumePoolDpxDeposit[msg.sender] < volumePoolDpxDepositRequired) {
      userVolumePoolDpxDeposit[msg.sender] = volumePoolDpxDepositRequired.sub(
        userVolumePoolDpxDeposit[msg.sender]
      );

      // Transfer volPoolDpxDeposit to volume pool
      IERC20(dopex.getAddress('DPX')).safeTransferFrom(
        msg.sender,
        address(this),
        userVolumePoolDpxDeposit[msg.sender]
      );

      volumePoolDpxDeposits = volumePoolDpxDeposits.add(userVolumePoolDpxDeposit[msg.sender]);
    }

    // Transfer funds to volume pool
    quoteAsset.safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposit(msg.sender, _amount, nextEpoch);

    return true;
  }

  /**
   * @notice Allows users to withdraw any unused quote asset from volume pools after paying a `volumePoolPenalty` %
   * penalty to option pools. This is enforced to incentivize user participation in generating
   * volume on option pools while accruing `volumePoolDiscount` % discounts.
   * @param _epoch Amount of USD to withdraw from volume pools for an elapsed epoch
   * @param _withdrawDpx Whether the DPX deposit should be withdrawn
   */
  function withdraw(uint256 _epoch, bool _withdrawDpx) external isEligibleSender {
    // Check for valid epoch
    require(_epoch < dopex.getCurrentGlobalWeeklyEpoch(), 'VolumePool: Invalid epoch');
    // User must have funds in volume pool for epoch
    require(
      userVolumePoolFunds[msg.sender][_epoch] > 0,
      'VolumePool: Insufficient funds for epoch'
    );

    uint256 funds = userVolumePoolFunds[msg.sender][_epoch];

    // Set volume pool funds to 0 for epoch
    userVolumePoolFunds[msg.sender][_epoch] = 0;
    uint256 penalty = funds.mul(volumePoolPenalty).div(100);

    // Account for volume pool penalty
    volumePoolPenalties[_epoch] = volumePoolPenalties[_epoch].add(penalty);

    // Transfer funds to user after accounting for penalty
    quoteAsset.safeTransfer(msg.sender, funds.sub(penalty));

    if (_withdrawDpx) {
      // Transfer DPX Deposit back to the user
      IERC20(dopex.getAddress('DPX')).safeTransfer(
        msg.sender,
        userVolumePoolDpxDeposit[msg.sender]
      );
    }

    emit Withdraw(msg.sender, funds.sub(penalty), penalty, _epoch);
  }

  /**
   * @notice Updates volume pool funds with option purchase cost for total and user volume pool funds
   * @param totalOptionCost Total cost of options being purchased after discount
   * @param fee Fee of the options
   * @param user User address making the purchase
   * @param optionPoolAddress The option pool to transfer the quote asset to
   * @return Whether volume pool funds were deducted and quote asset was transferred successfully
   */
  function purchase(
    uint256 totalOptionCost,
    uint256 fee,
    address user,
    address optionPoolAddress
  ) external returns (bool) {
    require(
      dopex.getAddress('OptionPoolBroker') == msg.sender,
      'VolumePool: Sender must be OptionPoolBroker contract'
    );
    uint256 epoch = dopex.getCurrentGlobalWeeklyEpoch();
    require(
      userVolumePoolFunds[user][epoch] >= totalOptionCost.add(fee),
      'VolumePool: Insufficient funds for epoch'
    );
    require(
      userVolumePoolDpxDeposit[user] >= volumePoolDpxDepositRequired,
      'VolumePool: DPX deposit is required'
    );

    userVolumePoolFunds[user][epoch] = userVolumePoolFunds[user][epoch].sub(totalOptionCost);
    volumePoolFunds[epoch] = volumePoolFunds[epoch].sub(totalOptionCost);

    // Transfer quote asset to option pool
    quoteAsset.safeTransfer(optionPoolAddress, totalOptionCost);

    // Transfer fee to the staking contract
    quoteAsset.safeTransfer(dopex.getAddress('FeeDistributor'), fee);

    return true;
  }

  /*==== VIEWS ====*/

  /// @notice Checks if passed address is a contract
  /// @param addr Address to check
  /// @return Whether address passed is a contract or not
  function isContract(address addr) public view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  /*==== EVENTS ====*/

  event UpdatePenalty(address sender, uint256 penalty);

  event UpdateDiscount(address sender, uint256 discount);

  event UpdateDpxDepositRequired(address sender, uint256 dpxDepositRequired);

  event Deposit(address sender, uint256 amount, uint256 epoch);

  event Withdraw(address sender, uint256 amount, uint256 penalty, uint256 epoch);

  event AddToContractWhitelist(address indexed _contract);

  event RemoveFromContractWhitelist(address indexed _contract);

  event WithdrawPenalties(uint256 penalties, uint256 epoch, address receiver);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Contracts
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VolumePool} from './VolumePool.sol';
import {Dopex} from '../Dopex.sol';

contract VolumePoolFactory is Ownable {
  /// @dev volume pool address => available bool
  mapping(address => bool) public availableVolumePools;

  /// @dev quote asset address => volume pool address
  mapping(address => address) public volumePools;

  /// @dev Dopex master contract
  Dopex public dopex;

  event VolumePoolCreated(address quoteAsset, address volumePoolAddress);

  constructor(address _dopex) {
    dopex = Dopex(_dopex);
  }

  function create(address _quoteAsset) external onlyOwner returns (address) {
    require(
      dopex.quoteTokensList(_quoteAsset),
      'Quote asset not added to the dopex master contract'
    );

    require(volumePools[_quoteAsset] == address(0), 'VolumePool must not already be added');

    address volumePool = address(new VolumePool(address(dopex), _quoteAsset));

    volumePools[_quoteAsset] = volumePool;

    availableVolumePools[volumePool] = true;

    emit VolumePoolCreated(_quoteAsset, volumePool);

    return volumePool;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IOptionPricing {
  /**
   * @notice computes the option price (with liquidity multiplier)
   * @param isPut is put option
   * @param expiry expiry timestamp
   * @param strike strike price
   * @param optionPool the option pool address
   */
  function getOptionPrice(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    address optionPool
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

// Libraries
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {BokkyPooBahsDateTimeLibrary} from '../libraries/BokkyPooBahsDateTimeLibrary.sol';
import {SafeERC20} from '../libraries/SafeERC20.sol';

// Interfaces
import {IERC20} from '../interfaces/IERC20.sol';

// Contracts
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {OptionPool} from '../pools/OptionPool.sol';
import {VolumePool} from '../pools/VolumePool.sol';
import {Dopex} from '../Dopex.sol';

contract DopexRewards is Ownable {
  using BokkyPooBahsDateTimeLibrary for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // user address => (pool+epoch key  => bool)
  mapping(address => mapping(bytes32 => bool)) public hasCollectedOptionPoolLiquidityRewards;

  // user address => (pool+epoch key  => bool)
  mapping(address => mapping(bytes32 => bool)) public hasCollectedVolumePoolLiquidityRewards;

  // Maps call reward keys to their rewards in %
  mapping(bytes32 => uint256) public callRewards;

  // Maps action reward keys to their rewards in %
  mapping(bytes32 => uint256) public actionRewards;

  // Reward precision
  uint256 public constant PERCENTAGE_PRECISION = 1e4;

  // Reward keys
  bytes32 public constant REWARD_KEY_CALL_BOOTSTRAP_OPTION_POOL = keccak256('bootstrapOptionPool');
  bytes32 public constant REWARD_KEY_CALL_EXPIRE_EPOCH = keccak256('expireEpoch');
  bytes32 public constant REWARD_KEY_ACTION_ADD_TO_OPTION_POOL = keccak256('addToOptionPool');
  bytes32 public constant REWARD_KEY_ACTION_ADD_TO_VOLUME_POOL = keccak256('addToVolumePool');

  // Dopex Contract
  Dopex public dopex;

  // Whether this contract has bootstrapped or not (recieved DPX in order to start emitting rewards)
  bool public bootstrapped;

  // Dpx Contract
  IERC20 public dpx;

  // Total rewards
  uint256 public totalRewards;

  // Reward duration in weeks
  uint256 public rewardDurationInDays;

  // Structure of reward weights
  struct RewardWeights {
    uint256 poolWeight;
    uint256 callWeight;
    uint256 putWeight;
  }

  // option pool address => RewardWeights
  mapping(address => RewardWeights) public optionPoolRewardWeights;

  // address => bool
  mapping(address => bool) public optionPools;

  // address => bool
  mapping(address => bool) public volPools;

  // total weight
  uint256 public totalWeight;

  // No. of option pools
  uint256 public noOfOptionsPools;

  // No. of vol pools
  uint256 public noOfVolPools;

  /*---- EVENTS ----*/

  event UpdateRewards(bytes32 rewardKey, uint256 rewardPercentage);

  event RegisterPoolForRewards(address optionPool, uint256 poolEpoch, uint256 weeklyEpoch);

  event RewardClaimedForCall(
    address optionPool,
    address recipient,
    bytes32 rewardKey,
    uint256 poolEpoch,
    uint256 amount
  );

  event RewardClaimedForOptionPoolLiquidity(
    address optionPool,
    address recipient,
    uint256 poolEpoch,
    uint256 amount
  );

  event RewardClaimedForVolumePoolLiquidity(
    address volumePool,
    address recipient,
    uint256 weeklyEpoch,
    uint256 amount
  );

  /*---- MODIFIERS ----*/

  modifier onlyGovernance() {
    require(msg.sender == dopex.governance(), 'Sender needs to be the governance contract');
    _;
  }

  /*---- CONSTRUCTOR ----*/

  constructor(address _dopex) {
    dopex = Dopex(_dopex);
    dpx = IERC20(dopex.getAddress('DPX'));

    // Call rewards
    callRewards[REWARD_KEY_CALL_BOOTSTRAP_OPTION_POOL] = 80; // 0.8%
    callRewards[REWARD_KEY_CALL_EXPIRE_EPOCH] = 20; // 0.2%

    // Action rewards
    actionRewards[REWARD_KEY_ACTION_ADD_TO_OPTION_POOL] = 89 * PERCENTAGE_PRECISION; // 89%
    actionRewards[REWARD_KEY_ACTION_ADD_TO_VOLUME_POOL] = 10 * PERCENTAGE_PRECISION; // 10%
  }

  /*---- EXTERNAL GOVERNACNE FUNCTION ----*/

  /**
   * Adds the option pool to the whitelist
   * @param _optionPoolAddress OptionPool address
   * @param _poolWeight The pool weight
   * @param _callWeight The weight given to the call (base) pool
   * @param _putWeight The weight given to the put (quote) pool
   */
  function addOptionPool(
    address _optionPoolAddress,
    uint256 _poolWeight,
    uint256 _callWeight,
    uint256 _putWeight
  ) external onlyGovernance {
    require(!optionPools[_optionPoolAddress], 'Option pool already added');

    optionPoolRewardWeights[_optionPoolAddress].poolWeight = _poolWeight;
    optionPoolRewardWeights[_optionPoolAddress].callWeight = _callWeight;
    optionPoolRewardWeights[_optionPoolAddress].putWeight = _putWeight;

    optionPools[_optionPoolAddress] = true;

    totalWeight = totalWeight.add(_poolWeight);

    noOfOptionsPools = noOfOptionsPools.add(1);
  }

  /**
   * Removes the option pool from the whitelist
   * @param _optionPoolAddress OptionPool address
   */
  function removeOptionPool(address _optionPoolAddress) external onlyGovernance {
    require(optionPools[_optionPoolAddress], 'Option pool should be added');

    optionPools[_optionPoolAddress] = false;

    totalWeight = totalWeight.sub(optionPoolRewardWeights[_optionPoolAddress].poolWeight);

    noOfOptionsPools = noOfOptionsPools.sub(1);
  }

  /**
   * Updates the option pools weights
   * @param _optionPoolAddress OptionPool address
   * @param _poolWeight The pool weight
   * @param _callWeight The weight given to the call (base) pool
   * @param _putWeight The weight given to the put (quote) pool
   */
  function updateOptionPoolRewardWeights(
    address _optionPoolAddress,
    uint256 _poolWeight,
    uint256 _callWeight,
    uint256 _putWeight
  ) external onlyGovernance {
    require(optionPools[_optionPoolAddress], 'Option pool should be added');

    totalWeight = totalWeight.sub(optionPoolRewardWeights[_optionPoolAddress].poolWeight).add(
      _poolWeight
    );

    optionPoolRewardWeights[_optionPoolAddress].poolWeight = _poolWeight;
    optionPoolRewardWeights[_optionPoolAddress].callWeight = _callWeight;
    optionPoolRewardWeights[_optionPoolAddress].putWeight = _putWeight;
  }

  /**
   * Adds the vol pool to the whitelist
   * @param _volPoolAddress VolPool address
   */
  function addVolPool(address _volPoolAddress) external onlyGovernance {
    require(_volPoolAddress != address(0), 'E54');
    require(!volPools[_volPoolAddress], 'VolPool already added');

    volPools[_volPoolAddress] = true;

    noOfVolPools = noOfVolPools.add(1);
  }

  /**
   * Removes the vol pool from the whitelist
   * @param _volPoolAddress VolPool address
   */
  function removeVolPool(address _volPoolAddress) external onlyGovernance {
    require(_volPoolAddress != address(0), 'E54');
    require(volPools[_volPoolAddress], 'VolPool should be added');

    volPools[_volPoolAddress] = false;

    noOfVolPools = noOfVolPools.sub(1);
  }

  /**
   * Sets the total reward amount, duration of the rewards and transfers the required DPX
   * @param _totalRewards the totalRewards to be set
   * @param _rewardDurationInDays the rewardDurationInDays to be set
   */
  function bootstrap(uint256 _totalRewards, uint256 _rewardDurationInDays) external onlyGovernance {
    require(!bootstrapped, 'Contract must not be already bootstrapped');
    dpx.safeTransferFrom(msg.sender, address(this), _totalRewards);
    totalRewards = _totalRewards;
    rewardDurationInDays = _rewardDurationInDays;
    bootstrapped = true;
  }

  /**
   * Unbootsrap the contract to stop emitting rewards
   * and transfers the DPX to the contract back to the caller
   */
  function unbootstrap() external onlyGovernance {
    require(bootstrapped, 'Contract must be bootstrapped');
    dpx.safeTransfer(msg.sender, dpx.balanceOf(address(this)));
    totalRewards = 0;
    rewardDurationInDays = 0;
    bootstrapped = false;
  }

  /**
   * Used to update/add reward percentage/key. Can only be called by governance
   * @param rewardKey Reward key
   * @param rewardPercentage Reward percentage
   * @param isActionRewards Whether to update action reward keys. If false will update call reward keys.
   * @return Whether update was successful
   */
  function updateReward(
    bytes32 rewardKey,
    uint256 rewardPercentage,
    bool isActionRewards
  ) external onlyGovernance returns (bool) {
    if (isActionRewards) {
      actionRewards[rewardKey] = rewardPercentage;
    } else {
      callRewards[rewardKey] = rewardPercentage;
    }
    emit UpdateRewards(rewardKey, rewardPercentage);
    return true;
  }

  /*---- EXTERNAL FUNCTIONS ----*/

  /**
   * Used to claim reward for a call
   * @param poolEpoch The epoch of the option pool for which the claim is made
   * @param rewardKey Reward key
   * @param recipient The recepient of the rewards, as the msg.sender for this function will always be an option pool
   * @return Amount of reward
   */
  function claimRewardForCall(
    uint256 poolEpoch,
    bytes32 rewardKey,
    address recipient
  ) external returns (uint256) {
    require(callRewards[rewardKey] != 0, 'Invalid reward key');

    // Check if the contract is active and option pool is added for rewards
    if (
      !bootstrapped ||
      dpx.balanceOf(address(this)) < getDailyRewardEmission() ||
      !optionPools[msg.sender]
    ) {
      return 0;
    }

    uint256 noOfDays = 0;

    if (OptionPool(msg.sender).timePeriod() == keccak256('weekly')) {
      noOfDays = 7;
    } else if (OptionPool(msg.sender).timePeriod() == keccak256('monthly')) {
      noOfDays = 31;
    }

    uint256 reward = getDailyRewardEmission()
      .mul(noOfDays)
      .mul(callRewards[rewardKey])
      .div(noOfOptionsPools)
      .div(PERCENTAGE_PRECISION);

    dpx.safeTransfer(recipient, reward);

    emit RewardClaimedForCall(msg.sender, recipient, rewardKey, poolEpoch, reward);
    return reward;
  }

  /**
   * Claim reward for actions performed within an option pool for an epoch
   * @param poolEpoch Pool epoch
   * @param optionPool Option pool address
   * @return Rewards claimed for epoch for pool
   */
  function claimRewardForOptionPoolLiquidity(uint256 poolEpoch, address optionPool)
    external
    returns (uint256)
  {
    require(optionPools[optionPool], 'Option pool not added');

    // Check if the contract is active
    if (!bootstrapped || dpx.balanceOf(address(this)) < getDailyRewardEmission()) {
      return 0;
    }

    OptionPool op = OptionPool(optionPool);

    require(op.isEpochExpired(poolEpoch), 'Epoch must be expired to claim action rewards');

    bytes32 poolEpochKey = keccak256(abi.encodePacked(optionPool, poolEpoch));

    require(
      !hasCollectedOptionPoolLiquidityRewards[msg.sender][poolEpochKey],
      'Option pool liquidity rewards already collected for this pool + epoch for user'
    );

    uint256 poolEpochReward = _calculateActionReward(
      REWARD_KEY_ACTION_ADD_TO_OPTION_POOL,
      op.timePeriod()
    );

    poolEpochReward = poolEpochReward.mul(optionPoolRewardWeights[address(op)].poolWeight).div(
      totalWeight
    );

    (
      uint256 userBaseAssetPercent,
      uint256 userQuoteAssetPercent
    ) = getUserAssetPercentagesForOptionPool(optionPool, poolEpoch);

    uint256 baseAssetUserReward = poolEpochReward
      .mul(userBaseAssetPercent)
      .mul(optionPoolRewardWeights[address(op)].callWeight)
      .div(uint256(100).mul(PERCENTAGE_PRECISION))
      .div(
        optionPoolRewardWeights[address(op)].callWeight.add(
          optionPoolRewardWeights[address(op)].putWeight
        )
      );

    uint256 quoteAssetUserReward = poolEpochReward
      .mul(userQuoteAssetPercent)
      .mul(optionPoolRewardWeights[address(op)].putWeight)
      .div(uint256(100).mul(PERCENTAGE_PRECISION))
      .div(
        optionPoolRewardWeights[address(op)].callWeight.add(
          optionPoolRewardWeights[address(op)].putWeight
        )
      );

    uint256 finalUserReward = baseAssetUserReward.add(quoteAssetUserReward);

    hasCollectedOptionPoolLiquidityRewards[msg.sender][poolEpochKey] = true;

    dpx.safeTransfer(msg.sender, finalUserReward);

    emit RewardClaimedForOptionPoolLiquidity(address(op), msg.sender, poolEpoch, finalUserReward);

    return finalUserReward;
  }

  /**
   * Claim reward for actions performed within an option pool for an epoch
   * @param globalEpoch  Pool epoch
   * @param volumePool VolumePool address
   * @return Rewards claimed for epoch for pool
   */
  function claimRewardForVolumePoolLiquidity(uint256 globalEpoch, address volumePool)
    external
    returns (uint256)
  {
    // Check if the contract is active
    if (!bootstrapped || dpx.balanceOf(address(this)) < getDailyRewardEmission()) {
      return 0;
    }

    require(
      globalEpoch < dopex.getCurrentGlobalWeeklyEpoch(),
      'Cannot claim volume pool rewards before epoch has passed'
    );

    bytes32 poolEpochKey = keccak256(abi.encodePacked(volumePool, globalEpoch));

    require(
      !hasCollectedVolumePoolLiquidityRewards[msg.sender][poolEpochKey],
      'Volume pool rewards already collected for this epoch by user'
    );

    uint256 poolEpochReward = _calculateActionReward(
      REWARD_KEY_ACTION_ADD_TO_VOLUME_POOL,
      'weekly'
    );

    uint256 userShare = getUserShareForVolumePool(globalEpoch, volumePool);

    uint256 finalUserReward = poolEpochReward.mul(userShare).div(
      uint256(100).mul(PERCENTAGE_PRECISION)
    );

    hasCollectedVolumePoolLiquidityRewards[msg.sender][poolEpochKey] = true;

    dpx.safeTransfer(msg.sender, finalUserReward);

    emit RewardClaimedForVolumePoolLiquidity(volumePool, msg.sender, globalEpoch, finalUserReward);

    return finalUserReward;
  }

  /*---- INTERNAL FUNCTIONS ----*/

  /**
   * Internal function to calculate the action rewards for an epoch
   * @param rewardKey Reward key
   * @param timePeriod The time period of the OptionPool
   */
  function _calculateActionReward(bytes32 rewardKey, bytes32 timePeriod)
    internal
    view
    returns (uint256 poolEpochReward)
  {
    uint256 noOfDays = 0;

    if (timePeriod == keccak256('weekly')) {
      noOfDays = 7;
    } else if (timePeriod == keccak256('monthly')) {
      noOfDays = 31;
    }

    poolEpochReward = getDailyRewardEmission()
      .mul(noOfDays)
      .mul(actionRewards[rewardKey])
      .div(PERCENTAGE_PRECISION)
      .div(1e2);
  }

  /*---- VIEWS ----*/

  /**
   * Gets the total rewards that are emitted for a particular epoch
   * @return the reward emission for the epoch
   */
  function getDailyRewardEmission() public view returns (uint256) {
    return totalRewards.div(rewardDurationInDays);
  }

  /**
   * Function to calculate the user percentage of call/put option pool
   * @param optionPool The option pool address
   * @param epoch The epoch to calculate the user percentage for
   */
  function getUserAssetPercentagesForOptionPool(address optionPool, uint256 epoch)
    public
    view
    returns (uint256, uint256)
  {
    OptionPool op = OptionPool(optionPool);
    uint256 userBaseAssets = op.getTotalNetUserBasePoolTokensUntilEpoch(msg.sender, epoch);
    uint256 userQuoteAssets = op.getTotalNetUserQuotePoolTokensUntilEpoch(msg.sender, epoch);
    uint256 poolBaseAssets = op.getTotalNetBasePoolTokensUntilEpoch(epoch);
    uint256 poolQuoteAssets = op.getTotalNetQuotePoolTokensUntilEpoch(epoch);
    uint256 userBaseAssetPercent;
    uint256 userQuoteAssetPercent;
    if (poolBaseAssets == 0) {
      userBaseAssetPercent = 0;
    } else {
      userBaseAssetPercent = userBaseAssets.mul(uint256(100).mul(PERCENTAGE_PRECISION)).div(
        poolBaseAssets
      );
    }
    if (poolQuoteAssets == 0) {
      userQuoteAssetPercent = 0;
    } else {
      userQuoteAssetPercent = userQuoteAssets.mul(uint256(100).mul(PERCENTAGE_PRECISION)).div(
        poolQuoteAssets
      );
    }
    return (userBaseAssetPercent, userQuoteAssetPercent);
  }

  /**
   * Function to get the share of a user in the volume pool for an epoch
   * @param epoch The epoch to calculate the user share for
   * @param volumePool VolumePool address
   */
  function getUserShareForVolumePool(uint256 epoch, address volumePool)
    public
    view
    returns (uint256 userShare)
  {
    VolumePool vp = VolumePool(volumePool);
    uint256 userVolumePoolFunds = vp.userVolumePoolFunds(msg.sender, epoch);
    uint256 totalVolumePoolFunds = vp.volumePoolFunds(epoch);

    if (totalVolumePoolFunds == 0) {
      userShare = 0;
    } else {
      userShare = userVolumePoolFunds.mul(uint256(100).mul(PERCENTAGE_PRECISION)).div(
        totalVolumePoolFunds
      );
    }

    return userShare;
  }
}