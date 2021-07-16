/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

/**
 * @dev String operations.
 */
library Strings {
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

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}



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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

interface IController {
    function getClusterAmountFromEth(uint256 _ethAmount, address _cluster) external view returns (uint256);

    function addClusterToRegister(address indexAddr) external;

    function getDHVPrice(address _cluster) external view returns (uint256);

    function getUnderlyingsInfo(address _cluster, uint256 _ethAmount)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256
        );

    function getUnderlyingsAmountsFromClusterAmount(uint256 _clusterAmount, address _clusterAddress) external view returns (uint256[] memory);

    function getEthAmountFromUnderlyingsAmounts(uint256[] memory _underlyingsAmounts, address _cluster) external view returns (uint256);

    function adapters(address _cluster) external view returns (address);

    function dhvTokenInstance() external view returns (address);

    function getDepositComission(address _cluster, uint256 _ethValue) external view returns (uint256);

    function getRedeemComission(address _cluster, uint256 _ethValue) external view returns (uint256);

    function getClusterPrice(address _cluster) external view returns (uint256);
}

interface IDexAdapter {
    function swapETHToUnderlying(address underlying) external payable;

    function swapUndelyingsToETH(uint256[] memory underlyingAmounts, address[] memory underlyings) external;

    function swapTokenToToken(
        uint256 _amountToSwap,
        address _tokenToSwap,
        address _tokenToReceive
    ) external returns (uint256);

    function getUnderlyingAmount(
        uint256 _amount,
        address _tokenToSwap,
        address _tokenToReceive
    ) external view returns (uint256);

    function getPath(address _tokenToSwap, address _tokenToReceive) external view returns (address[] memory);

    function getTokensPrices(address[] memory _tokens) external view returns (uint256[] memory);

    function getEthPrice() external view returns (uint256);

    function getDHVPrice(address _dhvToken) external view returns (uint256);
}


interface IClusterToken {
    function assemble(bool coverDhvWithEth) external payable returns (uint256);

    function disassemble(uint256 indexAmount, bool coverDhvWithEth) external payable;

    function withdrawToAccumulation(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _clusterAmount
    ) external;

    function refundFromAccumulation(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _clusterAmount
    ) external;

    function optimizeProportion(uint256[] memory updatedShares) external returns (uint256[] memory debt);

    function getUnderlyingShares() external view returns (uint256[] calldata);

    function getUnderlyings() external view returns (address[] calldata);

    function getUnderlyingBalance(address _underlying) external view returns (uint256);

    function getUnderlyingsAmountsFromClusterAmount(uint256 _clusterAmount) external view returns (uint256[] calldata);

    function clusterTokenLock() external view returns (uint256);

    function clusterLock(address _token) external view returns (uint256);

    function controllerChange(address) external;
}


interface IERC20Extend {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amound of token's decimals.
     */

