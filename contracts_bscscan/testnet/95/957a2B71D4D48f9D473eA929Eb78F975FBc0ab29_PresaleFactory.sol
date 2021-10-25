/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin\contracts\utils\Address.sol


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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol



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

// File: node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol



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

// File: node_modules\@openzeppelin\contracts\utils\Context.sol



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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol



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


// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol



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

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts\Presale.sol


pragma solidity ^0.8.0;







contract Presale is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public tokenX; // People will buy tokenX

  uint256 rate; // number of tokens per BUSD
  uint256 amountTokenToHold;
  uint8 tier;
  address factory;
  string presaleMediaLinks; // tokenX owner will give his social media, photo, driving liscense images links.
  bool presaleIsApproved;
  IERC20 tokenToHold; // Users may need to hold this token
  uint256 participants;
  uint256 public softCap;
  uint256 public hardCap;
  uint256 public raisedFunds;
  uint256 presaleScore;
  bool isDistributionMode;
  bool isCanceled;
  bool onlyWhitelistedAllowed;
  bool isDelayed;
  uint256 presaleOpenAt;
  uint256 presaleCloseAt;
  uint256[] bnbLimits;
  string description;

  mapping(address => bool) isWhitelisted;
  mapping(address => uint256) public userBNBAmount;
  mapping(address => bool) public isClaimed;

  struct PresaleInitInfo {
    IERC20 tokenX;
    uint256 rate;
    address projectAddress;
    uint256 amountTokenToHold;
    IERC20 tokenToHold;
    uint256 softCap;
    uint256 hardCap;
    address[] whitelistAddresses;
    string presaleMediaLinks;
    uint256[] bnbLimits;
    string description;
    uint256 presaleOpenAt;
    uint256 presaleCloseAt;
  }

  event Join(address sender, uint256 busdAmount);
  event ClaimTokens(address sender, uint256 tokenAmount);
  event WithdrawRaisedFunds(address to, uint256 raisedFunds);
  event Refund(address to, uint256 busdAmount);
  event RateChanged(uint256 oldRate, uint256 newRate);
  event PresaleCanceled();
  event PresaleScoreModified(uint256 oldPresaleScore, uint256 newPresaleScore);
  event PresaleTierModified(uint8 oldTier, uint8 newTier);
  event PresaleClosed();
  event PresaleDatesSet(uint256 openTime, uint256 closeTime);
  event PresaleDelayed(uint256 olcOpenTime, uint256 newOpenTime);
  event PresaleExtended(uint256 oldCloseTime, uint256 newCloseTime);

  constructor(PresaleInitInfo memory presaleInfo) {
    require(
      address(presaleInfo.tokenToHold) == address(0) || presaleInfo.amountTokenToHold > 0,
      "_amountTokenYToBuyTokenX: must be greater than zero"
    );
    require(presaleInfo.softCap <= presaleInfo.hardCap, "invalid soft cap");
    require(
      presaleInfo.bnbLimits[0] > 0 && presaleInfo.bnbLimits[0] <= presaleInfo.bnbLimits[1],
      "BNB limits: invalid"
    );

    tokenX = presaleInfo.tokenX;
    factory = msg.sender;
    rate = presaleInfo.rate;
    amountTokenToHold = presaleInfo.amountTokenToHold;
    presaleMediaLinks = presaleInfo.presaleMediaLinks;

    tokenToHold = presaleInfo.tokenToHold;
    softCap = presaleInfo.softCap;
    hardCap = presaleInfo.hardCap;

    bnbLimits = presaleInfo.bnbLimits;

    description = presaleInfo.description;
    presaleOpenAt = presaleInfo.presaleOpenAt;
    presaleCloseAt = presaleInfo.presaleCloseAt;

    transferOwnership(presaleInfo.projectAddress);
  }

  /**
  @notice Allows users to join the presale
  Requirements:
  - presale is open
  - presale is not closed
  - presale is approved
  - whitelist is disabled, otherwise validate sender against whitelist
  - hardCap is not set, otherwise validate that current transaction does not exceed hard cap
  */
  function join() external payable {
    require(block.timestamp >= presaleOpenAt, "Presale is not open.");
    require(block.timestamp < presaleCloseAt, "Presale is closed.");
    require(presaleIsApproved, "Presale is not approved.");
    require(
      address(tokenToHold) == address(0) || tokenToHold.balanceOf(msg.sender) >= amountTokenToHold,
      "You need to hold tokens to buy them from presale."
    );
    require(
      !onlyWhitelistedAllowed || isWhitelisted[msg.sender],
      "You should become whitelisted to continue."
    );
    require(!isCanceled, "presale is canceled");
    require(hardCap == 0 || raisedFunds + msg.value <= hardCap, "hard cap exceeded");
    require(
      msg.value >= bnbLimits[0] && msg.value <= bnbLimits[1],
      "contribution is higher/lower than expected"
    );
    // ensure to not exceed maximum BNB limit
    require(userBNBAmount[msg.sender] + msg.value <= bnbLimits[1], "You bought enough already");
    // ensure there are sufficient tokens to cover raised funds
    require(
      ((raisedFunds + msg.value) * rate) / 1e18 <= tokenX.totalSupply(),
      "presale exceeds token supply"
    );
    // ensure contracts cannot participate
    require(tx.origin == msg.sender, "contracts are not allowed");

    // Effects
    if (userBNBAmount[msg.sender] == 0) participants++;
    userBNBAmount[msg.sender] += msg.value;
    raisedFunds += msg.value;

    emit Join(msg.sender, msg.value);
  }

  /**
  @notice Allows users to claim their tokens.
  Requirements:
  - user's BUSD amount is grreater than zero
  - distribution mode is enabled
  - user has not not claimed before
  */
  function claimTokens() external {
    require(userBNBAmount[msg.sender] > 0, "not participant");
    require(isDistributionMode, "distribution mode disabled");
    require(!isClaimed[msg.sender], "tokens already claimed");

    //Effects
    isClaimed[msg.sender] = true;

    uint256 tokenAmount = (userBNBAmount[msg.sender] * rate) / 1e18;
    emit ClaimTokens(msg.sender, tokenAmount);

    // Calls
    tokenX.safeTransfer(msg.sender, tokenAmount);
  }

  /**
  @notice Allows users to get a refund whenver they want till just before distribution mode get enabled.
  Requirements:
  - user busd amount is greater than zero
  - refunds must be alowed at current presale state. See `isRefundAllowed()`.
  */
  function getRefund() external {
    require(userBNBAmount[msg.sender] > 0, "nothing to refund");
    require(isRefundAllowed(), "invalid presale state");

    // Effects
    uint256 refundAmount = userBNBAmount[msg.sender];
    userBNBAmount[msg.sender] = 0;
    raisedFunds -= refundAmount;
    participants--;

    emit Refund(msg.sender, refundAmount);

    // Calls
    Address.sendValue(payable(msg.sender), refundAmount);
  }

  /**
  @dev Validate if refunds are allowed at current presale state.
  Returns true if:
  - presale is canceled or 
    distribution mode is not enabled
  Otherwise returns false.
   */
  function isRefundAllowed() public view returns (bool) {
    return isCanceled || !isDistributionMode;
  }

  /**
  @notice Allows project to withdraw raised funds. This will enable distribution mode. NOT REVERSIBLE.
  Requirements:
  - presale must be closed or hard cap has been reached
  - soft cap has been reached
  - presale is not canceled
  - distribution mode is not enabled
  */
  function withdrawRaisedFunds() external onlyOwner {
    require(
      block.timestamp >= presaleCloseAt || (hardCap > 0 && raisedFunds == hardCap),
      "presale is still running"
    );
    require(raisedFunds >= softCap, "soft cap not reached");
    require(!isCanceled, "presale is canceled");
    require(!isDistributionMode, "distribution mode is already enabled");

    // Effects
    isDistributionMode = true;

    uint256 tokenAmount = (raisedFunds * rate) / 1e18;

    emit WithdrawRaisedFunds(msg.sender, raisedFunds);

    // Calls
    tokenX.safeTransferFrom(msg.sender, address(this), tokenAmount);
    Address.sendValue(payable(msg.sender), raisedFunds);

    // transfer anything left to shield-network
    uint256 balanceLeft = address(this).balance;
    if (balanceLeft > 0) {
      Address.sendValue(payable(Ownable(factory).owner()), balanceLeft);
    }

    // sanity check
    require(tokenX.balanceOf(address(this)) == tokenAmount, "expected token amount not met");
  }

  /**
  @notice Allows project to close presale whenever they want.
  Requirements:
  - soft cap have been reached
  - presale is not closed yet
   */
  function closePresale() external onlyOwner {
    require(raisedFunds >= softCap, "softap is not reached");
    require(block.timestamp < presaleCloseAt, "presale is already closed");

    // Effects
    presaleCloseAt = block.timestamp;

    emit PresaleClosed();
  }

  /** 
  @notice Allows project to cancel presale whenever they want. Their project, their call. NOT REVERTIBLE.
  Requirements
  - is not canceled yet
  - distribution mode is not enabled
  */
  function cancelPresale() external onlyOwner {
    require(!isCanceled, "presale is already canceled");
    require(!isDistributionMode, "distribution mode is enabled");

    // Effects
    isCanceled = true;

    emit PresaleCanceled();
  }

  /**
  @notice Allows project to set token rate.
  @dev _rate = number of coins per BUSD
  Requirements:
  - presale has not started yet.
  */
  function onlyOwnerFunction_setRate(uint256 _rate) external onlyOwner {
    require(presaleOpenAt == 0 || block.timestamp < presaleOpenAt, "presale is already open");
    emit RateChanged(rate, _rate);
    rate = _rate;
  }

  /**
  @notice Allows project to disable whitelist. NOT REVERTIBLE.
   */
  function disableWhitelist() external onlyOwner {
    onlyWhitelistedAllowed = false;
  }

  /**
  @notice Allows project to edit whitelist.
  @dev pass true to add to whitelist, pass false to remove from whitelist
   */
  function editWhitelist(address[] calldata whitelist, bool approved) external onlyOwner {
    for (uint32 i = 0; i < whitelist.length; i++) isWhitelisted[whitelist[i]] = approved;
  }

  /**
  @notice Allows project to delay presale.
  Requirements:
  - presale is not open yet
  - new open date must be greater than current open date
  */
  function delayPresale(uint256 presaleOpenAt_) external onlyOwner {
    require(block.timestamp < presaleOpenAt, "presale is already open");
    require(presaleOpenAt_ > presaleOpenAt, "you can only delay openning");

    emit PresaleDelayed(presaleOpenAt, presaleOpenAt_);

    // Effects
    isDelayed = true;
    presaleOpenAt = presaleOpenAt_;
  }

  /**
  @notice Allows project to extend presale.
  Requirements:
  - presale is not closed yet
  - new close date is greater than current time and greater than current close time
  - time diff (close - open) is less than or equal to 6 months (180 days)
  */
  function extendPresale(uint256 presaleCloseAt_) external onlyOwner {
    require(block.timestamp < presaleCloseAt, "presale is already closed");
    require(presaleCloseAt_ > presaleCloseAt, "specified time is not valid");

    uint256 timeDiff = presaleCloseAt_ - presaleOpenAt;
    require(timeDiff <= (30 days * 6), "presale period should not exceed 6 months");

    emit PresaleExtended(presaleCloseAt, presaleCloseAt_);

    // Effects
    presaleCloseAt = presaleCloseAt_;
  }

  modifier onlyParent() {
    require(msg.sender == parentCompany(), "You must be parent company to edit value");
    _;
  }

  function parentCompany() public view returns (address) {
    return Ownable(factory).owner();
  }

  /**
  @notice Allows parent company to cancel presale. NOT REVERTIBLE.
  This function  should only be executed if one of the following situations apply
  - Project goes MIA
  - Project wants to cancel presale before closing date or after reaching soft cap
  - etc. Any other reasonable reason to enable refund mode

  Why? We dont want our user funds to be locked forever in the presale contract.
  
  Requirements:
  - sender is parent company
  - distribution mode is not enabled
  */
  function onlyParentCompanyFunction_cancelPresale() external onlyParent {
    require(!isCanceled, "presale is already canceled");
    require(!isDistributionMode, "distribution mode is enabled");

    // Effects
    isCanceled = true;

    emit PresaleCanceled();
  }

  function onlyParentCompanyFunction_setPresaleScore(uint256 presaleScore_) external onlyParent {
    emit PresaleScoreModified(presaleScore, presaleScore_);
    presaleScore = presaleScore_;
  }

  /**
  @notice Allows parent company to approve/unapprove presale.
  Requirements:
  - Presale open date is not set or presale is still not open.
   After a presale is open, use cancelPresale.
   */
  function onlyParentCompanyFunction_editPresaleIsApproved(bool _presaleIsApproved)
    external
    onlyParent
  {
    require(presaleOpenAt == 0 || block.timestamp < presaleOpenAt, "presale is already running");

    // Effects
    presaleIsApproved = _presaleIsApproved;
  }

  function onlyParentCompanyFunction_setPresaleTier(uint8 _tier) external onlyParent {
    emit PresaleTierModified(tier, _tier);
    //Effects
    tier = _tier;
  }

  function onlyParentCompanyFunction_setAmountTokenToHold(uint256 amountTokenToHold_) external onlyParent {
    //Effects
    amountTokenToHold = amountTokenToHold_;
  }

  function getPresaleDetails()
    external
    view
    returns (
      address[] memory,
      uint256[] memory,
      bool[] memory,
      string[] memory
    )
  {
    ERC20 erc20 = ERC20(address(tokenX));
    address[] memory addresses = new address[](1);
    addresses[0] = address(tokenX);

    uint256[] memory uints = new uint256[](13);
    uints[0] = raisedFunds;
    uints[1] = rate;
    uints[2] = amountTokenToHold;
    uints[3] = tier;
    uints[4] = presaleOpenAt;
    uints[5] = presaleCloseAt;
    uints[6] = bnbLimits[0]; // min BNB
    uints[7] = bnbLimits[1]; // max BNB
    uints[8] = softCap;
    uints[9] = hardCap;
    uints[10] = tokenX.totalSupply();
    uints[11] = erc20.decimals();
    uints[12] = participants;

    bool[] memory bools = new bool[](6);
    bools[0] = presaleIsApproved;
    bools[1] = onlyWhitelistedAllowed;
    bools[2] = isDistributionMode;
    bools[3] = isCanceled;
    bools[4] = isDelayed;
    bools[5] = isRefundAllowed();

    string[] memory strings = new string[](2);
    strings[0] = erc20.name();
    strings[1] = erc20.symbol();

    return (addresses, uints, bools, strings);
  }

  function getPresaleMediaLinks() external view returns (string memory) {
    return presaleMediaLinks;
  }

  function getDescription() external view returns (string memory) {
    return description;
  }
}

