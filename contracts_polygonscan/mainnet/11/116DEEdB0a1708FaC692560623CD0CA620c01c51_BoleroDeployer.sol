/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




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

// File: contracts/BoleroArtist.sol



pragma solidity ^0.8.10;






interface BoleroABI {
    function management() external view returns (address);
    function rewards() external view returns (address);
}
interface PaymentSplitterABI {
    function releaseToken(address _want) external;
}

contract BoleroERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances; //switched to internal to be able to use it in Bolero

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
    constructor (string memory name_, string memory symbol_) {
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
}


contract BoleroArtist is BoleroERC20 {
    using SafeERC20 for IERC20;

    uint256 public constant MAXIMUM_PERCENT = 10000;
    uint256 public releaseTime = 0;
    uint256 public pricePerShare = 0;

    uint256 public shareForBolero = 0;
    uint256 public shareForArtist = 0;
    uint256 public boleroTreasure = 0;
    uint256 public artistTreasure = 0;

    uint256 public royaltiesForBolero = 150;
    uint256 public royaltiesForArtist = 150;
    uint256 public boleroRoyalties = 0;
    uint256 public artistRoyalties = 0;

    address public bolero = address(0);
    address public artist = address(0);
    address public artistPayment = address(0);
    address public pendingArtist = address(0);

    uint256 public underlyingDecimals = 0;
    string public baseURI;
    bool public isInitialized = false;
    bool public isAvailableToTrade = false;
    bool public isWithPaymentSplitter = false;
    bool public isEmergencyPause = false;
    IERC20Metadata public want;

	modifier onlyArtist() {
		require(msg.sender == artist, "!authorized");
		_;
	}
	modifier onlyBoleroOrManagement() {
		require(address(msg.sender) == bolero || address(msg.sender) == BoleroABI(bolero).management(), "!authorized");
		_;
	}
	modifier onlyManagement() {
		require(address(msg.sender) == address(BoleroABI(bolero).management()), "!authorized");
		_;
	}
	modifier onlyBolero() {
		require(address(msg.sender) == bolero, "!authorized");
		_;
	}
    modifier notEmergency() {
		require(isEmergencyPause == false, "emergency pause");
		_;
	}

    event SetArtistAddress(address newAddress);
    event SetPendingArtistAddress(address newAddress);
    event SetAvailableToTrade(bool status);
    event SetEmergencyPause(bool shouldPause);
    event SetPricePerShare(uint256 newPrice);
    event SetShares(uint256 shareForBolero, uint256 shareForArtist);
    event SetRoyalties(uint256 royaltiesForBolero, uint256 royaltiesForArtist);

    constructor(
        address boleroAddress,
        address artistAddress,
        address wantToken,
        string memory artistName,
        string memory artistSymbol,
        string memory artistURL
    ) BoleroERC20(artistName, artistSymbol) {
        bolero = address(boleroAddress);
        artist = artistAddress;
        artistPayment = artistAddress;
        baseURI = artistURL;
		want = IERC20Metadata(wantToken);
        underlyingDecimals = IERC20Metadata(wantToken).decimals();
    }

    /*******************************************************************************
    **	@notice
    **		Once the contract is deployed, some element must be initialized by the
    **      management. This is this function.
    **	@param _totalSupply: total amount of token available to trade.
    **	@param _amountForArtist: total amount of token to mint to the artist.
    **	@param _shareForBolero: % of share for Bolero on the ICO.
    **	@param _shareForArtist: % of share for the artist on the ICO.
    **	@param _releaseTime: date after which the token will be tradable.
    **	@param _initialPricePerShare: the initial price per share.
    **	@param _overrideArtistPaymentAddress: address of artistPayment to replace
    *******************************************************************************/
    function initialize(
        uint256 _totalSupply,
        uint256 _amountForArtist,
        uint256 _shareForBolero,
        uint256 _shareForArtist,
        uint256 _releaseTime,
        uint256 _initialPricePerShare,
        address _overrideArtistPaymentAddress
    ) external onlyBoleroOrManagement() {
        require(!isInitialized, "already initialized");
        require(_amountForArtist <= _totalSupply, "more for artist than supply");
        releaseTime = _releaseTime;

        if (_overrideArtistPaymentAddress != address(0)) {
            artistPayment = _overrideArtistPaymentAddress;
        }

        if (_amountForArtist > 0) {
            _mint(artistPayment, _amountForArtist);
        }
        _mint(address(this), _totalSupply - _amountForArtist);
        _setShares(_shareForBolero, _shareForArtist);
        _setPricePerShare(_initialPricePerShare);
        isInitialized = true;
    }

    /* PUBLIC ACTIONS FOR USERS/ARTIST/BOLERO */

    /*******************************************************************************
    **	@notice
    **		While on the initial coin offering, anyone can buy a share of the Bolero
    **      token. The price is set by Bolero and the amount is splitted between
    **      the artist and bolero.
    **	@param from: address which will receive the BoleroTokens
    **	@param amount: amount of underlying the sender wants to pay.
    *******************************************************************************/
    function buyShare(address from, uint256 amount) public notEmergency() returns (uint256) {
        require(isInitialized, "not initialized");
        require(block.timestamp < releaseTime || !isAvailableToTrade, "no longer available");
        uint256 forSponsor = (amount * 1e18 / pricePerShare * (10 ** underlyingDecimals)) * (10 ** underlyingDecimals);
        //If we are at the end of the sale and the buyer try to buy more token than available,
        //limit the share to the available balance and adjust the amount of underlying token
        //to use to the correct value.
        if (forSponsor > balanceOf(address(this))) {
            forSponsor = balanceOf(address(this));
            amount = forSponsor * pricePerShare;
        }

        uint256 amountForBolero = amount * shareForBolero / MAXIMUM_PERCENT;
        uint256 amountForArtist = amount - amountForBolero;

        boleroTreasure += amountForBolero;
        artistTreasure += amountForArtist;
        require(want.transferFrom(msg.sender, address(this), amountForArtist + amountForBolero));
        _transfer(address(this), from, forSponsor);
        return (forSponsor);
    }

    function estimateBuyShare(uint256 amount) public view returns (uint256, uint256, uint256) {
        uint256 forSponsor = (amount * 1e18 / pricePerShare * (10 ** underlyingDecimals)) * (10 ** underlyingDecimals);
        if (forSponsor > balanceOf(address(this))) {
            forSponsor = balanceOf(address(this));
            amount = forSponsor * pricePerShare;
        }

        uint256 amountForBolero = amount * shareForBolero / MAXIMUM_PERCENT;
        uint256 amountForArtist = amount - amountForBolero;
        return (amountForBolero, amountForArtist, forSponsor);
    }

    /*******************************************************************************
    **	@notice
    **		While on the ICO, the want token are stored in a treasure, with a part
    **      for bolero, and another part for the artist. This function can be used
    **      to withdraw the funds.
    *******************************************************************************/
    function claimTreasure() public notEmergency() returns (uint256) {
        require(isInitialized, "not initialized");
        uint256 claimable = 0;
        if (msg.sender == bolero || msg.sender == address(BoleroABI(bolero).management())) {
            claimable = boleroTreasure;
            boleroTreasure = 0;
            require(want.transfer(BoleroABI(bolero).rewards(), claimable));
            return claimable;
        }
        if (msg.sender == artist || msg.sender == artistPayment) {
            claimable = artistTreasure;
            artistTreasure = 0;
            require(want.transfer(artistPayment, claimable));
            if (isWithPaymentSplitter) {
                PaymentSplitterABI(artistPayment).releaseToken(address(want));
            }
            return claimable;
        }
        revert('invalid caller');
    }

    /*******************************************************************************
    **	@notice
    **		While not on the ICO, a part of each exchange can be taken as royalties.
    **      The value is splitted between the artist and Bolero. This fee occurs
    **      during the beforeTokenTransfer function.
    *******************************************************************************/
    function claimRoyalties() public notEmergency() returns (uint256) {
        require(isInitialized, "not initialized");
        uint256 claimable = 0;
        if (msg.sender == bolero || msg.sender == address(BoleroABI(bolero).management())) {
            claimable = boleroRoyalties;
            boleroRoyalties = 0;
            _transfer(address(this), BoleroABI(bolero).rewards(), claimable);
            return claimable;
        }
        if (msg.sender == artist || msg.sender == artistPayment) {
            claimable = artistRoyalties;
            artistRoyalties = 0;
            _transfer(address(this), artistPayment, claimable);
            if (isWithPaymentSplitter) {
                PaymentSplitterABI(artistPayment).releaseToken(address(this));
            }
            return claimable;
        }
        revert('invalid caller');
    }



    /* MANAGEMENT & CONTROL ACTIONS FOR BOLERO/MANAGEMENT */

    /*******************************************************************************
    **	@notice
    **		While on the initial coin offering, the price of the token is updated
    **      every week by Bolero.
    **	@param _pricePerShare: the new price
    *******************************************************************************/
    function setPricePerShare(uint256 _pricePerShare) public onlyManagement() {
        _setPricePerShare(_pricePerShare);
    }
    function _setPricePerShare(uint256 _pricePerShare) internal {
        require (_pricePerShare != 0, "invalid pricePerShare");

        pricePerShare = _pricePerShare;
        emit SetPricePerShare(_pricePerShare);
    }

    /*******************************************************************************
    **	@notice
    **		Change the availability for the secondary market.
    **      Can only be called by the management.
    *******************************************************************************/
    function setAvailableToTrade() public onlyManagement() {
        _setAvailableToTrade();
    }
    function _setAvailableToTrade() internal {
        require (!isAvailableToTrade, "already availableToTrade");

        isAvailableToTrade = true;
        emit SetAvailableToTrade(isAvailableToTrade);
        _burn(address(this), balanceOf(address(this)));
    }

    /*******************************************************************************
    **	@notice
    **		Change the address of the artist. This address is used to get the fees
    **      and royalties. This set the pendingAddress and not the actual one. It
    **      must be confirmed by Bolero.
    **      Can only be called by the artist itself.
    **	@param _pendingArtist: the new address
    *******************************************************************************/
    function setPendingArtistAddress(address _pendingArtist) public onlyArtist() {
        require (_pendingArtist != address(0), "invalid address");

        pendingArtist = _pendingArtist;
        emit SetPendingArtistAddress(_pendingArtist);
    }

    /*******************************************************************************
    **	@notice
    **		Change the address of the artist. This use the pendingArtistAddress to
    **      set the artistAddress to it
    **      Can only be called by the BoleroContract.
    *******************************************************************************/
    function setArtistAddress() public onlyBolero() {
        require (pendingArtist != address(0), "invalid address");
        artist = pendingArtist;
        pendingArtist = address(0);
        emit SetArtistAddress(pendingArtist);
        emit SetPendingArtistAddress(address(0));
    }

    /*******************************************************************************
    **	@notice
    **		Change the payment address of the artist. This address is used to get
    **      the fees and royalties.
    **	@param _artist: the new address
    **  @param _isPaymentSplitter: if this address a paymentSplitter contract
    *******************************************************************************/
    function setArtistPayment(address _artistPayment, bool _isPaymentSplitter) public onlyBoleroOrManagement() {
        require (_artistPayment != address(0), "invalid address");
        artistPayment = _artistPayment;
        isWithPaymentSplitter = _isPaymentSplitter;
    }

    /*******************************************************************************
    **	@notice Update the share distribution between Bolero and the Artist
    **	@param _shareForBolero: the new share for Bolero
    **	@param _shareForArtist: the new share for the Artist
    *******************************************************************************/
    function setShares(uint256 _shareForBolero, uint256 _shareForArtist) public onlyManagement() {
        _setShares(_shareForBolero, _shareForArtist);
    }
    function _setShares(uint256 _shareForBolero, uint256 _shareForArtist) internal {
        require (_shareForBolero + _shareForArtist == MAXIMUM_PERCENT, "invalid shares");
        shareForBolero = _shareForBolero;
        shareForArtist = _shareForArtist;
        emit SetShares(_shareForBolero, _shareForArtist);
    }

    /*******************************************************************************
    **	@notice Update the royaltis % Bolero and the Artist
    **	@param _royaltiesForBolero: the new share for Bolero
    **	@param _royaltiesForArtist: the new share for the Artist
    *******************************************************************************/
    function setRoyalties(uint256 _royaltiesForBolero, uint256 _royaltiesForArtist) public onlyManagement() {
        require (_royaltiesForBolero + _royaltiesForArtist <= MAXIMUM_PERCENT, "invalid shares");
        royaltiesForBolero = _royaltiesForBolero;
        royaltiesForArtist = _royaltiesForArtist;
        emit SetRoyalties(_royaltiesForBolero, _royaltiesForArtist);
    }

    /*******************************************************************************
    **	@notice Pause all the transfert from/out/mint/burn to handle an emergency
    **          situation.
    **	@param shouldPause: bool value, should we pause or unpause the emergency
    *******************************************************************************/
    function setEmergencyPause(bool shouldPause) public onlyManagement() {
        isEmergencyPause = shouldPause;
        emit SetEmergencyPause(shouldPause);
    }


    /* METHODS OVERRIDE & UPDATE */

    /*******************************************************************************
    **	@notice
    **		Overrinding the default _transfer function in order to setup the
    **      royalties fee system.
    **	@param from: sender
    **	@param to: receiver
    **	@param amount: amount of token in the transfer
    *******************************************************************************/
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 _royaltiesForBolero = 0;
        uint256 _royaltiesForArtist = 0;
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (sender != address(this) && sender != artistPayment) {
            _royaltiesForBolero = amount * royaltiesForBolero / MAXIMUM_PERCENT;
            boleroRoyalties += _royaltiesForBolero;
            _royaltiesForArtist = amount * royaltiesForArtist / MAXIMUM_PERCENT;
            artistRoyalties += _royaltiesForArtist;
        }

        //The sender is sending the full amount (including fees)
        _balances[sender] = senderBalance - amount;
        //The recipient is receiving the amount minus the fees
        _balances[recipient] += amount - _royaltiesForBolero - _royaltiesForArtist;
        _balances[address(this)] += _royaltiesForBolero + _royaltiesForArtist;

        emit Transfer(sender, recipient, amount);
    }

    /*******************************************************************************
    **	@notice
    **		Hook that is called before any transfer of tokens. This includes minting
    **      and burning.
    **      Prevent any transfer while the `isAvailableToTrade` is not enabled;
    **	@param from: address sending the tokens
    **	@param to: address receiveing the tokens
    **	@param amount: not used, the amount of token transfered
    *******************************************************************************/
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override notEmergency() {
        if (isAvailableToTrade) {
            return;
        }  else if (from == address(this)) {
            return;
        } else if (from == address(0) && (msg.sender == BoleroABI(bolero).management() || msg.sender == address(bolero))) {
            return;
        } else if (to == address(0) && (msg.sender == BoleroABI(bolero).management() || msg.sender == address(bolero))) {
            return;
        }

        if (block.timestamp >= releaseTime && !isAvailableToTrade) {
            _setAvailableToTrade();
            return;
        }
        require(isAvailableToTrade, "non transferable right now");

    }
}

