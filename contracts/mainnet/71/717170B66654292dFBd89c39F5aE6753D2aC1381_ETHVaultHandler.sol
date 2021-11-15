// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";

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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;


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
pragma solidity 0.7.5;

import "./IVaultHandler.sol";
import "./Orchestrator.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ETH TCAP Vault
 * @author Cryptex.finance
 * @notice Contract in charge of handling the TCAP Vault and stake using a ETH and WETH
 */
contract ETHVaultHandler is IVaultHandler {
  /// @notice Open Zeppelin libraries
  using SafeMath for uint256;

  /**
   * @notice Constructor
   * @param _orchestrator address
   * @param _divisor uint256
   * @param _ratio uint256
   * @param _burnFee uint256
   * @param _liquidationPenalty uint256
   * @param _tcapOracle address
   * @param _tcapAddress address
   * @param _collateralAddress address
   * @param _collateralOracle address
   * @param _ethOracle address
   * @param _rewardHandler address
   * @param _treasury address
   */
  constructor(
    Orchestrator _orchestrator,
    uint256 _divisor,
    uint256 _ratio,
    uint256 _burnFee,
    uint256 _liquidationPenalty,
    address _tcapOracle,
    TCAP _tcapAddress,
    address _collateralAddress,
    address _collateralOracle,
    address _ethOracle,
    address _rewardHandler,
    address _treasury
  )
    IVaultHandler(
      _orchestrator,
      _divisor,
      _ratio,
      _burnFee,
      _liquidationPenalty,
      _tcapOracle,
      _tcapAddress,
      _collateralAddress,
      _collateralOracle,
      _ethOracle,
      _rewardHandler,
      _treasury
    )
  {}

  /**
   * @notice only accept ETH via fallback from the WETH contract
   */
  receive() external payable {
    assert(msg.sender == address(collateralContract));
  }

  /**
   * @notice Adds collateral to vault using ETH
   * @dev value should be higher than 0
   * @dev ETH is turned into WETH
   */
  function addCollateralETH()
    external
    payable
    nonReentrant
    vaultExists
    whenNotPaused
  {
    require(
      msg.value > 0,
      "ETHVaultHandler::addCollateralETH: value can't be 0"
    );
    IWETH(address(collateralContract)).deposit{value: msg.value}();
    Vault storage vault = vaults[userToVault[msg.sender]];
    vault.Collateral = vault.Collateral.add(msg.value);
    emit CollateralAdded(msg.sender, vault.Id, msg.value);
  }

  /**
   * @notice Removes not used collateral from vault
   * @param _amount of collateral to remove
   * @dev _amount should be higher than 0
   * @dev WETH is turned into ETH
   */
  function removeCollateralETH(uint256 _amount)
    external
    nonReentrant
    vaultExists
    whenNotPaused
  {
    require(
      _amount > 0,
      "ETHVaultHandler::removeCollateralETH: value can't be 0"
    );
    Vault storage vault = vaults[userToVault[msg.sender]];
    uint256 currentRatio = getVaultRatio(vault.Id);
    require(
      vault.Collateral >= _amount,
      "ETHVaultHandler::removeCollateralETH: retrieve amount higher than collateral"
    );
    vault.Collateral = vault.Collateral.sub(_amount);
    if (currentRatio != 0) {
      require(
        getVaultRatio(vault.Id) >= ratio,
        "ETHVaultHandler::removeCollateralETH: collateral below min required ratio"
      );
    }

    IWETH(address(collateralContract)).withdraw(_amount);
    safeTransferETH(msg.sender, _amount);
    emit CollateralRemoved(msg.sender, vault.Id, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "./TCAP.sol";
import "./Orchestrator.sol";
import "./oracles/ChainlinkOracle.sol";

interface IRewardHandler {
  function stake(address _staker, uint256 amount) external;

  function withdraw(address _staker, uint256 amount) external;

  function getRewardFromVault(address _staker) external;
}

/**
 * @title TCAP Vault Handler Abstract Contract
 * @author Cryptex.Finance
 * @notice Contract in charge of handling the TCAP Token and stake
 */
abstract contract IVaultHandler is
  Ownable,
  AccessControl,
  ReentrancyGuard,
  Pausable,
  IERC165
{
  /// @notice Open Zeppelin libraries
  using SafeMath for uint256;
  using SafeCast for int256;
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

  /**
   * @notice Vault object created to manage the mint and burns of TCAP tokens
   * @param Id, unique identifier of the vault
   * @param Collateral, current collateral on vault
   * @param Debt, current amount of TCAP tokens minted
   * @param Owner, owner of the vault
   */
  struct Vault {
    uint256 Id;
    uint256 Collateral;
    uint256 Debt;
    address Owner;
  }

  /// @notice Vault Id counter
  Counters.Counter public counter;

  /// @notice TCAP Token Address
  TCAP public immutable TCAPToken;

  /// @notice Total Market Cap/USD Oracle Address
  ChainlinkOracle public immutable tcapOracle;

  /// @notice Collateral Token Address
  IERC20 public immutable collateralContract;

  /// @notice Collateral/USD Oracle Address
  ChainlinkOracle public immutable collateralPriceOracle;

  /// @notice ETH/USD Oracle Address
  ChainlinkOracle public immutable ETHPriceOracle;

  /// @notice Value used as divisor with the total market cap, just like the S&P 500 or any major financial index would to define the final tcap token price
  uint256 public divisor;

  /// @notice Minimun ratio required to prevent liquidation of vault
  uint256 public ratio;

  /// @notice Fee percentage of the total amount to burn charged on ETH when burning TCAP Tokens
  uint256 public burnFee;

  /// @notice Penalty charged to vault owner when a vault is liquidated, this value goes to the liquidator
  uint256 public liquidationPenalty;

  /// @notice Address of the contract that gives rewards to minters of TCAP, rewards are only given if address is set in constructor
  IRewardHandler public immutable rewardHandler;

  /// @notice Address of the treasury contract (usually the timelock) where the funds generated by the protocol are sent
  address public treasury;

  /// @notice Owner address to Vault Id
  mapping(address => uint256) public userToVault;

  /// @notice Id To Vault
  mapping(uint256 => Vault) public vaults;

  /// @notice value used to multiply chainlink oracle for handling decimals
  uint256 public constant oracleDigits = 10000000000;

  /// @notice Minimum value that the ratio can be set to
  uint256 public constant MIN_RATIO = 150;

  /// @notice Maximum value that the burn fee can be set to
  uint256 public constant MAX_FEE = 10;

  /**
   * @dev the computed interface ID according to ERC-165. The interface ID is a XOR of interface method selectors.
   * setRatio.selector ^
   * setBurnFee.selector ^
   * setLiquidationPenalty.selector ^
   * pause.selector ^
   * unpause.selector =>  0x9e75ab0c
   */
  bytes4 private constant _INTERFACE_ID_IVAULT = 0x9e75ab0c;

  /**
   * @dev the computed interface ID according to ERC-165. The interface ID is a XOR of interface method selectors.
   * queueTransaction.selector ^
   * cancelTransaction.selector ^
   * executeTransaction.selector  =>  0x6b5cc770
   */
  bytes4 private constant _INTERFACE_ID_TIMELOCK = 0x6b5cc770;

  /// @dev bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  /// @notice An event emitted when the ratio is updated
  event NewRatio(address indexed _owner, uint256 _ratio);

  /// @notice An event emitted when the burn fee is updated
  event NewBurnFee(address indexed _owner, uint256 _burnFee);

  /// @notice An event emitted when the liquidation penalty is updated
  event NewLiquidationPenalty(
    address indexed _owner,
    uint256 _liquidationPenalty
  );

  /// @notice An event emitted when the treasury contract is updated
  event NewTreasury(address indexed _owner, address _tresury);

  /// @notice An event emitted when a vault is created
  event VaultCreated(address indexed _owner, uint256 indexed _id);

  /// @notice An event emitted when collateral is added to a vault
  event CollateralAdded(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  /// @notice An event emitted when collateral is removed from a vault
  event CollateralRemoved(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  /// @notice An event emitted when tokens are minted
  event TokensMinted(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  /// @notice An event emitted when tokens are burned
  event TokensBurned(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  /// @notice An event emitted when a vault is liquidated
  event VaultLiquidated(
    uint256 indexed _vaultId,
    address indexed _liquidator,
    uint256 _liquidationCollateral,
    uint256 _reward
  );

  /// @notice An event emitted when a erc20 token is recovered
  event Recovered(address _token, uint256 _amount);

  /**
   * @notice Constructor
   * @param _orchestrator address
   * @param _divisor uint256
   * @param _ratio uint256
   * @param _burnFee uint256
   * @param _liquidationPenalty uint256
   * @param _tcapOracle address
   * @param _tcapAddress address
   * @param _collateralAddress address
   * @param _collateralOracle address
   * @param _ethOracle address
   * @param _rewardHandler address
   * @param _treasury address
   */
  constructor(
    Orchestrator _orchestrator,
    uint256 _divisor,
    uint256 _ratio,
    uint256 _burnFee,
    uint256 _liquidationPenalty,
    address _tcapOracle,
    TCAP _tcapAddress,
    address _collateralAddress,
    address _collateralOracle,
    address _ethOracle,
    address _rewardHandler,
    address _treasury
  ) {
    require(
      _liquidationPenalty.add(100) < _ratio,
      "VaultHandler::constructor: liquidation penalty too high"
    );
    require(
      _ratio >= MIN_RATIO,
      "VaultHandler::constructor: ratio lower than MIN_RATIO"
    );

    require(
      _burnFee <= MAX_FEE,
      "VaultHandler::constructor: burn fee higher than MAX_FEE"
    );

    require(
      ERC165Checker.supportsInterface(_treasury, _INTERFACE_ID_TIMELOCK),
      "VaultHandler::constructor: not a valid treasury"
    );

    divisor = _divisor;
    ratio = _ratio;
    burnFee = _burnFee;
    liquidationPenalty = _liquidationPenalty;
    tcapOracle = ChainlinkOracle(_tcapOracle);
    collateralContract = IERC20(_collateralAddress);
    collateralPriceOracle = ChainlinkOracle(_collateralOracle);
    ETHPriceOracle = ChainlinkOracle(_ethOracle);
    TCAPToken = _tcapAddress;
    rewardHandler = IRewardHandler(_rewardHandler);
    treasury = _treasury;

    /// @dev counter starts in 1 as 0 is reserved for empty objects
    counter.increment();

    /// @dev transfer ownership to orchestrator
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    transferOwnership(address(_orchestrator));
  }

  /// @notice Reverts if the user hasn't created a vault.
  modifier vaultExists() {
    require(
      userToVault[msg.sender] != 0,
      "VaultHandler::vaultExists: no vault created"
    );
    _;
  }

  /// @notice Reverts if value is 0.
  modifier notZero(uint256 _value) {
    require(_value != 0, "VaultHandler::notZero: value can't be 0");
    _;
  }

  /**
   * @notice Sets the collateral ratio needed to mint tokens
   * @param _ratio uint
   * @dev Only owner can call it
   */
  function setRatio(uint256 _ratio) external virtual onlyOwner {
    require(
      _ratio >= MIN_RATIO,
      "VaultHandler::setRatio: ratio lower than MIN_RATIO"
    );
    ratio = _ratio;
    emit NewRatio(msg.sender, _ratio);
  }

  /**
   * @notice Sets the burn fee percentage an user pays when burning tcap tokens
   * @param _burnFee uint
   * @dev Only owner can call it
   */
  function setBurnFee(uint256 _burnFee) external virtual onlyOwner {
    require(
      _burnFee <= MAX_FEE,
      "VaultHandler::setBurnFee: burn fee higher than MAX_FEE"
    );
    burnFee = _burnFee;
    emit NewBurnFee(msg.sender, _burnFee);
  }

  /**
   * @notice Sets the liquidation penalty % charged on liquidation
   * @param _liquidationPenalty uint
   * @dev Only owner can call it
   * @dev recommended value is between 1-15% and can't be above 100%
   */
  function setLiquidationPenalty(uint256 _liquidationPenalty)
    external
    virtual
    onlyOwner
  {
    require(
      _liquidationPenalty.add(100) < ratio,
      "VaultHandler::setLiquidationPenalty: liquidation penalty too high"
    );

    liquidationPenalty = _liquidationPenalty;
    emit NewLiquidationPenalty(msg.sender, _liquidationPenalty);
  }

  /**
   * @notice Sets the treasury contract address where fees are transfered to
   * @param _treasury address
   * @dev Only owner can call it
   */
  function setTreasury(address _treasury) external virtual onlyOwner {
    require(
      ERC165Checker.supportsInterface(_treasury, _INTERFACE_ID_TIMELOCK),
      "VaultHandler::setTreasury: not a valid treasury"
    );
    treasury = (_treasury);
    emit NewTreasury(msg.sender, _treasury);
  }

  /**
   * @notice Allows an user to create an unique Vault
   * @dev Only one vault per address can be created
   */
  function createVault() external virtual whenNotPaused {
    require(
      userToVault[msg.sender] == 0,
      "VaultHandler::createVault: vault already created"
    );

    uint256 id = counter.current();
    userToVault[msg.sender] = id;
    Vault memory vault = Vault(id, 0, 0, msg.sender);
    vaults[id] = vault;
    counter.increment();
    emit VaultCreated(msg.sender, id);
  }

  /**
   * @notice Allows users to add collateral to their vaults
   * @param _amount of collateral to be added
   * @dev _amount should be higher than 0
   * @dev ERC20 token must be approved first
   */
  function addCollateral(uint256 _amount)
    external
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    require(
      collateralContract.transferFrom(msg.sender, address(this), _amount),
      "VaultHandler::addCollateral: ERC20 transfer did not succeed"
    );

    Vault storage vault = vaults[userToVault[msg.sender]];
    vault.Collateral = vault.Collateral.add(_amount);
    emit CollateralAdded(msg.sender, vault.Id, _amount);
  }

  /**
   * @notice Allows users to remove collateral currently not being used to generate TCAP tokens from their vaults
   * @param _amount of collateral to remove
   * @dev reverts if the resulting ratio is less than the minimun ratio
   * @dev _amount should be higher than 0
   * @dev transfers the collateral back to the user
   */
  function removeCollateral(uint256 _amount)
    external
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    Vault storage vault = vaults[userToVault[msg.sender]];
    uint256 currentRatio = getVaultRatio(vault.Id);

    require(
      vault.Collateral >= _amount,
      "VaultHandler::removeCollateral: retrieve amount higher than collateral"
    );

    vault.Collateral = vault.Collateral.sub(_amount);
    if (currentRatio != 0) {
      require(
        getVaultRatio(vault.Id) >= ratio,
        "VaultHandler::removeCollateral: collateral below min required ratio"
      );
    }
    require(
      collateralContract.transfer(msg.sender, _amount),
      "VaultHandler::removeCollateral: ERC20 transfer did not succeed"
    );
    emit CollateralRemoved(msg.sender, vault.Id, _amount);
  }

  /**
   * @notice Uses collateral to generate debt on TCAP Tokens which are minted and assigend to caller
   * @param _amount of tokens to mint
   * @dev _amount should be higher than 0
   * @dev requires to have a vault ratio above the minimum ratio
   * @dev if reward handler is set stake to earn rewards
   */
  function mint(uint256 _amount)
    external
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    Vault storage vault = vaults[userToVault[msg.sender]];
    uint256 collateral = requiredCollateral(_amount);

    require(
      vault.Collateral >= collateral,
      "VaultHandler::mint: not enough collateral"
    );

    vault.Debt = vault.Debt.add(_amount);
    require(
      getVaultRatio(vault.Id) >= ratio,
      "VaultHandler::mint: collateral below min required ratio"
    );

    if (address(rewardHandler) != address(0)) {
      rewardHandler.stake(msg.sender, _amount);
    }

    TCAPToken.mint(msg.sender, _amount);
    emit TokensMinted(msg.sender, vault.Id, _amount);
  }

  /**
   * @notice Pays the debt of TCAP tokens resulting them on burn, this releases collateral up to minimun vault ratio
   * @param _amount of tokens to burn
   * @dev _amount should be higher than 0
   * @dev A fee of exactly burnFee must be sent as value on ETH
   * @dev The fee goes to the treasury contract
   * @dev if reward handler is set exit rewards
   */
  function burn(uint256 _amount)
    external
    payable
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    uint256 fee = getFee(_amount);
    require(
      msg.value >= fee,
      "VaultHandler::burn: burn fee less than required"
    );

    Vault memory vault = vaults[userToVault[msg.sender]];

    _burn(vault.Id, _amount);

    if (address(rewardHandler) != address(0)) {
      rewardHandler.withdraw(msg.sender, _amount);
      rewardHandler.getRewardFromVault(msg.sender);
    }
    safeTransferETH(treasury, fee);

    //send back ETH above fee
    safeTransferETH(msg.sender, msg.value.sub(fee));
    emit TokensBurned(msg.sender, vault.Id, _amount);
  }

  /**
   * @notice Allow users to burn TCAP tokens to liquidate vaults with vault collateral ratio under the minium ratio, the liquidator receives the staked collateral of the liquidated vault at a premium
   * @param _vaultId to liquidate
   * @param _maxTCAP max amount of TCAP the liquidator is willing to pay to liquidate vault
   * @dev Resulting ratio must be above or equal minimun ratio
   * @dev A fee of exactly burnFee must be sent as value on ETH
   * @dev The fee goes to the treasury contract
   */
  function liquidateVault(uint256 _vaultId, uint256 _maxTCAP)
    external
    payable
    nonReentrant
    whenNotPaused
  {
    Vault storage vault = vaults[_vaultId];
    require(vault.Id != 0, "VaultHandler::liquidateVault: no vault created");

    uint256 vaultRatio = getVaultRatio(vault.Id);
    require(
      vaultRatio < ratio,
      "VaultHandler::liquidateVault: vault is not liquidable"
    );

    uint256 requiredTCAP = requiredLiquidationTCAP(vault.Id);
    require(
      _maxTCAP >= requiredTCAP,
      "VaultHandler::liquidateVault: liquidation amount different than required"
    );

    uint256 fee = getFee(requiredTCAP);
    require(
      msg.value >= fee,
      "VaultHandler::liquidateVault: burn fee less than required"
    );

    uint256 reward = liquidationReward(vault.Id);
    _burn(vault.Id, requiredTCAP);

    //Removes the collateral that is rewarded to liquidator
    vault.Collateral = vault.Collateral.sub(reward);

    // Triggers update of CTX Rewards
    if (address(rewardHandler) != address(0)) {
      rewardHandler.withdraw(vault.Owner, requiredTCAP);
    }

    require(
      collateralContract.transfer(msg.sender, reward),
      "VaultHandler::liquidateVault: ERC20 transfer did not succeed"
    );
    safeTransferETH(treasury, fee);

    //send back ETH above fee
    safeTransferETH(msg.sender, msg.value.sub(fee));
    emit VaultLiquidated(vault.Id, msg.sender, requiredTCAP, reward);
  }

  /**
   * @notice Allows the owner to Pause the Contract
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Allows the owner to Unpause the Contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice  Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
   * @param _tokenAddress address
   * @param _tokenAmount uint
   * @dev Only owner  can call it
   */
  function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
    external
    onlyOwner
  {
    // Cannot recover the collateral token
    require(
      _tokenAddress != address(collateralContract),
      "Cannot withdraw the collateral tokens"
    );
    IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
    emit Recovered(_tokenAddress, _tokenAmount);
  }

  /**
   * @notice Allows the safe transfer of ETH
   * @param _to account to transfer ETH
   * @param _value amount of ETH
   */
  function safeTransferETH(address _to, uint256 _value) internal {
    (bool success, ) = _to.call{value: _value}(new bytes(0));
    require(success, "ETHVaultHandler::safeTransferETH: ETH transfer failed");
  }

  /**
   * @notice ERC165 Standard for support of interfaces
   * @param _interfaceId bytes of interface
   * @return bool
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (_interfaceId == _INTERFACE_ID_IVAULT ||
      _interfaceId == _INTERFACE_ID_ERC165);
  }

  /**
   * @notice Returns the Vault information of specified identifier
   * @param _id of vault
   * @return Id, Collateral, Owner, Debt
   */
  function getVault(uint256 _id)
    external
    view
    virtual
    returns (
      uint256,
      uint256,
      address,
      uint256
    )
  {
    Vault memory vault = vaults[_id];
    return (vault.Id, vault.Collateral, vault.Owner, vault.Debt);
  }

  /**
   * @notice Returns the price of the chainlink oracle multiplied by the digits to get 18 decimals format
   * @param _oracle to be the price called
   * @return price
   */
  function getOraclePrice(ChainlinkOracle _oracle)
    public
    view
    virtual
    returns (uint256 price)
  {
    price = _oracle.getLatestAnswer().toUint256().mul(oracleDigits);
  }

  /**
   * @notice Returns the price of the TCAP token
   * @return price of the TCAP Token
   * @dev TCAP token is 18 decimals
   * @dev oracle totalMarketPrice must be in wei format
   * @dev P = T / d
   * P = TCAP Token Price
   * T = Total Crypto Market Cap
   * d = Divisor
   */
  function TCAPPrice() public view virtual returns (uint256 price) {
    uint256 totalMarketPrice = getOraclePrice(tcapOracle);
    price = totalMarketPrice.div(divisor);
  }

  /**
   * @notice Returns the minimal required collateral to mint TCAP token
   * @param _amount uint amount to mint
   * @return collateral of the TCAP Token
   * @dev TCAP token is 18 decimals
   * @dev C = ((P * A * r) / 100) / cp
   * C = Required Collateral
   * P = TCAP Token Price
   * A = Amount to Mint
   * cp = Collateral Price
   * r = Minimun Ratio for Liquidation
   * Is only divided by 100 as eth price comes in wei to cancel the additional 0s
   */
  function requiredCollateral(uint256 _amount)
    public
    view
    virtual
    returns (uint256 collateral)
  {
    uint256 tcapPrice = TCAPPrice();
    uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
    collateral = ((tcapPrice.mul(_amount).mul(ratio)).div(100)).div(
      collateralPrice
    );
  }

  /**
   * @notice Returns the minimal required TCAP to liquidate a Vault
   * @param _vaultId of the vault to liquidate
   * @return amount required of the TCAP Token
   * @dev LT = ((((D * r) / 100) - cTcap) * 100) / (r - (p + 100))
   * cTcap = ((C * cp) / P)
   * LT = Required TCAP
   * D = Vault Debt
   * C = Required Collateral
   * P = TCAP Token Price
   * cp = Collateral Price
   * r = Min Vault Ratio
   * p = Liquidation Penalty
   */
  function requiredLiquidationTCAP(uint256 _vaultId)
    public
    view
    virtual
    returns (uint256 amount)
  {
    Vault memory vault = vaults[_vaultId];
    uint256 tcapPrice = TCAPPrice();
    uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
    uint256 collateralTcap =
      (vault.Collateral.mul(collateralPrice)).div(tcapPrice);
    uint256 reqDividend =
      (((vault.Debt.mul(ratio)).div(100)).sub(collateralTcap)).mul(100);
    uint256 reqDivisor = ratio.sub(liquidationPenalty.add(100));
    amount = reqDividend.div(reqDivisor);
  }

  /**
   * @notice Returns the Reward for liquidating a vault
   * @param _vaultId of the vault to liquidate
   * @return rewardCollateral for liquidating Vault
   * @dev the returned value is returned as collateral currency
   * @dev R = (LT * (p  + 100)) / 100
   * R = Liquidation Reward
   * LT = Required Liquidation TCAP
   * p = liquidation penalty
   */
  function liquidationReward(uint256 _vaultId)
    public
    view
    virtual
    returns (uint256 rewardCollateral)
  {
    uint256 req = requiredLiquidationTCAP(_vaultId);
    uint256 tcapPrice = TCAPPrice();
    uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
    uint256 reward = (req.mul(liquidationPenalty.add(100)));
    rewardCollateral = (reward.mul(tcapPrice)).div(collateralPrice.mul(100));
  }

  /**
   * @notice Returns the Collateral Ratio of the Vault
   * @param _vaultId id of vault
   * @return currentRatio
   * @dev vr = (cp * (C * 100)) / D * P
   * vr = Vault Ratio
   * C = Vault Collateral
   * cp = Collateral Price
   * D = Vault Debt
   * P = TCAP Token Price
   */
  function getVaultRatio(uint256 _vaultId)
    public
    view
    virtual
    returns (uint256 currentRatio)
  {
    Vault memory vault = vaults[_vaultId];
    if (vault.Id == 0 || vault.Debt == 0) {
      currentRatio = 0;
    } else {
      uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
      currentRatio = (
        (collateralPrice.mul(vault.Collateral.mul(100))).div(
          vault.Debt.mul(TCAPPrice())
        )
      );
    }
  }

  /**
   * @notice Returns the required fee of ETH to burn the TCAP tokens
   * @param _amount to burn
   * @return fee
   * @dev The returned value is returned in wei
   * @dev f = (((P * A * b)/ 100))/ EP
   * f = Burn Fee Value
   * P = TCAP Token Price
   * A = Amount to Burn
   * b = Burn Fee %
   * EP = ETH Price
   */
  function getFee(uint256 _amount) public view virtual returns (uint256 fee) {
    uint256 ethPrice = getOraclePrice(ETHPriceOracle);
    fee = (TCAPPrice().mul(_amount).mul(burnFee)).div(100).div(ethPrice);
  }

  /**
   * @notice Burns an amount of TCAP Tokens
   * @param _vaultId vault id
   * @param _amount to burn
   */
  function _burn(uint256 _vaultId, uint256 _amount) internal {
    Vault storage vault = vaults[_vaultId];
    require(
      vault.Debt >= _amount,
      "VaultHandler::burn: amount greater than debt"
    );
    vault.Debt = vault.Debt.sub(_amount);
    TCAPToken.burn(msg.sender, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

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
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "./IVaultHandler.sol";
import "./TCAP.sol";
import "./oracles/ChainlinkOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TCAP Orchestrator
 * @author Cryptex.finance
 * @notice Orchestrator contract in charge of managing the settings of the vaults, rewards and TCAP token. It acts as the owner of these contracts.
 */
contract Orchestrator is Ownable {
  /// @dev Enum which saves the available functions to emergency call.
  enum Functions {BURNFEE, LIQUIDATION, PAUSE}

  /// @notice Address that can set to 0 the fees or pause the vaults in an emergency event
  address public guardian;

  /** @dev Interface constants*/
  bytes4 private constant _INTERFACE_ID_IVAULT = 0x9e75ab0c;
  bytes4 private constant _INTERFACE_ID_TCAP = 0xbd115939;
  bytes4 private constant _INTERFACE_ID_CHAINLINK_ORACLE = 0x85be402b;

  /// @dev tracks which vault was emergency called
  mapping(IVaultHandler => mapping(Functions => bool)) private emergencyCalled;

  /// @notice An event emitted when the guardian is updated
  event GuardianSet(address indexed _owner, address guardian);

  /// @notice An event emitted when a transaction is executed
  event TransactionExecuted(
    address indexed target,
    uint256 value,
    string signature,
    bytes data
  );

  /**
   * @notice Constructor
   * @param _guardian The guardian address
   */
  constructor(address _guardian) {
    require(
      _guardian != address(0),
      "Orchestrator::constructor: guardian can't be zero"
    );
    guardian = _guardian;
  }

  /// @notice Throws if called by any account other than the guardian
  modifier onlyGuardian() {
    require(
      msg.sender == guardian,
      "Orchestrator::onlyGuardian: caller is not the guardian"
    );
    _;
  }

  /**
   * @notice Throws if vault is not valid.
   * @param _vault address
   */
  modifier validVault(IVaultHandler _vault) {
    require(
      ERC165Checker.supportsInterface(address(_vault), _INTERFACE_ID_IVAULT),
      "Orchestrator::validVault: not a valid vault"
    );
    _;
  }

  /**
   * @notice Throws if TCAP Token is not valid
   * @param _tcap address
   */
  modifier validTCAP(TCAP _tcap) {
    require(
      ERC165Checker.supportsInterface(address(_tcap), _INTERFACE_ID_TCAP),
      "Orchestrator::validTCAP: not a valid TCAP ERC20"
    );
    _;
  }

  /**
   * @notice Throws if Chainlink Oracle is not valid
   * @param _oracle address
   */
  modifier validChainlinkOracle(address _oracle) {
    require(
      ERC165Checker.supportsInterface(
        address(_oracle),
        _INTERFACE_ID_CHAINLINK_ORACLE
      ),
      "Orchestrator::validChainlinkOrchestrator: not a valid Chainlink Oracle"
    );
    _;
  }

  /**
   * @notice Sets the guardian of the orchestrator
   * @param _guardian address of the guardian
   * @dev Only owner can call it
   */
  function setGuardian(address _guardian) external onlyOwner {
    require(
      _guardian != address(0),
      "Orchestrator::setGuardian: guardian can't be zero"
    );
    guardian = _guardian;
    emit GuardianSet(msg.sender, _guardian);
  }

  /**
   * @notice Sets the ratio of a vault
   * @param _vault address
   * @param _ratio value
   * @dev Only owner can call it
   */
  function setRatio(IVaultHandler _vault, uint256 _ratio)
    external
    onlyOwner
    validVault(_vault)
  {
    _vault.setRatio(_ratio);
  }

  /**
   * @notice Sets the burn fee of a vault
   * @param _vault address
   * @param _burnFee value
   * @dev Only owner can call it
   */
  function setBurnFee(IVaultHandler _vault, uint256 _burnFee)
    external
    onlyOwner
    validVault(_vault)
  {
    _vault.setBurnFee(_burnFee);
  }

  /**
   * @notice Sets the burn fee to 0, only used on a black swan event
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function setEmergencyBurnFee(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.BURNFEE] != true,
      "Orchestrator::setEmergencyBurnFee: emergency call already used"
    );
    emergencyCalled[_vault][Functions.BURNFEE] = true;
    _vault.setBurnFee(0);
  }

  /**
   * @notice Sets the liquidation penalty of a vault
   * @param _vault address
   * @param _liquidationPenalty value
   * @dev Only owner can call it
   */
  function setLiquidationPenalty(
    IVaultHandler _vault,
    uint256 _liquidationPenalty
  ) external onlyOwner validVault(_vault) {
    _vault.setLiquidationPenalty(_liquidationPenalty);
  }

  /**
   * @notice Sets the liquidation penalty of a vault to 0, only used on a black swan event
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function setEmergencyLiquidationPenalty(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.LIQUIDATION] != true,
      "Orchestrator::setEmergencyLiquidationPenalty: emergency call already used"
    );
    emergencyCalled[_vault][Functions.LIQUIDATION] = true;
    _vault.setLiquidationPenalty(0);
  }

  /**
   * @notice Pauses the Vault
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function pauseVault(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.PAUSE] != true,
      "Orchestrator::pauseVault: emergency call already used"
    );
    emergencyCalled[_vault][Functions.PAUSE] = true;
    _vault.pause();
  }

  /**
   * @notice Unpauses the Vault
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function unpauseVault(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    _vault.unpause();
  }

  /**
   * @notice Enables or disables the TCAP Cap
   * @param _tcap address
   * @param _enable bool
   * @dev Only owner can call it
   * @dev Validates if _tcap is valid
   */
  function enableTCAPCap(TCAP _tcap, bool _enable)
    external
    onlyOwner
    validTCAP(_tcap)
  {
    _tcap.enableCap(_enable);
  }

  /**
   * @notice Sets the TCAP maximum minting value
   * @param _tcap address
   * @param _cap uint value
   * @dev Only owner can call it
   * @dev Validates if _tcap is valid
   */
  function setTCAPCap(TCAP _tcap, uint256 _cap)
    external
    onlyOwner
    validTCAP(_tcap)
  {
    _tcap.setCap(_cap);
  }

  /**
   * @notice Adds Vault to TCAP ERC20
   * @param _tcap address
   * @param _vault address
   * @dev Only owner can call it
   * @dev Validates if _tcap is valid
   * @dev Validates if _vault is valid
   */
  function addTCAPVault(TCAP _tcap, IVaultHandler _vault)
    external
    onlyOwner
    validTCAP(_tcap)
    validVault(_vault)
  {
    _tcap.addVaultHandler(address(_vault));
  }

  /**
   * @notice Removes Vault to TCAP ERC20
   * @param _tcap address
   * @param _vault address
   * @dev Only owner can call it
   * @dev Validates if _tcap is valid
   * @dev Validates if _vault is valid
   */
  function removeTCAPVault(TCAP _tcap, IVaultHandler _vault)
    external
    onlyOwner
    validTCAP(_tcap)
    validVault(_vault)
  {
    _tcap.removeVaultHandler(address(_vault));
  }

  /**
   * @notice Allows the owner to execute custom transactions
   * @param target address
   * @param value uint256
   * @param signature string
   * @param data bytes
   * @dev Only owner can call it
   */
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data
  ) external payable onlyOwner returns (bytes memory) {
    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    require(
      target != address(0),
      "Orchestrator::executeTransaction: target can't be zero"
    );

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) =
      target.call{value: value}(callData);
    require(
      success,
      "Orchestrator::executeTransaction: Transaction execution reverted."
    );

    emit TransactionExecuted(target, value, signature, data);
    (target, value, signature, data);

    return returnData;
  }

  /**
   * @notice Retrieves the eth stuck on the orchestrator
   * @param _to address
   * @dev Only owner can call it
   */
  function retrieveETH(address _to) external onlyOwner {
    require(
      _to != address(0),
      "Orchestrator::retrieveETH: address can't be zero"
    );
    uint256 amount = address(this).balance;
    payable(_to).transfer(amount);
  }

  /// @notice Allows the contract to receive ETH
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Orchestrator.sol";

/**
 * @title Total Market Cap Token
 * @author Cryptex.finance
 * @notice ERC20 token on the Ethereum Blockchain that provides total exposure to the cryptocurrency sector.
 */
contract TCAP is ERC20, Ownable, IERC165 {
  /// @notice Open Zeppelin libraries
  using SafeMath for uint256;

  /// @notice if enabled TCAP can't be minted if the total supply is above or equal the cap value
  bool public capEnabled = false;

  /// @notice Maximum value the total supply of TCAP
  uint256 public cap;

  /**
   * @notice Address to Vault Handler
   * @dev Only vault handlers can mint and burn TCAP
   */
  mapping(address => bool) public vaultHandlers;

  /**
   * @dev the computed interface ID according to ERC-165. The interface ID is a XOR of interface method selectors.
   * mint.selector ^
   * burn.selector ^
   * setCap.selector ^
   * enableCap.selector ^
   * transfer.selector ^
   * transferFrom.selector ^
   * addVaultHandler.selector ^
   * removeVaultHandler.selector ^
   * approve.selector => 0xbd115939
   */
  bytes4 private constant _INTERFACE_ID_TCAP = 0xbd115939;

  /// @dev bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  /// @notice An event emitted when a vault handler is added
  event VaultHandlerAdded(
    address indexed _owner,
    address indexed _tokenHandler
  );

  /// @notice An event emitted when a vault handler is removed
  event VaultHandlerRemoved(
    address indexed _owner,
    address indexed _tokenHandler
  );

  /// @notice An event emitted when the cap value is updated
  event NewCap(address indexed _owner, uint256 _amount);

  /// @notice An event emitted when the cap is enabled or disabled
  event NewCapEnabled(address indexed _owner, bool _enable);

  /**
   * @notice Constructor
   * @param _name uint256
   * @param _symbol uint256
   * @param _cap uint256
   * @param _orchestrator address
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _cap,
    Orchestrator _orchestrator
  ) ERC20(_name, _symbol) {
    cap = _cap;

    /// @dev transfer ownership to orchestrator
    transferOwnership(address(_orchestrator));
  }

  /// @notice Reverts if called by any account that is not a vault.
  modifier onlyVault() {
    require(
      vaultHandlers[msg.sender],
      "TCAP::onlyVault: caller is not a vault"
    );
    _;
  }

  /**
   * @notice Adds a new address as a vault
   * @param _vaultHandler address of a contract with permissions to mint and burn tokens
   * @dev Only owner can call it
   */
  function addVaultHandler(address _vaultHandler) external onlyOwner {
    vaultHandlers[_vaultHandler] = true;
    emit VaultHandlerAdded(msg.sender, _vaultHandler);
  }

  /**
   * @notice Removes an address as a vault
   * @param _vaultHandler address of the contract to be removed as vault
   * @dev Only owner can call it
   */
  function removeVaultHandler(address _vaultHandler) external onlyOwner {
    vaultHandlers[_vaultHandler] = false;
    emit VaultHandlerRemoved(msg.sender, _vaultHandler);
  }

  /**
   * @notice Mints TCAP Tokens
   * @param _account address of the receiver of tokens
   * @param _amount uint of tokens to mint
   * @dev Only vault can call it
   */
  function mint(address _account, uint256 _amount) external onlyVault {
    _mint(_account, _amount);
  }

  /**
   * @notice Burns TCAP Tokens
   * @param _account address of the account which is burning tokens.
   * @param _amount uint of tokens to burn
   * @dev Only vault can call it
   */
  function burn(address _account, uint256 _amount) external onlyVault {
    _burn(_account, _amount);
  }

  /**
   * @notice Sets maximum value the total supply of TCAP can have
   * @param _cap value
   * @dev When capEnabled is true, mint is not allowed to issue tokens that would increase the total supply above or equal the specified capacity.
   * @dev Only owner can call it
   */
  function setCap(uint256 _cap) external onlyOwner {
    cap = _cap;
    emit NewCap(msg.sender, _cap);
  }

  /**
   * @notice Enables or Disables the Total Supply Cap.
   * @param _enable value
   * @dev When capEnabled is true, minting will not be allowed above the max capacity. It can exist a supply above the cap, but it prevents minting above the cap.
   * @dev Only owner can call it
   */
  function enableCap(bool _enable) external onlyOwner {
    capEnabled = _enable;
    emit NewCapEnabled(msg.sender, _enable);
  }

  /**
   * @notice ERC165 Standard for support of interfaces
   * @param _interfaceId bytes of interface
   * @return bool
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (_interfaceId == _INTERFACE_ID_TCAP ||
      _interfaceId == _INTERFACE_ID_ERC165);
  }

  /**
   * @notice executes before each token transfer or mint
   * @param _from address
   * @param _to address
   * @param _amount value to transfer
   * @dev See {ERC20-_beforeTokenTransfer}.
   * @dev minted tokens must not cause the total supply to go over the cap.
   * @dev Reverts if the to address is equal to token address
   */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _amount);

    require(
      _to != address(this),
      "TCAP::transfer: can't transfer to TCAP contract"
    );

    if (_from == address(0) && capEnabled) {
      // When minting tokens
      require(
        totalSupply().add(_amount) <= cap,
        "TCAP::Transfer: TCAP cap exceeded"
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";

/**
 * @title Chainlink Oracle
 * @author Cryptex.finance
 * @notice Contract in charge or reading the information from a Chainlink Oracle. TCAP contracts read the price directly from this contract. More information can be found on Chainlink Documentation
 */
contract ChainlinkOracle is Ownable, IERC165 {
  AggregatorV3Interface internal aggregatorContract;

  /*
   * setReferenceContract.selector ^
   * getLatestAnswer.selector ^
   * getLatestTimestamp.selector ^
   * getPreviousAnswer.selector ^
   * getPreviousTimestamp.selector =>  0x85be402b
   */
  bytes4 private constant _INTERFACE_ID_CHAINLINK_ORACLE = 0x85be402b;

  /*
   * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
   */
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  /**
   * @notice Called once the contract is deployed.
   * Set the Chainlink Oracle as an aggregator.
   */
  constructor(address _aggregator) {
    aggregatorContract = AggregatorV3Interface(_aggregator);
  }

  /**
   * @notice Changes the reference contract.
   * @dev Only owner can call it.
   */
  function setReferenceContract(address _aggregator) public onlyOwner() {
    aggregatorContract = AggregatorV3Interface(_aggregator);
  }

  /**
   * @notice Returns the latest answer from the reference contract.
   * @return price
   */
  function getLatestAnswer() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      ,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContract.latestRoundData();
    require(
      timeStamp != 0,
      "ChainlinkOracle::getLatestAnswer: round is not complete"
    );
    require(
      answeredInRound >= roundID,
      "ChainlinkOracle::getLatestAnswer: stale data"
    );
    return price;
  }

  /**
   * @notice Returns the latest round from the reference contract.
   */
  function getLatestRound()
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContract.latestRoundData();

    return (roundID, price, startedAt, timeStamp, answeredInRound);
  }

  /**
   * @notice Returns a given round from the reference contract.
   * @param _id of round
   */
  function getRound(uint80 _id)
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContract.getRoundData(_id);

    return (roundID, price, startedAt, timeStamp, answeredInRound);
  }

  /**
   * @notice Returns the last time the Oracle was updated.
   */
  function getLatestTimestamp() public view returns (uint256) {
    (, , , uint256 timeStamp, ) = aggregatorContract.latestRoundData();
    return timeStamp;
  }

  /**
   * @notice Returns a previous answer updated on the Oracle.
   * @param _id of round
   * @return price
   */
  function getPreviousAnswer(uint80 _id) public view returns (int256) {
    (uint80 roundID, int256 price, , , ) = aggregatorContract.getRoundData(_id);
    require(
      _id <= roundID,
      "ChainlinkOracle::getPreviousAnswer: not enough history"
    );
    return price;
  }

  /**
   * @notice Returns a previous time the Oracle was updated.
   * @param _id of round
   * @return timeStamp
   */
  function getPreviousTimestamp(uint80 _id) public view returns (uint256) {
    (uint80 roundID, , , uint256 timeStamp, ) =
      aggregatorContract.getRoundData(_id);
    require(
      _id <= roundID,
      "ChainlinkOracle::getPreviousTimestamp: not enough history"
    );
    return timeStamp;
  }

  /**
   * @notice ERC165 Standard for support of interfaces.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (interfaceId == _INTERFACE_ID_CHAINLINK_ORACLE ||
      interfaceId == _INTERFACE_ID_ERC165);
  }
}

