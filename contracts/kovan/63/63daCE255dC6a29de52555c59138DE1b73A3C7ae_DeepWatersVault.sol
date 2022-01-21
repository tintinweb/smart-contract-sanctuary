/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// File: ../deepwaters/contracts/libraries/Context.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/access/Ownable.sol

pragma solidity ^0.8.10;


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

// File: ../deepwaters/contracts/interfaces/IERC20.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/token/extensions/IERC20Metadata.sol

pragma solidity ^0.8.10;


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

// File: ../deepwaters/contracts/token/ERC20.sol

pragma solidity ^0.8.10;



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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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

// File: ../deepwaters/contracts/libraries/Address.sol

pragma solidity ^0.8.10;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: ../deepwaters/contracts/libraries/SafeERC20.sol

pragma solidity ^0.8.10;



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

// File: ../deepwaters/contracts/interfaces/IDeepWatersPriceOracle.sol

pragma solidity ^0.8.10;

/**
 * @dev Interface for a DeepWaters price oracle.
 */
interface IDeepWatersPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
    function getFallbackAssetPrice(address asset) external view returns (uint256);
    function getFallbackAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersVault.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersVault contract
 **/

interface IDeepWatersVault {
    function liquidationUserBorrow(address _asset, address _user) external;
    function getAssetDecimals(address _asset) external view returns (uint256);
    function getAssetIsActive(address _asset) external view returns (bool);
    function getAssetDTokenAddress(address _asset) external view returns (address);
    function getAssetTotalLiquidity(address _asset) external view returns (uint256);
    function getAssetTotalBorrowBalance(address _asset) external view returns (uint256);
    function getAssetScarcityRatio(address _asset) external view returns (uint256);
    function getAssetScarcityRatioTarget(address _asset) external view returns (uint256);
    function getAssetBaseInterestRate(address _asset) external view returns (uint256);
    function getAssetSafeBorrowInterestRateMax(address _asset) external view returns (uint256);
    function getAssetInterestRateGrowthFactor(address _asset) external view returns (uint256);
    function getAssetVariableInterestRate(address _asset) external view returns (uint256);
    function getAssetCurrentStableInterestRate(address _asset) external view returns (uint256);
    function getAssetLiquidityRate(address _asset) external view returns (uint256);
    function getAssetCumulatedLiquidityIndex(address _asset) external view returns (uint256);
    function updateCumulatedLiquidityIndex(address _asset) external returns (uint256);
    function getInterestOnDeposit(address _asset, address _user) external view returns (uint256);
    function updateUserCumulatedLiquidityIndex(address _asset, address _user) external;
    function getAssetPriceUSD(address _asset) external view returns (uint256);
    function getUserAssetBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowAverageStableInterestRate(address _asset, address _user) external view returns (uint256);
    function isUserStableRateBorrow(address _asset, address _user) external view returns (bool);
    function getAssets() external view returns (address[] memory);
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external;
    function transferToUser(address _asset, address payable _user, uint256 _amount) external;
    function transferToRouter(address _asset, uint256 _amount) external;
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external;
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) external;
    function getUserBorrowCurrentLinearInterest(address _asset, address _user) external view returns (uint256);
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) external;
    receive() external payable;
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersDataAggregator.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersDataAggregator contract
 **/

interface IDeepWatersDataAggregator {
    function getUserData(address _user)
        external
        view
        returns (
            uint256 collateralBalanceUSD,
            uint256 borrowBalanceUSD,
            uint256 collateralRatio,
            uint256 healthFactor,
            uint256 availableToBorrowUSD
        );
        
