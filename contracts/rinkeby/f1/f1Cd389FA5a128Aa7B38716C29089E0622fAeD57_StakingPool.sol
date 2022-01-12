// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    struct SingleStakingPool {
      address stakeToken;
      address rewardToken;
      uint256 totalStaking;
      uint256 timeLock;
    }

    struct MultiStakingPool {
      address stakeToken1;
      address stakeToken2;
      address rewardToken;
      uint256 totalStakingToken1;
      uint256 totalStakingToken2;
      uint256 timeLock;
    }

    SingleStakingPool[] public initialPools;
    SingleStakingPool[] public normalPools;
    MultiStakingPool[] public pairPools;

    uint256 MINIMUM_LOCK = 10 minutes;

    struct UserStakeSingleToken {
        address userAddress;
        uint256 planId;
        uint256 stakeId;
        uint256 totalCurrentStake;    
        uint256 amount;
        uint256 startDate;
        uint256 timeLock;
        bool stateUnStake;
        bool stateReward;
    }

    struct UserStakePair {
        address userAddress;
        uint256 planId;
        uint256 stakeId;
        uint256 totalCurrentStake1;
        uint256 totalCurrentStake2;
        uint256 amountToken1;
        uint256 amountToken2;
        uint256 startDate;
        uint256 timeLock;
        bool stateUnStake;
        bool stateReward;
    }

    struct UserDistributeReward {
        address userAddress;
        address tokenRewardAddress;
        uint256 planId;
        uint256 stakeId;
        uint256 rewardAmount;
    }

    struct HistorySingleStake {
        UserStakeSingleToken[] historyStake;
    }

    struct HistoryPairStake {
        UserStakePair[] historyStake;
    }

    struct Pools {
        SingleStakingPool[] initial;
        SingleStakingPool[] normal;
        MultiStakingPool[] pair;
    }

    struct ListAvailableDistributeReward {
        UserStakeSingleToken[] listAvailableRewardInitial;
        UserStakeSingleToken[] listAvailableRewardNormal;
        UserStakePair[] listAvailableRewardPair;
    }

    mapping(address => uint256[]) public listStakeInitialOfUser;
    mapping(address => uint256[]) public listStakeNormalOfUser;
    mapping(address => uint256[]) public listStakePairOfUser;
    UserStakeSingleToken[] public allStakeInitial;
    UserStakeSingleToken[] public allStakeNormal;
    UserStakePair[] public allStakePair;

    address public WETH;
    mapping(address => bool) public adminWhiteList;

    /* ========== EVENTS ========== */

    event StakeInitial(address indexed user, uint256 amount);
    event StakeNormal(address indexed user, uint256 amount);
    event StakePair(address indexed user, uint256 amount1, uint256 amount2);
    event UnStakeInitial(address indexed user, uint256 amount);
    event UnStakeNormal(address indexed user, uint256 amount);
    event UnStakePair(address indexed user, uint256 amount1, uint256 amount2);

    /* ========== CONSTRUCTOR ========== */

    /// @dev Init pools for staking
    /// @param initialAddresses a array contain [stakeToken, rewardToken]
    /// @param normalAddresses a array contain [stakeToken, rewardToken, stakeToken, rewardToken]
    /// @param pairAddresses a array contain list stake token [stakeToken1, stakeToken2, stakeToken1, stakeToken2]
    /// @param rewardTokenPair a address is rewardToken when end pairStaking
    /// @param _WETH a contract address of ETH
    constructor(
        address[2] memory initialAddresses,
        address[2][2] memory normalAddresses,
        address[2][5] memory pairAddresses,
        address rewardTokenPair,
        address _WETH
    ) {
        WETH = _WETH;
        adminWhiteList[msg.sender] = true;
        initPools(initialAddresses, normalAddresses, pairAddresses, rewardTokenPair);
    }

    /* ========== INIT POOLS =========== */
    function initPools(address[2] memory _initialAddresses, address[2][2] memory _normalAddresses, address[2][5] memory _pairAddresses, address _rewardTokenPair) private {
      // Create pools for initial pools
      createInitialStakingPool(_initialAddresses[0], _initialAddresses[1], 90 days);
      createInitialStakingPool(_initialAddresses[0], _initialAddresses[1], 180 days);

      // Create pools for normal pools
      createNormalStakingPool(_normalAddresses[0][0], _normalAddresses[0][1], MINIMUM_LOCK);
      createNormalStakingPool(_normalAddresses[1][0], _normalAddresses[1][1], MINIMUM_LOCK);

      // Create pools for pair pools
      createMultiStakingPool(_pairAddresses[0][0], _pairAddresses[0][1], _rewardTokenPair, MINIMUM_LOCK);
      createMultiStakingPool(_pairAddresses[1][0], _pairAddresses[1][1], _rewardTokenPair, MINIMUM_LOCK);
      createMultiStakingPool(_pairAddresses[2][0], _pairAddresses[2][1], _rewardTokenPair, MINIMUM_LOCK);
      createMultiStakingPool(_pairAddresses[3][0], _pairAddresses[3][1], _rewardTokenPair, MINIMUM_LOCK);
      createMultiStakingPool(_pairAddresses[4][0], _pairAddresses[4][1], _rewardTokenPair, MINIMUM_LOCK);
    }

    function createInitialStakingPool(address _stakeToken, address _rewardToken, uint256 _timeLock) private {
      initialPools.push(
        SingleStakingPool({
          stakeToken: _stakeToken,
          rewardToken: _rewardToken,
          totalStaking: 0,
          timeLock: _timeLock
        })
      );
    }

    function createNormalStakingPool(address _stakeToken, address _rewardToken, uint256 _timeLock) private {
      normalPools.push(
        SingleStakingPool({
          stakeToken: _stakeToken,
          rewardToken: _rewardToken,
          totalStaking: 0,
          timeLock: _timeLock
        })
      );
    }

    function createMultiStakingPool(address _stakeToken1, address _stakeToken2, address _rewardToken, uint256 _timeLock) private {
      pairPools.push(
        MultiStakingPool({
          stakeToken1: _stakeToken1,
          stakeToken2: _stakeToken2,
          rewardToken: _rewardToken,
          totalStakingToken1: 0,
          totalStakingToken2: 0,
          timeLock: _timeLock
        })
      );
    }

    /* ========== ONLY OWNER ========= */

    function addAdminToWhiteList(address _admin) public onlyOwner {
        adminWhiteList[_admin] = true;
    }

    function addPoolInitial(address[2] memory _addresses, uint256 _timeLock) public onlyOwner {
        createInitialStakingPool(_addresses[0], _addresses[1], _timeLock);
    }

    function addPoolNormal(address[2] memory _addresses, uint256 _timeLock) public onlyOwner {
        createNormalStakingPool(_addresses[0], _addresses[1], _timeLock);
    }

    function addPoolPair(address[2] memory _addresses, address _rewardToken, uint256 _timeLock) public onlyOwner {
        createMultiStakingPool(_addresses[0], _addresses[1], _rewardToken, _timeLock);
    }

    function changeTimeLockInitial(uint256 _planId, uint256 _timeLock) public onlyOwner {
        SingleStakingPool storage currentPool = initialPools[_planId];
        currentPool.timeLock = _timeLock;
    }

    function changeTimeLockNormal(uint256 _planId, uint256 _timeLock) public onlyOwner {
        SingleStakingPool storage currentPool = normalPools[_planId];
        currentPool.timeLock = _timeLock;
    }

    function changeTimeLockPair(uint256 _planId, uint256 _timeLock) public onlyOwner {
        MultiStakingPool storage currentPool = pairPools[_planId];
        currentPool.timeLock = _timeLock;
    }

    /* ========== VIEWS ========== */

    function getAllPools() external view returns(Pools memory result) {
        result = Pools({
            initial: initialPools,
            normal: normalPools,
            pair: pairPools
        });
    }

    function getHistoryInitialStake(address _user) external view returns(HistorySingleStake memory result){
        uint256[] memory listIds = listStakeInitialOfUser[_user];
        result.historyStake = new UserStakeSingleToken[](listIds.length);
        for (uint256 i=0; i < listIds.length; i++) {
            result.historyStake[i] = allStakeInitial[listIds[i]];
        }
    }

    function getHistoryNormalStake(address _user) external view returns(HistorySingleStake memory result) {
        uint256[] memory listIds = listStakeNormalOfUser[_user];
        result.historyStake = new UserStakeSingleToken[](listIds.length);
        for (uint256 i=0; i < listIds.length; i++) {
            result.historyStake[i] = allStakeNormal[listIds[i]];
        }
    }

    function getHistoryPairStake(address _user) external view returns(HistoryPairStake memory result){
        uint256[] memory listIds = listStakePairOfUser[_user];
        result.historyStake = new UserStakePair[](listIds.length);
        for (uint256 i=0; i < listIds.length; i++) {
            result.historyStake[i] = allStakePair[listIds[i]];
        }
    }

    function getListDistributeRewardToken() external view returns(ListAvailableDistributeReward memory result){
        result.listAvailableRewardInitial = new UserStakeSingleToken[](allStakeInitial.length);
        for (uint256 i=0; i < allStakeInitial.length; i++) {
            result.listAvailableRewardInitial[i] = allStakeInitial[i];
        }
        result.listAvailableRewardNormal = new UserStakeSingleToken[](allStakeNormal.length);
        for (uint256 j=0; j < allStakeNormal.length; j++) {
            result.listAvailableRewardNormal[j] = allStakeNormal[j];
        }
        result.listAvailableRewardPair = new UserStakePair[](allStakePair.length);
        for (uint256 k=0; k < allStakePair.length; k++) {
            result.listAvailableRewardPair[k] = allStakePair[k];
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Staking Initial
    function stakeInitial(uint256 _planId, uint256 _amount) external {
        SingleStakingPool storage currentPool = initialPools[_planId];
        // Check allowance token of user
        require(
            IERC20(currentPool.stakeToken).allowance(msg.sender, address(this)) >=
                _amount,
            "token allowance too low"
        );

        // transfer token from user
        ERC20(currentPool.stakeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        
        currentPool.totalStaking = currentPool.totalStaking.add(_amount);

        allStakeInitial.push(
            UserStakeSingleToken({
                userAddress: msg.sender,
                planId: _planId,
                stakeId: allStakeInitial.length,
                totalCurrentStake: currentPool.totalStaking,
                amount: _amount,
                startDate: block.timestamp,
                timeLock: currentPool.timeLock,
                stateUnStake: false,
                stateReward: false
            })
        );
        listStakeInitialOfUser[msg.sender].push(allStakeInitial.length - 1);

        emit StakeInitial(msg.sender, _amount);
    }

    function unstakeInitial(uint256 _planId, uint256 _stakeId) external {
        SingleStakingPool storage currentPool = initialPools[_planId];
        bool doesListContainElement = false;
        for(uint256 i=0; i < listStakeInitialOfUser[msg.sender].length; i++) {
            if (_stakeId == listStakeInitialOfUser[msg.sender][i]) {
                doesListContainElement = true;
            }
        }
        require(doesListContainElement, "this stake is not exits");
        UserStakeSingleToken storage currentStake = allStakeInitial[_stakeId];

        // check enough time lock
        require(currentStake.startDate + currentStake.timeLock < block.timestamp, "stake not enough lock time");
        
        // check unstake
        require(!currentStake.stateUnStake, "this staking have unstaked");

        // transfer token to user
        ERC20(currentPool.stakeToken).safeTransfer(
            msg.sender,
            currentStake.amount
        );

        currentPool.totalStaking = currentPool.totalStaking.sub(currentStake.amount);
        currentStake.stateUnStake = true;
        emit UnStakeInitial(msg.sender, currentStake.amount);
    }

    // Staking Normal
    function stakeNormal(uint256 _planId, uint256 _amount) external {
        SingleStakingPool storage currentPool = normalPools[_planId];
        // Check allowance token of user
        require(
            IERC20(currentPool.stakeToken).allowance(msg.sender, address(this)) >=
                _amount,
            "token allowance too low"
        );

        // transfer token from user
        ERC20(currentPool.stakeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        
        currentPool.totalStaking = currentPool.totalStaking.add(_amount);

        allStakeNormal.push(
            UserStakeSingleToken({
                userAddress: msg.sender,
                planId: _planId,
                stakeId: allStakeNormal.length,
                totalCurrentStake: currentPool.totalStaking,
                amount: _amount,
                startDate: block.timestamp,
                timeLock: currentPool.timeLock,
                stateUnStake: false,
                stateReward: false
            })
        );

        listStakeNormalOfUser[msg.sender].push(allStakeNormal.length - 1);
        emit StakeNormal(msg.sender, _amount);
    }

    function unstakeNormal(uint256 _planId, uint256 _stakeId) external {
        SingleStakingPool storage currentPool = normalPools[_planId];
        bool doesListContainElement = false;
        for(uint256 i=0; i < listStakeNormalOfUser[msg.sender].length; i++) {
            if (_stakeId == listStakeNormalOfUser[msg.sender][i]) {
                doesListContainElement = true;
            }
        }
        require(doesListContainElement, "this stake is not exits");
        UserStakeSingleToken storage currentStake = allStakeNormal[_stakeId];

        // check enough time lock
        require(currentStake.startDate + currentStake.timeLock < block.timestamp, "stake not enough lock time");
        
        // check unstake
        require(!currentStake.stateUnStake, "this staking have unstaked");

        // transfer token to user
        ERC20(currentPool.stakeToken).safeTransfer(
            msg.sender,
            currentStake.amount
        );
        
        currentStake.stateUnStake = true;
        currentPool.totalStaking = currentPool.totalStaking.sub(currentStake.amount);
        emit UnStakeNormal(msg.sender, currentStake.amount);
    }

    // Staking Pair don't have ETH
    function stakePairToken(uint256 _planId, uint256 _amount1, uint256 _amount2) external {
        MultiStakingPool storage currentPool = pairPools[_planId];
        // Check allowance token1 of user
        require(
            IERC20(currentPool.stakeToken1).allowance(msg.sender, address(this)) >=
                _amount1,
            "token1 allowance too low"
        );

        require(
            IERC20(currentPool.stakeToken2).allowance(msg.sender, address(this)) >=
                _amount2,
            "token2 allowance too low"
        );

        // transfer token1 from user
        ERC20(currentPool.stakeToken1).safeTransferFrom(
            msg.sender,
            address(this),
            _amount1
        );

        // transfer token2 from user
        ERC20(currentPool.stakeToken2).safeTransferFrom(
            msg.sender,
            address(this),
            _amount2
        );
        
        currentPool.totalStakingToken1 = currentPool.totalStakingToken1.add(_amount1);
        currentPool.totalStakingToken2 = currentPool.totalStakingToken2.add(_amount2);

        allStakePair.push(
            UserStakePair({
                userAddress: msg.sender,
                planId: _planId,
                stakeId: allStakePair.length,
                totalCurrentStake1: currentPool.totalStakingToken1,
                totalCurrentStake2: currentPool.totalStakingToken2,
                amountToken1: _amount1,
                amountToken2: _amount2,
                startDate: block.timestamp,
                timeLock: currentPool.timeLock,
                stateUnStake: false,
                stateReward: false
            })
        );

        listStakePairOfUser[msg.sender].push(allStakePair.length - 1);
        emit StakePair(msg.sender, _amount1, _amount2);
    }

    function unstakePairToken(uint256 _planId, uint256 _stakeId) external {
        MultiStakingPool storage currentPool = pairPools[_planId];

        bool doesListContainElement = false;
        for(uint256 i=0; i < listStakePairOfUser[msg.sender].length; i++) {
            if (_stakeId == listStakePairOfUser[msg.sender][i]) {
                doesListContainElement = true;
            }
        }
        require(doesListContainElement, "this stake is not exits");
        UserStakePair storage currentStake = allStakePair[_stakeId];

        // check enough time lock
        require(currentStake.startDate + currentStake.timeLock < block.timestamp, "stake not enough lock time");
        
        // check unstake
        require(!currentStake.stateUnStake, "this staking have unstaked");

        // transfer token1 to user
        ERC20(currentPool.stakeToken1).safeTransfer(
            msg.sender,
            currentStake.amountToken1
        );

        // transfer token1 to user
        ERC20(currentPool.stakeToken2).safeTransfer(
            msg.sender,
            currentStake.amountToken2
        );
        
        currentStake.stateUnStake = true;
        currentPool.totalStakingToken1 = currentPool.totalStakingToken1.sub(currentStake.amountToken1);
        currentPool.totalStakingToken2 = currentPool.totalStakingToken2.sub(currentStake.amountToken2);
        emit UnStakePair(msg.sender, currentStake.amountToken1, currentStake.totalCurrentStake2);
    }


    // Staking Pair have ETH
    function stakePairETH(uint256 _planId, uint256 _amount1, uint256 _amount2) external payable {
        MultiStakingPool storage currentPool = pairPools[_planId];
        uint256 balance;
        if (currentPool.stakeToken1 == WETH) {
            // Check allowance token2 of user
            require(
                IERC20(currentPool.stakeToken2).allowance(msg.sender, address(this)) >=
                    _amount2,
                "token1 allowance too low"
            );
            // transfer token2 from user
            ERC20(currentPool.stakeToken2).safeTransferFrom(
                msg.sender,
                address(this),
                _amount2
            );
            balance = msg.value - _amount1;
        } else if (currentPool.stakeToken2 == WETH) {
            // Check allowance token1 of user
            require(
                IERC20(currentPool.stakeToken1).allowance(msg.sender, address(this)) >=
                    _amount1,
                "token1 allowance too low"
            );
            // transfer token1 from user
            ERC20(currentPool.stakeToken1).safeTransferFrom(
                msg.sender,
                address(this),
                _amount1
            );
            balance = msg.value - _amount2;
        }
        
        currentPool.totalStakingToken1 = currentPool.totalStakingToken1.add(_amount1);
        currentPool.totalStakingToken2 = currentPool.totalStakingToken2.add(_amount2);

        allStakePair.push(
            UserStakePair({
                userAddress: msg.sender,
                planId: _planId,
                stakeId: allStakePair.length,
                totalCurrentStake1: currentPool.totalStakingToken1,
                totalCurrentStake2: currentPool.totalStakingToken2,
                amountToken1: _amount1,
                amountToken2: _amount2,
                startDate: block.timestamp,
                timeLock: currentPool.timeLock,
                stateUnStake: false,
                stateReward: false
            })
        );

        listStakePairOfUser[msg.sender].push(allStakePair.length - 1);
        // return eth from user
        if (balance > 0)
            payable(msg.sender).transfer(balance);

        emit StakePair(msg.sender, _amount1, _amount2);
    }

    function unstakePairETH(uint256 _planId, uint256 _stakeId) external {
        MultiStakingPool storage currentPool = pairPools[_planId];

        bool doesListContainElement = false;
        for(uint256 i=0; i < listStakePairOfUser[msg.sender].length; i++) {
            if (_stakeId == listStakePairOfUser[msg.sender][i]) {
                doesListContainElement = true;
            }
        }
        require(doesListContainElement, "this stake is not exits");
        UserStakePair storage currentStake = allStakePair[_stakeId];

        // check enough time lock
        require(currentStake.startDate + currentStake.timeLock < block.timestamp, "stake not enough lock time");
        
        // check unstake
        require(!currentStake.stateUnStake, "this staking have unstaked");

        if (currentPool.stakeToken1 == WETH) {
            payable(msg.sender).transfer(currentStake.amountToken1);

            // transfer token2 to user
            ERC20(currentPool.stakeToken2).safeTransfer(
                msg.sender,
                currentStake.amountToken2
            );
        } else if (currentPool.stakeToken2 == WETH) {
            payable(msg.sender).transfer(currentStake.amountToken2);

            // transfer token2 to user
            ERC20(currentPool.stakeToken1).safeTransfer(
                msg.sender,
                currentStake.amountToken1
            );
        }
        
        currentStake.stateUnStake = true;
        currentPool.totalStakingToken1 = currentPool.totalStakingToken1.sub(currentStake.amountToken1);
        currentPool.totalStakingToken2 = currentPool.totalStakingToken2.sub(currentStake.amountToken2);
        emit UnStakePair(msg.sender, currentStake.amountToken1, currentStake.totalCurrentStake2);
    }

    modifier onlyAdmin() {
        require(adminWhiteList[msg.sender], "Only admin transfer reward token to user");
        _;
    }

    // Bulk Trasfer reward token for initial staking vs normal Staking
    /// @dev Function transfer reward token for user after end time staking
    /// @param listReceivers is a list object user need distribute reward token
    function transferRewardInitialStaking(UserDistributeReward[] memory listReceivers) public onlyAdmin {
        for (uint256 i = 0; i < listReceivers.length; i++) {
            UserStakeSingleToken storage currentStake = allStakeInitial[listReceivers[i].stakeId];

            if (currentStake.stateReward) { continue; }
            ERC20(listReceivers[i].tokenRewardAddress).safeTransfer(
                listReceivers[i].userAddress,
                listReceivers[i].rewardAmount
            );

            currentStake.stateReward = true;
        }
    }

    // Bulk Transfer reward token for normal
    function transferRewardsNormalStaking(UserDistributeReward[] memory listReceivers) public onlyAdmin {
        for (uint256 i = 0; i < listReceivers.length; i++) {
            UserStakeSingleToken storage currentStake = allStakeNormal[listReceivers[i].stakeId];

            if (currentStake.stateReward) { continue; }
            ERC20(listReceivers[i].tokenRewardAddress).safeTransfer(
                listReceivers[i].userAddress,
                listReceivers[i].rewardAmount
            );

            currentStake.stateReward = true;
        }
    }

    // Bulk Transfer reward token for pair staking 
    function transferRewardsPairStaking(UserDistributeReward[] memory listReceivers) public onlyAdmin {
        for (uint256 i = 0; i < listReceivers.length; i++) {
            UserStakePair storage currentStake = allStakePair[listReceivers[i].stakeId];

            if (currentStake.stateReward) { continue; }
            ERC20(listReceivers[i].tokenRewardAddress).safeTransfer(
                listReceivers[i].userAddress,
                listReceivers[i].rewardAmount
            );

            currentStake.stateReward = true;
        }
    }
}