/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    mapping (address => uint256) private _balances;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

/**
 * @title RandomNumberConsumer Interface
 */
interface IRandomNumberConsumer {
    /**
     * @dev External function to request randomness and returns request Id. This function can be called by only apporved games.
     */
    function requestRandomNumber() external returns (bytes32);

    /**
     * @dev External function to return verified random number. This function can be called by only ULP.
     * @param _reqeustId Batching Id of random number.
     */
    function getVerifiedRandomNumber(bytes32 _reqeustId)
        external
        view
        returns (uint256);

    /**
     * @dev External function to set ULP address. This function can be called by only owner.
     * @param _ulpAddr Address of ULP
     */
    function setULPAddress(address _ulpAddr) external;
}

/**
 * @title UnifiedLiquidityPool Contract
 */
contract UnifiedLiquidityPool is ERC20, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    /// @notice Event emitted only on construction.
    event UnifiedLiquidityPoolDeployed();

    /// @notice Event emitted when owner initialize staking.
    event stakingStarted(uint256 GBTSAmount);

    /// @notice Event emitted when user stake GBTS token
    event staked(address staker, uint256 GBTSAmount, uint256 sGBTSAmount);

    /// @notice Event emitted when user exit staking
    event stakeExit(address staker, uint256 GBTSAmount, uint256 sGBTSAmount);

    /// @notice Event emitted when sGBTS put into the dividend pool
    event sharesAdded(address provider, uint256 shares);

    /// @notice Event emitted when sGBTS is removed from dividend pool
    event sharesRemoved(address provider, uint256 shares);

    /// @notice Event emitted when distributed
    event distributed(uint256 distributionAmount, address receiver);

    /// @notice Event emitted when dividend pool is changed
    event dividendPoolAddressChanged(address ulpDivAddr, uint256 burnAmount);

    /// @notice Event emitted when game unlock is initiated
    event gameApprovalUnlockInitiated(address gameAddr);

    /// @notice Event emitted when game is approved
    event gameApproved(address gameAddr, bool approved);

    /// @notice Event emitted when prize is sent to the winner
    event prizeSent(address gameAddr, address winner, uint256 GBTSAmount);

    /// @notice Event emitted when only burn sGBTS token
    event sGBTSburnt(uint256 sGBTSAmount);
    
    /// @notice Event emitted only when batch block changes
    event batchGroupingChanged(uint256 nextCall);

    struct dividendPool {
        address provider;
        uint256 shares;
        uint256 profits;
    }

    /// @notice Approved Game List
    address[] public approvedGamesList;

    /// @notice Current game is approved
    mapping(address => bool) public isApprovedGame;

    /// @notice GBTS token instance
    IERC20 public GBTS;

    /// @notice Random Number Consumer instance
    IRandomNumberConsumer public RNG;

    /// @notice Boolean variable for checking whether staking is started or not
    bool public isStakingStarted;

    /// @notice Weight of current distribution amount
    uint256 public currentWeight;

    /// @notice Stakers array in dividend pool
    dividendPool[] public stakers;

    /// @notice Track the provider index in dividend pool
    mapping(address => uint256) public providerIndex;

    /// @notice Point the next receipent in dividend pool
    uint256 public indexProvider;

    /// @notice Amount of limit can be distributed
    uint256 constant balanceControlULP = 45000000 * 10**18;

    /// @notice Distribution weight
    uint256 public distribution;

    bytes32 private currentRequestId;

    uint256 private constant APPROVAL_TIMELOCK = 1 days;

    mapping(address => uint256) public gameApprovalLockTimestamp;

    mapping(bytes32 => uint256) randomMatch;

    mapping(bytes32 => bool) hasReturned;

    uint256 lastBlockNumber;

    uint256 nextCall;

    mapping(address => uint256) gameIndex;

    uint256 public dividendTotal;

    modifier canStake() {
        require(isStakingStarted, "ULP: Owner must initialize staking");
        _;
    }

    modifier onlyApprovedGame() {
        require(isApprovedGame[msg.sender], "ULP: Game is not approved");
        _;
    }

    modifier gameApprovalNotLocked(address _gameAddr) {
        require(
            gameApprovalLockTimestamp[_gameAddr] != 0,
            "ULP: Game approval unlock not initiated"
        );
        require(
            block.timestamp >=
                gameApprovalLockTimestamp[_gameAddr] + APPROVAL_TIMELOCK,
            "ULP: Game approval under timelock"
        );
        _;
    }

    /**
     * @dev Constructor function
     * @param _GBTS Interface of GBTS
     * @param _RNG Interface of Random Number Generator
     */
    constructor(IERC20 _GBTS, IRandomNumberConsumer _RNG)
        ERC20("Stake GBTS", "sGBTS")
    {
        GBTS = _GBTS;
        RNG = _RNG;
        emit UnifiedLiquidityPoolDeployed();
        nextCall = 3;
    }

    /**
     * @dev External function to start staking. Only owner can call this function.
     * @param _initialStake Amount of GBTS token
     */
    function startStaking(uint256 _initialStake) external onlyOwner {
        require(!isStakingStarted, "ULP: FAIL");

        require(
            GBTS.balanceOf(msg.sender) >= _initialStake,
            "ULP: Caller has not enough balance"
        );

        GBTS.safeTransferFrom(msg.sender, address(this), _initialStake);

        _mint(address(this), _initialStake);

        isStakingStarted = true;
        stakers.push(dividendPool(address(this), _initialStake, 0));
        dividendTotal += _initialStake;
        emit stakingStarted(_initialStake);
    }

    /**
     * @dev External function for staking. This function can be called by any users.
     * @param _amount Amount of GBTS token
     */
    function stake(uint256 _amount) external canStake {
        require(
            GBTS.balanceOf(msg.sender) >= _amount,
            "ULP: Caller has not enough balance"
        );

        uint256 feeAmount = (_amount * 3) / 100;

        uint256 sGBTSAmount = ((_amount - feeAmount) * totalSupply()) /
            ((GBTS.balanceOf(address(this)) + currentWeight));

        GBTS.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, sGBTSAmount);

        emit staked(msg.sender, _amount, sGBTSAmount);
    }

    /**
     * @dev External function to exit staking. Users can withdraw their funds.
     * @param _amount Amount of sGBTS token
     */
    function exitStake(uint256 _amount) external canStake nonReentrant {
        require(
            balanceOf(msg.sender) >= _amount,
            "ULP: Caller has not enough balance"
        );

        uint256 stakeValue = (_amount * GBTS.balanceOf(address(this))) /
            totalSupply();

        uint256 toSend = (stakeValue * 97) / 100;

        if (distribution > 0) {
            uint256 removeDis = (currentWeight * _amount) / totalSupply();
            currentWeight = currentWeight - removeDis;
        }
        _burn(msg.sender, _amount);

        GBTS.safeTransfer(msg.sender, toSend);

        if (totalSupply() == 0) {
            isStakingStarted = false;
        }

        emit stakeExit(msg.sender, toSend, _amount);
    }

    /**
     * @dev External function to allow sGBTS holder to deposit their token to earn direct deposits of GBTS into their wallets
     * @param _amount Amount of sGBTS
     */
    function addToDividendPool(uint256 _amount) external {
        require(
            balanceOf(msg.sender) >= _amount,
            "ULP: Caller has not enough balance"
        );

        require(transfer(address(this), _amount), "ULP: Transfer failed");
        dividendTotal += _amount;
        uint256 index = providerIndex[msg.sender];

        if (stakers[index].provider == msg.sender && index != 0) {
            stakers[index].shares = stakers[index].shares + _amount;
        } else {
            providerIndex[msg.sender] = stakers.length;
            stakers.push(dividendPool(msg.sender, _amount, 0));
        }

        emit sharesAdded(msg.sender, _amount);
    }

    /**
     * @dev External function for getting amount of sGBTS which caller in DividedPool holds.
     */
    function getBalanceofUserHoldInDividendPool()
        external
        view
        returns (uint256)
    {
        uint256 index = providerIndex[msg.sender];
        require(
            stakers[index].provider == msg.sender,
            "ULP: Caller is not in dividend pool."
        );

        return stakers[index].shares;
    }

    /**
     * @dev External function to withdraw from the dividendPool.
     * @param _amount Amount of sGBTS
     */
    function removeFromDividendPool(uint256 _amount) external nonReentrant {
        uint256 index = providerIndex[msg.sender];

        require(index != 0, "ULP: Index out of bounds");
        require(stakers[index].shares >= _amount, "ULP: Not enough shares");

        uint256 feeAmount = _amount / 25; //4% fee
        stakers[index].shares = stakers[index].shares - _amount;
        dividendTotal = dividendTotal - _amount;
        _burn(address(this), feeAmount);

        uint256 amountToSend = _amount - feeAmount;

        _transfer(address(this), msg.sender, amountToSend);

        emit sharesRemoved(msg.sender, _amount);
    }

    /**
     * @dev Public function to check to see if the distributor has any sGBTS then distribute. Only distributes to one provider at a time.
     *      Only if the ULP has more then 45 million GBTS.
     */
    function distribute() public nonReentrant {
        if (GBTS.balanceOf(address(this)) >= balanceControlULP) {
            dividendPool storage user = stakers[indexProvider];
            if (user.provider != address(this)) {
                if (stakers[indexProvider].shares == 0) {
                    // Current Staker hasn't got any sGBTS. That means that user isn't staker anymore. So remove that user in Stakers pool.
                    // And replace last staker to that user who hasn't got any sGBTS.

                    stakers[indexProvider] = stakers[stakers.length - 1];
                    providerIndex[
                        stakers[stakers.length - 1].provider
                    ] = indexProvider;
                    providerIndex[user.provider] = 0;
                    stakers.pop();

                    emit distributed(0, user.provider);
                } else {
                    //Set to sGBTS % to 2millGBTS
                    uint256 sendAmount = (user.shares * 2000000 * 10**18) /
                        dividendTotal;
                    currentWeight = currentWeight + sendAmount;
                    distribution = distribution + sendAmount;
                    GBTS.safeTransfer(user.provider, sendAmount);
                    user.profits = sendAmount + user.profits;
                    emit distributed(
                        sendAmount,
                        stakers[indexProvider].provider
                    );
                }
            }
            if (indexProvider == 0) {
                stakers[0].provider = address(this);
                indexProvider = stakers.length;
            }
            indexProvider = indexProvider - 1;
        }
    }

    /**
     * @dev External Admin function to adjust for casino Costs, i.e. VRF, developers, raffles ...
     *      When distributed to the new address the address will be readjusted back to the ULP.
     * @param _ulpDivAddr is the address to recieve the dividends
     */
    function changeULPDivs(address _ulpDivAddr) external onlyOwner {
        require(
            stakers[0].provider == address(this),
            "ULP: Need to wait for distribution."
        );
        stakers[0].provider = _ulpDivAddr;
        uint256 feeAmount = stakers[0].shares / 1000; //0.1% fee to change ULP stakes
        stakers[0].shares = stakers[0].shares - feeAmount;
        dividendTotal = dividendTotal - feeAmount;
        _burn(address(this), feeAmount);
        emit dividendPoolAddressChanged(_ulpDivAddr, feeAmount);
    }

    /**
     * @dev External function to unlock game for approval. This can be called by only owner.
     * @param _gameAddr Game Address
     */
    function unlockGameForApproval(address _gameAddr) external onlyOwner {
        require(
            _gameAddr.isContract() == true,
            "ULP: Address is not contract address"
        );
        require(
            gameApprovalLockTimestamp[_gameAddr] == 0,
            "ULP: Game approval unlock already initiated"
        );
        gameApprovalLockTimestamp[_gameAddr] = block.timestamp;

        emit gameApprovalUnlockInitiated(_gameAddr);
    }

    /**
     * @dev External function for changing game's approval. This is called by only owner.
     * @param _gameAddr Address of game
     * @param _approved Approve a game or not
     */

    function changeGameApproval(address _gameAddr, bool _approved)
        external
        onlyOwner
        gameApprovalNotLocked(_gameAddr)
    {
        require(
            _gameAddr.isContract() == true,
            "ULP: Address is not contract address"
        );
        uint256 currentGameIndex = gameIndex[_gameAddr];

        if (approvedGamesList.length > currentGameIndex && approvedGamesList[currentGameIndex] == _gameAddr) {
            address lastGameAddr = approvedGamesList[approvedGamesList.length - 1];
            approvedGamesList[currentGameIndex] = lastGameAddr;
            gameIndex[lastGameAddr] = currentGameIndex;
            approvedGamesList.pop();
        }

        if (_approved == true) {
            gameIndex[_gameAddr] = approvedGamesList.length;
            approvedGamesList.push(_gameAddr);
        }

        gameApprovalLockTimestamp[_gameAddr] = 0;
        isApprovedGame[_gameAddr] = _approved;

        emit gameApproved(_gameAddr, _approved);
    }

    /**
     * @dev External function to get approved games list.
     */
    function getApprovedGamesList() external view returns (address[] memory) {
        return approvedGamesList;
    }

    /**
     * @dev External function to send prize to winner. This is called by only approved games.
     * @param _winner Address of game winner
     * @param _prizeAmount Amount of GBTS token
     */
    function sendPrize(address _winner, uint256 _prizeAmount)
        external
        onlyApprovedGame
    {
        require(
            GBTS.balanceOf(address(this)) >= _prizeAmount,
            "ULP: There is no enough GBTS balance"
        );
        GBTS.safeTransfer(_winner, _prizeAmount);

        emit prizeSent(msg.sender, _winner, _prizeAmount);
    }

    /**
     * @dev Public function to request Chainlink random number from ULP. This function can be called by only apporved games.
     */
    function requestRandomNumber() public onlyApprovedGame returns (bytes32) {
        if (block.number - lastBlockNumber > nextCall) {
            distribute();
            currentRequestId = RNG.requestRandomNumber();
            randomMatch[currentRequestId] = 0;
            hasReturned[currentRequestId] = false;
            lastBlockNumber = block.number;
        }
        return currentRequestId;
    }

    /**
     * @dev Public function to get new vrf number(Game number). This function can be called by only apporved games.
     * @param _requestId Batching Id of random number.
     */
    function getVerifiedRandomNumber(bytes32 _requestId)
        public
        onlyApprovedGame
        returns (uint256)
    {
        if (hasReturned[_requestId]) {
            return randomMatch[_requestId];
        } else {
            uint256 random = RNG.getVerifiedRandomNumber(_requestId); //RNG will revert if it is not returned
            hasReturned[_requestId] = true;
            randomMatch[_requestId] = random;
            return random;
        }
    }

    /**
     * @dev External function to check if the gameAddress is the approved game.
     * @param _gameAddress Game Address
     */
    function currentGameApproved(address _gameAddress)
        external
        view
        returns (bool)
    {
        return isApprovedGame[_gameAddress];
    }

    /**
     * @dev External function to burn sGBTS token. Only called by owner.
     * @param _amount Amount of sGBTS
     */
    function burnULPsGbts(uint256 _amount) external onlyOwner {
        require(stakers[0].shares >= _amount, "ULP: Not enough shares");
        stakers[0].shares = stakers[0].shares - _amount;
        dividendTotal = dividendTotal - _amount;
        _burn(address(this), _amount);
        emit sGBTSburnt(_amount);
    }

    /**
     * @dev External function to change batch block space. Only called by owner.
     * @param _newChange Block space change amount
     */
    function changeBatchBlockSpace(uint256 _newChange) external onlyOwner {
        require(_newChange <= 3, "ULP: The change does not meet the parameters");
        nextCall = _newChange;
        emit batchGroupingChanged(nextCall);
    }
}