// File: contracts/BoleroDeployer.sol



pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;


interface BoleroArtistABI {
    function initialize(uint256 _totalSupply, uint256 _amountForArtist, uint256 _shareForBolero, uint256 _shareForArtist, uint256 _releaseTime, uint256 _initialPricePerShare, address _overrideArtistPaymentAddress) external;
    function artist() external returns (address);
    function pendingArtist() external returns (address);
    function artistPayment() external returns (address);
    function isWithPaymentSplitter() external returns (bool);
    function setArtistAddress() external;
}

interface BoleroPaymentSplitter {
    function migratePayee(address oldPayee, address newPayee) external;
}

contract BoleroDeployer {
    address public management = address(0);
    address public pendingManagement = address(0);
    address public rewards = address(0);
    mapping (address => address) public artists;

    event UpdateManagement(address indexed management);
    event UpdateRewards(address indexed rewards);

	modifier onlyManagement() {
		require(msg.sender == management, "!authorized");
		_;
	}
	modifier onlyPendingManagement() {
		require(msg.sender == pendingManagement, "!authorized");
		_;
	}

    constructor(address _management, address _rewards) {
        management = _management;
        rewards = _rewards;
    }

	function name() external pure returns (string memory) {
        return "Bolero Deployer";
	}
	
	/*******************************************************************************
	**	@notice Create a new artist. This may only be called by Management
	**	@param artistAddress The address of the artist
	**	@param artistName Name of the artist/ERC20
	**	@param artistSymbol Symbol of the artist/ERC20
	**	@param artistURL URL to the artist page
	*******************************************************************************/
    function newArtist(
        address artistAddress,
        address wantToken,
        string memory artistName,
        string memory artistSymbol,
        string memory artistURL
    ) external onlyManagement() {
        require(artists[artistAddress] == address(0), 'Artist already deployed');

        address artistContract = address(new BoleroArtist(
            address(this),
            artistAddress,
            wantToken,
            artistName,
            artistSymbol,
            artistURL
        ));
        artists[artistAddress] = artistContract;
    }

	/*******************************************************************************
	**	@notice Initialize an existing artist.
    **	@param contractAddress: address of the artist's contract
    **	@param totalSupply: total amount of token available to trade.
    **	@param amountForArtist: total amount of token to mint to the artist.
    **	@param shareForBolero: % of share for Bolero on the ICO.
    **	@param shareForArtist: % of share for the artist on the ICO.
    **	@param releaseTime: date after which the token will be tradable.
    **	@param overrideArtistPaymentAddress: address of artistPayment to replace
	*******************************************************************************/
    function initializeArtist(
        address contractAddress,
        uint256 totalSupply,
        uint256 amountForArtist,
        uint256 shareForBolero,
        uint256 shareForArtist,
        uint256 releaseTime,
        uint256 initialPricePerShare,
        address overrideArtistPaymentAddress
    ) external onlyManagement() {
        BoleroArtistABI(contractAddress).initialize(
            totalSupply,
            amountForArtist,
            shareForBolero,
            shareForArtist,
            releaseTime,
            initialPricePerShare,
            overrideArtistPaymentAddress
        );
    }

    /*******************************************************************************
	**	@notice Update the artists mapping for a specific contract. Also used to
    **          confirm the update of the artistAddress
    **	@param contractAddress: address of the artist's contract
	*******************************************************************************/
    function migrateArtist(address artistContract) external onlyManagement() {
        address artist = BoleroArtist(artistContract).artist();
        require(artist != address(0), "invalid address");
        address pendingArtist = BoleroArtist(artistContract).pendingArtist();
        require(pendingArtist != address(0), "invalid address");
        bool isWithPaymentSplitter = BoleroArtist(artistContract).isWithPaymentSplitter();

        artists[artist] = address(0);
        artists[pendingArtist] = artistContract;
        BoleroArtist(artistContract).setArtistAddress();
        if (isWithPaymentSplitter) {
            address artistPayment = BoleroArtist(artistContract).artistPayment();
            BoleroPaymentSplitter(artistPayment).migratePayee(artist, pendingArtist);
        }
    }

	/*******************************************************************************
	**	@notice
	**		Nominate a new address to use as management.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the management address is not updated until
	**		the proposed management address has accepted the responsibility.
	**		This may only be called by the current management address.
	**	@param _management The address requested to take over the management.
	*******************************************************************************/
    function setManagement(address _management) public onlyManagement() {
		pendingManagement = _management;
	}

	/*******************************************************************************
	**	@notice
	**		Once a new management address has been proposed using setManagement(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over management for this contract.
	**		This may only be called by the proposed management address.
	**	@dev
	**		setManagement() should be called by the existing management address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptManagement() public onlyPendingManagement() {
		management = msg.sender;
		emit UpdateManagement(msg.sender);
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the address of `rewards`.
	**		This may only be called by Management
	**	@param _rewards The new rewards address to use.
	*******************************************************************************/
    function setRewards(address _rewards) public onlyManagement() {
		rewards = _rewards;
		emit UpdateRewards(rewards);
	}
}