// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AdminControlled is Initializable {
    address public admin;
    uint public paused;

    function __AdminControlled_init(address _admin, uint flags) internal onlyInitializing {
        admin = _admin;
        paused = flags;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier pausable(uint flag) {
        require((paused & flag) == 0 || msg.sender == admin);
        _;
    }

    function adminPause(uint flags) public onlyAdmin {
        paused = flags;
    }

    function adminSstore(uint key, uint value) public onlyAdmin {
        assembly {
            sstore(key, value)
        }
    }

    function adminSstoreWithMask(
        uint key,
        uint value,
        uint mask
    ) public onlyAdmin {
        assembly {
            let oldval := sload(key)
            sstore(key, xor(and(xor(value, oldval), mask), oldval))
        }
    }

    function adminSendEth(address payable destination, uint amount) public onlyAdmin {
        destination.transfer(amount);
    }

    function adminReceiveEth() public payable onlyAdmin {}

    function adminDelegatecall(address target, bytes memory data) public payable onlyAdmin returns (bytes memory) {
        (bool success, bytes memory rdata) = target.delegatecall(data);
        require(success);
        return rdata;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) internal _balances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(sender, recipient, amount);
        
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./AdminControlled.sol";
import "./ERC20Upgradeable.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/ITreasury.sol";

// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once VOTE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

contract JetStaking is Initializable, AdminControlled, ERC20Upgradeable, IStaking {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant BP = 10;
    uint256 public constant DENOMINATOR = 10000;

    address public auroraToken;
    address public treasury;
    uint256 public totalStaked;
    uint256 public seasonAmount;
    uint256 public seasonDuration;
    uint256 public startTime;
    uint256 public decayGracePeriod;
    uint256 public burnGracePeriod;
    uint256 public minimunAuroraStake;
    uint256 public totalFor0Seasons;

    struct Deposit {
        uint256 amount;
        uint256 startSeason;
        uint256 endSeason;
        uint256 rewardWeight;
        uint256 voteWeight;
    }

    struct Stream {
        uint256 auroraAmountTotal;
        uint256 rewardsTokenAmount;
        uint256 height;
        uint256 lastAuroraClaimed;
        bool initialized;
        bool blacklisted;
        address rewardsToken;
        address tokenOwner;
        uint256[] rewardsScheduleKeys;
        mapping (uint256 => uint256) rewardsSchedule;
        mapping (address => mapping (uint256 => uint256)) lastRewardClaims;
    }

    struct Season {
        uint256 startSeason;
        uint256 applicationStart;
        uint256 applicationEnd;
        uint256 applicationVotingStart;
        uint256 applicationVotingEnd; 
        uint256 startVoting;
        uint256 endVoting;
        uint256 endSeason;
        uint256 decayStart;
    }
    
    Stream[] public streams;
    Season[] public seasons;

    mapping (address => bool) public whitelistedContracts;
    mapping (address => mapping (uint256 => Deposit)) public deposits;
    mapping (address => uint256) public depositIds;
    mapping (address => bool) public supportedRewardTokens;
    mapping (uint256 => uint256) public rewardWeights;
    mapping (uint256 => uint256) public voteWeights;
    mapping (uint256 => uint256) public claimedVoteTokens;
    mapping (address => mapping (uint256 => uint256)) public userClaimedVoteTokens;
    mapping (address => mapping (uint256 => uint256)) public userUsedVoteTokens;
    mapping (uint256 => uint256) public totalWeightedDepositedAmounts;
    mapping (address => uint256) public rewardsPool;

    event Claimed(address indexed user, address indexed token, uint256 amount, uint256 timestamp);
    event StreamAdded(address indexed rewardsToken, address indexed tokenOwner, uint256 auroraAmountTotal, uint256 rewardsTokenAmount, uint256 height, uint256 lastAuroraClaimed);
    event StreamRemoved(uint256 _index);
    event Deposited(address indexed _user, uint256 _amount, uint256 _seasonsAmount);
    event Unstaked(address indexed _user, uint256 _amount);
    event DepositedToRewardPool(address indexed _user, uint256 _amount, uint256 _index);   
    event AddedToRewardPool(address indexed _user, uint256 _amount, uint256 _index);
    event RemovedFromRewardPool(address indexed _user, uint256 _amount, uint256 _index);
    event VotesTransfered(address indexed _sender, address indexed _recipient, uint256 _amount);

    
    /// @notice initializator for upgradeable contract
    /// @param _name name for Vote token
    /// @param _symbol symbol for Vote token
    /// @param _seasonAmount season amount for staking period
    /// @param _seasonDuration timestamp duration for one season 
    /// @param _startTime timestamp for first season starts
    /// @param _auroraToken staking token, aslo rewards token
    /// @param _treasury treasury contract address for the reward tokens
    /// @param _admin admin of the contract
    /// @param _flags flags determine is contract on paused or unpaused
    /// @param _decayGracePeriod period for each season in which vote tokes don't decay
    /// @param _burnGracePeriod period for each season after which admin is able to burn unused vote tokens
    function initialize(
        string memory _name, 
        string memory _symbol, 
        uint256 _seasonAmount, 
        uint256 _seasonDuration,
        uint256 _startTime,
        address _auroraToken,
        address _treasury,
        address _admin,
        uint256 _flags,
        uint256 _decayGracePeriod,
        uint256 _burnGracePeriod
    ) public initializer {

        __ERC20_init(_name, _symbol);

        require(_admin != address(0));
        __AdminControlled_init(_admin, _flags);

        require(_startTime > block.timestamp);
        require(_seasonDuration > 0);
        require(_decayGracePeriod < _seasonDuration);
        require(_burnGracePeriod < _seasonDuration);
        require(_auroraToken != address(0));
        require(_treasury != address(0));

        startTime = _startTime;
        seasonAmount = _seasonAmount;
        seasonDuration = _seasonDuration;
        auroraToken = _auroraToken;
        treasury = _treasury;
        decayGracePeriod = _decayGracePeriod;
        burnGracePeriod = _burnGracePeriod;

        initSeasons(_seasonDuration);
    }

    
    /// @notice Initialize N seasons based on season duration
    /// @dev each new season strarts from start + seasonDuration + 1 seconds 
    /// @param _seasonDuration timestamp duration for one season 
    function initSeasons(uint256 _seasonDuration) private {

        uint256 start = block.timestamp;

        for (uint i = 0; i < seasonAmount; i++) {
            
            uint256 idx = seasons.length;
            seasons.push();
            Season storage season = seasons[idx];

            season.startSeason = start;
            season.applicationStart = start;
            season.applicationEnd = start + _seasonDuration;
            season.applicationVotingStart = start;
            season.applicationVotingEnd = start + _seasonDuration;
            season.startVoting = start;
            season.endVoting = start + _seasonDuration;
            season.endSeason = start + _seasonDuration;
            season.decayStart = start + decayGracePeriod;

            start += _seasonDuration + 1;
        }
    }
    
    
    /// @notice add new season after last existing season
    /// @dev restricted for the admin only
    /// @param _startSeason timestamp which determines starting point for the season
    /// @param _applicationStart timestamp which determines starting point for the application
    /// @param _applicationEnd timestamp which determines ending point for the application
    /// @param _applicationVotingStart timestamp which determines starting point for the application voting during the season
    /// @param _applicationVotingEnd timestamp which determines ending point for the application voting during the season
    /// @param _startVoting timestamp which determines starting point for the voting during the season
    /// @param _endVoting timestamp which determines ending point for the voting during the season
    /// @param _endSeason timestamp which determines ending point for the season
    /// @param _decayStart timestamp period for each season after which vote tokes decay
    function addSeason(
        uint256 _startSeason,
        uint256 _applicationStart,
        uint256 _applicationEnd,
        uint256 _applicationVotingStart,
        uint256 _applicationVotingEnd,
        uint256 _startVoting,
        uint256 _endVoting,
        uint256 _endSeason,
        uint256 _decayStart
    ) external onlyAdmin {

        validateSeasonParams(
            _startSeason,
            _applicationStart,
            _applicationEnd,
            _applicationVotingStart,
            _applicationVotingEnd,
            _startVoting,
            _endVoting,
            _endSeason,
            _decayStart
        );

        uint256 idx = seasons.length;
        seasons.push();

        Season storage season = seasons[idx];
        season.startSeason = _startSeason;
        season.applicationStart = _applicationStart;
        season.applicationEnd = _applicationEnd;
        season.applicationVotingStart = _applicationVotingStart;
        season.applicationVotingEnd = _applicationVotingEnd;
        season.startVoting = _startVoting;
        season.endVoting = _endVoting;
        season.endSeason = _endSeason;
        season.decayStart = _decayStart;
    }

    
    /// @notice sets minimal amount of AURORA that is allowed for staking
    /// @dev restricted for the admin only
    /// @param _minimunAuroraStake actual number of minimal allowed AURORA
    function setMimunAuroraStake(uint256 _minimunAuroraStake) external onlyAdmin {
        minimunAuroraStake = _minimunAuroraStake;
    }

    
    /// @notice updates a season by its index
    /// @dev restricted for the admin only
    /// @param _startSeason timestamp which determines starting point for the season
    /// @param _applicationStart timestamp which determines starting point for the application
    /// @param _applicationEnd timestamp which determines ending point for the application
    /// @param _applicationVotingStart timestamp which determines starting point for the application voting during the season
    /// @param _applicationVotingEnd timestamp which determines ending point for the application voting during the season
    /// @param _startVoting timestamp which determines starting point for the voting during the season
    /// @param _endVoting timestamp which determines ending point for the voting during the season
    /// @param _endSeason timestamp which determines ending point for the season
    /// @param _decayStart timestamp period for each season after which vote tokes decay
    /// @param _index index of the configured season
    function configureSeason(
        uint256 _startSeason,
        uint256 _applicationStart,
        uint256 _applicationEnd,
        uint256 _applicationVotingStart,
        uint256 _applicationVotingEnd,
        uint256 _startVoting,
        uint256 _endVoting,
        uint256 _endSeason,
        uint256 _decayStart,
        uint256 _index
    ) external onlyAdmin {
        require(seasons.length > _index, "Out of bound index");
        require(_index != currentSeason(), "Invalid season index");

        validateSeasonParams(
            _startSeason,
            _applicationStart,
            _applicationEnd,
            _applicationVotingStart,
            _applicationVotingEnd,
            _startVoting,
            _endVoting,
            _endSeason,
            _decayStart
        );

        Season storage season = seasons[_index];
        season.startSeason = _startSeason;
        season.applicationStart = _applicationStart;
        season.applicationEnd = _applicationEnd;
        season.applicationVotingStart = _applicationVotingStart;
        season.applicationVotingEnd = _applicationVotingEnd;
        season.startVoting = _startVoting;
        season.endVoting = _endVoting;
        season.endSeason = _endSeason;
        season.decayStart = _decayStart;
    }

    
    /// @notice validates season params
    /// @dev private function
    /// @param _startSeason timestamp which determines starting point for the season
    /// @param _applicationStart timestamp which determines starting point for the application
    /// @param _applicationEnd timestamp which determines ending point for the application
    /// @param _applicationVotingStart timestamp which determines starting point for the application voting during the season
    /// @param _applicationVotingEnd timestamp which determines ending point for the application voting during the season
    /// @param _startVoting timestamp which determines starting point for the voting during the season
    /// @param _endVoting timestamp which determines ending point for the voting during the season
    /// @param _endSeason timestamp which determines ending point for the season
    /// @param _decayStart timestamp period for each season after which vote tokes decay
    function validateSeasonParams(
        uint256 _startSeason,
        uint256 _applicationStart,
        uint256 _applicationEnd,
        uint256 _applicationVotingStart,
        uint256 _applicationVotingEnd,
        uint256 _startVoting,
        uint256 _endVoting,
        uint256 _endSeason,
        uint256 _decayStart
    ) pure private {
        require(_startSeason < _endSeason);
        require(_startVoting < _endVoting);
        require(_applicationStart < _applicationEnd);
        require(_applicationVotingStart < _applicationVotingEnd);
        require(_startSeason <= _applicationStart);
        require(_startSeason <= _applicationVotingStart);
        require(_startSeason <= _startVoting);
        require(_startSeason <= _decayStart);
        require(_startVoting <= _decayStart);
        require(_endSeason >= _endVoting);
        require(_endSeason >= _decayStart);
        require(_endSeason >= _applicationVotingEnd);
    }

    
    /// @notice adds address to whitelist. Whitelisted addreses only are allowed to call transferFrom function 
    /// @dev restricted for the admin only
    /// @param _address address to be added to whitelist
    /// @param _allowance flag determines allowance for the address
    function whitelistContract(address _address, bool _allowance) public onlyAdmin {
        require(_address != address(0), "Zero address");
        whitelistedContracts[_address] = _allowance;
    }

    
    /// @notice batch adding address to whitelist. Whitelisted addreses only are allowed to call transferFrom function 
    /// @dev restricted for the admin only
    /// @param _addresses addresses to be added to whitelist
    /// @param _allowances flag determines allowances for the addresses
    function batchWhitelistContract(address[] memory _addresses, bool[] memory _allowances) external onlyAdmin {
        require(_addresses.length == _allowances.length, "Invalid length");

        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Zero address");
            whitelistContract(_addresses[i], _allowances[i]);
        }  
    }

    
    /// @notice updates decay grace perion
    /// @dev restricted for the admin only
    /// @param _decayGracePeriod period for each season in which vote tokes don't decay
    function updateDecayGracePeriod(uint _decayGracePeriod) external onlyAdmin {
        require(_decayGracePeriod < seasonDuration);
        decayGracePeriod = _decayGracePeriod;
    }

    
    /// @notice updates seasons amount
    /// @dev restricted for the admin only
    /// @param _seasonAmount season amount for staking period
    function updateSeasonAmount(uint _seasonAmount) external onlyAdmin {
        seasonAmount = _seasonAmount;
    }

    
    /// @notice updates treasury account
    /// @dev restricted for the admin only
    /// @param _treasury treasury contract address for the reward tokens
    function updateTreasury(address _treasury) external onlyAdmin {
        require(_treasury != address(0), "Zero address");
        treasury = _treasury;
    }

    
    /// @notice updates aurora token
    /// @dev restricted for the admin only
    /// @param _auroraToken staking token, aslo rewards token
    function updateAuroraToken(address _auroraToken) external onlyAdmin {
        require(_auroraToken != address(0), "Zero address");
        auroraToken = _auroraToken;
    }

    
    /// @notice updates season duration
    /// @dev restricted for the admin only
    /// @param _newDuration timestamp duration for one season 
    function updateSeasonDuration(uint256 _newDuration) external onlyAdmin {
        seasonDuration = _newDuration;
    }

    
    /// @notice updates reward weigths for seasons
    /// @dev restricted for the admin only
    /// @param _keys array of the seasons numbers
    /// @param _values array of the seasons weigths
    function updateRewardWeight(uint256[] memory _keys, uint256[] memory _values) external onlyAdmin {
        require(_keys.length == _values.length, "Invalid length");

        for (uint i = 0; i < _keys.length; i++) {
            require(_keys[i] <= seasonAmount, "Invalid params");
            rewardWeights[_keys[i]] = _values[i];
        }
    }

    /// @notice updates vote weigths for seasons
    /// @dev restricted for the admin only
    /// @param _keys array of the seasons numbers
    /// @param _values array of the seasons weigths
    function updateVoteWeight(uint256[] memory _keys, uint256[] memory _values) external onlyAdmin {
        require(_keys.length == _values.length, "Invalid length");

        for (uint i = 0; i < _keys.length; i++) {
            require(_keys[i] <= seasonAmount, "Invalid params");
            voteWeights[_keys[i]] = _values[i];
        }
    }

    /// @notice adds new steam that determines rules for rewards allocation
    /// @dev restricted for the admin only
    /// @param _rewardsToken token that will be rewarded to users based on users stakes
    /// @param _tokenOwner project's tokens are expected to be received from 
    /// @param _auroraAmountTotal deposited by Admin (AURORA should be transferred through transferFrom method of AURORA ERC-20)
    /// @param _rewardsTokenAmount the upper amount of the token, that should be deposited by the token owne
    /// @param _height timestamp until which this option is active
    /// @param _seasonIndexes piecewise-linear dependency of the decay of the rewards token on the staking contract, indexed
    /// @param _seasonRewards piecewise-linear dependency of the decay of the rewards token on the staking contract, values
    function addStream(
        address _rewardsToken, 
        address _tokenOwner, 
        uint256 _auroraAmountTotal, 
        uint256 _rewardsTokenAmount, 
        uint256 _height,
        uint256[] memory _seasonIndexes, 
        uint256[] memory _seasonRewards
    ) 
        external 
        onlyAdmin 
    {
        require(_seasonIndexes.length == _seasonRewards.length);
        require(!supportedRewardTokens[_rewardsToken], "Token already added");
        supportedRewardTokens[_rewardsToken] = true;

        uint256 idx = streams.length;
        streams.push();

        Stream storage stream = streams[idx];
        stream.rewardsToken = _rewardsToken;
        stream.tokenOwner = _tokenOwner;
        stream.auroraAmountTotal = _auroraAmountTotal;
        stream.rewardsTokenAmount = _rewardsTokenAmount;
        stream.height = _height;
        Season memory season = seasons[_seasonIndexes[0]];
        stream.lastAuroraClaimed = season.startSeason;

        uint256 rewardsTotalPercent;
        
        for (uint i = 0; i < _seasonIndexes.length; i++) {
            require(_seasonRewards[i] > 0);
            stream.rewardsSchedule[_seasonIndexes[i]] = _seasonRewards[i];
            stream.rewardsScheduleKeys.push(_seasonIndexes[i]);
            rewardsTotalPercent += _seasonRewards[i];
        }

        require(rewardsTotalPercent == 10000, "Invalid total percent");

        IERC20Upgradeable(auroraToken).safeTransferFrom(msg.sender, treasury, _auroraAmountTotal);
        
        emit StreamAdded(
            stream.rewardsToken,
            stream.tokenOwner,
            stream.auroraAmountTotal,
            stream.rewardsTokenAmount,
            stream.height,
            stream.lastAuroraClaimed
        );
    }

    /// @notice removes stream by its index
    /// @dev restricted for the admin only. Copies last stream into stream with id = _index, removes last element from sreams array
    /// @param _index the index of the stream to remove
    function removeStream(uint256 _index) external onlyAdmin {
        require(streams.length > _index, "Out of bound index");

        supportedRewardTokens[streams[_index].rewardsToken] = false;
        
        Stream storage last = streams[streams.length - 1];
        Stream storage operated = streams[_index];

        operated.rewardsToken = last.rewardsToken;
        operated.tokenOwner = last.tokenOwner;
        operated.auroraAmountTotal = last.auroraAmountTotal;
        operated.rewardsTokenAmount = last.rewardsTokenAmount;
        operated.height = last.height;
        operated.lastAuroraClaimed = last.lastAuroraClaimed;

        for (uint i = 0; i < operated.rewardsScheduleKeys.length; i++) {
            operated.rewardsSchedule[operated.rewardsScheduleKeys[i]] = 0;
        }

        operated.rewardsScheduleKeys = new uint256[](last.rewardsScheduleKeys.length);

        for (uint i = 0; i < last.rewardsScheduleKeys.length; i++) {
            operated.rewardsSchedule[last.rewardsScheduleKeys[i]] = last.rewardsSchedule[last.rewardsScheduleKeys[i]];
            operated.rewardsScheduleKeys[i] = last.rewardsScheduleKeys[i];
        }
    
        streams.pop();

        emit StreamRemoved(
            _index
        );
    }

    /// @notice implements the functionality to send the AURORA tokens to the staking of the particular user
    /// @dev can by paused by admin. Initializes last rewerd claim timestamp for each existing stream as current block timestamp
    /// @param _amount amount of AURORA to be deposited for user. Minimal deposit is 5 AURORA
    /// @param _user users address
    function depositOnBehalfOfAnotherUser(uint256 _amount, address _user) external pausable(1) {
        require(_amount >= minimunAuroraStake * (10 ** decimals()), "Amount < 5");

        if (deposits[_user][0].amount == 0) {
            deposits[_user][0].rewardWeight = rewardWeights[0];
            deposits[_user][0].voteWeight = voteWeights[0];
        }
        
        deposits[_user][0].amount += _amount;
        totalWeightedDepositedAmounts[0] += _amount * rewardWeights[0];

        for (uint i = 0; i < streams.length; i++) {
            streams[i].lastRewardClaims[_user][0] = block.timestamp;
        }

        totalStaked += _amount;
        IERC20Upgradeable(auroraToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(_user, _amount, 0);
    }
    
    /// @notice implements the functionality to send the AURORA tokens to the staking by AURORA holders
    /// @dev can by paused by admin
    /// @param _amount amount of AURORA to be deposited for user. Minimal deposit is 5 AURORA
    /// @param _seasonsAmount determines amount of seasons the stake applicable for, Should be between 0 and 24 seasons
    function stake(uint256 _amount, uint256 _seasonsAmount) external pausable(1) {
        require(_seasonsAmount <= seasonAmount, "Error:seasons");
        require(_amount >= minimunAuroraStake * (10 ** decimals()), "Amount < 5");

        if (_seasonsAmount == 0) {

            if (deposits[msg.sender][0].amount == 0) {

                deposits[msg.sender][0].amount += _amount;
                deposits[msg.sender][0].rewardWeight = rewardWeights[0];
                deposits[msg.sender][0].voteWeight = voteWeights[0];

                for (uint i = 0; i < streams.length; i++) {
                    streams[i].lastRewardClaims[msg.sender][0] = block.timestamp;
                }

                totalFor0Seasons += _amount;

            } else {

                deposits[msg.sender][0].amount += _amount;
                totalFor0Seasons += _amount;

            }
        } else {

            depositIds[msg.sender]++;
            deposits[msg.sender][depositIds[msg.sender]].amount = _amount;
            deposits[msg.sender][depositIds[msg.sender]].startSeason = currentSeason() + 1;
            deposits[msg.sender][depositIds[msg.sender]].endSeason = currentSeason() + _seasonsAmount;
            deposits[msg.sender][depositIds[msg.sender]].rewardWeight = _seasonsAmount > 7 ? rewardWeights[7] : rewardWeights[_seasonsAmount];
            deposits[msg.sender][depositIds[msg.sender]].voteWeight = _seasonsAmount > 7 ? voteWeights[7] : voteWeights[_seasonsAmount];
            
            for (uint i = 0; i < streams.length; i++) {
                streams[i].lastRewardClaims[msg.sender][depositIds[msg.sender]] = block.timestamp + seasonDuration;
            }

            for (uint i = currentSeason() + 1; i <= currentSeason() + _seasonsAmount; i++) {
                totalWeightedDepositedAmounts[i] += _amount * deposits[msg.sender][depositIds[msg.sender]].rewardWeight;
            }
            totalStaked += _amount;
        }

        IERC20Upgradeable(auroraToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount, _seasonsAmount);
    }  

    /// @notice implements the functionality to unstake the AURORA tokens by users. Claims available VOTE tokens and rewards
    /// @dev can by paused by admin
    /// @param _depositId determines deposit id for unstaking from
    function unstake(uint256 _depositId) external pausable(1) {
        Deposit storage deposit = deposits[msg.sender][_depositId];
        require(currentSeason() > deposit.endSeason, "Locked");

        uint256 depositAmount = deposit.amount;

        if (deposit.endSeason - deposit.startSeason > 0) {
            claimVoteInternal(_depositId, msg.sender);
        }

        for (uint256 i = 0; i < streams.length; i++) {
            claimRewards(_depositId, i, msg.sender);
        }

        if (_depositId == 0) {
            totalFor0Seasons -= depositAmount;
        } else {
            totalStaked -= depositAmount;
        }

        deposit.amount = 0;
        deposit.rewardWeight = 0;
        deposit.voteWeight = 0;

        IERC20Upgradeable(auroraToken).safeTransfer(msg.sender, depositAmount);

        emit Unstaked(msg.sender, depositAmount);
    }

    
    /// @notice implements the functionality to claim the VOTE tokens by users.
    /// @dev can by paused by admin. external
    /// @param _depositId determines deposit id for unstaking from
    function claimVote(uint256 _depositId) external pausable(1) {
        claimVoteInternal(_depositId, msg.sender);
    }

    
    /// @notice implements the functionality to claim the VOTE tokens by users.
    /// @dev private
    /// @param _depositId determines deposit id for unstaking from
    /// @param _user address to claim votes to
    function claimVoteInternal(uint256 _depositId, address _user) private {
        Deposit storage deposit = deposits[_user][_depositId];

        require(deposit.amount > 0, "Inactive");

        uint256 amountToPay = (deposit.voteWeight * deposit.amount / BP) - userClaimedVoteTokens[_user][currentSeason()];
        require(amountToPay > 0, "Nothing to claim");

        _mint(_user, amountToPay);

        claimedVoteTokens[currentSeason()] += amountToPay;
        userClaimedVoteTokens[_user][currentSeason()] += amountToPay;

        emit Claimed(_user, address(this), amountToPay, block.timestamp);
    }

    
    /// @notice implements the functionality to claim the reward tokens by users.
    /// @dev private
    /// @param _depositId determines deposit id for unstaking from
    /// @param _index index of the rewards stream
    /// @param _user address to claim votes to
    function claimRewards(uint256 _depositId, uint _index, address _user) public pausable(1) {
        require(!streams[_index].blacklisted, "Blacklisted");
        uint256 totalUserRewardToPay = calculateRewards(_depositId, _index, _user);
        require(totalUserRewardToPay != 0, "Nothing to pay!");

        streams[_index].lastRewardClaims[_user][_depositId] = block.timestamp;
        ITreasury(treasury).payRewards(_user, streams[_index].rewardsToken, totalUserRewardToPay);
        
        emit Claimed(_user, streams[_index].rewardsToken, totalUserRewardToPay, block.timestamp);
    }

    
    /// @notice implements the main logic of calculation rewards per user per stream for specified depositId
    /// @dev can by paused by admin. Calclulates user rewards based on time user being in the seasons
    /// @param _depositId determines deposit id for unstaking from
    /// @param _index index of the rewards stream
    /// @param _user address to claim votes to
    function calculateRewards(uint256 _depositId, uint _index, address _user) public pausable(1) view returns (uint totalUserRewardToPay) {
        require(supportedRewardTokens[streams[_index].rewardsToken], "! supported");
        
        Deposit storage deposit = deposits[_user][_depositId];
        Stream storage stream = streams[_index];

        uint256 lengthOfUserBeingInTheSeasonStartingThePreviousWithdraw;

        // starting points
        uint256 startSeasonIndex = getSeasonByTimestamp(stream.lastRewardClaims[_user][_depositId]);
        uint256 startSeasonEndTimestamp = seasons[startSeasonIndex].endSeason;
        
        // ending points
        uint256 endSeasonIndex = currentSeason();
        uint256 endSeasonStartTimestamp = seasons[endSeasonIndex].startSeason;

        uint256 duration = 0;

        for (uint i = startSeasonIndex; i <= endSeasonIndex; i++) {

            duration = seasons[i].endSeason - seasons[i].startSeason;
            
            if (startSeasonIndex == endSeasonIndex) {

                lengthOfUserBeingInTheSeasonStartingThePreviousWithdraw = block.timestamp - stream.lastRewardClaims[_user][_depositId];
                
            } else {

                if (i == startSeasonIndex) {

                    lengthOfUserBeingInTheSeasonStartingThePreviousWithdraw = startSeasonEndTimestamp - stream.lastRewardClaims[_user][_depositId];

                } else if (i == endSeasonIndex) {

                    lengthOfUserBeingInTheSeasonStartingThePreviousWithdraw = block.timestamp - endSeasonStartTimestamp;

                } else {

                    lengthOfUserBeingInTheSeasonStartingThePreviousWithdraw = duration;
                }
            }

            totalUserRewardToPay += 
                lengthOfUserBeingInTheSeasonStartingThePreviousWithdraw * 
                deposit.amount * 
                (getSeasonByTimestamp(block.timestamp) > deposit.endSeason ? rewardWeights[0] : deposit.rewardWeight) * 
                (stream.rewardsTokenAmount * stream.rewardsSchedule[i] / DENOMINATOR) / 
                duration / 
                ((totalFor0Seasons * rewardWeights[0]) + totalWeightedDepositedAmounts[i]) / BP;
        }
    }

    
    /// @notice implements the main logic of calculation AURORA rewards for token owner specified in the stream
    /// @dev can by paused by admin. Calclulates rewards for stream token owner based on rewards shedule
    /// @param _index index of the rewards stream
    function claimAuroraByTokenOwner(uint256 _index) external pausable(1) {
        Stream storage stream = streams[_index];
        require(!stream.blacklisted, "Blacklisted");
        require(stream.tokenOwner == msg.sender, "! allowed");

        uint256 totalReward = 0;

        for (uint256 i; i < stream.rewardsScheduleKeys.length; i++) {

            if (block.timestamp < seasons[stream.rewardsScheduleKeys[i]].startSeason) {
                break;
            }

            uint256 duration = seasons[stream.rewardsScheduleKeys[i]].endSeason - seasons[stream.rewardsScheduleKeys[i]].startSeason;

            if ((stream.lastAuroraClaimed <= seasons[stream.rewardsScheduleKeys[i]].startSeason) && (block.timestamp >= seasons[stream.rewardsScheduleKeys[i]].endSeason)) {

                uint256 start = seasons[stream.rewardsScheduleKeys[i]].startSeason;
                uint256 end = seasons[stream.rewardsScheduleKeys[i]].endSeason;
                
                totalReward += (stream.auroraAmountTotal * stream.rewardsSchedule[stream.rewardsScheduleKeys[i]] / DENOMINATOR) *
                (end - start) / duration;
        

            } else if ((stream.lastAuroraClaimed <= seasons[stream.rewardsScheduleKeys[i]].startSeason) && (block.timestamp < seasons[stream.rewardsScheduleKeys[i]].endSeason)) {
                
                uint256 start = seasons[stream.rewardsScheduleKeys[i]].startSeason;
                uint256 end = block.timestamp;
                
                totalReward += (stream.auroraAmountTotal * stream.rewardsSchedule[stream.rewardsScheduleKeys[i]] / DENOMINATOR) *
                (end - start) / duration;
            
            
            } else if ((stream.lastAuroraClaimed > seasons[stream.rewardsScheduleKeys[i]].startSeason) && stream.lastAuroraClaimed <= seasons[stream.rewardsScheduleKeys[i]].endSeason) {

                uint256 start = stream.lastAuroraClaimed;
                uint256 end = seasons[stream.rewardsScheduleKeys[i]].endSeason;
                
                totalReward += (stream.auroraAmountTotal * stream.rewardsSchedule[stream.rewardsScheduleKeys[i]] / DENOMINATOR) *
                (end - start) / duration;
     
            }            
        }
        
        stream.lastAuroraClaimed = block.timestamp;
        IERC20Upgradeable(auroraToken).safeTransferFrom(treasury, msg.sender, totalReward);
        emit Claimed(msg.sender, auroraToken, totalReward, block.timestamp);
    }

    
    /// @notice implements deposit tokens on the staking contract from stream token owner
    /// @dev can by paused by admin. Msg.sender should be stream.tokenOwner
    /// @param _index index of the rewards stream
    /// @param _amount of rewerd token to be deposited
    function depositTokensToRewardPool(uint256 _index, uint256 _amount) external pausable(1) {

        Stream storage stream = streams[_index];

        require(_amount > 0, "! allowed");
        require(!stream.initialized, "Initialized");
        require(stream.tokenOwner == msg.sender, "! allowed");
        require(stream.rewardsTokenAmount >= _amount, "Too big amount");
        require(stream.height >= block.timestamp, "! allowed");

        rewardsPool[stream.rewardsToken] += _amount;
        stream.rewardsTokenAmount = _amount;
        stream.initialized = true; 

        IERC20Upgradeable(stream.rewardsToken).safeTransferFrom(msg.sender, treasury, _amount);
        emit DepositedToRewardPool(msg.sender, _amount, _index);   
    }

    function addTokensToRewardPool(uint256 _index, uint256 _amount) external onlyAdmin {

        Stream storage stream = streams[_index];
    
        require(stream.initialized, "! initialized");

        if (stream.blacklisted) {
            stream.blacklisted = false;
        }

        rewardsPool[stream.rewardsToken] += _amount;
        IERC20Upgradeable(stream.rewardsToken).safeTransferFrom(msg.sender, treasury, _amount);
        emit AddedToRewardPool(msg.sender, _amount, _index);
    }

    /// @notice removes tokens from the stream with id = _index. Sends tokens back to stream token owner. Adds stream to blacklist
    /// @dev restricted for the admin only.
    /// @param _index index of the rewards stream
    function removeTokensFromRewardPool(uint256 _index) external onlyAdmin {

        Stream storage stream = streams[_index];
    
        require(stream.initialized, "! initialized");

        rewardsPool[stream.rewardsToken] = 0;
        stream.blacklisted = true;
        ITreasury(treasury).payRewards(stream.tokenOwner, stream.rewardsToken, IERC20Upgradeable(stream.rewardsToken).balanceOf(treasury));  
        emit RemovedFromRewardPool(msg.sender, IERC20Upgradeable(stream.rewardsToken).balanceOf(treasury), _index);   
    }

    /// @notice standard ERC20 transfer
    /// @dev reverts on any token transfer
    function transfer(address, uint256) public override returns (bool) {
        revert();
    }

    /// @notice standard ERC20 approve
    /// @dev reverts on any call
    function approve(address, uint256) public virtual override returns (bool) {
        revert();
    }

    
    /// @notice standard ERC20 transfer from
    /// @dev can called only by whitelisted contracts, implements accessible VOTE cheking based on decay. Can by paused by admin.
    /// @param _sender owner of the VOTE token
    /// @param _recipient tokens transfer to
    /// @param _amount amount of tokens to transfer
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override pausable(1) returns (bool) {

        require(whitelistedContracts[msg.sender], "Only whitelisted");

        Season memory season = seasons[currentSeason()];
        
        uint256 accessibleVOTE;

        if (block.timestamp <= season.decayStart) {

           accessibleVOTE = userClaimedVoteTokens[_sender][currentSeason()];

        } else {
            accessibleVOTE = 
                userClaimedVoteTokens[_sender][currentSeason()] - 
                (( userClaimedVoteTokens[_sender][currentSeason()] * 
                (block.timestamp - season.decayStart)) / 
                (season.endVoting - season.decayStart));
        }

        require(_amount <= accessibleVOTE, "Tranfser not allowed");

        if (block.timestamp <= season.decayStart) {
            userUsedVoteTokens[_sender][currentSeason()] += _amount;
        } else {
            userUsedVoteTokens[_sender][currentSeason()] += _amount - (_amount * 
            (block.timestamp - season.decayStart)) / 
            (season.endVoting - season.decayStart);
        }

        _transfer(_sender, _recipient, _amount);

        emit VotesTransfered(_sender, _recipient, _amount);
        return true;
    }

    
    /// @notice standard ERC20 balanceOf
    /// @dev calculates balance based on decay
    /// @param _account owner of the VOTE token
    /// @return the amount of tokens owned by _account
    function balanceOf(address _account) public view override returns (uint256) {
        Season memory season = seasons[currentSeason()];
        
        if (block.timestamp <= season.decayStart) {

           return userClaimedVoteTokens[_account][currentSeason()];
        }

        return 
            userClaimedVoteTokens[_account][currentSeason()] - 
            ((userClaimedVoteTokens[_account][currentSeason()] * 
            (block.timestamp - season.decayStart)) / 
            (season.endVoting - season.decayStart));
    }

    function balanceOfWithoutDecay(address _account) external view returns (uint256) {
        return _balances[_account];
    }

    function getDepositAmount(uint256 _depositId) external view returns (uint256) {
        return deposits[msg.sender][_depositId].amount;
    }

    function getDepositStartSeason(uint256 _depositId) external view returns (uint256) {
        return deposits[msg.sender][_depositId].startSeason;
    }

    function getDepositEndSeason(uint256 _depositId) external view returns (uint256) {
        return deposits[msg.sender][_depositId].endSeason;
    }

    function getDepositRewardWeight(uint256 _depositId) external view returns (uint256) {
        return deposits[msg.sender][_depositId].rewardWeight;
    }

    function getDepositVoteWeight(uint256 _depositId) external view returns (uint256) {
        return deposits[msg.sender][_depositId].voteWeight;
    }

    function currentSeason() public view returns(uint256) {
        return getSeasonByTimestamp(block.timestamp);
    }

    /// @notice returns season number by its timestam
    /// @dev cheks if timestamp is between seasons[i].startSeason and seasons[i].endSeason
    /// @param _timestamp timestamp to checko
    /// @return season number
    function getSeasonByTimestamp(uint256 _timestamp) public view returns (uint256 season) {

        require(seasons[0].startSeason < _timestamp, "Seasons haven't started");

        for (uint i = 0; i < seasons.length; i++) {        
            if (seasons[i].startSeason <= _timestamp && _timestamp <= seasons[i].endSeason) {
                season = i;
            }
        }
    }

    /// @notice allows admin to burn user tokens for current season that userd didn't used
    /// @param _user user wich tokens to burn
    function burnUnused(address _user) external onlyAdmin {
        Season memory season = seasons[currentSeason()];
        require(block.timestamp >= season.startSeason + burnGracePeriod, "! allowed");

        _burn(_user, _balances[_user] - userClaimedVoteTokens[_user][currentSeason()]);
    }

    /// @notice Destroys `amount` tokens from `_user`, reducing the total supply
    /// @param _user user wich tokens to burn
    /// @param _amount of tokens to burn
    function burn(address _user, uint256 _amount) external onlyAdmin {
        _burn(_user, _amount);
    }

    /// @notice Creates `_amount` tokens and assigns them to `_user`, increasing the total supply.
    /// @param _user user address to mint
    /// @param _amount of tokens to mint
    function mint(address _user, uint256 _amount) external onlyAdmin {
        _mint(_user, _amount);
    }

    /// @notice Batch destroys `_amounts` tokens from `_users`, reducing the total supply
    /// @param _users array of users
    /// @param _amounts arrays of amounts
    function burnBatch(address[] memory _users, uint256[] memory _amounts) external onlyAdmin {
        require(_users.length == _amounts.length);

        for (uint i = 0; i < _users.length; i++) {
            _burn(_users[i], _amounts[i]);
        }
    }

    /// @notice Batch creates `_amount` tokens and assigns them to `_user`, increasing the total supply.
    /// @param _users array of user address to mint
    /// @param _amounts array of amounts to mint
    function mintBatch(address[] memory _users, uint256[] memory _amounts) external onlyAdmin {
        require(_users.length == _amounts.length);

        for (uint i = 0; i < _users.length; i++) {
            _mint(_users[i], _amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IStaking {
  // function pause() external;
  // function unpause() external;

  function stake(uint256 amount, uint256 seasonAmount) external;
  function unstake (uint256 depositId) external;

  function claimVote(uint256 depositId) external;
  function claimRewards(uint256 depositId, uint index, address user) external;

  function updateSeasonDuration(uint256 newDuration) external;
  function burn(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITreasury {
  function pause() external;
  function unpause() external;

  function payRewards(address _user, address _token, uint256 _deposit) external;
}