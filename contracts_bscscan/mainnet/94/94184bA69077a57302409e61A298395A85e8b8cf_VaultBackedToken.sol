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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity 0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../interfaces/IUniswapV2Router02.sol";
import "./YearnVaultLiqGen.sol";

contract VaultBackedToken is ERC20("CakeStake Test", "CSTKT"), Ownable {
    IUniswapV2Router02 public router = IUniswapV2Router02(0x3309f91A094626A98c2CC580A8c232081CF246b7);

    IERC20 iWETH = IERC20(router.WETH());
    IERC20 cake = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);

    YearnVaultLiqGen public stakedCake = new YearnVaultLiqGen(0xc9728D1168B6289Db613Eff30e7b217F26976C09);

    bool public swapAndLiquifyEnabled;
    bool inSwapAndLiquify;

    bool public checkPairTx = true;
    bool public paused = true;

    uint256 public mintableBalance;
    uint256 public minMint;

    uint256 DIVISOR = 10_000;
    uint256 public transferBudget = 100; // 1%

    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2Pair public scakePair;

    mapping(address => bool) public allowList;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        //approve cakr to stake in scake
        cake.approve(address(stakedCake), type(uint256).max);

        //Approve all assets used to router
        cake.approve(address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);
        iWETH.approve(address(router), type(uint256).max);
        stakedCake.approve(address(router), type(uint256).max);

        //Create coin-BNB and coin-scake pairs
        uniswapV2Pair = IUniswapV2Pair(IUniswapV2Factory(router.factory()).createPair(address(this), address(iWETH)));
        scakePair = IUniswapV2Pair(IUniswapV2Factory(router.factory()).createPair(address(this), address(stakedCake)));

        stakedCake.setPair(address(scakePair));
        stakedCake.transferOwnership(msg.sender);

        //Set initial whitelisted addrs as deployer and minting address
        allowList[msg.sender] = true;
        allowList[address(0)] = true;

        //Mint initial supply
        _mint(msg.sender, 80_000 ether);
        minMint = 1 ether;
    }

    function getTokenOutPath(address _token_in, address _token_out) internal view returns (address[] memory _path) {
        bool is_weth = _token_in == address(address(iWETH)) || _token_out == address(address(iWETH));
        _path = new address[](is_weth ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth) {
            _path[1] = _token_out;
        } else {
            _path[1] = address(address(iWETH));
            _path[2] = _token_out;
        }
    }

    function getQuarter(uint256 num) internal view returns (uint256) {
        return (num * 25) / 100;
    }

    function updateTransferBudget(uint256 _newbudget) external onlyOwner {
        transferBudget = _newbudget;
    }

    function updateMinMint(uint256 _newMinMint) external onlyOwner {
        minMint = _newMinMint;
    }

    function manualLiquify(uint256 liquifyAmount) external onlyOwner {
        runLiquifyActions(liquifyAmount);
    }

    function toggleLiquify() external onlyOwner {
        swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
        mintableBalance = 0;
    }

    function toggleCheckPairTx() external onlyOwner {
        checkPairTx = !checkPairTx;
    }

    function addToAllow(address _from) external onlyOwner {
        allowList[_from] = true;
    }

    function unlock() external {
        require(allowList[msg.sender], "INV_CALL_UNLOCK");
        paused = false;
    }

    function overMinTokenBalance() public view returns (bool) {
        return mintableBalance > minMint;
    }

    function _checkMintable(address _from, address _to) internal view returns (bool) {
        return
            checkPairTx
                ? (_from == address(uniswapV2Pair) || _to == address(uniswapV2Pair)) ||
                    (_from == address(scakePair) || _to == address(scakePair))
                : (_from != address(0) && _to != address(0));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!paused || allowList[from], "Not allowed");
        if (!paused && from != address(0) && _checkMintable(from, to) && swapAndLiquifyEnabled) {
            mintableBalance += (amount * transferBudget) / DIVISOR;
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (
            from != address(0) &&
            overMinTokenBalance() &&
            !inSwapAndLiquify &&
            from != address(uniswapV2Pair) &&
            swapAndLiquifyEnabled &&
            to != address(0) &&
            !paused
        ) {
            runLiquifyActions(mintableBalance);
            mintableBalance = 0;
        }
    }

    function refundExcess() internal {
        iWETH.transfer(owner(), iWETH.balanceOf(address(this)));
        stakedCake.transfer(owner(), stakedCake.balanceOf(address(this)));
        cake.transfer(owner(), cake.balanceOf(address(this)));
        _transfer(address(this), owner(), balanceOf(address(this)));
    }

    function runLiquifyActions(uint256 swapAmount) internal lockTheSwap {
        _mint(address(this), swapAmount);
        //Override and set it to proper budget from mint
        swapAmount = getQuarter(swapAmount);
        //First swap tokens to cake
        router.swapExactTokensForTokens(swapAmount, 0, getTokenOutPath(address(this), address(cake)), address(this), block.timestamp, true);
        //stake to yscake
        uint256 cakeReturned = cake.balanceOf(address(this));
        stakedCake.depositAndMint(cakeReturned);
        //add liq to yscake-token pair
        router.addLiquidity(address(this), address(stakedCake), swapAmount, cakeReturned, 0, 0, address(this), block.timestamp);
        //Then swap remaining half to bnb
        uint256[] memory returnAmounts = router.swapExactTokensForTokens(
            swapAmount,
            0,
            getTokenOutPath(address(this), address(address(iWETH))),
            address(this),
            block.timestamp,
            true
        );
        //Add liq for token-wbnb
        router.addLiquidity(
            address(this),
            address(iWETH),
            balanceOf(address(this)),
            returnAmounts[returnAmounts.length - 1],
            0,
            0,
            address(this),
            block.timestamp
        );
        refundExcess();
    }

    function LiquifyProfits() external lockTheSwap {
        if (stakedCake.getProfitForUser(address(stakedCake.StakeCpair())) > 0) {
            stakedCake.withdrawProfitsOnPair();
            uint256 halfCake = cake.balanceOf(address(this)) / 2;
            //Swap half of the cake for bnb
            uint256[] memory returnAmounts = router.swapExactTokensForTokens(
                halfCake,
                0,
                getTokenOutPath(address(cake), address(address(iWETH))),
                address(this),
                block.timestamp,
                false
            );
            //swap the rest half for self
            uint256[] memory returnAmounts2 = router.swapExactTokensForTokens(
                halfCake,
                0,
                getTokenOutPath(address(cake), address(this)),
                address(this),
                block.timestamp,
                true
            );
            //Add liq to bnb-token pair
            router.addLiquidity(
                address(this),
                address(iWETH),
                returnAmounts2[returnAmounts2.length - 1],
                returnAmounts[returnAmounts.length - 1],
                0,
                0,
                address(this),
                block.timestamp
            );
            refundExcess();
        }
    }

    function recoverToken(address token) external onlyOwner {
        IERC20 iToken = IERC20(token);
        iToken.transfer(msg.sender, iToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
    This contract allows users to do the following
    Deposit base token which mints yvault tokens,which then mints sXYZ (XYZ being the ticker of the token being staked)
    Anytime user wants to retrive the underlying tokens they can  call withdraw or withdrawAll to get back their capital + some profits
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IVault.sol";
import "../interfaces/IBaseToken.sol";

contract YearnVaultLiqGen is Ownable, ERC20("StakedCAKE", "SCAKE") {
    using SafeERC20 for IERC20;

    IBaseToken internal curC;
    address public StakeCpair;

    IERC20 internal want;
    IVault public vault;

    uint256 internal DIVISOR;
    uint256 public profits;

    //How much shares a user has deposited,to check against redeemable
    mapping(address => uint256) public shares;
    mapping(address => uint256) public underlyingDeposit;

    //Internal counter to combat against manipulation of redemptions
    uint256 public vaultBalanceReserve = 0;

    constructor(address _vault) {
        curC = IBaseToken(msg.sender);
        vault = IVault(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, type(uint256).max);
        DIVISOR = 10**vault.decimals();
    }

    /**
     * @notice Get how many vault shares should be used to redeem a set amount of underlying token amount
     * @param _amount The amount of tokens to withdraw
     * @return The amount of vault shares to withdraw
     */
    function sharesForAmount(uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        return (_amount / vault.pricePerShare()) / DIVISOR;
    }

    /**
     * @notice Get how many underlying tokens a share can redeem
     * @param _shares The amount of shares being withdrawn or quoted
     * @return The amount of tokens retriveable on withdraw of specified shares
     */
    function tokensForShares(uint256 _shares) internal view returns (uint256) {
        if (_shares == 0) return _shares;
        return (_shares * vault.pricePerShare()) / DIVISOR;
    }

    /**
     * @notice Get the profits of a user
     * @param user The user of whom the profit is checked
     * @return The amount of pending profit in underlying for user
     */
    function getProfitForUser(address user) public view returns (uint256) {
        uint256 _shares = shares[user];
        if (_shares <= 0) return 0;
        uint256 origDepositAmount = underlyingDeposit[user];
        uint256 currentBaseAmount = tokensForShares(_shares);
        return currentBaseAmount > origDepositAmount ? currentBaseAmount - origDepositAmount : 0;
    }

    /**
     * @notice Get amount of tokens deposited in vault wrapper
     * @return The amount of tokens deposited in vault
     */
    function getBaseDeposited() external view returns (uint256) {
        return tokensForShares(vaultBalanceReserve);
    }

    /**
     * @notice Get the amount of shares to withdraw based on wrapper token burn amount
     * @param tokensBurned The amount of wrapper tokens  burnt
     * @param supplyBefore The token supply of wrapper contract before the burn
     * @return The amount of shares to withdraw
     */
    function getSharesForWithdraw(uint256 tokensBurned, uint256 supplyBefore) internal view returns (uint256) {
        return (((tokensBurned * DIVISOR) / supplyBefore) * vaultBalanceReserve) / DIVISOR;
    }

    /**
     * @notice Get the amount of shares to transfer to the destination address
     * @param user The origin of the transfer
     * @param transferAmount The token amount being transfed
     * @return The amount of shares to transfer to destination address
     */
    function getAccSharesToTransfer(address user, uint256 transferAmount) internal view returns (uint256) {
        return (((transferAmount * DIVISOR) / balanceOf(user)) * shares[user]) / DIVISOR;
    }

    /**
     * @notice Get the amount of underlying balance to transfer
     * @param user The origin of the transfer
     * @param transferAmount The token amount being transfed
     * @return The amount of underlying balance to transfer to destination address
     */
    function getAccUnderlyingToTransfer(address user, uint256 transferAmount) internal view returns (uint256) {
        return (((transferAmount * DIVISOR) / balanceOf(user)) * underlyingDeposit[user]) / DIVISOR;
    }

    /**
     * @notice Deposits underlying asset to vault and mints vault wrapper tokens
     * @param underlyingAmount The amount of underlying asset being deposited
     */
    function depositAndMint(uint256 underlyingAmount) external {
        want.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        _deposit(underlyingAmount);
        _mint(msg.sender, underlyingAmount);
    }

    /**
     * @notice Withdraws the underlying tokens based on number of wrapper tokens burned
     * @param _tokens The amount of wrapper tokens to burn
     */
    function withdrawAndBurn(uint256 _tokens) external {
        _withdraw(msg.sender, _tokens);
    }

    /**
     * @notice Withdraws all available underlying balance for caller
     */
    function withdrawAllAndBurn() external {
        _withdraw(msg.sender, balanceOf(msg.sender));
    }

    /**
     * @notice Withdraws unrealized profits for caller
     */
    function withdrawProfits() public {
        _redeemProfit(msg.sender, getProfitForUser(msg.sender));
    }

    /**
     * @notice Withdraws unrealized profits for scake-coin pair to coin contract
     */
    function withdrawProfitsOnPair() public {
        _redeemProfit(address(curC), getProfitForUser(StakeCpair));
    }

    /**
     * @notice Changes the basepair incase the base pair changes
     */
    function setPair(address _basePair) external onlyOwner {
        StakeCpair = _basePair;
    }

    //WIP,this breaks share and profit checks
    function migrateVault(address newVault) external onlyOwner {
        vault.withdraw();

        want.safeApprove(newVault, type(uint256).max);
        vault = IVault(newVault);

        vault.deposit();
    }

    /**
     * @notice Sends any extra vault tokens to owner
     */
    function skim() public {
        uint256 vaultbal = vault.balanceOf(address(this));
        uint256 diff = vaultbal - vaultBalanceReserve;
        if (diff > 0) vault.transfer(owner(), diff);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        //Call liquifyprofits before transfer from the scake liq pair
        if (from == StakeCpair) {
            curC.LiquifyProfits();
        }
        if (amount > 0 && balanceOf(from) > 0 && from != address(0) && to != address(0)) {
            uint256 sharesToChange = getAccSharesToTransfer(from, amount);
            uint256 underlyingToChange = getAccUnderlyingToTransfer(from, amount);
            shares[to] += sharesToChange;
            shares[from] -= sharesToChange;
            underlyingDeposit[to] += underlyingToChange;
            underlyingDeposit[from] -= underlyingToChange;
        }
    }

    function _beforeVaultAction() internal {
        skim();
    }

    function _deposit(uint256 depositAmount) internal {
        _beforeVaultAction();
        underlyingDeposit[msg.sender] += depositAmount;
        uint256 newShares = vault.deposit(depositAmount);
        shares[msg.sender] += newShares;
        vaultBalanceReserve += newShares;
    }

    function _withdraw(address user, uint256 tokensToBurn) internal {
        _beforeVaultAction();
        uint256 totalSupplyBeforeBurn = totalSupply();
        _burn(user, tokensToBurn);

        if (getProfitForUser(user) > 0) withdrawProfits();
        uint256 userShares = shares[user];
        uint256 calcShares = getSharesForWithdraw(tokensToBurn, totalSupplyBeforeBurn);
        uint256 sharesToWithdraw = balanceOf(user) == 0 ? userShares : calcShares;
        _redeemShares(user, sharesToWithdraw);
    }

    function _redeemProfit(address user, uint256 profit) internal {
        _beforeVaultAction();
        if (profit > 0) {
            uint256 _shares = sharesForAmount(profit);
            if (_shares <= 0) {
                uint256 sharesStart = vaultBalanceReserve;
                //Workaround by withdrawing full amount and depositing the excess back in
                vault.withdraw();
                want.transfer(user, profit);
                vault.deposit();
                _shares = sharesStart - vault.balanceOf(address(this));
            } else {
                vault.withdraw(_shares, user);
            }
            shares[user] -= _shares;
            vaultBalanceReserve -= _shares;
            underlyingDeposit[user] = tokensForShares(shares[user]);
            profits += profit;
        }
    }

    function _redeemShares(address user, uint256 sharesToUse) internal {
        _beforeVaultAction();
        uint256 underlyingBalance = tokensForShares(sharesToUse);
        if (underlyingDeposit[user] < underlyingBalance) {
            uint256 diff = underlyingBalance - underlyingDeposit[user];
            underlyingDeposit[user] += diff;
        }
        require(sharesToUse > 0, "No shares being withdrawn");
        require(sharesToUse <= vaultBalanceReserve, "Excess shares");
        shares[user] -= sharesToUse;
        underlyingDeposit[user] -= underlyingBalance;
        vaultBalanceReserve -= sharesToUse;
        vault.withdraw(sharesToUse, user);
    }

    function recoverToken(address token) external onlyOwner {
        IERC20 iToken = IERC20(token);
        iToken.transfer(msg.sender, iToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBaseToken {
    function LiquifyProfits() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool sendFromRouter
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVault {
    function transfer(address receiver, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 amount) external returns (bool);

    function decreaseAllowance(address spender, uint256 amount) external returns (bool);

    function totalAssets() external view returns (uint256);

    function deposit() external returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function deposit(uint256 _amount, address recipient) external returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function withdrawalQueue(uint256) external view returns (address);

    function pricePerShare() external view returns (uint256);

    function sweep(address token) external;

    function sweep(address token, uint256 amount) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address arg0) external view returns (uint256);

    function allowance(address arg0, address arg1) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function token() external view returns (address);

    function depositLimit() external view returns (uint256);

    function debtRatio() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

