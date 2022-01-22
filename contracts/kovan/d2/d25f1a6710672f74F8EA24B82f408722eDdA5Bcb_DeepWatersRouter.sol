/**
 *Submitted for verification at Etherscan.io on 2022-01-22
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

// File: ../deepwaters/contracts/interfaces/ILendingPool.sol

pragma solidity ^0.8.10;

/**
 * @dev Partial interface for a Aave LendingPool contract,
 * which is the main point of interaction with an Aave protocol's market
 **/
interface ILendingPool {
    /**
    * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    * @param asset The address of the underlying asset to deposit
    * @param amount The amount to be deposited
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
    
    /**
    * @dev Returns the state and configuration of the reserve
    * @param asset The address of the underlying asset of the reserve
    **/
    function getReserveData(address asset) 
        external
        view
        returns (
            //stores the reserve configuration
            //bit 0-15: LTV
            //bit 16-31: Liq. threshold
            //bit 32-47: Liq. bonus
            //bit 48-55: Decimals
            //bit 56: Reserve is active
            //bit 57: reserve is frozen
            //bit 58: borrowing is enabled
            //bit 59: stable rate borrowing enabled
            //bit 60-63: reserved
            //bit 64-79: reserve factor
            uint256 configuration,
            //the liquidity index. Expressed in ray
            uint128 liquidityIndex,
            //variable borrow index. Expressed in ray
            uint128 variableBorrowIndex,
            //the current supply rate. Expressed in ray
            uint128 currentLiquidityRate,
            //the current variable borrow rate. Expressed in ray
            uint128 currentVariableBorrowRate,
            //the current stable borrow rate. Expressed in ray
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            //tokens addresses
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            //address of the interest rate strategy
            address interestRateStrategyAddress,
            //the id of the reserve. Represents the position in the list of the active reserves
            uint8 id
        );
}

// File: ../deepwaters/contracts/interfaces/IWETHGateway.sol

pragma solidity ^0.8.10;

/**
 * @dev Partial interface for a Aave WETHGateway contract,
 **/
interface IWETHGateway {
  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param lendingPool address of the targeted underlying lending pool
   * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function depositETH(
    address lendingPool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param lendingPool address of the targeted underlying lending pool
   * @param amount amount of aWETH to withdraw and receive native ETH
   * @param onBehalfOf address of the user who will receive native ETH
   */
  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address onBehalfOf
  ) external;
  
  /**
   * @dev Get WETH address used by WETHGateway
   */
  function getWETHAddress() external view returns (address);
}

// File: ../deepwaters/contracts/interfaces/ComptrollerInterface.sol

pragma solidity ^0.8.10;

/**
 * @dev Partial interface for a Compound's CTokenInterface Contract
 **/

interface ComptrollerInterface {
    // @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external view returns (bool);
    
    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (address[] memory);
}

// File: ../deepwaters/contracts/interfaces/CTokenInterface.sol

pragma solidity ^0.8.10;

/**
 * @dev Partial interface for a Compound's CTokenInterface Contract
 **/

interface CTokenInterface {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    function isCToken() external view returns (bool);
    
    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external view returns (address);

    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);
    
    /*** User Interface ***/
    function mint(uint mintAmount) external returns (uint);
    
    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see CompoundCTokenError for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

// File: ../deepwaters/contracts/interfaces/CEtherInterface.sol

pragma solidity ^0.8.10;

/**
 * @dev Partial interface for a Compound's CEther Contract
 **/

interface CEtherInterface {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    function isCToken() external view returns (bool);
    
    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);
    
    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable;
}

// File: ../deepwaters/contracts/DeepWatersRouter.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;