    function decimals() external view returns (uint8);

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


/// @title Cluster Token Contract
/// @author Anna Korunska, Pavlo Horbonos, Philipp Taratuta, Svyatoslav Delukin
/// @notice Cluster Token is a ERC-20 token representing a DeHive cluster of DeFi assets
contract ClusterToken is ERC20Pausable, AccessControl, IClusterToken {
    using SafeERC20 for IERC20;

    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Address of Controller smart contract.
    address public clusterControllerAddress;
    /// @notice Address of treasury.
    address internal treasuryAddress;
    /// @notice Instance of the DHV token instance
    IERC20 public dhvTokenInstance;
    /// @notice Hash id, serves as an additional identifier of the cluster.
    uint256 public clusterHashId;

    /// @notice lock period, during which user can't redeem or transfer cluster after assemble
    uint256 public cooldownPeriod;
    /// @notice List of tokens that cluster holds, called underlyings.
    /// @dev Order of addresses is important, as it corresponds with the order in underlyingsShares.
    address[] public underlyings;
    /// @notice List of shares, multiplied by 10 ** 6
    /// @dev Order of addresses is important, as it corresponds with the order of tokens in underlyings.
    uint256[] public underlyingsShares;

    /// @notice Amount of cluster token locked
    uint256 public override clusterTokenLock;

    /// @notice timestamp, before which user can't redeem or transfer cluster.
    /// @dev userAddress => uint.
    mapping(address => uint256) public cooldownTimestamps;

    mapping(address => uint256) public override clusterLock;

    /// @notice Event emitted on each successful deposit for cluster in ETH.
    /// @param clusterAddress Address of cluster deposited upon.
    /// @param buyer Address of user depositing (user who bought token).
    /// @param ethDeposited Amount of ETH deposited in exchange of cluster.
    /// @param clusterAmountBought Amount of cluster bought for given amount of ETH.
    event ClusterAssembledInETH(address clusterAddress, address buyer, uint256 ethDeposited, uint256 clusterAmountBought);
    /// @notice Event emitted on each successful cluster redeeming for ETH.
    /// @param clusterAddress Address of cluster redeemed.
    /// @param redeemer Address of user performing the redeem.
    /// @param clusterAmountRedeemed Amount of cluster redeemed by user.
    event ClusterDisassembledInETH(address clusterAddress, address redeemer, uint256 clusterAmountRedeemed);

    /// @notice Event emitted on each successful deposit for cluster in ETH.
    /// @param clusterAddress Address of cluster deposited upon.
    /// @param buyer Address of user depositing (user who bought token).
    /// @param clusterAmountBought Amount of cluster bought for given amount of ETH.
    event ClusterAssembled(address clusterAddress, address buyer, uint256 clusterAmountBought);
    /// @notice Event emitted on each successful cluster redeeming for ETH.
    /// @param clusterAddress Address of cluster redeemed.
    /// @param redeemer Address of user performing the redeem.
    /// @param clusterAmountRedeemed Amount of cluster redeemed by user.
    event ClusterDisassembled(address clusterAddress, address redeemer, uint256 clusterAmountRedeemed);

    /// @notice Checks that lock period on redeeming or transfering cluster is over.
    modifier checkCooldownPeriod() {
        require(cooldownTimestamps[_msgSender()] <= block.timestamp, "Cooldown in progress");
        _;
    }

    /// @notice Checks admin role.
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Unauthorized");
        _;
    }

    /// @notice Checks farmer role.
    modifier onlyFarmer() {
        require(hasRole(FARMER_ROLE, _msgSender()), "Unauthorized");
        _;
    }

    /// @notice Checks delegate role.
    modifier onlyDelegate() {
        require(hasRole(DELEGATE_ROLE, _msgSender()), "Unauthorized");
        _;
    }

