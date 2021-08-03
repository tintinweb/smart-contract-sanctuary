// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Pool implementation contract for all pool proxies
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IController.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract Pool is Initializable, ERC20Upgradeable {
    using SafeERC20 for IERC20;
    bool public stopped = false;

    IERC20 public underlying;
    address[] public rewardTokens;
    IController public controller;

    address public strategist;

    uint256 public totalStaked;
    bool public isFinalized;
    uint256 public toDepositBuffer; // amount (in BPS) to actually deposit
    uint256 public constant BPS_MAX = 10000;

    // user => lastDepositTime
    mapping(address => uint256) public lastDepositTime;
    uint256 public withdrawPenaltyTime;
    uint256 public withdrawPenalty; // in BPS

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct TWAP_S {
        uint256 priceCumulative;
        uint256 lastTimeStamp;
    }
    TWAP_S public TWAP;
    event TWAP_Update(
        uint256 priceCumulative,
        uint256 lastTimeStamp,
        uint256 pricePerShare
    );

    function initialize(
        address _underlying,
        address[] memory _rewardTokens,
        address _controller,
        address _strategist
    ) public initializer {
        __ERC20_init("Zapper Staking Token", "ZST");

        underlying = IERC20(_underlying);
        rewardTokens = _rewardTokens;
        controller = IController(_controller);
        strategist = _strategist;

        isFinalized = false;
        toDepositBuffer = 9500;

        withdrawPenaltyTime = 3 days;
        withdrawPenalty = 50; // 0.5%

        emit TWAP_Update(0, 0, 0);
    }

    // --- Modifiers ---

    modifier onlyController {
        require(msg.sender == address(controller), "ZSS: Not Controller");
        _;
    }

    modifier stopInEmergency {
        if (stopped) {
            revert("ZSS: Temporarily Paused");
        } else {
            _;
        }
    }

    modifier checkFinalized {
        if (isFinalized) {
            // allow anyone to interact if finalized
            _;
        } else {
            // only allow strategist to interact if Not finalized
            require(msg.sender == strategist, "ZSS: Not Finalized");
            _;
        }
    }

    // --- External Mutative Functions ---

    function deposit(
        address _fromToken,
        uint256 _amountIn,
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) external payable checkFinalized stopInEmergency {
        uint256 _pool = balance();

        // get tokens from user
        _pullTokens(_fromToken, _amountIn);

        // swap them to underlying
        uint256 netUnderlyingReceived =
            _fillQuote(
                _fromToken,
                address(underlying),
                _amountIn,
                _swapTarget,
                _swapData,
                _minToTokens
            );

        // deposit amount after accounting for buffer
        uint256 underlyingToDeposit =
            (netUnderlyingReceived * toDepositBuffer) / BPS_MAX;

        // deposit into staking contract
        _deposit(underlyingToDeposit);

        // mint shares for user
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = netUnderlyingReceived;
        } else {
            shares = (netUnderlyingReceived * totalSupply()) / _pool;
        }
        lastDepositTime[msg.sender] = block.timestamp;
        _mint(msg.sender, shares);
    }

    function withdraw(
        uint256 _shares,
        address _toToken,
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) external checkFinalized {
        // burn user shares
        uint256 underlyingToSend = (balance() * _shares) / totalSupply();
        _burn(msg.sender, _shares);

        // deduct early withdrawal fee
        if (
            lastDepositTime[msg.sender] + withdrawPenaltyTime >= block.timestamp
        ) {
            uint256 earlyWithdrawalFee =
                (underlyingToSend * withdrawPenalty) / BPS_MAX;
            underlyingToSend -= earlyWithdrawalFee;
        }

        // check balance
        uint256 underlyingBalance = underlying.balanceOf(address(this));
        if (underlyingBalance < underlyingToSend) {
            uint256 underlyingToWithdraw = underlyingToSend - underlyingBalance;
            // withdraw from staking contract
            _withdraw(underlyingToWithdraw);
        }

        // swap to _toToken
        uint256 toTokenAmt =
            _fillQuote(
                address(underlying),
                _toToken,
                underlyingToSend,
                _swapTarget,
                _swapData,
                _minToTokens
            );

        // send _toToken to user
        if (_toToken == address(0)) {
            payable(msg.sender).transfer(toTokenAmt);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, toTokenAmt);
        }
    }

    function harvest(
        address[] memory _swapTargets,
        bytes[] memory _swapDatas,
        uint256[] memory _minToTokens
    ) external stopInEmergency {
        if (isFinalized) {
            require(
                controller.approvedKeepers(msg.sender),
                "ZSS: Keeper not Authorized"
            );
        } else {
            // only allow strategist to interact if Not finalized
            require(msg.sender == strategist, "ZSS: Not Finalized");
        }

        require(
            (_swapTargets.length == rewardTokens.length) &&
                (_swapDatas.length == rewardTokens.length) &&
                (_minToTokens.length == rewardTokens.length),
            "Incorrect array length"
        );

        // claim reward
        (address[] memory claimTargets, bytes[] memory claimCallData) =
            controller.claimReward();

        for (uint256 i; i < claimTargets.length; i++) {
            (bool claimSuccess, ) = claimTargets[i].call(claimCallData[i]);
            require(claimSuccess, "Can't claim reward");
        }

        // Convert to underlying token
        uint256 underlyingReceived;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 rewardAmount = _getBalance(rewardTokens[i]);

            underlyingReceived += _fillQuote(
                rewardTokens[i],
                address(underlying),
                rewardAmount,
                _swapTargets[i],
                _swapDatas[i],
                _minToTokens[i]
            );
        }

        // deduct fees
        uint256 strategistShare =
            (underlyingReceived * controller.strategistFees()) / 10000;
        uint256 keeperShare =
            (underlyingReceived * controller.keeperFees()) / 10000;

        underlying.safeTransfer(strategist, strategistShare);
        underlying.safeTransfer(msg.sender, keeperShare);

        // deposit back into staking contract
        uint256 underlyingToDeposit =
            underlyingReceived - strategistShare - keeperShare;
        _deposit(underlyingToDeposit);

        _updateTWAP();
    }

    function modifyPoolParams(
        address _new_underlying,
        address[] calldata _new_rewardTokens
    ) external onlyController {
        underlying = IERC20(_new_underlying);
        rewardTokens = _new_rewardTokens;
    }

    function finalizePool() external {
        require(msg.sender == strategist, "ZSS: Not Strategist");
        require(!isFinalized, "ZSS: Already Finalized");

        isFinalized = true;
    }

    function togglePoolActive() external onlyController {
        stopped = !stopped;
    }

    function updateDepositBuffer(uint256 _new_toDepositBuffer)
        external
        onlyController
    {
        require(_new_toDepositBuffer <= BPS_MAX, "Can't exceed BPS_MAX");
        toDepositBuffer = _new_toDepositBuffer;
    }

    function updateWithdrawPenalty(uint256 _new_withdrawPenalty)
        external
        onlyController
    {
        require(_new_withdrawPenalty <= BPS_MAX, "Can't exceed BPS_MAX");
        withdrawPenalty = _new_withdrawPenalty;
    }

    function updateWithdrawPenaltyTime(uint256 _new_withdrawPenaltyTime)
        external
        onlyController
    {
        withdrawPenaltyTime = _new_withdrawPenaltyTime;
    }

    // --- External View Functions ---

    function balance() public view returns (uint256) {
        return totalStaked + availableBuffer();
    }

    function availableBuffer() public view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function pricePerShare() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }

        return (balance() * 1e18) / totalSupply();
    }

    function pendingRewards()
        external
        view
        returns (
            uint256[] memory claimableRewards,
            uint256[] memory rewardTokensBalance
        )
    {
        (address[] memory targets, bytes[] memory staticCallData) =
            controller.pendingRewards();

        uint256 countA = targets.length;
        claimableRewards = new uint256[](countA);

        for (uint256 i = 0; i < countA; i++) {
            (bool success, bytes memory returnData) =
                targets[i].staticcall(staticCallData[i]);
            require(success, "Error getting reward");

            claimableRewards[i] = abi.decode(returnData, (uint256));
        }

        uint256 countB = rewardTokens.length;
        rewardTokensBalance = new uint256[](countB);

        for (uint256 i = 0; i < countB; i++) {
            rewardTokensBalance[i] = _getBalance(rewardTokens[i]);
        }
    }

    // --- Internal Mutative Functions ---

    function _deposit(uint256 amount) internal {
        (address depositTarget, bytes memory depositCallData) =
            controller.deposit(amount);

        _approveToken(address(underlying), depositTarget);
        (bool success, ) = depositTarget.call(depositCallData);
        require(success, "Can't deposit");
        totalStaked += amount;
    }

    function _withdraw(uint256 amount) internal {
        (address target, bytes memory withdrawCallData) =
            controller.withdraw(amount);

        (bool success, ) = target.call(withdrawCallData);
        require(success, "Can't withdraw");
        totalStaked -= amount;
    }

    function _updateTWAP() internal {
        uint256 timeElapsed = block.timestamp - TWAP.lastTimeStamp;
        uint256 newPriceCumulative =
            TWAP.priceCumulative + pricePerShare() * timeElapsed;

        TWAP.priceCumulative = newPriceCumulative;
        TWAP.lastTimeStamp = block.timestamp;

        emit TWAP_Update(newPriceCumulative, block.timestamp, pricePerShare());
    }

    function _pullTokens(address token, uint256 amount) internal {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            return;
        }

        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        // transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _approveToken(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) return;
        else {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    function _fillQuote(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapData,
        uint256 _minToTokens
    ) internal returns (uint256 amtBought) {
        if (_fromToken == _toToken) {
            return _amount;
        }

        if (_fromToken == address(0) && _toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (_fromToken == wethTokenAddress && _toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (_fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromToken, _swapTarget);
        }

        uint256 iniBal = _getBalance(_toToken);
        require(
            controller.approvedTargets(_swapTarget),
            "ZSS: Target not Authorized"
        );
        (bool success, ) = _swapTarget.call{ value: valueToSend }(_swapData);
        require(success, "ZSS: Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toToken);

        amtBought = finalBal - iniBal;
        require(amtBought >= _minToTokens, "ZSS: High Slippage");
    }

    // --- Internal View Functions ---

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    // --- Receive ---

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface IController {
    function approvedDeployers(address) external view returns (bool);

    function approvedKeepers(address) external view returns (bool);

    function approvedTargets(address) external view returns (bool);

    function claimReward()
        external
        view
        returns (address[] memory targets, bytes[] memory claimCallData);

    function deposit(uint256 _amountIn)
        external
        view
        returns (address target, bytes memory depositCallData);

    function getPoolsCount() external view returns (uint256);

    function implementation() external view returns (address);

    function initialize(
        address _implementation,
        uint256 _strategistFees,
        uint256 _keeperFees
    ) external;

    function keeperFees() external view returns (uint256);

    function nullBytes() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingRewards()
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory pendingRewardsInfoCallData
        );

    function poolInfo(address)
        external
        view
        returns (
            address stakingContract,
            bytes memory preDepositData,
            bytes memory postDepositData,
            bytes memory preWithdrawData,
            bytes memory postWithdrawData
        );

    function pools(uint256) external view returns (address);

    function predictPoolAddress(
        address _underlying,
        address _stakingContract,
        bytes memory _preDepositData,
        bytes memory _postDepositData,
        bytes memory _preWithdrawData,
        bytes memory _postWithdrawData
    ) external view returns (address);

    function renounceOwnership() external;

    function setApprovedDeployers(
        address[] memory deployers,
        bool[] memory isApproved
    ) external;

    function setApprovedKeepers(
        address[] memory keepers,
        bool[] memory isApproved
    ) external;

    function setApprovedTargets(
        address[] memory targets,
        bool[] memory isApproved
    ) external;

    function strategistFees() external view returns (uint256);

    function togglePoolActive(address _poolAddress) external;

    function transferOwnership(address newOwner) external;

    function updateFees(uint256 _new_strategistFees, uint256 _new_keeperFees)
        external;

    function updateImplementation(address _new_implementation) external;

    function withdraw(uint256 _amountOut)
        external
        view
        returns (address target, bytes memory withdrawCallData);
}