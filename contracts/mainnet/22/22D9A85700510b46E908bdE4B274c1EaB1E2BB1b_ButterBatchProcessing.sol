// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IACLRegistry.sol";
import "../../../externals/interfaces/YearnVault.sol";
import "../../../externals/interfaces/BasicIssuanceModule.sol";
import "../../../externals/interfaces/ISetToken.sol";
import "../../../externals/interfaces/CurveContracts.sol";
import "../../interfaces/IContractRegistry.sol";
import "../../utils/KeeperIncentive.sol";

/*
 * @notice This Contract allows smaller depositors to mint and redeem Butter (formerly known as HYSI) without needing to through all the steps necessary on their own,
 * which not only takes long but mainly costs enormous amounts of gas.
 * The Butter is created from several different yTokens which in turn need each a deposit of a crvLPToken.
 * This means multiple approvals and deposits are necessary to mint one Butter.
 * We batch this process and allow users to pool their funds. Then we pay a keeper to mint or redeem Butter regularly.
 */
contract ButterBatchProcessing is Pausable, ReentrancyGuard {
  using SafeERC20 for YearnVault;
  using SafeERC20 for ISetToken;
  using SafeERC20 for IERC20;

  /**
   * @notice Defines if the Batch will mint or redeem Butter
   */
  enum BatchType {
    Mint,
    Redeem
  }

  /**
   * @notice Defines if the Batch will mint or redeem Butter
   * @param curveMetaPool A CurveMetaPool for trading an exotic stablecoin against 3CRV
   * @param crvLPToken The LP-Token of the CurveMetapool
   */
  struct CurvePoolTokenPair {
    CurveMetapool curveMetaPool;
    IERC20 crvLPToken;
  }

  /**
   * @notice The Batch structure is used both for Batches of Minting and Redeeming
   * @param batchType Determines if this Batch is for Minting or Redeeming Butter
   * @param batchId bytes32 id of the batch
   * @param claimable Shows if a batch has been processed and is ready to be claimed, the suppliedToken cant be withdrawn if a batch is claimable
   * @param unclaimedShares The total amount of unclaimed shares in this batch
   * @param suppliedTokenBalance The total amount of deposited token (either 3CRV or Butter)
   * @param claimableTokenBalance The total amount of claimable token (either 3CRV or Butter)
   * @param tokenAddress The address of the the token to be claimed
   * @param shareBalance The individual share balance per user that has deposited token
   */
  struct Batch {
    BatchType batchType;
    bytes32 batchId;
    bool claimable;
    uint256 unclaimedShares;
    uint256 suppliedTokenBalance;
    uint256 claimableTokenBalance;
    address suppliedTokenAddress;
    address claimableTokenAddress;
  }

  /* ========== STATE VARIABLES ========== */

  bytes32 public immutable contractName = "ButterBatchProcessing";

  IContractRegistry public contractRegistry;
  ISetToken public setToken;
  IERC20 public threeCrv;
  BasicIssuanceModule public setBasicIssuanceModule;
  mapping(address => CurvePoolTokenPair) public curvePoolTokenPairs;

  /**
   * @notice This maps batch ids to addresses with share balances
   */
  mapping(bytes32 => mapping(address => uint256)) public accountBalances;
  mapping(address => bytes32[]) public accountBatches;
  mapping(bytes32 => Batch) public batches;
  bytes32[] public batchIds;

  uint256 public lastMintedAt;
  uint256 public lastRedeemedAt;
  bytes32 public currentMintBatchId;
  bytes32 public currentRedeemBatchId;
  uint256 public batchCooldown;
  uint256 public mintThreshold;
  uint256 public redeemThreshold;

  /* ========== EVENTS ========== */

  event Deposit(address indexed from, uint256 deposit);
  event Withdrawal(address indexed to, uint256 amount);
  event BatchMinted(bytes32 indexed batchId, uint256 suppliedTokenAmount, uint256 hysiAmount);
  event BatchRedeemed(bytes32 indexed batchId, uint256 suppliedTokenAmount, uint256 threeCrvAmount);
  event Claimed(address indexed account, BatchType batchType, uint256 shares, uint256 claimedToken);
  event WithdrawnFromBatch(bytes32 batchId, uint256 amount, address to);
  event MovedUnclaimedDepositsIntoCurrentBatch(uint256 amount, BatchType batchType, address account);
  event RedeemThresholdUpdated(uint256 previousThreshold, uint256 newThreshold);
  event MintThresholdUpdated(uint256 previousThreshold, uint256 newThreshold);
  event BatchCooldownUpdated(uint256 previousCooldown, uint256 newCooldown);
  event CurveTokenPairsUpdated(address[] yTokenAddresses, CurvePoolTokenPair[] curveTokenPairs);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    ISetToken _setToken,
    IERC20 _threeCrv,
    BasicIssuanceModule _basicIssuanceModule,
    address[] memory _yTokenAddresses,
    CurvePoolTokenPair[] memory _curvePoolTokenPairs,
    uint256 _batchCooldown,
    uint256 _mintThreshold,
    uint256 _redeemThreshold
  ) {
    contractRegistry = _contractRegistry;
    setToken = _setToken;
    threeCrv = _threeCrv;
    setBasicIssuanceModule = _basicIssuanceModule;

    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);

    batchCooldown = _batchCooldown;
    mintThreshold = _mintThreshold;
    redeemThreshold = _redeemThreshold;
    lastMintedAt = block.timestamp;
    lastRedeemedAt = block.timestamp;

    _generateNextBatch(bytes32("mint"), BatchType.Mint);
    _generateNextBatch(bytes32("redeem"), BatchType.Redeem);
  }

  /* ========== VIEWS ========== */
  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBatches(address _account) external view returns (bytes32[] memory) {
    return accountBatches[_account];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Deposits funds in the current mint batch
   * @param _amount Amount of 3cr3CRV to use for minting
   * @param _depositFor User that gets the shares attributed to (for use in zapper contract)
   */
  function depositForMint(uint256 _amount, address _depositFor) external nonReentrant whenNotPaused {
    require(
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).hasRole(
        keccak256("ButterZapper"),
        msg.sender
      ) || msg.sender == _depositFor,
      "you cant transfer other funds"
    );
    require(threeCrv.balanceOf(msg.sender) >= _amount, "insufficent balance");
    threeCrv.transferFrom(msg.sender, address(this), _amount);
    _deposit(_amount, currentMintBatchId, _depositFor);
  }

  /**
   * @notice deposits funds in the current redeem batch
   * @param _amount amount of Butter to be redeemed
   */
  function depositForRedeem(uint256 _amount) external nonReentrant whenNotPaused {
    require(setToken.balanceOf(msg.sender) >= _amount, "insufficient balance");
    setToken.transferFrom(msg.sender, address(this), _amount);
    _deposit(_amount, currentRedeemBatchId, msg.sender);
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param _batchId From which batch should funds be withdrawn from
   * @param _amountToWithdraw Amount of Butter or 3CRV to be withdrawn from the queue (depending on mintBatch / redeemBatch)
   * @param _withdrawFor User that gets the shares attributed to (for use in zapper contract)
   */
  function withdrawFromBatch(
    bytes32 _batchId,
    uint256 _amountToWithdraw,
    address _withdrawFor
  ) external {
    address recipient = _getRecipient(_withdrawFor);

    Batch storage batch = batches[_batchId];
    uint256 accountBalance = accountBalances[_batchId][_withdrawFor];
    require(batch.claimable == false, "already processed");
    require(accountBalance >= _amountToWithdraw, "account has insufficient funds");

    //At this point the account balance is equal to the supplied token and can be used interchangeably
    accountBalances[_batchId][_withdrawFor] = accountBalance - _amountToWithdraw;
    batch.suppliedTokenBalance = batch.suppliedTokenBalance - _amountToWithdraw;
    batch.unclaimedShares = batch.unclaimedShares - _amountToWithdraw;

    if (batch.batchType == BatchType.Mint) {
      threeCrv.safeTransfer(recipient, _amountToWithdraw);
    } else {
      setToken.safeTransfer(recipient, _amountToWithdraw);
    }
    emit WithdrawnFromBatch(_batchId, _amountToWithdraw, _withdrawFor);
  }

  /**
   * @notice Claims funds after the batch has been processed (get Butter from a mint batch and 3CRV from a redeem batch)
   * @param _batchId Id of batch to claim from
   * @param _claimFor User that gets the shares attributed to (for use in zapper contract)
   */
  function claim(bytes32 _batchId, address _claimFor) external returns (uint256) {
    Batch storage batch = batches[_batchId];
    require(batch.claimable, "not yet claimable");

    address recipient = _getRecipient(_claimFor);
    uint256 accountBalance = accountBalances[_batchId][_claimFor];
    require(accountBalance <= batch.unclaimedShares, "claiming too many shares");

    //Calculate how many token will be claimed
    uint256 tokenAmountToClaim = (batch.claimableTokenBalance * accountBalance) / batch.unclaimedShares;

    //Subtract the claimed token from the batch
    batch.claimableTokenBalance = batch.claimableTokenBalance - tokenAmountToClaim;
    batch.unclaimedShares = batch.unclaimedShares - accountBalance;
    accountBalances[_batchId][_claimFor] = 0;

    //Transfer token
    if (batch.batchType == BatchType.Mint) {
      setToken.safeTransfer(recipient, tokenAmountToClaim);
    } else {
      threeCrv.safeTransfer(recipient, tokenAmountToClaim);
    }

    emit Claimed(_claimFor, batch.batchType, accountBalance, tokenAmountToClaim);

    return tokenAmountToClaim;
  }

  /**
   * @notice Moves unclaimed token (3crv or Hysi) from their respective Batches into a new redeemBatch / mintBatch without needing to claim them first. This will typically be used when hysi has already been minted and a user has never claimed / transfered the token to their address and they would like to convert it to stablecoin.
   * @param _batchIds the ids of each batch where hysi should be moved from
   * @param _shares how many shares should redeemed in each of the batches
   * @param _batchType the batchType where funds should be taken from (Mint -> Take Hysi and redeem then, Redeem -> Take 3Crv and Mint Butter)
   * @dev the indices of batchIds must match the amountsInHysi to work properly (This will be done by the frontend)
   */
  function moveUnclaimedDepositsIntoCurrentBatch(
    bytes32[] calldata _batchIds,
    uint256[] calldata _shares,
    BatchType _batchType
  ) external whenNotPaused {
    require(_batchIds.length == _shares.length, "array lengths must match");

    uint256 totalAmount;

    for (uint256 i; i < _batchIds.length; i++) {
      Batch storage batch = batches[_batchIds[i]];
      uint256 accountBalance = accountBalances[batch.batchId][msg.sender];
      //Check that the user has enough funds and that the batch was already minted
      //Only the current redeemBatch is claimable == false so this check allows us to not adjust batch.suppliedTokenBalance
      //Additionally it makes no sense to move funds from the current redeemBatch to the current redeemBatch
      require(batch.claimable == true, "has not yet been processed");
      require(batch.batchType == _batchType, "incorrect batchType");
      require(accountBalance >= _shares[i], "account has insufficient funds");

      uint256 tokenAmountToClaim = (batch.claimableTokenBalance * _shares[i]) / batch.unclaimedShares;
      batch.claimableTokenBalance = batch.claimableTokenBalance - tokenAmountToClaim;
      batch.unclaimedShares = batch.unclaimedShares - _shares[i];
      accountBalances[batch.batchId][msg.sender] = accountBalance - _shares[i];

      totalAmount = totalAmount + tokenAmountToClaim;
    }
    require(totalAmount > 0, "totalAmount must be larger 0");

    if (BatchType.Mint == _batchType) {
      _deposit(totalAmount, currentRedeemBatchId, msg.sender);
    }

    if (BatchType.Redeem == _batchType) {
      _deposit(totalAmount, currentMintBatchId, msg.sender);
    }

    emit MovedUnclaimedDepositsIntoCurrentBatch(totalAmount, _batchType, msg.sender);
  }

  /**
   * @notice Mint Butter token with deposited 3CRV. This function goes through all the steps necessary to mint an optimal amount of Butter
   * @param _minAmountToMint The expected min amount of hysi to mint. If hysiAmount is lower than minAmountToMint_ the transaction will revert.
   * @dev This function deposits 3CRV in the underlying Metapool and deposits these LP token to get yToken which in turn are used to mint Butter
   * @dev This process leaves some leftovers which are partially used in the next mint batches.
   * @dev In order to get 3CRV we can implement a zap to move stables into the curve tri-pool
   * @dev handleKeeperIncentive checks if the msg.sender is a permissioned keeper and pays them a reward for calling this function (see KeeperIncentive.sol)
   */
  function batchMint(uint256 _minAmountToMint) external whenNotPaused {
    KeeperIncentive(contractRegistry.getContract(keccak256("KeeperIncentive"))).handleKeeperIncentive(
      contractName,
      0,
      msg.sender
    );
    Batch storage batch = batches[currentMintBatchId];

    //Check if there was enough time between the last batch minting and this attempt...
    //...or if enough 3CRV was deposited to make the minting worthwhile
    //This is to prevent excessive gas consumption and costs as we will pay keeper to call this function
    require(
      (block.timestamp - lastMintedAt) >= batchCooldown || (batch.suppliedTokenBalance >= mintThreshold),
      "can not execute batch action yet"
    );

    //Check if the Batch got already processed -- should technically not be possible
    require(batch.claimable == false, "already minted");

    //Check if this contract has enough 3CRV -- should technically not be necessary
    require(
      threeCrv.balanceOf(address(this)) >= batch.suppliedTokenBalance,
      "account has insufficient balance of token to mint"
    );

    //Get the quantity of yToken for one Butter
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, 1e18);

    //Total value of leftover yToken valued in 3CRV
    uint256 totalLeftoverIn3Crv;

    //Individual yToken leftovers valued in 3CRV
    uint256[] memory leftoversIn3Crv = new uint256[](quantities.length);

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Check how many crvLPToken are needed to mint one yToken
      uint256 yTokenInCrvToken = YearnVault(tokenAddresses[i]).pricePerShare();

      //Check how many 3CRV are needed to mint one crvLPToken
      uint256 crvLPTokenIn3Crv = uint256(2e18) -
        curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool.calc_withdraw_one_coin(1e18, 1);

      //Calculate how many 3CRV are needed to mint one yToken
      uint256 yTokenIn3Crv = (yTokenInCrvToken * crvLPTokenIn3Crv) / 1e18;

      //Calculate how much the yToken leftover are worth in 3CRV
      uint256 leftoverIn3Crv = (YearnVault(tokenAddresses[i]).balanceOf(address(this)) * yTokenIn3Crv) / 1e18;

      //Add the leftover value to the array of leftovers for later use
      leftoversIn3Crv[i] = leftoverIn3Crv;

      //Add the leftover value to the total leftover value
      totalLeftoverIn3Crv = totalLeftoverIn3Crv + leftoverIn3Crv;
    }

    //Calculate the total value of supplied token + leftovers in 3CRV
    uint256 suppliedTokenBalancePlusLeftovers = batch.suppliedTokenBalance + totalLeftoverIn3Crv;

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Calculate the pool allocation by dividing the suppliedTokenBalance by number of token addresses and take leftovers into account
      uint256 poolAllocation = suppliedTokenBalancePlusLeftovers / tokenAddresses.length - leftoversIn3Crv[i];

      //Pool 3CRV to get crvLPToken
      _sendToCurve(poolAllocation, curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool);

      //Deposit crvLPToken to get yToken
      _sendToYearn(
        curvePoolTokenPairs[tokenAddresses[i]].crvLPToken.balanceOf(address(this)),
        YearnVault(tokenAddresses[i])
      );

      //Approve yToken for minting
      YearnVault(tokenAddresses[i]).safeIncreaseAllowance(
        address(setBasicIssuanceModule),
        YearnVault(tokenAddresses[i]).balanceOf(address(this))
      );
    }

    //Get the minimum amount of hysi that we can mint with our balances of yToken
    uint256 hysiAmount = (YearnVault(tokenAddresses[0]).balanceOf(address(this)) * 1e18) / quantities[0];

    for (uint256 i = 1; i < tokenAddresses.length; i++) {
      hysiAmount = Math.min(
        hysiAmount,
        (YearnVault(tokenAddresses[i]).balanceOf(address(this)) * 1e18) / quantities[i]
      );
    }

    require(hysiAmount >= _minAmountToMint, "slippage too high");

    //Mint Butter
    setBasicIssuanceModule.issue(setToken, hysiAmount, address(this));

    //Save the minted amount Butter as claimable token for the batch
    batch.claimableTokenBalance = hysiAmount;

    //Set claimable to true so users can claim their Butter
    batch.claimable = true;

    //Update lastMintedAt for cooldown calculations
    lastMintedAt = block.timestamp;

    emit BatchMinted(currentMintBatchId, batch.suppliedTokenBalance, hysiAmount);

    //Create the next mint batch
    _generateNextBatch(currentMintBatchId, BatchType.Mint);
  }

  /**
   * @notice Redeems Butter for 3CRV. This function goes through all the steps necessary to get 3CRV
   * @param _min3crvToReceive sets minimum amount of 3crv to redeem Butter for, otherwise the transaction will revert
   * @dev This function reedeems Butter for the underlying yToken and deposits these yToken in curve Metapools for 3CRV
   * @dev In order to get stablecoins from 3CRV we can use a zap to redeem 3CRV for stables in the curve tri-pool
   * @dev handleKeeperIncentive checks if the msg.sender is a permissioned keeper and pays them a reward for calling this function (see KeeperIncentive.sol)
   */
  function batchRedeem(uint256 _min3crvToReceive) external whenNotPaused {
    KeeperIncentive(contractRegistry.getContract(keccak256("KeeperIncentive"))).handleKeeperIncentive(
      contractName,
      1,
      msg.sender
    );
    Batch storage batch = batches[currentRedeemBatchId];

    //Check if there was enough time between the last batch redemption and this attempt...
    //...or if enough Butter was deposited to make the redemption worthwhile
    //This is to prevent excessive gas consumption and costs as we will pay keeper to call this function
    require(
      (block.timestamp - lastRedeemedAt >= batchCooldown) || (batch.suppliedTokenBalance >= redeemThreshold),
      "can not execute batch action yet"
    );
    //Check if the Batch got already processed -- should technically not be possible
    require(batch.claimable == false, "already redeemed");

    //Check if this contract has enough Butter -- should technically not be necessary
    require(
      setToken.balanceOf(address(this)) >= batch.suppliedTokenBalance,
      "contract has insufficient balance of token to redeem"
    );

    //Get tokenAddresses for mapping of underlying
    (address[] memory tokenAddresses, ) = setBasicIssuanceModule.getRequiredComponentUnitsForIssue(setToken, 1e18);

    //Allow setBasicIssuanceModule to use Butter
    _setBasicIssuanceModuleAllowance(batch.suppliedTokenBalance);
    //Redeem Butter for yToken
    setBasicIssuanceModule.redeem(setToken, batch.suppliedTokenBalance, address(this));

    //Check our balance of 3CRV since we could have some still around from previous batches
    uint256 oldBalance = threeCrv.balanceOf(address(this));

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Deposit yToken to receive crvLPToken
      _withdrawFromYearn(YearnVault(tokenAddresses[i]).balanceOf(address(this)), YearnVault(tokenAddresses[i]));

      uint256 crvLPTokenBalance = curvePoolTokenPairs[tokenAddresses[i]].crvLPToken.balanceOf(address(this));

      //Deposit crvLPToken to receive 3CRV
      _withdrawFromCurve(crvLPTokenBalance, curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool);
    }

    //Save the redeemed amount of 3CRV as claimable token for the batch
    batch.claimableTokenBalance = threeCrv.balanceOf(address(this)) - oldBalance;

    require(batch.claimableTokenBalance >= _min3crvToReceive, "slippage too high");

    emit BatchRedeemed(currentRedeemBatchId, batch.suppliedTokenBalance, batch.claimableTokenBalance);

    //Set claimable to true so users can claim their Butter
    batch.claimable = true;

    //Update lastRedeemedAt for cooldown calculations
    lastRedeemedAt = block.timestamp;

    //Create the next redeem batch id
    _generateNextBatch(currentRedeemBatchId, BatchType.Redeem);
  }

  /**
   * @notice sets approval for contracts that require access to assets held by this contract
   */
  function setApprovals() external {
    (address[] memory tokenAddresses, ) = setBasicIssuanceModule.getRequiredComponentUnitsForIssue(setToken, 1e18);

    for (uint256 i; i < tokenAddresses.length; i++) {
      IERC20 curveLpToken = curvePoolTokenPairs[tokenAddresses[i]].crvLPToken;
      CurveMetapool curveMetapool = curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool;
      YearnVault yearnVault = YearnVault(tokenAddresses[i]);

      threeCrv.safeApprove(address(curveMetapool), 0);
      threeCrv.safeApprove(address(curveMetapool), type(uint256).max);

      curveLpToken.safeApprove(address(yearnVault), 0);
      curveLpToken.safeApprove(address(yearnVault), type(uint256).max);

      curveLpToken.safeApprove(address(curveMetapool), 0);
      curveLpToken.safeApprove(address(curveMetapool), type(uint256).max);
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
   * @notice sets allowance for basic issuance module
   * @param _amount amount to approve
   */
  function _setBasicIssuanceModuleAllowance(uint256 _amount) internal {
    setToken.safeApprove(address(setBasicIssuanceModule), 0);
    setToken.safeApprove(address(setBasicIssuanceModule), _amount);
  }

  /**
   * @notice makes sure only zapper or user can withdraw from accout_ and returns the recipient of the withdrawn token
   * @param _account is the address which gets withdrawn from
   * @dev returns recipient of the withdrawn funds
   * @dev By default a user should set _account to their address
   * @dev If zapper is used to withdraw and swap for a user the msg.sender will be zapper and _account is the user which we withdraw from. The zapper than sends the swapped funds afterwards to the user
   */
  function _getRecipient(address _account) internal view returns (address) {
    //Make sure that only zapper can withdraw from someone else
    require(
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).hasRole(
        keccak256("ButterZapper"),
        msg.sender
      ) || msg.sender == _account,
      "you cant transfer other funds"
    );

    //Set recipient per default to _account
    address recipient = _account;

    //set the recipient to zapper if its called by the zapper
    if (
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).hasRole(
        keccak256("ButterZapper"),
        msg.sender
      )
    ) {
      recipient = msg.sender;
    }
    return recipient;
  }

  /**
   * @notice Generates the next batch id for new deposits
   * @param _currentBatchId takes the current mint or redeem batch id
   * @param _batchType BatchType of the newly created id
   */
  function _generateNextBatch(bytes32 _currentBatchId, BatchType _batchType) internal returns (bytes32) {
    bytes32 id = _generateNextBatchId(_currentBatchId);
    batchIds.push(id);
    Batch storage batch = batches[id];
    batch.batchType = _batchType;
    batch.batchId = id;

    if (BatchType.Mint == _batchType) {
      currentMintBatchId = id;
      batch.suppliedTokenAddress = address(threeCrv);
      batch.claimableTokenAddress = address(setToken);
    }
    if (BatchType.Redeem == _batchType) {
      currentRedeemBatchId = id;
      batch.suppliedTokenAddress = address(setToken);
      batch.claimableTokenAddress = address(threeCrv);
    }
    return id;
  }

  /**
   * @notice Deposit either Butter or 3CRV in their respective batches
   * @param _amount The amount of 3CRV or Butter a user is depositing
   * @param _currentBatchId The current reedem or mint batch id to place the funds in the next batch to be processed
   * @param _depositFor User that gets the shares attributed to (for use in zapper contract)
   * @dev This function will be called by depositForMint or depositForRedeem and simply reduces code duplication
   */
  function _deposit(
    uint256 _amount,
    bytes32 _currentBatchId,
    address _depositFor
  ) internal {
    Batch storage batch = batches[_currentBatchId];

    //Add the new funds to the batch
    batch.suppliedTokenBalance = batch.suppliedTokenBalance + _amount;
    batch.unclaimedShares = batch.unclaimedShares + _amount;
    accountBalances[_currentBatchId][_depositFor] = accountBalances[_currentBatchId][_depositFor] + _amount;

    //Save the batchId for the user so they can be retrieved to claim the batch
    if (
      accountBatches[_depositFor].length == 0 ||
      accountBatches[_depositFor][accountBatches[_depositFor].length - 1] != _currentBatchId
    ) {
      accountBatches[_depositFor].push(_currentBatchId);
    }

    emit Deposit(_depositFor, _amount);
  }

  /**
   * @notice Deposit 3CRV in a curve metapool for its LP-Token
   * @param _amount The amount of 3CRV that gets deposited
   * @param _curveMetapool The metapool where we want to provide liquidity
   */
  function _sendToCurve(uint256 _amount, CurveMetapool _curveMetapool) internal {
    //Takes 3CRV and sends lpToken to this contract
    //Metapools take an array of amounts with the exoctic stablecoin at the first spot and 3CRV at the second.
    //The second variable determines the min amount of LP-Token we want to receive (slippage control)
    _curveMetapool.add_liquidity([0, _amount], 0);
  }

  /**
   * @notice Withdraws 3CRV for deposited crvLPToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _curveMetapool The metapool where we want to provide liquidity
   */
  function _withdrawFromCurve(uint256 _amount, CurveMetapool _curveMetapool) internal {
    //Takes lp Token and sends 3CRV to this contract
    //The second variable is the index for the token we want to receive (0 = exotic stablecoin, 1 = 3CRV)
    //The third variable determines min amount of token we want to receive (slippage control)
    _curveMetapool.remove_liquidity_one_coin(_amount, 1, 0);
  }

  /**
   * @notice Deposits crvLPToken for yToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _sendToYearn(uint256 _amount, YearnVault _yearnVault) internal {
    //Mints yToken and sends them to msg.sender (this contract)
    _yearnVault.deposit(_amount);
  }

  /**
   * @notice Withdraw crvLPToken from yearn
   * @param _amount The amount of crvLPToken which we deposit
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _withdrawFromYearn(uint256 _amount, YearnVault _yearnVault) internal {
    //Takes yToken and sends crvLPToken to this contract
    _yearnVault.withdraw(_amount);
  }

  /**
   * @notice Generates the next batch id for new deposits
   * @param _currentBatchId takes the current mint or redeem batch id
   */
  function _generateNextBatchId(bytes32 _currentBatchId) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(block.timestamp, _currentBatchId));
  }

  /* ========== ADMIN ========== */

  /**
   * @notice This function allows the owner to change the composition of underlying token of the Butter
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   */
  function setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] calldata _curvePoolTokenPairs)
    public
  {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);
  }

  /**
   * @notice This function defines which underlying token and pools are needed to mint a hysi token
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   * @dev since our calculations for minting just iterate through the index and match it with the quantities given by Set
   * @dev we must make sure to align them correctly by index, otherwise our whole calculation breaks down
   */
  function _setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] memory _curvePoolTokenPairs)
    internal
  {
    emit CurveTokenPairsUpdated(_yTokenAddresses, _curvePoolTokenPairs);
    for (uint256 i; i < _yTokenAddresses.length; i++) {
      curvePoolTokenPairs[_yTokenAddresses[i]] = _curvePoolTokenPairs[i];
    }
    emit CurveTokenPairsUpdated(_yTokenAddresses, _curvePoolTokenPairs);
  }

  /**
   * @notice Changes the current batch cooldown
   * @param _cooldown Cooldown in seconds
   * @dev The cooldown is the same for redeem and mint batches
   */
  function setBatchCooldown(uint256 _cooldown) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit BatchCooldownUpdated(batchCooldown, _cooldown);
    batchCooldown = _cooldown;
  }

  /**
   * @notice Changes the Threshold of 3CRV which need to be deposited to be able to mint immediately
   * @param _threshold Amount of 3CRV necessary to mint immediately
   */
  function setMintThreshold(uint256 _threshold) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit MintThresholdUpdated(mintThreshold, _threshold);
    mintThreshold = _threshold;
  }

  /**
   * @notice Changes the Threshold of Butter which need to be deposited to be able to redeem immediately
   * @param _threshold Amount of Butter necessary to mint immediately
   */
  function setRedeemThreshold(uint256 _threshold) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit RedeemThresholdUpdated(redeemThreshold, _threshold);
    redeemThreshold = _threshold;
  }

  /**
   * @notice Pauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function pause() external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    _pause();
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IACLRegistry {
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
   * bearer except when using {AccessControl-_setupRole}.
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
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns `true` if `account` has been granted `permission`.
   */
  function hasPermission(bytes32 permission, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

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
  function renounceRole(bytes32 role, address account) external;

  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  function grantPermission(bytes32 permission, address account) external;

  function revokePermission(bytes32 permission) external;

  function requireApprovedContractOrEOA(address account) external view;

  function requireRole(bytes32 role, address account) external view;

  function requirePermission(bytes32 permission, address account) external view;

  function isRoleAdmin(bytes32 role, address account) external view;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface IStaking {
  function balanceOf(address account) external view returns (uint256);

  function stake(uint256 amount, uint256 lengthOfTime) external;

  function stakeFor(
    address account,
    uint256 amount,
    uint256 lengthOfTime
  ) external;

  function withdraw(uint256 amount) external;

  function getVoiceCredits(address _address) external view returns (uint256);

  function getWithdrawableBalance(address _address) external view returns (uint256);

  function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IACLRegistry.sol";
import "../interfaces/IContractRegistry.sol";
import "../interfaces/IStaking.sol";

contract KeeperIncentive {
  using SafeERC20 for IERC20;

  struct Incentive {
    uint256 reward; //pop reward for calling the function
    bool enabled;
    bool openToEveryone; //can everyone call the function to get the reward or only approved?
  }

  /* ========== STATE VARIABLES ========== */

  IContractRegistry public contractRegistry;

  uint256 public incentiveBudget;
  mapping(bytes32 => Incentive[]) public incentives;
  mapping(bytes32 => address) public controllerContracts;
  uint256 public burnRate;
  address internal immutable burnAddress = 0x000000000000000000000000000000000000dEaD; // Burn Address
  uint256 public requiredKeeperStake;

  /* ========== EVENTS ========== */

  event IncentiveCreated(bytes32 contractName, uint256 reward, bool openToEveryone);
  event IncentiveChanged(
    bytes32 contractName,
    uint256 oldReward,
    uint256 newReward,
    bool oldOpenToEveryone,
    bool newOpenToEveryone
  );
  event IncentiveFunded(uint256 amount);
  event ApprovalToggled(bytes32 contractName, bool openToEveryone);
  event IncentiveToggled(bytes32 contractName, bool enabled);
  event ControllerContractAdded(bytes32 contractName, address contractAddress);
  event Burned(uint256 amount);
  event BurnRateChanged(uint256 oldRate, uint256 newRate);
  event RequiredKeeperStakeChanged(uint256 oldRequirement, uint256 newRequirement);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    uint256 _burnRate,
    uint256 _requiredKeeperStake
  ) {
    contractRegistry = _contractRegistry;
    burnRate = _burnRate; //25e16
    requiredKeeperStake = _requiredKeeperStake; // 2000 ether
  }

  /* ==========  MUTATIVE FUNCTIONS  ========== */

  function handleKeeperIncentive(
    bytes32 _contractName,
    uint8 _i,
    address _keeper
  ) external {
    require(msg.sender == controllerContracts[_contractName], "Can only be called by the controlling contract");

    Incentive memory incentive = incentives[_contractName][_i];

    if (!incentive.openToEveryone) {
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("Keeper"), _keeper);
      require(
        IStaking(contractRegistry.getContract(keccak256("PopLocker"))).balanceOf(_keeper) >= requiredKeeperStake,
        "not enough pop at stake"
      );
    }
    if (incentive.enabled && incentive.reward <= incentiveBudget && incentive.reward > 0) {
      incentiveBudget = incentiveBudget - incentive.reward;
      uint256 amountToBurn = (incentive.reward * burnRate) / 1e18;
      uint256 incentivePayout = incentive.reward - amountToBurn;
      IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransfer(_keeper, incentivePayout);
      _burn(amountToBurn);
    }
  }

  /* ========== SETTER ========== */

  /**
   * @notice Create Incentives for keeper to call a function
   * @param _contractName Name of contract that uses ParticipationRewards in bytes32
   * @param _reward The amount in POP the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone Can anyone call the function for rewards or only keeper?
   * @dev This function is only for creating unique incentives for future contracts
   * @dev Multiple functions can use the same incentive which can than be updated with one governance vote
   */
  function createIncentive(
    bytes32 _contractName,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone
  ) public {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    incentives[_contractName].push(Incentive({reward: _reward, enabled: _enabled, openToEveryone: _openToEveryone}));
    emit IncentiveCreated(_contractName, _reward, _openToEveryone);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function updateIncentive(
    bytes32 _contractName,
    uint8 _i,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone
  ) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    Incentive storage incentive = incentives[_contractName][_i];
    uint256 oldReward = incentive.reward;
    bool oldOpenToEveryone = incentive.openToEveryone;
    incentive.reward = _reward;
    incentive.enabled = _enabled;
    incentive.openToEveryone = _openToEveryone;
    emit IncentiveChanged(_contractName, oldReward, _reward, oldOpenToEveryone, _openToEveryone);
  }

  function toggleApproval(bytes32 _contractName, uint8 _i) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    Incentive storage incentive = incentives[_contractName][_i];
    incentive.openToEveryone = !incentive.openToEveryone;
    emit ApprovalToggled(_contractName, incentive.openToEveryone);
  }

  function toggleIncentive(bytes32 _contractName, uint8 _i) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    Incentive storage incentive = incentives[_contractName][_i];
    incentive.enabled = !incentive.enabled;
    emit IncentiveToggled(_contractName, incentive.enabled);
  }

  function fundIncentive(uint256 _amount) external {
    IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransferFrom(msg.sender, address(this), _amount);
    incentiveBudget = incentiveBudget + _amount;
    emit IncentiveFunded(_amount);
  }

  /**
   * @notice In order to allow a contract to use ParticipationReward they need to be added as a controller contract
   * @param _contractName the name of the controller contract in bytes32
   * @param contract_ the address of the controller contract
   * @dev all critical functions to init/open vaults and add shares to them can only be called by controller contracts
   */
  function addControllerContract(bytes32 _contractName, address contract_) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    controllerContracts[_contractName] = contract_;
    emit ControllerContractAdded(_contractName, contract_);
  }

  /**
   * @notice Sets the current burn rate as a percentage of the incentive reward.
   * @param _burnRate Percentage in Mantissa. (1e14 = 1 Basis Point)
   */
  function updateBurnRate(uint256 _burnRate) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit BurnRateChanged(burnRate, _burnRate);
    burnRate = _burnRate;
  }

  function _burn(uint256 _amount) internal {
    IERC20(contractRegistry.getContract(keccak256("POP"))).transfer(burnAddress, _amount);
    emit Burned(_amount);
  }

  /**
   * @notice Sets the required amount of POP a keeper needs to have staked to handle incentivized functions.
   * @param _amount Amount of POP a keeper needs to stake
   */
  function updateRequiredKeeperStake(uint256 _amount) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit RequiredKeeperStakeChanged(requiredKeeperStake, _amount);
    requiredKeeperStake = _amount;
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./ISetToken.sol";

