/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT
// File: Finalizable.sol


pragma solidity ^0.8.2;


abstract contract Finalizable {
    // using SafeMath for uint256;

    bool private _finalized;

    event Finalized();

    modifier WhenFinalized() {
        require(_finalized, "Not Finalized");
        _;
    }

    modifier WhenNotFinalized() {
        require(!_finalized, "Finalized");
        _;
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view returns (bool) {
        return _finalized;
    }

    function _finalize() internal virtual {

        _finalized = true;

        _finalization();
        emit Finalized();
    }

    function _finalization() internal {
        // solhint-disable-previous-line no-empty-blocks
    }
}
// File: @openzeppelin/[email protected]/utils/Counters.sol


// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: Whitelist.sol


pragma solidity ^0.8.2;


abstract contract Whitelist {
  using Counters for Counters.Counter;

  mapping(address => bool) public whitelist;
  Counters.Counter private _whitelistCounter;

  event WhitelistAdded(address indexed _account);
  event WhitelistRemoved(address indexed _account);

  ///@notice Verifies if the account is whitelisted.
  modifier isWhitelisted(address _account) {
    require(_account != address(0), "Address 0 can not be whitelisted");
    require(whitelist[_account], "Address is not in whitelist");
    _;
  }

  function whitelisted(address _account) internal virtual returns (bool){
      if(whitelist[_account]){
        return true;
      }
      else{
        return false;
      }
  }

  function _addToWhitelist(address _account) internal virtual {
    require(_account != address(0), "account is zero address");

    if(!whitelist[_account]) {
      whitelist[_account] = true;
      _whitelistCounter.increment();

      emit WhitelistAdded(_account);
    }
  }

  ///@notice Adds multiple accounts to the whitelist.
  ///@param _accounts The wallet addresses to add to the whitelist.
  function _addManyWhitelist(address[] memory _accounts) internal virtual {
    for(uint8 i = 0;i<_accounts.length;i++) {
      if(_accounts[i] != address(0) && !whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = true;
        _whitelistCounter.increment();

        emit WhitelistAdded(_accounts[i]);
      }
    }
  }

  function _removeFromWhitelist(address _account) internal virtual {
    require(_account != address(0));
    if(whitelist[_account]) {
      whitelist[_account] = false;
      _whitelistCounter.decrement();

      emit WhitelistRemoved(_account);
    }
  }

  ///@notice Removes multiple accounts from the whitelist.
  ///@param _accounts The wallet addresses to remove from the whitelist.
  function _removeManyWhitelist(address[] memory _accounts) internal virtual {
    for(uint8 i=0;i<_accounts.length;i++) {
      if(_accounts[i] != address(0) && whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = false;
        _whitelistCounter.decrement();
        
        emit WhitelistRemoved(_accounts[i]);
      }
    }
  }

  function whitelistCount() public view returns(uint count) {
    return _whitelistCounter.current();
  }

}
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;





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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: BuntERC20.sol



pragma solidity ^0.8.2;




contract BuntERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _excludedFromTax;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _taxRate;
    address private _taxWallet;

    event IncludeInTax(address indexed account);
    event ExcludeFromTax(address indexed account);


    constructor(string memory name_, string memory symbol_, uint256 taxRate_, address taxWallet_) {
        _name = name_;
        _symbol = symbol_;
        _taxRate = taxRate_;
        _taxWallet = taxWallet_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;

    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;

    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];

        uint256 tax = amount / _taxRate;
        uint256 sendTax = 0;
        uint256 receiveTax = 0;


        if(!_excludedFromTax[sender]) {
            sendTax = tax;
        }
        else if(_excludedFromTax[sender] && !_excludedFromTax[recipient]) {
            receiveTax = tax;
        }
        else if(_excludedFromTax[sender] && _excludedFromTax[recipient]){
            tax = 0;
        }

        uint256 totalAmount = amount + sendTax;

        //require(senderBalance >= totalAmount , string(abi.encodePacked("ERC20: transfer amount exceeds balance. Max valid transfer: ", Strings.toString(senderBalance - (senderBalance /(_taxRate * totalAmount / senderBalance))))));

        require(senderBalance >= totalAmount , "ERC20: transfer amount exceeds balance");

        uint256 sendAmount = amount + sendTax;
        uint256 receiveAmount = amount - receiveTax;

        unchecked {
            _balances[sender] -= sendAmount;
        }

        _balances[recipient] += receiveAmount;
        emit Transfer(sender, recipient, receiveAmount);

        
        if(tax > 0){
            _balances[_taxWallet] += tax;
            emit Transfer(sender, _taxWallet, tax);
        }

        _afterTokenTransfer(sender, recipient, receiveAmount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount

    ) internal virtual {}

    function _includeInTax(address account) internal virtual {
        if (!_excludedFromTax[account]) return;
        _excludedFromTax[account] = false;
        emit IncludeInTax(account);
    }



    function _excludeFromTax(address account) internal virtual {
        if (_excludedFromTax[account]) return;
        _excludedFromTax[account] = true;

        emit ExcludeFromTax(account);
    }
  

    function isExcludeFromTax(address account) public view returns (bool) {
        return _excludedFromTax[account];
    }

    function _updateTaxWallet(address taxWallet_) internal returns (address) {
        _taxWallet = taxWallet_;
        return _taxWallet;
    }

    function _updateTaxRate(uint256 taxRate_) internal returns (uint256) {
        _taxRate = taxRate_;
        return _taxRate;
    }

}