    function setVault(address payable _newVault) external;
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersLending.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersLending contract
 **/

interface IDeepWatersLending {
    function setVault(address payable _newVault) external;
    function setDataAggregator(address _newDataAggregator) external;
    function getDataAggregator() external view returns (address);
    function getLiquidator() external view returns (address);
    function beforeTransferDToken(address _asset, address _fromUser, address _toUser, uint256 _amount) external;
}

// File: ../deepwaters/contracts/interfaces/IDToken.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DToken contract
 **/

interface IDToken {
    function balanceOf(address _user) external view returns(uint256);
    function changeDeepWatersContracts(address _newLendingContract, address payable _newVault) external;
    function mint(address _user, uint256 _amount) external;
    function burn(address _user, uint256 _amount) external;
}

// File: ../deepwaters/contracts/DeepWatersVault.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;









/**
* @title DeepWatersVault contract
* @author DeepWaters
* @notice Holds all the funds deposited
**/
contract DeepWatersVault is IDeepWatersVault, Ownable {
    using SafeERC20 for ERC20;
    using Address for address;

    struct Asset {
        uint256 decimals; // the decimals of the asset
        address dTokenAddress; // the address of the dToken representing the asset
        bool isActive; // isActive = true means the asset has been activated (default is true)
        uint256 scarcityRatioTarget; // the scarcity ratio target of the asset (default is 70%)
        uint256 baseInterestRate; // the minimum interest rate charged to borrowers (default is 0.5%)
        uint256 safeBorrowInterestRateMax; // the interest rate growth factor of the asset (default is 4%)
        uint256 interestRateGrowthFactor; // the interest rate growth factor of the asset (default is 100%)
    }
    
    struct AssetTotalBorrowBalances {
        uint256 totalVariableBorrowBalance;
        uint256 totalStableBorrowBalance;
    }

    struct UserDebt {
        uint256 borrowBalance; // user borrow balance of the asset
        uint256 averageStableInterestRate; // user average stable borrow rate of the asset
        bool isStableRateBorrow; // this is a fixed rate loan
        uint256 lastTimestamp; // timestamp of the last operation of the borrow or repay
    }
    
    struct CumulatedLiquidityIndexes {
        uint256 value; // value of cumulated liquidity index of the asset
        uint256 lastUpdate; // timestamp of the last index change
    }
    
    address internal lendingContractAddress;
    IDeepWatersLending lendingContract;
    
    address internal previousVaultAddress;
    address public priceOracleAddress;
    address payable public routerContractAddress;
    
    /**
    * @dev only lending contract can use functions affected by this modifier
    **/
    modifier onlyLendingContract {
        require(lendingContractAddress == msg.sender, "The caller must be a lending contract");
        _;
    }
    
    /**
    * @dev only router contract can use functions affected by this modifier
    **/
    modifier onlyRouterContract {
        require(routerContractAddress == msg.sender, "The caller must be a router contract");
        _;
    }
    
    /**
    * @dev only previous vault contract can use functions affected by this modifier
    **/
    modifier onlyPreviousVault {
        require(previousVaultAddress == msg.sender, "The caller must be a previous vault contract");
        _;
    }
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    uint256 internal constant SECONDS_PER_YEAR = 31536000; // 365 days = 60*60*24*365 = 31536000 sec
    uint256 internal constant ONE_PERCENT = 1e18;
    uint256 internal constant HUNDRED_PERCENT = 1e20;
    
    mapping(address => Asset) internal assets;
    
    // user debt
    // usersDebts[asset][user] => UserDebt
    mapping(address => mapping(address => UserDebt)) internal usersDebts;
    mapping(address => bool) internal users;
    
    // total borrow balances of the assets
    // totalBorrowBalances[asset] => AssetTotalBorrowBalances
    mapping(address => AssetTotalBorrowBalances) internal totalBorrowBalances;
    
    // cumulated liquidity indexes of the assets
    // cumulatedLiquidityIndexes[asset] => CumulatedLiquidityIndexes
    mapping(address => CumulatedLiquidityIndexes) internal cumulatedLiquidityIndexes;
    
    // user cumulated liquidity indexes of the assets
    // usersCumulatedLiquidityIndexes[asset][user] => CumulatedLiquidityIndexes
    mapping(address => mapping(address => CumulatedLiquidityIndexes)) internal usersCumulatedLiquidityIndexes;
    
    address[] public addedAssetsList;
    address[] public usersList;
    
    constructor(
        address _previousVaultAddress,
        address _priceOracleAddress
    ) {
        previousVaultAddress = _previousVaultAddress;
        priceOracleAddress = _priceOracleAddress;
    }
    
    /**
    * @dev liquidation the user's debt
    * @param _asset the address of the asset
    * @param _user the address of the liquidated user
    **/
    function liquidationUserBorrow(address _asset, address _user) external onlyLendingContract {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        
        if (userDebt.borrowBalance > 0) {
            address liquidator = lendingContract.getLiquidator();
            
            updateBorrowBalance(
                _asset,
                liquidator,
                usersDebts[_asset][liquidator].borrowBalance +
                  userDebt.borrowBalance +
                  getUserBorrowCurrentLinearInterest(_asset, _user)
            );
            
            updateBorrowBalance(_asset, _user, 0);
        }
    }
    
    /**
    * @dev sets lendingContractAddress
    * @param _newLendingContract the address of the DeepWatersLending contract
    **/
    function setLendingContract(address _newLendingContract) external onlyOwner {
        lendingContractAddress = _newLendingContract;
        lendingContract = IDeepWatersLending(lendingContractAddress);
        
        Asset memory asset;
        IDToken dToken;
        
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            asset = assets[addedAssetsList[i]];
           
            dToken = IDToken(asset.dTokenAddress);
            dToken.changeDeepWatersContracts(_newLendingContract, payable(address(this)));
        }
    }
    
