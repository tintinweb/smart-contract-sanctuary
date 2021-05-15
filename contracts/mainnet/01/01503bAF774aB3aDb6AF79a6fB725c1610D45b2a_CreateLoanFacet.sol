// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

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
import "./extensions/IERC20MetadataUpgradeable.sol";
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId
            || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControlStorageLib, AccessControlStorage } from "../storage.sol";

abstract contract ReentryMods {
    modifier nonReentry(bytes32 id) {
        AccessControlStorage storage s = AccessControlStorageLib.store();
        require(!s.entered[id], "AccessControl: reentered");
        s.entered[id] = true;
        _;
        s.entered[id] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RolesMods } from "./RolesMods.sol";
import { RolesLib } from "./RolesLib.sol";
import { ADMIN } from "../../../shared/roles.sol";

contract RolesFacet is RolesMods {
    /**
     * @notice Checks if an account has a specific role.
     * @param role Encoding of the role to check.
     * @param account Address to check the {role} for.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return RolesLib.hasRole(role, account);
    }

    /**
     * @notice Grants an account a new role.
     * @param role Encoding of the role to give.
     * @param account Address to give the {role} to.
     *
     * Requirements:
     *  - Sender must be role admin.
     */
    function grantRole(bytes32 role, address account)
        external
        authorized(ADMIN, msg.sender)
    {
        RolesLib.grantRole(role, account);
    }

    /**
     * @notice Removes a role from an account.
     * @param role Encoding of the role to remove.
     * @param account Address to remove the {role} from.
     *
     * Requirements:
     *  - Sender must be role admin.
     */
    function revokeRole(bytes32 role, address account)
        external
        authorized(ADMIN, msg.sender)
    {
        RolesLib.revokeRole(role, account);
    }

    /**
     * @notice Removes a role from the sender.
     * @param role Encoding of the role to remove.
     */
    function renounceRole(bytes32 role) external {
        RolesLib.revokeRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControlStorageLib, AccessControlStorage } from "../storage.sol";

library RolesLib {
    function s() private pure returns (AccessControlStorage storage) {
        return AccessControlStorageLib.store();
    }

    /**
     * @dev Emitted when `account` is granted `role`.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Checks if an account has a specific role.
     */
    function hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return s().roles[role][account];
    }

    /**
     * @dev Gives an account a new role.
     * @dev Should only use when circumventing admin checking.
     * @dev If account already has the role, no event is emitted.
     * @param role Encoding of the role to give.
     * @param account Address to give the {role} to.
     */
    function grantRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) return;
        s().roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Removes a role from an account.
     * @dev Should only use when circumventing admin checking.
     * @dev If account does not already have the role, no event is emitted.
     * @param role Encoding of the role to remove.
     * @param account Address to remove the {role} from.
     */
    function revokeRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) return;
        s().roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RolesLib } from "./RolesLib.sol";