// File: BuntToken.sol


pragma solidity ^0.8.2;




contract BuntToken is BuntERC20, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public taxRate = 200;
    address private taxWallet = 0x59b48F67B3D846b8a3ce3c162650d951BDAD9E87;
    
    constructor() BuntERC20("BUNT Token", "BUNT", taxRate, taxWallet) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); 
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyRole(ADMIN_ROLE) {
        _burn(account, amount);
    }

    /**
    * @dev Exclude address from tax deduction
    */
    function excludeFromTax(address account) public onlyRole(ADMIN_ROLE) {
        _excludeFromTax(account);
    }

    /**
    * @dev Include address in tax deduction
    */
    function includeInTax(address account) public onlyRole(ADMIN_ROLE) {
        _includeInTax(account);
    }

    /**
    * @dev Update the wallet address into where the tax is transferred
    */
    function updateTaxWallet(address taxWallet_) public onlyRole(ADMIN_ROLE) 
    {
        require(taxWallet_ != address(0), "taxWallet is address 0");
        _updateTaxWallet(taxWallet_);
    }

    function updateTaxRate(uint256 taxRate_) public onlyRole(ADMIN_ROLE) {
        _updateTaxRate(taxRate_);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {        
        super._beforeTokenTransfer(from, to, amount);
    }

}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

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

// File: VestingVault.sol


pragma solidity ^0.8.2;