    /**
    * @dev sets priceOracleAddress
    * @param _newPriceOracleAddress the address of the DeepWatersPriceOracle contract
    **/
    function setPriceOracleContract(address _newPriceOracleAddress) external onlyOwner {
        priceOracleAddress = _newPriceOracleAddress;
    }
    
    /**
    * @dev sets routerContractAddress
    * @param _newRouterContractAddress the address of the DeepWatersRouter contract
    **/
    function setRouterContract(address payable _newRouterContractAddress) external onlyOwner {
        routerContractAddress = _newRouterContractAddress;
    }
    
    /**
    * @dev fallback function enforces that the caller is a contract
    **/
    receive() external payable {
        require(msg.sender.isContract(), "Only contracts can send ETH to the DeepWatersVault contract");
    }

    /**
    * @dev transfers an asset from a depositor to the DeepWatersVault contract
    * @param _asset the address of the asset where the amount is being transferred
    * @param _depositor the address of the depositor from where the transfer is happening
    * @param _amount the asset amount being transferred
    **/
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external onlyLendingContract {
        require(ERC20(_asset).balanceOf(_depositor) >= _amount, "The user does not have enough balance to transfer");
        
        ERC20(_asset).safeTransferFrom(_depositor, address(this), _amount);
    }
    
    /**
    * @dev transfers to the user a specific amount of asset from the DeepWatersVault contract.
    * @param _asset the address of the asset
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _asset, address payable _user, uint256 _amount) external onlyLendingContract {
        if (_asset == ETH_ADDRESS) {
            _user.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(_user, _amount);
        }
    }
    
    /**
    * @dev transfers to the DeepWatersRouter contract a specific amount of asset from the DeepWatersVault contract.
    * @param _asset the address of the asset
    * @param _amount the amount being transferred
    **/
    function transferToRouter(address _asset, uint256 _amount) external onlyRouterContract {
        if (_asset == ETH_ADDRESS) {
            routerContractAddress.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(routerContractAddress, _amount);
        }
    }