// File: contracts\PresaleFactory.sol


pragma solidity ^0.8.0;



interface IName {
  function name() external view returns (string memory);
}

interface ISymbol {
  function symbol() external view returns (string memory);
}

contract PresaleFactory is Ownable {
  mapping(uint256 => Presale) public presales;
  uint256 public lastPresaleIndex = 0;

  IERC20 tokenToHold;
  uint256 amountTokenToHold;

  uint256 bnbPerPresale = 1e18; // 1 BNB
  address payable paymentRecipient;

  struct CreatePresaleInfo {
    IERC20 tokenX;
    uint256 rate;
    uint256 softCap;
    uint256 hardCap;
    address[] whitelistAddresses;
    string presaleMediaLinks;
    uint256[] bnbLimits;
    string description;
    uint32 presaleOpenAt;
    uint32 presaleCloseAt;
  }

  constructor(address owner_, IERC20 tokenToHold_, address payable paymentRecipient_) {
    require(paymentRecipient_ != address(0), "zero address");
    tokenToHold = tokenToHold_;
    paymentRecipient = paymentRecipient_;
    transferOwnership(owner_);
  }

  /// @dev users can create an ICO for erc20 from this function
  function createERC20Presale(CreatePresaleInfo memory createPresaleInfo) external payable {
    require(msg.value == bnbPerPresale, "value: invalid amount");
    Presale presale = new Presale(
      Presale.PresaleInitInfo(
        createPresaleInfo.tokenX,
        createPresaleInfo.rate,
        msg.sender,
        amountTokenToHold,
        tokenToHold,
        createPresaleInfo.softCap,
        createPresaleInfo.hardCap,
        createPresaleInfo.whitelistAddresses,
        createPresaleInfo.presaleMediaLinks,
        createPresaleInfo.bnbLimits,
        createPresaleInfo.description,
        createPresaleInfo.presaleOpenAt,
        createPresaleInfo.presaleCloseAt
      )
    );

    presales[lastPresaleIndex++] = presale;

    Address.sendValue(paymentRecipient, msg.value);
  }

  function onlyOwner_editTokenToHoldSettings(IERC20 _tokenToHold, uint256 _amountTokenToHold) external onlyOwner {
    tokenToHold = _tokenToHold;
    amountTokenToHold = _amountTokenToHold;
  }

  function onlyOwner_setBNBPerPresaleSettings(address paymentRecipient_, uint256 bnbPerPresale_) external onlyOwner {
    paymentRecipient = payable(paymentRecipient_);
    bnbPerPresale = bnbPerPresale_;
  }

  function getPresales(uint256 _index, uint256 _amountToFetch)
    external
    view
    returns (Presale[] memory, IERC20[] memory)
  {
    uint256 currIndex = _index;
    Presale[] memory tempPresales = new Presale[](_amountToFetch);
    IERC20[] memory tempTokens = new IERC20[](_amountToFetch);
    for (uint256 i = 0; i < _amountToFetch && i < lastPresaleIndex; i++) {
      tempPresales[i] = presales[currIndex];
      tempTokens[i] = presales[currIndex++].tokenX();
    }
    return (tempPresales, tempTokens);
  }

  function getPresaleDetails(address _presale)
    external
    view
    returns (
      address[] memory,
      uint256[] memory,
      bool[] memory,
      string[] memory
    )
  {
    return Presale(_presale).getPresaleDetails();
  }

  function getTokenName(address _token) public view returns (string memory name) {
    return IName(_token).name();
  }

  function getTokenSymbol(address _token) public view returns (string memory symbol) {
    return ISymbol(_token).symbol();
  }

  function getPresaleMediaLinks(Presale presale_) public view returns (string memory symbol) {
    return presale_.getPresaleMediaLinks();
  }
}