    /// @notice Checks minter role.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Unauthorized");
        _;
    }

    /// @notice Performs initial setup.
    /// @param _clusterControllerAddress Address of the Controller SC.
    /// @param _underlyings List of tokens to be recorded in underlyings.
    /// @param _underlyingsShares List of shares to be recorded in underlyingsShares.
    /// @param _name Name of the ERC-20 token.
    /// @param _symbol Symbol of the ERC-20 token.
    /// @param _hashId cluster hash identifier.
    constructor(
        address _clusterControllerAddress,
        address _treasury,
        address[] memory _underlyings,
        uint256[] memory _underlyingsShares,
        string memory _name,
        string memory _symbol,
        uint256 _hashId
    ) ERC20(_name, _symbol) {
        require(_clusterControllerAddress != address(0), "dev: Controller zero address");
        require(_treasury != address(0), "dev: Treasury zero address");
        require(_underlyings.length == _underlyingsShares.length, "dev: Arrays' lengths must be equal");
        for (uint256 i = 0; i < _underlyings.length; i++) {
            require(_underlyings[i] != address(0), "dev: Underlying zero address");
            require(_underlyingsShares[i] > 0, "dev: Share equals zero");
        }
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FARMER_ROLE, _msgSender());
        _setupRole(DELEGATE_ROLE, _msgSender());

        underlyings = _underlyings;
        underlyingsShares = _underlyingsShares;
        clusterHashId = _hashId;
        clusterControllerAddress = _clusterControllerAddress;
        treasuryAddress = _treasury;

        dhvTokenInstance = IERC20(IController(_clusterControllerAddress).dhvTokenInstance());
    }

    receive() external payable {}

    /**********
     * ADMIN INTERFACE
     **********/

    /// @notice Function that allows contract owner to update cooldown period on cluster redeeming and transfering.
    /// @param _cooldownPeriod New lock period.
    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyAdmin {
        cooldownPeriod = _cooldownPeriod;
    }

    /// @notice Function pauses assemble, dissamble, transfers.
    function pause() external onlyAdmin {
        _pause();
    }

    /// @notice Function unpauses assemble, dissamble, transfers.
    function unpause() external onlyAdmin {
        _unpause();
    }

    /// @notice Controller ownership transfer.
    function controllerChange(address _controller) external override {
        require(_msgSender() == clusterControllerAddress, "COntroller only");
        clusterControllerAddress = _controller;
    }

    /**********
     * USER'S INTERFACE
     **********/

    /// @notice Function that allows depositing ETH and purchase respective amount of cluster.
    /// @dev Can only be called when token is not paused.
    /// @param coverDhvWithEth Should DHV to cover commission be purchased during the call,
    /// rather then transferred from the caller's address.
    /// @return Amount of cluster purchased.
    function assemble(bool coverDhvWithEth) external payable override whenNotPaused returns (uint256) {
        require(msg.value > 0, "No ether sent");

        uint256 _ethCommission = IController(clusterControllerAddress).getDepositComission(address(this), msg.value);
        uint256 ethAmount = msg.value - _coverCommission(_ethCommission, coverDhvWithEth);

        uint256 balanceBefore = address(this).balance;
        uint256 denominator = _swapEthToUnderlyings(ethAmount);
        uint256 balanceAfter = address(this).balance;

        if (balanceBefore - balanceAfter < ethAmount) {
            uint256 dust = ethAmount - (balanceBefore - balanceAfter);
            _payInEth(dust);
            ethAmount -= (dust);
        }
        uint256 clusterAmount = (ethAmount * 10**18) / denominator;

        cooldownTimestamps[_msgSender()] = block.timestamp + cooldownPeriod;

        _mint(_msgSender(), clusterAmount);
        emit ClusterAssembledInETH(address(this), _msgSender(), ethAmount, clusterAmount);

        return clusterAmount;
    }

    /// @notice Function that allows disassembling cluster and receiving respective amount of ETH.
    /// @dev Can only be called when token is not paused.
    /// @param _clusterAmount Amount of cluster to be redeemed, e.g. exchanged to ETH equivalent.
    /// @param coverDhvWithEth Should DHV to cover commission be purchased during the call,
    /// rather then transferred from the caller's address.
    function disassemble(uint256 _clusterAmount, bool coverDhvWithEth) external payable override whenNotPaused checkCooldownPeriod {
        require(_clusterAmount > 0 && _clusterAmount <= balanceOf(_msgSender()), "Not enough cluster");
        IERC20(address(this)).safeTransferFrom(_msgSender(), address(this), _clusterAmount);

        uint256[] memory underlyingAmounts = getUnderlyingsAmountsFromClusterAmount(_clusterAmount);

        uint256 balanceBefore = address(this).balance;
        _swapUnderlyingsToEth(underlyingAmounts);
        uint256 balanceAfter = address(this).balance;

        uint256 ethEstimated = balanceAfter - balanceBefore;
        uint256 _ethCommission = IController(clusterControllerAddress).getRedeemComission(address(this), ethEstimated);
        uint256 ethAmount = ethEstimated - _coverCommission(_ethCommission, coverDhvWithEth);

        _payInEth(ethAmount);

        _burn(address(this), _clusterAmount);
        emit ClusterDisassembledInETH(address(this), _msgSender(), _clusterAmount);
    }

    /// @dev Standard ERC20 transfer function, overriden in order to check lock period.
    function transfer(address recipient, uint256 amount) public override checkCooldownPeriod returns (bool) {
        return super.transfer(recipient, amount);
    }

    /// @dev Standard ERC20 transferFrom function, overriden in order to check lock period.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override checkCooldownPeriod returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**********
     * FARMER AND DELEGATE INTERFACE
     **********/

    /// @notice Mints tokens for the contract with minter role.
    /// @notice requires approved amounts of underlyings
    /// @param _clusterAmount Cluster token amount to be minted.
    function mint(uint256 _clusterAmount) external onlyMinter {
        uint256[] memory underlyingAmounts = getUnderlyingsAmountsFromClusterAmount(_clusterAmount);

        for (uint256 i = 0; i < underlyingAmounts.length; i++) {
            IERC20(underlyings[i]).safeTransferFrom(_msgSender(), address(this), underlyingAmounts[i]);
        }

        _mint(_msgSender(), _clusterAmount);

        emit ClusterAssembled(address(this), _msgSender(), _clusterAmount);
    }

    /// @notice Mints tokens for the account. Sets cooldown
    /// @notice requires approved amounts of underlyings
    /// @param _account Account to be minted for.
    /// @param _clusterAmount Cluster token amount to be minted.
    function mintFor(address _account, uint256 _clusterAmount) external onlyMinter {
        uint256[] memory underlyingAmounts = getUnderlyingsAmountsFromClusterAmount(_clusterAmount);

        for (uint256 i = 0; i < underlyingAmounts.length; i++) {
            IERC20(underlyings[i]).safeTransferFrom(_msgSender(), address(this), underlyingAmounts[i]);
        }

        cooldownTimestamps[_account] = block.timestamp + cooldownPeriod;
        _mint(_account, _clusterAmount);

        emit ClusterAssembled(address(this), _account, _clusterAmount);
    }

    /// @notice Burns cluster tokens after the trade.
    /// @notice requires underlyings to be present
    /// @param _clusterAmount Cluster token amount to be minted.
    function burn(uint256 _clusterAmount) external onlyMinter {
        uint256[] memory underlyingAmounts = getUnderlyingsAmountsFromClusterAmount(_clusterAmount);

        for (uint256 i = 0; i < underlyingAmounts.length; i++) {
            IERC20(underlyings[i]).safeTransfer(_msgSender(), underlyingAmounts[i]);
        }

        _burn(address(this), _clusterAmount);

        emit ClusterDisassembled(address(this), _msgSender(), _clusterAmount);
    }

    /// @notice Withdraw tokens of cluster for staking.
    /// @param _tokens List of tokens to be transferred.
    /// @param _amounts Amounts of tokens to be transferred.
    function withdrawToAccumulation(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _clusterAmount
    ) external override onlyFarmer {
        require(_tokens.length == _amounts.length, "Wrong array");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(_msgSender(), _amounts[i]);
            clusterLock[_tokens[i]] += _amounts[i];
        }
        clusterTokenLock += _clusterAmount;
    }

    /// @notice Refund tokens of cluster from staking.
    /// @param _tokens List of tokens to be transferred.
    /// @param _amounts Amounts of tokens to be transferred.
    function refundFromAccumulation(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _clusterAmount
    ) external override onlyFarmer {
        require(_tokens.length == _amounts.length, "Wrong array");
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransferFrom(_msgSender(), address(this), _amounts[i]);
            clusterLock[_tokens[i]] -= _amounts[i];
        }
        clusterTokenLock -= _clusterAmount;
    }

    /// @notice Interface for optimizer for the correction of the underlyings proportion.
    /// @param updatedShares New weights.
    function optimizeProportion(uint256[] memory updatedShares) external override onlyDelegate returns (uint256[] memory debt) {
        require(updatedShares.length == underlyingsShares.length, "Wrong array");
        debt = new uint256[](underlyings.length);

        uint256 clusterTokenLockMemo = clusterTokenLock;
        uint256[] memory curSharesAmounts = getUnderlyingsAmountsFromClusterAmount(totalSupply() - clusterTokenLockMemo);
        underlyingsShares = updatedShares;
        uint256[] memory newSharesAmounts = getUnderlyingsAmountsFromClusterAmount(totalSupply() - clusterTokenLockMemo);
        uint256[] memory newLock = getUnderlyingsAmountsFromClusterAmount(clusterTokenLockMemo);

        for (uint256 i = 0; i < underlyings.length; i++) {
            address tkn = underlyings[i];
            if (curSharesAmounts[i] > newSharesAmounts[i]) {
                IERC20(tkn).safeTransfer(_msgSender(), curSharesAmounts[i] - newSharesAmounts[i]);
            } else if (curSharesAmounts[i] < newSharesAmounts[i]) {
                IERC20(tkn).safeTransferFrom(_msgSender(), address(this), newSharesAmounts[i] - curSharesAmounts[i]);
            }
            if (newLock[i] > clusterLock[tkn]) {
                debt[i] = newLock[i] - clusterLock[tkn];
            } else {
                debt[i] = 0;
            }
            clusterLock[tkn] = newLock[i];
        }
    }

    /**********
     * VIEW INTERFACE
     **********/

    /// @notice Get list of underlyings for cluster.
    /// @return underlyings array.
    function getUnderlyings() public view override returns (address[] memory) {
        return underlyings;
    }

    /// @notice Get list of underlyings shares for cluster.
    /// @return underlyingsShares array.
    function getUnderlyingShares() public view override returns (uint256[] memory) {
        return underlyingsShares;
    }

    /// @notice Calculates amounts of underlyings over the amount of cluster.
    /// @param _clusterAmount Amount of cluster to calculate underlyings from.
    /// @return Array, which contains amounts of underlyings.
    function getUnderlyingsAmountsFromClusterAmount(uint256 _clusterAmount) public view override returns (uint256[] memory) {
        uint256 totalCluster = IERC20(address(this)).totalSupply();
        uint256 clusterShare = (_clusterAmount * 10**18) / totalCluster;
        uint256[] memory underlyingsAmount = new uint256[](underlyings.length);
        for (uint256 i = 0; i < underlyings.length; i++) {
            uint256 underlyingAmount = getUnderlyingBalance(underlyings[i]);
            underlyingsAmount[i] = (underlyingAmount * clusterShare) / 10**18;
        }

        return underlyingsAmount;
    }

    /// @notice Calculates amount of underlying including locked assets.
    /// @param _underlying Underlying address.
    /// @return Array, which contains amounts of underlyings.
    function getUnderlyingBalance(address _underlying) public view override returns (uint256) {
        return IERC20(_underlying).balanceOf(address(this)) + clusterLock[_underlying];
    }

    /**********
     * INTERNAL HELPERS AND PRICE CALCULATIONS
     **********/

    /// @notice Sends ether to sender for redeeming cluster in ETH.
    /// @dev Reverts if transaction failed.
    /// @param ethAmount Amount of ether to be sent.
    function _payInEth(uint256 ethAmount) private {
        (bool success, ) = _msgSender().call{value: ethAmount}("");
        require(success, "ETH transfer failed");
    }

    /// @notice Covers commission, necessary for cluster deposit or redeem.
    /// @param _ethCommission Commission in ETH to be covered.
    /// @param coverDhvWithEth Should DHV to cover commission be purchased during the call,
    /// rather then transferred from the caller's address.
    /// @return Amount of Ether, spent on commission.
    function _coverCommission(uint256 _ethCommission, bool coverDhvWithEth) internal returns (uint256) {
        if (_ethCommission != 0) {
            if (coverDhvWithEth) {
                (bool success, ) = treasuryAddress.call{value: _ethCommission}("");
                require(success, "Eth transfer failed");
                return _ethCommission;
            } else {
                uint256 _dhvCommission = (_ethCommission * 10**18) / IController(clusterControllerAddress).getDHVPrice(address(this));
                dhvTokenInstance.safeTransferFrom(_msgSender(), treasuryAddress, _dhvCommission);
                return 0;
            }
        }
        return 0;
    }

    /// @notice Allows to swap collected funds into underlyings through the appropriate adapter.
    /// @param _ethAmount Eth amount to be splitted among underlyings.
    function _swapEthToUnderlyings(uint256 _ethAmount) internal returns (uint256) {
        address adapter = IController(clusterControllerAddress).adapters(address(this));

        (uint256[] memory underlyingsAmount, uint256[] memory ethPortion, uint256 clusterPrice) = IController(clusterControllerAddress)
        .getUnderlyingsInfo(address(this), _ethAmount);

        for (uint256 i = 0; i < underlyings.length; i++) {
            if (IERC20(underlyings[i]).balanceOf(treasuryAddress) >= underlyingsAmount[i]) {
                IERC20(underlyings[i]).safeTransferFrom(treasuryAddress, address(this), underlyingsAmount[i]);
                (bool sent, ) = treasuryAddress.call{value: ethPortion[i]}("");
                require(sent, "ETH transfer failed");
            } else {
                IDexAdapter(adapter).swapETHToUnderlying{value: ethPortion[i]}(underlyings[i]);
            }
        }
        return clusterPrice;
    }

    /// @notice Swaps underlyings tokens into ETH.
    /// @param _underlyingsAmounts Array of underlying tokens amounts.
    function _swapUnderlyingsToEth(uint256[] memory _underlyingsAmounts) internal {
        address adapter = IController(clusterControllerAddress).adapters(address(this));
        for (uint256 i = 0; i < _underlyingsAmounts.length; i++) {
            IERC20(underlyings[i]).safeApprove(adapter, 0);
            IERC20(underlyings[i]).safeApprove(adapter, _underlyingsAmounts[i]);
        }

        IDexAdapter(adapter).swapUndelyingsToETH(_underlyingsAmounts, underlyings);
    }
}