contract VestingVault is AccessControl, Initializable {

    bytes32 public constant VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");

    struct VestingWallet {
        uint256 totalAmount; // Vested amount BUNT in BUNT
        uint256 releasedAmount; // Amount that beneficiary withdraw
        mapping(address => VestingEventWallet) data;
        address[] vestingEventProvider;
        uint size;
    }

    struct VestingEventWallet {
        address eventProvider;
        uint256 vestingPerPeriod;
        uint256 firstClaim;
        uint256 amount; // Vested amount BUNT in BUNT
        uint256 released; // Amount that beneficiary withdraw
    }

    struct VestingEvent {
        string name;
        address eventProvider;
        uint256 cliff;
        uint256 firstClaimRate;
        uint256 periods;
        uint256 periodDuration;
        uint256 vestingEnd;
    }

    struct VestingEventMap {
        mapping(address => VestingEvent) data;
        VestingEvent[] vestingEvents;
        uint size;
        uint256 totalAmount; // Vested amount BUNT in BUNT
        uint256 releasedAmount; // Amount that beneficiary withdraw
    }

    bool private initialized;
    BuntToken private buntToken;
    address private tokenAddress;
    uint256 public vaultTotalAmount;
    uint256 public vaultTotalReleased;  

    mapping(address => VestingWallet) public vestingWallet;

    mapping(address => VestingEventMap) private eventProviderMap;

    event TokensClaimed(address account, uint256 amount);
    event VestingAdded(address eventProvider, address account, uint256 amount);
    event VestingEventAdded(address eventProvider, uint256 cliff);

    modifier onlyBeneficiaries(address _beneficiary) {
        require(vestingWallet[_beneficiary].totalAmount > 0, "You do not have any locked tokens");
        _;
    }

    modifier vestingEventInitialized(address _eventProvider) {
        require(eventProviderMap[tokenAddress].data[_eventProvider].cliff > 0, "vesting event not initialized");
        _;
    }

    modifier hasRequiredRole() {
        require(buntToken.hasRole(keccak256("MINTER_ROLE"), address(this)), "Contract is not minter");
        _;
    }

    modifier isExcludedFromFee() {
        require(buntToken.isExcludeFromTax(address(this)), "Contract is not excluded from fees");
        _;
    }

    function initialize(address _token) initializer public  {
        require(!initialized,"Contract already initialized");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VAULT_ADMIN_ROLE, msg.sender);
        tokenAddress = _token;
        buntToken = BuntToken(_token);
        initialized = true;    
    }
    
    function addVestingEvent(string memory _name, address _eventProvider, uint256 _cliff, uint256 _firstClaimRate, uint256 _periods, uint256 _periodDuration) public isExcludedFromFee() onlyRole(VAULT_ADMIN_ROLE) {

        require(_cliff >= block.timestamp, "cliff can be in the past");
        require(_firstClaimRate > 0 && _firstClaimRate <= 100, "first claim rate should be > 0 and <= 100");
        require(_periods > 0, "number of periods should be > 0");
        require(_periodDuration >= (1 minutes), "Period Duration should be >= 1 minute");


        VestingEventMap storage vestingMap = eventProviderMap[tokenAddress];

        vestingMap.data[_eventProvider].name = _name;
        vestingMap.data[_eventProvider].cliff = _cliff;
        vestingMap.data[_eventProvider].firstClaimRate = _firstClaimRate;
        vestingMap.data[_eventProvider].periods = _periods;
        vestingMap.data[_eventProvider].periodDuration = _periodDuration;
        vestingMap.data[_eventProvider].eventProvider = _eventProvider;
        vestingMap.data[_eventProvider].vestingEnd = _cliff + ((_periods + 1) * _periodDuration);

        vestingMap.size += 1;
        vestingMap.vestingEvents.push(vestingMap.data[_eventProvider]);

        emit VestingEventAdded(_eventProvider, _cliff);
    }

    function addVesting(address _beneficiary, uint256 _amount, address _eventProvider) public onlyRole(VAULT_ADMIN_ROLE) vestingEventInitialized(_eventProvider) {
        require(_amount > 0, "Amount is 0");
        require(_beneficiary != address(0), "Address 0 can not be vested");
        addTimedVesting(_beneficiary, _amount, eventProviderMap[tokenAddress].data[_eventProvider].cliff, _eventProvider);
    }

    function addTimedVesting(address _beneficiary, uint256 _amount, uint256 _cliff, address _eventProvider) internal onlyRole(VAULT_ADMIN_ROLE) vestingEventInitialized(_eventProvider) {
        uint256 cliff = _cliff;
        uint periods = eventProviderMap[tokenAddress].data[_eventProvider].periods;
        uint256 firstClaimRate = eventProviderMap[tokenAddress].data[_eventProvider].firstClaimRate;

        require(cliff >= block.timestamp, "cliff can be in the past");
        require(_amount >= periods, "vesting amount is low");

        if(vestingWallet[_beneficiary].data[_eventProvider].amount == 0){
            vestingWallet[_beneficiary].vestingEventProvider.push(_eventProvider);
            vestingWallet[_beneficiary].size += 1;
        }

        vestingWallet[_beneficiary].data[_eventProvider].amount = vestingWallet[_beneficiary].data[_eventProvider].amount + _amount;
        vestingWallet[_beneficiary].data[_eventProvider].firstClaim = vestingWallet[_beneficiary].data[_eventProvider].amount * firstClaimRate / 100;
        vestingWallet[_beneficiary].data[_eventProvider].vestingPerPeriod = (vestingWallet[_beneficiary].data[_eventProvider].amount - vestingWallet[_beneficiary].data[_eventProvider].firstClaim) / periods;

        vestingWallet[_beneficiary].totalAmount += _amount;
        vaultTotalAmount = vaultTotalAmount + _amount;

        emit VestingAdded(_eventProvider, _beneficiary, _amount);
    }

    /// @notice Method that allows a beneficiary to withdraw vested tokens of a specific vesting event
    function claimTokens(address _eventProvider) external onlyBeneficiaries(msg.sender) hasRequiredRole() vestingEventInitialized(_eventProvider) {
        require(eventProviderMap[tokenAddress].size > 0,"No vesting events");
        require(vestingWallet[msg.sender].size > 0, "No locked tokens");

        uint256 amount = vestedAmountAtTimestamp(msg.sender, block.timestamp, _eventProvider);
        require(amount > 0, "No tokens vested yet");

        // Increased released amount in mapping
        vestingWallet[msg.sender].data[_eventProvider].released += amount;
        vestingWallet[msg.sender].releasedAmount += amount;

        require(vestingWallet[msg.sender].data[_eventProvider].released <= vestingWallet[msg.sender].data[_eventProvider].amount, "Error releasing amount");

        // Increased total released in contract
        vaultTotalReleased += amount;

        buntToken.mint(address(this), amount);
        buntToken.transfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
    }

    /// @notice Method that allows a beneficiary to withdraw all vested tokens of all vesting events
    function claimTokens() external onlyBeneficiaries(msg.sender) hasRequiredRole() {
        require(eventProviderMap[tokenAddress].size > 0,"No vesting events");
        require(vestingWallet[msg.sender].size > 0, "No locked tokens");

        uint256 totalAmount = 0;

        for(uint i = 0; i < vestingWallet[msg.sender].size; i++){

            address provider = vestingWallet[msg.sender].vestingEventProvider[i];
            uint256 amount = vestedAmountAtTimestamp(msg.sender, block.timestamp, provider);

            vestingWallet[msg.sender].data[provider].released += amount;

            require(vestingWallet[msg.sender].data[provider].released <= vestingWallet[msg.sender].data[provider].amount, "Error releasing amount");

            totalAmount += amount;
        }

        require(totalAmount > 0, "No tokens vested yet");

        // Increased released amount in in mapping
        vestingWallet[msg.sender].releasedAmount += totalAmount;

        // Increased total released in contract
        vaultTotalReleased += totalAmount;

        buntToken.mint(address(this), totalAmount);
        buntToken.transfer(msg.sender, totalAmount);

        emit TokensClaimed(msg.sender, totalAmount);
    }

    function updateCliff(uint256 _cliff, address _eventProvider) public onlyRole(VAULT_ADMIN_ROLE) vestingEventInitialized(_eventProvider){
        eventProviderMap[tokenAddress].data[_eventProvider].cliff = _cliff;
        eventProviderMap[tokenAddress].data[_eventProvider].vestingEnd = _cliff + ((eventProviderMap[tokenAddress].data[_eventProvider].periods + 1) * eventProviderMap[tokenAddress].data[_eventProvider].periodDuration);
    }

    function vestingWalletInfo(address _beneficiary, address _eventProvider) public view returns(uint256 amount, uint256 released, uint256 firstClaim, uint256 vestingPerPeriod){
        return (vestingWallet[_beneficiary].data[_eventProvider].amount, vestingWallet[_beneficiary].data[_eventProvider].released, vestingWallet[_beneficiary].data[_eventProvider].firstClaim, vestingWallet[_beneficiary].data[_eventProvider].vestingPerPeriod);
    }

    function vestingEventInfo(address _eventProvider) public view returns(string memory name, uint256 cliff, uint256 firstClaimRate, uint256 periods, uint256 periodDuration, uint256 vestingEnd){
        return (eventProviderMap[tokenAddress].data[_eventProvider].name, eventProviderMap[tokenAddress].data[_eventProvider].cliff, eventProviderMap[tokenAddress].data[_eventProvider].firstClaimRate, eventProviderMap[tokenAddress].data[_eventProvider].periods, eventProviderMap[tokenAddress].data[_eventProvider].periodDuration, eventProviderMap[tokenAddress].data[_eventProvider].vestingEnd);
    }

    function vestedAmount(address _beneficiary, address _eventProvider) public view vestingEventInitialized(_eventProvider) returns (uint256) {
        return vestedAmountAtTimestamp(_beneficiary, block.timestamp, _eventProvider);
    }

    function vestedAmountTotal(address _beneficiary) public view returns (uint256) {
        require(eventProviderMap[tokenAddress].size > 0);
        uint256 totalAmount = 0;

        for(uint i = 0; i < eventProviderMap[tokenAddress].size; i++){
            uint256 amount = vestedAmountAtTimestamp(_beneficiary, block.timestamp, eventProviderMap[tokenAddress].vestingEvents[i].eventProvider);
            totalAmount += amount;
        }

        require(totalAmount > 0, "No tokens vested yet");
        return totalAmount;
    }

    function vestedAmountAtTimestamp(address _beneficiary, uint256 _timestamp, address _eventProvider) public view vestingEventInitialized(_eventProvider) returns (uint256) {
        require(eventProviderMap[tokenAddress].data[_eventProvider].cliff < _timestamp, "vesting not started");

        uint256 timestamp = _timestamp;

        if (_timestamp >= eventProviderMap[tokenAddress].data[_eventProvider].vestingEnd){
            timestamp = eventProviderMap[tokenAddress].data[_eventProvider].vestingEnd;
        }

        uint256 periodsPassed = (timestamp - eventProviderMap[tokenAddress].data[_eventProvider].cliff) / eventProviderMap[tokenAddress].data[_eventProvider].periodDuration;
        require(periodsPassed > 0, "no vested amounts");
        
        if (vestingWallet[_beneficiary].data[_eventProvider].released == 0){
            return (vestingWallet[_beneficiary].data[_eventProvider].vestingPerPeriod * (periodsPassed - 1) + vestingWallet[_beneficiary].data[_eventProvider].firstClaim);
        }
        
        if (periodsPassed >= eventProviderMap[tokenAddress].data[_eventProvider].periods) {
            return (vestingWallet[_beneficiary].data[_eventProvider].amount - vestingWallet[_beneficiary].data[_eventProvider].released);
        }

        return ((vestingWallet[_beneficiary].data[_eventProvider].vestingPerPeriod * periodsPassed) - vestingWallet[_beneficiary].data[_eventProvider].released);
    }

    function vestingPeriod(address _eventProvider) public view vestingEventInitialized(_eventProvider) returns (uint) {
        uint256 cliff = eventProviderMap[tokenAddress].data[_eventProvider].cliff;
        require(cliff < block.timestamp, "vesting not started");
        uint periodsPassed = (block.timestamp - cliff) / (eventProviderMap[tokenAddress].data[_eventProvider].periodDuration);

        if (periodsPassed >= eventProviderMap[tokenAddress].data[_eventProvider].periods) {
            return eventProviderMap[tokenAddress].data[_eventProvider].periods;
        }

        return periodsPassed;
    }

}
// File: TokenSale.sol


