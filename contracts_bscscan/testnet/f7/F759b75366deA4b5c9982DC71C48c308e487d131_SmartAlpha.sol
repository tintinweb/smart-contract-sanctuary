// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/ISeniorRateModel.sol";
import "./interfaces/IAccountingModel.sol";
import "./SmartAlphaEvents.sol";

/// @notice Governance functions for SmartAlpha
/// @dev It defines a DAO and a Guardian
/// From a privilege perspective, the DAO is also considered Guardian, allowing it to execute any action
/// that the Guardian can do.
abstract contract Governed is SmartAlphaEvents {
    address public dao;
    address public guardian;

    bool public paused;

    IPriceOracle public priceOracle;
    ISeniorRateModel public seniorRateModel;
    IAccountingModel public accountingModel;

    uint256 public constant MAX_FEES_PERCENTAGE = 5 * 10 ** 16; // 5% * 10^18
    address public feesOwner;
    uint256 public feesPercentage;

    constructor (address _dao, address _guardian) {
        require(_dao != address(0), "invalid address");
        require(_guardian != address(0), "invalid address");

        dao = _dao;
        guardian = _guardian;
    }

    /// @notice Transfer the DAO to a new address
    /// @dev Only callable by the current DAO. The new dao cannot be address(0) or the same dao.
    /// @param newDAO The address of the new dao
    function transferDAO(address newDAO) public {
        enforceCallerDAO();
        require(newDAO != address(0), "invalid address");
        require(newDAO != dao, "!new");

        emit TransferDAO(dao, newDAO);

        dao = newDAO;
    }

    /// @notice Transfer the Guardian to a new address
    /// @dev Callable by the current DAO or the current Guardian. The new Guardian cannot be address(0)
    /// or the same as before.
    /// @param newGuardian The address of the new Guardian
    function transferGuardian(address newGuardian) public {
        enforceCallerGuardian();
        require(newGuardian != address(0), "invalid address");
        require(newGuardian != guardian, "!new");

        emit TransferGuardian(guardian, newGuardian);

        guardian = newGuardian;
    }

    /// @notice Pause the deposits into the system
    /// @dev Callable by DAO or Guardian. It will block any junior & senior deposits until resumed.
    function pauseSystem() public {
        enforceCallerGuardian();
        require(!paused, "paused");

        paused = true;

        emit PauseSystem();
    }

    /// @notice Resume the deposits into the system
    /// @dev Callable by DAO or Guardian. It will resume deposits.
    function resumeSystem() public {
        enforceCallerGuardian();
        require(paused, "!paused");

        paused = false;

        emit ResumeSystem();
    }

    /// @notice Change the price oracle
    /// @dev Only callable by DAO. The address of the new price oracle must have contract code.
    /// @param newPriceOracle The address of the new price oracle contract
    function setPriceOracle(address newPriceOracle) public {
        enforceCallerDAO();
        enforceHasContractCode(newPriceOracle, "invalid address");

        emit SetPriceOracle(address(priceOracle), newPriceOracle);

        priceOracle = IPriceOracle(newPriceOracle);
    }

    /// @notice Change the senior rate model contract
    /// @dev Only callable by DAO. The address of the new contract must have code.
    /// @param newModel The address of the new model
    function setSeniorRateModel(address newModel) public {
        enforceCallerDAO();
        enforceHasContractCode(newModel, "invalid address");

        emit SetSeniorRateModel(address(seniorRateModel), newModel);

        seniorRateModel = ISeniorRateModel(newModel);
    }

    /// @notice Change the accounting model contract
    /// @dev Only callable by DAO. The address of the new contract must have code.
    /// @param newModel The address of the new model
    function setAccountingModel(address newModel) public {
        enforceCallerDAO();
        enforceHasContractCode(newModel, "invalid address");

        emit SetAccountingModel(address(accountingModel), newModel);

        accountingModel = IAccountingModel(newModel);
    }

    /// @notice Change the owner of the fees
    /// @dev Only callable by DAO. The new owner must not be 0 address.
    /// @param newOwner The address to which fees will be transferred
    function setFeesOwner(address newOwner) public {
        enforceCallerDAO();
        require(newOwner != address(0), "invalid address");

        emit SetFeesOwner(feesOwner, newOwner);

        feesOwner = newOwner;
    }

    /// @notice Change the percentage of the fees applied
    /// @dev Only callable by DAO. If the percentage is greater than 0, it must also have a fees owner.
    /// @param percentage The percentage of profits to be taken as fee
    function setFeesPercentage(uint256 percentage) public {
        enforceCallerDAO();
        if (percentage > 0) {
            require(feesOwner != address(0), "no fees owner");
        }
        require(percentage < MAX_FEES_PERCENTAGE, "max percentage exceeded");

        emit SetFeesPercentage(feesPercentage, percentage);

        feesPercentage = percentage;
    }

    /// @notice Helper function to enforce that the call comes from the DAO
    /// @dev Reverts the execution if msg.sender is not the DAO.
    function enforceCallerDAO() internal view {
        require(msg.sender == dao, "!dao");
    }

    /// @notice Helper function to enforce that the call comes from the Guardian
    /// @dev Reverts the execution if msg.sender is not the Guardian.
    function enforceCallerGuardian() internal view {
        require(msg.sender == guardian || msg.sender == dao, "!guardian");
    }

    /// @notice Helper function to block any action while the system is paused
    /// @dev Reverts the execution if the system is paused
    function enforceSystemNotPaused() internal view {
        require(!paused, "paused");
    }

    /// @notice Helper function to check for contract code at given address
    /// @dev Reverts if there's no code at the given address.
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A token that allows advanced privileges to its owner
/// @notice Allows the owner to mint, burn and transfer tokens without requiring explicit user approval
contract OwnableERC20 is ERC20, Ownable {
    uint8 private _dec;

    constructor(string memory name, string memory symbol, uint8 _decimals) ERC20(name, symbol) {
        _dec = _decimals;
    }


    /// @dev Returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a balance of `505` tokens should
    /// be displayed to a user as `5,05` (`505 / 10 ** 2`).
    ///
    /// Tokens usually opt for a value of 18, imitating the relationship between
    /// Ether and Wei. This is the value {ERC20} uses, unless this function is
    /// overridden;
    ///
    /// NOTE: This information is only used for _display_ purposes: it in
    /// no way affects any of the arithmetic of the contract, including
    /// {IERC20-balanceOf} and {IERC20-transfer}.
    function decimals() public view override returns (uint8) {
        return _dec;
    }

    /// @notice Allow the owner of the contract to mint an amount of tokens to the specified user
    /// @dev Only callable by owner
    /// @dev Emits a Transfer from the 0 address
    /// @param user The address of the user to mint tokens for
    /// @param amount The amount of tokens to mint
    function mint(address user, uint256 amount) public onlyOwner {
        _mint(user, amount);
    }

    /// @notice Allow the owner of the contract to burn an amount of tokens from the specified user address
    /// @dev Only callable by owner
    /// @dev The user's balance must be at least equal to the amount specified
    /// @dev Emits a Transfer to the 0 address
    /// @param user The address of the user from which to burn tokens
    /// @param amount The amount of tokens to burn
    function burn(address user, uint256 amount) public onlyOwner {
        _burn(user, amount);
    }

    /// @notice Allow the owner of the contract to transfer an amount of tokens from sender to recipient
    /// @dev Only callable by owner
    /// @dev Acts just like transferFrom but without the allowance check
    /// @param sender The address of the account from which to transfer tokens
    /// @param recipient The address of the account to which to transfer tokens
    /// @param amount The amount of tokens to transfer
    /// @return bool (always true)
    function transferAsOwner(address sender, address recipient, uint256 amount) public onlyOwner returns (bool){
        _transfer(sender, recipient, amount);

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "./interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OwnableERC20.sol";
import "./interfaces/ISeniorRateModel.sol";
import "./Governed.sol";

/// @title SMART Alpha
/// @notice This contract implements the main logic of the system.
contract SmartAlpha is Governed {
    using SafeERC20 for IERC20;

    uint256 constant public scaleFactor = 10 ** 18;

    bool public initialized;

    IERC20 public poolToken;

    OwnableERC20 public juniorToken;
    OwnableERC20 public seniorToken;

    uint256 public epoch1Start;
    uint256 public epochDuration;

    /// epoch accounting
    uint256 public epoch;
    uint256 public epochSeniorLiquidity;
    uint256 public epochJuniorLiquidity;
    uint256 public epochUpsideExposureRate;
    uint256 public epochDownsideProtectionRate;
    uint256 public epochEntryPrice;

    uint256 public queuedJuniorsUnderlyingIn;
    uint256 public queuedJuniorsUnderlyingOut;
    uint256 public queuedJuniorTokensBurn;

    uint256 public queuedSeniorsUnderlyingIn;
    uint256 public queuedSeniorsUnderlyingOut;
    uint256 public queuedSeniorTokensBurn;

    /// history management
    mapping(uint256 => uint256) public history_epochJuniorTokenPrice;
    mapping(uint256 => uint256) public history_epochSeniorTokenPrice;

    // a user can have only one queue position at a time
    // if they try a new deposit while there's a queue position redeemable, it will be automatically redeemed
    struct QueuePosition {
        uint256 epoch;
        uint256 amount;
    }

    mapping(address => QueuePosition) public juniorEntryQueue;
    mapping(address => QueuePosition) public juniorExitQueue;
    mapping(address => QueuePosition) public seniorEntryQueue;
    mapping(address => QueuePosition) public seniorExitQueue;

    constructor (address _dao, address _guardian) Governed(_dao, _guardian) {}

    /// @notice Initialize the SmartAlpha system
    /// @dev Junior and Senior tokens must be owner by this contract or the function will revert.
    /// @param poolTokenAddr Address of the pool token
    /// @param oracleAddr Address of the price oracle for the pool token
    /// @param seniorRateModelAddr Address of the senior rate model (used to calculate upside exposure and downside protection rates)
    /// @param accountingModelAddr Address of the accounting model (used to determine the junior or senior losses for an epoch)
    /// @param juniorTokenAddr Address of the junior token (ERC20)
    /// @param seniorTokenAddr Address of the senior token (ERC20)
    /// @param _epoch1Start Timestamp at which the first epoch begins
    /// @param _epochDuration Duration of the epoch in seconds
    function initialize(
        address poolTokenAddr,
        address oracleAddr,
        address seniorRateModelAddr,
        address accountingModelAddr,
        address juniorTokenAddr,
        address seniorTokenAddr,
        uint256 _epoch1Start,
        uint256 _epochDuration
    ) public {
        require(!initialized, "contract already initialized");
        initialized = true;

        enforceCallerDAO();
        setPriceOracle(oracleAddr);
        setSeniorRateModel(seniorRateModelAddr);
        setAccountingModel(accountingModelAddr);

        require(poolTokenAddr != address(0), "pool token can't be 0x0");
        require(juniorTokenAddr != address(0), "junior token can't be 0x0");
        require(seniorTokenAddr != address(0), "senior token can't be 0x0");

        poolToken = IERC20(poolTokenAddr);

        juniorToken = OwnableERC20(juniorTokenAddr);
        require(juniorToken.owner() == address(this), "junior token owner must be SA");

        seniorToken = OwnableERC20(seniorTokenAddr);
        require(seniorToken.owner() == address(this), "senior token owner must be SA");

        epoch1Start = _epoch1Start;
        epochDuration = _epochDuration;
    }

    /// @notice Advance/finalize an epoch
    /// @dev Epochs are automatically advanced/finalized if there are user interactions with the contract.
    /// @dev If there are no interactions for one or multiple epochs, they will be skipped and the materializing of
    /// @dev profits and losses will only happen as if only one epoch passed. We call this "elastic epochs".
    /// @dev This function may also be called voluntarily by any party (including bots).
    function advanceEpoch() public {
        uint256 currentEpoch = getCurrentEpoch();

        if (epoch >= currentEpoch) {
            return;
        }

        // finalize the current epoch and take the fee from the side that made profits this epoch
        uint256 seniorProfits = getCurrentSeniorProfits();
        uint256 juniorProfits = getCurrentJuniorProfits();
        if (seniorProfits > 0) {
            uint256 fee = seniorProfits * feesPercentage / scaleFactor;
            epochJuniorLiquidity = epochJuniorLiquidity - seniorProfits;
            epochSeniorLiquidity = epochSeniorLiquidity + (seniorProfits - fee);
        } else if (juniorProfits > 0) {
            uint256 fee = juniorProfits * feesPercentage / scaleFactor;
            epochSeniorLiquidity = epochSeniorLiquidity - juniorProfits;
            epochJuniorLiquidity = epochJuniorLiquidity + (juniorProfits - fee);
        }

        emit EpochEnd(epoch, juniorProfits, seniorProfits);

        // set the epoch entry price to the current price, effectively resetting profits and losses to 0
        epochEntryPrice = priceOracle.getPrice();

        uint256 juniorUnderlyingOut = _processJuniorQueues();
        uint256 seniorUnderlyingOut = _processSeniorQueues();

        // move the liquidity from the entry queue to the epoch balance & the exited liquidity from the epoch to the exit queue
        epochSeniorLiquidity = epochSeniorLiquidity - seniorUnderlyingOut + queuedSeniorsUnderlyingIn;
        queuedSeniorsUnderlyingOut += seniorUnderlyingOut;
        queuedSeniorsUnderlyingIn = 0;

        epochJuniorLiquidity = epochJuniorLiquidity - juniorUnderlyingOut + queuedJuniorsUnderlyingIn;
        queuedJuniorsUnderlyingOut += juniorUnderlyingOut;
        queuedJuniorsUnderlyingIn = 0;

        // reset the queue of tokens to burn
        queuedJuniorTokensBurn = 0;
        queuedSeniorTokensBurn = 0;

        // update the upside exposure and downside protection rates based on the new pool composition (after processing the entry and exit queues)
        (epochUpsideExposureRate, epochDownsideProtectionRate) = seniorRateModel.getRates(epochJuniorLiquidity, epochSeniorLiquidity);

        // set the stored epoch to the current epoch
        epoch = currentEpoch;
    }

    /// @notice Signal the entry into the pool as a junior
    /// @dev If the user already has a position in the queue, they can increase the amount by calling this function again
    /// @dev If a user is in the queue, they cannot exit it
    /// @param amount The amount of underlying the user wants to increase his queue position with
    function depositJunior(uint256 amount) public {
        enforceSystemNotPaused();
        advanceEpoch();

        require(amount > 0, "amount must be greater than 0");
        require(poolToken.allowance(msg.sender, address(this)) >= amount, "not enough allowance");

        QueuePosition storage pos = juniorEntryQueue[msg.sender];

        // if the user already has a position for an older epoch that was not redeemed, do it automatically
        // after this operation, pos.amount would be set to 0
        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemJuniorTokens();
        }

        // update the stored position's epoch to the current one
        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        // add the amount to the queue to be converted into junior tokens when the epoch ends
        queuedJuniorsUnderlyingIn += amount;

        uint256 newBalance = pos.amount + amount;
        pos.amount = newBalance;

        poolToken.safeTransferFrom(msg.sender, address(this), amount);

        emit JuniorJoinEntryQueue(msg.sender, epoch, amount, newBalance);
    }

    /// @notice Redeem the junior tokens generated for a user that participated in the queue at a specific epoch
    /// @dev User will receive an amount of junior tokens corresponding to his underlying balance converted at the price the epoch was finalized
    /// @dev This only works for past epochs and will revert if called for current or future epochs.
    function redeemJuniorTokens() public {
        advanceEpoch();

        QueuePosition storage pos = juniorEntryQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 underlyingAmount = pos.amount;
        require(underlyingAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochJuniorTokenPrice[pos.epoch];
        uint256 amountJuniorTokensDue = underlyingAmount * scaleFactor / price;

        juniorToken.transfer(msg.sender, amountJuniorTokensDue);

        emit JuniorRedeemTokens(msg.sender, pos.epoch, amountJuniorTokensDue);
    }

    /// @notice Signal the entry into the pool as a senior
    /// @dev If the user already has a position in the queue, they can increase the amount by calling this function again
    /// @dev If a user is in the queue, they cannot exit it
    /// @param amount The amount of underlying the user wants to increase his queue position with
    function depositSenior(uint256 amount) public {
        enforceSystemNotPaused();
        advanceEpoch();

        require(amount > 0, "amount must be greater than 0");
        require(poolToken.allowance(msg.sender, address(this)) >= amount, "not enough allowance");

        QueuePosition storage pos = seniorEntryQueue[msg.sender];

        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemSeniorTokens();
        }

        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        queuedSeniorsUnderlyingIn += amount;

        uint256 newBalance = pos.amount + amount;
        pos.amount = newBalance;

        poolToken.safeTransferFrom(msg.sender, address(this), amount);

        emit SeniorJoinEntryQueue(msg.sender, epoch, amount, newBalance);
    }

    /// @notice Redeem the senior tokens generated for a user that participated in the queue at a specific epoch
    /// @dev User will receive an amount of senior tokens corresponding to his underlying balance converted at the price the epoch was finalized
    /// @dev This only works for past epochs and will revert if called for current or future epochs.
    function redeemSeniorTokens() public {
        advanceEpoch();

        QueuePosition storage pos = seniorEntryQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 underlyingAmount = pos.amount;
        require(underlyingAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochSeniorTokenPrice[pos.epoch];
        uint256 amountSeniorTokensDue = underlyingAmount * scaleFactor / price;

        seniorToken.transfer(msg.sender, amountSeniorTokensDue);

        emit SeniorRedeemTokens(msg.sender, pos.epoch, amountSeniorTokensDue);
    }

    /// @notice Signal the intention to leave the pool as a junior
    /// @dev User will join the exit queue and his junior tokens will be transferred back to the pool.
    /// @dev Their tokens will be burned when the epoch is finalized and the underlying due will be set aside.
    /// @dev Users can increase their queue amount but can't exit the queue
    /// @param amountJuniorTokens The amount of tokens the user wants to exit with
    function exitJunior(uint256 amountJuniorTokens) public {
        advanceEpoch();

        uint256 balance = juniorToken.balanceOf(msg.sender);
        require(balance >= amountJuniorTokens, "not enough balance");

        queuedJuniorTokensBurn += amountJuniorTokens;

        QueuePosition storage pos = juniorExitQueue[msg.sender];
        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemJuniorUnderlying();
        }

        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        uint256 newBalance = pos.amount + amountJuniorTokens;
        pos.amount = newBalance;

        juniorToken.transferAsOwner(msg.sender, address(this), amountJuniorTokens);

        emit JuniorJoinExitQueue(msg.sender, epoch, amountJuniorTokens, newBalance);
    }

    /// @notice Redeem the underlying for an exited epoch
    /// @dev Only works if the user signaled the intention to exit the pool by entering the queue for that epoch.
    /// @dev Can only be called for a previous epoch and will revert for current and future epochs.
    /// @dev At this point, the junior tokens were burned by the contract and the underlying was set aside.
    function redeemJuniorUnderlying() public {
        advanceEpoch();

        QueuePosition storage pos = juniorExitQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 juniorTokenAmount = pos.amount;
        require(juniorTokenAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochJuniorTokenPrice[pos.epoch];
        uint256 underlyingDue = juniorTokenAmount * price / scaleFactor;

        queuedJuniorsUnderlyingOut -= underlyingDue;

        poolToken.safeTransfer(msg.sender, underlyingDue);

        emit JuniorRedeemUnderlying(msg.sender, pos.epoch, underlyingDue);
    }

    /// @notice Signal the intention to leave the pool as a senior
    /// @dev User will join the exit queue and his senior tokens will be transferred back to the pool.
    /// @dev Their tokens will be burned when the epoch is finalized and the underlying due will be set aside.
    /// @dev Users can increase their queue amount but can't exit the queue
    /// @param amountSeniorTokens The amount of tokens the user wants to exit with
    function exitSenior(uint256 amountSeniorTokens) public {
        advanceEpoch();

        uint256 balance = seniorToken.balanceOf(msg.sender);
        require(balance >= amountSeniorTokens, "not enough balance");

        queuedSeniorTokensBurn += amountSeniorTokens;

        QueuePosition storage pos = seniorExitQueue[msg.sender];
        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemSeniorUnderlying();
        }

        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        uint256 newBalance = pos.amount + amountSeniorTokens;
        pos.amount = newBalance;

        seniorToken.transferAsOwner(msg.sender, address(this), amountSeniorTokens);

        emit SeniorJoinExitQueue(msg.sender, epoch, amountSeniorTokens, newBalance);
    }

    /// @notice Redeem the underlying for an exited epoch
    /// @dev Only works if the user signaled the intention to exit the pool by entering the queue for that epoch.
    /// @dev Can only be called for a previous epoch and will revert for current and future epochs.
    /// @dev At this point, the senior tokens were burned by the contract and the underlying was set aside.
    function redeemSeniorUnderlying() public {
        advanceEpoch();

        QueuePosition storage pos = seniorExitQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 seniorTokenAmount = pos.amount;
        require(seniorTokenAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochSeniorTokenPrice[pos.epoch];
        uint256 underlyingDue = seniorTokenAmount * price / scaleFactor;

        queuedSeniorsUnderlyingOut -= underlyingDue;

        poolToken.safeTransfer(msg.sender, underlyingDue);

        emit SeniorRedeemUnderlying(msg.sender, pos.epoch, underlyingDue);
    }

    /// @notice Transfer the accrued fees to the fees owner
    /// @dev Anyone can call but fees are transferred to fees owner. Reverts if no fees accrued.
    function transferFees() public {
        uint256 amount = feesAccrued();
        require(amount > 0, "no fees");
        require(feesOwner != address(0), "no fees owner");

        // assumption: if there are fees accrued, it means there was an owner at some point
        // since the percentage cannot be set without an owner and the owner can't be set to address(0) later
        poolToken.safeTransfer(feesOwner, amount);

        emit FeesTransfer(msg.sender, feesOwner, amount);
    }

    /// @notice Calculates the current epoch based on the start of the first epoch and the epoch duration
    /// @return The id of the current epoch
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return (block.timestamp - epoch1Start) / epochDuration + 1;
    }

    /// @notice Calculates the junior profits based on current pool conditions
    /// @dev It always returns 0 if the price went down.
    /// @return The amount, in pool tokens, that is considered profit for the juniors
    function getCurrentJuniorProfits() public view returns (uint256) {
        uint256 currentPrice = priceOracle.getPrice();

        return accountingModel.calcJuniorProfits(
            epochEntryPrice,
            currentPrice,
            epochUpsideExposureRate,
            epochSeniorLiquidity,
            epochBalance()
        );
    }

    /// @notice Calculates the junior losses (in other words, senior profits) based on the current pool conditions
    /// @dev It always returns 0 if the price went up.
    /// @return The amount, in pool tokens, that is considered loss for the juniors
    function getCurrentSeniorProfits() public view returns (uint256) {
        uint256 currentPrice = priceOracle.getPrice();

        return accountingModel.calcSeniorProfits(
            epochEntryPrice,
            currentPrice,
            epochDownsideProtectionRate,
            epochSeniorLiquidity,
            epochBalance()
        );
    }

    /// @notice Calculate the epoch balance
    /// @return epoch balance
    function epochBalance() public view returns (uint256) {
        return epochJuniorLiquidity + epochSeniorLiquidity;
    }

    /// @notice Return the total amount of underlying in the queues
    /// @return amount of underlying in the queues
    function underlyingInQueues() public view returns (uint256) {
        return queuedJuniorsUnderlyingIn + queuedSeniorsUnderlyingIn + queuedJuniorsUnderlyingOut + queuedSeniorsUnderlyingOut;
    }

    /// @notice Calculate the total fees accrued
    /// @dev We consider fees any amount of underlying that is not accounted for in the epoch balance & queues
    function feesAccrued() public view returns (uint256) {
        return poolToken.balanceOf(address(this)) - epochBalance() - underlyingInQueues();
    }

    /// @notice Return the price of the junior token for the current epoch
    /// @dev If there's no supply, it returns 1 (scaled by scaleFactor).
    /// @dev It does not take into account the current profits and losses.
    /// @return The price of a junior token in pool tokens
    function getEpochJuniorTokenPrice() public view returns (uint256) {
        uint256 supply = juniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return epochJuniorLiquidity * scaleFactor / supply;
    }

    /// @notice Return the price of the senior token for the current epoch
    /// @dev If there's no supply, it returns 1 (scaled by scaleFactor).
    /// @dev It does not take into account the current profits and losses.
    /// @return The price of a senior token in pool tokens
    function getEpochSeniorTokenPrice() public view returns (uint256) {
        uint256 supply = seniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return epochSeniorLiquidity * scaleFactor / supply;
    }

    /// @notice Return the senior liquidity taking into account the current, unrealized, profits and losses
    /// @return The estimated senior liquidity
    function estimateCurrentSeniorLiquidity() public view returns (uint256) {
        uint256 seniorProfits = getCurrentSeniorProfits();
        if (seniorProfits > 0) {
            uint256 fee = seniorProfits * feesPercentage / scaleFactor;
            seniorProfits -= fee;
        }

        uint256 juniorProfits = getCurrentJuniorProfits();

        return epochSeniorLiquidity + seniorProfits - juniorProfits;
    }

    /// @notice Return the junior liquidity taking into account the current, unrealized, profits and losses
    /// @return The estimated junior liquidity
    function estimateCurrentJuniorLiquidity() public view returns (uint256) {
        uint256 seniorProfits = getCurrentSeniorProfits();

        uint256 juniorProfits = getCurrentJuniorProfits();
        if (juniorProfits > 0) {
            uint256 fee = juniorProfits * feesPercentage / scaleFactor;
            juniorProfits -= fee;
        }

        return epochJuniorLiquidity - seniorProfits + juniorProfits;
    }

    /// @notice Return the current senior token price taking into account the current, unrealized, profits and losses
    /// @return The estimated senior token price
    function estimateCurrentSeniorTokenPrice() public view returns (uint256) {
        uint256 supply = seniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return estimateCurrentSeniorLiquidity() * scaleFactor / supply;
    }

    /// @notice Return the current junior token price taking into account the current, unrealized, profits and losses
    /// @return The estimated junior token price
    function estimateCurrentJuniorTokenPrice() public view returns (uint256) {
        uint256 supply = juniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return estimateCurrentJuniorLiquidity() * scaleFactor / supply;
    }

    /// @notice Process the junior entry and exit queues
    /// @dev It saves the junior token price valid for the stored epoch to storage for further reference.
    /// @dev It optimizes gas usage by re-using some of the tokens it already has minted which leads to only one of the {mint, burn} actions to be executed.
    /// @dev All queued positions will be converted into junior tokens or underlying at the same price.
    /// @return The amount of underlying (pool tokens) that should be set aside
    function _processJuniorQueues() internal returns (uint256){
        uint256 juniorTokenPrice = getEpochJuniorTokenPrice();
        history_epochJuniorTokenPrice[epoch] = juniorTokenPrice;

        uint256 juniorTokensToMint = queuedJuniorsUnderlyingIn * scaleFactor / juniorTokenPrice;
        uint256 juniorTokensToBurn = queuedJuniorTokensBurn;

        uint256 juniorUnderlyingOut = juniorTokensToBurn * juniorTokenPrice / scaleFactor;

        if (juniorTokensToMint > juniorTokensToBurn) {
            uint256 diff = juniorTokensToMint - juniorTokensToBurn;
            juniorToken.mint(address(this), diff);
        } else if (juniorTokensToBurn > juniorTokensToMint) {
            uint256 diff = juniorTokensToBurn - juniorTokensToMint;
            juniorToken.burn(address(this), diff);
        } else {
            // nothing to mint or burn
        }

        return juniorUnderlyingOut;
    }

    /// @notice Process the senior entry and exit queues
    /// @dev It saves the senior token price valid for the stored epoch to storage for further reference.
    /// @dev It optimizes gas usage by re-using some of the tokens it already has minted which leads to only one of the {mint, burn} actions to be executed.
    /// @dev All queued positions will be converted into senior tokens or underlying at the same price.
    /// @return The amount of underlying (pool tokens) that should be set aside
    function _processSeniorQueues() internal returns (uint256) {
        uint256 seniorTokenPrice = getEpochSeniorTokenPrice();
        history_epochSeniorTokenPrice[epoch] = seniorTokenPrice;

        uint256 seniorTokensToMint = queuedSeniorsUnderlyingIn * scaleFactor / seniorTokenPrice;
        uint256 seniorTokensToBurn = queuedSeniorTokensBurn;

        uint256 seniorUnderlyingOut = seniorTokensToBurn * seniorTokenPrice / scaleFactor;

        if (seniorTokensToMint > seniorTokensToBurn) {
            uint256 diff = seniorTokensToMint - seniorTokensToBurn;
            seniorToken.mint(address(this), diff);
        } else if (seniorTokensToBurn > seniorTokensToMint) {
            uint256 diff = seniorTokensToBurn - seniorTokensToMint;
            seniorToken.burn(address(this), diff);
        } else {
            // nothing to mint or burn
        }

        return seniorUnderlyingOut;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

abstract contract SmartAlphaEvents {
    /// @notice Logs a deposit of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param underlyingIn The amount of underlying deposited
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event JuniorJoinEntryQueue(address indexed user, uint256 epochId, uint256 underlyingIn, uint256 currentQueueBalance);

    /// @notice Logs a redeem (2nd step of deposit) of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param tokensOut The amount of junior tokens redeemed
    event JuniorRedeemTokens(address indexed user, uint256 epochId, uint256 tokensOut);

    /// @notice Logs an exit (1st step) of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param tokensIn The amount of junior tokens deposited into the queue
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event JuniorJoinExitQueue(address indexed user, uint256 epochId, uint256 tokensIn, uint256 currentQueueBalance);

    /// @notice Logs an exit (2nd step) of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param underlyingOut The amount of underlying transferred to the user
    event JuniorRedeemUnderlying(address indexed user, uint256 epochId, uint256 underlyingOut);

    /// @notice Logs a deposit of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param underlyingIn The amount of underlying deposited
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event SeniorJoinEntryQueue(address indexed user, uint256 epochId, uint256 underlyingIn, uint256 currentQueueBalance);

    /// @notice Logs a redeem (2nd step of deposit) of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param tokensOut The amount of senior tokens redeemed
    event SeniorRedeemTokens(address indexed user, uint256 epochId, uint256 tokensOut);

    /// @notice Logs an exit (1st step) of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param tokensIn The amount of senior tokens deposited into the queue
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event SeniorJoinExitQueue(address indexed user, uint256 epochId, uint256 tokensIn, uint256 currentQueueBalance);

    /// @notice Logs an exit (2nd step) of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param underlyingOut The amount of underlying transferred to the user
    event SeniorRedeemUnderlying(address indexed user, uint256 epochId, uint256 underlyingOut);

    /// @notice Logs an epoch end
    /// @param epochId The id of the epoch that just ended
    /// @param juniorProfits The amount of junior profits for the epoch that ended in underlying tokens
    /// @param seniorProfits The amount of senior profits for the epoch that ended in underlying tokens
    event EpochEnd(uint256 epochId, uint256 juniorProfits, uint256 seniorProfits);

    /// @notice Logs a transfer of fees
    /// @param caller The caller of the function
    /// @param destination The destination address of the funds
    /// @param amount The amount of tokens that were transferred
    event FeesTransfer(address caller, address destination, uint256 amount);

    /// @notice Logs a transfer of dao power to a new address
    /// @param oldDAO The address of the old DAO
    /// @param newDAO The address of the new DAO
    event TransferDAO(address oldDAO, address newDAO);

    /// @notice Logs a transfer of Guardian power to a new address
    /// @param oldGuardian The address of the old guardian
    /// @param newGuardian The address of the new guardian
    event TransferGuardian(address oldGuardian, address newGuardian);

    /// @notice Logs a system pause
    event PauseSystem();

    /// @notice logs a system resume
    event ResumeSystem();

    /// @notice logs a change of price oracle
    /// @param oldOracle Address of the old oracle
    /// @param newOracle Address of the new oracle
    event SetPriceOracle(address oldOracle, address newOracle);

    /// @notice Logs a change of senior rate model contract
    /// @param oldModel Address of the old model
    /// @param newModel Address of the new model
    event SetSeniorRateModel(address oldModel, address newModel);

    /// @notice Logs a change of accounting model contract
    /// @param oldModel Address of the old model
    /// @param newModel Address of the new model
    event SetAccountingModel(address oldModel, address newModel);

    /// @notice Logs a change of fees owner
    /// @param oldOwner Address of the old owner of fees
    /// @param newOwner Address of the new owner of fees
    event SetFeesOwner(address oldOwner, address newOwner);

    /// @notice Logs a change of fees percentage
    /// @param oldPercentage The old percentage of fees
    /// @param newPercentage The new percentage of fees
    event SetFeesPercentage(uint256 oldPercentage, uint256 newPercentage);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IAccountingModel {
    function calcJuniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 upsideExposureRate,
        uint256 totalSeniors,
        uint256 totalBalance
    ) external pure returns (uint256);

    function calcSeniorProfits(
        uint256 entryPrice,
        uint256 currentPrice,
        uint256 downsideProtectionRate,
        uint256 totalSeniors,
        uint256 totalBalance
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface ISeniorRateModel {
    function getRates(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256, uint256);
    function getUpsideExposureRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256);
    function getDownsideProtectionRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256);
}

