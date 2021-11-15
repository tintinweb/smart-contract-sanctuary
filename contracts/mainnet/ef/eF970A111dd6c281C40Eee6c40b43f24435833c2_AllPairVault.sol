// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
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
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/OndoRegistryClient.sol";
import "contracts/TrancheToken.sol";
import "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/IPairVault.sol";
import "contracts/interfaces/IFeeCollector.sol";

/**
 * @title A container for all Vaults
 * @notice Vaults are created and managed here
 * @dev Because Ethereum transactions are so expensive,
 * we reinvent an OO system in this code. There are 4 primary
 * functions:
 *
 * deposit, withdraw: investors can add remove funds into a
 *     particular tranche in a Vault.
 * invest, redeem: a strategist pushes the Vault to buy/sell LP tokens in
 *     an underlying AMM
 */
contract AllPairVault is OndoRegistryClient, IPairVault {
  using OLib for OLib.Investor;
  using SafeERC20 for IERC20;
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  // A Vault object is parameterized by these values.
  struct Vault {
    mapping(OLib.Tranche => Asset) assets; // Assets corresponding to each tranche
    IStrategy strategy; // Shared contract that interacts with AMMs
    address creator; // Account that calls createVault
    address strategist; // Has the right to call invest() and redeem(), and harvest() if strategy supports it
    address rollover; // Manager of investment auto-rollover, if any
    uint256 rolloverId;
    uint256 hurdleRate; // Return offered to senior tranche
    OLib.State state; // Current state of Vault
    uint256 startAt; // Time when the Vault is unpaused to begin accepting deposits
    uint256 investAt; // Time when investors can't move funds, strategist can invest
    uint256 redeemAt; // Time when strategist can redeem LP tokens, investors can withdraw
    uint256 performanceFee; // Optional fee on junior tranche goes to strategist
  }

  // (TrancheToken address => (investor address => OLib.Investor)
  mapping(address => mapping(address => OLib.Investor)) investors;

  // An instance of TrancheToken from which all other tokens are cloned
  address public immutable trancheTokenImpl;

  // Address that collects performance fees
  IFeeCollector public performanceFeeCollector;

  // Locate Vault by hashing metadata about the product
  mapping(uint256 => Vault) private Vaults;

  // Locate Vault by starting from the TrancheToken address
  mapping(address => uint256) public VaultsByTokens;

  // All Vault IDs
  EnumerableSet.UintSet private vaultIDs;

  // Access restriction to registered strategist
  modifier onlyStrategist(uint256 _vaultId) {
    require(msg.sender == Vaults[_vaultId].strategist, "Invalid caller");
    _;
  }

  // Access restriction to registered rollover
  modifier onlyRollover(uint256 _vaultId, uint256 _rolloverId) {
    Vault storage vault_ = Vaults[_vaultId];
    require(
      msg.sender == vault_.rollover && _rolloverId == vault_.rolloverId,
      "Invalid caller"
    );
    _;
  }

  // Access is only rollover if rollover addr nonzero, else strategist
  modifier onlyRolloverOrStrategist(uint256 _vaultId) {
    Vault storage vault_ = Vaults[_vaultId];
    address rollover = vault_.rollover;
    require(
      (rollover == address(0) && msg.sender == vault_.strategist) ||
        (msg.sender == rollover),
      "Invalid caller"
    );
    _;
  }

  // Guard functions with state machine
  modifier atState(uint256 _vaultId, OLib.State _state) {
    require(getState(_vaultId) == _state, "Invalid operation");
    _;
  }

  // Determine if one can move to a new state. For now the transitions
  // are strictly linear. No state machines, really.
  function transition(uint256 _vaultId, OLib.State _nextState) private {
    Vault storage vault_ = Vaults[_vaultId];
    OLib.State curState = vault_.state;
    if (_nextState == OLib.State.Live) {
      require(curState == OLib.State.Deposit, "Invalid operation");
      require(vault_.investAt <= block.timestamp, "Not time yet");
    } else {
      require(
        curState == OLib.State.Live && _nextState == OLib.State.Withdraw,
        "Invalid operation"
      );
      require(vault_.redeemAt <= block.timestamp, "Not time yet");
    }
    vault_.state = _nextState;
  }

  // Determine if a Vault can shift to an open state. A Vault is started
  // in an inactive state. It can only move forward when time has
  // moved past the starttime.
  function maybeOpenDeposit(uint256 _vaultId) private {
    Vault storage vault_ = Vaults[_vaultId];
    if (vault_.state == OLib.State.Inactive) {
      require(
        vault_.startAt > 0 && vault_.startAt <= block.timestamp,
        "Not time yet"
      );
      vault_.state = OLib.State.Deposit;
    } else if (vault_.state != OLib.State.Deposit) {
      revert("Invalid operation");
    }
  }

  // modifier onlyETH(uint256 _vaultId, OLib.Tranche _tranche) {
  //   require(
  //     address((getVaultById(_vaultId)).assets[uint256(_tranche)].token) ==
  //       address(registry.weth()),
  //     "Not an ETH vault"
  //   );
  //   _;
  // }

  function onlyETH(uint256 _vaultId, OLib.Tranche _tranche) private view {
    require(
      address((getVaultById(_vaultId)).assets[uint256(_tranche)].token) ==
        address(registry.weth()),
      "Not an ETH vault"
    );
  }

  /**
   * Event declarations
   */
  event CreatedPair(
    uint256 indexed vaultId,
    IERC20 indexed seniorAsset,
    IERC20 indexed juniorAsset,
    ITrancheToken seniorToken,
    ITrancheToken juniorToken
  );

  event SetRollover(
    address indexed rollover,
    uint256 indexed rolloverId,
    uint256 indexed vaultId
  );

  event Deposited(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 indexed trancheId,
    uint256 amount
  );

  event Invested(
    uint256 indexed vaultId,
    uint256 seniorAmount,
    uint256 juniorAmount
  );

  event DepositedLP(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 amount,
    uint256 senior,
    uint256 junior
  );

  event RolloverDeposited(
    address indexed rollover,
    uint256 indexed rolloverId,
    uint256 indexed vaultId,
    uint256 seniorAmount,
    uint256 juniorAmount
  );

  event Claimed(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 indexed trancheId,
    uint256 shares,
    uint256 excess
  );

  event RolloverClaimed(
    address indexed rollover,
    uint256 indexed rolloverId,
    uint256 indexed vaultId,
    uint256 seniorAmount,
    uint256 juniorAmount
  );

  event Redeemed(
    uint256 indexed vaultId,
    uint256 seniorReceived,
    uint256 juniorReceived
  );

  event Withdrew(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 indexed trancheId,
    uint256 amount
  );

  event WithdrewLP(address indexed depositor, uint256 amount);

  event PerformanceFeeSet(uint256 indexed vaultId, uint256 fee);

  event PerformanceFeeCollectorSet(address indexed collector);

  /**
   * @notice Container points back to registry
   * @dev Hook up this contract to the global registry.
   */
  constructor(address _registry, address _trancheTokenImpl)
    OndoRegistryClient(_registry)
  {
    require(_trancheTokenImpl != address(0), "Invalid target");
    trancheTokenImpl = _trancheTokenImpl;
  }

  /**
   * @notice Initialize parameters for a Vault
   * @dev
   * @param _params Struct with all initialization info
   * @return vaultId hashed identifier of Vault used everywhere
   **/
  function createVault(OLib.VaultParams calldata _params)
    external
    override
    whenNotPaused
    isAuthorized(OLib.CREATOR_ROLE)
    nonReentrant
    returns (uint256 vaultId)
  {
    require(
      registry.authorized(OLib.STRATEGY_ROLE, _params.strategy),
      "Invalid target"
    );
    require(
      registry.authorized(OLib.STRATEGIST_ROLE, _params.strategist),
      "Invalid target"
    );
    require(_params.startTime >= block.timestamp, "Invalid start time");
    require(
      _params.enrollment > 0 && _params.duration > 0,
      "No zero intervals"
    );
    require(_params.hurdleRate < 1e8, "Maximum hurdle is 10000%");
    require(denominator <= _params.hurdleRate, "Min hurdle is 100%");

    require(
      _params.seniorAsset != address(0) &&
        _params.seniorAsset != address(this) &&
        _params.juniorAsset != address(0) &&
        _params.juniorAsset != address(this),
      "Invalid target"
    );
    uint256 investAtTime = _params.startTime + _params.enrollment;
    uint256 redeemAtTime = investAtTime + _params.duration;
    TrancheToken seniorITrancheToken;
    TrancheToken juniorITrancheToken;
    {
      vaultId = uint256(
        keccak256(
          abi.encode(
            _params.seniorAsset,
            _params.juniorAsset,
            _params.strategy,
            _params.hurdleRate,
            _params.startTime,
            investAtTime,
            redeemAtTime
          )
        )
      );
      vaultIDs.add(vaultId);
      Vault storage vault_ = Vaults[vaultId];
      require(address(vault_.strategist) == address(0), "Duplicate");
      vault_.strategy = IStrategy(_params.strategy);
      vault_.creator = msg.sender;
      vault_.strategist = _params.strategist;
      vault_.hurdleRate = _params.hurdleRate;
      vault_.startAt = _params.startTime;
      vault_.investAt = investAtTime;
      vault_.redeemAt = redeemAtTime;

      registry.recycleDeadTokens(2);

      seniorITrancheToken = TrancheToken(
        Clones.cloneDeterministic(
          trancheTokenImpl,
          keccak256(abi.encodePacked(uint256(0), vaultId))
        )
      );
      juniorITrancheToken = TrancheToken(
        Clones.cloneDeterministic(
          trancheTokenImpl,
          keccak256(abi.encodePacked(uint256(1), vaultId))
        )
      );
      vault_.assets[OLib.Tranche.Senior].token = IERC20(_params.seniorAsset);
      vault_.assets[OLib.Tranche.Junior].token = IERC20(_params.juniorAsset);
      vault_.assets[OLib.Tranche.Senior].trancheToken = seniorITrancheToken;
      vault_.assets[OLib.Tranche.Junior].trancheToken = juniorITrancheToken;

      vault_.assets[OLib.Tranche.Senior].trancheCap = _params.seniorTrancheCap;
      vault_.assets[OLib.Tranche.Senior].userCap = _params.seniorUserCap;
      vault_.assets[OLib.Tranche.Junior].trancheCap = _params.juniorTrancheCap;
      vault_.assets[OLib.Tranche.Junior].userCap = _params.juniorUserCap;

      VaultsByTokens[address(seniorITrancheToken)] = vaultId;
      VaultsByTokens[address(juniorITrancheToken)] = vaultId;
      if (vault_.startAt == block.timestamp) {
        vault_.state = OLib.State.Deposit;
      }

      IStrategy(_params.strategy).addVault(
        vaultId,
        IERC20(_params.seniorAsset),
        IERC20(_params.juniorAsset)
      );

      seniorITrancheToken.initialize(
        vaultId,
        _params.seniorName,
        _params.seniorSym,
        address(this)
      );
      juniorITrancheToken.initialize(
        vaultId,
        _params.juniorName,
        _params.juniorSym,
        address(this)
      );
    }

    emit CreatedPair(
      vaultId,
      IERC20(_params.seniorAsset),
      IERC20(_params.juniorAsset),
      seniorITrancheToken,
      juniorITrancheToken
    );
  }

  /**
   * @notice Set the rollover details for a Vault
   * @dev
   * @param _vaultId Vault to update
   * @param _rollover Account of approved rollover agent
   * @param _rolloverId Rollover fund in RolloverVault
   */
  function setRollover(
    uint256 _vaultId,
    address _rollover,
    uint256 _rolloverId
  ) external override isAuthorized(OLib.ROLLOVER_ROLE) {
    Vault storage vault_ = Vaults[_vaultId];
    if (vault_.rollover != address(0)) {
      require(
        msg.sender == vault_.rollover && _rolloverId == vault_.rolloverId,
        "Invalid caller"
      );
    }
    vault_.rollover = _rollover;
    vault_.rolloverId = _rolloverId;
    emit SetRollover(_rollover, _rolloverId, _vaultId);
  }

  /** @dev Enforce cap on user investment if any
   */
  function depositCapGuard(uint256 _allowedAmount, uint256 _amount)
    internal
    pure
  {
    require(
      _allowedAmount == 0 || _amount <= _allowedAmount,
      "Exceeds user cap"
    );
  }

  /**
   * @notice Deposit funds into specific tranche of specific Vault
   * @dev OLib.Tranche balances are maintained by a unique ERC20 contract
   * @param _vaultId Specific ID for this Vault
   * @param _tranche Tranche to be deposited in
   * @param _amount Amount of tranche asset to transfer to the strategy contract
   */
  function _deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount,
    address _payer
  ) internal whenNotPaused  {
    maybeOpenDeposit(_vaultId);
    Vault storage vault_ = Vaults[_vaultId];
    vault_.assets[_tranche].token.safeTransferFrom(
      _payer,
      address(vault_.strategy),
      _amount
    );
    uint256 _total = vault_.assets[_tranche].deposited += _amount;
    OLib.Investor storage _investor =
      investors[address(vault_.assets[_tranche].trancheToken)][msg.sender];
    uint256 userSum =
      _investor.userSums.length > 0
        ? _investor.userSums[_investor.userSums.length - 1] + _amount
        : _amount;
    depositCapGuard(vault_.assets[_tranche].userCap, userSum);
    _investor.prefixSums.push(_total);
    _investor.userSums.push(userSum);
    emit Deposited(msg.sender, _vaultId, uint256(_tranche), _amount);
  }

  function deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external override nonReentrant {
    _deposit(_vaultId, _tranche, _amount, msg.sender);
  }

  function depositETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    payable
    override
    nonReentrant
  {
    onlyETH(_vaultId, _tranche);
    registry.weth().deposit{value: msg.value}();
    _deposit(_vaultId, _tranche, msg.value, address(this));
  }

  /**
   * @notice Called by rollover to deposit funds
   * @dev Rollover gets priority over other depositors.
   * @param _vaultId Vault to work on
   * @param _rolloverId Rollover that is depositing funds
   * @param _seniorAmount Total available amount of assets
   * @param _juniorAmount Total available amount of assets
   */
  function depositFromRollover(
    uint256 _vaultId,
    uint256 _rolloverId,
    uint256 _seniorAmount,
    uint256 _juniorAmount
  )
    external
    override
    onlyRollover(_vaultId, _rolloverId)
    whenNotPaused
    nonReentrant
  {
    maybeOpenDeposit(_vaultId);
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    senior_.deposited += _seniorAmount;
    junior_.deposited += _juniorAmount;
    senior_.rolloverDeposited += _seniorAmount;
    junior_.rolloverDeposited += _juniorAmount;
    senior_.token.safeTransferFrom(
      msg.sender,
      address(vault_.strategy),
      _seniorAmount
    );
    junior_.token.safeTransferFrom(
      msg.sender,
      address(vault_.strategy),
      _juniorAmount
    );
    emit RolloverDeposited(
      msg.sender,
      _rolloverId,
      _vaultId,
      _seniorAmount,
      _juniorAmount
    );
  }

  /**
   * @notice Deposit more LP tokens into a Vault that is live
   * @dev When a Vault is created it establishes a ratio between
   *      senior/junior tranche tokens per LP token. If LP tokens are added
   *      while the Vault is running, it will get the same ratio of tranche
   *      tokens in return, regardless of the current balance in the pool.
   * @param _vaultId  reference to Vault
   * @param _lpTokens Amount of LP tokens to provide
   */
  function depositLp(uint256 _vaultId, uint256 _lpTokens)
    external
    override
    whenNotPaused
    nonReentrant
    atState(_vaultId, OLib.State.Live)
    returns (uint256 seniorTokensOwed, uint256 juniorTokensOwed)
  {
    require(registry.tokenMinting(), "Vault tokens inactive");
    Vault storage vault_ = Vaults[_vaultId];
    IERC20 pool;
    (seniorTokensOwed, juniorTokensOwed, pool) = getDepositLp(
      _vaultId,
      _lpTokens
    );

    depositCapGuard(
      vault_.assets[OLib.Tranche.Senior].userCap,
      seniorTokensOwed
    );
    depositCapGuard(
      vault_.assets[OLib.Tranche.Junior].userCap,
      juniorTokensOwed
    );

    vault_.assets[OLib.Tranche.Senior].totalInvested += seniorTokensOwed;
    vault_.assets[OLib.Tranche.Junior].totalInvested += juniorTokensOwed;
    vault_.assets[OLib.Tranche.Senior].trancheToken.mint(
      msg.sender,
      seniorTokensOwed
    );
    vault_.assets[OLib.Tranche.Junior].trancheToken.mint(
      msg.sender,
      juniorTokensOwed
    );

    pool.safeTransferFrom(msg.sender, address(vault_.strategy), _lpTokens);
    vault_.strategy.addLp(_vaultId, _lpTokens);
    emit DepositedLP(
      msg.sender,
      _vaultId,
      _lpTokens,
      seniorTokensOwed,
      juniorTokensOwed
    );
  }

  function getDepositLp(uint256 _vaultId, uint256 _lpTokens)
    public
    view
    atState(_vaultId, OLib.State.Live)
    returns (
      uint256 seniorTokensOwed,
      uint256 juniorTokensOwed,
      IERC20 pool
    )
  {
    Vault storage vault_ = Vaults[_vaultId];
    (uint256 shares, uint256 vaultShares, IERC20 ammPool) =
      vault_.strategy.sharesFromLp(_vaultId, _lpTokens);
    seniorTokensOwed =
      (vault_.assets[OLib.Tranche.Senior].totalInvested * shares) /
      vaultShares;
    juniorTokensOwed =
      (vault_.assets[OLib.Tranche.Junior].totalInvested * shares) /
      vaultShares;
    pool = ammPool;
  }

  /**
   * @notice Invest funds into AMM
   * @dev Push deposited funds into underlying strategy contract
   * @param _vaultId Specific id for this Vault
   * @param _seniorMinIn To ensure you get a decent price
   * @param _juniorMinIn Same. Passed to addLiquidity on AMM
   *
   */
  function invest(
    uint256 _vaultId,
    uint256 _seniorMinIn,
    uint256 _juniorMinIn
  )
    external
    override
    whenNotPaused
    nonReentrant
    onlyRolloverOrStrategist(_vaultId)
    returns (uint256, uint256)
  {
    transition(_vaultId, OLib.State.Live);
    Vault storage vault_ = Vaults[_vaultId];
    investIntoStrategy(vault_, _vaultId, _seniorMinIn, _juniorMinIn);
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    senior_.totalInvested = vault_.assets[OLib.Tranche.Senior].originalInvested;
    junior_.totalInvested = vault_.assets[OLib.Tranche.Junior].originalInvested;
    emit Invested(_vaultId, senior_.totalInvested, junior_.totalInvested);
    return (senior_.totalInvested, junior_.totalInvested); 
  }

  /*
   * @dev Separate investable amount calculation and strategy call from storage updates
   to keep the stack down.
   */
  function investIntoStrategy(
    Vault storage vault_,
    uint256 _vaultId,
    uint256 _seniorMinIn,
    uint256 _juniorMinIn
  ) private {
    uint256 seniorInvestableAmount =
      vault_.assets[OLib.Tranche.Senior].deposited;
    uint256 seniorCappedAmount = seniorInvestableAmount;
    if (vault_.assets[OLib.Tranche.Senior].trancheCap > 0) {
      seniorCappedAmount = min(
        seniorInvestableAmount,
        vault_.assets[OLib.Tranche.Senior].trancheCap
      );
    }
    uint256 juniorInvestableAmount =
      vault_.assets[OLib.Tranche.Junior].deposited;
    uint256 juniorCappedAmount = juniorInvestableAmount;
    if (vault_.assets[OLib.Tranche.Junior].trancheCap > 0) {
      juniorCappedAmount = min(
        juniorInvestableAmount,
        vault_.assets[OLib.Tranche.Junior].trancheCap
      );
    }

    (
      vault_.assets[OLib.Tranche.Senior].originalInvested,
      vault_.assets[OLib.Tranche.Junior].originalInvested
    ) = vault_.strategy.invest(
      _vaultId,
      seniorCappedAmount,
      juniorCappedAmount,
      seniorInvestableAmount - seniorCappedAmount,
      juniorInvestableAmount - juniorCappedAmount,
      _seniorMinIn,
      _juniorMinIn
    );
  }

  /**
   * @notice Return undeposited funds and trigger minting in Tranche Token
   * @dev Because the tranches must be balanced to buy LP tokens at
   *      the right ratio, it is likely that some deposits will not be
   *      accepted. This function transfers that "excess" deposit. Also, it
   *      finally mints the tranche tokens for this customer.
   * @param _vaultId  Reference to specific Vault
   * @param _tranche which tranche to act on
   * @return userInvested Total amount actually invested from this tranche
   * @return excess Any uninvested funds
   */
  function _claim(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    address _receiver
  )
    internal
    whenNotPaused
    atState(_vaultId, OLib.State.Live)
    returns (uint256 userInvested, uint256 excess)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage _asset = vault_.assets[_tranche];
    ITrancheToken _trancheToken = _asset.trancheToken;
    OLib.Investor storage investor =
      investors[address(_trancheToken)][msg.sender];
    require(!investor.claimed, "Already claimed");
    IStrategy _strategy = vault_.strategy;
    (userInvested, excess) = investor.getInvestedAndExcess(
      _getNetOriginalInvested(_asset)
    );
    if (excess > 0)
      _strategy.withdrawExcess(_vaultId, _tranche, _receiver, excess);
    if (registry.tokenMinting()) {
      _trancheToken.mint(msg.sender, userInvested);
    }

    investor.claimed = true;
    emit Claimed(msg.sender, _vaultId, uint256(_tranche), userInvested, excess);
    return (userInvested, excess);
  }

  function claim(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256, uint256)
  {
    return _claim(_vaultId, _tranche, msg.sender);
  }

  function claimETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256 invested, uint256 excess)
  {
    onlyETH(_vaultId, _tranche);
    (invested, excess) = _claim(_vaultId, _tranche, address(this));
    registry.weth().withdraw(excess);
    safeTransferETH(msg.sender, excess);
  }

  /**
   * @notice Called by rollover to claim both tranches
   * @dev Triggers minting of tranche tokens. Moves excess to Rollover.
   * @param _vaultId Vault id
   * @param _rolloverId Rollover ID
   * @return srRollInv Amount invested in tranche
   * @return jrRollInv Amount invested in tranche
   */
  function rolloverClaim(uint256 _vaultId, uint256 _rolloverId)
    external
    override
    whenNotPaused
    nonReentrant
    atState(_vaultId, OLib.State.Live)
    onlyRollover(_vaultId, _rolloverId)
    returns (uint256 srRollInv, uint256 jrRollInv)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    srRollInv = _getRolloverInvested(senior_);
    jrRollInv = _getRolloverInvested(junior_);
    if (srRollInv > 0) {
      senior_.trancheToken.mint(msg.sender, srRollInv);
    }
    if (jrRollInv > 0) {
      junior_.trancheToken.mint(msg.sender, jrRollInv);
    }
    if (senior_.rolloverDeposited > srRollInv) {
      vault_.strategy.withdrawExcess(
        _vaultId,
        OLib.Tranche.Senior,
        msg.sender,
        senior_.rolloverDeposited - srRollInv
      );
    }
    if (junior_.rolloverDeposited > jrRollInv) {
      vault_.strategy.withdrawExcess(
        _vaultId,
        OLib.Tranche.Junior,
        msg.sender,
        junior_.rolloverDeposited - jrRollInv
      );
    }
    emit RolloverClaimed(
      msg.sender,
      _rolloverId,
      _vaultId,
      srRollInv,
      jrRollInv
    );
    return (srRollInv, jrRollInv);
  }

  /**
   * @notice Redeem funds into AMM
   * @dev Exchange LP tokens for senior/junior assets. Compute the amount
   *      the senior tranche should get (like 10% more). The senior._received
   *      value should be equal to or less than that expected amount. The
   *      junior.received should be all that's left.
   * @param _vaultId Specific id for this Vault
   * @param _seniorMinReceived Compute total expected to redeem, factoring in slippage
   * @param _juniorMinReceived Same.
   */
  function redeem(
    uint256 _vaultId,
    uint256 _seniorMinReceived,
    uint256 _juniorMinReceived
  )
    external
    override
    whenNotPaused
    nonReentrant
    onlyRolloverOrStrategist(_vaultId)
    returns (uint256, uint256)
  {
    transition(_vaultId, OLib.State.Withdraw);
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    Asset storage junior_ = vault_.assets[OLib.Tranche.Junior];
    (senior_.received, junior_.received) = vault_.strategy.redeem(
      _vaultId,
      _getSeniorExpected(vault_, senior_),
      _seniorMinReceived,
      _juniorMinReceived
    );
    junior_.received -= takePerformanceFee(vault_, _vaultId);

    emit Redeemed(_vaultId, senior_.received, junior_.received);
    return (senior_.received, junior_.received);
  }

  /**
   * @notice Investors withdraw funds from Vault
   * @dev Based on the fraction of ownership in the original pool of invested assets,
          investors get the same fraction of the resulting pile of assets. All funds are withdrawn.
   * @param _vaultId Specific ID for this Vault
   * @param _tranche Tranche to be deposited in
   * @return tokensToWithdraw Amount investor received from transfer
   */
  function _withdraw(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    address _receiver
  )
    internal
    whenNotPaused
    atState(_vaultId, OLib.State.Withdraw)
    returns (uint256 tokensToWithdraw)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage asset_ = vault_.assets[_tranche];
    (, , , tokensToWithdraw) = vaultInvestor(_vaultId, _tranche);
    ITrancheToken token_ = asset_.trancheToken;
    if (registry.tokenMinting()) {
      uint256 bal = token_.balanceOf(msg.sender);
      if (bal > 0) {
        token_.burn(msg.sender, bal);
      }
    }
    asset_.token.safeTransferFrom(
      address(vault_.strategy),
      _receiver,
      tokensToWithdraw
    );
    investors[address(asset_.trancheToken)][msg.sender].withdrawn = true;
    emit Withdrew(msg.sender, _vaultId, uint256(_tranche), tokensToWithdraw);
    return tokensToWithdraw;
  }

  function withdraw(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256)
  {
    return _withdraw(_vaultId, _tranche, msg.sender);
  }

  function withdrawETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    override
    nonReentrant
    returns (uint256 amount)
  {
    onlyETH(_vaultId, _tranche);
    amount = _withdraw(_vaultId, _tranche, address(this));
    registry.weth().withdraw(amount);
    safeTransferETH(msg.sender, amount);
  }

  receive() external payable {
    assert(msg.sender == address(registry.weth()));
  }

  /**
   * @notice Exchange the correct ratio of senior/junior tokens to get LP tokens
   * @dev Burn tranche tokens on both sides and send LP tokens to customer
   * @param _vaultId  reference to Vault
   * @param _shares Share of lp tokens to withdraw
   */
  function withdrawLp(uint256 _vaultId, uint256 _shares)
    external
    override
    whenNotPaused
    nonReentrant
    atState(_vaultId, OLib.State.Live)
    returns (uint256 seniorTokensNeeded, uint256 juniorTokensNeeded)
  {
    require(registry.tokenMinting(), "Vault tokens inactive");
    Vault storage vault_ = Vaults[_vaultId];
    (seniorTokensNeeded, juniorTokensNeeded) = getWithdrawLp(_vaultId, _shares);
    vault_.assets[OLib.Tranche.Senior].trancheToken.burn(
      msg.sender,
      seniorTokensNeeded
    );
    vault_.assets[OLib.Tranche.Junior].trancheToken.burn(
      msg.sender,
      juniorTokensNeeded
    );
    vault_.assets[OLib.Tranche.Senior].totalInvested -= seniorTokensNeeded;
    vault_.assets[OLib.Tranche.Junior].totalInvested -= juniorTokensNeeded;
    vault_.strategy.removeLp(_vaultId, _shares, msg.sender);
    emit WithdrewLP(msg.sender, _shares);
  }

  function getWithdrawLp(uint256 _vaultId, uint256 _shares)
    public
    view
    atState(_vaultId, OLib.State.Live)
    returns (uint256 seniorTokensNeeded, uint256 juniorTokensNeeded)
  {
    Vault storage vault_ = Vaults[_vaultId];
    (, uint256 totalShares) = vault_.strategy.getVaultInfo(_vaultId);
    seniorTokensNeeded =
      (vault_.assets[OLib.Tranche.Senior].totalInvested * _shares) /
      totalShares;
    juniorTokensNeeded =
      (vault_.assets[OLib.Tranche.Junior].totalInvested * _shares) /
      totalShares;
  }

  function getState(uint256 _vaultId)
    public
    view
    override
    returns (OLib.State)
  {
    Vault storage vault_ = Vaults[_vaultId];
    return vault_.state;
  }

  /**
   * Helper functions
   */

  /**
   * @notice Compute performance fee for strategist
   * @dev If junior makes at least as much as the senior, then charge
   *      a performance fee on junior's earning beyond the hurdle.
   * @param vault Vault to work on
   * @return fee Amount of tokens deducted from junior tranche
   */
  function takePerformanceFee(Vault storage vault, uint256 vaultId)
    internal
    returns (uint256 fee)
  {
    fee = 0;
    if (address(performanceFeeCollector) != address(0)) {
      Asset storage junior = vault.assets[OLib.Tranche.Junior];
      uint256 juniorHurdle =
        (junior.totalInvested * vault.hurdleRate) / denominator;

      if (junior.received > juniorHurdle) {
        fee = (vault.performanceFee * (junior.received - juniorHurdle)) / denominator;
        IERC20(junior.token).safeTransferFrom(
          address(vault.strategy),
          address(performanceFeeCollector),
          fee
        );
        performanceFeeCollector.processFee(vaultId, IERC20(junior.token), fee);
      }
    }
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH transfer failed");
  }

  /**
   * @notice Multiply senior by hurdle raten
   * @param vault Vault to work on
   * @param senior Relevant asset
   * @return Max value senior can earn for this Vault
   */
  function _getSeniorExpected(Vault storage vault, Asset storage senior)
    internal
    view
    returns (uint256)
  {
    return (senior.totalInvested * vault.hurdleRate) / denominator;
  }

  function _getNetOriginalInvested(Asset storage asset)
    internal
    view
    returns (uint256)
  {
    uint256 o = asset.originalInvested;
    uint256 r = asset.rolloverDeposited;
    return o > r ? o - r : 0;
  }

  function _getRolloverInvested(Asset storage asset)
    internal
    view
    returns (uint256)
  {
    uint256 o = asset.originalInvested;
    uint256 r = asset.rolloverDeposited;
    return o > r ? r : o;
  }

  /**
   * Setters
   */

  /**
   * @notice Set optional performance fee for Vault
   * @dev Only available before deposits are open
   * @param _vaultId Vault to work on
   * @param _performanceFee Percent fee, denominator is 10000
   */
  function setPerformanceFee(uint256 _vaultId, uint256 _performanceFee)
    external
    onlyStrategist(_vaultId)
    atState(_vaultId, OLib.State.Inactive)
  {
    require(_performanceFee <= denominator, "Too high");
    Vault storage vault_ = Vaults[_vaultId];
    vault_.performanceFee = _performanceFee;
    emit PerformanceFeeSet(_vaultId, _performanceFee);
  }

  /**
   * @notice All performanceFees go this address. Only set by governance role.
   * @param _collector Address of collector contract
   */
  function setPerformanceFeeCollector(address _collector)
    external
    isAuthorized(OLib.GOVERNANCE_ROLE)
  {
    performanceFeeCollector = IFeeCollector(_collector);
    emit PerformanceFeeCollectorSet(_collector);
  }

  function canDeposit(uint256 _vaultId) external view override returns (bool) {
    Vault storage vault_ = Vaults[_vaultId];
    if (vault_.state == OLib.State.Inactive) {
      return vault_.startAt <= block.timestamp && vault_.startAt > 0;
    }
    return vault_.state == OLib.State.Deposit;
  }

  function getVaults(uint256 _from, uint256 _to)
    external
    view
    returns (VaultView[] memory vaults)
  {
    EnumerableSet.UintSet storage vaults_ = vaultIDs;
    uint256 len = vaults_.length();
    if (len == 0) {
      return new VaultView[](0);
    }
    if (len <= _to) {
      _to = len - 1;
    }
    vaults = new VaultView[](1 + _to - _from);
    for (uint256 i = _from; i <= _to; i++) {
      vaults[i] = getVaultById(vaults_.at(i));
    }
    return vaults;
  }

  function getVaultByToken(address _trancheToken)
    external
    view
    returns (VaultView memory)
  {
    return getVaultById(VaultsByTokens[_trancheToken]);
  }

  function getVaultById(uint256 _vaultId)
    public
    view
    override
    returns (VaultView memory vault)
  {
    Vault storage svault_ = Vaults[_vaultId];
    mapping(OLib.Tranche => Asset) storage sassets_ = svault_.assets;
    Asset[] memory assets = new Asset[](2);
    assets[0] = sassets_[OLib.Tranche.Senior];
    assets[1] = sassets_[OLib.Tranche.Junior];
    vault = VaultView(
      _vaultId,
      assets,
      svault_.strategy,
      svault_.creator,
      svault_.strategist,
      svault_.rollover,
      svault_.hurdleRate,
      svault_.state,
      svault_.startAt,
      svault_.investAt,
      svault_.redeemAt
    );
  }

  function isPaused() external view override returns (bool) {
    return paused();
  }

  function getRegistry() external view override returns (address) {
    return address(registry);
  }

  function seniorExpected(uint256 _vaultId)
    external
    view
    override
    returns (uint256)
  {
    Vault storage vault_ = Vaults[_vaultId];
    Asset storage senior_ = vault_.assets[OLib.Tranche.Senior];
    return _getSeniorExpected(vault_, senior_);
  }

  function getUserCaps(uint256 _vaultId)
    external
    view
    override
    returns (uint256 seniorUserCap, uint256 juniorUserCap)
  {
    Vault storage vault_ = Vaults[_vaultId];
    return (
      vault_.assets[OLib.Tranche.Senior].userCap,
      vault_.assets[OLib.Tranche.Junior].userCap
    );
  }

  /*
   * @return position: total user invested = unclaimed invested amount + tranche token balance
   * @return claimableBalance: unclaimed invested deposit amount that can be converted into tranche tokens by claiming
   * @return withdrawableExcess: unclaimed uninvested deposit amount that can be recovered by claiming
   * @return withdrawableBalance: total amount that the user can redeem their position for by withdrawaing, 0 if the product is still live
   */
  function vaultInvestor(uint256 _vaultId, OLib.Tranche _tranche)
    public
    view
    override
    returns (
      uint256 position,
      uint256 claimableBalance,
      uint256 withdrawableExcess,
      uint256 withdrawableBalance
    )
  {
    Asset storage asset_ = Vaults[_vaultId].assets[_tranche];
    OLib.Investor storage investor_ =
      investors[address(asset_.trancheToken)][msg.sender];
    if (!investor_.withdrawn) {
      (position, withdrawableExcess) = investor_.getInvestedAndExcess(
        _getNetOriginalInvested(asset_)
      );
      if (!investor_.claimed) {
        claimableBalance = position;
        position += asset_.trancheToken.balanceOf(msg.sender);
      } else {
        withdrawableExcess = 0;
        if (registry.tokenMinting()) {
          position = asset_.trancheToken.balanceOf(msg.sender);
        }
      }
      if (Vaults[_vaultId].state == OLib.State.Withdraw) {
        claimableBalance = 0;
        withdrawableBalance =
          withdrawableExcess +
          (asset_.received * position) /
          asset_.totalInvested;
      }
    }
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./OndoRegistryClientInitializable.sol";

abstract contract OndoRegistryClient is OndoRegistryClientInitializable {
  constructor(address _registry) {
    __OndoRegistryClient__initialize(_registry);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/libraries/OndoLibrary.sol";

abstract contract OndoRegistryClientInitializable is
  Initializable,
  ReentrancyGuard,
  Pausable
{
  using SafeERC20 for IERC20;

  IRegistry public registry;
  uint256 public denominator;

  function __OndoRegistryClient__initialize(address _registry)
    internal
    initializer
  {
    require(_registry != address(0), "Invalid registry address");
    registry = IRegistry(_registry);
    denominator = registry.denominator();
  }

  /**
   * @notice General ACL checker
   * @param _role Role as defined in OndoLibrary
   */
  modifier isAuthorized(bytes32 _role) {
    require(registry.authorized(_role, msg.sender), "Unauthorized");
    _;
  }

  /*
   * @notice Helper to expose a Pausable interface to tools
   */
  function paused() public view virtual override returns (bool) {
    return registry.paused() || super.paused();
  }

  function pause() external virtual isAuthorized(OLib.PANIC_ROLE)
  {
    super._pause();
  }

  function unpause() external virtual isAuthorized(OLib.GUARDIAN_ROLE)
  {
    super._unpause();
  }

  /**
   * @notice Grab tokens and send to caller
   * @dev If the _amount[i] is 0, then transfer all the tokens
   * @param _tokens List of tokens
   * @param _amounts Amount of each token to send
   */
  function _rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    internal
    virtual
  {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 amount = _amounts[i];
      if (amount == 0) {
        amount = IERC20(_tokens[i]).balanceOf(address(this));
      }
      IERC20(_tokens[i]).safeTransfer(msg.sender, amount);
    }
  }

  function rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    public
    whenPaused
    isAuthorized(OLib.GUARDIAN_ROLE)
  {
    require(_tokens.length == _amounts.length, "Invalid array sizes");
    _rescueTokens(_tokens, _amounts);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "contracts/interfaces/IPairVault.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IBasicVault.sol";

/**
 * @title Fixed duration tokens representing tranches
 * @notice For every Vault, for every tranche, this ERC20 token enables trading.
 * @dev Since these are short-lived tokens and we are producing lots
 *      of them, this uses clones to cheaply create many instance.  in
 *      practice this is not upgradeable, we use openzeppelin's clone
 */
contract TrancheToken is ERC20Upgradeable, ITrancheToken, OwnableUpgradeable {
  IBasicVault public vault;
  uint256 public vaultId;

  modifier whenNotPaused {
    require(!vault.isPaused(), "Global pause in effect");
    _;
  }

  modifier onlyRegistry {
    require(
      vault.getRegistry() == msg.sender,
      "Invalid access: Only Registry can call"
    );
    _;
  }

  function initialize(
    uint256 _vaultId,
    string calldata _name,
    string calldata _symbol,
    address _vault
  ) external initializer {
    __Ownable_init();
    __ERC20_init(_name, _symbol);
    vault = IBasicVault(_vault);
    vaultId = _vaultId;
  }

  function mint(address _account, uint256 _amount)
    external
    override
    whenNotPaused
    onlyOwner
  {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount)
    external
    override
    whenNotPaused
    onlyOwner
  {
    _burn(_account, _amount);
  }

  function transfer(address _account, uint256 _amount)
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_account, _amount);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _amount);
  }

  function approve(address _account, uint256 _amount)
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.approve(_account, _amount);
  }

  function destroy(address payable _receiver)
    external
    override
    whenNotPaused
    onlyRegistry
  {
    selfdestruct(_receiver);
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    override(ERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    override(ERC20Upgradeable)
    whenNotPaused
    returns (bool)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface IBasicVault {
  function isPaused() external view returns (bool);

  function getRegistry() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeCollector {
  function processFee(
    uint256 vaultId,
    IERC20 token,
    uint256 feeSent
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/IBasicVault.sol";

interface IPairVault is IBasicVault {
  // Container to return Vault info to caller
  struct VaultView {
    uint256 id;
    Asset[] assets;
    IStrategy strategy; // Shared contract that interacts with AMMs
    address creator; // Account that calls createVault
    address strategist; // Has the right to call invest() and redeem(), and harvest() if strategy supports it
    address rollover;
    uint256 hurdleRate; // Return offered to senior tranche
    OLib.State state; // Current state of Vault
    uint256 startAt; // Time when the Vault is unpaused to begin accepting deposits
    uint256 investAt; // Time when investors can't move funds, strategist can invest
    uint256 redeemAt; // Time when strategist can redeem LP tokens, investors can withdraw
  }

  // Track the asset type and amount in different stages
  struct Asset {
    IERC20 token;
    ITrancheToken trancheToken;
    uint256 trancheCap;
    uint256 userCap;
    uint256 deposited;
    uint256 originalInvested;
    uint256 totalInvested; // not literal 1:1, originalInvested + proportional lp from mid-term
    uint256 received;
    uint256 rolloverDeposited;
  }

  function getState(uint256 _vaultId) external view returns (OLib.State);

  function createVault(OLib.VaultParams calldata _params)
    external
    returns (uint256 vaultId);

  function deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external;

  function depositETH(uint256 _vaultId, OLib.Tranche _tranche) external payable;

  function depositLp(uint256 _vaultId, uint256 _amount)
    external
    returns (uint256 seniorTokensOwed, uint256 juniorTokensOwed);

  function invest(
    uint256 _vaultId,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external
    returns (uint256, uint256);

  function redeem(
    uint256 _vaultId,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external
    returns (uint256, uint256);

  function withdraw(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256);

  function withdrawETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256);

  function withdrawLp(uint256 _vaultId, uint256 _amount)
    external
    returns (uint256, uint256);

  function claim(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256, uint256);

  function claimETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256, uint256);

  function depositFromRollover(
    uint256 _vaultId,
    uint256 _rolloverId,
    uint256 _seniorAmount,
    uint256 _juniorAmount
  ) external;

  function rolloverClaim(uint256 _vaultId, uint256 _rolloverId)
    external
    returns (uint256, uint256);

  function setRollover(
    uint256 _vaultId,
    address _rollover,
    uint256 _rolloverId
  ) external;

  function canDeposit(uint256 _vaultId) external view returns (bool);

  // function canTransition(uint256 _vaultId, OLib.State _state)
  //   external
  //   view
  //   returns (bool);

  function getVaultById(uint256 _vaultId)
    external
    view
    returns (VaultView memory);

  function vaultInvestor(uint256 _vaultId, OLib.Tranche _tranche)
    external
    view
    returns (
      uint256 position,
      uint256 claimableBalance,
      uint256 withdrawableExcess,
      uint256 withdrawableBalance
    );

  function seniorExpected(uint256 _vaultId) external view returns (uint256);

  function getUserCaps(uint256 _vaultId)
    external
    view
    returns (uint256 seniorUserCap, uint256 juniorUserCap);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/interfaces/IWETH.sol";

/**
 * @title Global values used by many contracts
 * @notice This is mostly used for access control
 */
interface IRegistry is IAccessControl {
  function paused() external view returns (bool);

  function pause() external;

  function unpause() external;

  function tokenMinting() external view returns (bool);

  function denominator() external view returns (uint256);

  function weth() external view returns (IWETH);

  function authorized(bytes32 _role, address _account)
    external
    view
    returns (bool);

  function enableTokens() external;
  function disableTokens() external;

  function recycleDeadTokens(uint256 _tranches) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/IPairVault.sol";

interface IStrategy {
  // Additional info stored for each Vault
  struct Vault {
    IPairVault origin; // who created this Vault
    IERC20 pool; // the DEX pool
    IERC20 senior; // senior asset in pool
    IERC20 junior; // junior asset in pool
    uint256 shares; // number of shares for ETF-style mid-duration entry/exit
    uint256 seniorExcess; // unused senior deposits
    uint256 juniorExcess; // unused junior deposits
  }

  function vaults(uint256 vaultId)
    external
    view
    returns (
      IPairVault origin,
      IERC20 pool,
      IERC20 senior,
      IERC20 junior,
      uint256 shares,
      uint256 seniorExcess,
      uint256 juniorExcess
    );

  function addVault(
    uint256 _vaultId,
    IERC20 _senior,
    IERC20 _junior
  ) external;

  function addLp(uint256 _vaultId, uint256 _lpTokens) external;

  function removeLp(
    uint256 _vaultId,
    uint256 _shares,
    address to
  ) external;

  function getVaultInfo(uint256 _vaultId)
    external
    view
    returns (IERC20, uint256);

  function invest(
    uint256 _vaultId,
    uint256 _totalSenior,
    uint256 _totalJunior,
    uint256 _extraSenior,
    uint256 _extraJunior,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256 seniorInvested, uint256 juniorInvested);

  function sharesFromLp(uint256 vaultId, uint256 lpTokens)
    external
    view
    returns (
      uint256 shares,
      uint256 vaultShares,
      IERC20 pool
    );

  function lpFromShares(uint256 vaultId, uint256 shares)
    external
    view
    returns (uint256 lpTokens, uint256 vaultShares);

  function redeem(
    uint256 _vaultId,
    uint256 _seniorExpected,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function withdrawExcess(
    uint256 _vaultId,
    OLib.Tranche tranche,
    address to,
    uint256 amount
  ) external;

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITrancheToken is IERC20Upgradeable {
  function mint(address _account, uint256 _amount) external;

  function burn(address _account, uint256 _amount) external;

  function destroy(address payable _receiver) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Helper functions
 */
library OLib {
  using Arrays for uint256[];
  using OLib for OLib.Investor;

  // State transition per Vault. Just linear transitions.
  enum State {Inactive, Deposit, Live, Withdraw}

  // Only supports 2 tranches for now
  enum Tranche {Senior, Junior}

  struct VaultParams {
    address seniorAsset;
    address juniorAsset;
    address strategist;
    address strategy;
    uint256 hurdleRate;
    uint256 startTime;
    uint256 enrollment;
    uint256 duration;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
    uint256 seniorTrancheCap;
    uint256 seniorUserCap;
    uint256 juniorTrancheCap;
    uint256 juniorUserCap;
  }

  struct RolloverParams {
    VaultParams vault;
    address strategist;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
  }

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant PANIC_ROLE = keccak256("PANIC_ROLE");
  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
  bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
  bytes32 public constant ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
  bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");

  // Both sums are running sums. If a user deposits [$1, $5, $3], then
  // userSums would be [$1, $6, $9]. You can figure out the deposit
  // amount be subtracting userSums[i]-userSum[i-1].

  // prefixSums is the total deposited for all investors + this
  // investors deposit at the time this deposit is made. So at
  // prefixSum[0], it would be $1 + totalDeposits, where totalDeposits
  // could be $1000 because other investors have put in money.
  struct Investor {
    uint256[] userSums;
    uint256[] prefixSums;
    bool claimed;
    bool withdrawn;
  }

  /**
   * @dev Given the total amount invested by the Vault, we want to find
   *   out how many of this investor's deposits were actually
   *   used. Use findUpperBound on the prefixSum to find the point
   *   where total deposits were accepted. For example, if $2000 was
   *   deposited by all investors and $1000 was invested, then some
   *   position in the prefixSum splits the array into deposits that
   *   got in, and deposits that didn't get in. That same position
   *   maps to userSums. This is the user's deposits that got
   *   in. Since we are keeping track of the sums, we know at that
   *   position the total deposits for a user was $15, even if it was
   *   15 $1 deposits. And we know the amount that didn't get in is
   *   the last value in userSum - the amount that got it.

   * @param investor A specific investor
   * @param invested The total amount invested by this Vault
   */
  function getInvestedAndExcess(Investor storage investor, uint256 invested)
    internal
    view
    returns (uint256 userInvested, uint256 excess)
  {
    uint256[] storage prefixSums_ = investor.prefixSums;
    uint256 length = prefixSums_.length;
    if (length == 0) {
      // There were no deposits. Return 0, 0.
      return (userInvested, excess);
    }
    uint256 leastUpperBound = prefixSums_.findUpperBound(invested);
    if (length == leastUpperBound) {
      // All deposits got in, no excess. Return total deposits, 0
      userInvested = investor.userSums[length - 1];
      return (userInvested, excess);
    }
    uint256 prefixSum = prefixSums_[leastUpperBound];
    if (prefixSum == invested) {
      // Not all deposits got in, but there are no partial deposits
      userInvested = investor.userSums[leastUpperBound];
      excess = investor.userSums[length - 1] - userInvested;
    } else {
      // Let's say some of my deposits got in. The last deposit,
      // however, was $100 and only $30 got in. Need to split that
      // deposit so $30 got in, $70 is excess.
      userInvested = leastUpperBound > 0
        ? investor.userSums[leastUpperBound - 1]
        : 0;
      uint256 depositAmount = investor.userSums[leastUpperBound] - userInvested;
      if (prefixSum - depositAmount < invested) {
        userInvested += (depositAmount + invested - prefixSum);
        excess = investor.userSums[length - 1] - userInvested;
      } else {
        excess = investor.userSums[length - 1] - userInvested;
      }
    }
  }
}

/**
 * @title Subset of SafeERC20 from openZeppelin
 *
 * @dev Some non-standard ERC20 contracts (e.g. Tether) break
 * `approve` by forcing it to behave like `safeApprove`. This means
 * `safeIncreaseAllowance` will fail when it tries to adjust the
 * allowance. The code below simply adds an extra call to
 * `approve(spender, 0)`.
 */
library OndoSaferERC20 {
  using SafeERC20 for IERC20;

  function ondoSafeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    token.safeApprove(spender, 0);
    token.safeApprove(spender, newAllowance);
  }
}