    /**
    * @dev updates the user's borrow balance and total borrow balance
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _newBorrowBalance new value of borrow balance
    **/
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) public {
        require(
            msg.sender == lendingContractAddress ||
            msg.sender == address(this) ||
            msg.sender == previousVaultAddress,
            "The caller must be a lending contract or vault contract"
        );
    
        if (!users[_user]) {
            users[_user] = true;
            usersList.push(_user);
        }
        
        UserDebt storage userDebt = usersDebts[_asset][_user];
        
        if (_user != lendingContract.getLiquidator()) {
            AssetTotalBorrowBalances storage assetTotalBorrowBalances = totalBorrowBalances[_asset];
            
            if (userDebt.isStableRateBorrow) {
                assetTotalBorrowBalances.totalStableBorrowBalance = 
                    assetTotalBorrowBalances.totalStableBorrowBalance -
                      userDebt.borrowBalance +
                      _newBorrowBalance;
                
                if (_newBorrowBalance == 0) {
                    userDebt.averageStableInterestRate = 0;
                    userDebt.isStableRateBorrow = false;
                }
            } else {
                assetTotalBorrowBalances.totalVariableBorrowBalance = 
                    assetTotalBorrowBalances.totalVariableBorrowBalance -
                    userDebt.borrowBalance +
                    _newBorrowBalance;
            }
        }
        
        userDebt.borrowBalance = _newBorrowBalance;
        userDebt.lastTimestamp = block.timestamp;
    }
    
    
    
    /**
    * @dev sets the user's average stable interest rate
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _newAverageStableInterestRate new value of average stable interest rate
    **/
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) public onlyLendingContract {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        userDebt.averageStableInterestRate = _newAverageStableInterestRate;
    }
    
    /**
    * @dev gets the linear interest of user borrow
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @return the linear interest of user borrow
    **/
    function getUserBorrowCurrentLinearInterest(address _asset, address _user)
        public
        view
        returns (uint256)
    {
        if (_user == lendingContract.getLiquidator()) {
            return 0;
        }
        
        UserDebt storage userDebt = usersDebts[_asset][_user];
        uint256 rate;
        
        if (userDebt.isStableRateBorrow) {
            rate = userDebt.averageStableInterestRate;
        } else {
            rate = getAssetVariableInterestRate(_asset);
        }
        
        return userDebt.borrowBalance *
          (block.timestamp - userDebt.lastTimestamp) *
          rate /
          SECONDS_PER_YEAR /
          HUNDRED_PERCENT;
    }
    
    /**
    * @dev sets the user's borrow interest rate mode (stable or variable) for asset-specific borrows
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _isStableRateBorrow the true for stable mode and the false for variable mode
    **/
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) public onlyLendingContract {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        userDebt.isStableRateBorrow = _isStableRateBorrow;
    }
    
    /**
    * @dev gets total borrow balance of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetTotalBorrowBalance(address _asset) public view returns (uint256) {
        return totalBorrowBalances[_asset].totalVariableBorrowBalance + totalBorrowBalances[_asset].totalStableBorrowBalance;
    }
    
    /**
    * @dev gets total variable borrow balance of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetTotalVariableBorrowBalance(address _asset) public view returns (uint256) {
        return totalBorrowBalances[_asset].totalVariableBorrowBalance;
    }
    
    /**
    * @dev gets total stable borrow balance of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetTotalStableBorrowBalance(address _asset) external view returns (uint256) {
        return totalBorrowBalances[_asset].totalStableBorrowBalance;
    }
    
    /**
    * @dev gets scarcity ratio of the specified asset (in percents and with 18 decimals).
    * Scarcity ratio is ratio of asset-specific liabilities relative to asset-specific deposits.
    * @param _asset the address of the basic asset
    **/
    function getAssetScarcityRatio(address _asset) public view returns (uint256) {
        uint256 reserveSize = getAssetTotalLiquidity(_asset) + getAssetTotalBorrowBalance(_asset);
        
        return reserveSize == 0 ? 0 : getAssetTotalBorrowBalance(_asset) * HUNDRED_PERCENT / reserveSize;
    }
    
    /**
    * @dev gets variable interest rate of the specified asset (in percents and with 18 decimals).
    * The interest rate for a variable-rate loan.
    * Rate is constantly variable in response to conditions of the system.
    * @param _asset the address of the basic asset
    **/
    function getAssetVariableInterestRate(address _asset) public view returns (uint256) {
        uint256 variableInterestRate;
        uint256 scarcityRatio = getAssetScarcityRatio(_asset);
        uint256 scarcityRatioTarget = assets[_asset].scarcityRatioTarget;
        
        if (scarcityRatio <= scarcityRatioTarget) {
            variableInterestRate = assets[_asset].baseInterestRate +
                scarcityRatio * assets[_asset].safeBorrowInterestRateMax / scarcityRatioTarget;
        } else {
            variableInterestRate = assets[_asset].baseInterestRate +
                assets[_asset].safeBorrowInterestRateMax +
                scarcityRatio * assets[_asset].interestRateGrowthFactor / scarcityRatioTarget / (HUNDRED_PERCENT - scarcityRatioTarget);
        }
        
        return variableInterestRate;
    }
    
    /**
    * @dev gets current stable interest rate of the specified asset (in percents and with 18 decimals).
    * The current interest rate for a stable-rate loan.
    * @param _asset the address of the basic asset
    **/
    function getAssetCurrentStableInterestRate(address _asset) external view returns (uint256) {
        return getAssetVariableInterestRate(_asset) + uint256(4) * ONE_PERCENT;
    }
    
    /**
    * @dev gets liquidity rate of the specified asset (in percents and with 18 decimals).
    * Ratio of interest for all borrows of the basic asset to reserve size
    * @param _asset the address of the basic asset
    * @return calculated liquidity rate
    **/
    function getAssetLiquidityRate(address _asset) public view returns (uint256) {
        uint256 totalVariableInterestPerYear = getAssetTotalVariableBorrowBalance(_asset) * getAssetVariableInterestRate(_asset);
        
        address user;
        uint256 totalStableInterestPerYear;
        
        for (uint256 j = 0; j < usersList.length; j++) {
            user = usersList[j];

            totalStableInterestPerYear = totalStableInterestPerYear +
                usersDebts[_asset][user].borrowBalance * usersDebts[_asset][user].averageStableInterestRate;
        }
        
        uint256 reserveSize = getAssetTotalLiquidity(_asset) + getAssetTotalBorrowBalance(_asset);
        
        return reserveSize == 0 ? 0 : (totalVariableInterestPerYear + totalStableInterestPerYear)/reserveSize;
    }
    
    /**
    * @dev gets calculated cumulated liquidity index of the specified asset (in percents and with 18 decimals).
    * @param _asset the address of the basic asset
    * @return calculated cumulated liquidity index
    **/
    function getAssetCumulatedLiquidityIndex(address _asset) public view returns (uint256) {
        return ((getAssetLiquidityRate(_asset) *
                    (block.timestamp - getAssetCumulatedLiquidityIndexLastUpdate(_asset)) /
                    SECONDS_PER_YEAR) + HUNDRED_PERCENT) *
                  getAssetLastStoredCumulatedLiquidityIndex(_asset) /
                  HUNDRED_PERCENT;
    }
    
    /**
    * @dev gets last stored cumulated liquidity index of the specified asset (in percents and with 18 decimals).
    * @param _asset the address of the basic asset
    * @return last stored cumulated liquidity index
    **/
    function getAssetLastStoredCumulatedLiquidityIndex(address _asset) public view returns (uint256) {
        return cumulatedLiquidityIndexes[_asset].value;
    }
    
    /**
    * @dev gets last stored timestamp of last update of the cumulated liquidity index of the specified asset
    * @param _asset the asset address
    * @return last stored timestamp
    **/
    function getAssetCumulatedLiquidityIndexLastUpdate(address _asset) public view returns (uint256) {
        return cumulatedLiquidityIndexes[_asset].lastUpdate;
    }
    
    /**
    * @dev updates cumulated liquidity index of the specified asset
    * @param _asset the address of the basic asset
    * @return cumulated liquidity index
    **/
    function updateCumulatedLiquidityIndex(address _asset) external onlyLendingContract returns (uint256) {
        CumulatedLiquidityIndexes storage cumulatedLiquidityIndex = cumulatedLiquidityIndexes[_asset];
        cumulatedLiquidityIndex.value = getAssetCumulatedLiquidityIndex(_asset);
        cumulatedLiquidityIndex.lastUpdate = block.timestamp;
        
        return cumulatedLiquidityIndex.value;
    }
    
    /**
    * @dev gets the amount of the user interest on deposit of the specified asset
    * @param _asset the address of the basic asset
    * @param _user the user address
    **/
    function getInterestOnDeposit(address _asset, address _user) public view returns (uint256) {
        uint256 currentBalance = getUserAssetBalance(_asset, _user);
        
        return currentBalance *
            getAssetCumulatedLiquidityIndex(_asset) /
            getUserAssetCumulatedLiquidityIndex(_asset, _user) -
            currentBalance;
    }
    
    /**
    * @dev updates user cumulated liquidity index of the specified asset
    * @param _asset the address of the basic asset
    * @param _user the user address
    **/
    function updateUserCumulatedLiquidityIndex(address _asset, address _user) external onlyLendingContract {
        CumulatedLiquidityIndexes storage userCumulatedLiquidityIndex = usersCumulatedLiquidityIndexes[_asset][_user];
        userCumulatedLiquidityIndex.value = getAssetCumulatedLiquidityIndex(_asset);
        userCumulatedLiquidityIndex.lastUpdate = block.timestamp;
    }
    
    /**
    * @dev gets user cumulated liquidity index of the specified asset (in percents and with 18 decimals)
    * @param _asset the basic asset address
    * @param _user the user address
    * @return user cumulated liquidity index
    **/
    function getUserAssetCumulatedLiquidityIndex(address _asset, address _user) public view returns (uint256) {
        uint256 userAssetCumulatedLiquidityIndex = usersCumulatedLiquidityIndexes[_asset][_user].value;
        
        return userAssetCumulatedLiquidityIndex == 0 ? HUNDRED_PERCENT : userAssetCumulatedLiquidityIndex;
    }
    
    /**
    * @dev gets timestamp last update of the user cumulated liquidity index of the specified asset
    * @param _asset the basic asset address
    * @param _user the user address
    * @return user last update timestamp
    **/
    function getUserAssetCumulatedLiquidityIndexLastUpdate(address _asset, address _user) public view returns (uint256) {
        return usersCumulatedLiquidityIndexes[_asset][_user].lastUpdate;
    }
    
    /**
    * @dev gets the basic asset balance of a user based on the corresponding dToken balance.
    * @param _asset the basic asset address
    * @param _user the user address
    * @return the basic asset balance of the user
    **/
    function getUserAssetBalance(address _asset, address _user) public view returns (uint256) {
        IDToken dToken = IDToken(assets[_asset].dTokenAddress);
        return dToken.balanceOf(_user);
    }
    
    /**
    * @dev gets the borrow balance of a user for the specified asset
    * @param _asset the basic asset address
    * @param _user the user address
    * @return borrow balance of the user
    **/
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256) {
        return usersDebts[_asset][_user].borrowBalance;
    }
    
    /**
    * @dev gets the user's average stable interest rate for the specified asset
    * @param _asset the basic asset address
    * @param _user the user address
    * @return average stable interest rate
    **/
    function getUserBorrowAverageStableInterestRate(address _asset, address _user) external view returns (uint256) {
        return usersDebts[_asset][_user].averageStableInterestRate;
    }
    
    /**
    * @dev gets the true if the user has a borrow with a stable rate for specified asset
    * @param _asset the asset address
    * @param _user the user address
    * @return the true if it is stable rate borrow. Otherwise returns false
    **/
    function isUserStableRateBorrow(address _asset, address _user) external view returns (bool) {
        return usersDebts[_asset][_user].isStableRateBorrow;
    }

    /**
    * @dev gets the dToken contract address for the specified asset
    * @param _asset the basic asset address
    * @return the address of the dToken contract
    **/
    function getAssetDTokenAddress(address _asset) public view returns (address) {
        return assets[_asset].dTokenAddress;
    }

    /**
    * @dev gets the asset total liquidity.
    *   The total liquidity is the balance of the asset in the DeepWatersVault contract
    * @param _asset the basic asset address
    * @return the asset total liquidity
    **/
    function getAssetTotalLiquidity(address _asset) public view returns (uint256) {
        uint256 balance;

        if (_asset == ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_asset).balanceOf(address(this));
        }
        return balance;
    }

    /**
    * @dev gets the decimals of the specified asset
    * @param _asset the basic asset address
    * @return the asset decimals
    **/
    function getAssetDecimals(address _asset) external view returns (uint256) {
        return assets[_asset].decimals;
    }

    /**
    * @dev returns true if the specified asset is active
    * @param _asset the basic asset address
    * @return true if the asset is active, false otherwise
    **/
    function getAssetIsActive(address _asset) external view returns (bool) {
        return assets[_asset].isActive;
    }
    
    /**
    * @dev gets the scarcity ratio target of the specified asset
    * @param _asset the basic asset address
    * @return the scarcity ratio target
    **/
    function getAssetScarcityRatioTarget(address _asset) external view returns (uint256) {
        return assets[_asset].scarcityRatioTarget;
    }
    
    /**
    * @dev gets the base interest rate of the specified asset
    * @param _asset the basic asset address
    * @return the base interest rate
    **/
    function getAssetBaseInterestRate(address _asset) external view returns (uint256) {
        return assets[_asset].baseInterestRate;
    }
    
    /**
    * @dev gets the safe borrow interest rate max of the specified asset
    * @param _asset the basic asset address
    * @return the safe borrow interest rate max
    **/
    function getAssetSafeBorrowInterestRateMax(address _asset) external view returns (uint256) {
        return assets[_asset].safeBorrowInterestRateMax;
    }
    
    /**
    * @dev gets the interest rate growth factor of the specified asset
    * @param _asset the basic asset address
    * @return the interest rate growth factor
    **/
    function getAssetInterestRateGrowthFactor(address _asset) external view returns (uint256) {
        return assets[_asset].interestRateGrowthFactor;
    }

    /**
    * @return the array of basic assets added on the vault
    **/
    function getAssets() external view returns (address[] memory) {
        return addedAssetsList;
    }
    
    /**
    * @dev initializes an asset
    * @param _asset the address of the asset
    * @param _dTokenAddress the address of the corresponding dToken contract
    * @param _decimals the number of decimals of the asset
    * @param _isActive true if the basic asset is activated
    * @param _scarcityRatioTarget the scarcity ratio target of the asset in percents and with 18 decimals. Default is 70e18 (70%)
    * @param _baseInterestRate the minimum interest rate charged to borrowers in percents and with 18 decimals. Default is 5e17 (0.5%)
    * @param _safeBorrowInterestRateMax the safe borrow interest rate max of the asset in percents and with 18 decimals. Default is 4e18 (4%)
    * @param _interestRateGrowthFactor the interest rate growth factor of the asset in percents and with 18 decimals. Default is 100e18 (100%)
    **/
    function initAsset(
        address _asset,
        address _dTokenAddress,
        uint256 _decimals,
        bool _isActive,
        uint256 _scarcityRatioTarget,
        uint256 _baseInterestRate,
        uint256 _safeBorrowInterestRateMax,
        uint256 _interestRateGrowthFactor
    ) public {
        require(
            msg.sender == owner() || msg.sender == previousVaultAddress,
            "The caller must be owner or previous vault contract"
        );
        
        Asset storage asset = assets[_asset];
        require(asset.dTokenAddress == address(0), "Asset has already been initialized");

        asset.dTokenAddress = _dTokenAddress;
        asset.decimals = _decimals;
        asset.isActive = _isActive;
        asset.scarcityRatioTarget = _scarcityRatioTarget;
        asset.baseInterestRate = _baseInterestRate;
        asset.safeBorrowInterestRateMax = _safeBorrowInterestRateMax;
        asset.interestRateGrowthFactor = _interestRateGrowthFactor;
        
        CumulatedLiquidityIndexes storage cumulatedLiquidityIndex = cumulatedLiquidityIndexes[_asset];
        cumulatedLiquidityIndex.value = HUNDRED_PERCENT;
        cumulatedLiquidityIndex.lastUpdate = block.timestamp;
        
        bool currentAssetAdded = false;
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            if (addedAssetsList[i] == _asset) {
                currentAssetAdded = true;
            }
        }
        
        if (!currentAssetAdded) {
            addedAssetsList.push(_asset);
        }
    }

    /**
    * @dev activates an asset
    * @param _asset the address of the basic asset
    **/
    function activateAsset(address _asset) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.isActive = true;
    }
    
    /**
    * @dev deactivates an asset
    * @param _asset the address of the basic asset
    **/
    function deactivateAsset(address _asset) public {
        require(
            msg.sender == owner() || msg.sender == address(this),
            "The caller must be owner or vault contract"
        );
        
        Asset storage asset = assets[_asset];
        asset.isActive = false;
    }
    
    /**
    * @dev sets the scarcity ratio target of the specified asset
    * @param _asset the address of the basic asset
    * @param newScarcityRatioTarget new value of the scarcity ratio target of the basic asset
    **/
    function setAssetScarcityRatioTarget(address _asset, uint256 newScarcityRatioTarget) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.scarcityRatioTarget = newScarcityRatioTarget;
    }
    
    /**
    * @dev sets the base interest rate of the specified asset
    * @param _asset the address of the basic asset
    * @param newBaseInterestRate new value of the base interest rate of the basic asset
    **/
    function setAssetBaseInterestRate(address _asset, uint256 newBaseInterestRate) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.baseInterestRate = newBaseInterestRate;
    }
    
    /**
    * @dev sets the safe borrow interest rate max of the specified asset
    * @param _asset the address of the basic asset
    * @param newSafeBorrowInterestRateMax new value of the safe borrow interest rate max of the basic asset
    **/
    function setAssetSafeBorrowInterestRateMax(address _asset, uint256 newSafeBorrowInterestRateMax) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.safeBorrowInterestRateMax = newSafeBorrowInterestRateMax;
    }

    /**
    * @dev sets the interest rate growth factor of the specified asset
    * @param _asset the address of the basic asset
    * @param newInterestRateGrowthFactor new value of the interest rate growth factor of the basic asset
    **/
    function setAssetInterestRateGrowthFactor(address _asset, uint256 newInterestRateGrowthFactor) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.interestRateGrowthFactor = newInterestRateGrowthFactor;
    }
    
    /**
    * @dev gets the price in USD of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetPriceUSD(address _asset) external view returns (uint256) {
        IDeepWatersPriceOracle priceOracle = IDeepWatersPriceOracle(priceOracleAddress);
        return priceOracle.getAssetPrice(_asset);
    }
    
    /**
    * @dev the migration of assets and debt balances between DeepWatersVault contracts
    * This function is only used on the testnet!
    * Migration is prohibited on the mainnet!
    * @param _newLendingContract the address of new DeepWatersLending contract
    * @param _newVault the address of new DeepWatersVault contract
    **/
    function migrationToNewVault(address _newLendingContract, address payable _newVault) external onlyOwner {
        DeepWatersVault newVault = DeepWatersVault(_newVault);
        
        address assetAddress;
        Asset memory asset;
        IDToken dToken;
        address user;
        
        lendingContract.setVault(_newVault);
        
        IDeepWatersDataAggregator dataAggregator = IDeepWatersDataAggregator(lendingContract.getDataAggregator());
        dataAggregator.setVault(_newVault);
        
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            assetAddress = addedAssetsList[i];
            asset = assets[assetAddress];
           
            newVault.initAsset(
                assetAddress,
                asset.dTokenAddress,
                asset.decimals,
                asset.isActive,
                asset.scarcityRatioTarget,
                asset.baseInterestRate,
                asset.safeBorrowInterestRateMax,
                asset.interestRateGrowthFactor
            );
        
            if (assetAddress == ETH_ADDRESS) {
                _newVault.transfer(address(this).balance);
            } else {
                ERC20(assetAddress).safeTransfer(_newVault, ERC20(assetAddress).balanceOf(address(this)));
            }
            
            dToken = IDToken(asset.dTokenAddress);
            dToken.changeDeepWatersContracts(_newLendingContract, _newVault);
            
            for (uint256 j = 0; j < usersList.length; j++) {
                user = usersList[j];
                
                if (usersDebts[assetAddress][user].borrowBalance > 0) {
                    newVault.migrationUserDebt(
                        assetAddress,
                        user,
                        usersDebts[assetAddress][user].borrowBalance,
                        usersDebts[assetAddress][user].averageStableInterestRate,
                        usersDebts[assetAddress][user].isStableRateBorrow,
                        usersDebts[assetAddress][user].lastTimestamp
                    );
                }
                
                newVault.setUserCumulatedLiquidityIndex(
                    assetAddress,
                    user, 
                    getUserAssetCumulatedLiquidityIndex(assetAddress, user),
                    getUserAssetCumulatedLiquidityIndexLastUpdate(assetAddress, user)
                );
            }
            
            newVault.setCumulatedLiquidityIndex(
                assetAddress,
                getAssetLastStoredCumulatedLiquidityIndex(assetAddress),
                getAssetCumulatedLiquidityIndexLastUpdate(assetAddress)
            );
            
            deactivateAsset(assetAddress);
        }
    }
    
    /**
    * @dev the migration of user debt balance of the asset between DeepWatersVault contracts
    * This function is only used on the testnet!!!
    * Migration is prohibited on the mainnet!!!
    * @param _asset the asset address
    * @param _user the user address
    * @param _newBorrowBalance new value of user borrow balance of the asset
    * @param _newAverageStableInterestRate new value of average stable borrow interest rate of the asset
    * @param _isStableRateBorrow the true for fixed rate loan and the false for variable rate loan
    * @param _lastTimestamp the timestamp of the last user operation of the borrow or repay
    **/
    function migrationUserDebt(
        address _asset,
        address _user,
        uint256 _newBorrowBalance,
        uint256 _newAverageStableInterestRate,
        bool _isStableRateBorrow,
        uint256 _lastTimestamp
    ) external onlyPreviousVault {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        
        userDebt.averageStableInterestRate = _newAverageStableInterestRate;
        userDebt.isStableRateBorrow = _isStableRateBorrow;
        
        updateBorrowBalance(_asset, _user, _newBorrowBalance);
        
        userDebt.lastTimestamp = _lastTimestamp;
    }
    
    /**
    * @dev sets cumulated liquidity index of the specified asset during migration between DeepWatersVault contracts
    * This function is only used on the testnet!!!
    * Migration is prohibited on the mainnet!!!
    * @param _asset the address of the basic asset
    **/
    function setCumulatedLiquidityIndex(
        address _asset,
        uint256 _cumulatedLiquidityIndex,
        uint256 _lastUpdate
    ) external onlyPreviousVault {
        CumulatedLiquidityIndexes storage cumulatedLiquidityIndex = cumulatedLiquidityIndexes[_asset];
        cumulatedLiquidityIndex.value = _cumulatedLiquidityIndex;
        cumulatedLiquidityIndex.lastUpdate = _lastUpdate;
    }
    
    /**
    * @dev sets user cumulated liquidity index of the specified asset during migration between DeepWatersVault contracts
    * This function is only used on the testnet!!!
    * Migration is prohibited on the mainnet!!!
    * @param _asset the address of the basic asset
    * @param _user the user address
    **/
    function setUserCumulatedLiquidityIndex(
        address _asset,
        address _user,
        uint256 _cumulatedLiquidityIndex,
        uint256 _lastUpdate
    ) external onlyPreviousVault {
        CumulatedLiquidityIndexes storage userCumulatedLiquidityIndex = usersCumulatedLiquidityIndexes[_asset][_user];
        userCumulatedLiquidityIndex.value = _cumulatedLiquidityIndex;
        userCumulatedLiquidityIndex.lastUpdate = _lastUpdate;
    }
    
    function setDataAggregator(address _newDataAggregator) external onlyOwner {
        lendingContract.setDataAggregator(_newDataAggregator);
    }
    
    /**
    * @dev gets the address of the DeepWatersLending contract
    **/
    function getLendingContract() external view returns (address) {
        return lendingContractAddress;
    }
    
    function getPreviousVault() external view returns (address) {
        return previousVaultAddress;
    }
}