/**
* @title DeepWatersRouter contract
* @author DeepWaters
* @dev Implements functions to transfer assets from DeepWatersVault contract to Aave protocol and back.
*
* Holds the derivatives (aTokens).
**/
contract DeepWatersRouter is Ownable {
    using SafeERC20 for ERC20;

    IDeepWatersVault public vault;
    
    ILendingPool public aaveLendingPool;
    IWETHGateway public aaveWETHGateway;
    
    ComptrollerInterface public compoundComptroller;
    
    /**
    * @dev emitted on deposit to Aave
    * @param _asset the address of the basic asset
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event DepositeToAave(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on redeem from Aave
    * @param _asset the address of the basic asset
    * @param _amount the amount to be redeemed
    * @param _timestamp the timestamp of the action
    **/
    event RedeemFromAave(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on deposit to Compound
    * @param _asset the address of the basic asset
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event DepositeToCompound(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on redeem from Compound
    * @param _asset the address of the basic asset
    * @param _amount the amount to be redeemed
    * @param _timestamp the timestamp of the action
    **/
    event RedeemFromCompound(
        address indexed _asset,
        uint256 _amount,
        uint256 _timestamp
    );
    
    string[] internal compoundCTokenError = [
        'NO_ERROR',
        'UNAUTHORIZED',
        'BAD_INPUT',
        'COMPTROLLER_REJECTION',
        'COMPTROLLER_CALCULATION_ERROR',
        'INTEREST_RATE_MODEL_ERROR',
        'INVALID_ACCOUNT_PAIR',
        'INVALID_CLOSE_AMOUNT_REQUESTED',
        'INVALID_COLLATERAL_FACTOR',
        'MATH_ERROR',
        'MARKET_NOT_FRESH',
        'MARKET_NOT_LISTED',
        'TOKEN_INSUFFICIENT_ALLOWANCE',
        'TOKEN_INSUFFICIENT_BALANCE',
        'TOKEN_INSUFFICIENT_CASH',
        'TOKEN_TRANSFER_IN_FAILED',
        'TOKEN_TRANSFER_OUT_FAILED'
    ];
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Aave balances of router loans by assets
    mapping(address => uint256) public aaveRouterLoanBalances;
    
    // Compound balances of router loans by assets
    mapping(address => uint256) public compoundRouterLoanBalances;
    
    // Aave interest bearing WETH (aWETH)
    address public aWETH;
    
    constructor(
        address payable _vault,
        address _aaveLendingPool,
        address _aaveWETHGateway,
        address _compoundComptroller
    ) {
        vault = IDeepWatersVault(_vault);
        aaveLendingPool = ILendingPool(_aaveLendingPool);
        aaveWETHGateway = IWETHGateway(_aaveWETHGateway);
        updateAWETH();
        
        compoundComptroller = ComptrollerInterface(_compoundComptroller);
    }

    /**
    * @dev deposites an asset from a DeepWatersVault to Aave protocol
    * @param _asset the address of the asset
    * @param _amount the asset amount being deposited
    **/
    function depositeToAave(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification of an asset in Aave protocol
        ( , , , , , , , address aTokenAddress, , , , ) = aaveLendingPool.getReserveData(_asset);
        require(aTokenAddress != address(0), "The asset is not supported by the Aave protocol");
        
        // verification of an asset liquidity in DeepWatersVault contract
        require(_amount <= vault.getAssetTotalLiquidity(_asset), "There is not enough asset liquidity for the operation");
        
        // get _asset from DeepWatersVault contract
        vault.transferToRouter(_asset, _amount);
        
        aaveRouterLoanBalances[_asset] = aaveRouterLoanBalances[_asset] + _amount;
        
        if (_asset == ETH_ADDRESS) {
            // deposit ETH to Aave protocol
            aaveWETHGateway.depositETH{value: _amount}(
                address(aaveLendingPool),
                address(this),
                0
            );
        } else {
            ERC20(_asset).approve(
                address(aaveLendingPool),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            
            // deposit _asset to Aave protocol
            aaveLendingPool.deposit(
                _asset,
                _amount,
                address(this),
                0
            );
        }
        
        emit DepositeToAave(_asset, _amount, block.timestamp);
    }
    
    /**
    * @dev redeems an asset from Aave protocol to DeepWatersVault
    * @param _asset the address of the asset
    * @param _amount the asset amount being redeemed
    **/
    function redeemFromAave(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification of an asset in Aave protocol
        ( , , , , , , , address aTokenAddress, , , , ) = aaveLendingPool.getReserveData(_asset);
        require(aTokenAddress != address(0), "The asset is not supported by the Aave protocol");
        
        // verification loan balance of an asset in DeepWatersRouter contract
        require(_amount <= aaveRouterLoanBalances[_asset], "_amount exceeds the loan balance of an asset in DeepWatersRouter contract");

        if (_asset == ETH_ADDRESS) {
            ERC20(aWETH).approve(
                address(aaveWETHGateway),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        
            // withdraw ETH from Aave protocol
            aaveWETHGateway.withdrawETH(
                address(aaveLendingPool),
                _amount,
                address(this)
            );
            
            payable(address(vault)).transfer(_amount);
        } else {
            // withdraw _asset from Aave protocol to DeepWatersRouter contract
            aaveLendingPool.withdraw(
                _asset,
                _amount,
                address(this)
            );
            
            ERC20(_asset).safeTransfer(address(vault), _amount);
        }
        
        aaveRouterLoanBalances[_asset] = aaveRouterLoanBalances[_asset] - _amount;
        
        emit RedeemFromAave(_asset, _amount, block.timestamp);
    }
    
    /**
    * @dev deposites an asset from a DeepWatersVault to Compound protocol
    * @param _asset the address of the asset
    * @param _amount the asset amount being deposited
    **/
    function depositeToCompound(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification of an asset liquidity in DeepWatersVault contract
        require(_amount <= vault.getAssetTotalLiquidity(_asset), "There is not enough asset liquidity for the operation");
        
        address compoundMarketAddress = getCompoundMarketAddress(_asset);
        
        // get _asset from DeepWatersVault contract
        vault.transferToRouter(_asset, _amount);
        
        compoundRouterLoanBalances[_asset] = compoundRouterLoanBalances[_asset] + _amount;
        
        if (_asset == ETH_ADDRESS) {
            CEtherInterface cEther = CEtherInterface(compoundMarketAddress);
            
            // deposit ETH to Compound protocol
            cEther.mint{value: _amount}();
        } else {
            ERC20(_asset).approve(
                compoundMarketAddress,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            
            CTokenInterface cToken = CTokenInterface(compoundMarketAddress);
            
            // deposit _asset to Compound protocol
            uint result = cToken.mint(_amount);
            require(result == 0, compoundCTokenError[result]);
        }
        
        emit DepositeToCompound(_asset, _amount, block.timestamp);
    }
    
    /**
    * @dev redeems an asset from Compound protocol to DeepWatersVault
    * @param _asset the address of the asset
    * @param _amount the asset amount being redeemed
    **/
    function redeemFromCompound(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        
        // verification loan balance of an asset in DeepWatersRouter contract
        require(_amount <= compoundRouterLoanBalances[_asset], "_amount exceeds the loan balance of an asset in DeepWatersRouter contract");
        
        address compoundMarketAddress = getCompoundMarketAddress(_asset);
        
        CTokenInterface cToken = CTokenInterface(compoundMarketAddress);
        
        // redeem _asset from Compound protocol to DeepWatersRouter contract
        uint result = cToken.redeemUnderlying(_amount);
        require(result == 0, compoundCTokenError[result]);
        
        if (_asset == ETH_ADDRESS) {
            payable(address(vault)).transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(address(vault), _amount);
        }
        
        compoundRouterLoanBalances[_asset] = compoundRouterLoanBalances[_asset] - _amount;
        
        emit RedeemFromCompound(_asset, _amount, block.timestamp);
    }
    
    function getCompoundMarketAddress(address _asset)
        public
        view
        returns (address)
    {
        require(compoundComptroller.isComptroller(), "Wrong comptroller address");
        
        address[] memory compoundMarkets = compoundComptroller.getAllMarkets();
        
        CTokenInterface compoundMarket;
        
        for (uint256 j = 0; j < compoundMarkets.length; j++) {
            compoundMarket = CTokenInterface(compoundMarkets[j]);
            
            if (_asset == ETH_ADDRESS) {
                if (keccak256(abi.encodePacked(compoundMarket.symbol())) == 
                        keccak256(abi.encodePacked('cETH'))) {
                    return compoundMarkets[j];
                }
            } else {
                if (keccak256(abi.encodePacked(compoundMarket.symbol())) !=
                        keccak256(abi.encodePacked('cETH')) && 
                        compoundMarket.underlying() == _asset) {
                    return compoundMarkets[j];
                }
            }
        }
        
        require(false, "The asset is not supported by the Compound protocol");
        return address(0);
    }
    
    function updateAWETH() internal {
        address WETHAddress = aaveWETHGateway.getWETHAddress();
        ( , , , , , , , aWETH, , , , ) = aaveLendingPool.getReserveData(WETHAddress);
        require(aWETH != address(0), "aWETH does not exist");
    }
    
    function setAaveLendingPool(address _newAaveLendingPool) external onlyOwner {
        aaveLendingPool = ILendingPool(_newAaveLendingPool);
        updateAWETH();
    }
    
    function setAaveWETHGateway(address _newAaveWETHGateway) external onlyOwner {
        aaveWETHGateway = IWETHGateway(_newAaveWETHGateway);
        updateAWETH();
    }
    
    function setCompoundComptroller(address _newCompoundComptroller) external onlyOwner {
        compoundComptroller = ComptrollerInterface(_newCompoundComptroller);
    }
}