abstract contract RolesMods {
    /**
     * @notice Requires that the {account} has {role}
     * @param role Encoding of the role to check.
     * @param account Address to check the {role} for.
     */
    modifier authorized(bytes32 role, address account) {
        require(
            RolesLib.hasRole(role, account),
            "AccessControl: not authorized"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AccessControlStorage {
    mapping(bytes32 => mapping(address => bool)) roles;
    mapping(address => address) owners;
    mapping(bytes32 => bool) entered;
}

bytes32 constant ACCESS_CONTROL_POS = keccak256(
    "teller.access_control.storage"
);

library AccessControlStorageLib {
    function store() internal pure returns (AccessControlStorage storage s) {
        bytes32 pos = ACCESS_CONTROL_POS;
        assembly {
            s.slot := pos
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
    // refer to the aave whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
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
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode { NONE, STABLE, VARIABLE }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IAToken {
    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount)
        external
        returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IAaveLendingPoolAddressesProvider.sol";
import "./DataTypes.sol";

interface IAaveLendingPool {
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
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (IAaveLendingPoolAddressesProvider);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface IAaveLendingPoolAddressesProvider {
    function getMarketId() external view returns (string memory);

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @notice This interface defines the different functions available for a Yearn Vault
    @author [email protected]
 */

interface IVault {
    /**
        @notice Returns the unwrapped native token address that the Vault takes as deposit
        @return The address of the unwrapped token
     */
    function token() external view returns (address);

    /**
        @notice Returns the vault's wrapped token name as a string, example 'yearn Dai Stablecoin'
        @return The name of the wrapped token
     */
    function name() external view returns (string memory);

    /**
        @notice Returns the vault's wrapped token symbol as a string, example 'yDai'
        @return The symbol of the wrapped token
     */
    function symbol() external view returns (string memory);

    /**
        @notice Returns the amount of decimals for this vault's wrapped token as a uin8
        @return The number of decimals for the token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
        @notice Returns the address of the Vault's controller
        @return The address of the controller contract
     */
    function controller() external view returns (address);

    /**
        @notice Returns the address of the Vault's governance contract
        @return The contract address
     */
    function governance() external view returns (address);

    /**
        @notice Returns the price of the Vault's wrapped token, denominated in the unwrapped native token
        @notice Calculation is: nativeTokenBalance/yTokenTotalSupply,
            - nativeTokenBalance is the current balance of the native token (example DAI) in the Vault
            - yTokenTotalSupply is the total supply of the Vault's wrapped token (example yDAI)
        @return The token price
     */
    function getPricePerFullShare() external view returns (uint256); // v1 vaults

    /**
        @notice Returns the price of the Vault's wrapped token, denominated in the unwrapped native token
        @notice Calculation is: nativeTokenBalance/yTokenTotalSupply,
            - nativeTokenBalance is the current balance of the native token (example DAI) in the Vault
            - yTokenTotalSupply is the total supply of the Vault's wrapped token (example yDAI)
        @return The token price
     */
    function getPricePerShare() external view returns (uint256); // v2 vaults

    /**
        @notice Deposits the specified amount of the native unwrapped token (same as token() returns) into the Vault
        @param amountToDeposit The amount of tokens to deposit
     */
    function deposit(uint256 amountToDeposit) external;

    /**
        @notice Deposits the maximum available amount of the native wrapped token (same as token()) into the Vault
     */
    function depositAll() external;

    /**
        @notice Withdraws the specified amount of the native unwrapped token (same as token() returns) from the Vault
        @param amountToWithdraw The amount to withdraw
     */
    function withdraw(uint256 amountToWithdraw) external;

    /**
        @notice Withdraws the maximum available amount of native unwrapped token (same as token()) from the Vault
     */
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAToken } from "../interfaces/IAToken.sol";
import { IAaveLendingPool } from "../interfaces/IAaveLendingPool.sol";
import {
    IAaveLendingPoolAddressesProvider
} from "../interfaces/IAaveLendingPoolAddressesProvider.sol";
import {
    IUniswapV2Router
} from "../../../shared/interfaces/IUniswapV2Router.sol";
import { IVault } from "../interfaces/IVault.sol";

// Libraries
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Storage
import { MarketStorageLib, MarketStorage } from "../../../storage/market.sol";
import { AppStorageLib } from "../../../storage/app.sol";

library LibDapps {
    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    /**
        @notice Grabs the Aave lending pool instance from the Aave lending pool address provider
        @return IAaveLendingPool instance address
     */
    function getAaveLendingPool() internal view returns (IAaveLendingPool) {
        return
            IAaveLendingPool(
                IAaveLendingPoolAddressesProvider(
                    0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
                )
                    .getLendingPool()
            ); // LP address provider contract is immutable and the address will never change
    }

    /**
        @notice Grabs the aToken instance from the lending pool
        @param tokenAddress The underlying asset address to get the aToken for
        @return IAToken instance
     */
    function getAToken(address tokenAddress) internal view returns (IAToken) {
        return
            IAToken(
                getAaveLendingPool().getReserveData(tokenAddress).aTokenAddress
            );
    }

    /**
        @notice Grabs the yVault address for a token from the asset settings
        @param tokenAddress The underlying token address for the associated yVault
        @return yVault instance
     */
    function getYVault(address tokenAddress) internal view returns (IVault) {
        return
            IVault(
                AppStorageLib.store().assetSettings[tokenAddress].addresses[
                    keccak256("yVaultAddress")
                ]
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoansEscrow {
    function init() external;

    function callDapp(address dappAddress, bytes calldata dappData)
        external
        returns (bytes memory);

    function setTokenAllowance(address token, address spender) external;

    function claimToken(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { LibDapps } from "../dapps/libraries/LibDapps.sol";
import { LibLoans } from "../../market/libraries/LibLoans.sol";
import { PriceAggLib } from "../../price-aggregator/PriceAggLib.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILoansEscrow } from "../escrow/ILoansEscrow.sol";

// Storage
import { MarketStorageLib, MarketStorage } from "../../storage/market.sol";

library LibEscrow {
    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function e(uint256 loanID) internal view returns (ILoansEscrow e_) {
        e_ = s().loanEscrows[loanID];
    }

    function getEscrowTokens(uint256 loanID)
        internal
        view
        returns (EnumerableSet.AddressSet storage t_)
    {
        t_ = s().escrowTokens[loanID];
    }

    function balanceOf(uint256 loanID, address token)
        internal
        view
        returns (uint256)
    {
        return IERC20(token).balanceOf(address(e(loanID)));
    }

    /**
     * @notice Adds or removes tokens held by the Escrow contract
     * @param loanID The loan ID to update the token list for
     * @param tokenAddress The token address to be added or removed
     */
    function tokenUpdated(uint256 loanID, address tokenAddress) internal {
        // Skip if is lending token
        if (LibLoans.loan(loanID).lendingToken == tokenAddress) return;

        EnumerableSet.AddressSet storage tokens = s().escrowTokens[loanID];
        bool contains = EnumerableSet.contains(tokens, tokenAddress);
        if (balanceOf(loanID, tokenAddress) > 0) {
            if (!contains) {
                EnumerableSet.add(tokens, tokenAddress);
            }
        } else if (contains) {
            EnumerableSet.remove(tokens, tokenAddress);
        }
    }

    /**
     * @notice Calculate the value of the loan by getting the value of all tokens the Escrow owns.
     * @param loanID The loan ID to calculate value for
     * @return value_ Escrow total value denoted in the lending token.
     */
    function calculateTotalValue(uint256 loanID)
        internal
        view
        returns (uint256 value_)
    {
        address lendingToken = LibLoans.loan(loanID).lendingToken;
        value_ += balanceOf(loanID, lendingToken);

        EnumerableSet.AddressSet storage tokens = getEscrowTokens(loanID);
        if (EnumerableSet.length(tokens) > 0) {
            for (uint256 i = 0; i < EnumerableSet.length(tokens); i++) {
                uint256 tokenBal =
                    balanceOf(loanID, EnumerableSet.at(tokens, i));
                value_ += PriceAggLib.valueFor(
                    EnumerableSet.at(tokens, i),
                    lendingToken,
                    tokenBal
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";

// Interfaces
import { ITToken } from "../ttoken/ITToken.sol";

// Storage
import { MarketStorageLib, MarketStorage } from "../../storage/market.sol";

library LendingLib {
    bytes32 internal constant ID = keccak256("LENDING");

    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function tToken(address asset) internal view returns (ITToken tToken_) {
        tToken_ = s().tTokens[asset];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    RolesFacet
} from "../../contexts2/access-control/roles/RolesFacet.sol";

/**
 * @notice This contract acts as an interface for the Teller token (TToken).
 *
 * @author [email protected]
 */
abstract contract ITToken is ERC20Upgradeable, RolesFacet {
    /**
     * @notice This event is emitted when an user deposits tokens into the pool.
     */
    event Mint(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice This event is emitted when an user withdraws tokens from the pool.
     */
    event Redeem(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice The token that is the underlying assets for this Teller token.
     */
    function underlying() external view virtual returns (ERC20);

    /**
     * @notice The balance of an {account} denoted in underlying value.
     * @param account Address to calculate the underlying balance.
     */
    function balanceOfUnderlying(address account)
        external
        virtual
        returns (uint256 balance_);

    /**
     * @notice It calculates the current exchange rate for a whole Teller Token based of the underlying token balance.
     * @return rate_ The current exchange rate.
     */
    function exchangeRate() external virtual returns (uint256 rate_);

    /**
     * @notice Redeem supplied Teller token underlying value.
     * @return totalSupply_ The total value of the underlying token managed by the LP.
     */
    function totalUnderlyingSupply()
        external
        virtual
        returns (uint256 totalSupply_);

    /**
     * @notice It calculates the market state values across a given markets.
     * @notice Returns values that represent the global state across the market.
     * @return totalSupplied Total amount of the underlying asset supplied.
     * @return totalBorrowed Total amount borrowed through loans.
     * @return totalRepaid The total amount repaid till the current timestamp.
     * @return totalInterestRepaid The total amount interest repaid till the current timestamp.
     * @return totalOnLoan Total amount currently deployed in loans.
     */
    function getMarketState()
        external
        virtual
        returns (
            uint256 totalSupplied,
            uint256 totalBorrowed,
            uint256 totalRepaid,
            uint256 totalInterestRepaid,
            uint256 totalOnLoan
        );

    /**
     * @notice Calculates the current Total Value Locked, denoted in the underlying asset, in the Teller Token pool.
     * @return tvl_ The value locked in the pool.
     *
     * Note: This value includes the amount that is on loan (including ones that were sent to EOAs).
     */
    function currentTVL() external virtual returns (uint256 tvl_);

    /**
     * @notice It validates whether supply to debt (StD) ratio is valid including the loan amount.
     * @param newLoanAmount the new loan amount to consider o the StD ratio.
     * @return ratio_ Whether debt ratio for lending pool is valid.
     */
    function debtRatioFor(uint256 newLoanAmount)
        external
        virtual
        returns (uint16 ratio_);

    /**
     * @notice Called by the Teller Diamond contract when a loan has been taken out and requires funds.
     * @param recipient The account to send the funds to.
     * @param amount Funds requested to fulfil the loan.
     */
    function fundLoan(address recipient, uint256 amount) external virtual;

    /**
     * @notice Called by the Teller Diamond contract when a loan has been repaid.
     * @param amount Funds deposited back into the pool to repay the principal amount of a loan.
     * @param interestAmount Interest value paid into the pool from a loan.
     */
    function repayLoan(uint256 amount, uint256 interestAmount) external virtual;

    /**
     * @notice Increase account supply of specified token amount.
     * @param amount The amount of underlying tokens to use to mint.
     */
    function mint(uint256 amount)
        external
        virtual
        returns (uint256 mintAmount_);

    /**
     * @notice Redeem supplied Teller token underlying value.
     * @param amount The amount of Teller tokens to redeem.
     */
    function redeem(uint256 amount) external virtual;

    /**
     * @notice Redeem supplied underlying value.
     * @param amount The amount of underlying tokens to redeem.
     */
    function redeemUnderlying(uint256 amount) external virtual;

    /**
     * @notice Rebalances the funds controlled by Teller Token according to the current strategy.
     *
     * See {TTokenStrategy}.
     */
    function rebalance() external virtual;

    /**
     * @notice Sets a new strategy to use for balancing funds.
     * @param strategy Address to the new strategy contract. Must implement the {ITTokenStrategy} interface.
     * @param initData Optional data to initialize the strategy.
     *
     * Requirements:
     *  - Sender must have ADMIN role
     */
    function setStrategy(address strategy, bytes calldata initData)
        external
        virtual;

    /**
     * @notice Gets the strategy used for balancing funds.
     */
    function getStrategy() external view virtual returns (address);

    /**
     * @notice Sets the restricted state of the platform.
     */
    function restrict(bool state) external virtual;

    function initialize(address admin, address underlying) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { PausableMods } from "../settings/pausable/PausableMods.sol";
import {
    ReentryMods
} from "../contexts2/access-control/reentry/ReentryMods.sol";
import { RolesMods } from "../contexts2/access-control/roles/RolesMods.sol";
import { AUTHORIZED } from "../shared/roles.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Libraries
import { LibLoans } from "./libraries/LibLoans.sol";
import { LibEscrow } from "../escrow/libraries/LibEscrow.sol";
import { LibCollateral } from "./libraries/LibCollateral.sol";
import { LibConsensus } from "./libraries/LibConsensus.sol";
import { LendingLib } from "../lending/libraries/LendingLib.sol";
import {
    PlatformSettingsLib
} from "../settings/platform/libraries/PlatformSettingsLib.sol";
import {
    MaxDebtRatioLib
} from "../settings/asset/libraries/MaxDebtRatioLib.sol";
import {
    MaxLoanAmountLib
} from "../settings/asset/libraries/MaxLoanAmountLib.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { NumbersLib } from "../shared/libraries/NumbersLib.sol";
import { NFTLib, NftLoanSizeProof } from "../nft/libraries/NFTLib.sol";

// Interfaces
import { ILoansEscrow } from "../escrow/escrow/ILoansEscrow.sol";

// Proxy
import {
    BeaconProxy
} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

// Storage
import {
    LoanRequest,
    LoanResponse,
    LoanStatus,
    LoanTerms,
    Loan,
    MarketStorageLib
} from "../storage/market.sol";
import { AppStorageLib } from "../storage/app.sol";

contract CreateLoanFacet is RolesMods, ReentryMods, PausableMods {
    /**
     * @notice This event is emitted when loan terms have been successfully set
     * @param loanID ID of loan from which collateral was withdrawn
     * @param borrower Account address of the borrower
     */
    event LoanTermsSet(uint256 indexed loanID, address indexed borrower);

    /**
     * @notice This event is emitted when a loan has been successfully taken out
     * @param loanID ID of loan from which collateral was withdrawn
     * @param borrower Account address of the borrower
     * @param amountBorrowed Total amount taken out in the loan
     * @param withNFT Boolean indicating if the loan was taken out using NFTs
     */
    event LoanTakenOut(
        uint256 indexed loanID,
        address indexed borrower,
        uint256 amountBorrowed,
        bool withNFT
    );

    /**
     * @notice Creates a loan with the loan request and terms
     * @param request Struct of the protocol loan request
     * @param responses List of structs of the protocol loan responses
     * @param collateralToken Token address to use as collateral for the new loan
     * @param collateralAmount Amount of collateral required for the loan
     */
    function createLoanWithTerms(
        LoanRequest calldata request,
        LoanResponse[] calldata responses,
        address collateralToken,
        uint256 collateralAmount
    )
        external
        payable
        paused(LibLoans.ID, false)
        nonReentry("")
        authorized(AUTHORIZED, msg.sender)
    {
        CreateLoanLib.verifyCreateLoan(request, collateralToken);
        uint256 loanID =
            CreateLoanLib.initLoan(request, responses, collateralToken);

        // Pay in collateral
        if (collateralAmount > 0) {
            LibCollateral.deposit(loanID, collateralAmount);
        }

        emit LoanTermsSet(loanID, msg.sender);
    }

    function takeOutLoanWithNFTs(
        uint256 loanID,
        uint256 amount,
        NftLoanSizeProof[] calldata proofs
    ) external paused(LibLoans.ID, false) __takeOutLoan(loanID, amount) {
        uint256 allowedLoanSize;
        for (uint256 i; i < proofs.length; i++) {
            NFTLib.applyToLoan(loanID, proofs[i]);

            allowedLoanSize += proofs[i].baseLoanSize;
            if (allowedLoanSize >= amount) {
                break;
            }
        }
        require(
            amount <= allowedLoanSize,
            "Teller: insufficient NFT loan size"
        );

        // Pull funds from Teller Token LP and transfer to the new loan escrow
        LendingLib.tToken(LibLoans.loan(loanID).lendingToken).fundLoan(
            CreateLoanLib.createEscrow(loanID),
            amount
        );

        emit LoanTakenOut(loanID, msg.sender, amount, true);
    }

    modifier __takeOutLoan(uint256 loanID, uint256 amount) {
        Loan storage loan = LibLoans.loan(loanID);

        require(msg.sender == loan.borrower, "Teller: not borrower");
        require(loan.status == LoanStatus.TermsSet, "Teller: loan not set");
        require(
            uint256(LibLoans.terms(loanID).termsExpiry) >= block.timestamp,
            "Teller: loan terms expired"
        );
        require(
            LendingLib.tToken(loan.lendingToken).debtRatioFor(amount) <=
                MaxDebtRatioLib.get(loan.lendingToken),
            "Teller: max supply-to-debt ratio exceeded"
        );
        require(
            LibLoans.terms(loanID).maxLoanAmount >= amount,
            "Teller: max loan amount exceeded"
        );

        loan.borrowedAmount = amount;
        LibLoans.debt(loanID).principalOwed = amount;
        LibLoans.debt(loanID).interestOwed = LibLoans.getInterestOwedFor(
            uint256(loan.id),
            amount
        );
        loan.status = LoanStatus.Active;
        loan.loanStartTime = uint32(block.timestamp);

        _;
    }

    /**
     * @notice Take out a loan
     *
     * @dev collateral ratio is a percentage of the loan amount that's required in collateral
     * @dev the percentage will be *(10**2). I.e. collateralRatio of 5244 means 52.44% collateral
     * @dev is required in the loan. Interest rate is also a percentage with 2 decimal points.
     */
    function takeOutLoan(uint256 loanID, uint256 amount)
        external
        paused(LibLoans.ID, false)
        nonReentry("")
        authorized(AUTHORIZED, msg.sender)
        __takeOutLoan(loanID, amount)
    {
        {
            // Check that enough collateral has been provided for this loan
            (, uint256 neededInCollateral, ) =
                LibLoans.getCollateralNeededInfo(loanID);
            require(
                neededInCollateral <=
                    LibCollateral.e(loanID).loanSupply(loanID),
                "Teller: more collateral required"
            );
        }

        Loan storage loan = MarketStorageLib.store().loans[loanID];
        address loanRecipient;
        bool eoaAllowed =
            LibLoans.canGoToEOAWithCollateralRatio(loan.collateralRatio);
        if (eoaAllowed) {
            loanRecipient = loan.borrower;
        } else {
            loanRecipient = CreateLoanLib.createEscrow(loanID);
        }

        // Pull funds from Teller token LP and and transfer to the recipient
        LendingLib.tToken(LibLoans.loan(loanID).lendingToken).fundLoan(
            loanRecipient,
            amount
        );

        emit LoanTakenOut(loanID, msg.sender, amount, false);
    }
}

library CreateLoanLib {
    function verifyCreateLoan(
        LoanRequest calldata request,
        address collateralToken
    ) internal view {
        // Perform loan request checks
        require(msg.sender == request.borrower, "Teller: not loan requester");
        require(
            PlatformSettingsLib.getMaximumLoanDurationValue() >=
                request.duration,
            "Teller: max loan duration exceeded"
        );
        // Verify collateral token is acceptable
        require(
            EnumerableSet.contains(
                MarketStorageLib.store().collateralTokens[request.assetAddress],
                collateralToken
            ),
            "Teller: collateral token not allowed"
        );
        require(
            MaxLoanAmountLib.get(request.assetAddress) > request.amount,
            "Teller: asset max loan amount exceeded"
        );
    }

    function initLoan(
        LoanRequest calldata request,
        LoanResponse[] calldata responses,
        address collateralToken
    ) internal returns (uint256 loanID_) {
        // Get consensus values from request
        (uint16 interestRate, uint16 collateralRatio, uint256 maxLoanAmount) =
            LibConsensus.processLoanTerms(request, responses);

        // Get and increment new loan ID
        loanID_ = CreateLoanLib.newID();
        LibLoans.terms(loanID_).maxLoanAmount = maxLoanAmount;
        LibLoans.terms(loanID_).termsExpiry = uint32(
            block.timestamp + PlatformSettingsLib.getTermsExpiryTimeValue()
        );
        LibLoans.loan(loanID_).id = uint128(loanID_);
        LibLoans.loan(loanID_).status = LoanStatus.TermsSet;
        LibLoans.loan(loanID_).lendingToken = request.assetAddress;
        LibLoans.loan(loanID_).collateralToken = collateralToken;
        LibLoans.loan(loanID_).borrower = request.borrower;
        LibLoans.loan(loanID_).interestRate = interestRate;
        LibLoans.loan(loanID_).collateralRatio = collateralRatio;
        LibLoans.loan(loanID_).duration = request.duration;

        // Add loanID to borrower list
        MarketStorageLib.store().borrowerLoans[request.borrower].push(
            uint128(loanID_)
        );
    }

    function newID() internal returns (uint256 id_) {
        Counters.Counter storage counter =
            MarketStorageLib.store().loanIDCounter;
        id_ = Counters.current(counter);
        Counters.increment(counter);
    }

    function createEscrow(uint256 loanID) internal returns (address escrow_) {
        // Create escrow
        escrow_ = AppStorageLib.store().loansEscrowBeacon.cloneProxy("");
        ILoansEscrow(escrow_).init();
        // Save escrow address for loan
        MarketStorageLib.store().loanEscrows[loanID] = ILoansEscrow(escrow_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollateralEscrow {
    function init(address tokenAddress, bool isWETH) external;

    function deposit(uint256 loanID, uint256 amount) external payable;

    function withdraw(
        uint256 loanID,
        uint256 amount,
        address payable receiver
    ) external;

    function loanSupply(uint256 loanID) external view returns (uint256 supply_);

    function totalSupply() external view returns (uint256 supply_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ICollateralEscrow } from "../collateral/ICollateralEscrow.sol";

// Storage
import { AppStorageLib } from "../../storage/app.sol";
import { MarketStorageLib } from "../../storage/market.sol";

library LibCollateral {
    /**
     * @notice This event is emitted when collateral has been deposited for the loan
     * @param loanID ID of the loan for which collateral was deposited
     * @param depositor Account that deposited funds
     * @param amount Amount of collateral deposited
     */
    event CollateralDeposited(
        uint256 indexed loanID,
        address indexed depositor,
        uint256 amount
    );

    /**
     * @notice This event is emitted when collateral has been withdrawn
     * @param loanID ID of loan from which collateral was withdrawn
     * @param receiver Account that received funds
     * @param amount Value of collateral withdrawn
     */
    event CollateralWithdrawn(
        uint256 indexed loanID,
        address indexed receiver,
        uint256 amount
    );

    function e(uint256 loanID) internal view returns (ICollateralEscrow c_) {
        c_ = MarketStorageLib.store().collateralEscrows[
            MarketStorageLib.store().loans[loanID].collateralToken
        ];
    }

    function e(address token) internal view returns (ICollateralEscrow c_) {
        c_ = MarketStorageLib.store().collateralEscrows[token];
    }

    function deposit(uint256 loanID, uint256 amount) internal {
        e(loanID).deposit{ value: amount }(loanID, amount);

        emit CollateralDeposited(loanID, msg.sender, amount);
    }

    function withdraw(
        uint256 loanID,
        uint256 amount,
        address payable receiver
    ) internal {
        e(loanID).withdraw(loanID, amount, receiver);

        emit CollateralWithdrawn(loanID, receiver, amount);
    }

    function withdrawAll(uint256 loanID, address payable receiver) internal {
        withdraw(loanID, e(loanID).loanSupply(loanID), receiver);
    }

    function createEscrow(address token) internal {
        // Check if collateral escrow exists
        if (address(e(token)) == address(0)) {
            // Create escrow
            address escrow =
                AppStorageLib.store().collateralEscrowBeacon.cloneProxy("");
            ICollateralEscrow(escrow).init(
                token,
                // Check if collateral token is WETH
                token == AppStorageLib.store().assetAddresses["WETH"]
            );

            // Set max allowance
            IERC20(token).approve(escrow, type(uint256).max);
            // Save escrow address for loan
            MarketStorageLib.store().collateralEscrows[
                token
            ] = ICollateralEscrow(escrow);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorageLib } from "../../storage/app.sol";
import {
    MarketStorageLib,
    MarketStorage,
    LoanRequest,
    LoanResponse,
    Signature
} from "../../storage/market.sol";
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";
import { NumbersList } from "../../shared/libraries/NumbersList.sol";
import {
    PlatformSettingsLib
} from "../../settings/platform/libraries/PlatformSettingsLib.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { RolesLib } from "../../contexts2/access-control/roles/RolesLib.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibConsensus {
    using NumbersList for NumbersList.Values;

    /**
     * @notice Represents loan terms based on consensus values
     * @param interestRate The consensus value for the interest rate based on all the loan responses from the signers
     * @param collateralRatio The consensus value for the ratio of collateral to loan amount required for the loan, based on all the loan responses from the signers
     * @param maxLoanAmount The consensus value for the largest amount of tokens that can be taken out in the loan, based on all the loan responses from the signers
     */
    struct AccruedLoanTerms {
        NumbersList.Values interestRate;
        NumbersList.Values collateralRatio;
        NumbersList.Values maxLoanAmount;
    }

    function s() private pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function processLoanTerms(
        LoanRequest calldata request,
        LoanResponse[] calldata responses
    )
        internal
        view
        returns (
            uint16 interestRate,
            uint16 collateralRatio,
            uint256 maxLoanAmount
        )
    {
        EnumerableSet.AddressSet storage signers =
            s().signers[request.assetAddress];
        require(
            uint256(
                NumbersLib.ratioOf(
                    responses.length,
                    EnumerableSet.length(signers)
                )
            ) >= PlatformSettingsLib.getRequiredSubmissionsPercentageValue(),
            "Teller: insufficient signer responses"
        );

        _validateLoanRequest(request.borrower, request.requestNonce);

        uint32 chainId = _getChainId();
        bytes32 requestHash = _hashRequest(request, chainId);

        AccruedLoanTerms memory termSubmissions;

        for (uint256 i = 0; i < responses.length; i++) {
            LoanResponse memory response = responses[i];

            require(
                EnumerableSet.contains(signers, response.signer),
                "Teller: invalid signer"
            );
            require(
                response.assetAddress == request.assetAddress,
                "Teller: consensus address mismatch"
            );
            require(
                uint256(response.responseTime) >=
                    block.timestamp -
                        PlatformSettingsLib.getTermsExpiryTimeValue(),
                "Teller: consensus response expired"
            );
            require(
                _signatureValid(
                    response.signature,
                    _hashResponse(requestHash, response, chainId),
                    response.signer
                ),
                "Teller: response signature invalid"
            );

            // TODO: use a local AddressArrayLib instead to save gas
            for (uint8 j = 0; j < i; j++) {
                require(
                    response.signer != responses[j].signer,
                    "Teller: dup signer response"
                );
            }

            termSubmissions.interestRate.addValue(response.interestRate);
            termSubmissions.collateralRatio.addValue(response.collateralRatio);
            termSubmissions.maxLoanAmount.addValue(response.maxLoanAmount);
        }

        uint16 tolerance =
            uint16(PlatformSettingsLib.getMaximumToleranceValue());
        interestRate = uint16(
            _getConsensus(termSubmissions.interestRate, tolerance)
        );
        collateralRatio = uint16(
            _getConsensus(termSubmissions.collateralRatio, tolerance)
        );
        maxLoanAmount = _getConsensus(termSubmissions.maxLoanAmount, tolerance);
    }

    /**
     * @dev Checks if the nonce provided in the request is equal to the borrower's number of loans.
     * @dev Also verifies if the borrower has taken out a loan recently (rate limit).
     * @param borrower the borrower's address.
     * @param nonce the nonce included in the loan request.
     */
    function _validateLoanRequest(address borrower, uint256 nonce)
        private
        view
    {
        uint128[] storage borrowerLoans = s().borrowerLoans[borrower];
        uint256 numberOfLoans = borrowerLoans.length;

        require(nonce == numberOfLoans, "Teller: bad request nonce");

        // In case it is the first time that borrower requests loan terms, we don't
        // validate the rate limit.
        if (numberOfLoans == 0) {
            return;
        }

        require(
            uint256(
                s().loans[uint256(borrowerLoans[numberOfLoans - 1])]
                    .loanStartTime
            ) +
                PlatformSettingsLib.getRequestLoanTermsRateLimitValue() <=
                block.timestamp,
            "Teller: loan terms rate limit reached"
        );
    }

    /**
     * @notice Gets the current chain id using the opcode 'chainid()'.
     * @return id_ The current chain id.
     */
    function _getChainId() private view returns (uint32 id_) {
        // silence state mutability warning without generating bytecode.
        // see https://github.com/ethereum/solidity/issues/2691
        assembly {
            id_ := chainid()
        }
    }

    /**
     * @notice Generates a hash for the loan request
     * @param request Struct of the protocol loan request
     * @return bytes32 Hash of the loan request
     */
    function _hashRequest(LoanRequest memory request, uint32 chainId)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    request.borrower,
                    request.assetAddress,
                    request.amount,
                    request.requestNonce,
                    request.duration,
                    request.requestTime,
                    chainId
                )
            );
    }

    /**
     * @notice Generates a hash for the loan response
     * @param requestHash Hash of the loan request
     * @param response Structs of the protocol loan responses
     * @return bytes32 Hash of the loan response
     */
    function _hashResponse(
        bytes32 requestHash,
        LoanResponse memory response,
        uint32 chainId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    response.assetAddress,
                    response.maxLoanAmount,
                    requestHash,
                    response.responseTime,
                    response.interestRate,
                    response.collateralRatio,
                    chainId
                )
            );
    }

    /**
     * @notice It validates whether a signature is valid or not.
     * @param signature signature to validate.
     * @param dataHash used to recover the signer.
     * @param expectedSigner the expected signer address.
     * @return true if the expected signer is equal to the signer. Otherwise it returns false.
     */
    function _signatureValid(
        Signature memory signature,
        bytes32 dataHash,
        address expectedSigner
    ) internal pure returns (bool) {
        return
            expectedSigner ==
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        dataHash
                    )
                ),
                signature.v,
                signature.r,
                signature.s
            );
    }

    /**
     * @notice Gets the consensus value for a list of values (uint values).
     * @notice The values must be in a maximum tolerance range.
     * @return the consensus value.
     */
    function _getConsensus(NumbersList.Values memory values, uint16 tolerance)
        internal
        pure
        returns (uint256)
    {
        require(
            values.isWithinTolerance(tolerance),
            "Teller: consensus response values too varied"
        );

        return values.getAverage();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { LibEscrow } from "../../escrow/libraries/LibEscrow.sol";
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";
import {
    PlatformSettingsLib
} from "../../settings/platform/libraries/PlatformSettingsLib.sol";
import { PriceAggLib } from "../../price-aggregator/PriceAggLib.sol";

// Storage
import {
    MarketStorageLib,
    MarketStorage,
    Loan,
    LoanStatus,
    LoanDebt,
    LoanTerms
} from "../../storage/market.sol";

library LibLoans {
    using NumbersLib for int256;
    using NumbersLib for uint256;

    bytes32 internal constant ID = keccak256("LOANS");
    uint32 internal constant SECONDS_PER_YEAR = 31536000;

    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function loan(uint256 loanID) internal view returns (Loan storage l_) {
        l_ = s().loans[loanID];
    }

    function debt(uint256 loanID) internal view returns (LoanDebt storage d_) {
        d_ = s().loanDebt[loanID];
    }

    function terms(uint256 loanID)
        internal
        view
        returns (LoanTerms storage t_)
    {
        t_ = s().loanTerms[loanID];
    }

    /**
     * @notice Returns the total amount owed for a specified loan.
     * @param loanID The loan ID to get the total amount owed.
     * @return uint256 The total owed amount.
     */
    function getTotalOwed(uint256 loanID) internal view returns (uint256) {
        if (loan(loanID).status == LoanStatus.TermsSet) {
            uint256 interestOwed =
                getInterestOwedFor(loanID, terms(loanID).maxLoanAmount);
            return terms(loanID).maxLoanAmount + (interestOwed);
        } else if (loan(loanID).status == LoanStatus.Active) {
            return debt(loanID).principalOwed + (debt(loanID).interestOwed);
        }
        return 0;
    }

    /**
     * @notice Returns the amount of interest owed for a given loan and loan amount.
     * @param loanID The loan ID to get the owed interest.
     * @param amountBorrow The principal of the loan to take out.
     * @return uint256 The interest owed.
     */
    function getInterestOwedFor(uint256 loanID, uint256 amountBorrow)
        internal
        view
        returns (uint256)
    {
        return amountBorrow.percent(uint16(getInterestRatio(loanID)));
    }

    function getCollateralNeededInfo(uint256 loanID)
        internal
        view
        returns (
            uint256 neededInLendingTokens,
            uint256 neededInCollateralTokens,
            uint256 escrowLoanValue
        )
    {
        (neededInLendingTokens, escrowLoanValue) = getCollateralNeededInTokens(
            loanID
        );

        if (neededInLendingTokens == 0) {
            neededInCollateralTokens = 0;
        } else {
            neededInCollateralTokens = PriceAggLib.valueFor(
                loan(loanID).lendingToken,
                loan(loanID).collateralToken,
                neededInLendingTokens
            );
        }
    }

    /**
     * @notice Returns the minimum collateral value threshold, in the lending token, needed to take out the loan or for it be liquidated.
     * @dev If the loan status is TermsSet, then the value is whats needed to take out the loan.
     * @dev If the loan status is Active, then the value is the threshold at which the loan can be liquidated at.
     * @param loanID The loan ID to get needed collateral info for.
     * @return neededInLendingTokens int256 The minimum collateral value threshold required.
     * @return escrowLoanValue uint256 The value of the loan held in the escrow contract.
     */
    function getCollateralNeededInTokens(uint256 loanID)
        internal
        view
        returns (uint256 neededInLendingTokens, uint256 escrowLoanValue)
    {
        if (!_isActiveOrSet(loanID) || loan(loanID).collateralRatio == 0) {
            return (0, 0);
        }

        /*
            The collateral to principal owed ratio is the sum of:
                * collateral buffer percent
                * loan interest rate
                * liquidation reward percent
                * X factor of additional collateral
        */
        // * To take out a loan (if status == TermsSet), the required collateral is (max loan amount * the collateral ratio).
        // * For the loan to not be liquidated (when status == Active), the minimum collateral is (principal owed * (X collateral factor + liquidation reward)).
        // * If the loan has an escrow account, the minimum collateral is ((principal owed - escrow value) * (X collateral factor + liquidation reward)).
        if (loan(loanID).status == LoanStatus.TermsSet) {
            neededInLendingTokens = _getLoanAmount(loanID).percent(
                loan(loanID).collateralRatio
            );
        } else {
            uint16 requiredRatio =
                loan(loanID).collateralRatio -
                    getInterestRatio(loanID) -
                    uint16(PlatformSettingsLib.getCollateralBufferValue());

            neededInLendingTokens =
                debt(loanID).principalOwed +
                debt(loanID).interestOwed;
            escrowLoanValue = LibEscrow.calculateTotalValue(loanID);
            if (
                escrowLoanValue > 0 && neededInLendingTokens > escrowLoanValue
            ) {
                neededInLendingTokens -= escrowLoanValue;
            }
            neededInLendingTokens = neededInLendingTokens.percent(
                requiredRatio
            );
        }
    }

    function canGoToEOAWithCollateralRatio(uint256 collateralRatio)
        internal
        view
        returns (bool)
    {
        return
            collateralRatio >=
            PlatformSettingsLib.getOverCollateralizedBufferValue();
    }

    /**
     * @notice Returns the interest ratio based on the loan interest rate for the loan duration.
     * @notice There is a minimum threshold of 1%.
     * @dev The interest rate on the loan terms is APY.
     * @param loanID The loan ID to get the interest rate for.
     */
    function getInterestRatio(uint256 loanID)
        internal
        view
        returns (uint16 ratio_)
    {
        ratio_ = uint16(
            (uint64(loan(loanID).duration) * loan(loanID).interestRate) /
                SECONDS_PER_YEAR
        );

        if (ratio_ == 0) {
            ratio_ = 1;
        }
    }

    function _getLoanAmount(uint256 loanID) private view returns (uint256) {
        if (loan(loanID).status == LoanStatus.TermsSet) {
            return terms(loanID).maxLoanAmount;
        } else if (loan(loanID).status == LoanStatus.Active) {
            return loan(loanID).borrowedAmount;
        }
        return 0;
    }

    function _isActiveOrSet(uint256 loanID) private view returns (bool) {
        LoanStatus status = loan(loanID).status;
        return status == LoanStatus.Active || status == LoanStatus.TermsSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Interfaces
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ITellerNFT {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    /**
     * @notice The contract metadata URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param index Tier index to get info.
     */
    function getTier(uint256 index) external view returns (Tier memory tier_);

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function getTokenTier(uint256 tokenId)
        external
        view
        returns (uint256 index_, Tier memory tier_);

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getTierHashes(uint256 tierIndex)
        external
        view
        returns (string[] memory hashes_);

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getOwnedTokens(address owner)
        external
        view
        returns (uint256[] memory owned);

    /**
     * @notice It mints a new token for a Tier index.
     *
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(uint256 tierIndex, address owner) external;

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {MINTER} role
     */
    function addTier(Tier memory newTier) external;

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash) external;

    /**
     * @notice Initializes the TellerNFT.
     * @param minters The addresses that should allowed to mint tokens.
     */
    function initialize(address[] calldata minters) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interfaces
import "./ITellerNFT.sol";

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                                  THIS CONTRACT IS UPGRADEABLE!                                  **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT change the order of or PREPEND any storage variables to this or new versions of this    **/
/**  contract as this will cause the the storage slots to be overwritten on the proxy contract!!    **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice This contract is used by borrowers to call Dapp functions (using delegate calls).
 * @notice This contract should only be constructed using it's upgradeable Proxy contract.
 * @notice In order to call a Dapp function, the Dapp must be added in the DappRegistry instance.
 *
 * @author [email protected]
 */
contract TellerNFT is ITellerNFT, ERC721Upgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    /* Constants */

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");

    /* State Variables */

    // It holds the total number of tiers.
    Counters.Counter internal _tierCounter;

    // It holds the total number of tokens minted.
    Counters.Counter internal _tokenCounter;

    // It holds the information about a tier.
    mapping(uint256 => Tier) internal _tiers;

    // It holds which tier a token ID is in.
    mapping(uint256 => uint256) internal _tokenTier;

    // It holds a set of token IDs for an owner address.
    mapping(address => EnumerableSet.UintSet) internal _ownerTokenIDs;

    // Link to the contract metadata
    string private _metadataBaseURI;

    // Hash to the contract metadata located on the {_metadataBaseURI}
    string private _contractURIHash;

    /* Modifiers */

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "TellerNFT: not admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER, _msgSender()), "TellerNFT: not minter");
        _;
    }

    /* External Functions */

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param index Tier index to get info.
     */
    function getTier(uint256 index)
        external
        view
        override
        returns (Tier memory tier_)
    {
        tier_ = _tiers[index];
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function getTokenTier(uint256 tokenId)
        external
        view
        override
        returns (uint256 index_, Tier memory tier_)
    {
        index_ = _tokenTier[tokenId];
        tier_ = _tiers[index_];
    }

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getTierHashes(uint256 tierIndex)
        external
        view
        override
        returns (string[] memory hashes_)
    {
        hashes_ = _tiers[tierIndex].hashes;
    }

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getOwnedTokens(address owner)
        external
        view
        override
        returns (uint256[] memory owned_)
    {
        EnumerableSet.UintSet storage set = _ownerTokenIDs[owner];
        owned_ = new uint256[](set.length());
        for (uint256 i; i < owned_.length; i++) {
            owned_[i] = set.at(i);
        }
    }

    /**
     * @notice The contract metadata URI.
     */
    function contractURI() external view override returns (string memory) {
        return _contractURIHash;
    }

    /**
     * @notice The token URI is based on the token ID.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "TellerNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenURIHash(tokenId)))
                : "";
    }

    /**
     * @notice It mints a new token for a Tier index.
     * @param tierIndex Tier to mint token on.
     * @param owner The owner of the new token.
     *
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(uint256 tierIndex, address owner)
        external
        override
        onlyMinter
    {
        // Get the new token ID
        uint256 tokenId = _tokenCounter.current();
        _tokenCounter.increment();

        // Mint and set the token to the tier index
        _safeMint(owner, tokenId);
        _tokenTier[tokenId] = tierIndex;

        // Set owner
        _setOwner(owner, tokenId);
    }

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {MINTER} role
     */
    function addTier(Tier memory newTier) external override onlyMinter {
        Tier storage tier = _tiers[_tierCounter.current()];

        tier.baseLoanSize = newTier.baseLoanSize;
        tier.hashes = newTier.hashes;
        tier.contributionAsset = newTier.contributionAsset;
        tier.contributionSize = newTier.contributionSize;
        tier.contributionMultiplier = newTier.contributionMultiplier;

        _tierCounter.increment();
    }

    function removeMinter(address minter) external onlyMinter {
        revokeRole(MINTER, minter);
    }

    function addMinter(address minter) public onlyMinter {
        _setupRole(MINTER, minter);
    }

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash)
        external
        override
        onlyAdmin
    {
        _contractURIHash = contractURIHash;
    }

    /**
     * @notice Initializes the TellerNFT.
     * @param minters The addresses that should allowed to mint tokens.
     */
    function initialize(address[] calldata minters)
        external
        override
        initializer
    {
        __ERC721_init("Teller NFT", "TNFT");
        __AccessControl_init();

        for (uint256 i; i < minters.length; i++) {
            _setupRole(MINTER, minters[i]);
        }

        _metadataBaseURI = "https://gateway.pinata.cloud/ipfs/";
        _contractURIHash = "QmWAfQFFwptzRUCdF2cBFJhcB2gfHJMd7TQt64dZUysk3R";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(ITellerNFT).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice It returns the hash to use for the token URI.
     */
    function _tokenURIHash(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string[] storage tierImageHashes = _tiers[_tokenTier[tokenId]].hashes;
        return tierImageHashes[tokenId.mod(tierImageHashes.length)];
    }

    /**
     * @notice The base URI path where the token media is hosted.
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    /**
     * @notice Moves token to new owner set and then transfers.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        _setOwner(to, tokenId);
        super._transfer(from, to, tokenId);
    }

    /**
     * @notice It removes the token from the current owner set and adds to new owner.
     */
    function _setOwner(address newOwner, uint256 tokenId) internal {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != address(0)) {
            _ownerTokenIDs[currentOwner].remove(tokenId);
        }
        _ownerTokenIDs[newOwner].add(tokenId);
    }

    function _msgData() internal pure override returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { TellerNFT } from "../TellerNFT.sol";

// Libraries
import {
    MerkleProof
} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Storage
import { AppStorageLib, AppStorage } from "../../storage/app.sol";
import { NFTStorageLib, NFTStorage } from "../../storage/nft.sol";

struct NftLoanSizeProof {
    uint256 id;
    uint256 baseLoanSize;
    bytes32[] proof;
}

library NFTLib {
    function s() internal pure returns (NFTStorage storage s_) {
        s_ = NFTStorageLib.store();
    }

    function nft() internal view returns (TellerNFT nft_) {
        nft_ = AppStorageLib.store().nft;
    }

    function stake(uint256 nftID, address owner) internal {
        // Transfer to diamond
        NFTLib.nft().transferFrom(msg.sender, address(this), nftID);
        // Add NFT ID to user set
        EnumerableSet.add(s().stakedNFTs[owner], nftID);
    }

    function unstake(uint256 nftID) internal returns (bool success_) {
        success_ = EnumerableSet.remove(s().stakedNFTs[msg.sender], nftID);
    }

    function stakedNFTs(address nftOwner)
        internal
        view
        returns (uint256[] memory staked_)
    {
        EnumerableSet.UintSet storage nfts = s().stakedNFTs[nftOwner];
        staked_ = new uint256[](EnumerableSet.length(nfts));
        for (uint256 i; i < staked_.length; i++) {
            staked_[i] = EnumerableSet.at(nfts, i);
        }
    }

    function liquidateNFT(uint256 loanID) internal {
        // Check if NFTs are linked
        EnumerableSet.UintSet storage nfts = s().loanNFTs[loanID];
        for (uint256 i; i < EnumerableSet.length(nfts); i++) {
            NFTLib.nft().transferFrom(
                address(this),
                AppStorageLib.store().nftLiquidationController,
                EnumerableSet.at(nfts, i)
            );
        }
    }

    function applyToLoan(uint256 loanID, NftLoanSizeProof calldata proof)
        internal
    {
        // NFT must be currently staked
        // Remove NFT from being staked - returns bool
        require(unstake(proof.id), "Teller: borrower nft not staked");

        require(verifyLoanSize(proof), "Teller invalid nft proof");

        // Apply NFT to loan
        EnumerableSet.add(s().loanNFTs[loanID], proof.id);
    }

    function restakeLinked(uint256 loanID, address owner) internal {
        // Get linked NFT
        EnumerableSet.UintSet storage nfts = s().loanNFTs[loanID];
        for (uint256 i; i < EnumerableSet.length(nfts); i++) {
            // Restake the NFT
            stake(EnumerableSet.at(nfts, i), owner);
        }
    }

    function verifyLoanSize(NftLoanSizeProof calldata proof)
        internal
        view
        returns (bool verified_)
    {
        verified_ = MerkleProof.verify(
            proof.proof,
            s().nftMerkleRoot,
            keccak256(abi.encodePacked(proof.id, proof.baseLoanSize))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ChainlinkLib } from "./chainlink/ChainlinkLib.sol";
import { CompoundLib } from "../shared/libraries/CompoundLib.sol";

// Interfaces
import {
    AggregatorV2V3Interface
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Storage
import { AppStorageLib } from "../storage/app.sol";

contract PriceAggFacet {
    uint256 internal constant TEN = 10;

    /**
     * @notice It returns the price of the token pair as given from the Chainlink Aggregator.
     * @dev It tries to use ETH as a pass through asset if the direct pair is not supported.
     * @param src Source token address.
     * @param dst Destination token address.
     * @return int256 The latest answer as given from Chainlink.
     */
    function getPriceFor(address src, address dst)
        external
        view
        returns (int256)
    {
        return _priceFor(src, dst);
    }

    /**
     * @notice It calculates the value of a token amount into another.
     * @param src Source token address.
     * @param dst Destination token address.
     * @param srcAmount Amount of the source token to convert into the destination token.
     * @return uint256 Value of the source token amount in destination tokens.
     */
    function getValueFor(
        address src,
        address dst,
        uint256 srcAmount
    ) external view returns (uint256) {
        return _valueFor(src, srcAmount, uint256(_priceFor(src, dst)));
    }

    function _valueFor(
        address src,
        uint256 amount,
        uint256 exchangeRate
    ) internal view returns (uint256) {
        return (amount * exchangeRate) / _oneToken(src);
    }

    function _oneToken(address token) internal view returns (uint256) {
        return TEN**_decimalsFor(token);
    }

    /**
     * @dev It gets the number of decimals for a given token.
     * @param addr Token address to get decimals for.
     * @return uint8 Number of decimals the given token.
     */
    function _decimalsFor(address addr) internal view returns (uint8) {
        return ERC20(addr).decimals();
    }

    /**
     * @dev Tries to calculate a price from Compound and Chainlink.
     */
    function _priceFor(address src, address dst)
        private
        view
        returns (int256 price_)
    {
        // If no Compound route, try Chainlink directly.
        price_ = int256(_compoundPriceFor(src, dst));
        if (price_ == 0) {
            price_ = _chainlinkPriceFor(src, dst);
            if (price_ == 0) {
                revert("Teller: cannot calc price");
            }
        }
    }

    /**
     * @dev Tries to get a price from {src} to {dst} by checking if either tokens are from Compound.
     */
    function _compoundPriceFor(address src, address dst)
        private
        view
        returns (uint256)
    {
        (bool isSrcCompound, address srcUnderlying) = _isCToken(src);
        if (isSrcCompound) {
            uint256 cRate = CompoundLib.valueInUnderlying(src, _oneToken(src));
            if (srcUnderlying == dst) {
                return cRate;
            } else {
                return _calcPriceFromCompoundRate(srcUnderlying, dst, cRate);
            }
        } else {
            (bool isDstCompound, address dstUnderlying) = _isCToken(dst);
            if (isDstCompound) {
                uint256 cRate =
                    CompoundLib.valueOfUnderlying(dst, _oneToken(src));
                if (dstUnderlying == src) {
                    return cRate;
                } else {
                    return
                        _calcPriceFromCompoundRate(src, dstUnderlying, cRate);
                }
            }
        }

        return 0;
    }

    /**
     * @dev Tries to get a price from {src} to {dst} and then converts using a rate from Compound.
     */
    function _calcPriceFromCompoundRate(
        address src,
        address dst,
        uint256 cRate
    ) private view returns (uint256) {
        uint256 rate = uint256(_chainlinkPriceFor(src, dst));
        uint256 value = (cRate * _oneToken(dst)) / rate;
        return _scale(value, _decimalsFor(src), _decimalsFor(dst));
    }

    /**
     * @dev Scales the {value} by the difference in decimal values.
     */
    function _scale(
        uint256 value,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        if (dstDecimals > srcDecimals) {
            return value * (TEN**(dstDecimals - srcDecimals));
        } else {
            return value / (TEN**(srcDecimals - dstDecimals));
        }
    }

    /**
     * @dev Tries to calculate the price of {src} in {dst}
     */
    function _chainlinkPriceFor(address src, address dst)
        private
        view
        returns (int256)
    {
        (address agg, bool foundAgg, bool inverse) =
            ChainlinkLib.aggregatorFor(src, dst);
        if (foundAgg) {
            uint256 price =
                SafeCast.toUint256(AggregatorV2V3Interface(agg).latestAnswer());
            uint8 resDecimals = AggregatorV2V3Interface(agg).decimals();
            if (inverse) {
                price = (TEN**(resDecimals + resDecimals)) / price;
            }
            return
                SafeCast.toInt256(
                    (_scale(price, resDecimals, _decimalsFor(dst)))
                );
        } else {
            address WETH = AppStorageLib.store().assetAddresses["WETH"];
            if (dst != WETH) {
                int256 price1 = _priceFor(src, WETH);
                if (price1 > 0) {
                    int256 price2 = _priceFor(dst, WETH);
                    if (price2 > 0) {
                        uint256 dstFactor = TEN**_decimalsFor(dst);
                        return (price1 * int256(dstFactor)) / price2;
                    }
                }
            }
        }

        return 0;
    }

    function _isCToken(address token)
        private
        view
        returns (bool isCToken, address underlying)
    {
        isCToken = CompoundLib.isCompoundToken(token);
        if (isCToken) {
            underlying = CompoundLib.getUnderlying(token);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PriceAggFacet } from "./PriceAggFacet.sol";

// Storage
import { AppStorageLib } from "../storage/app.sol";

/**
 * @notice Helper functions to staticcall into the PriceAggFacet from other facets. See {PriceAggFacet.getPriceFor}
 */
library PriceAggLib {
    /**
     * @notice See {PriceAggFacet.getValueFor}
     */
    function valueFor(
        address src,
        address dst,
        uint256 srcAmount
    ) internal view returns (uint256 value_) {
        value_ = PriceAggFacet(address(this)).getValueFor(src, dst, srcAmount);
    }

    /**
     * @notice See {PriceAggFacet.getPriceFor}
     */
    function priceFor(address src, address dst)
        internal
        view
        returns (int256 price_)
    {
        price_ = PriceAggFacet(address(this)).getPriceFor(src, dst);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Storage
import {
    PriceAggStorageLib,
    ChainlinkAggStorage
} from "../../storage/price-aggregator.sol";

library ChainlinkLib {
    function s() internal view returns (ChainlinkAggStorage storage) {
        return PriceAggStorageLib.store().chainlink;
    }

    /**
     * @notice It grabs the Chainlink Aggregator contract address for the token pair if it is supported.
     * @param src Source token address.
     * @param dst Destination token address.
     * @return aggregator The Chainlink Aggregator address.
     * @return found whether or not the ChainlinkAggregator exists.
     * @return inverse whether or not the values from the Aggregator should be considered inverted.
     */
    function aggregatorFor(address src, address dst)
        internal
        view
        returns (
            address aggregator,
            bool found,
            bool inverse
        )
    {
        aggregator = s().aggregators[src][dst];
        if (aggregator != address(0)) {
            found = true;
        } else {
            aggregator = s().aggregators[dst][src];
            if (aggregator != address(0)) {
                found = true;
                inverse = true;
            }
        }
    }

    /**
     * @dev Checks if a token address is supported by Chainlink (has a pair aggregator).
     * @param token Token address to check if is supported.
     * @return isSupported_ true if there is at least 1 pair aggregator for {token}
     */
    function isTokenSupported(address token)
        internal
        view
        returns (bool isSupported_)
    {
        isSupported_ = EnumerableSet.contains(s().supportedTokens, token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../../shared/libraries/CacheLib.sol";

// Storage
import { AppStorageLib } from "../../../storage/app.sol";

/**
 * @notice Utility library of inline functions for MaxDebtRatio asset setting.
 *
 * @author [email protected]
 */
library MaxDebtRatioLib {
    bytes32 private constant NAME = keccak256("MaxDebtRatio");

    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    function get(address asset) internal view returns (uint16) {
        return uint16(s(asset).uints[NAME]);
    }

    function set(address asset, uint16 newValue) internal {
        s(asset).uints[NAME] = uint256(newValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../../shared/libraries/CacheLib.sol";

// Storage
import { AppStorageLib } from "../../../storage/app.sol";

/**
 * @notice Utility library of inline functions for MaxLoanAmount asset setting.
 *
 * @author [email protected]
 */
library MaxLoanAmountLib {
    bytes32 private constant NAME = keccak256("MaxLoanAmount");

    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    function get(address asset) internal view returns (uint256) {
        return s(asset).uints[NAME];
    }

    function set(address asset, uint256 newValue) internal {
        s(asset).uints[NAME] = newValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorageLib } from "../../storage/app.sol";

abstract contract PausableMods {
    /**
     * @notice Requires that the state of the protocol AND the given facet id equal {state}.
     * @param id id of the facet to check if is paused.
     * @param state Boolean that the protocol AND facet should be in.
     */
    modifier paused(bytes32 id, bool state) {
        require(
            __isPaused("") == state && __isPaused(id) == state,
            __pausedMessage(state)
        );
        _;
    }

    /**
     * @dev Checks if the given id is paused.
     * @param id Encoded id of the facet to check if is paused.
     */
    function __isPaused(bytes32 id) private view returns (bool) {
        return AppStorageLib.store().paused[id];
    }

    /**
     * @dev Gets the message that should be reverted with given a state it should be in.
     * @param state Boolean that an id should be in.
     */
    function __pausedMessage(bool state) private pure returns (string memory) {
        return state ? "Pausable: not paused" : "Pausable: paused";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorageLib } from "../../../storage/app.sol";
import "../names.sol" as NAMES;
import {
    RolesMods
} from "../../../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN, AUTHORIZED } from "../../../shared/roles.sol";
import { RolesLib } from "../../../contexts2/access-control/roles/RolesLib.sol";

// It defines a platform settings. It includes: value, min, and max values.
struct PlatformSetting {
    uint256 value;
    uint256 min;
    uint256 max;
    bool exists;
}

/**
 * @notice Utility library of inline functions on the PlatformSetting struct.
 *
 * @author [email protected]
 */
library PlatformSettingsLib {
    function s(bytes32 name) internal view returns (PlatformSetting storage) {
        return AppStorageLib.store().platformSettings[name];
    }

    /**
     * @notice It gets the current "RequiredSubmissionsPercentage" setting's value
     * @return value_ the current value.
     */
    function getRequiredSubmissionsPercentageValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.REQUIRED_SUBMISSIONS_PERCENTAGE).value;
    }

    /**
     * @notice It gets the current "MaximumTolerance" setting's value
     * @return value_ the current value.
     */
    function getMaximumToleranceValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.MAXIMUM_TOLERANCE).value;
    }

    /**
     * @notice It gets the current "ResponseExpiryLength" setting's value
     * @return value_ the current value.
     */
    function getResponseExpiryLengthValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.RESPONSE_EXPIRY_LENGTH).value;
    }

    /**
     * @notice It gets the current "SafetyInterval" setting's value
     * @return value_ the current value.
     */
    function getSafetyIntervalValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.SAFETY_INTERVAL).value;
    }

    /**
     * @notice It gets the current "TermsExpiryTime" setting's value
     * @return value_ the current value.
     */
    function getTermsExpiryTimeValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.TERMS_EXPIRY_TIME).value;
    }

    /**
     * @notice It gets the current "LiquidateRewardPercent" setting's value
     * @return value_ the current value.
     */
    function getLiquidateRewardPercent()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.LIQUIDATE_REWARD_PERCENT).value;
    }

    /**
     * @notice It gets the current "MaximumLoanDuration" setting's value
     * @return value_ the current value.
     */
    function getMaximumLoanDurationValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.MAXIMUM_LOAN_DURATION).value;
    }

    /**
     * @notice It gets the current "RequestLoanTermsRateLimit" setting's value
     * @return value_ the current value.
     */
    function getRequestLoanTermsRateLimitValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.REQUEST_LOAN_TERMS_RATE_LIMIT).value;
    }

    /**
     * @notice It gets the current "CollateralBuffer" setting's value
     * @return value_ the current value.
     */
    function getCollateralBufferValue() internal view returns (uint256 value_) {
        value_ = s(NAMES.COLLATERAL_BUFFER).value;
    }

    /**
     * @notice It gets the current "OverCollateralizedBuffer" setting's value
     * @return value_ the current value.
     */
    function getOverCollateralizedBufferValue()
        internal
        view
        returns (uint256 value_)
    {
        value_ = s(NAMES.OVER_COLLATERALIZED_BUFFER).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
        @dev The setting name for the required subsmission settings.
        @dev This is the minimum percentage of node responses that will be required by the platform to either take out a loan, and to claim accrued interest. If the number of node responses are less than the ones specified here, the loan or accrued interest claim request will be rejected by the platform
     */
bytes32 constant REQUIRED_SUBMISSIONS_PERCENTAGE = keccak256(
    "RequiredSubmissionsPercentage"
);

/**
        @dev The setting name for the maximum tolerance settings.
        @dev This is the maximum tolerance for the values submitted (by nodes) when they are aggregated (average). It is used in the consensus mechanisms.
        @dev This is a percentage value with 2 decimal places.
            i.e. maximumTolerance of 325 => tolerance of 3.25% => 0.0325 of value
            i.e. maximumTolerance of 0 => It means all the values submitted must be equals.
        @dev The max value is 100% => 10000
     */
bytes32 constant MAXIMUM_TOLERANCE = keccak256("MaximumTolerance");
/**
        @dev The setting name for the response expiry length settings.
        @dev This is the maximum time (in seconds) a node has to submit a response. After that time, the response is considered expired and will not be accepted by the protocol.
     */

bytes32 constant RESPONSE_EXPIRY_LENGTH = keccak256("ResponseExpiryLength");

/**
        @dev The setting name for the safety interval settings.
        @dev This is the minimum time you need to wait (in seconds) between the last time you deposit collateral and you take out the loan.
        @dev It is used to avoid potential attacks using Flash Loans (AAVE) or Flash Swaps (Uniswap V2).
     */
bytes32 constant SAFETY_INTERVAL = keccak256("SafetyInterval");

/**
        @dev The setting name for the term expiry time settings.
        @dev This represents the time (in seconds) that loan terms will be available after requesting them.
        @dev After this time, the loan terms will expire and the borrower will need to request it again.
     */
bytes32 constant TERMS_EXPIRY_TIME = keccak256("TermsExpiryTime");

/**
        @dev The setting name for the liquidation reward percent setting.
        @dev It represents the percentage value (with 2 decimal places) for the MAX liquidation reward.
            i.e. an ETH liquidation price at 5% is stored as 500
     */
bytes32 constant LIQUIDATE_REWARD_PERCENT = keccak256("LiquidateRewardPercent");

/**
        @dev The setting name for the maximum loan duration settings.
        @dev The maximum loan duration setting is defined in seconds. Loans will not be given for timespans larger than the one specified here.
     */
bytes32 constant MAXIMUM_LOAN_DURATION = keccak256("MaximumLoanDuration");

/**
        @dev The setting name for the request loan terms rate limit settings.
        @dev The request loan terms rate limit setting is defined in seconds.
     */
bytes32 constant REQUEST_LOAN_TERMS_RATE_LIMIT = keccak256(
    "RequestLoanTermsRateLimit"
);

/**
        @dev The setting name for the collateral buffer.
        @dev The collateral buffer is a safety buffer above the required collateral amount to liquidate a loan. It is required to ensure the loan does not get liquidated immediately after the loan is taken out if the value of the collateral asset deposited drops drastically.
        @dev It represents the percentage value (with 2 decimal places) of a collateral buffer.
            e.g.: collateral buffer at 100% is stored as 10000.
     */
bytes32 constant COLLATERAL_BUFFER = keccak256("CollateralBuffer");

/**
        @dev The setting name for the over collateralized buffer.
        @dev The over collateralized buffer is the minimum required collateral ratio in order for a loan to be taken out without an Escrow contract and for the funds to go to the borrower's EOA (external overridely owned account).
        @dev It represents the percentage value (with 2 decimal places) of a over collateralized buffer.
            e.g.: over collateralized buffer at 130% is stored as 13000.
     */
bytes32 constant OVER_COLLATERALIZED_BUFFER = keccak256(
    "OverCollateralizedBuffer"
);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IComptroller.sol";

interface ICErc20 {
    /*** User Interface ***/

    /**
        @notice The mint function transfers an asset into the protocol, which begins accumulating interest based on the current Supply Rate for the asset. The user receives a quantity of cTokens equal to the underlying tokens supplied, divided by the current Exchange Rate.
        @param mintAmount The amount of the asset to be supplied, in units of the underlying asset.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account which shall supply the asset, and own the minted cTokens.
        @dev Before supplying an asset, users must first approve the cToken to access their token balance.
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
        @notice The redeem function converts a specified quantity of cTokens into the underlying asset, and returns them to the user. The amount of underlying tokens received is equal to the quantity of cTokens redeemed, multiplied by the current Exchange Rate. The amount redeemed must be less than the user's Account Liquidity and the market's available liquidity.
        @param redeemTokens The number of cTokens to be redeemed.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account to which redeemed funds shall be transferred.
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
        @notice The redeem underlying function converts cTokens into a specified quantity of the underlying asset, and returns them to the user. The amount of cTokens redeemed is equal to the quantity of underlying tokens received, divided by the current Exchange Rate. The amount redeemed must be less than the user's Account Liquidity and the market's available liquidity.
        @param redeemAmount The amount of underlying to be redeemed.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account to which redeemed funds shall be transferred.
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
        @notice The borrow function transfers an asset from the protocol to the user, and creates a borrow balance which begins accumulating interest based on the Borrow Rate for the asset. The amount borrowed must be less than the user's Account Liquidity and the market's available liquidity.
        @param borrowAmount The amount of the underlying asset to be borrowed.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account to which borrowed funds shall be transferred.
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
        @notice The repay function transfers an asset into the protocol, reducing the user's borrow balance.
        @param repayAmount The amount of the underlying borrowed asset to be repaid. A value of -1 (i.e. 2^256 - 1) can be used to repay the full amount.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account which borrowed the asset, and shall repay the borrow.
        @dev Before repaying an asset, users must first approve the cToken to access their token balance.
     */
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    /**
        @notice The repay function transfers an asset into the protocol, reducing the target user's borrow balance.
        @param borrower The account which borrowed the asset to be repaid.
        @param repayAmount The amount of the underlying borrowed asset to be repaid. A value of -1 (i.e. 2^256 - 1) can be used to repay the full amount.
        @return 0 on success, otherwise an Error code
        @dev msg.sender The account which shall repay the borrow.
        @dev Before repaying an asset, users must first approve the cToken to access their token balance.
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);

    /** End Admin Functions */

    function underlying() external view returns (address);

    /**
        @notice Each cToken is convertible into an ever increasing quantity of the underlying asset, as interest accrues in the market. The exchange rate between a cToken and the underlying asset is
        equal to: exchangeRate = (getCash() + totalBorrows() - totalReserves()) / totalSupply()
        @return The current exchange rate as an unsigned integer, scaled by 1e18.
     */
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external;

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    /**
        @notice The user's underlying balance, representing their assets in the protocol, is equal to the user's cToken balance multiplied by the Exchange Rate.
        @param account The account to get the underlying balance of.
        @return The amount of underlying currently owned by the account.
     */
    function balanceOfUnderlying(address account) external returns (uint256);

    function comptroller() external view returns (IComptroller);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function claimComp(address holder) external;

    function claimComp(address holder, address[] calldata cTokens) external;

    function claimComp(
        address[] calldata holders,
        address[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getCompAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @notice This interface defines the different functions available for a UniswapV2Router.
    @author [email protected]
 */
interface IUniswapV2Router {
    function factory() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
        @notice It returns the address of the canonical WETH address;
    */
    function WETH() external pure returns (address);

    /**
        @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
        @param amountIn The amount of input tokens to send.
        @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
        @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
        @param to Recipient of the output tokens.
        @param deadline Unix timestamp after which the transaction will revert.
        @return amounts The input token amount and all subsequent output token amounts.
        @dev msg.sender should have already given the router an allowance of at least amountIn on the input token.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
        @notice Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
        @param amountIn The amount of input tokens to send.
        @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
        @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
        @param to Recipient of the ETH.
        @param deadline Unix timestamp after which the transaction will revert.
        @return amounts The input token amount and all subsequent output token amounts.
        @dev If the to address is a smart contract, it must have the ability to receive ETH.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
        @notice Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path. The first element of path must be WETH, the last is the output token, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
        @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
        @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
        @param to Recipient of the output tokens.
        @param deadline Unix timestamp after which the transaction will revert.
        @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum CacheType { Address, Uint, Int, Byte, Bool }

/**
 * @notice This struct manages the cache of the library instance.
 * @param addresses A mapping of address values mapped to cache keys in bytes.
 * @param uints A mapping of uint values mapped to cache keys names in bytes.
 * @param ints A mapping of int values mapped to cache keys names in bytes.
 * @param bites A mapping of bytes values mapped to cache keys names in bytes.
 * @param bools A mapping of bool values mapped to cache keys names in bytes.
 */
struct Cache {
    // Mapping of cache keys names to address values.
    mapping(bytes32 => address) addresses;
    // Mapping of cache keys names to uint256 values.
    mapping(bytes32 => uint256) uints;
    // Mapping of cache keys names to int256 values.
    mapping(bytes32 => int256) ints;
    // Mapping of cache keys names to bytes32 values.
    mapping(bytes32 => bytes32) bites;
    // Mapping of cache keys names to bool values.
    mapping(bytes32 => bool) bools;
}

library CacheLib {
    // The constant for the initialization check
    bytes32 private constant INITIALIZED = keccak256("Initialized");

    /**
     * @notice Initializes the cache instance.
     * @param cache The current cache
     */
    function initialize(Cache storage cache) internal {
        requireNotExists(cache);
        cache.bools[INITIALIZED] = true;
    }

    /**
     * @notice Checks whether the current cache does not, throwing an error if it does.
     * @param cache The current cache
     */
    function requireNotExists(Cache storage cache) internal view {
        require(!exists(cache), "CACHE_ALREADY_EXISTS");
    }

    /**
     * @notice Checks whether the current cache exists, throwing an error if the cache does not.
     * @param cache The current cache
     */
    function requireExists(Cache storage cache) internal view {
        require(exists(cache), "CACHE_DOES_NOT_EXIST");
    }

    /**
     * @notice Tests whether the current cache exists or not.
     * @param cache The current cache.
     * @return bool True if the cache exists.
     */
    function exists(Cache storage cache) internal view returns (bool) {
        return cache.bools[INITIALIZED];
    }

    function update(
        Cache storage cache,
        bytes32 key,
        bytes32 value,
        CacheType cacheType
    ) internal {
        requireExists(cache);

        assembly {
            mstore(0, value)
        }
        if (cacheType == CacheType.Address) {
            address addr;
            assembly {
                addr := mload(0)
            }
            cache.addresses[key] = addr;
        } else if (cacheType == CacheType.Uint) {
            uint256 ui;
            assembly {
                ui := mload(0)
            }
            cache.uints[key] = ui;
        } else if (cacheType == CacheType.Int) {
            int256 i;
            assembly {
                i := mload(0)
            }
            cache.ints[key] = i;
        } else if (cacheType == CacheType.Byte) {
            cache.bites[key] = value;
        } else if (cacheType == CacheType.Bool) {
            bool b;
            assembly {
                b := mload(0)
            }
            cache.bools[key] = b;
        }
    }

    /**
     */
    function clearCache(
        Cache storage cache,
        bytes32[5] memory keysToClear,
        CacheType[5] memory keyTypes
    ) internal {
        requireExists(cache);
        require(
            keysToClear.length == keyTypes.length,
            "ARRAY_LENGTHS_MISMATCH"
        );
        for (uint256 i; i <= keysToClear.length; i++) {
            if (keyTypes[i] == CacheType.Address) {
                delete cache.addresses[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Uint) {
                delete cache.uints[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Int) {
                delete cache.ints[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Byte) {
                delete cache.bites[keysToClear[i]];
            } else if (keyTypes[i] == CacheType.Bool) {
                delete cache.bools[keysToClear[i]];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import { ICErc20 } from "../interfaces/ICErc20.sol";

// Storage
import { AppStorageLib } from "../../storage/app.sol";

/**
 * @notice Utility library to calculate the value of a Compound cToken and its underlying asset.
 *
 * @author [email protected]
 */
library CompoundLib {
    /**
     * @dev Compounds exchange rate is scaled by 18 decimals (10^18)
     */
    uint256 internal constant EXCHANGE_RATE_SCALE = 1e18;

    function exchangeRate(address cToken) internal view returns (uint256) {
        return ICErc20(cToken).exchangeRateStored();
    }

    /**
     * @notice Takes an amount of the Compound asset and calculates the underlying amount using the stored exchange rate.
     * @param cToken Address of the Compound token.
     * @param cTokenAmount Amount of the Compound asset.
     * @return value of the Compound token amount in underlying tokens.
     */
    function valueInUnderlying(address cToken, uint256 cTokenAmount)
        internal
        view
        returns (uint256)
    {
        return
            (cTokenAmount * ICErc20(cToken).exchangeRateStored()) /
            EXCHANGE_RATE_SCALE;
    }

    /**
     * @notice Takes an amount of the underlying Compound asset and calculates the cToken amount using the stored exchange rate.
     * @param cToken Address of the Compound token.
     * @param underlyingAmount Amount of the underlying asset for the Compound token.
     * @return value of the underlying amount in Compound tokens.
     */
    function valueOfUnderlying(address cToken, uint256 underlyingAmount)
        internal
        view
        returns (uint256)
    {
        return
            (underlyingAmount * EXCHANGE_RATE_SCALE) /
            ICErc20(cToken).exchangeRateStored();
    }

    function isCompoundToken(address token) internal view returns (bool) {
        return AppStorageLib.store().cTokenRegistry[token];
    }

    /**
     * @notice Tests the {underlying} function on the cToken and assumes its WETH otherwise.
     * @notice CETH is the only Compound token that does not support the {underlying} function.
     */
    function getUnderlying(address cToken) internal view returns (address) {
        (bool success, bytes memory data) =
            cToken.staticcall(abi.encode(ICErc20.underlying.selector));
        if (success) {
            return abi.decode(data, (address));
        }

        return AppStorageLib.store().assetAddresses["WETH"];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Utility library for uint256 numbers
 *
 * @author [email protected]
 */
library NumbersLib {
    /**
     * @dev It represents 100% with 2 decimal places.
     */
    uint256 internal constant ONE_HUNDRED_PERCENT = 10000;

    /**
     * @notice Returns a percentage value of a number.
     * @param self The number to get a percentage of.
     * @param percentage The percentage value to calculate with 2 decimal places (10000 = 100%).
     */
    function percent(uint256 self, uint16 percentage)
        internal
        pure
        returns (uint256)
    {
        return (self * uint256(percentage)) / ONE_HUNDRED_PERCENT;
    }

    function percent(int256 self, uint256 percentage)
        internal
        pure
        returns (int256)
    {
        return (self * int256(percentage)) / int256(ONE_HUNDRED_PERCENT);
    }

    function abs(int256 self) internal pure returns (uint256) {
        return self >= 0 ? uint256(self) : uint256(-1 * self);
    }

    /**
     * @notice Returns a ratio percentage of {num1} to {num2}.
     * @param num1 The number used to get the ratio for.
     * @param num2 The number used to get the ratio from.
     * @return Ratio percentage with 2 decimal places (10000 = 100%).
     */
    function ratioOf(uint256 num1, uint256 num2)
        internal
        pure
        returns (uint16)
    {
        return num2 == 0 ? 0 : uint16((num1 * ONE_HUNDRED_PERCENT) / num2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./NumbersLib.sol";

/**
 * @dev Utility library of inline functions on NumbersList.Values
 *
 * @author [email protected]
 */
library NumbersList {
    using NumbersLib for uint256;

    // Holds values to calculate the threshold of a list of numbers
    struct Values {
        uint256 count; // The total number of numbers added
        uint256 max; // The maximum number that was added
        uint256 min; // The minimum number that was added
        uint256 sum; // The total sum of the numbers that were added
    }

    /**
     * @dev Add to the sum while keeping track of min and max values
     * @param self The Value this function was called on
     * @param newValue Number to increment sum by
     */
    function addValue(Values memory self, uint256 newValue) internal pure {
        if (self.max < newValue) {
            self.max = newValue;
        }
        if (self.min > newValue || self.count == 0) {
            self.min = newValue;
        }
        self.sum = self.sum + (newValue);
        self.count = self.count + 1;
    }

    /**
     * @param self The Value this function was called on
     * @return the number of times the sum has updated
     */
    function valuesCount(Values memory self) internal pure returns (uint256) {
        return self.count;
    }

    /**
     * @dev Checks if the sum has been changed
     * @param self The Value this function was called on
     * @return boolean
     */
    function isEmpty(Values memory self) internal pure returns (bool) {
        return valuesCount(self) == 0;
    }

    /**
     * @param self The Value this function was called on
     * @return the average number that was used to calculate the sum
     */
    function getAverage(Values memory self) internal pure returns (uint256) {
        return isEmpty(self) ? 0 : self.sum / (valuesCount(self));
    }

    /**
     * @dev Checks if the min and max numbers are within the acceptable tolerance
     * @param self The Value this function was called on
     * @param tolerancePercentage Acceptable tolerance percentage as a whole number
     * The percentage should be entered with 2 decimal places. e.g. 2.5% should be entered as 250.
     * @return boolean
     */
    function isWithinTolerance(Values memory self, uint16 tolerancePercentage)
        internal
        pure
        returns (bool)
    {
        if (isEmpty(self)) {
            return false;
        }
        uint256 average = getAverage(self);
        uint256 toleranceAmount = average.percent(tolerancePercentage);

        uint256 minTolerance = average - toleranceAmount;
        if (self.min < minTolerance) {
            return false;
        }

        uint256 maxTolerance = average + toleranceAmount;
        if (self.max > maxTolerance) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract InitializeableBeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    function initialize(address beacon, bytes memory data) external payable {
        assert(
            _BEACON_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)
        );
        require(_beacon() == address(0), "Beacon: already initialized");

        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(
                _implementation(),
                data,
                "BeaconProxy: function call failed"
            );
        }
    }

    receive() external payable override {
        // Needed to receive ETH without data
        // OZ Proxy contract calls the _fallback() on receive and tries to delegatecall which fails
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./InitializeableBeaconProxy.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeaconFactory is IBeacon, Ownable {
    address private _implementation;
    InitializeableBeaconProxy public proxyAddress;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address payable proxyAddress_, address implementation_) {
        proxyAddress = InitializeableBeaconProxy(proxyAddress_);
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    function cloneProxy(bytes memory initData)
        external
        returns (address payable proxy_)
    {
        proxy_ = payable(Clones.clone(address(proxyAddress)));
        InitializeableBeaconProxy(proxy_).initialize(address(this), initData);
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant ADMIN = keccak256("ADMIN");
bytes32 constant PAUSER = keccak256("PAUSER");
bytes32 constant AUTHORIZED = keccak256("AUTHORIZED");

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { TellerNFT } from "../nft/TellerNFT.sol";

// Interfaces

// Libraries
import {
    PlatformSetting
} from "../settings/platform/libraries/PlatformSettingsLib.sol";
import { Cache } from "../shared/libraries/CacheLib.sol";
import {
    UpgradeableBeaconFactory
} from "../shared/proxy/beacon/UpgradeableBeaconFactory.sol";

struct AppStorage {
    bool initialized;
    bool platformRestricted;
    mapping(bytes32 => bool) paused;
    mapping(bytes32 => PlatformSetting) platformSettings;
    mapping(address => Cache) assetSettings;
    mapping(string => address) assetAddresses;
    mapping(address => bool) cTokenRegistry;
    TellerNFT nft;
    UpgradeableBeaconFactory loansEscrowBeacon;
    UpgradeableBeaconFactory collateralEscrowBeacon;
    address nftLiquidationController;
    UpgradeableBeaconFactory tTokenBeacon;
}

library AppStorageLib {
    function store() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../shared/libraries/NumbersList.sol";

// Interfaces
import { ILoansEscrow } from "../escrow/escrow/ILoansEscrow.sol";
import { ICollateralEscrow } from "../market/collateral/ICollateralEscrow.sol";
import { ITToken } from "../lending/ttoken/ITToken.sol";

struct LoanTerms {
    // Max size the loan max be taken out with
    uint256 maxLoanAmount;
    // The timestamp at which the loan terms expire, after which if the loan is not yet active, cannot be taken out
    uint32 termsExpiry;
}

enum LoanStatus { NonExistent, TermsSet, Active, Closed, Liquidated }

struct Loan {
    // Account that owns the loan
    address payable borrower;
    // The asset lent out for the loan
    address lendingToken;
    // The token used as collateral for the loan
    address collateralToken;
    // The total amount of the loan size taken out
    uint256 borrowedAmount;
    // The id of the loan for internal tracking
    uint128 id;
    // How long in seconds until the loan must be repaid
    uint32 duration;
    // The timestamp at which the loan became active
    uint32 loanStartTime;
    // The interest rate given for repaying the loan
    uint16 interestRate;
    // Ratio used to determine amount of collateral required based on the collateral asset price
    uint16 collateralRatio;
    // The status of the loan
    LoanStatus status;
}

struct LoanDebt {
    // The total amount of the loan taken out by the borrower, reduces on loan repayments
    uint256 principalOwed;
    // The total interest owed by the borrower for the loan, reduces on loan repayments
    uint256 interestOwed;
}

/**
 * @notice Borrower request object to take out a loan
 * @param borrower The wallet address of the borrower
 * @param assetAddress The address of the asset for the requested loan
 * @param amount The amount of tokens requested by the borrower for the loan
 * @param requestNonce The nonce of the borrower wallet address required for authentication
 * @param duration The length of time in seconds that the loan has been requested for
 * @param requestTime The timestamp at which the loan was requested
 */
struct LoanRequest {
    address payable borrower;
    address assetAddress;
    uint256 amount;
    uint32 requestNonce;
    uint32 duration;
    uint32 requestTime;
}

/**
 * @notice Borrower response object to take out a loan
 * @param signer The wallet address of the signer validating the interest request of the lender
 * @param assetAddress The address of the asset for the requested loan
 * @param maxLoanAmount The largest amount of tokens that can be taken out in the loan by the borrower
 * @param responseTime The timestamp at which the response was sent
 * @param interestRate The signed interest rate generated by the signer's Credit Risk Algorithm (CRA)
 * @param collateralRatio The ratio of collateral to loan amount that is generated by the signer's Credit Risk Algorithm (CRA)
 * @param signature The signature generated by the signer in the format of the above Signature struct
 */
struct LoanResponse {
    address signer;
    address assetAddress;
    uint256 maxLoanAmount;
    uint32 responseTime;
    uint16 interestRate;
    uint16 collateralRatio;
    Signature signature;
}

/**
 * @notice Represents a user signature
 * @param v The recovery identifier represented by the last byte of a ECDSA signature as an int
 * @param r The random point x-coordinate of the signature respresented by the first 32 bytes of the generated ECDSA signature
 * @param s The signature proof represented by the second 32 bytes of the generated ECDSA signature
 */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct MarketStorage {
    // Holds the index for the next loan ID
    Counters.Counter loanIDCounter;
    // Maps loanIDs to loan data
    mapping(uint256 => Loan) loans;
    // Maps loanID to loan debt (total owed left)
    mapping(uint256 => LoanDebt) loanDebt;
    // Maps loanID to loan terms
    mapping(uint256 => LoanTerms) loanTerms;
    // Maps loanIDs to escrow address to list of held tokens
    mapping(uint256 => ILoansEscrow) loanEscrows;
    // Maps loanIDs to list of tokens owned by a loan escrow
    mapping(uint256 => EnumerableSet.AddressSet) escrowTokens;
    // Maps collateral token address to a LoanCollateralEscrow that hold collateral funds
    mapping(address => ICollateralEscrow) collateralEscrows;
    // Maps accounts to owned loan IDs
    mapping(address => uint128[]) borrowerLoans;
    // Maps lending token to overall amount of interest collected from loans
    mapping(address => ITToken) tTokens;
    // Maps lending token to list of signer addresses who are only ones allowed to verify loan requests
    mapping(address => EnumerableSet.AddressSet) signers;
    // Maps lending token to list of allowed collateral tokens
    mapping(address => EnumerableSet.AddressSet) collateralTokens;
}

bytes32 constant MARKET_STORAGE_POS = keccak256("teller.market.storage");

library MarketStorageLib {
    function store() internal pure returns (MarketStorage storage s) {
        bytes32 pos = MARKET_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Utils
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct NFTStorage {
    // Maps NFT owner to set of token IDs owned
    mapping(address => EnumerableSet.UintSet) stakedNFTs;
    // Maps loanID to NFT IDs indicating NFT being used for the loan
    mapping(uint256 => EnumerableSet.UintSet) loanNFTs;
    // Merkle root used for verifying nft IDs to base loan size
    bytes32 nftMerkleRoot;
}

bytes32 constant NFT_STORAGE_POS = keccak256("teller.staking.storage");

library NFTStorageLib {
    function store() internal pure returns (NFTStorage storage s) {
        bytes32 pos = NFT_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct ChainlinkAggStorage {
    // Maps source token => destination token => Chainlink Aggregator
    mapping(address => mapping(address => address)) aggregators;
    // Maps token address to number of supported Chainlink pairs
    mapping(address => uint256) pairCount;
    // Stores set of token addresses supported by Chainlink
    EnumerableSet.AddressSet supportedTokens;
}

struct PriceAggStorage {
    ChainlinkAggStorage chainlink;
}

bytes32 constant PRICE_AGG_STORAGE_POS = keccak256(
    "teller.price.aggregator.storage"
);

library PriceAggStorageLib {
    function store() internal pure returns (PriceAggStorage storage s) {
        bytes32 pos = PRICE_AGG_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}