pragma solidity ^0.8.2;









contract TokenSale is AccessControl, Whitelist, Finalizable, Initializable {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public USDRate;
    uint256 public bonusRate;

    bool internal initialized;
    bool internal tokenSaleInitialized;
    bool internal vestingEventInitialized;

    VestingVault private vestingVault;

    address internal wallet;
    
    uint256 public maxPurchase;
    uint256 public minPurchase;

    uint256 public softCap;
    uint256 public hardCap;

    uint256 public tokensAllocated;
    uint256 public tokensPurchased;
    uint256 public tokensVested;

    uint256 public BNBRaised;
    uint256 public USDRaised;

    uint256 internal _amountRaisedInUSD;

    Counters.Counter internal _purchasersCounter;

    struct Purchase {
        address purchaser;
        uint256 amount;
        uint256 bonus;
    }

    mapping(address => Purchase) internal purchaserList;

    AggregatorV3Interface internal BNBPriceFeed;

    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount);
    event TokensWithdrawn(address wallet, address token, uint256 amount);
    event FundsWithdrawn(address wallet, uint256 amount);

    modifier isInitialized() {
        require(initialized, "Contract is not initialized");
        _;
    }

    modifier isTokenSaleInitialized() {
        require(tokenSaleInitialized, "Token Sale is not initialized");
        require(vestingEventInitialized, "Vesting event is not initialized");
        _;
    }

    modifier isOpen() {
        require(!finalized(), "Token Sale is Finalized");
        require(_amountRaisedInUSD < hardCap, "Hard Cap Reached");
        _;
    }

    modifier canWithdrawFunds() {
        require(_amountRaisedInUSD >= softCap, "Soft Cap not Reached");
        _;
    }

    modifier canFinalize() {
        require(!finalized(), "Token Sale is Finalized");
        require(_amountRaisedInUSD >= softCap, "Soft Cap not Reached");
        _;
    }

    modifier hasRequiredRole() {
        require(vestingVault.hasRole(keccak256("VAULT_ADMIN_ROLE"), address(this)), "Contract is not vault admin");
        _;
    }


    // Initializer function (replaces constructor)
    function initialize(address _wallet, address _priceFeedAddress, address _vestingVault) initializer public {
        require(!initialized, "Contract instance has already been initialized");
        require (_wallet != address(0), "Wallet is the zero address");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        wallet = _wallet;
        vestingVault = VestingVault(_vestingVault);

        //BSC MAIN NET BNB/USD
        //BNBPriceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        //BSC TEST NET BNB/USD
        //BNBPriceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);

        BNBPriceFeed = AggregatorV3Interface(_priceFeedAddress);     
        initialized = true;   
    }

    // Initializer Token Sale
    function initializeTokenSale(uint256 _USDRate, uint _bonusRate, uint256 _minPurchase, uint256 _maxPurchase, uint256 _softcap, uint256 _hardcap) onlyRole(ADMIN_ROLE) public isInitialized hasRequiredRole {
        require(!tokenSaleInitialized, "Token Sale has already been initialized");

        require(_USDRate > 0);
        require(_minPurchase > 0);
        require(_maxPurchase > 0);
        require(_softcap > 0);
        require(_hardcap > 0);
        require(_bonusRate >= 0 && _bonusRate <= 100, "Bonus rate should be between 0 and 100");

        require(_maxPurchase >= _minPurchase, "maxPurchase is less than minPurchase");

        require(_softcap <=_hardcap, "softCap is larger than hardCap");
        
        USDRate = _USDRate;
        bonusRate = _bonusRate;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softcap;
        hardCap = _hardcap;

        tokensAllocated = _hardcap * _USDRate; 

        tokenSaleInitialized = true;
    }

    function initVestingEvent(string memory _name, uint256 _cliff, uint256 _firstClaimRate, uint256 _periods, uint256 _periodDuration) public isInitialized onlyRole(ADMIN_ROLE) hasRequiredRole {
        vestingVault.addVestingEvent(_name, address(this), _cliff, _firstClaimRate, _periods, _periodDuration);
        vestingEventInitialized = true;
    }

    function addToWhitelist(address _account) public isInitialized onlyRole(ADMIN_ROLE) {
        _addToWhitelist(_account);
    }

    function addManyWhitelist(address[] memory _accounts) public isInitialized onlyRole(ADMIN_ROLE) {
        _addManyWhitelist(_accounts);
    }

    function removeFromWhitelist(address _account) public isInitialized onlyRole(ADMIN_ROLE) {
        _removeFromWhitelist(_account);
    }

    function removeManyWhitelist(address[] memory _accounts) public isInitialized onlyRole(ADMIN_ROLE) {
        _removeManyWhitelist(_accounts);
    }

    function finalize() public isTokenSaleInitialized canFinalize onlyRole(ADMIN_ROLE) {
        _finalize();
    }

    function funded() internal isTokenSaleInitialized canFinalize {
        _finalize();
    }

    function purchaseInUSD(uint256 purchaseAmount, address usdTokenAddress) public isTokenSaleInitialized isOpen isWhitelisted(msg.sender) {

        require(purchaseAmount > 0, "Amount is 0");

        uint256 allowance = IERC20(usdTokenAddress).allowance(msg.sender, address(this));
        
        require(purchaseAmount <= allowance,"Amount larger than allowance");

        uint256 tokens  = purchaseAmount * USDRate;

        _addPurchaser(msg.sender);

        _prePurchaseValidate(msg.sender, purchaseAmount, USDperTokens(tokens));

        USDRaised = USDRaised + purchaseAmount;
        _postPurchaseProcess(msg.sender, USDperTokens(tokens));

        IERC20(usdTokenAddress).transferFrom(msg.sender, address(this), purchaseAmount);

        tokensPurchased = tokensPurchased + tokens;
        
        uint256 totalTokens = tokens + (tokens * bonusRate / 100);
        vestingVault.addVesting(msg.sender, totalTokens, address(this));

        tokensVested = tokensVested + totalTokens;

        emit TokensPurchased(msg.sender, purchaseAmount, totalTokens);
    }

    function purchaseInBNB() public payable isTokenSaleInitialized isOpen isWhitelisted(_msgSender()) {
        require(msg.value > 0, "Amount is 0");

        uint256 purchaseAmount = msg.value;

        uint256 tokens = tokensPerBNB(purchaseAmount);

        _addPurchaser(_msgSender());

        _prePurchaseValidate(_msgSender(), purchaseAmount, USDperTokens(tokens));

        BNBRaised = BNBRaised + purchaseAmount;
        _postPurchaseProcess(_msgSender(), USDperTokens(tokens));

        tokensPurchased = tokensPurchased + tokens;

        uint256 totalTokens = tokens + (tokens * bonusRate / 100);
        vestingVault.addVesting(_msgSender(), totalTokens, address(this));

        tokensVested = tokensVested + totalTokens;

        emit TokensPurchased(_msgSender(), purchaseAmount, totalTokens);
    }

    function withdrawTokens(address _token) public isTokenSaleInitialized onlyRole(ADMIN_ROLE) {
        require(IERC20(_token).balanceOf(address(this)) > 0, "No Tokens in contract");

        IERC20 erc20 = IERC20(_token);
        uint256 tokenBalance = erc20.balanceOf(address(this));

        erc20.transfer(wallet, tokenBalance);

        emit TokensWithdrawn(wallet, _token, tokenBalance);
    }

    ///@notice Enables the admins to withdraw USD when Soft Cap is reached
    function withdrawUSD(address usdTokenAddress) external isTokenSaleInitialized canWithdrawFunds onlyRole(ADMIN_ROLE) { 
        withdrawTokens(usdTokenAddress);      
    }

    ///@notice Enables the admins to withdraw BNB when Soft Cap is reached
    function withdrawFunds() external isTokenSaleInitialized canWithdrawFunds onlyRole(ADMIN_ROLE) {
        require(address(this).balance > 0, "No BNB Balance");

        // payable(wallet).transfer(address(this).balance);

        uint256 funds = address(this).balance;
        Address.sendValue(payable(wallet), funds);

        emit FundsWithdrawn(wallet, funds);
    }

    function capRaisedUSD() public view returns (uint256) {
        return _amountRaisedInUSD;
    }

    function capToRaiseUSD() public view returns (uint256) {
        if(_amountRaisedInUSD >= hardCap){
            return 0;
        }
        else{
            return (hardCap - _amountRaisedInUSD);
        }
    }

    function tokensRemaining() public view returns (uint256) {
        if(tokensPurchased >= tokensAllocated){
            return 0;
        }
        else{
            return tokensAllocated - tokensPurchased;
        }
        
    }

    function tokensGranted() public view returns (uint256) {
        if(tokensVested > 0){
            return tokensVested - tokensPurchased;
        }
        else{
            return 0;
        }
    }

    function balanceBNB() public view returns (uint256 _balance) {
        return address(this).balance;
    }

    function BNBPrice() public view returns (uint256) {
        ( , int price, , , ) = BNBPriceFeed.latestRoundData();
        return uint256(price);
    }

    function tokensPerBNB(uint256 _amount) public view returns (uint256) {
            return (BNBPrice() * (USDRate * _amount));
    }

    function ceil(uint256 a, uint m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

    function tokensPerUSD(uint256 _amount) public view returns (uint256) {
            return _amount * USDRate;
    }

    function USDperTokens(uint256 _tokens) public view returns (uint256) {
            return _tokens / USDRate;
    }

    function BNBperTokens(uint256 _tokens) public view returns (uint256) {
        // return ceil(((_tokens * 10 ** 18) / (USDRate * BNBPrice())) , 10);
        return (_tokens / (USDRate * BNBPrice()));
    }

    function purchasers(address _purchaser) public view returns (uint256) {
            return purchaserList[_purchaser].amount;
    }

    function _addPurchaser(address _purchaser) internal {
        if(purchaserList[_purchaser].amount == 0) {
            Purchase storage purchase_ = purchaserList[_purchaser];
            purchase_.purchaser = _purchaser;
            purchase_.amount = 0;
            _purchasersCounter.increment();
        }
    }

    function purchaserCount() public view returns(uint count) {
        return _purchasersCounter.current();
    }

    function _updatePurchaser(address _purchaser, uint256 _amount) internal {
        purchaserList[_purchaser].amount = purchaserList[_purchaser].amount + _amount;
    }

    function _prePurchaseValidate(address beneficiary, uint256 purchaseAmount, uint256 tokensUSDPrice) internal view {
        require (beneficiary != address(0), "Beneficiary is the zero address");
        require (purchaseAmount != 0, "You have not approved any USD tokens for this contract to receive BUNT");
        require (tokensUSDPrice >= minPurchase, "Amount is less than minPurchase price");
        require (tokensUSDPrice <= maxPurchase, "Amount is larger than maxPurchase price");
        require ((purchaserList[beneficiary].amount + tokensUSDPrice) <= maxPurchase, "Max purchase limit reached");
        require (purchaserList[beneficiary].amount <= capToRaiseUSD(), "amount larger than target cap");
        this;
    }

    function tokenSaleInfo() public view returns(uint256 _USDRate, uint256 _BNBRate, uint256 _bonusRate, uint256 _BNBPrice, uint256 _maxPurchase, uint256 _minPurchase){
        return (USDRate, tokensPerBNB(1), bonusRate, BNBPrice(), maxPurchase, minPurchase);
    }

    function tokenSaleStats() public view returns(uint256 _hardCap, uint256 _capRaised, uint256 _capToRaise, uint256 _tokensAllocated, uint256 _tokensPurchased, uint256 _tokensRemaining, uint256 _tokensGranted){
        return (hardCap, capRaisedUSD(), capToRaiseUSD(), tokensAllocated, tokensPurchased, tokensRemaining(), tokensGranted());
    }

    function _postPurchaseProcess(address purchaser, uint256 amount) internal {
        _amountRaisedInUSD += amount;
        _updatePurchaser(purchaser, amount);
                
        if(_amountRaisedInUSD >= hardCap){
            funded();
        }

        if(capToRaiseUSD() < minPurchase){
            minPurchase = capToRaiseUSD();
            maxPurchase = minPurchase;
        }
    }

    receive() external payable virtual {
        purchaseInBNB();
    }
}