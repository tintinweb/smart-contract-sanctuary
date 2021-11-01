// SPDX-License-Identifier: MIT

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAccessControl.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, IAccessControl {
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external override {
        require(account == msg.sender, "71");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IAgToken
/// @author Angle Core Team
/// @notice Interface for the stablecoins `AgToken` contracts
/// @dev The only functions that are left in the interface are the functions which are used
/// at another point in the protocol by a different contract
interface IAgToken is IERC20Upgradeable {
    // ======================= `StableMaster` functions ============================
    function mint(address account, uint256 amount) external;

    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    function burnSelf(uint256 amount, address burner) external;

    // ========================= External function =================================

    function stableMaster() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title ICollateralSettler
/// @author Angle Core Team
/// @notice Interface for the collateral settlement contracts
interface ICollateralSettler {
    function triggerSettlement(
        uint256 _oracleValue,
        uint256 _sanRate,
        uint256 _stocksUsers
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IStableMaster.sol";

/// @title ICore
/// @author Angle Core Team
/// @dev Interface for the functions of the `Core` contract
interface ICore {
    function revokeStableMaster(address stableMaster) external;

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address _guardian) external;

    function revokeGuardian() external;

    function governorList() external view returns (address[] memory);

    function stablecoinList() external view returns (address[] memory);

    function guardian() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IAccessControl.sol";

/// @title IFeeManagerFunctions
/// @author Angle Core Team
/// @dev Interface for the `FeeManager` contract
interface IFeeManagerFunctions is IAccessControl {
    // ================================= Keepers ===================================

    function updateUsersSLP() external;

    function updateHA() external;

    // ================================= Governance ================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        address _perpetualManager
    ) external;

    function setFees(
        uint256[] memory xArray,
        uint64[] memory yArray,
        uint8 typeChange
    ) external;

    function setHAFees(uint64 _haFeeDeposit, uint64 _haFeeWithdraw) external;
}

/// @title IFeeManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev We need these getters as they are used in other contracts of the protocol
interface IFeeManager is IFeeManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IOracle
/// @author Angle Core Team
/// @notice Interface for Angle's oracle contracts reading oracle rates from both UniswapV3 and Chainlink
/// from just UniswapV3 or from just Chainlink
interface IOracle {
    function read() external view returns (uint256);

    function readAll() external view returns (uint256 lowerRate, uint256 upperRate);

    function readLower() external view returns (uint256);

    function readUpper() external view returns (uint256);

    function readQuote(uint256 baseAmount) external view returns (uint256);

    function readQuoteLower(uint256 baseAmount) external view returns (uint256);

    function inBase() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IFeeManager.sol";
import "./IOracle.sol";
import "./IAccessControl.sol";

/// @title Interface of the contract managing perpetuals
/// @author Angle Core Team
/// @dev Front interface, meaning only user-facing functions
interface IPerpetualManagerFront is IERC721Metadata {
    function openPerpetual(
        address owner,
        uint256 amountBrought,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin
    ) external returns (uint256 perpetualID);

    function closePerpetual(
        uint256 perpetualID,
        address to,
        uint256 minCashOutAmount
    ) external;

    function addToPerpetual(uint256 perpetualID, uint256 amount) external;

    function removeFromPerpetual(
        uint256 perpetualID,
        uint256 amount,
        address to
    ) external;

    function liquidatePerpetuals(uint256[] memory perpetualIDs) external;

    function forceClosePerpetuals(uint256[] memory perpetualIDs) external;

    // ========================= External View Functions =============================

    function getCashOutAmount(uint256 perpetualID, uint256 rate) external view returns (uint256, uint256);

    function isApprovedOrOwner(address spender, uint256 perpetualID) external view returns (bool);
}

/// @title Interface of the contract managing perpetuals
/// @author Angle Core Team
/// @dev This interface does not contain user facing functions, it just has functions that are
/// interacted with in other parts of the protocol
interface IPerpetualManagerFunctions is IAccessControl {
    // ================================= Governance ================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IFeeManager feeManager,
        IOracle oracle_
    ) external;

    function setFeeManager(IFeeManager feeManager_) external;

    function setHAFees(
        uint64[] memory _xHAFees,
        uint64[] memory _yHAFees,
        uint8 deposit
    ) external;

    function setTargetAndLimitHAHedge(uint64 _targetHAHedge, uint64 _limitHAHedge) external;

    function setKeeperFeesLiquidationRatio(uint64 _keeperFeesLiquidationRatio) external;

    function setKeeperFeesCap(uint256 _keeperFeesLiquidationCap, uint256 _keeperFeesClosingCap) external;

    function setKeeperFeesClosing(uint64[] memory _xKeeperFeesClosing, uint64[] memory _yKeeperFeesClosing) external;

    function setLockTime(uint64 _lockTime) external;

    function setBoundsPerpetual(uint64 _maxLeverage, uint64 _maintenanceMargin) external;

    function pause() external;

    function unpause() external;

    // ==================================== Keepers ================================

    function setFeeKeeper(uint64 feeDeposit, uint64 feesWithdraw) external;

    // =============================== StableMaster ================================

    function setOracle(IOracle _oracle) external;
}

/// @title IPerpetualManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IPerpetualManager is IPerpetualManagerFunctions {
    function poolManager() external view returns (address);

    function oracle() external view returns (address);

    function targetHAHedge() external view returns (uint64);

    function totalHedgeAmount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IFeeManager.sol";
import "./IPerpetualManager.sol";
import "./IOracle.sol";

// Struct for the parameters associated to a strategy interacting with a collateral `PoolManager`
// contract
struct StrategyParams {
    // Timestamp of last report made by this strategy
    // It is also used to check if a strategy has been initialized
    uint256 lastReport;
    // Total amount the strategy is expected to have
    uint256 totalStrategyDebt;
    // The share of the total assets in the `PoolManager` contract that the `strategy` can access to.
    uint256 debtRatio;
}

/// @title IPoolManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the collateral poolManager contracts handling each one type of collateral for
/// a given stablecoin
/// @dev Only the functions used in other contracts of the protocol are left here
interface IPoolManagerFunctions {
    // ============================ Constructor ====================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IPerpetualManager _perpetualManager,
        IFeeManager feeManager,
        IOracle oracle
    ) external;

    // ============================ Yield Farming ==================================

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;

    // ============================ Governance =====================================

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address _guardian, address guardian) external;

    function revokeGuardian(address guardian) external;

    function setFeeManager(IFeeManager _feeManager) external;

    // ============================= Getters =======================================

    function getBalance() external view returns (uint256);

    function getTotalAsset() external view returns (uint256);
}

/// @title IPoolManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev Used in other contracts of the protocol
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);

    function token() external view returns (address);

    function feeManager() external view returns (address);

    function totalDebt() external view returns (uint256);

    function strategies(address _strategy) external view returns (StrategyParams memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title ISanToken
/// @author Angle Core Team
/// @notice Interface for Angle's `SanToken` contract that handles sanTokens, tokens that are given to SLPs
/// contributing to a collateral for a given stablecoin
interface ISanToken is IERC20Upgradeable {
    // ================================== StableMaster =============================

    function mint(address account, uint256 amount) external;

    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    function burnSelf(uint256 amount, address burner) external;

    function stableMaster() external view returns (address);

    function poolManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Normally just importing `IPoolManager` should be sufficient, but for clarity here
// we prefer to import all concerned interfaces
import "./IPoolManager.sol";
import "./IOracle.sol";
import "./IPerpetualManager.sol";
import "./ISanToken.sol";

// Struct to handle all the parameters to manage the fees
// related to a given collateral pool (associated to the stablecoin)
struct MintBurnData {
    // Values of the thresholds to compute the minting fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeMint;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeMint;
    // Values of the thresholds to compute the burning fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeBurn;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeBurn;
    // Max proportion of collateral from users that can be covered by HAs
    // It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
    // the other changes accordingly
    uint64 targetHAHedge;
    // Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusMint;
    // Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusBurn;
    // Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
    uint256 capOnStableMinted;
}

// Struct to handle all the variables and parameters to handle SLPs in the protocol
// including the fraction of interests they receive or the fees to be distributed to
// them
struct SLPData {
    // Last timestamp at which the `sanRate` has been updated for SLPs
    uint256 lastBlockUpdated;
    // Fees accumulated from previous blocks and to be distributed to SLPs
    uint256 lockedInterests;
    // Max interests used to update the `sanRate` in a single block
    // Should be in collateral token base
    uint256 maxInterestsDistributed;
    // Amount of fees left aside for SLPs and that will be distributed
    // when the protocol is collateralized back again
    uint256 feesAside;
    // Part of the fees normally going to SLPs that is left aside
    // before the protocol is collateralized back again (depends on collateral ratio)
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippageFee;
    // Portion of the fees from users minting and burning
    // that goes to SLPs (the rest goes to surplus)
    uint64 feesForSLPs;
    // Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
    // If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippage;
    // Portion of the interests from lending
    // that goes to SLPs (the rest goes to surplus)
    uint64 interestsForSLPs;
}

/// @title IStableMasterFunctions
/// @author Angle Core Team
/// @notice Interface for the `StableMaster` contract
interface IStableMasterFunctions {
    function deploy(
        address[] memory _governorList,
        address _guardian,
        address _agToken
    ) external;

    // ============================== Lending ======================================

    function accumulateInterest(uint256 gain) external;

    function signalLoss(uint256 loss) external;

    // ============================== HAs ==========================================

    function getStocksUsers() external view returns (uint256 maxCAmountInStable);

    function convertToSLP(uint256 amount, address user) external;

    // ============================== Keepers ======================================

    function getCollateralRatio() external returns (uint256);

    function setFeeKeeper(
        uint64 feeMint,
        uint64 feeBurn,
        uint64 _slippage,
        uint64 _slippageFee
    ) external;

    // ============================== AgToken ======================================

    function updateStocksUsers(uint256 amount, address poolManager) external;

    // ============================= Governance ====================================

    function setCore(address newCore) external;

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address newGuardian, address oldGuardian) external;

    function revokeGuardian(address oldGuardian) external;

    function setCapOnStableAndMaxInterests(
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed,
        IPoolManager poolManager
    ) external;

    function setIncentivesForSLPs(
        uint64 _feesForSLPs,
        uint64 _interestsForSLPs,
        IPoolManager poolManager
    ) external;

    function setUserFees(
        IPoolManager poolManager,
        uint64[] memory _xFee,
        uint64[] memory _yFee,
        uint8 _mint
    ) external;

    function setTargetHAHedge(uint64 _targetHAHedge) external;

    function pause(bytes32 agent, IPoolManager poolManager) external;

    function unpause(bytes32 agent, IPoolManager poolManager) external;
}

/// @title IStableMaster
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
interface IStableMaster is IStableMasterFunctions {
    function agToken() external view returns (address);

    function collateralMap(IPoolManager poolManager)
        external
        view
        returns (
            IERC20 token,
            ISanToken sanToken,
            IPerpetualManager perpetualManager,
            IOracle oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./StableMasterInternal.sol";

/// @title StableMaster
/// @author Angle Core Team
/// @notice `StableMaster` is the contract handling all the collateral types accepted for a given stablecoin
/// It does all the accounting and is the point of entry in the protocol for stable holders and seekers as well as SLPs
/// @dev This file contains the core functions of the `StableMaster` contract
contract StableMaster is StableMasterInternal, IStableMasterFunctions, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Role for governors only
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    /// @notice Role for guardians and governors
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    /// @notice Role for `Core` only, used to propagate guardian and governors
    bytes32 public constant CORE_ROLE = keccak256("CORE_ROLE");

    bytes32 public constant STABLE = keccak256("STABLE");
    bytes32 public constant SLP = keccak256("SLP");

    // ============================ DEPLOYER =======================================

    /// @notice Creates the access control logic for the governor and guardian addresses
    /// @param governorList List of the governor addresses of the protocol
    /// @param guardian Guardian address of the protocol
    /// @param _agToken Reference to the `AgToken`, that is the ERC20 token handled by the `StableMaster`
    /// @dev This function is called by the `Core` when a stablecoin is deployed to maintain consistency
    /// across the governor and guardian roles
    /// @dev When this function is called by the `Core`, it has already been checked that the `stableMaster`
    /// corresponding to the `agToken` was this `stableMaster`
    function deploy(
        address[] memory governorList,
        address guardian,
        address _agToken
    ) external override onlyRole(CORE_ROLE) {
        for (uint256 i = 0; i < governorList.length; i++) {
            _grantRole(GOVERNOR_ROLE, governorList[i]);
            _grantRole(GUARDIAN_ROLE, governorList[i]);
        }
        _grantRole(GUARDIAN_ROLE, guardian);
        agToken = IAgToken(_agToken);
        // Since there is only one address that can be the `AgToken`, and since `AgToken`
        // is not to be admin of any role, we do not define any access control role for it
    }

    // ============================ STRATEGIES =====================================

    /// @notice Takes into account the gains made while lending and distributes it to SLPs by updating the `sanRate`
    /// @param gain Interests accumulated from lending
    /// @dev This function is called by a `PoolManager` contract having some yield farming strategies associated
    /// @dev To prevent flash loans, the `sanRate` is not directly updated, it is updated at the blocks that follow
    function accumulateInterest(uint256 gain) external override {
        // Searching collateral data
        Collateral storage col = collateralMap[IPoolManager(msg.sender)];
        _contractMapCheck(col);
        // A part of the gain goes to SLPs, the rest to the surplus of the protocol
        _updateSanRate((gain * col.slpData.interestsForSLPs) / BASE_PARAMS, col);
    }

    /// @notice Takes into account a loss made by a yield farming strategy
    /// @param loss Loss made by the yield farming strategy
    /// @dev This function is called by a `PoolManager` contract having some yield farming strategies associated
    /// @dev Fees are not accumulated for this function before being distributed: everything is directly used to
    /// update the `sanRate`
    function signalLoss(uint256 loss) external override {
        // Searching collateral data
        IPoolManager poolManager = IPoolManager(msg.sender);
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        uint256 sanMint = col.sanToken.totalSupply();
        if (sanMint != 0) {
            // Updating the `sanRate` and the `lockedInterests` by taking into account a loss
            if (col.sanRate * sanMint + col.slpData.lockedInterests * BASE_TOKENS > loss * BASE_TOKENS) {
                // The loss is first taken from the `lockedInterests`
                uint256 withdrawFromLoss = col.slpData.lockedInterests;

                if (withdrawFromLoss >= loss) {
                    withdrawFromLoss = loss;
                }

                col.slpData.lockedInterests -= withdrawFromLoss;
                col.sanRate -= ((loss - withdrawFromLoss) * BASE_TOKENS) / sanMint;
            } else {
                // Normally it should be set to 0, but this would imply that no SLP can enter afterwards
                // we therefore set it to 1 (equivalent to 10**(-18))
                col.sanRate = 1;
                col.slpData.lockedInterests = 0;
                // As it is a critical time, governance pauses SLPs to solve the situation
                _pause(keccak256(abi.encodePacked(SLP, address(poolManager))));
            }
            emit SanRateUpdated(address(col.token), col.sanRate);
        }
    }

    // ============================== HAs ==========================================

    /// @notice Transforms a HA position into a SLP Position
    /// @param amount The amount to transform
    /// @param user Address to mint sanTokens to
    /// @dev Can only be called by a `PerpetualManager` contract
    /// @dev This is typically useful when a HA wishes to cash out but there is not enough collateral
    /// in reserves
    function convertToSLP(uint256 amount, address user) external override {
        // Data about the `PerpetualManager` calling the function is fetched using the `contractMap`
        IPoolManager poolManager = _contractMap[msg.sender];
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        // If SLPs are paused, in this situation, then this transaction should revert
        // In this extremely rare case, governance should take action and also pause HAs
        _whenNotPaused(SLP, address(poolManager));
        _updateSanRate(0, col);
        col.sanToken.mint(user, (amount * BASE_TOKENS) / col.sanRate);
    }

    /// @notice Sets the proportion of `stocksUsers` available for perpetuals
    /// @param _targetHAHedge New value of the hedge ratio that the protocol wants to arrive to
    /// @dev Can only be called by the `PerpetualManager`
    function setTargetHAHedge(uint64 _targetHAHedge) external override {
        // Data about the `PerpetualManager` calling the function is fetched using the `contractMap`
        IPoolManager poolManager = _contractMap[msg.sender];
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        col.feeData.targetHAHedge = _targetHAHedge;
        // No need to issue an event here, one has already been issued by the corresponding `PerpetualManager`
    }

    // ============================ VIEW FUNCTIONS =================================

    /// @notice Transmits to the `PerpetualManager` the max amount of collateral (in stablecoin value) HAs can hedge
    /// @return _stocksUsers All stablecoins currently assigned to the pool of the caller
    /// @dev This function will not return something relevant if it is not called by a `PerpetualManager`
    function getStocksUsers() external view override returns (uint256 _stocksUsers) {
        _stocksUsers = collateralMap[_contractMap[msg.sender]].stocksUsers;
    }

    /// @notice Returns the collateral ratio for this stablecoin
    /// @dev The ratio returned is scaled by `BASE_PARAMS` since the value is used to
    /// in the `FeeManager` contrat to be compared with the values in `xArrays` expressed in `BASE_PARAMS`
    function getCollateralRatio() external view override returns (uint256) {
        uint256 mints = agToken.totalSupply();
        if (mints == 0) {
            // If nothing has been minted, the collateral ratio is infinity
            return type(uint256).max;
        }
        uint256 val;
        for (uint256 i = 0; i < _managerList.length; i++) {
            // Oracle needs to be called for each collateral to compute the collateral ratio
            val += collateralMap[_managerList[i]].oracle.readQuote(_managerList[i].getTotalAsset());
        }
        return (val * BASE_PARAMS) / mints;
    }

    // ============================== KEEPERS ======================================

    /// @notice Updates all the fees not depending on personal agents inputs via a keeper calling the corresponding
    /// function in the `FeeManager` contract
    /// @param _bonusMalusMint New corrector of user mint fees for this collateral. These fees will correct
    /// the mint fees from users that just depend on the hedge curve by HAs by introducing other dependencies.
    /// In normal times they will be equal to `BASE_PARAMS` meaning fees will just depend on the hedge ratio
    /// @param _bonusMalusBurn New corrector of user burn fees, depending on collateral ratio
    /// @param _slippage New global slippage (the SLP fees from withdrawing) factor
    /// @param _slippageFee New global slippage fee (the non distributed accumulated fees) factor
    function setFeeKeeper(
        uint64 _bonusMalusMint,
        uint64 _bonusMalusBurn,
        uint64 _slippage,
        uint64 _slippageFee
    ) external override {
        // Fetching data about the `FeeManager` contract calling this function
        // It is stored in the `_contractMap`
        Collateral storage col = collateralMap[_contractMap[msg.sender]];
        _contractMapCheck(col);

        col.feeData.bonusMalusMint = _bonusMalusMint;
        col.feeData.bonusMalusBurn = _bonusMalusBurn;
        col.slpData.slippage = _slippage;
        col.slpData.slippageFee = _slippageFee;
        // An event is already emitted in the `FeeManager` contract
    }

    // ============================== AgToken ======================================

    /// @notice Allows the `agToken` contract to update the `stocksUsers` for a given collateral after a burn
    /// with no redeem
    /// @param amount Amount by which `stocksUsers` should decrease
    /// @param poolManager Reference to `PoolManager` for which `stocksUsers` needs to be updated
    /// @dev This function can be called by the `agToken` contract after a burn of agTokens for which no collateral has been
    /// redeemed
    function updateStocksUsers(uint256 amount, address poolManager) external override {
        require(msg.sender == address(agToken), "3");
        Collateral storage col = collateralMap[IPoolManager(poolManager)];
        _contractMapCheck(col);
        require(col.stocksUsers >= amount, "4");
        col.stocksUsers -= amount;
        emit StocksUsersUpdated(address(col.token), col.stocksUsers);
    }

    // ================================= GOVERNANCE ================================

    // =============================== Core Functions ==============================

    /// @notice Changes the `Core` contract
    /// @param newCore New core address
    /// @dev This function can only be called by the `Core` contract
    function setCore(address newCore) external override onlyRole(CORE_ROLE) {
        // Access control for this contract
        _revokeRole(CORE_ROLE, address(_core));
        _grantRole(CORE_ROLE, newCore);
        _core = ICore(newCore);
    }

    /// @notice Adds a new governor address
    /// @param governor New governor address
    /// @dev This function propagates changes from `Core` to other contracts
    /// @dev Propagating changes like that allows to maintain the protocol's integrity
    function addGovernor(address governor) external override onlyRole(CORE_ROLE) {
        // Access control for this contract
        _grantRole(GOVERNOR_ROLE, governor);
        _grantRole(GUARDIAN_ROLE, governor);

        for (uint256 i = 0; i < _managerList.length; i++) {
            // The `PoolManager` will echo the changes across all the corresponding contracts
            _managerList[i].addGovernor(governor);
        }
    }

    /// @notice Removes a governor address which loses its role
    /// @param governor Governor address to remove
    /// @dev This function propagates changes from `Core` to other contracts
    /// @dev Propagating changes like that allows to maintain the protocol's integrity
    /// @dev It has already been checked in the `Core` that this address could be removed
    /// and that it would not put the protocol in a situation with no governor at all
    function removeGovernor(address governor) external override onlyRole(CORE_ROLE) {
        // Access control for this contract
        _revokeRole(GOVERNOR_ROLE, governor);
        _revokeRole(GUARDIAN_ROLE, governor);

        for (uint256 i = 0; i < _managerList.length; i++) {
            // The `PoolManager` will echo the changes across all the corresponding contracts
            _managerList[i].removeGovernor(governor);
        }
    }

    /// @notice Changes the guardian address
    /// @param newGuardian New guardian address
    /// @param oldGuardian Old guardian address
    /// @dev This function propagates changes from `Core` to other contracts
    /// @dev The zero check for the guardian address has already been performed by the `Core`
    /// contract
    function setGuardian(address newGuardian, address oldGuardian) external override onlyRole(CORE_ROLE) {
        _revokeRole(GUARDIAN_ROLE, oldGuardian);
        _grantRole(GUARDIAN_ROLE, newGuardian);

        for (uint256 i = 0; i < _managerList.length; i++) {
            _managerList[i].setGuardian(newGuardian, oldGuardian);
        }
    }

    /// @notice Revokes the guardian address
    /// @param oldGuardian Guardian address to revoke
    /// @dev This function propagates changes from `Core` to other contracts
    function revokeGuardian(address oldGuardian) external override onlyRole(CORE_ROLE) {
        _revokeRole(GUARDIAN_ROLE, oldGuardian);
        for (uint256 i = 0; i < _managerList.length; i++) {
            _managerList[i].revokeGuardian(oldGuardian);
        }
    }

    // ============================= Governor Functions ============================

    /// @notice Deploys a new collateral by creating the correct references in the corresponding contracts
    /// @param poolManager Contract managing and storing this collateral for this stablecoin
    /// @param perpetualManager Contract managing HA perpetuals for this stablecoin
    /// @param oracle Reference to the oracle that will give the price of the collateral with respect to the stablecoin
    /// @param sanToken Reference to the sanTokens associated to the collateral
    /// @dev All the references in parameters should correspond to contracts that have already been deployed and
    /// initialized with appropriate references
    /// @dev After calling this function, governance should initialize all parameters corresponding to this new collateral
    function deployCollateral(
        IPoolManager poolManager,
        IPerpetualManager perpetualManager,
        IFeeManager feeManager,
        IOracle oracle,
        ISanToken sanToken
    ) external onlyRole(GOVERNOR_ROLE) {
        // If the `sanToken`, `poolManager`, `perpetualManager` and `feeManager` were zero
        // addresses, the following require would fail
        // The only elements that are checked here are those that are defined in the constructors/initializers
        // of the concerned contracts
        require(
            sanToken.stableMaster() == address(this) &&
                sanToken.poolManager() == address(poolManager) &&
                poolManager.stableMaster() == address(this) &&
                perpetualManager.poolManager() == address(poolManager) &&
                // If the `feeManager` is not initialized with the correct `poolManager` then this function
                // will revert when `poolManager.deployCollateral` will be executed
                feeManager.stableMaster() == address(this),
            "9"
        );
        // Checking if the base of the tokens and of the oracle are not similar with one another
        address token = poolManager.token();
        uint256 collatBase = 10**(IERC20Metadata(token).decimals());
        // If the address of the oracle was the zero address, the following would revert
        require(oracle.inBase() == collatBase, "11");
        // Checking if the collateral has not already been deployed
        Collateral storage col = collateralMap[poolManager];
        require(address(col.token) == address(0), "13");

        // Creating the correct references
        col.token = IERC20(token);
        col.sanToken = sanToken;
        col.perpetualManager = perpetualManager;
        col.oracle = oracle;
        // Initializing with the correct values
        col.sanRate = BASE_TOKENS;
        col.collatBase = collatBase;

        // Adding the correct references in the `contractMap` we use in order not to have to pass addresses when
        // calling the `StableMaster` from the `PerpetualManager` contract, or the `FeeManager` contract
        // This is equivalent to granting Access Control roles for these contracts
        _contractMap[address(perpetualManager)] = poolManager;
        _contractMap[address(feeManager)] = poolManager;
        _managerList.push(poolManager);

        // Pausing agents at deployment to leave governance time to set parameters
        // The `PerpetualManager` contract is automatically paused after being initialized, so HAs will not be able to
        // interact with the protocol
        _pause(keccak256(abi.encodePacked(SLP, address(poolManager))));
        _pause(keccak256(abi.encodePacked(STABLE, address(poolManager))));

        // Fetching the governor list and the guardian to initialize the `poolManager` correctly
        address[] memory governorList = _core.governorList();
        address guardian = _core.guardian();

        // Propagating the deployment and passing references to the corresponding contracts
        poolManager.deployCollateral(governorList, guardian, perpetualManager, feeManager, oracle);
        emit CollateralDeployed(address(poolManager), address(perpetualManager), address(sanToken), address(oracle));
    }

    /// @notice Removes a collateral from the list of accepted collateral types and pauses all actions associated
    /// to this collateral
    /// @param poolManager Reference to the contract managing this collateral for this stablecoin in the protocol
    /// @param settlementContract Settlement contract that will be used to close everyone's positions and to let
    /// users, SLPs and HAs redeem if not all a portion of their claim
    /// @dev Since this function has the ability to transfer the contract's funds to another contract, it should
    /// only be accessible to the governor
    /// @dev Before calling this function, governance should make sure that all the collateral lent to strategies
    /// has been withdrawn
    function revokeCollateral(IPoolManager poolManager, ICollateralSettler settlementContract)
        external
        onlyRole(GOVERNOR_ROLE)
    {
        // Checking if the `poolManager` given here is well in the list of managers and taking advantage of that to remove
        // the `poolManager` from the list
        uint256 indexMet;
        uint256 managerListLength = _managerList.length;
        require(managerListLength >= 1, "10");
        for (uint256 i = 0; i < managerListLength - 1; i++) {
            if (_managerList[i] == poolManager) {
                indexMet = 1;
                _managerList[i] = _managerList[managerListLength - 1];
                break;
            }
        }
        require(indexMet == 1 || _managerList[managerListLength - 1] == poolManager, "10");
        _managerList.pop();
        Collateral memory col = collateralMap[poolManager];

        // Deleting the references of the associated contracts: `perpetualManager` and `keeper` in the
        // `_contractMap` and `poolManager` from the `collateralMap`
        delete _contractMap[poolManager.feeManager()];
        delete _contractMap[address(col.perpetualManager)];
        delete collateralMap[poolManager];
        emit CollateralRevoked(address(poolManager));

        // Pausing entry (and exits for HAs)
        col.perpetualManager.pause();
        // No need to pause `SLP` and `STABLE_HOLDERS` as deleting the entry associated to the `poolManager`
        // in the `collateralMap` will make everything revert

        // Transferring the whole balance to global settlement
        uint256 balance = col.token.balanceOf(address(poolManager));
        col.token.safeTransferFrom(address(poolManager), address(settlementContract), balance);

        // Settlement works with a fixed oracle value for HAs, it needs to be computed here
        uint256 oracleValue = col.oracle.readLower();
        // Notifying the global settlement contract with the properties of the contract to settle
        // In case of global shutdown, there would be one settlement contract per collateral type
        // Not using the `lockedInterests` to update the value of the sanRate
        settlementContract.triggerSettlement(oracleValue, col.sanRate, col.stocksUsers);
    }

    // ============================= Guardian Functions ============================

    /// @notice Pauses an agent's actions within this contract for a given collateral type for this stablecoin
    /// @param agent Bytes representing the agent (`SLP` or `STABLE`) and the collateral type that is going to
    /// be paused. To get the `bytes32` from a string, we use in Solidity a `keccak256` function
    /// @param poolManager Reference to the contract managing this collateral for this stablecoin in the protocol and
    /// for which `agent` needs to be paused
    /// @dev If agent is `STABLE`, it is going to be impossible for users to mint stablecoins using collateral or to burn
    /// their stablecoins
    /// @dev If agent is `SLP`, it is going to be impossible for SLPs to deposit collateral and receive
    /// sanTokens in exchange, or to withdraw collateral from their sanTokens
    function pause(bytes32 agent, IPoolManager poolManager) external override onlyRole(GUARDIAN_ROLE) {
        Collateral storage col = collateralMap[poolManager];
        // Checking for the `poolManager`
        _contractMapCheck(col);
        _pause(keccak256(abi.encodePacked(agent, address(poolManager))));
    }

    /// @notice Unpauses an agent's action for a given collateral type for this stablecoin
    /// @param agent Agent (`SLP` or `STABLE`) to unpause the action of
    /// @param poolManager Reference to the associated `PoolManager`
    /// @dev Before calling this function, the agent should have been paused for this collateral
    function unpause(bytes32 agent, IPoolManager poolManager) external override onlyRole(GUARDIAN_ROLE) {
        Collateral storage col = collateralMap[poolManager];
        // Checking for the `poolManager`
        _contractMapCheck(col);
        _unpause(keccak256(abi.encodePacked(agent, address(poolManager))));
    }

    /// @notice Updates the `stocksUsers` for a given pair of collateral
    /// @param amount Amount of `stocksUsers` to transfer from a pool to another
    /// @param poolManagerUp Reference to `PoolManager` for which `stocksUsers` needs to increase
    /// @param poolManagerDown Reference to `PoolManager` for which `stocksUsers` needs to decrease
    /// @dev This function can be called in case where the reserves of the protocol for each collateral do not exactly
    /// match what is stored in the `stocksUsers` because of increases or decreases in collateral prices at times
    /// in which the protocol was not fully hedged by HAs
    /// @dev With this function, governance can allow/prevent more HAs coming in a pool while preventing/allowing HAs
    /// from other pools because the accounting variable of `stocksUsers` does not really match
    function rebalanceStocksUsers(
        uint256 amount,
        IPoolManager poolManagerUp,
        IPoolManager poolManagerDown
    ) external onlyRole(GUARDIAN_ROLE) {
        Collateral storage colUp = collateralMap[poolManagerUp];
        Collateral storage colDown = collateralMap[poolManagerDown];
        // Checking for the `poolManager`
        _contractMapCheck(colUp);
        _contractMapCheck(colDown);
        // The invariant `col.stocksUsers <= col.capOnStableMinted` should remain true even after a
        // governance update
        require(colUp.stocksUsers + amount <= colUp.feeData.capOnStableMinted, "8");
        colDown.stocksUsers -= amount;
        colUp.stocksUsers += amount;
        emit StocksUsersUpdated(address(colUp.token), colUp.stocksUsers);
        emit StocksUsersUpdated(address(colDown.token), colDown.stocksUsers);
    }

    /// @notice Propagates the change of oracle for one collateral to all the contracts which need to have
    /// the correct oracle reference
    /// @param _oracle New oracle contract for the pair collateral/stablecoin
    /// @param poolManager Reference to the `PoolManager` contract associated to the collateral
    function setOracle(IOracle _oracle, IPoolManager poolManager)
        external
        onlyRole(GOVERNOR_ROLE)
        zeroCheck(address(_oracle))
    {
        Collateral storage col = collateralMap[poolManager];
        // Checking for the `poolManager`
        _contractMapCheck(col);
        require(col.oracle != _oracle, "12");
        // The `inBase` of the new oracle should be the same as the `_collatBase` stored for this collateral
        require(col.collatBase == _oracle.inBase(), "11");
        col.oracle = _oracle;
        emit OracleUpdated(address(poolManager), address(_oracle));
        col.perpetualManager.setOracle(_oracle);
    }

    /// @notice Changes the parameters to cap the number of stablecoins you can issue using one
    /// collateral type and the maximum interests you can distribute to SLPs in a sanRate update
    /// in a block
    /// @param _capOnStableMinted New value of the cap
    /// @param _maxInterestsDistributed Maximum amount of interests distributed to SLPs in a block
    /// @param poolManager Reference to the `PoolManager` contract associated to the collateral
    function setCapOnStableAndMaxInterests(
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed,
        IPoolManager poolManager
    ) external override onlyRole(GUARDIAN_ROLE) {
        Collateral storage col = collateralMap[poolManager];
        // Checking for the `poolManager`
        _contractMapCheck(col);
        // The invariant `col.stocksUsers <= col.capOnStableMinted` should remain true even after a
        // governance update
        require(_capOnStableMinted >= col.stocksUsers, "8");
        col.feeData.capOnStableMinted = _capOnStableMinted;
        col.slpData.maxInterestsDistributed = _maxInterestsDistributed;
        emit CapOnStableAndMaxInterestsUpdated(address(poolManager), _capOnStableMinted, _maxInterestsDistributed);
    }

    /// @notice Sets a new `FeeManager` contract and removes the old one which becomes useless
    /// @param newFeeManager New `FeeManager` contract
    /// @param oldFeeManager Old `FeeManager` contract
    /// @param poolManager Reference to the contract managing this collateral for this stablecoin in the protocol
    /// and associated to the `FeeManager` to update
    function setFeeManager(
        address newFeeManager,
        address oldFeeManager,
        IPoolManager poolManager
    ) external onlyRole(GUARDIAN_ROLE) zeroCheck(newFeeManager) {
        Collateral storage col = collateralMap[poolManager];
        // Checking for the `poolManager`
        _contractMapCheck(col);
        require(_contractMap[oldFeeManager] == poolManager, "10");
        require(newFeeManager != oldFeeManager, "14");
        delete _contractMap[oldFeeManager];
        _contractMap[newFeeManager] = poolManager;
        emit FeeManagerUpdated(address(poolManager), newFeeManager);
        poolManager.setFeeManager(IFeeManager(newFeeManager));
    }

    /// @notice Sets the proportion of fees from burn/mint of users and the proportion
    /// of lending interests going to SLPs
    /// @param _feesForSLPs New proportion of mint/burn fees going to SLPs
    /// @param _interestsForSLPs New proportion of interests from lending going to SLPs
    /// @dev The higher these proportions the bigger the APY for SLPs
    /// @dev These proportions should be inferior to `BASE_PARAMS`
    function setIncentivesForSLPs(
        uint64 _feesForSLPs,
        uint64 _interestsForSLPs,
        IPoolManager poolManager
    ) external override onlyRole(GUARDIAN_ROLE) onlyCompatibleFees(_feesForSLPs) onlyCompatibleFees(_interestsForSLPs) {
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        col.slpData.feesForSLPs = _feesForSLPs;
        col.slpData.interestsForSLPs = _interestsForSLPs;
        emit SLPsIncentivesUpdated(address(poolManager), _feesForSLPs, _interestsForSLPs);
    }

    /// @notice Sets the x array (ie ratios between amount hedged by HAs and amount to hedge)
    /// and the y array (ie values of fees at thresholds) used to compute mint and burn fees for users
    /// @param poolManager Reference to the `PoolManager` handling the collateral
    /// @param _xFee Thresholds of hedge ratios
    /// @param _yFee Values of the fees at thresholds
    /// @param _mint Whether mint fees or burn fees should be updated
    /// @dev The evolution of the fees between two thresholds is linear
    /// @dev The length of the two arrays should be the same
    /// @dev The values of `_xFee` should be in ascending order
    /// @dev For mint fees, values in the y-array below should normally be decreasing: the higher the `x` the cheaper
    /// it should be for stable seekers to come in as a high `x` corresponds to a high demand for volatility and hence
    /// to a situation where all the collateral can be hedged
    /// @dev For burn fees, values in the array below should normally be decreasing: the lower the `x` the cheaper it should
    /// be for stable seekers to go out, as a low `x` corresponds to low demand for volatility and hence
    /// to a situation where the protocol has a hard time covering its collateral
    function setUserFees(
        IPoolManager poolManager,
        uint64[] memory _xFee,
        uint64[] memory _yFee,
        uint8 _mint
    ) external override onlyRole(GUARDIAN_ROLE) onlyCompatibleInputArrays(_xFee, _yFee) {
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        if (_mint > 0) {
            col.feeData.xFeeMint = _xFee;
            col.feeData.yFeeMint = _yFee;
        } else {
            col.feeData.xFeeBurn = _xFee;
            col.feeData.yFeeBurn = _yFee;
        }
        emit FeeArrayUpdated(address(poolManager), _xFee, _yFee, _mint);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../external/AccessControlUpgradeable.sol";

import "../interfaces/IAgToken.sol";
import "../interfaces/ICollateralSettler.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IPerpetualManager.sol";
import "../interfaces/IPoolManager.sol";
import "../interfaces/ISanToken.sol";
import "../interfaces/IStableMaster.sol";

import "../utils/FunctionUtils.sol";
import "../utils/PausableMapUpgradeable.sol";

/// @title StableMasterEvents
/// @author Angle Core Team
/// @notice `StableMaster` is the contract handling all the collateral types accepted for a given stablecoin
/// It does all the accounting and is the point of entry in the protocol for stable holders and seekers as well as SLPs
/// @dev This file contains all the events of the `StableMaster` contract
contract StableMasterEvents {
    event SanRateUpdated(address indexed _token, uint256 _newSanRate);

    event StocksUsersUpdated(address indexed _poolManager, uint256 _stocksUsers);

    event MintedStablecoins(address indexed _poolManager, uint256 amount, uint256 amountForUserInStable);

    event BurntStablecoins(address indexed _poolManager, uint256 amount, uint256 redeemInC);

    // ============================= Governors =====================================

    event CollateralDeployed(
        address indexed _poolManager,
        address indexed _perpetualManager,
        address indexed _sanToken,
        address _oracle
    );

    event CollateralRevoked(address indexed _poolManager);

    // ========================= Parameters update =================================

    event OracleUpdated(address indexed _poolManager, address indexed _oracle);

    event FeeManagerUpdated(address indexed _poolManager, address indexed newFeeManager);

    event CapOnStableAndMaxInterestsUpdated(
        address indexed _poolManager,
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed
    );

    event SLPsIncentivesUpdated(address indexed _poolManager, uint64 _feesForSLPs, uint64 _interestsForSLPs);

    event FeeArrayUpdated(address indexed _poolManager, uint64[] _xFee, uint64[] _yFee, uint8 _type);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./StableMaster.sol";

/// @title StableMasterFront
/// @author Angle Core Team
/// @notice `StableMaster` is the contract handling all the collateral types accepted for a given stablecoin
/// It does all the accounting and is the point of entry in the protocol for stable holders and seekers as well as SLPs
/// @dev This file contains the front end, that is all external functions associated to the given stablecoin
contract StableMasterFront is StableMaster {
    using SafeERC20 for IERC20;

    // ============================ CONSTRUCTORS AND DEPLOYERS =====================

    /// @notice Initializes the `StableMaster` contract
    /// @param core_ Address of the `Core` contract handling all the different `StableMaster` contracts
    function initialize(address core_) external zeroCheck(core_) initializer {
        __AccessControl_init();
        // Access control
        _core = ICore(core_);
        _setupRole(CORE_ROLE, core_);
        // `Core` is admin of all roles
        _setRoleAdmin(CORE_ROLE, CORE_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, CORE_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, CORE_ROLE);
        // All the roles that are specific to a given collateral can be changed by the governor
        // in the `deployCollateral`, `revokeCollateral` and `setFeeManager` functions by updating the `contractMap`
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ============================= USERS =========================================

    /// @notice Lets a user send collateral to the system to mint stablecoins
    /// @param amount Amount of collateral sent
    /// @param user Address of the contract or the person to give the minted tokens to
    /// @param poolManager Address of the `PoolManager` of the required collateral
    /// @param minStableAmount Minimum amount of stablecoins the user wants to get with this transaction
    /// @dev This function works as a swap from a user perspective from collateral to stablecoins
    /// @dev It is impossible to mint tokens and to have them sent to the zero address: there
    /// would be an issue with the `_mint` function called by the `AgToken` contract
    /// @dev The parameter `minStableAmount` serves as a slippage protection for users
    /// @dev From a user perspective, this function is equivalent to a swap between collateral and
    /// stablecoins
    function mint(
        uint256 amount,
        address user,
        IPoolManager poolManager,
        uint256 minStableAmount
    ) external {
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        // Checking if the contract is paused for this agent
        _whenNotPaused(STABLE, address(poolManager));

        // No overflow check are needed for the amount since it's never casted to `int` and Solidity 0.8.0
        // automatically handles overflows
        col.token.safeTransferFrom(msg.sender, address(poolManager), amount);

        // Getting a quote for the amount of stablecoins to issue
        // We read the lowest oracle value we get for this collateral/stablecoin pair: it's the one
        // that is most at the advantage of the protocol
        // Decimals are handled directly in the oracle contract
        uint256 amountForUserInStable = col.oracle.readQuoteLower(amount);

        // Getting the fees paid for this transaction, expressed in `BASE_PARAMS`
        // Floor values are taken for fees computation, as what is earned by users is lost by SLP
        // when calling `_updateSanRate` and vice versa
        uint256 fees = _computeFeeMint(amountForUserInStable, col);

        // Computing the net amount that will be taken into account for this user by deducing fees
        amountForUserInStable = (amountForUserInStable * (BASE_PARAMS - fees)) / BASE_PARAMS;
        // Checking if the user got more stablecoins than the least amount specified in the parameters of the
        // function
        require(amountForUserInStable >= minStableAmount, "15");

        // Updating the `stocksUsers` for this collateral, that is the amount of collateral that was
        // brought by users
        col.stocksUsers += amountForUserInStable;
        // Checking if stablecoins can still be issued using this collateral type
        require(col.stocksUsers <= col.feeData.capOnStableMinted, "16");

        // Event needed to track `col.stocksUsers` off-chain
        emit MintedStablecoins(address(poolManager), amount, amountForUserInStable);

        // Distributing the fees taken to SLPs
        // The `fees` variable computed above is a proportion expressed in `BASE_PARAMS`.
        // To compute the amount of fees in collateral value, we can directly use the `amount` of collateral
        // entered by the user
        // Not all the fees are distributed to SLPs, a portion determined by `col.slpData.feesForSLPs` goes to surplus
        _updateSanRate((amount * fees * col.slpData.feesForSLPs) / (BASE_PARAMS**2), col);

        // Minting
        agToken.mint(user, amountForUserInStable);
    }

    /// @notice Lets a user burn agTokens (stablecoins) and receive the collateral specified by the `poolManager`
    /// in exchange
    /// @param amount Amount of stable asset burnt
    /// @param burner Address from which the agTokens will be burnt
    /// @param dest Address where collateral is going to be
    /// @param poolManager Collateral type requested by the user burning
    /// @param minCollatAmount Minimum amount of collateral that the user is willing to get for this transaction
    /// @dev The `msg.sender` should have approval to burn from the `burner` or the `msg.sender` should be the `burner`
    /// @dev If there are not enough reserves this transaction will revert and the user will have to come back to the
    /// protocol with a correct amount. Checking for the reserves currently available in the `PoolManager`
    /// is something that should be handled by the front interacting with this contract
    /// @dev In case there are not enough reserves, strategies should be harvested or their debt ratios should be adjusted
    /// by governance to make sure that users, HAs or SLPs withdrawing always have free collateral they can use
    /// @dev From a user perspective, this function is equivalent to a swap from stablecoins to collateral
    function burn(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager,
        uint256 minCollatAmount
    ) external {
        // Searching collateral data
        Collateral storage col = collateralMap[poolManager];
        // Checking the collateral requested
        _contractMapCheck(col);
        _whenNotPaused(STABLE, address(poolManager));

        // Checking if the amount is not going to make the `stocksUsers` negative
        // A situation like that is likely to happen if users mint using one collateral type and in volume redeem
        // another collateral type
        // In this situation, governance should rapidly react to pause the pool and then rebalance the `stocksUsers`
        // between different collateral types, or at least rebalance what is stored in the reserves through
        // the `recoverERC20` function followed by a swap and then a transfer
        require(amount <= col.stocksUsers, "17");

        // Burning the tokens will revert if there are not enough tokens in balance or if the `msg.sender`
        // does not have approval from the burner
        // A reentrancy attack is potentially possible here as state variables are written after the burn,
        // but as the `AgToken` is a protocol deployed contract, it can be trusted. Still, `AgToken` is
        // upgradeable by governance, the following could become risky in case of a governance attack
        if (burner == msg.sender) {
            agToken.burnSelf(amount, burner);
        } else {
            agToken.burnFrom(amount, burner, msg.sender);
        }

        // Getting the highest possible oracle value
        uint256 oracleValue = col.oracle.readUpper();

        // Converting amount of agTokens in collateral and computing how much should be reimbursed to the user
        // Amount is in `BASE_TOKENS` and the outputted collateral amount should be in collateral base
        uint256 amountInC = (amount * col.collatBase) / oracleValue;

        // Computing how much of collateral can be redeemed by the user after taking fees
        // The value of the fees here is `_computeFeeBurn(amount,col)` (it is a proportion expressed in `BASE_PARAMS`)
        // The real value of what can be redeemed by the user is `amountInC * (BASE_PARAMS - fees) / BASE_PARAMS`,
        // but we prefer to avoid doing multiplications after divisions
        uint256 redeemInC = (amount * (BASE_PARAMS - _computeFeeBurn(amount, col)) * col.collatBase) /
            (oracleValue * BASE_PARAMS);
        require(redeemInC >= minCollatAmount, "15");

        // Updating the `stocksUsers` that is the amount of collateral that was brought by users
        col.stocksUsers -= amount;

        // Event needed to track `col.stocksUsers` off-chain
        emit BurntStablecoins(address(poolManager), amount, redeemInC);

        // Computing the exact amount of fees from this transaction and accumulating it for SLPs
        _updateSanRate(((amountInC - redeemInC) * col.slpData.feesForSLPs) / BASE_PARAMS, col);

        col.token.safeTransferFrom(address(poolManager), dest, redeemInC);
    }

    // ============================== SLPs =========================================

    /// @notice Lets a SLP enter the protocol by sending collateral to the system in exchange of sanTokens
    /// @param user Address of the SLP to send sanTokens to
    /// @param amount Amount of collateral sent
    /// @param poolManager Address of the `PoolManager` of the required collateral
    function deposit(
        uint256 amount,
        address user,
        IPoolManager poolManager
    ) external {
        // Searching collateral data
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        _whenNotPaused(SLP, address(poolManager));
        _updateSanRate(0, col);

        // No overflow check needed for the amount since it's never casted to int and Solidity versions above 0.8.0
        // automatically handle overflows
        col.token.safeTransferFrom(msg.sender, address(poolManager), amount);
        col.sanToken.mint(user, (amount * BASE_TOKENS) / col.sanRate);
    }

    /// @notice Lets a SLP burn of sanTokens and receive the corresponding collateral back in exchange at the
    /// current exchange rate between sanTokens and collateral
    /// @param amount Amount of sanTokens burnt by the SLP
    /// @param burner Address that will burn its sanTokens
    /// @param dest Address that will receive the collateral
    /// @param poolManager Address of the `PoolManager` of the required collateral
    /// @dev The `msg.sender` should have approval to burn from the `burner` or the `msg.sender` should be the `burner`
    /// @dev This transaction will fail if the `PoolManager` does not have enough reserves, the front will however be here
    /// to notify them that they cannot withdraw
    /// @dev In case there are not enough reserves, strategies should be harvested or their debt ratios should be adjusted
    /// by governance to make sure that users, HAs or SLPs withdrawing always have free collateral they can use
    function withdraw(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager
    ) external {
        Collateral storage col = collateralMap[poolManager];
        _contractMapCheck(col);
        _whenNotPaused(SLP, address(poolManager));
        _updateSanRate(0, col);

        if (burner == msg.sender) {
            col.sanToken.burnSelf(amount, burner);
        } else {
            col.sanToken.burnFrom(amount, burner, msg.sender);
        }
        // Computing the amount of collateral to give back to the SLP depending on slippage and on the `sanRate`
        uint256 redeemInC = (amount * (BASE_PARAMS - col.slpData.slippage) * col.sanRate) / (BASE_TOKENS * BASE_PARAMS);

        col.token.safeTransferFrom(address(poolManager), dest, redeemInC);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./StableMasterStorage.sol";

/// @title StableMasterInternal
/// @author Angle Core Team
/// @notice `StableMaster` is the contract handling all the collateral types accepted for a given stablecoin
/// It does all the accounting and is the point of entry in the protocol for stable holders and seekers as well as SLPs
/// @dev This file contains all the internal function of the `StableMaster` contract
contract StableMasterInternal is StableMasterStorage, PausableMapUpgradeable {
    /// @notice Checks if the `msg.sender` calling the contract has the right to do it
    /// @param col Struct for the collateral associated to the caller address
    /// @dev Since the `StableMaster` contract uses a `contractMap` that stores addresses of some verified
    /// protocol's contracts in it, and since the roles corresponding to these addresses are never admin roles
    /// it is cheaper not to use for these contracts OpenZeppelin's access control logic
    /// @dev A non null associated token address is what is used to check if a `PoolManager` has well been initialized
    /// @dev We could set `PERPETUALMANAGER_ROLE`, `POOLMANAGER_ROLE` and `FEEMANAGER_ROLE` for this
    /// contract, but this would actually be inefficient
    function _contractMapCheck(Collateral storage col) internal view {
        require(address(col.token) != address(0), "3");
    }

    /// @notice Checks if the protocol has been paused for an agent and for a given collateral type for this
    /// stablecoin
    /// @param agent Name of the agent to check, it is either going to be `STABLE` or `SLP`
    /// @param poolManager `PoolManager` contract for which to check pauses
    function _whenNotPaused(bytes32 agent, address poolManager) internal view {
        require(!paused[keccak256(abi.encodePacked(agent, poolManager))], "18");
    }

    /// @notice Updates the `sanRate` that is the exchange rate between sanTokens given to SLPs and collateral or
    /// accumulates fees to be distributed to SLPs before doing it at next block
    /// @param toShare Amount of interests that needs to be redistributed to the SLPs through the `sanRate`
    /// @param col Struct for the collateral of interest here which values are going to be updated
    /// @dev This function can only increase the `sanRate` and is not used to take into account a loss made through
    /// lending or another yield farming strategy: this is done in the `signalLoss` function
    /// @dev The `sanRate` is only be updated from the fees accumulated from previous blocks and the fees to share to SLPs
    /// are just accumulated to be distributed at next block
    /// @dev A flashloan attack could consist in seeing fees to be distributed, deposit, increase the `sanRate` and then
    /// withdraw: what is done with the `lockedInterests` parameter is a way to mitigate that
    /// @dev Another solution against flash loans would be to have a non null `slippage` at all times: this is far from ideal
    /// for SLPs in the first place
    function _updateSanRate(uint256 toShare, Collateral storage col) internal {
        uint256 _lockedInterests = col.slpData.lockedInterests;
        // Checking if the `sanRate` has been updated in the current block using past block fees
        // This is a way to prevent flash loans attacks when an important amount of fees are going to be distributed
        // in a block: fees are stored but will just be distributed to SLPs who will be here during next blocks
        if (block.timestamp != col.slpData.lastBlockUpdated && _lockedInterests > 0) {
            uint256 sanMint = col.sanToken.totalSupply();
            if (sanMint != 0) {
                // Checking if the update is too important and should be made in multiple blocks
                if (_lockedInterests > col.slpData.maxInterestsDistributed) {
                    // `sanRate` is expressed in `BASE_TOKENS`
                    col.sanRate += (col.slpData.maxInterestsDistributed * BASE_TOKENS) / sanMint;
                    _lockedInterests -= col.slpData.maxInterestsDistributed;
                } else {
                    col.sanRate += (_lockedInterests * BASE_TOKENS) / sanMint;
                    _lockedInterests = 0;
                }
                emit SanRateUpdated(address(col.token), col.sanRate);
            } else {
                _lockedInterests = 0;
            }
        }
        // Adding the fees to be distributed at next block
        if (toShare != 0) {
            if ((col.slpData.slippageFee == 0) && (col.slpData.feesAside != 0)) {
                // If the collateral ratio is big enough, all the fees or gains will be used to update the `sanRate`
                // If there were fees or lending gains that had been put aside, they will be added in this case to the
                // update of the `sanRate`
                toShare += col.slpData.feesAside;
                col.slpData.feesAside = 0;
            } else if (col.slpData.slippageFee != 0) {
                // Computing the fraction of fees and gains that should be left aside if the collateral ratio is too small
                uint256 aside = (toShare * col.slpData.slippageFee) / BASE_PARAMS;
                toShare -= aside;
                // The amount of fees left aside should be rounded above
                col.slpData.feesAside += aside;
            }
            // Updating the amount of fees to be distributed next block
            _lockedInterests += toShare;
        }
        col.slpData.lockedInterests = _lockedInterests;
        col.slpData.lastBlockUpdated = block.timestamp;
    }

    /// @notice Computes the current fees to be taken when minting using `amount` of collateral
    /// @param amount Amount of collateral in the transaction to get stablecoins
    /// @param col Struct for the collateral of interest
    /// @return feeMint Mint Fees taken to users expressed in collateral
    /// @dev Fees depend on the hedge ratio that is the ratio between what is hedged by HAs and what should be hedged
    /// @dev The more is hedged by HAs, the smaller fees are expected to be
    /// @dev Fees are also corrected by the `bonusMalusMint` parameter which induces a dependence in collateral ratio
    function _computeFeeMint(uint256 amount, Collateral storage col) internal view returns (uint256 feeMint) {
        uint64 feeMint64;
        if (col.feeData.xFeeMint.length == 1) {
            // This is done to avoid an external call in the case where the fees are constant regardless of the collateral
            // ratio
            feeMint64 = col.feeData.yFeeMint[0];
        } else {
            uint64 hedgeRatio = _computeHedgeRatio(amount + col.stocksUsers, col);
            // Computing the fees based on the spread
            feeMint64 = _piecewiseLinear(hedgeRatio, col.feeData.xFeeMint, col.feeData.yFeeMint);
        }
        // Fees could in some occasions depend on other factors like collateral ratio
        // Keepers are the ones updating this part of the fees
        feeMint = (feeMint64 * col.feeData.bonusMalusMint) / BASE_PARAMS;
    }

    /// @notice Computes the current fees to be taken when burning stablecoins
    /// @param amount Amount of collateral corresponding to the stablecoins burnt in the transaction
    /// @param col Struct for the collateral of interest
    /// @return feeBurn Burn fees taken to users expressed in collateral
    /// @dev The amount is obtained after the amount of agTokens sent is converted in collateral
    /// @dev Fees depend on the hedge ratio that is the ratio between what is hedged by HAs and what should be hedged
    /// @dev The more is hedged by HAs, the higher fees are expected to be
    /// @dev Fees are also corrected by the `bonusMalusBurn` parameter which induces a dependence in collateral ratio
    function _computeFeeBurn(uint256 amount, Collateral storage col) internal view returns (uint256 feeBurn) {
        uint64 feeBurn64;
        if (col.feeData.xFeeBurn.length == 1) {
            // Avoiding an external call if fees are constant
            feeBurn64 = col.feeData.yFeeBurn[0];
        } else {
            uint64 hedgeRatio = _computeHedgeRatio(col.stocksUsers - amount, col);
            // Computing the fees based on the spread
            feeBurn64 = _piecewiseLinear(hedgeRatio, col.feeData.xFeeBurn, col.feeData.yFeeBurn);
        }
        // Fees could in some occasions depend on other factors like collateral ratio
        // Keepers are the ones updating this part of the fees
        feeBurn = (feeBurn64 * col.feeData.bonusMalusBurn) / BASE_PARAMS;
    }

    /// @notice Computes the hedge ratio that is the ratio between the amount of collateral hedged by HAs
    /// divided by the amount that should be hedged
    /// @param newStocksUsers Value of the collateral from users to hedge
    /// @param col Struct for the collateral of interest
    /// @return ratio Ratio between what's hedged divided what's to hedge
    /// @dev This function is typically called to compute mint or burn fees
    /// @dev It seeks from the `PerpetualManager` contract associated to the collateral the total amount
    /// already hedged by HAs and compares it to the amount to hedge
    function _computeHedgeRatio(uint256 newStocksUsers, Collateral storage col) internal view returns (uint64 ratio) {
        // Fetching the amount hedged by HAs from the corresponding `perpetualManager` contract
        uint256 totalHedgeAmount = col.perpetualManager.totalHedgeAmount();
        newStocksUsers = (col.feeData.targetHAHedge * newStocksUsers) / BASE_PARAMS;
        if (newStocksUsers > totalHedgeAmount) ratio = uint64((totalHedgeAmount * BASE_PARAMS) / newStocksUsers);
        else ratio = uint64(BASE_PARAMS);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./StableMasterEvents.sol";

/// @title StableMasterStorage
/// @author Angle Core Team
/// @notice `StableMaster` is the contract handling all the collateral types accepted for a given stablecoin
/// It does all the accounting and is the point of entry in the protocol for stable holders and seekers as well as SLPs
/// @dev This file contains all the variables and parameters used in the `StableMaster` contract
contract StableMasterStorage is StableMasterEvents, FunctionUtils {
    // All the details about a collateral that are going to be stored in `StableMaster`
    struct Collateral {
        // Interface for the token accepted by the underlying `PoolManager` contract
        IERC20 token;
        // Reference to the `SanToken` for the pool
        ISanToken sanToken;
        // Reference to the `PerpetualManager` for the pool
        IPerpetualManager perpetualManager;
        // Adress of the oracle for the change rate between
        // collateral and the corresponding stablecoin
        IOracle oracle;
        // Amount of collateral in the reserves that comes from users
        // converted in stablecoin value. Updated at minting and burning.
        // A `stocksUsers` of 10 for a collateral type means that overall the balance of the collateral from users
        // that minted/burnt stablecoins using this collateral is worth 10 of stablecoins
        uint256 stocksUsers;
        // Exchange rate between sanToken and collateral
        uint256 sanRate;
        // Base used in the collateral implementation (ERC20 decimal)
        uint256 collatBase;
        // Parameters for SLPs and update of the `sanRate`
        SLPData slpData;
        // All the fees parameters
        MintBurnData feeData;
    }

    // ============================ Variables and References =====================================

    /// @notice Maps a `PoolManager` contract handling a collateral for this stablecoin to the properties of the struct above
    mapping(IPoolManager => Collateral) public collateralMap;

    /// @notice Reference to the `AgToken` used in this `StableMaster`
    /// This reference cannot be changed
    IAgToken public agToken;

    // Maps a contract to an address corresponding to the `IPoolManager` address
    // It is typically used to avoid passing in parameters the address of the `PerpetualManager` when `PerpetualManager`
    // is calling `StableMaster` to get information
    // It is the Access Control equivalent for the `SanToken`, `PoolManager`, `PerpetualManager` and `FeeManager`
    // contracts associated to this `StableMaster`
    mapping(address => IPoolManager) internal _contractMap;

    // List of all collateral managers
    IPoolManager[] internal _managerList;

    // Reference to the `Core` contract of the protocol
    ICore internal _core;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title FunctionUtils
/// @author Angle Core Team
/// @notice Contains all the utility functions that are needed in different places of the protocol
/// @dev Functions in this contract should typically be pure functions
/// @dev This contract is voluntarily a contract and not a library to save some gas cost every time it is used
contract FunctionUtils {
    /// @notice Base that is used to compute ratios and floating numbers
    uint256 public constant BASE_TOKENS = 10**18;
    /// @notice Base that is used to define parameters that need to have a floating value (for instance parameters
    /// that are defined as ratios)
    uint256 public constant BASE_PARAMS = 10**9;

    /// @notice Computes the value of a linear by part function at a given point
    /// @param x Point of the function we want to compute
    /// @param xArray List of breaking points (in ascending order) that define the linear by part function
    /// @param yArray List of values at breaking points (not necessarily in ascending order)
    /// @dev The evolution of the linear by part function between two breaking points is linear
    /// @dev Before the first breaking point and after the last one, the function is constant with a value
    /// equal to the first or last value of the yArray
    /// @dev This function is relevant if `x` is between O and `BASE_PARAMS`. If `x` is greater than that, then
    /// everything will be as if `x` is equal to the greater element of the `xArray`
    function _piecewiseLinear(
        uint64 x,
        uint64[] memory xArray,
        uint64[] memory yArray
    ) internal pure returns (uint64) {
        if (x >= xArray[xArray.length - 1]) {
            return yArray[xArray.length - 1];
        } else if (x <= xArray[0]) {
            return yArray[0];
        } else {
            uint256 lower;
            uint256 upper = xArray.length - 1;
            uint256 mid;
            while (upper - lower > 1) {
                mid = lower + (upper - lower) / 2;
                if (xArray[mid] <= x) {
                    lower = mid;
                } else {
                    upper = mid;
                }
            }
            if (yArray[upper] > yArray[lower]) {
                // There is no risk of overflow here as in the product of the difference of `y`
                // with the difference of `x`, the product is inferior to `BASE_PARAMS**2` which does not
                // overflow for `uint64`
                return
                    yArray[lower] +
                    ((yArray[upper] - yArray[lower]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            } else {
                return
                    yArray[lower] -
                    ((yArray[lower] - yArray[upper]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            }
        }
    }

    /// @notice Checks if the input arrays given by governance to update the fee structure is valid
    /// @param xArray List of breaking points (in ascending order) that define the linear by part function
    /// @param yArray List of values at breaking points (not necessarily in ascending order)
    /// @dev This function is a way to avoid some governance attacks or errors
    /// @dev The modifier checks if the arrays have a non null length, if their length is the same, if the values
    /// in the `xArray` are in ascending order and if the values in the `xArray` and in the `yArray` are not superior
    /// to `BASE_PARAMS`
    modifier onlyCompatibleInputArrays(uint64[] memory xArray, uint64[] memory yArray) {
        require(xArray.length == yArray.length && xArray.length > 0, "5");
        for (uint256 i = 0; i <= yArray.length - 1; i++) {
            require(yArray[i] <= uint64(BASE_PARAMS) && xArray[i] <= uint64(BASE_PARAMS), "6");
            if (i > 0) {
                require(xArray[i] > xArray[i - 1], "7");
            }
        }
        _;
    }

    /// @notice Checks if the new value given for the parameter is consistent (it should be inferior to 1
    /// if it corresponds to a ratio)
    /// @param fees Value of the new parameter to check
    modifier onlyCompatibleFees(uint64 fees) {
        require(fees <= BASE_PARAMS, "4");
        _;
    }

    /// @notice Checks if the new address given is not null
    /// @param newAddress Address to check
    /// @dev Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
    modifier zeroCheck(address newAddress) {
        require(newAddress != address(0), "0");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title PausableMap
/// @author Angle Core Team after a fork from OpenZeppelin's similar Pausable Contracts
/// @notice Contract module which allows children to implement an emergency stop
/// mechanism that can be triggered by an authorized account.
/// @notice It generalizes Pausable from OpenZeppelin by allowing to specify a bytes32 that
/// should be stopped
/// @dev This module is used through inheritance
/// @dev In Angle's protocol, this contract is mainly used in `StableMasterFront`
/// to prevent SLPs and new stable holders from coming in
/// @dev The modifiers `whenNotPaused` and `whenPaused` from the original OpenZeppelin contracts were removed
/// to save some space and because they are not used in the `StableMaster` contract where this contract
/// is imported
contract PausableMapUpgradeable {
    /// @dev Emitted when the pause is triggered for `name`
    event Paused(bytes32 name);

    /// @dev Emitted when the pause is lifted for `name`
    event Unpaused(bytes32 name);

    /// @dev Mapping between a name and a boolean representing the paused state
    mapping(bytes32 => bool) public paused;

    /// @notice Triggers stopped state for `name`
    /// @param name Name for which to pause the contract
    /// @dev The contract must not be paused for `name`
    function _pause(bytes32 name) internal {
        require(!paused[name], "18");
        paused[name] = true;
        emit Paused(name);
    }

    /// @notice Returns to normal state for `name`
    /// @param name Name for which to unpause the contract
    /// @dev The contract must be paused for `name`
    function _unpause(bytes32 name) internal {
        require(paused[name], "19");
        paused[name] = false;
        emit Unpaused(name);
    }
}