interface BasicIssuanceModule {
  function getRequiredComponentUnitsForIssue(ISetToken _setToken, uint256 _quantity)
    external
    view
    returns (address[] memory, uint256[] memory);

  function issue(
    ISetToken _setToken,
    uint256 _quantity,
    address _to
  ) external;

  function redeem(
    ISetToken _setToken,
    uint256 _quantity,
    address _to
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface CurveAddressProvider {
  function get_registry() external view returns (address);
}

interface CurveRegistry {
  function get_pool_from_lp_token(address lp_token) external view returns (address);
}

interface CurveMetapool {
  function get_virtual_price() external view returns (uint256);

  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amounts) external returns (uint256);

  function add_liquidity(
    uint256[2] calldata _amounts,
    uint256 _min_mint_amounts,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 amount,
    int128 i,
    uint256 min_underlying_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface ThreeCrv is IERC20 {}

interface CrvLPToken is IERC20 {}

// SPDX-License-Identifier: Apache-2.0
// Docgen-SOLC: 0.8.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {
  /* ============ Enums ============ */

  enum ModuleState {
    NONE,
    PENDING,
    INITIALIZED
  }

  /* ============ Structs ============ */
  /**
   * The base definition of a SetToken Position
   *
   * @param component           Address of token in the Position
   * @param module              If not in default state, the address of associated module
   * @param unit                Each unit is the # of components per 10^18 of a SetToken
   * @param positionState       Position ENUM. Default is 0; External is 1
   * @param data                Arbitrary data
   */
  struct Position {
    address component;
    address module;
    int256 unit;
    uint8 positionState;
    bytes data;
  }

  /**
   * A struct that stores a component's cash position details and external positions
   * This data structure allows O(1) access to a component's cash position units and
   * virtual units.
   *
   * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
   *                                  updating all units at once via the position multiplier. Virtual units are achieved
   *                                  by dividing a "real" value by the "positionMultiplier"
   * @param componentIndex
   * @param externalPositionModules   List of external modules attached to each external position. Each module
   *                                  maps to an external position
   * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
   */
  struct ComponentPosition {
    int256 virtualUnit;
    address[] externalPositionModules;
    mapping(address => ExternalPosition) externalPositions;
  }

  /**
   * A struct that stores a component's external position details including virtual unit and any
   * auxiliary data.
   *
   * @param virtualUnit       Virtual value of a component's EXTERNAL position.
   * @param data              Arbitrary data
   */
  struct ExternalPosition {
    int256 virtualUnit;
    bytes data;
  }

  /* ============ Functions ============ */

  function addComponent(address _component) external;

  function removeComponent(address _component) external;

  function editDefaultPositionUnit(address _component, int256 _realUnit) external;

  function addExternalPositionModule(address _component, address _positionModule) external;

  function removeExternalPositionModule(address _component, address _positionModule) external;

  function editExternalPositionUnit(
    address _component,
    address _positionModule,
    int256 _realUnit
  ) external;

  function editExternalPositionData(
    address _component,
    address _positionModule,
    bytes calldata _data
  ) external;

  function invoke(
    address _target,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes memory);

  function editPositionMultiplier(int256 _newMultiplier) external;

  function mint(address _account, uint256 _quantity) external;

  function burn(address _account, uint256 _quantity) external;

  function lock() external;

  function unlock() external;

  function addModule(address _module) external;

  function removeModule(address _module) external;

  function initializeModule() external;

  function setManager(address _manager) external;

  function manager() external view returns (address);

  function moduleStates(address _module) external view returns (ModuleState);

  function getModules() external view returns (address[] memory);

  function getDefaultPositionRealUnit(address _component) external view returns (int256);

  function getExternalPositionRealUnit(address _component, address _positionModule) external view returns (int256);

  function getComponents() external view returns (address[] memory);

  function getExternalPositionModules(address _component) external view returns (address[] memory);

  function getExternalPositionData(address _component, address _positionModule) external view returns (bytes memory);

  function isExternalPositionModule(address _component, address _module) external view returns (bool);

  function isComponent(address _component) external view returns (bool);

  function positionMultiplier() external view returns (int256);

  function getPositions() external view returns (Position[] memory);

  function getTotalComponentRealUnits(address _component) external view returns (int256);

  function isInitializedModule(address _module) external view returns (bool);

  function isPendingModule(address _module) external view returns (bool);

  function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface YearnVault is IERC20 {
  function token() external view returns (address);

  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function pricePerShare() external view returns (uint256);
}