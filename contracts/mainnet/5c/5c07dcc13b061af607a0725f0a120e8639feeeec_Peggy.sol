/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

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


// File contracts/@openzeppelin/contracts/utils/Address.sol





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


// File contracts/@openzeppelin/contracts/SafeERC20.sol






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


// File contracts/@openzeppelin/contracts/utils/Initializable.sol



// solhint-disable-next-line compiler-version


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/@openzeppelin/contracts/utils/ContextUpgradeable.sol





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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/@openzeppelin/contracts/utils/Pausable.sol



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is ContextUpgradeable {
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


// File contracts/@openzeppelin/contracts/security/ReentrancyGuard.sol





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


// File contracts/@openzeppelin/contracts/IERC20Metadata.sol





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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


// File contracts/@openzeppelin/contracts/utils/Context.sol





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


// File contracts/@openzeppelin/contracts/ERC20.sol







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
     * overloaded;
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


// File contracts/CosmosToken.sol




contract CosmosERC20 is ERC20 {
	uint256 MAX_UINT = 2**256 - 1;
	uint8 immutable private _decimals;

	constructor(
		address peggyAddress_,
		string memory name_,
		string memory symbol_,
		uint8 decimals_
	) ERC20(name_, symbol_) {
		_decimals = decimals_;
		_mint(peggyAddress_, MAX_UINT);
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}
}


// File contracts/@openzeppelin/contracts/OwnableUpgradeableWithExpiry.sol






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
abstract contract OwnableUpgradeableWithExpiry is Initializable, ContextUpgradeable {
    address private _owner;
    uint256 private _deployTimestamp;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        _deployTimestamp = block.timestamp;
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
    function renounceOwnership() external virtual onlyOwner {
        _renounceOwnership();
    }

        /**
     * @dev Get the timestamp of ownership expiry.
     * @return The timestamp of ownership expiry.
     */
    function getOwnershipExpiryTimestamp() public view returns (uint256) {
       return _deployTimestamp + 52 weeks;
    }

    /**
     * @dev Check if the contract ownership is expired.
     * @return True if the contract ownership is expired.
     */
    function isOwnershipExpired() public view returns (bool) {
       return block.timestamp > getOwnershipExpiryTimestamp();
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called after ownership is expired.
     */
    function renounceOwnershipAfterExpiry() external {
        require(isOwnershipExpired(), "Ownership not yet expired");
        _renounceOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _renounceOwnership() private {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    uint256[49] private __gap;
}


// File contracts/Peggy.sol










// This is used purely to avoid stack too deep errors
// represents everything about a given validator set
struct ValsetArgs {
  // the validators in this set, represented by an Ethereum address
  address[] validators;
  // the powers of the given validators in the same order as above
  uint256[] powers;
  // the nonce of this validator set
  uint256 valsetNonce;
  // the reward amount denominated in the below reward token, can be
  // set to zero
  uint256 rewardAmount;
  // the reward token, should be set to the zero address if not being used
  address rewardToken;
}

// Don't change the order of state for working upgrades.
// AND BE AWARE OF INHERITANCE VARIABLES!
// Inherited contracts contain storage slots and must be accounted for in any upgrades
// always test an exact upgrade on testnet and localhost before mainnet upgrades.
contract Peggy is Initializable, OwnableUpgradeableWithExpiry, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // These are updated often
  bytes32 public state_lastValsetCheckpoint;
  mapping(address => uint256) public state_lastBatchNonces;
  mapping(bytes32 => uint256) public state_invalidationMapping;
  uint256 public state_lastValsetNonce = 0;
  uint256 public state_lastEventNonce = 0;

  // These are set once at initialization
  bytes32 public state_peggyId;
  uint256 public state_powerThreshold;

  // TransactionBatchExecutedEvent and SendToCosmosEvent both include the field _eventNonce.
  // This is incremented every time one of these events is emitted. It is checked by the
  // Cosmos module to ensure that all events are received in order, and that none are lost.
  //
  // ValsetUpdatedEvent does not include the field _eventNonce because it is never submitted to the Cosmos
  // module. It is purely for the use of relayers to allow them to successfully submit batches.
  event TransactionBatchExecutedEvent(
    uint256 indexed _batchNonce,
    address indexed _token,
    uint256 _eventNonce
  );
  event SendToCosmosEvent(
    address indexed _tokenContract,
    address indexed _sender,
    bytes32 indexed _destination,
    uint256 _amount,
    uint256 _eventNonce
  );
  event ERC20DeployedEvent(
    // TODO(xlab): _cosmosDenom can be represented as bytes32 to allow indexing
    string _cosmosDenom,
    address indexed _tokenContract,
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _eventNonce
  );
  event ValsetUpdatedEvent(
    uint256 indexed _newValsetNonce,
    uint256 _eventNonce,
    uint256 _rewardAmount,
    address _rewardToken,
    address[] _validators,
    uint256[] _powers
  );

  function initialize(
    // A unique identifier for this peggy instance to use in signatures
    bytes32 _peggyId,
    // How much voting power is needed to approve operations
    uint256 _powerThreshold,
    // The validator set, not in valset args format since many of it's
    // arguments would never be used in this case
    address[] calldata _validators,
    uint256[] memory _powers
  ) external initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
    // CHECKS

    // Check that validators, powers, and signatures (v,r,s) set is well-formed
    require(
      _validators.length == _powers.length,
      "Malformed current validator set"
    );

    // Check cumulative power to ensure the contract has sufficient power to actually
    // pass a vote
    uint256 cumulativePower = 0;
    for (uint256 i = 0; i < _powers.length; i++) {
      cumulativePower = cumulativePower + _powers[i];
      if (cumulativePower > _powerThreshold) {
        break;
      }
    }

    require(
      cumulativePower > _powerThreshold,
      "Submitted validator set signatures do not have enough power."
    );

    ValsetArgs memory _valset;
    _valset = ValsetArgs(_validators, _powers, 0, 0, address(0));

    bytes32 newCheckpoint = makeCheckpoint(_valset, _peggyId);

    // ACTIONS

    state_peggyId = _peggyId;
    state_powerThreshold = _powerThreshold;
    state_lastValsetCheckpoint = newCheckpoint;
    state_lastEventNonce = state_lastEventNonce + 1;
    // LOGS

    emit ValsetUpdatedEvent(
      state_lastValsetNonce,
      state_lastEventNonce,
      0,
      address(0),
      _validators,
      _powers
    );
  }

  function lastBatchNonce(address _erc20Address) public view returns (uint256) {
    return state_lastBatchNonces[_erc20Address];
  }

  // Utility function to verify geth style signatures
  function verifySig(
    address _signer,
    bytes32 _theHash,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) private pure returns (bool) {
    bytes32 messageDigest =
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _theHash));
    return _signer == ecrecover(messageDigest, _v, _r, _s);
  }

  // Make a new checkpoint from the supplied validator set
  // A checkpoint is a hash of all relevant information about the valset. This is stored by the contract,
  // instead of storing the information directly. This saves on storage and gas.
  // The format of the checkpoint is:
  // h(peggyId, "checkpoint", valsetNonce, validators[], powers[])
  // Where h is the keccak256 hash function.
  // The validator powers must be decreasing or equal. This is important for checking the signatures on the
  // next valset, since it allows the caller to stop verifying signatures once a quorum of signatures have been verified.
  function makeCheckpoint(ValsetArgs memory _valsetArgs, bytes32 _peggyId)
    private
    pure
    returns (bytes32)
  {
    // bytes32 encoding of the string "checkpoint"
    bytes32 methodName =
      0x636865636b706f696e7400000000000000000000000000000000000000000000;

    bytes32 checkpoint =
      keccak256(
        abi.encode(
          _peggyId,
          methodName,
          _valsetArgs.valsetNonce,
          _valsetArgs.validators,
          _valsetArgs.powers,
          _valsetArgs.rewardAmount,
          _valsetArgs.rewardToken
        )
      );
    return checkpoint;
  }

  function checkValidatorSignatures(
    // The current validator set and their powers
    address[] memory _currentValidators,
    uint256[] memory _currentPowers,
    // The current validator's signatures
    uint8[] memory _v,
    bytes32[] memory _r,
    bytes32[] memory _s,
    // This is what we are checking they have signed
    bytes32 _theHash,
    uint256 _powerThreshold
  ) private pure {
    uint256 cumulativePower = 0;

    for (uint256 i = 0; i < _currentValidators.length; i++) {
      // If v is set to 0, this signifies that it was not possible to get a signature from this validator and we skip evaluation
      // (In a valid signature, it is either 27 or 28)
      if (_v[i] != 0) {
        // Check that the current validator has signed off on the hash
        require(
          verifySig(_currentValidators[i], _theHash, _v[i], _r[i], _s[i]),
          "Validator signature does not match."
        );

        // Sum up cumulative power
        cumulativePower = cumulativePower + _currentPowers[i];

        // Break early to avoid wasting gas
        if (cumulativePower > _powerThreshold) {
          break;
        }
      }
    }

    // Check that there was enough power
    require(
      cumulativePower > _powerThreshold,
      "Submitted validator set signatures do not have enough power."
    );
    // Success
  }

  // This updates the valset by checking that the validators in the current valset have signed off on the
  // new valset. The signatures supplied are the signatures of the current valset over the checkpoint hash
  // generated from the new valset.
  // Anyone can call this function, but they must supply valid signatures of state_powerThreshold of the current valset over
  // the new valset.
  function updateValset(
    // The new version of the validator set
    ValsetArgs memory _newValset,
    // The current validators that approve the change
    ValsetArgs memory _currentValset,
    // These are arrays of the parts of the current validator's signatures
    uint8[] memory _v,
    bytes32[] memory _r,
    bytes32[] memory _s
  ) external whenNotPaused {
    // CHECKS

    // Check that the valset nonce is greater than the old one
    require(
      _newValset.valsetNonce > _currentValset.valsetNonce,
      "New valset nonce must be greater than the current nonce"
    );

    // Check that new validators and powers set is well-formed
    require(
      _newValset.validators.length == _newValset.powers.length,
      "Malformed new validator set"
    );

    // Check that current validators, powers, and signatures (v,r,s) set is well-formed
    require(
      _currentValset.validators.length == _currentValset.powers.length &&
        _currentValset.validators.length == _v.length &&
        _currentValset.validators.length == _r.length &&
        _currentValset.validators.length == _s.length,
      "Malformed current validator set"
    );

    // Check that the supplied current validator set matches the saved checkpoint
    require(
      makeCheckpoint(_currentValset, state_peggyId) ==
        state_lastValsetCheckpoint,
      "Supplied current validators and powers do not match checkpoint."
    );

    // Check that enough current validators have signed off on the new validator set
    bytes32 newCheckpoint = makeCheckpoint(_newValset, state_peggyId);
    checkValidatorSignatures(
      _currentValset.validators,
      _currentValset.powers,
      _v,
      _r,
      _s,
      newCheckpoint,
      state_powerThreshold
    );

    // ACTIONS

    // Stored to be used next time to validate that the valset
    // supplied by the caller is correct.
    state_lastValsetCheckpoint = newCheckpoint;

    // Store new nonce
    state_lastValsetNonce = _newValset.valsetNonce;

    // Send submission reward to msg.sender if reward token is a valid value
    if (_newValset.rewardToken != address(0) && _newValset.rewardAmount != 0) {
      IERC20(_newValset.rewardToken).safeTransfer(
        msg.sender,
        _newValset.rewardAmount
      );
    }

    // LOGS
    state_lastEventNonce = state_lastEventNonce + 1;
    emit ValsetUpdatedEvent(
      _newValset.valsetNonce,
      state_lastEventNonce,
      _newValset.rewardAmount,
      _newValset.rewardToken,
      _newValset.validators,
      _newValset.powers
    );
  }

  // submitBatch processes a batch of Cosmos -> Ethereum transactions by sending the tokens in the transactions
  // to the destination addresses. It is approved by the current Cosmos validator set.
  // Anyone can call this function, but they must supply valid signatures of state_powerThreshold of the current valset over
  // the batch.
  function submitBatch(
    // The validators that approve the batch
    ValsetArgs memory _currentValset,
    // These are arrays of the parts of the validators signatures
    uint8[] memory _v,
    bytes32[] memory _r,
    bytes32[] memory _s,
    // The batch of transactions
    uint256[] memory _amounts,
    address[] memory _destinations,
    uint256[] memory _fees,
    uint256 _batchNonce,
    address _tokenContract,
    // a block height beyond which this batch is not valid
    // used to provide a fee-free timeout
    uint256 _batchTimeout
  ) external nonReentrant whenNotPaused {
    // CHECKS scoped to reduce stack depth
    {
      // Check that the batch nonce is higher than the last nonce for this token
      require(
        state_lastBatchNonces[_tokenContract] < _batchNonce,
        "New batch nonce must be greater than the current nonce"
      );

      // Check that the block height is less than the timeout height
      require(
        block.number < _batchTimeout,
        "Batch timeout must be greater than the current block height"
      );

      // Check that current validators, powers, and signatures (v,r,s) set is well-formed
      require(
        _currentValset.validators.length == _currentValset.powers.length &&
          _currentValset.validators.length == _v.length &&
          _currentValset.validators.length == _r.length &&
          _currentValset.validators.length == _s.length,
        "Malformed current validator set"
      );

      // Check that the supplied current validator set matches the saved checkpoint
      require(
        makeCheckpoint(_currentValset, state_peggyId) ==
          state_lastValsetCheckpoint,
        "Supplied current validators and powers do not match checkpoint."
      );

      // Check that the transaction batch is well-formed
      require(
        _amounts.length == _destinations.length &&
          _amounts.length == _fees.length,
        "Malformed batch of transactions"
      );

      // Check that enough current validators have signed off on the transaction batch and valset
      checkValidatorSignatures(
        _currentValset.validators,
        _currentValset.powers,
        _v,
        _r,
        _s,
        // Get hash of the transaction batch and checkpoint
        keccak256(
          abi.encode(
            state_peggyId,
            // bytes32 encoding of "transactionBatch"
            0x7472616e73616374696f6e426174636800000000000000000000000000000000,
            _amounts,
            _destinations,
            _fees,
            _batchNonce,
            _tokenContract,
            _batchTimeout
          )
        ),
        state_powerThreshold
      );

      // ACTIONS

      // Store batch nonce
      state_lastBatchNonces[_tokenContract] = _batchNonce;

      {
        // Send transaction amounts to destinations
        uint256 totalFee;
        for (uint256 i = 0; i < _amounts.length; i++) {
          IERC20(_tokenContract).safeTransfer(_destinations[i], _amounts[i]);
          totalFee = totalFee + _fees[i];
        }

        if (totalFee > 0) {
          // Send transaction fees to msg.sender
          IERC20(_tokenContract).safeTransfer(msg.sender, totalFee);
        }
      }
    }

    // LOGS scoped to reduce stack depth
    {
      state_lastEventNonce = state_lastEventNonce + 1;
      emit TransactionBatchExecutedEvent(
        _batchNonce,
        _tokenContract,
        state_lastEventNonce
      );
    }
  }

  function sendToCosmos(
    address _tokenContract,
    bytes32 _destination,
    uint256 _amount
  ) external whenNotPaused nonReentrant {
    IERC20(_tokenContract).safeTransferFrom(msg.sender, address(this), _amount);
    state_lastEventNonce = state_lastEventNonce + 1;
    emit SendToCosmosEvent(
      _tokenContract,
      msg.sender,
      _destination,
      _amount,
      state_lastEventNonce
    );
  }

  function deployERC20(
    string calldata _cosmosDenom,
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals
  ) external {
    // Deploy an ERC20 with entire supply granted to Peggy.sol
    CosmosERC20 erc20 =
      new CosmosERC20(address(this), _name, _symbol, _decimals);

    // Fire an event to let the Cosmos module know
    state_lastEventNonce = state_lastEventNonce + 1;
    emit ERC20DeployedEvent(
      _cosmosDenom,
      address(erc20),
      _name,
      _symbol,
      _decimals,
      state_lastEventNonce
    );
  }

  function emergencyPause() external onlyOwner {
    _pause();
  }

  function emergencyUnpause() external onlyOwner {
    _unpause();
  }
}