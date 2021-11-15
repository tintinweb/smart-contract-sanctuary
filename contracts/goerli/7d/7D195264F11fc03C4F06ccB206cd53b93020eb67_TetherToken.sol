// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../utils/EnumerableSet.sol';
import '../utils/Address.sol';
import '../utils/Context.sol';

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

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

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
  function getRoleMember(bytes32 role, uint256 index)
    public
    view
    returns (address)
  {
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
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to grant'
    );

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
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to revoke'
    );

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
    require(
      account == _msgSender(),
      'AccessControl: can only renounce roles for self'
    );

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

pragma solidity 0.7.6;

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
    mapping(bytes32 => uint256) _indexes;
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

    if (valueIndex != 0) {
      // Equivalent to contains(set, value)
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
  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
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
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
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
  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
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
  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
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
  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
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
  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
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
  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
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
  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity 0.7.6;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  // Default hash for EOA accounts returned by extcodehash
  bytes32 internal constant ACCOUNT_HASH =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly {
      codehash := extcodehash(_address)
    }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`.
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
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);

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

pragma solidity 0.7.6;

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

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 * *
 * This file is derived from OpenZeppelin, available under the MIT
 * license. https://openzeppelin.com/contracts/

 * SPDX-License-Identifier: Apache-2.0 AND MIT
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155Metadata.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155MintBurn.sol';

/**
 * @dev Partial implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155]
 * Multi Token Standard
 *
 * This contract is a replacement for the file ERC1155PresetMinterPauser.sol
 * in the OpenZeppelin project.
 */
contract WOWSMinterPauser is
  Context,
  AccessControl,
  ERC1155MintBurn,
  ERC1155Metadata
{
  //////////////////////////////////////////////////////////////////////////////
  // Roles
  //////////////////////////////////////////////////////////////////////////////

  // Role to mint new tokens
  bytes32 public constant MINTER_ROLE = 'MINTER_ROLE';

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Pause
  bool private _pauseActive;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Event triggered when _pause state changed
  event Pause(bool active);

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  constructor() {}

  //////////////////////////////////////////////////////////////////////////////
  // Pausing interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Pauses all token transfers.
   *
   * Requirements:
   *
   * - The caller must have the `DEFAULT_ADMIN_ROLE`.
   */
  function pause(bool active) public {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');

    if (_pauseActive != active) {
      // Update state
      _pauseActive = active;
      emit Pause(active);
    }
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _pauseActive;
  }

  function _pause(bool active) internal {
    _pauseActive = active;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Minting interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `tokenId`.
   *
   * See {ERC1155-_mint}.
   *
   * Requirements:
   *
   * - The caller must have the `MINTER_ROLE`.
   */
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public virtual {
    // Validate access
    require(hasRole(MINTER_ROLE, _msgSender()), 'Only minter');

    // Validate parameters
    require(to != address(0), "Can't mint to zero address");

    // Update state
    _mint(to, tokenId, amount, data);
  }

  /**
   * @dev Batched variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual {
    // Validate access
    require(hasRole(MINTER_ROLE, _msgSender()), 'Only minter');

    // Validate parameters
    require(to != address(0), "Can't mint to zero address");
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Update state
    _batchMint(to, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Burning interface
  //////////////////////////////////////////////////////////////////////////////

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    // Validate access
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'Caller is not owner nor approved'
    );

    // Update state
    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] calldata ids,
    uint256[] calldata values
  ) public virtual {
    // Validate access
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'Caller is not owner nor approved'
    );

    // Update state
    _batchBurn(account, ids, values);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   *
   * This function is necessary due to diamond inheritance.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    // Validate state
    require(!_pauseActive, 'Transfer operation paused!');

    // Call ancestor
    super._beforeTokenTransfer(operator, from, to, tokenId, amount, data);
  }

  /**
   * @dev See {ERC1155-_beforeBatchTokenTransfer}.
   *
   * This function is necessary due to diamond inheritance.
   */
  function _beforeBatchTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    // Valiate state
    require(!_pauseActive, 'Transfer operation paused!');

    // Call ancestor
    super._beforeBatchTokenTransfer(
      operator,
      from,
      to,
      tokenIds,
      amounts,
      data
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ERC165}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC165-supportsInterface}
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override(ERC1155, ERC1155Metadata)
    returns (bool)
  {
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import '../../interfaces/IERC1155Metadata.sol';
import '../../utils/ERC165.sol';

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is IERC1155Metadata, ERC165 {
  // URI's default URI prefix
  string private _baseMetadataURI;

  // contract metadata URL
  string private _contractMetadataURI;

  // Hex numbers for creating hexadecimal tokenId
  bytes16 private constant HEX_MAP = '0123456789ABCDEF';

  // bytes4(keccak256('contractURI()')) == 0xe8a3d485
  bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   * @return URI string
   */
  function uri(uint256 _id)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return _uri(_id, 0);
  }

  /**
   * @notice Opensea calls this fuction to get information about how to display storefront.
   *
   * @return full URI to the location of the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return _contractMetadataURI;
  }

  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_uri(_tokenIDs[i], 0), _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory newBaseMetadataURI) internal {
    _baseMetadataURI = newBaseMetadataURI;
  }

  /**
   * @notice Will update the contract metadata URI
   * @param newContractMetadataURI New contract metadata URI
   */
  function _setContractMetadataURI(string memory newContractMetadataURI)
    internal
  {
    _contractMetadataURI = newContractMetadataURI;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` or CONTRACT_URI
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (
      _interfaceID == type(IERC1155Metadata).interfaceId ||
      _interfaceID == _INTERFACE_ID_CONTRACT_URI
    ) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  /***********************************|
  |    Utility private Functions     |
  |__________________________________*/

  /**
   * @notice returns uri
   * @param tokenId Unsigned integer to convert to string
   */
  function _uri(uint256 tokenId, uint256 minLength)
    internal
    view
    returns (string memory)
  {
    // Calculate URI
    string memory baseURL = _baseMetadataURI;
    uint256 temp = tokenId;
    uint256 length = tokenId == 0 ? 2 : 0;
    while (temp != 0) {
      length += 2;
      temp >>= 8;
    }
    if (length > minLength) minLength = length;

    bytes memory buffer = new bytes(minLength);
    for (uint256 i = minLength; i > minLength - length; --i) {
      buffer[i - 1] = HEX_MAP[tokenId & 0xf];
      tokenId >>= 4;
    }
    minLength -= length;
    while (minLength > 0) buffer[--minLength] = '0';

    return string(abi.encodePacked(baseURL, buffer, '.json'));
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import './ERC1155.sol';

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal {
    _beforeTokenTransfer(msg.sender, address(0x0), _to, _id, _amount, _data);

    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal {
    require(
      _ids.length == _amounts.length,
      'ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH'
    );

    _beforeBatchTokenTransfer(
      msg.sender,
      address(0x0),
      _to,
      _ids,
      _amounts,
      _data
    );

    // Number of mints to execute
    uint256 nMint = _ids.length;

    // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(
      address(0x0),
      _to,
      _ids,
      _amounts,
      gasleft(),
      _data
    );
  }

  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(
    address _from,
    uint256 _id,
    uint256 _amount
  ) internal {
    _beforeTokenTransfer(msg.sender, _from, address(0x0), _id, _amount, '');

    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(
      nBurn == _amounts.length,
      'ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH'
    );

    _beforeBatchTokenTransfer(
      msg.sender,
      _from,
      address(0x0),
      _ids,
      _amounts,
      ''
    );

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract ERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    returns (bool)
  {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import '../../utils/SafeMath.sol';
import '../../interfaces/IERC1155TokenReceiver.sol';
import '../../interfaces/IERC1155.sol';
import '../../utils/Address.sol';
import '../../utils/ERC165.sol';

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping(address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping(address => mapping(address => bool)) internal operators;

  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) public virtual override {
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      'ERC1155#safeTransferFrom: INVALID_OPERATOR'
    );
    require(_to != address(0), 'ERC1155#safeTransferFrom: INVALID_RECIPIENT');
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) public virtual override {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      'ERC1155#safeBatchTransferFrom: INVALID_OPERATOR'
    );
    require(
      _to != address(0),
      'ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT'
    );

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }

  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    _beforeTokenTransfer(msg.sender, _from, _to, _id, _amount, '');

    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{
        gas: _gasLimit
      }(msg.sender, _from, _id, _amount, _data);
      require(
        retval == ERC1155_RECEIVED_VALUE,
        'ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE'
      );
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    require(
      _ids.length == _amounts.length,
      'ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH'
    );

    _beforeBatchTokenTransfer(msg.sender, _from, _to, _ids, _amounts, '');

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{
        gas: _gasLimit
      }(msg.sender, _from, _ids, _amounts, _data);
      require(
        retval == ERC1155_BATCH_RECEIVED_VALUE,
        'ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE'
      );
    }
  }

  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    public
    virtual
    override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    virtual
    override
    returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }

  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public
    view
    override
    returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public
    view
    override
    returns (uint256[] memory)
  {
    require(
      _owners.length == _ids.length,
      'ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH'
    );

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }

  /***********************************|
  |               HOOKS               |
  |__________________________________*/

  /**
   * @notice overrideable hook for single transfers.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) internal virtual {}

  /**
   * @notice overrideable hook for batch transfers.
   */
  function _beforeBatchTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath#mul: OVERFLOW');

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, 'SafeMath#div: DIVISION_BY_ZERO');
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath#sub: UNDERFLOW');
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath#add: OVERFLOW');

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'SafeMath#mod: DIVISION_BY_ZERO');
    return a % b;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {
  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address _operator,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IERC1155 {
  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice Transfers amount of an _id from the _from address to the _to address specified
   * @dev MUST emit TransferSingle event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev MUST emit TransferBatch event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if length of `_ids` is not the same as length of `_amounts`
   * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';

import './interfaces/IWOWSCryptofolio.sol';
import './interfaces/IWOWSERC1155.sol';
import './WOWSMinterPauser.sol';
import '../utils/TokenIds.sol';

contract WOWSERC1155 is IWOWSERC1155, WOWSMinterPauser {
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // Used to restict calls to TRADEFLOOR but also to collect all TRADEFLOORS
  bytes32 public constant TRADEFLOOR_ROLE = 'TRADEFLOOR_ROLE';

  // Operator role is required to set approval for tokens. This prevents
  // auctions like OpenSea from selling the tokens. Selling by third parties
  // is only allowed for cryptofolios which are locked in one of our TradeFloor
  // contracts.
  bytes32 public constant OPERATOR_ROLE = 'OPERATOR_ROLE';

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Cap per card for each level
  mapping(uint8 => uint16) private _wowsLevelCap;

  // How many cards have been minted
  mapping(uint16 => uint16) private _wowsCardsMinted;

  // Card state of custom NFT's
  struct CustomCard {
    string uri;
    uint8 level;
  }
  mapping(uint256 => CustomCard) private _customCards;
  uint256 private _customCardCount;

  struct ListKey {
    uint256 index;
  }

  // Per-token data
  struct TokenInfo {
    bool minted; // Make sure we only mint 1
    uint64 timestamp;
    ListKey listKey; // Next tokenId in the owner linkedList
  }
  mapping(uint256 => TokenInfo) private _tokenInfos;

  // Mapping tokenId -> generated address
  mapping(uint256 => address) private _tokenIdToAddress;

  // Mapping generated address -> tokenId
  mapping(address => uint256) private _addressToTokenId;

  // Mapping owner -> first owned token
  //
  // Note that we work 1-based here because of initialization
  // e.g. firstId == 1 links to tokenId 0
  struct Owned {
    uint256 count;
    ListKey listKey; // First tokenId in linked list
  }
  mapping(address => Owned) private _owned;

  // Our master cryptofolio used for clones
  address private _cryptofolio;

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev URI is for WOWS predefined NFT's
   *
   * The other token URI's must be set separately.
   */
  constructor(
    address owner,
    address cryptofolio,
    string memory baseMetadataURI,
    string memory contractMetadataURI
  ) {
    // Initialize {AccessControl}
    _setupRole(DEFAULT_ADMIN_ROLE, owner);

    // Setup wows card definition
    _wowsLevelCap[0] = 20;
    _wowsLevelCap[1] = 20;
    _wowsLevelCap[4] = 20;
    _wowsLevelCap[5] = 20;

    // Our clone blueprint cryptofolio.
    _cryptofolio = cryptofolio;

    // Metadata
    _setBaseMetadataURI(baseMetadataURI);
    _setContractMetadataURI(contractMetadataURI);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSERC1155-isTradeFloor}.
   */
  function isTradeFloor(address account) external view override returns (bool) {
    return hasRole(TRADEFLOOR_ROLE, account);
  }

  /**
   * @dev See {IWOWSERC1155-addressToTokenId}.
   */
  function addressToTokenId(address tokenAddress)
    external
    view
    override
    returns (uint256)
  {
    // Load state
    uint256 tokenId = _addressToTokenId[tokenAddress];

    // Error case: token ID isn't known
    if (_tokenIdToAddress[tokenId] != tokenAddress) {
      return uint256(-1);
    }

    // Success
    return tokenId;
  }

  /**
   * @dev See {IWOWSERC1155-tokenIdToAddress}.
   */
  function tokenIdToAddress(uint256 tokenId)
    external
    view
    override
    returns (address)
  {
    // Load state
    return _tokenIdToAddress[tokenId];
  }

  /**
   * @dev See {IWOWSERC1155-getNextMintableTokenId}.
   */
  function getNextMintableTokenId(uint8 level, uint8 cardId)
    external
    view
    override
    returns (bool, uint256)
  {
    // Encode token ID
    uint256 tokenId = _encodeTokenId(level, cardId);

    // Load state
    uint256 tokenIdEnd = tokenId + _wowsLevelCap[level];

    // Search state
    for (; tokenId < tokenIdEnd; ++tokenId) {
      if (!_tokenInfos[tokenId].minted) {
        // Success
        return (true, tokenId);
      }
    }

    // Error case: no free token ID
    return (false, uint256(-1));
  }

  /**
   * @dev See {IWOWSERC1155-getNextMintableCustomToken}.
   */
  function getNextMintableCustomToken()
    external
    view
    override
    returns (uint256)
  {
    // Validate state
    require(_customCardCount + (1 << 32) > _customCardCount, 'math overflow');

    // Encode token ID
    return _customCardCount + (1 << 32);
  }

  /**
   * @dev See {IWOWSERC1155-setBaseMetadataURI}.
   */
  function setBaseMetadataURI(string memory baseMetadataURI) external override {
    // Access control
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Access denied');

    // Set state
    _setBaseMetadataURI(baseMetadataURI);
  }

  /**
   * @dev See {IWOWSERC1155-setContractMetadataURI}.
   */
  function setContractMetadataURI(string memory contractMetadataURI)
    external
    override
  {
    // Access control
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Access denied');

    // Set state
    _setContractMetadataURI(contractMetadataURI);
  }

  /**
   * @dev See {IWOWSERC1155-setCustomURI}.
   */
  function setCustomURI(uint256 tokenId, string memory customURI)
    public
    override
  {
    // Access control
    require(hasRole(MINTER_ROLE, _msgSender()), 'Access denied');

    // Validate parameters
    require(!tokenId.isStockCard(), 'Only custom cards');

    // Update state
    _customCards[tokenId].uri = customURI;
  }

  /**
   * @dev See {IWOWSERC1155-setCustomCardLevel}.
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel)
    public
    override
  {
    // Access control
    require(hasRole(MINTER_ROLE, _msgSender()), 'Only minter');

    // Validate parameter
    require(!tokenId.isStockCard(), 'Only custom cards');

    // Update state
    _customCards[tokenId].level = cardLevel;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    // Prevent auctions like OpenSea from selling this token. Selling by third
    // parties is only allowed for cryptofolios which are locked in one of our
    // TradeFloor contracts.
    require(hasRole(OPERATOR_ROLE, operator), 'Only Operators');

    // Call ancestor
    super.setApprovalForAll(operator, approved);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155MetadataURI}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * For custom tokens the URI is thought to be a full URL without
   * placeholders. For our WOWS token a tokenId placeholder is expected, and
   * the ID is tokenId >> 16 because 16-bit then shares the same
   * metadata / image.
   */
  function uri(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    // Custom token
    if (!tokenId.isStockCard()) {
      if (bytes(_customCards[tokenId].uri).length == 0) {
        return _uri(tokenId, 0);
      } else {
        return _customCards[tokenId].uri;
      }
    }

    // WOWS token
    return _uri(tokenId >> 16, 4);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ERC1155} via {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    // Perform action
    _tokenTransfered(from, to, tokenId, amount);

    // Call ancestor
    super._beforeTokenTransfer(operator, from, to, tokenId, amount, data);
  }

  /**
   * @dev See {ERC1155-_beforeBatchTokenTransfer}.
   */
  function _beforeBatchTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    // Validate parameters
    require(tokenIds.length == amounts.length, 'Length mismatch');

    // Process tokens being transferred
    uint256 length = tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      _tokenTransfered(from, to, tokenIds[i], amounts[i]);
    }

    // Call ancestor
    super._beforeBatchTokenTransfer(
      operator,
      from,
      to,
      tokenIds,
      amounts,
      data
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return information about a WOWS card
   *
   * NOTE: The implementation in the initial deployment was incorrect. If you
   * are interacting with contract 0x64B3342dB643f3Fb4da5781b6D09B44Ab4668dE4,
   * you must use {getCardDataBatch}!
   *
   * @param level The level of the card
   * @param cardId The ID of the card
   *
   * @return cap Max mintable cards
   * @return minted Number of cards that are already minted
   */
  function getCardData(uint8 level, uint8 cardId)
    external
    view
    returns (uint16 cap, uint16 minted)
  {
    // Load state
    return (_wowsLevelCap[level], _getCardsMinted(level, cardId));
  }

  /**
   * @dev Return information about a WOWS card
   *
   * @param levels The levels of the card to query
   * @param cardIds A list of card IDs to query
   *
   * @return capMintedPair Array of 16-bit cap,minted,...
   */
  function getCardDataBatch(uint8[] memory levels, uint8[] memory cardIds)
    external
    view
    returns (uint16[] memory capMintedPair)
  {
    // Validate parameters
    require(levels.length == cardIds.length, 'Length mismatch');

    // Return value
    uint16[] memory result = new uint16[](cardIds.length * 2);

    // Load state
    for (uint256 i = 0; i < cardIds.length; ++i) {
      // Record cap
      result[i * 2] = _wowsLevelCap[levels[i]];

      // Record minted
      result[i * 2 + 1] = _getCardsMinted(levels[i], cardIds[i]);
    }

    return result;
  }

  /**
   * @dev See {IWOWSERC1155-getTokenData}.
   */
  function getTokenData(uint256 tokenId)
    external
    view
    override
    returns (uint64 mintTimestamp, uint8 level)
  {
    // Decode token ID
    uint8 _level = _getLevel(tokenId);

    // Load state
    return (_tokenInfos[tokenId].timestamp, _level);
  }

  /**
   * @dev See {IWOWSERC1155-getTokenIds}.
   */
  function getTokenIds(address account)
    external
    view
    override
    returns (uint256[] memory)
  {
    // Load state
    Owned storage list = _owned[account];

    // Return value
    uint256[] memory result = new uint256[](list.count);

    // Search state
    ListKey storage key = list.listKey;
    for (uint256 i = 0; i < list.count; ++i) {
      result[i] = key.index;
      key = _tokenInfos[key.index].listKey;
    }

    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the cap of a specific WOWS level
   *
   * Note that this function can be used to add a new card.
   */
  function setWowsLevelCaps(uint8[] memory levels, uint16[] memory newCaps)
    public
  {
    // Access control
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');

    // Validate parameters
    require(levels.length == newCaps.length, "Lengths don't match");

    // Update state
    for (uint256 i = 0; i < levels.length; ++i) {
      require(_wowsLevelCap[levels[i]] < newCaps[i], 'Decrement forbidden');
      _wowsLevelCap[levels[i]] = newCaps[i];
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Handles transfer of an SFT token
   */
  function _tokenTransfered(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) private {
    // We have only NFTs in this contract
    require(amount == 1, 'Amount != 1');

    // Load state
    address tokenAddress = _tokenIdToAddress[tokenId];
    TokenInfo storage tokenInfo = _tokenInfos[tokenId];

    // Minting
    if (from == address(0)) {
      // Validate state
      require(!tokenInfo.minted, 'Already minted');

      // Update state
      tokenInfo.minted = true;
      // solhint-disable-next-line not-rely-on-time
      tokenInfo.timestamp = uint64(block.timestamp);
      // Create a new WOWSCryptofolio by cloning masterTokenReceiver
      // The clone itself is a minimal delegate proxy.
      if (tokenAddress == address(0)) {
        tokenAddress = Clones.clone(_cryptofolio);
        _tokenIdToAddress[tokenId] = tokenAddress;
        IWOWSCryptofolio(tokenAddress).initialize();
      }
      _addressToTokenId[tokenAddress] = tokenId;

      // Increment the minted count for this card
      if (tokenId.isBaseCard()) {
        if (tokenId.isStockCard()) {
          _wowsCardsMinted[uint16(tokenId >> 16)] += 1;
        } else {
          ++_customCardCount;
        }
      }
    }
    // Burning
    else if (to == address(0)) {
      // Make sure underlying assets gets burned
      IWOWSCryptofolio(tokenAddress).burn();

      // Make token mintable again
      tokenInfo.minted = false;

      // Decrement the minted count for this card
      if (tokenId.isStockCard()) {
        _wowsCardsMinted[uint16(tokenId >> 16)] -= 1;
      }
    }

    // Signal ownership change in Cryptofolio
    IWOWSCryptofolio(tokenAddress).setOwner(to);

    // Remove tokenId from List
    if (from != address(0)) {
      // Load state
      Owned storage fromList = _owned[from];

      // Validate state
      require(fromList.count > 0, 'Count mismatch');

      ListKey storage key = fromList.listKey;
      uint256 count = fromList.count;

      // Search the token which links to tokenId
      for (; count > 0 && key.index != tokenId; --count)
        key = _tokenInfos[key.index].listKey;
      require(key.index == tokenId, 'Key mismatch');

      // Unlink prev -> tokenId
      key.index = tokenInfo.listKey.index;
      // Unlink tokenId -> next
      tokenInfo.listKey.index = 0;
      // Decrement count
      fromList.count--;
    }

    // Update state
    if (to != address(0)) {
      Owned storage toList = _owned[to];
      tokenInfo.listKey.index = toList.listKey.index;
      toList.listKey.index = tokenId;
      toList.count++;
    }
  }

  /**
   * @dev Utility function to encode a level and card ID into a token ID
   *
   * @param level The level of the card
   * @param cardId The ID of the card
   *
   * @return tokenId The encoded token ID
   */
  function _encodeTokenId(uint8 level, uint8 cardId)
    private
    pure
    returns (uint256 tokenId)
  {
    uint16 levelCard = (uint16(level) << 8) | cardId;
    tokenId = uint32(levelCard) << 16;
  }

  /**
   * @dev Get the number of cards that have been minted
   *
   * @param level The level of cards to check
   * @param cardId The ID of cards to check
   *
   * @return cardsMinted The number of cards that have been minted
   */
  function _getCardsMinted(uint8 level, uint8 cardId)
    private
    view
    returns (uint16 cardsMinted)
  {
    uint16 levelCard = (uint16(level) << 8) | cardId;
    cardsMinted = _wowsCardsMinted[levelCard];
  }

  /**
   * @dev Get the level of a given token
   *
   * @param tokenId The ID of the token
   *
   * @return level The level of the token
   */
  function _getLevel(uint256 tokenId) private view returns (uint8 level) {
    if (!tokenId.isStockCard()) {
      level = _customCards[tokenId].level;
    } else {
      level = uint8(tokenId >> 24);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
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
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 */
interface IWOWSCryptofolio {
  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Initialize the deployed contract after creation
   *
   * This is a one time call which sets _deployer to msg.sender.
   * Subsequent calls reverts.
   */
  function initialize() external;

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return tradefloor at given index
   *
   * @param index The 0-based index in the tradefloor array
   *
   * @return The address of the tradefloor and position index
   */
  function _tradefloors(uint256 index) external view returns (address);

  /**
   * @dev Return array of cryptofolio item token IDs
   *
   * The token IDs belong to the contract TradeFloor.
   *
   * @param tradefloor The TradeFloor that items belong to
   *
   * @return tokenIds The token IDs in scope of operator
   * @return idsLength The number of valid token IDs
   */
  function getCryptofolio(address tradefloor)
    external
    view
    returns (uint256[] memory tokenIds, uint256 idsLength);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the owner of the underlying NFT
   *
   * This function is called if ownership of the parent NFT has changed.
   *
   * The new owner gets allowance to transfer cryptofolio items. The new owner
   * is allowed to transfer / burn cryptofolio items. Make sure that allowance
   * is removed from previous owner.
   *
   * @param owner The new owner of the underlying NFT, or address(0) if the
   * underlying NFT is being burned
   */
  function setOwner(address owner) external;

  /**
   * @dev Allow owner (of parent NFT) to approve external operators to transfer
   * our cryptofolio items
   *
   * The NFT owner is allowed to approve operator to handle cryptofolios.
   *
   * @param operator The operator
   * @param allow True to approve for all NFTs, false to revoke approval
   */
  function setApprovalForAll(address operator, bool allow) external;

  /**
   * @dev Burn all cryptofolio items
   *
   * In case an underlying NFT is burned, we also burn the cryptofolio.
   */
  function burn() external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Check if the specified address is a known tradefloor
   *
   * @param account The address to check
   *
   * @return True if the address is a known tradefloor, false otherwise
   */
  function isTradeFloor(address account) external view returns (bool);

  /**
   * @dev Get the token ID of a given address
   *
   * A cross check is required because token ID 0 is valid.
   *
   * @param tokenAddress The address to convert to a token ID
   *
   * @return The token ID on success, or uint256(-1) if `tokenAddress` does not
   * belong to a token ID
   */
  function addressToTokenId(address tokenAddress)
    external
    view
    returns (uint256);

  /**
   * @dev Get the address for a given token ID
   *
   * @param tokenId The token ID to convert
   *
   * @return The address, or address(0) in case the token ID does not belong
   * to an NFT
   */
  function tokenIdToAddress(uint256 tokenId) external view returns (address);

  /**
   * @dev Get the next mintable token ID for the specified card
   *
   * @param level The level of the card
   * @param cardId The ID of the card
   *
   * @return bool True if a free token ID was found, false otherwise
   * @return uint256 The first free token ID if one was found, or invalid otherwise
   */
  function getNextMintableTokenId(uint8 level, uint8 cardId)
    external
    view
    returns (bool, uint256);

  /**
   * @dev Return the next mintable custom token ID
   */
  function getNextMintableCustomToken() external view returns (uint256);

  /**
   * @dev Return the level and the mint timestamp of tokenId
   *
   * @param tokenId The tokenId to query
   *
   * @return mintTimestamp The timestamp token was minted
   * @return level The level token belongs to
   */
  function getTokenData(uint256 tokenId)
    external
    view
    returns (uint64 mintTimestamp, uint8 level);

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the base URI for either predefined cards or custom cards
   * which don't have it's own URI.
   *
   * The resulting uri is baseUri+[hex(tokenId)] + '.json'. where
   * tokenId will be reduces to upper 16 bit (>> 16) before building the hex string.
   *
   */
  function setBaseMetadataURI(string memory baseContractMetadata) external;

  /**
   * @dev Set the contracts metadata URI
   *
   * @param contractMetadataURI The URI which point to the contract metadata file.
   */
  function setContractMetadataURI(string memory contractMetadataURI) external;

  /**
   * @dev Set the URI for a custom card
   *
   * @param tokenId The token ID whose URI is being set.
   * @param customURI The URI which point to an unique metadata file.
   */
  function setCustomURI(uint256 tokenId, string memory customURI) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library TokenIds {
  // 128 bit underlying hash
  uint256 public constant HASH_MASK = (1 << 128) - 1;

  function isBaseCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 64);
  }

  function isStockCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 32);
  }

  function isCFolioCard(uint256 tokenId) internal pure returns (bool) {
    return
      (tokenId & HASH_MASK) >= (1 << 64) && (tokenId & HASH_MASK) < (1 << 128);
  }

  function toSftTokenId(uint256 tokenId) internal pure returns (uint256) {
    return tokenId & HASH_MASK;
  }

  function maskHash(uint256 tokenId) internal pure returns (uint256) {
    return tokenId & ~HASH_MASK;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';

import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemCallback.sol';
import './WOWSMinterPauser.sol';

abstract contract OpenSeaProxyRegistry {
  mapping(address => address) public proxies;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155]
 * Multi Token Standard, including the Metadata URI extension.
 *
 * This contract is an extension of the minter preset. It accepts the address
 * of the contract minting the token via the ERC-1155 data parameter. When
 * the token is transferred or burned, the minter is notified.
 *
 * Token ID allocation:
 *
 *   - 32Bit Stock Cards
 *   - 32Bit Custom Cards
 *   - Remaining CFolio NFTs
 */
contract TradeFloor is WOWSMinterPauser, ERC1155Holder {
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Roles
  //////////////////////////////////////////////////////////////////////////////

  // Only OPERATORS can approve when trading is restricted
  bytes32 public constant OPERATOR_ROLE = 'OPERATOR_ROLE';

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // solhint-disable-next-line const-name-snakecase
  string public constant name = 'Wolves of Wall Street - C-Folio NFTs';
  // solhint-disable-next-line const-name-snakecase
  string public constant symbol = 'WOWSCFNFT';

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmins() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');
    _;
  }

  modifier notNull(address adr) {
    require(adr != address(0), 'Null address');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Per token information, used to cap NFT's and to allow querying a list
   * of NFT's owned by an address
   */
  struct ListKey {
    uint256 index;
  }

  // Per token information
  struct TokenInfo {
    bool minted; // Make sure we only mint 1
    ListKey listKey; // Next tokenId in the owner linkedList
  }
  mapping(uint256 => TokenInfo) private _tokenInfos;

  // Mapping owner -> first owned token
  //
  // Note that we work 1 based here because of initialization
  // e.g. firstId == 1 links to tokenId 0;
  struct Owned {
    uint256 count;
    ListKey listKey; // First tokenId in linked list
  }
  mapping(address => Owned) private _owned;

  // Our SFT contract, needed to check for locked transfers
  IWOWSERC1155 private immutable _sftHolder;

  // Our CFolioItemBridge contract, needed to get hashed tokenId
  address private immutable _cfiBridge;

  // Restrict approvals to OPERATOR_ROLE members
  bool private _tradingRestricted;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Emitted when the state of restriction has updated
   *
   * @param tradingRestricted True if trading has been restricted, false otherwise
   */
  event RestrictionUpdated(bool tradingRestricted);

  //////////////////////////////////////////////////////////////////////////////
  // OpenSea compatibility
  //////////////////////////////////////////////////////////////////////////////

  // OpenSea per-account proxy registry. Used to whitelist Approvals and save
  // GAS.
  OpenSeaProxyRegistry private immutable _openSeaProxyRegistry;
  address private immutable _deployer;

  // OpenSea events
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  //////////////////////////////////////////////////////////////////////////////
  // Rarible compatibility
  //////////////////////////////////////////////////////////////////////////////

  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  uint256 private _fee;
  address private _feeRecipient;

  // Rarible events
  // solhint-disable-next-line event-name-camelcase
  event CreateERC1155_v1(address indexed creator, string name, string symbol);
  event SecondarySaleFees(
    uint256 tokenId,
    address payable[] recipients,
    uint256[] bps
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Construct the contract
   *
   * @param addressRegistry Registry containing our system addresses
   *
   * Note: Pause operation in this context. Only calls from Proxy allowed.
   */
  constructor(
    IAddressRegistry addressRegistry,
    OpenSeaProxyRegistry openSeaProxyRegistry
  ) {
    // Initialize {AccessControl}
    address marketingWallet = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.MARKETING_WALLET
    );
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);

    // Immutable, visible for all contexts
    _sftHolder = IWOWSERC1155(
      _getAddressRegistryAddress(addressRegistry, AddressBook.SFT_HOLDER)
    );

    // Immutable, visible for all contexts
    _cfiBridge = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.CFOLIOITEM_BRIDGE_PROXY
    );

    // Immutable, visible for all contexts
    _openSeaProxyRegistry = openSeaProxyRegistry;

    // Immutable, visible for all contexts
    _deployer = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.DEPLOYER
    );

    // Pause this instance
    _pause(true);
  }

  /**
   * @dev One time contract initializer
   *
   * @param tokenUriPrefix The ERC-1155 metadata URI Prefix
   * @param contractUri The contract metadata URI
   */
  function initialize(
    IAddressRegistry addressRegistry,
    string memory tokenUriPrefix,
    string memory contractUri
  ) public {
    // Validate state
    require(_feeRecipient == address(0), 'already initialized');

    // Initialize {AccessControl}
    address marketingWallet = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.MARKETING_WALLET
    );
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);

    // Initialize {ERC1155Metadata}
    _setBaseMetadataURI(tokenUriPrefix);
    _setContractMetadataURI(contractUri);

    _feeRecipient = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.REWARD_HANDLER
    );
    _fee = 1000; // 10%

    // This event initializes Rarible storefront
    emit CreateERC1155_v1(_deployer, name, symbol);

    // OpenSea enable storefront editing
    emit OwnershipTransferred(address(0), _deployer);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return list of tokenIds owned by `account`
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory)
  {
    Owned storage list = _owned[account];
    uint256[] memory result = new uint256[](list.count);
    ListKey storage key = list.listKey;
    for (uint256 i = 0; i < list.count; ++i) {
      result[i] = key.index;
      key = _tokenInfos[key.index].listKey;
    }
    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155} via {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override notNull(from) notNull(to) {
    // Call parent
    super.safeTransferFrom(from, to, tokenId, amount, data);

    uint256[] memory tokenIds = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    tokenIds[0] = tokenId;
    amounts[0] = amount;

    _onTransfer(from, to, tokenIds);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override notNull(from) notNull(to) {
    // Validate parameters
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Call parent
    super.safeBatchTransferFrom(from, to, tokenIds, amounts, data);

    _onTransfer(from, to, tokenIds);
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   *
   * Override setApprovalForAll to be able to restrict to known operators.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    // Validate access
    require(
      !_tradingRestricted || hasRole(OPERATOR_ROLE, operator),
      'forbidden'
    );

    // Call ancestor
    super.setApprovalForAll(operator, approved);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(address account, address operator)
    public
    view
    override
    returns (bool)
  {
    if (!_tradingRestricted && address(_openSeaProxyRegistry) != address(0)) {
      // Whitelist OpenSea proxy contract for easy trading.
      OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
        _openSeaProxyRegistry
      );
      if (proxyRegistry.proxies(account) == operator) {
        return true;
      }
    }

    // Call ancestor
    return super.isApprovedForAll(account, operator);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155MetadataURI} via {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * Revert for unminted SFT NFTs.
   */
  function uri(uint256 tokenId) public view override returns (string memory) {
    // Validate state
    require(_tokenInfos[tokenId].minted, 'Not minted');
    // Load state
    return _uri(tokenId, 0);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155MintBurn-_burn}.
   */
  function burn(
    address account,
    uint256 tokenId,
    uint256 amount
  ) public override notNull(account) {
    // Call ancestor
    super.burn(account, tokenId, amount);

    // Perform internal handling
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    _onTransfer(account, address(0), tokenIds);
  }

  /**
   * @dev See {ERC1155MintBurn-_batchBurn}.
   */
  function burnBatch(
    address account,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) public virtual override notNull(account) {
    // Validate parameters
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Call ancestor
    super.burnBatch(account, tokenIds, amounts);

    // Perform internal handling
    _onTransfer(account, address(0), tokenIds);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155TokenReceiver} via {ERC1155Holder}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155Received}
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(from, tokenIds, amounts, data);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    _onTokensReceived(from, tokenIds, amounts, data);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Administrative functions
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155Metadata-setBaseMetadataURI}.
   */
  function setBaseMetadataURI(string memory baseMetadataURI)
    external
    onlyAdmins
  {
    // Set state
    _setBaseMetadataURI(baseMetadataURI);
  }

  /**
   * @dev Set contract metadata URI
   */
  function setContractMetadataURI(string memory newContractUri)
    public
    onlyAdmins
  {
    _setContractMetadataURI(newContractUri);
  }

  /**
   * @dev Register interfaces
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override(WOWSMinterPauser, ERC1155Holder)
    returns (bool)
  {
    // Register rarible fee interface
    if (_interfaceID == _INTERFACE_ID_FEES) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  /**
   * @dev Withdraw tokenAddress ERC20token to destination
   *
   * A future improvement would be to swap the token into WOWS.
   *
   * @param tokenAddress the address of the token to transfer. Cannot be
   * rewardToken.
   */
  function collectGarbage(address tokenAddress) external onlyAdmins {
    // Transfer token to msg.sender
    uint256 amountToken = IERC20(tokenAddress).balanceOf(address(this));
    if (amountToken > 0)
      IERC20(tokenAddress).transfer(_msgSender(), amountToken);
  }

  /**
   * @dev Restrict trading to OPERATOR_ROLE (see setApprovalForAll)
   */
  function restrictTrading(bool restrict) external onlyAdmins {
    // Update state
    _tradingRestricted = restrict;

    // Dispatch event
    emit RestrictionUpdated(restrict);
  }

  /**
   * @dev Move all TF CFolioItems inside CFolios to CFolioItemBridge
   */
  function migrate(uint256[] calldata tokenIds) external onlyAdmins {
    uint256 length = tokenIds.length;
    uint256[] memory cfiTokenIds;
    uint256 cfiLength;
    address cfolio;

    for (uint256 i = 0; i < length; ++i) {
      if (tokenIds[i].isBaseCard()) {
        cfolio = _sftHolder.tokenIdToAddress(tokenIds[i]);
        require(cfolio != address(0), 'Invalid');
        (cfiTokenIds, cfiLength) = IWOWSCryptofolio(cfolio).getCryptofolio(
          address(this)
        );
        for (uint256 j = 0; j < cfiLength; ++j) {
          // Burn CFI (which transfers sft)
          _burn(cfolio, cfiTokenIds[j], 1);
          _relinkOwner(cfolio, address(0), cfiTokenIds[j], uint256(-1));

          // Transfer the SFT cFolio (currently owned by us) to cfiBridge
          WOWSMinterPauser(address(_sftHolder)).safeTransferFrom(
            address(this),
            _cfiBridge,
            cfiTokenIds[j].toSftTokenId(),
            1,
            abi.encodePacked(cfolio)
          );
        }
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // OpenSea compatibility
  //////////////////////////////////////////////////////////////////////////////

  function isOwner() external view returns (bool) {
    return _msgSender() == owner();
  }

  function owner() public view returns (address) {
    return _deployer;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Rarible fees and events
  //////////////////////////////////////////////////////////////////////////////

  function setFee(uint256 fee) external onlyAdmins {
    // Update state
    _fee = fee;
  }

  function setFeeRecipient(address feeRecipient) external onlyAdmins {
    // Update state
    _feeRecipient = feeRecipient;
  }

  function getFeeRecipients(uint256)
    public
    view
    returns (address payable[] memory)
  {
    // Return value
    address payable[] memory recipients = new address payable[](1);

    // Load state
    recipients[0] = payable(_feeRecipient);
    return recipients;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    // Return value
    uint256[] memory bps = new uint256[](1);

    // Load state
    bps[0] = _fee;

    return bps;
  }

  function logURI(uint256 tokenId) external {
    emit URI(uri(tokenId), tokenId);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  function _onTransfer(
    address from,
    address to,
    uint256[] memory tokenIds
  ) private {
    // Before all NFTs are migrated, users could have cfolioItems from this
    // contract in cfolio. Because burning is not recorded in cfih's anymore,
    // we have to disallow it. Next line can be removed after migration.
    require(
      from == address(0) || _sftHolder.addressToTokenId(from) == uint256(-1),
      'TF: Forbidden'
    );

    // Count SFT tokenIds
    uint256 length = tokenIds.length;
    // Relink owner
    for (uint256 i = 0; i < length; ++i) {
      _relinkOwner(from, to, tokenIds[i], uint256(-1));
    }

    // On Burn we need to transfer SFT ownership back
    if (to == address(0)) {
      uint256[] memory sftTokenIds = new uint256[](length);
      uint256[] memory amounts = new uint256[](length);
      for (uint256 i = 0; i < length; ++i) {
        uint256 tokenId = tokenIds[i];
        sftTokenIds[i] = tokenId.toSftTokenId();
        amounts[i] = 1;
      }

      WOWSMinterPauser(address(_sftHolder)).safeBatchTransferFrom(
        address(this),
        _msgSender(),
        sftTokenIds,
        amounts,
        ''
      );
    }
  }

  /**
   * @dev SFT token arrived, provide an NFT
   */
  function _onTokensReceived(
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    // We only support tokens from our SFT Holder contract
    require(_msgSender() == address(_sftHolder), 'TF: Invalid sender');

    // Validate parameters
    require(tokenIds.length == amounts.length, 'TF: Lengths mismatch');

    // To save gas we allow minting directly into a given recipient
    address sftRecipient;
    if (data.length == 20) {
      sftRecipient = _getAddress(data);
      require(sftRecipient != address(0), 'TF: invalid recipient');
    } else sftRecipient = from;

    // Update state
    uint256[] memory mintedTokenIds = new uint256[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] == 1, 'Amount != 1 not allowed');

      uint256 mintedTokenId = _hashedTokenId(tokenIds[i]);
      mintedTokenIds[i] = mintedTokenId;

      // OpenSea only listens to TransferSingle event on mint
      _mintAndEmit(sftRecipient, mintedTokenId);
    }
    _onTransfer(address(0), sftRecipient, mintedTokenIds);
  }

  /**
   * @dev Ownership change -> update linked list owner -> tokenId
   *
   * If tokenIdNew is != uint256(-1) this function executes an
   * ownership transfer of "from" from tokenId to tokenIdNew
   * In this case "to" must be set to 0.
   */
  function _relinkOwner(
    address from,
    address to,
    uint256 tokenId,
    uint256 tokenIdNew
  ) internal {
    // Load state
    TokenInfo storage tokenInfo = _tokenInfos[tokenId];

    // Remove tokenId from List
    if (from != address(0)) {
      // Load state
      Owned storage fromList = _owned[from];

      // Validate state
      require(fromList.count > 0, 'Count mismatch');

      ListKey storage key = fromList.listKey;
      uint256 count = fromList.count;

      // Search the token which links to tokenId
      for (; count > 0 && key.index != tokenId; --count)
        key = _tokenInfos[key.index].listKey;
      require(key.index == tokenId, 'Key mismatch');

      if (tokenIdNew == uint256(-1)) {
        // Unlink prev -> tokenId
        key.index = tokenInfo.listKey.index;
        // Decrement count
        fromList.count--;
      } else {
        // replace tokenId -> tokenIdNew
        key.index = tokenIdNew;
        TokenInfo storage tokenInfoNew = _tokenInfos[tokenIdNew];
        require(!tokenInfoNew.minted, 'Must not be minted');
        tokenInfoNew.listKey.index = tokenInfo.listKey.index;
        tokenInfoNew.minted = true;
      }
      // Unlink tokenId -> next
      tokenInfo.listKey.index = 0;
      require(tokenInfo.minted, 'Must be minted');
      tokenInfo.minted = false;
    }

    // Update state
    if (to != address(0)) {
      Owned storage toList = _owned[to];
      tokenInfo.listKey.index = toList.listKey.index;
      require(!tokenInfo.minted, 'Must not be minted');
      tokenInfo.minted = true;
      toList.listKey.index = tokenId;
      toList.count++;
    }
  }

  /**
   * @dev Get the address from the user data parameter
   *
   * @param data Per ERC-1155, the data parameter is additional data with no
   * specified format, and is sent unaltered in the call to
   * {IERC1155Receiver-onERC1155Received} on the receiver of the minted token.
   */
  function _getAddress(bytes memory data) public pure returns (address addr) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      addr := mload(add(data, 20))
    }
  }

  /**
   * @dev Save contract size by wrappng external call into an internal
   */
  function _getAddressRegistryAddress(IAddressRegistry reg, bytes32 data)
    private
    view
    returns (address)
  {
    return reg.getRegistryEntry(data);
  }

  /**
   * @dev Save contract size by wrappng external call into an internal
   */
  function _addressToTokenId(address tokenAddress)
    private
    view
    returns (uint256)
  {
    return _sftHolder.addressToTokenId(tokenAddress);
  }

  /**
   * @dev internal mint + event emiting
   */
  function _mintAndEmit(address recipient, uint256 tokenId) private {
    _mint(recipient, tokenId, 1, '');

    // Rarible needs to be informed about fees
    emit SecondarySaleFees(tokenId, getFeeRecipients(0), getFeeBps(0));
  }

  /**
   * @dev Calculate a 128-bit hash for making tokenIds unique to underlying asset
   *
   * @param sftTokenId The tokenId from SFT contract from that we use the first 128 bit
   * TokenIds in SFT contract are limited to max 128 Bit in WowsSftMinter contract.
   */
  function _hashedTokenId(uint256 sftTokenId) private view returns (uint256) {
    bytes memory hashData;
    uint256[] memory tokenIds;
    uint256 tokenIdsLength;
    if (sftTokenId.isBaseCard()) {
      // It's a base card, calculate hash using all cfolioItems
      address cfolio = _sftHolder.tokenIdToAddress(sftTokenId);
      require(cfolio != address(0), 'TF: src token invalid');
      (tokenIds, tokenIdsLength) = IWOWSCryptofolio(cfolio).getCryptofolio(
        _cfiBridge
      );
      hashData = abi.encodePacked(address(this), sftTokenId);
    } else {
      // It's a cfolioItem itself, only calculate underlying value
      tokenIds = new uint256[](1);
      tokenIds[0] = sftTokenId;
      tokenIdsLength = 1;
    }

    // Run through all cfolioItems and let their single CFolioItemHandler
    // append hashable data
    for (uint256 i = 0; i < tokenIdsLength; ++i) {
      address cfolio = _sftHolder.tokenIdToAddress(tokenIds[i].toSftTokenId());
      require(cfolio != address(0), 'TF: item token invalid');

      address handler = IWOWSCryptofolio(cfolio)._tradefloors(0);
      require(handler != address(0), 'TF: item handler invalid');

      hashData = ICFolioItemCallback(handler).appendHash(cfolio, hashData);
    }

    uint256 hashNum = uint256(keccak256(hashData));
    return (hashNum ^ (hashNum << 128)).maskHash() | sftTokenId;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../../interfaces/IERC1155TokenReceiver.sol';
import '../../utils/ERC165.sol';

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC165, IERC1155TokenReceiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (_interfaceID == type(IERC1155TokenReceiver).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library AddressBook {
  bytes32 public constant DEPLOYER = 'DEPLOYER';
  bytes32 public constant TEAM_WALLET = 'TEAM_WALLET';
  bytes32 public constant MARKETING_WALLET = 'MARKETING_WALLET';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
  bytes32 public constant WOWS_TOKEN = 'WOWS_TOKEN';
  bytes32 public constant UNISWAP_V2_PAIR = 'UNISWAP_V2_PAIR';
  bytes32 public constant WOWS_BOOSTER_PROXY = 'WOWS_BOOSTER_PROXY';
  bytes32 public constant REWARD_HANDLER = 'REWARD_HANDLER';
  bytes32 public constant SFT_MINTER = 'SFT_MINTER';
  bytes32 public constant SFT_HOLDER = 'SFT_HOLDER';
  bytes32 public constant CFOLIOITEM_BRIDGE_PROXY = 'CFOLIOITEM_BRIDGE_PROXY';
  bytes32 public constant BOIS_REWARDS = 'BOIS_REWARDS';
  bytes32 public constant WOLVES_REWARDS = 'WOLVES_REWARDS';
  bytes32 public constant SFT_EVALUATOR_PROXY = 'SFT_EVALUATOR_PROXY';
  bytes32 public constant TRADE_FLOOR_PROXY = 'TRADE_FLOOR_PROXY';
  bytes32 public constant CURVE_Y_TOKEN = 'CURVE_Y_TOKEN';
  bytes32 public constant CURVE_Y_DEPOSIT = 'CURVE_Y_DEPOSIT';
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get a registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to receive callbacks when minted tokens are burnt
 */
interface ICFolioItemCallback {
  /**
   * @dev Called when a TradeFloor CFolioItem is transfered
   *
   * In case of mint `from` is address(0).
   * In case of burn `to` is address(0).
   *
   * cfolioHandlers are passed to let each cfolioHandler filter for its own
   * token. This eliminates the need for creating separate lists.
   *
   * @param from The account sending the token
   * @param to The account receiving the token
   * @param tokenIds The ERC-1155 token IDs
   * @param cfolioHandlers cFolioItem handlers
   */
  function onCFolioItemsTransferedFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    address[] calldata cfolioHandlers
  ) external;

  /**
   * @dev Append data we use later for hashing
   *
   * @param cfolioItem The token ID of the c-folio item
   * @param current The current data being hashes
   *
   * @return The current data, with internal data appended
   */
  function appendHash(address cfolioItem, bytes calldata current)
    external
    view
    returns (bytes memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../token/interfaces/ICFolioItemCallback.sol';

/**
 * @dev Interface to C-folio item contracts
 */
interface ICFolioItemHandler is ICFolioItemCallback {
  /**
   * @dev Called when a SFT tokens grade needs re-evaluation
   *
   * @param tokenId The ERC-1155 token ID. Rate is in 1E6 convention: 1E6 = 100%
   * @param newRate The new value rate
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external;

  /**
   * @dev Called from SFTMinter after an Investment SFT is minted
   *
   * @param payer The approved address to get investment from
   * @param sftTokenId The sftTokenId whose c-folio is the owner of investment
   * @param amounts The amounts of invested assets
   */
  function setupCFolio(
    address payer,
    uint256 sftTokenId,
    uint256[] calldata amounts
  ) external;

  //////////////////////////////////////////////////////////////////////////////
  // Asset access
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Adds investments into a cFolioItem SFT
   *
   * Transfers amounts of assets from users wallet to the contract. In general,
   * an Approval call is required before the function is called.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function deposit(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Removes investments from a cFolioItem SFT
   *
   * Withdrawn token are transfered back to msg.sender.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Updates the Farm rewards
   *
   * This function iterates through all CFI's and evaluates
   * the farm share depending parameters like prowess.
   *
   * @param tokenId Base CFolio tokenId to update
   */
  function updateRewards(uint256 tokenId) external;

  /**
   * @dev Get the rewards collected by an SFT base card
   *
   * Calls only allowed from sftMinter.
   *
   * @param owner The owner of the NFT token
   * @param recipient Recipient of the rewards (- fees)
   * @param tokenId SFT base card tokenId, must be unlocked
   */
  function getRewards(
    address owner,
    address recipient,
    uint256 tokenId
  ) external;

  /**
   * @dev Get amounts (handler specific) for a cfolioItem
   *
   * @param cfolioItem address of CFolioItem contract
   */
  function getAmounts(address cfolioItem)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Get information obout the rewardFarm
   *
   * @param tokenIds List of basecard tokenIds
   * @return bytes of uint256[]: total, rewardDur, rewardRateForDur, [share, earned]
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory);

  /**
   * @dev Add virtual assets from sideChain into the rewardPool
   *
   * Assets are added if an cfolioItem is transfered from sideChain
   * to this chain. The slotId is fetched from registered side chains
   * using msg.sender
   *
   * @param cFolioItem The item which has arrived
   * @param amount The amount of tokens which arrived
   */
  function addAssets(
    address cFolioItem,
    uint256 sideChainSlotId,
    uint256 amount
  ) external;

  /**
   * @dev Remove virtual assets from sideChain from the rewardPool
   *
   * Assets are removed if an cfolioItem is transfered from this root chain
   * to a sideChain. The slotId is fetched from registered side chains
   * using msg.sender
   *
   * @param cFolioItem The item which will be bridged to sideChain
   */
  function removeAssets(address cFolioItem, uint256 sideChainSlotId)
    external
    returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC1155 } from '../../0xerc1155/interfaces/IERC1155.sol';
import { ERC1155Holder } from '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import { SafeMath } from '../../0xerc1155/utils/SafeMath.sol';
import { FxBaseRootTunnel } from '../../polygonFx/tunnel/FxBaseRootTunnel.sol';

import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../cfolio/interfaces/ISFTEvaluator.sol';
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/TokenIds.sol';

contract WowsERC1155RootTunnel is FxBaseRootTunnel, ERC1155Holder {
  using TokenIds for uint256;
  using SafeMath for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 private constant DEPOSIT = keccak256('DEPOSIT');
  bytes32 private constant DEPOSIT_BATCH = keccak256('DEPOSIT_BATCH');
  bytes32 private constant WITHDRAW = keccak256('WITHDRAW');
  bytes32 private constant WITHDRAW_BATCH = keccak256('WITHDRAW_BATCH');
  bytes32 private constant MAP_TOKEN = keccak256('MAP_TOKEN');

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  IERC1155 private immutable rootToken_;
  address private immutable childToken_;

  IWOWSERC1155 private immutable sftContract_;
  address private immutable cfiBridge_;
  ISFTEvaluator private immutable sftEvaluator_;

  //////////////////////////////////////////////////////////////////////////////
  // state
  //////////////////////////////////////////////////////////////////////////////

  bool public mapped;

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    address _checkpointManager,
    address _fxRoot,
    address _rootToken,
    address _childToken,
    address _sftContract,
    address _cfiBridge,
    address _sftEvaluator
  ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
    require(_rootToken != address(0), 'RT: Invalid root');
    require(_childToken != address(0), 'RT: Invalid child');
    require(_cfiBridge != address(0), 'RT: Invalid cfib');

    rootToken_ = IERC1155(_rootToken);
    childToken_ = _childToken;

    sftContract_ = IWOWSERC1155(_sftContract);
    cfiBridge_ = _cfiBridge;
    sftEvaluator_ = ISFTEvaluator(_sftEvaluator);
  }

  function initialize() external {
    require(!mapped, 'RT: Already mapped');
    mapped = true;

    bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken_));
    _sendMessageToChild(message);
  }

  function deposit(
    address user,
    uint256 tokenId,
    uint256 amount
  ) public {
    // transfer from depositor to this contract
    rootToken_.safeTransferFrom(
      msg.sender, // depositor
      address(this), // manager contract
      tokenId,
      amount,
      ''
    );

    bytes memory data = _getCFolio('', tokenId);

    // DEPOSIT, encode(rootToken, depositor, user, id, amount, extra data)
    bytes memory message = abi.encode(
      DEPOSIT,
      abi.encode(address(rootToken_), msg.sender, user, tokenId, amount, data)
    );
    _sendMessageToChild(message);
  }

  function depositBatch(
    address user,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) public {
    // transfer from depositor to this contract
    rootToken_.safeBatchTransferFrom(
      msg.sender, // depositor
      address(this), // manager contract
      tokenIds,
      amounts,
      ''
    );

    bytes memory data;
    for (uint256 i = 0; i < tokenIds.length; ++i)
      data = _getCFolio(data, tokenIds[i]);

    // DEPOSIT_BATCH, encode(rootToken, depositor, user, id, amount, extra data)
    bytes memory message = abi.encode(
      DEPOSIT_BATCH,
      abi.encode(address(rootToken_), msg.sender, user, tokenIds, amounts, data)
    );
    _sendMessageToChild(message);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal
  //////////////////////////////////////////////////////////////////////////////

  function _processMessageFromChild(bytes memory data) internal override {
    (bytes32 syncType, bytes memory syncData) = abi.decode(
      data,
      (bytes32, bytes)
    );

    if (syncType == WITHDRAW) {
      _syncWithdraw(syncData);
    } else if (syncType == WITHDRAW_BATCH) {
      _syncBatchWithdraw(syncData);
    } else {
      revert('RT: Invalid sync type');
    }
  }

  function _syncWithdraw(bytes memory syncData) internal {
    (
      address rootToken,
      address childToken,
      address user,
      uint256 id,
      uint256 amount,
      bytes memory data
    ) = abi.decode(
        syncData,
        (address, address, address, uint256, uint256, bytes)
      );
    require(rootToken == address(rootToken_), 'RT: Invalid root');
    require(childToken == childToken_, 'RT: Invalid child');

    rootToken_.safeTransferFrom(address(this), user, id, amount, data);
  }

  function _syncBatchWithdraw(bytes memory syncData) internal {
    (
      address rootToken,
      address childToken,
      address user,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
    ) = abi.decode(
        syncData,
        (address, address, address, uint256[], uint256[], bytes)
      );
    require(rootToken == address(rootToken_), 'RT: Invalid root');
    require(childToken == childToken_, 'RT: Invalid child');

    rootToken_.safeBatchTransferFrom(address(this), user, ids, amounts, data);
  }

  function _getCFolio(bytes memory data, uint256 tokenId)
    private
    returns (bytes memory)
  {
    // Collect changed CFIH's
    address[] memory updateHandler = new address[](1);

    if (tokenId.isBaseCard()) {
      address cfolio = sftContract_.tokenIdToAddress(tokenId);
      require(cfolio != address(0), 'RT: Invalid cfolio');

      (uint256[] memory items, uint256 itemsLength) = IWOWSCryptofolio(cfolio)
        .getCryptofolio(cfiBridge_);
      bytes memory result = abi.encodePacked(itemsLength);
      // Loop over cfolioItems, remove share, and add them for transfer
      for (uint256 i = 0; i < itemsLength; ++i) {
        result = abi.encodePacked(
          result,
          items[i],
          sftEvaluator_.getCFolioItemType(items[i]),
          _removeAsset(items[i], updateHandler)
        );
      }
      // Update farms after asset adding
      for (
        uint256 i = 0;
        i < updateHandler.length && updateHandler[i] != address(0);
        ++i
      ) ICFolioItemHandler(updateHandler[i]).updateRewards(tokenId);
      return abi.encodePacked(data, result);
    } else {
      return
        abi.encodePacked(
          data,
          sftEvaluator_.getCFolioItemType(tokenId),
          _removeAsset(tokenId, updateHandler)
        );
    }
  }

  function _removeAsset(uint256 tokenId, address[] memory updateHandler)
    private
    returns (uint256)
  {
    address cfolioItem = sftContract_.tokenIdToAddress(tokenId);
    require(cfolioItem != address(0), 'RT: Invalid cfolioItem');
    address handler = IWOWSCryptofolio(cfolioItem)._tradefloors(0);

    uint256 amount = ICFolioItemHandler(handler).removeAssets(cfolioItem, 0);
    if (amount > 0) {
      // Currently only one CFIH supported
      if (updateHandler[0] == address(0)) updateHandler[0] = handler;
      else require(updateHandler[0] == handler, 'RT: Only 1 handler');
    }
    return amount;
  }

  function _parseAmounts(
    bytes memory data,
    uint256 tokenId,
    uint256 start
  ) private returns (uint256) {
    // Collect changed CFIH's
    address[] memory updateHandler = new address[](1);

    if (tokenId.isBaseCard()) {
      // Num | [TokenId | Amount]
      uint256 incomingSum;
      uint256 expectedSum;

      address cfolio = sftContract_.tokenIdToAddress(tokenId);
      require(cfolio != address(0), 'RT: Invalid cfolio');

      (uint256[] memory items, uint256 itemCount) = IWOWSCryptofolio(cfolio)
        .getCryptofolio(cfiBridge_);

      uint256 incomingItemCount = _getUint256(data, start++);
      require(itemCount == incomingItemCount, 'RT: Wrong cfi count');
      require(data.length / 32 >= start + 2 * itemCount, 'RT: data wrong');

      // Iterate through cfi's and add asset into CFIH
      // Also sum tokenIds up for a final verification step
      for (uint256 i = 0; i < incomingItemCount; ++i) {
        uint256 itemTokenId = _getUint256(data, start++);
        uint256 amount = _getUint256(data, start++);
        incomingSum = incomingSum.add(itemTokenId);
        expectedSum = expectedSum.add(items[i]);
        _addAsset(itemTokenId, amount, updateHandler);
      }
      // Verify that tokenId sums are equal
      require(incomingSum == expectedSum, 'RT: Verification failed');
      // Update farms after asset adding
      for (
        uint256 i = 0;
        i < updateHandler.length && updateHandler[i] != address(0);
        ++i
      ) ICFolioItemHandler(updateHandler[i]).updateRewards(tokenId);
    } else {
      // Amount
      require(data.length / 32 > start, 'RT: data wrong');
      _addAsset(tokenId, _getUint256(data, start++), updateHandler);
    }
    return start;
  }

  function _addAsset(
    uint256 tokenId,
    uint256 amount,
    address[] memory updateHandler
  ) private {
    if (amount > 0) {
      address cfolioItem = sftContract_.tokenIdToAddress(tokenId);
      require(cfolioItem != address(0), 'RT: Invalid cfolioItem');
      address handler = IWOWSCryptofolio(cfolioItem)._tradefloors(0);

      ICFolioItemHandler(handler).addAssets(cfolioItem, 0, amount);
      // Currently only one CFIH supported
      if (updateHandler[0] == address(0)) updateHandler[0] = handler;
      else require(updateHandler[0] == handler, 'RT: Only 1 handler');
    }
  }

  function _getUint256(bytes memory bs, uint256 start)
    internal
    pure
    returns (uint256)
  {
    uint256 ret;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      ret := mload(add(bs, add(0x20, mul(start, 0x20))))
    }
    return ret;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { RLPReader } from '../lib/RLPReader.sol';
import { MerklePatriciaProof } from '../lib/MerklePatriciaProof.sol';
import { Merkle } from '../lib/Merkle.sol';

interface IFxStateSender {
  function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
  struct HeaderBlock {
    bytes32 root;
    uint256 start;
    uint256 end;
    uint256 createdAt;
    address proposer;
  }

  /**
   * @notice mapping of checkpoint header numbers to block details
   * @dev These checkpoints are submited by plasma contracts
   */
  mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;
  using Merkle for bytes32;

  // keccak256(MessageSent(bytes))
  bytes32 public constant SEND_MESSAGE_EVENT_SIG =
    0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

  // state sender contract
  IFxStateSender public fxRoot;
  // root chain manager
  ICheckpointManager public checkpointManager;
  // child tunnel contract which receives and sends messages
  address public fxChildTunnel;

  // storage to avoid duplicate exits
  mapping(bytes32 => bool) public processedExits;

  constructor(address _checkpointManager, address _fxRoot) {
    checkpointManager = ICheckpointManager(_checkpointManager);
    fxRoot = IFxStateSender(_fxRoot);
  }

  // set fxChildTunnel if not set already
  function setFxChildTunnel(address _fxChildTunnel) public {
    require(
      fxChildTunnel == address(0x0),
      'FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET'
    );
    fxChildTunnel = _fxChildTunnel;
  }

  /**
   * @notice Send bytes message to Child Tunnel
   * @param message bytes message that will be sent to Child Tunnel
   * some message examples -
   *   abi.encode(tokenId);
   *   abi.encode(tokenId, tokenMetadata);
   *   abi.encode(messageType, messageData);
   */
  function _sendMessageToChild(bytes memory message) internal {
    fxRoot.sendMessageToChild(fxChildTunnel, message);
  }

  function _validateAndExtractMessage(bytes memory inputData)
    internal
    returns (bytes memory)
  {
    RLPReader.RLPItem[] memory inputDataRLPList = inputData
      .toRlpItem()
      .toList();

    // checking if exit has already been processed
    // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
    bytes32 exitHash = keccak256(
      abi.encodePacked(
        inputDataRLPList[2].toUint(), // blockNumber
        // first 2 nibbles are dropped while generating nibble array
        // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
        // so converting to nibble array and then hashing it
        MerklePatriciaProof._getNibbleArray(inputDataRLPList[8].toBytes()), // branchMask
        inputDataRLPList[9].toUint() // receiptLogIndex
      )
    );
    require(
      processedExits[exitHash] == false,
      'FxRootTunnel: EXIT_ALREADY_PROCESSED'
    );
    processedExits[exitHash] = true;

    RLPReader.RLPItem[] memory receiptRLPList = inputDataRLPList[6]
      .toBytes()
      .toRlpItem()
      .toList();
    RLPReader.RLPItem memory logRLP = receiptRLPList[3].toList()[
      inputDataRLPList[9].toUint() // receiptLogIndex
    ];

    RLPReader.RLPItem[] memory logRLPList = logRLP.toList();

    // check child tunnel
    require(
      fxChildTunnel == RLPReader.toAddress(logRLPList[0]),
      'FxRootTunnel: INVALID_FX_CHILD_TUNNEL'
    );

    // verify receipt inclusion
    require(
      MerklePatriciaProof.verify(
        inputDataRLPList[6].toBytes(), // receipt
        inputDataRLPList[8].toBytes(), // branchMask
        inputDataRLPList[7].toBytes(), // receiptProof
        bytes32(inputDataRLPList[5].toUint()) // receiptRoot
      ),
      'FxRootTunnel: INVALID_RECEIPT_PROOF'
    );

    // verify checkpoint inclusion
    _checkBlockMembershipInCheckpoint(
      inputDataRLPList[2].toUint(), // blockNumber
      inputDataRLPList[3].toUint(), // blockTime
      bytes32(inputDataRLPList[4].toUint()), // txRoot
      bytes32(inputDataRLPList[5].toUint()), // receiptRoot
      inputDataRLPList[0].toUint(), // headerNumber
      inputDataRLPList[1].toBytes() // blockProof
    );

    RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

    require(
      bytes32(logTopicRLPList[0].toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
      'FxRootTunnel: INVALID_SIGNATURE'
    );

    // received message data
    bytes memory receivedData = logRLPList[2].toBytes();
    bytes memory message = abi.decode(receivedData, (bytes)); // event decodes params again, so decoding bytes to get message
    return message;
  }

  function _checkBlockMembershipInCheckpoint(
    uint256 blockNumber,
    uint256 blockTime,
    bytes32 txRoot,
    bytes32 receiptRoot,
    uint256 headerNumber,
    bytes memory blockProof
  ) private view returns (uint256) {
    (
      bytes32 headerRoot,
      uint256 startBlock,
      ,
      uint256 createdAt,

    ) = checkpointManager.headerBlocks(headerNumber);

    require(
      keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot))
        .checkMembership(blockNumber - startBlock, headerRoot, blockProof),
      'FxRootTunnel: INVALID_HEADER'
    );
    return createdAt;
  }

  /**
   * @notice receive message from  L2 to L1, validated by proof
   * @dev This function verifies if the transaction actually happened on child chain
   *
   * @param inputData RLP encoded data of the reference tx containing following list of fields
   *  0 - headerNumber - Checkpoint header block number containing the reference tx
   *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
   *  2 - blockNumber - Block number containing the reference tx on child chain
   *  3 - blockTime - Reference tx block time
   *  4 - txRoot - Transactions root of block
   *  5 - receiptRoot - Receipts root of block
   *  6 - receipt - Receipt of the reference transaction
   *  7 - receiptProof - Merkle proof of the reference receipt
   *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
   *  9 - receiptLogIndex - Log Index to read from the receipt
   */
  function receiveMessage(bytes memory inputData) public virtual {
    bytes memory message = _validateAndExtractMessage(inputData);
    _processMessageFromChild(message);
  }

  /**
   * @notice Process message received from Child Tunnel
   * @dev function needs to be implemented to handle message as per requirement
   * This is called by onStateReceive function.
   * Since it is called via a system call, any event will not be emitted during its execution.
   * @param message bytes message that was sent from Child Tunnel
   */
  function _processMessageFromChild(bytes memory message) internal virtual;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

// BOIS feature bitmask
uint256 constant LEVEL2BOIS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000F;
uint256 constant LEVEL2WOLF = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000F0;

interface ISFTEvaluator {
  /**
   * @dev Returns the reward in 1e6 factor notation (1e6 = 100%)
   */
  function rewardRate(uint256 sftTokenId) external view returns (uint32);

  /**
   * @dev Returns the cFolioItemType of a given cFolioItem tokenId
   */
  function getCFolioItemType(uint256 tokenId) external view returns (uint256);

  /**
   * @dev Calculate the current reward rate, and notify TFC in case of change
   *
   * Optional revert on unchange to save gas on external calls.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged) external;

  /**
   * @dev Sets the cfolioItemType of a cfolioItem tokenId, not yet used
   * sftHolder tokenId expected (without hash)
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType_) external;
}

// SPDX-License-Identifier: MIT
/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.7.6;

library RLPReader {
  uint8 private constant STRING_SHORT_START = 0x80;
  uint8 private constant STRING_LONG_START = 0xb8;
  uint8 private constant LIST_SHORT_START = 0xc0;
  uint8 private constant LIST_LONG_START = 0xf8;
  uint8 private constant WORD_SIZE = 32;

  struct RLPItem {
    uint256 len;
    uint256 memPtr;
  }

  struct Iterator {
    RLPItem item; // Item that's being iterated over.
    uint256 nextPtr; // Position of the next item in the list.
  }

  /*
   * @dev Returns the next element in the iteration. Reverts if it has not next element.
   * @param self The iterator.
   * @return The next element in the iteration.
   */
  function next(Iterator memory self) internal pure returns (RLPItem memory) {
    require(hasNext(self));

    uint256 ptr = self.nextPtr;
    uint256 itemLength = _itemLength(ptr);
    self.nextPtr = ptr + itemLength;

    return RLPItem(itemLength, ptr);
  }

  /*
   * @dev Returns true if the iteration has more elements.
   * @param self The iterator.
   * @return true if the iteration has more elements.
   */
  function hasNext(Iterator memory self) internal pure returns (bool) {
    RLPItem memory item = self.item;
    return self.nextPtr < item.memPtr + item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
    uint256 memPtr;
    assembly {
      memPtr := add(item, 0x20)
    }

    return RLPItem(item.length, memPtr);
  }

  /*
   * @dev Create an iterator. Reverts if item is not a list.
   * @param self The RLP item.
   * @return An 'Iterator' over the item.
   */
  function iterator(RLPItem memory self)
    internal
    pure
    returns (Iterator memory)
  {
    require(isList(self));

    uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
    return Iterator(self, ptr);
  }

  /*
   * @param item RLP encoded bytes
   */
  function rlpLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function payloadLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len - _payloadOffset(item.memPtr);
  }

  /*
   * @param item RLP encoded list in bytes
   */
  function toList(RLPItem memory item)
    internal
    pure
    returns (RLPItem[] memory)
  {
    require(isList(item));

    uint256 items = numItems(item);
    RLPItem[] memory result = new RLPItem[](items);

    uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 dataLen;
    for (uint256 i = 0; i < items; i++) {
      dataLen = _itemLength(memPtr);
      result[i] = RLPItem(dataLen, memPtr);
      memPtr = memPtr + dataLen;
    }

    return result;
  }

  // @return indicator whether encoded payload is a list. negate this function call for isData.
  function isList(RLPItem memory item) internal pure returns (bool) {
    if (item.len == 0) return false;

    uint8 byte0;
    uint256 memPtr = item.memPtr;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < LIST_SHORT_START) return false;
    return true;
  }

  /*
   * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
   * @return keccak256 hash of RLP encoded bytes.
   */
  function rlpBytesKeccak256(RLPItem memory item)
    internal
    pure
    returns (bytes32)
  {
    uint256 ptr = item.memPtr;
    uint256 len = item.len;
    bytes32 result;
    assembly {
      result := keccak256(ptr, len)
    }
    return result;
  }

  function payloadLocation(RLPItem memory item)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 offset = _payloadOffset(item.memPtr);
    uint256 memPtr = item.memPtr + offset;
    uint256 len = item.len - offset; // data length
    return (memPtr, len);
  }

  /*
   * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
   * @return keccak256 hash of the item payload.
   */
  function payloadKeccak256(RLPItem memory item)
    internal
    pure
    returns (bytes32)
  {
    (uint256 memPtr, uint256 len) = payloadLocation(item);
    bytes32 result;
    assembly {
      result := keccak256(memPtr, len)
    }
    return result;
  }

  /** RLPItem conversions into data types **/

  // @returns raw rlp encoding in bytes
  function toRlpBytes(RLPItem memory item)
    internal
    pure
    returns (bytes memory)
  {
    bytes memory result = new bytes(item.len);
    if (result.length == 0) return result;

    uint256 ptr;
    assembly {
      ptr := add(0x20, result)
    }

    copy(item.memPtr, ptr, item.len);
    return result;
  }

  // any non-zero byte is considered true
  function toBoolean(RLPItem memory item) internal pure returns (bool) {
    require(item.len == 1);
    uint256 result;
    uint256 memPtr = item.memPtr;
    assembly {
      result := byte(0, mload(memPtr))
    }

    return result == 0 ? false : true;
  }

  function toAddress(RLPItem memory item) internal pure returns (address) {
    // 1 byte for the length prefix
    require(item.len == 21);

    return address(uint160(toUint(item)));
  }

  function toUint(RLPItem memory item) internal pure returns (uint256) {
    require(item.len > 0 && item.len <= 33);

    uint256 offset = _payloadOffset(item.memPtr);
    uint256 len = item.len - offset;

    uint256 result;
    uint256 memPtr = item.memPtr + offset;
    assembly {
      result := mload(memPtr)

      // shfit to the correct location if neccesary
      if lt(len, 32) {
        result := div(result, exp(256, sub(32, len)))
      }
    }

    return result;
  }

  // enforces 32 byte length
  function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
    // one byte prefix
    require(item.len == 33);

    uint256 result;
    uint256 memPtr = item.memPtr + 1;
    assembly {
      result := mload(memPtr)
    }

    return result;
  }

  function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
    require(item.len > 0);

    uint256 offset = _payloadOffset(item.memPtr);
    uint256 len = item.len - offset; // data length
    bytes memory result = new bytes(len);

    uint256 destPtr;
    assembly {
      destPtr := add(0x20, result)
    }

    copy(item.memPtr + offset, destPtr, len);
    return result;
  }

  /*
   * Private Helpers
   */

  // @return number of payload items inside an encoded list.
  function numItems(RLPItem memory item) private pure returns (uint256) {
    if (item.len == 0) return 0;

    uint256 count = 0;
    uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 endPtr = item.memPtr + item.len;
    while (currPtr < endPtr) {
      currPtr = currPtr + _itemLength(currPtr); // skip over an item
      count++;
    }

    return count;
  }

  // @return entire rlp item byte length
  function _itemLength(uint256 memPtr) private pure returns (uint256) {
    uint256 itemLen;
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) itemLen = 1;
    else if (byte0 < STRING_LONG_START)
      itemLen = byte0 - STRING_SHORT_START + 1;
    else if (byte0 < LIST_SHORT_START) {
      assembly {
        let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
        memPtr := add(memPtr, 1) // skip over the first byte
        /* 32 byte word size */
        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
        itemLen := add(dataLen, add(byteLen, 1))
      }
    } else if (byte0 < LIST_LONG_START) {
      itemLen = byte0 - LIST_SHORT_START + 1;
    } else {
      assembly {
        let byteLen := sub(byte0, 0xf7)
        memPtr := add(memPtr, 1)

        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    return itemLen;
  }

  // @return number of bytes until the data
  function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) return 0;
    else if (
      byte0 < STRING_LONG_START ||
      (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
    ) return 1;
    else if (byte0 < LIST_SHORT_START)
      // being explicit
      return byte0 - (STRING_LONG_START - 1) + 1;
    else return byte0 - (LIST_LONG_START - 1) + 1;
  }

  /*
   * @param src Pointer to source
   * @param dest Pointer to destination
   * @param len Amount of memory to copy from the source
   */
  function copy(
    uint256 src,
    uint256 dest,
    uint256 len
  ) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    // left over bytes. Mask is used to remove unwanted bytes from the word
    uint256 mask = 256**(WORD_SIZE - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask)) // zero out src
      let destpart := and(mload(dest), mask) // retrieve the bytes
      mstore(dest, or(destpart, srcpart))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { RLPReader } from './RLPReader.sol';

library MerklePatriciaProof {
  /*
   * @dev Verifies a merkle patricia proof.
   * @param value The terminating value in the trie.
   * @param encodedPath The path in the trie leading to value.
   * @param rlpParentNodes The rlp encoded stack of nodes.
   * @param root The root hash of the trie.
   * @return The boolean validity of the proof.
   */
  function verify(
    bytes memory value,
    bytes memory encodedPath,
    bytes memory rlpParentNodes,
    bytes32 root
  ) internal pure returns (bool) {
    RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
    RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

    bytes memory currentNode;
    RLPReader.RLPItem[] memory currentNodeList;

    bytes32 nodeKey = root;
    uint256 pathPtr = 0;

    bytes memory path = _getNibbleArray(encodedPath);
    if (path.length == 0) {
      return false;
    }

    for (uint256 i = 0; i < parentNodes.length; i++) {
      if (pathPtr > path.length) {
        return false;
      }

      currentNode = RLPReader.toRlpBytes(parentNodes[i]);
      if (nodeKey != keccak256(currentNode)) {
        return false;
      }
      currentNodeList = RLPReader.toList(parentNodes[i]);

      if (currentNodeList.length == 17) {
        if (pathPtr == path.length) {
          if (
            keccak256(RLPReader.toBytes(currentNodeList[16])) ==
            keccak256(value)
          ) {
            return true;
          } else {
            return false;
          }
        }

        uint8 nextPathNibble = uint8(path[pathPtr]);
        if (nextPathNibble > 16) {
          return false;
        }
        nodeKey = bytes32(
          RLPReader.toUintStrict(currentNodeList[nextPathNibble])
        );
        pathPtr += 1;
      } else if (currentNodeList.length == 2) {
        uint256 traversed = _nibblesToTraverse(
          RLPReader.toBytes(currentNodeList[0]),
          path,
          pathPtr
        );
        if (pathPtr + traversed == path.length) {
          //leaf node
          if (
            keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)
          ) {
            return true;
          } else {
            return false;
          }
        }

        //extension node
        if (traversed == 0) {
          return false;
        }

        pathPtr += traversed;
        nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
      } else {
        return false;
      }
    }
    return false;
  }

  function _nibblesToTraverse(
    bytes memory encodedPartialPath,
    bytes memory path,
    uint256 pathPtr
  ) private pure returns (uint256) {
    uint256 len = 0;
    // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
    // and slicedPath have elements that are each one hex character (1 nibble)
    bytes memory partialPath = _getNibbleArray(encodedPartialPath);
    bytes memory slicedPath = new bytes(partialPath.length);

    // pathPtr counts nibbles in path
    // partialPath.length is a number of nibbles
    for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
      bytes1 pathNibble = path[i];
      slicedPath[i - pathPtr] = pathNibble;
    }

    if (keccak256(partialPath) == keccak256(slicedPath)) {
      len = partialPath.length;
    } else {
      len = 0;
    }
    return len;
  }

  // bytes b must be hp encoded
  function _getNibbleArray(bytes memory b)
    internal
    pure
    returns (bytes memory)
  {
    bytes memory nibbles = '';
    if (b.length > 0) {
      uint8 offset;
      uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
      if (hpNibble == 1 || hpNibble == 3) {
        nibbles = new bytes(b.length * 2 - 1);
        bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
        nibbles[0] = oddNibble;
        offset = 1;
      } else {
        nibbles = new bytes(b.length * 2 - 2);
        offset = 0;
      }

      for (uint256 i = offset; i < nibbles.length; i++) {
        nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
      }
    }
    return nibbles;
  }

  function _getNthNibbleOfBytes(uint256 n, bytes memory str)
    private
    pure
    returns (bytes1)
  {
    return
      bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library Merkle {
  function checkMembership(
    bytes32 leaf,
    uint256 index,
    bytes32 rootHash,
    bytes memory proof
  ) internal pure returns (bool) {
    require(proof.length % 32 == 0, 'Invalid proof length');
    uint256 proofHeight = proof.length / 32;
    // Proof of size n means, height of the tree is n+1.
    // In a tree of height n+1, max #leafs possible is 2 ^ n
    require(index < 2**proofHeight, 'Leaf index is too big');

    bytes32 proofElement;
    bytes32 computedHash = leaf;
    for (uint256 i = 32; i <= proof.length; i += 32) {
      assembly {
        proofElement := mload(add(proof, i))
      }

      if (index % 2 == 0) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }

      index = index / 2;
    }
    return computedHash == rootHash;
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';

import './interfaces/IERC1155BurnMintable.sol';
import './interfaces/IWOWSCryptofolio.sol';
import './interfaces/IWOWSERC1155.sol';

contract WOWSCryptofolio is IWOWSCryptofolio, Context, ERC1155Holder {
  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // List of all known tradefloors
  address[] public override _tradefloors;

  // Our NFT token parent
  IWOWSERC1155 private _deployer;

  // The owner of the NFT token parent
  address private _owner;

  // Mapping of cryptofolio items (trade floor to token ID) owned by this
  // cryptofolio
  mapping(address => uint256[]) private _cryptofolios;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Triggered if an SFT receives new tokens from operator
   *
   * @param sft The contract address of the tokens
   * @param operator The user that sent the tokens to the cryptofolio
   * @param tokenIds The IDs being transferred
   * @param amounts The amounts being transferred
   */
  event CryptoFolioAdded(
    address indexed sft,
    address indexed operator,
    uint256[] tokenIds,
    uint256[] amounts
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-initialize}.
   */
  function initialize() external override {
    // Validate state
    require(address(_deployer) == address(0), 'CF: Already initialized');

    // Update state
    _deployer = IWOWSERC1155(_msgSender());
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSCryptofolio}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-getCryptofolio}.
   */
  function getCryptofolio(address tradefloor)
    external
    view
    override
    returns (uint256[] memory tokenIds, uint256 idsLength)
  {
    // Load state
    uint256[] storage itemIds = _cryptofolios[tradefloor];

    // Allocate return values
    uint256[] memory result = new uint256[](itemIds.length);
    uint256 newLength = 0;

    if (itemIds.length > 0) {
      // All tokens belong to this contract
      address[] memory accounts = new address[](itemIds.length);
      for (uint256 i = 0; i < itemIds.length; ++i) {
        accounts[i] = address(this);
      }

      // Load state
      uint256[] memory balances = IERC1155(tradefloor).balanceOfBatch(
        accounts,
        itemIds
      );

      // Calculate return value
      for (uint256 i = 0; i < itemIds.length; ++i) {
        if (balances[i] > 0) {
          result[newLength++] = itemIds[i];
        }
      }
    }

    return (result, newLength);
  }

  /**
   * @dev See {IWOWSCryptofolio-setOwner}.
   */
  function setOwner(address newOwner) external override {
    // Access control
    require(msg.sender == address(_deployer), 'CF: Only deployer');

    // Update state
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      if (_owner != address(0))
        IERC1155(_tradefloors[i]).setApprovalForAll(_owner, false);
      if (newOwner != address(0))
        IERC1155(_tradefloors[i]).setApprovalForAll(newOwner, true);
    }
    _owner = newOwner;
  }

  /**
   * @dev See {IWOWSCryptofolio-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool allow) external override {
    // Access control
    require(_msgSender() == _owner, 'CF: Only owner');

    // Update state
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      IERC1155(_tradefloors[i]).setApprovalForAll(operator, allow);
    }
  }

  /**
   * @dev See {IWOWSCryptofolio-burn}.
   */
  function burn() external override {
    // Access control
    require(_msgSender() == address(_deployer), 'CF: Only deployer');

    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      // Load state
      IERC1155BurnMintable tradefloor = IERC1155BurnMintable(_tradefloors[i]);
      uint256[] storage itemIds = _cryptofolios[address(tradefloor)];

      if (itemIds.length > 0) {
        // All tokens belong to this contract
        address[] memory accounts = new address[](itemIds.length);
        for (uint256 j = 0; j < itemIds.length; ++j) {
          accounts[j] = address(this);
        }

        // Load state
        uint256[] memory balances = tradefloor.balanceOfBatch(
          accounts,
          itemIds
        );

        // Update state
        tradefloor.burnBatch(address(this), itemIds, balances);
      }

      // Update state
      delete _cryptofolios[address(tradefloor)];
    }

    // Update state
    delete _tradefloors;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155TokenReceiver} via {ERC1155Holder}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155Received}
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override returns (bytes4) {
    // Parameters
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;

    // Update state
    _onTokensReceived(tokenIds, amounts);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) public override returns (bytes4) {
    // Update state
    _onTokensReceived(tokenIds, amounts);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Update our collection of tradeable cryptofolio items
   *
   * This function is only allowed to be called from one of our pseudo
   * TokenReceiver contracts.
   */
  function _onTokensReceived(
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) internal {
    address tradefloor = _msgSender();

    // Access control
    require(_deployer.isTradeFloor(tradefloor), 'CF: Only tradefloor');

    // Validate parameters
    require(tokenIds.length == amounts.length, 'CF: Input lengths differ');

    // Load state
    uint256[] storage currentIds = _cryptofolios[tradefloor];

    // Update state
    if (currentIds.length == 0) {
      IERC1155(tradefloor).setApprovalForAll(_owner, true);
      _tradefloors.push(tradefloor);
    }

    // Update state
    for (uint256 iIds = 0; iIds < tokenIds.length; ++iIds) {
      if (amounts[iIds] > 0) {
        uint256 tokenId = tokenIds[iIds];

        // Search tokenId
        uint256 i = 0;
        for (; i < currentIds.length && currentIds[i] != tokenId; ++i) i;

        // If token was not found, insert it
        if (i == currentIds.length) {
          currentIds.push(tokenId);
        }
      }
    }

    // Log state change
    emit CryptoFolioAdded(address(this), tradefloor, tokenIds, amounts);
  }
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

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IERC1155BurnMintable is IERC1155 {
  /**
   * @dev Mint amount new tokens at ID `tokenId` (MINTER_ROLE required)
   */
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) external;

  /**
   * @dev Mint new token amounts at IDs `tokenIds` (MINTER_ROLE required)
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes memory data
  ) external;

  /**
   * @dev Burn value amount of tokens with ID `tokenId`.
   *
   * Caller must be approvedForAll.
   */
  function burn(
    address account,
    uint256 tokenId,
    uint256 value
  ) external;

  /**
   * @dev Burn `values` amounts of tokens with IDs `tokenIds`.
   *
   * Caller must be approvedForAll.
   */
  function burnBatch(
    address account,
    uint256[] calldata tokenIds,
    uint256[] calldata values
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
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

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../booster/interfaces/IBooster.sol';
import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../cfolio/interfaces/ISFTEvaluator.sol';
import '../investment/interfaces/IRewardHandler.sol';
import '../token/interfaces/IERC1155BurnMintable.sol';
import '../token/interfaces/ITradeFloor.sol';
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

contract WOWSSftMinter is Context, Ownable {
  using TokenIds for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // PricePerlevel, customLevel start at 0xFF
  mapping(uint16 => uint256) public _pricePerLevel;

  struct CFolioItemSft {
    uint256 handlerId;
    uint256 price;
    uint128 numMinted;
    uint128 maxMintable;
  }
  mapping(uint256 => CFolioItemSft) public cfolioItemSfts; // C-folio type to c-folio data
  ICFolioItemHandler[] private cfolioItemHandlers;

  uint256 public nextCFolioItemNft = (1 << 64);

  // The ERC1155 contract we are minting from
  IWOWSERC1155 private immutable _sftContract;

  // The cfolioItem wrapper bridge
  address private immutable _cfiBridge;

  // WOWS token contract
  IERC20 private immutable _wowsToken;

  // Booster
  IBooster private immutable _booster;

  // Reward handler which distributes WOWS
  IRewardHandler public rewardHandler;

  // TradeFloor Proxy contract
  address public tradeFloor;

  // SFTEvaluator to store the cfolioItemType
  ISFTEvaluator public sftEvaluator;

  // Set while minting CFolioToken
  bool private _setupCFolio;

  // 1.0 of the rewards go to distribution
  uint32 private constant ALL = 1 * 1e6;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Emitted if a new SFT is minted
  event Mint(
    address indexed recipient,
    uint256 tokenId,
    uint256 price,
    uint256 cfolioType
  );

  // Emitted if cFolio mint specifications (e.g. limits / price) have changed
  event CFolioSpecChanged(uint256[] ids, WOWSSftMinter upgradeFrom);

  // Emitted if the contract gets destroyed
  event Destruct();

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Contruct WOWSSftMinter
   *
   * @param addressRegistry WOWS system addressRegistry
   */
  constructor(IAddressRegistry addressRegistry) {
    // Initialize {Ownable}
    transferOwnership(
      addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET)
    );

    // Initialize state
    _sftContract = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );
    _wowsToken = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
    );
    _cfiBridge = addressRegistry.getRegistryEntry(
      AddressBook.CFOLIOITEM_BRIDGE_PROXY
    );
    rewardHandler = IRewardHandler(
      addressRegistry.getRegistryEntry(AddressBook.REWARD_HANDLER)
    );
    _booster = IBooster(
      addressRegistry.getRegistryEntry(AddressBook.WOWS_BOOSTER_PROXY)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set prices for the given levels
   */
  function setPrices(uint16[] memory levels, uint256[] memory prices)
    external
    onlyOwner
  {
    // Validate parameters
    require(levels.length == prices.length, 'Length mismatch');

    // Update state
    for (uint256 i = 0; i < levels.length; ++i)
      _pricePerLevel[levels[i]] = prices[i];
  }

  /**
   * @dev Set new reward handler
   *
   * RewardHandler is by concept upgradeable / see investment::Controller.sol.
   */
  function setRewardHandler(IRewardHandler newRewardHandler)
    external
    onlyOwner
  {
    // Update state
    rewardHandler = newRewardHandler;
  }

  /**
   * @dev Set Trade Floor
   */
  function setTradeFloor(address tradeFloor_) external onlyOwner {
    // Validate parameters
    require(tradeFloor_ != address(0), 'Invalid TF');

    // Update state
    tradeFloor = tradeFloor_;
  }

  /**
   * @dev Set SFT evaluator
   */
  function setSFTEvaluator(ISFTEvaluator sftEvaluator_) external onlyOwner {
    // Validate parameters
    require(address(sftEvaluator_) != address(0), 'Invalid TF');

    // Update state
    sftEvaluator = sftEvaluator_;
  }

  /**
   * @dev Set the limitations, the price and the handlers for CFolioItem SFT's
   */
  function setCFolioSpec(
    uint256[] calldata cFolioTypes,
    address[] calldata handlers,
    uint128[] calldata maxMint,
    uint256[] calldata prices,
    WOWSSftMinter oldMinter
  ) external onlyOwner {
    // Validate parameters
    require(
      cFolioTypes.length == handlers.length &&
        handlers.length == maxMint.length &&
        maxMint.length == prices.length,
      'Length mismatch'
    );

    // Update state
    delete (cfolioItemHandlers);

    for (uint256 i = 0; i < cFolioTypes.length; ++i) {
      uint256 j = 0;
      for (; j < cfolioItemHandlers.length; ++j) {
        if (address(cfolioItemHandlers[j]) == handlers[i]) break;
      }

      if (j == cfolioItemHandlers.length) {
        cfolioItemHandlers.push(ICFolioItemHandler(handlers[i]));
      }

      CFolioItemSft storage cfi = cfolioItemSfts[cFolioTypes[i]];
      cfi.handlerId = j;
      cfi.maxMintable = maxMint[i];
      cfi.price = prices[i];
    }
    if (address(oldMinter) != address(0)) {
      for (uint256 i = 0; i < cFolioTypes.length; ++i) {
        (, , uint128 numMinted, ) = oldMinter.cfolioItemSfts(cFolioTypes[i]);
        cfolioItemSfts[cFolioTypes[i]].numMinted = numMinted;
      }

      nextCFolioItemNft = oldMinter.nextCFolioItemNft();
    }

    // Dispatch event
    emit CFolioSpecChanged(cFolioTypes, oldMinter);
  }

  /**
   * @dev upgrades state from an existing WOWSSFTMinter
   */
  function destructContract() external onlyOwner {
    // Dispatch event
    emit Destruct();

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "WOWSSftMinter.destructContract() allows anyone to destruct the
    // contract", which is not the case due to the {Ownable-onlyOwner} modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(_msgSender());
  }

  /**
   * @dev Mint one of our stock card SFTs
   *
   * Approval of WOWS token required before the call.
   */
  function mintWowsSFT(
    address recipient,
    uint8 level,
    uint8 cardId
  ) external {
    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // Load state
    uint256 price = _pricePerLevel[level];

    // Validate state
    require(price > 0, 'No price available');

    // Get the next free mintable token for level / cardId
    (bool success, uint256 tokenId) = _sftContract.getNextMintableTokenId(
      level,
      cardId
    );
    require(success, 'Unsufficient cards');

    // Update state
    _mint(recipient, tokenId, price, 0);
  }

  /**
   * @dev Mint a custom token
   *
   * Approval of WOWS token required before the call.
   */
  function mintCustomSFT(
    address recipient,
    uint8 level,
    string memory uri
  ) external {
    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // Load state
    uint256 price = _pricePerLevel[0x100 + level];

    // Validate state
    require(price > 0, 'No price available');

    // Get the next free mintable token for level / cardId
    uint256 tokenId = _sftContract.getNextMintableCustomToken();

    // Custom baseToken only allowed < 64Bit
    require(tokenId.isBaseCard(), 'Max tokenId reached');

    // Set card level and uri
    _sftContract.setCustomCardLevel(tokenId, level);
    _sftContract.setCustomURI(tokenId, uri);

    // Update state
    _mint(recipient, tokenId, price, 0);
  }

  /**
   * @dev Mint a CFolioItem token
   *
   * Approval of WOWS token required before the call.
   *
   * Post-condition: `_setupCFolio` must be false.
   *
   * @param recipient Recipient of the SFT, unused if sftTokenId is != -1
   * @param cfolioItemType The item type of the SFT
   * @param sftTokenId If <> -1 recipient is the SFT c-folio / handler must be called
   * @param investAmounts Arguments needed for the handler (in general investments).
   * Investments may be zero if the user is just buying an SFT.
   */
  function mintCFolioItemSFT(
    address recipient,
    uint256 cfolioItemType,
    uint256 sftTokenId,
    uint256[] calldata investAmounts
  ) external {
    // Validate state
    require(!_setupCFolio, 'Already setting up');
    require(address(sftEvaluator) != address(0), 'SFTE not set');

    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // Load state
    CFolioItemSft storage sftData = cfolioItemSfts[cfolioItemType];

    // Validate state
    require(
      sftData.numMinted < sftData.maxMintable,
      'CFI Minter: Insufficient amount'
    );

    address sftCFolio = address(0);
    if (sftTokenId != uint256(-1)) {
      require(sftTokenId.isBaseCard(), 'Invalid sftTokenId');

      // Get the CFolio contract address, it will be the final recipient
      sftCFolio = _sftContract.tokenIdToAddress(sftTokenId);
      require(sftCFolio != address(0), 'Bad sftTokenId');

      // Intermediate owner of the minted SFT
      recipient = address(this);

      // Allow this contract to be an ERC1155 holder
      _setupCFolio = true;
    }

    uint256 tokenId = nextCFolioItemNft++;
    require(tokenId.isCFolioCard(), 'Invalid cfolioItem tokenId');

    sftEvaluator.setCFolioItemType(tokenId, cfolioItemType);

    // Update state, mint SFT token
    sftData.numMinted += 1;
    _mint(recipient, tokenId, sftData.price, cfolioItemType);

    // Let CFolioHandler setup the new minted token
    cfolioItemHandlers[sftData.handlerId].setupCFolio(
      _msgSender(),
      tokenId,
      investAmounts
    );

    // Check-effects-interaction not needed, as `_setupCFolio` can't be mutated
    // outside this function.

    // If the SFT's c-folio is final recipient of c-folio item, we call the
    // handler and lock the c-folio item in the TradeFloor contract before we
    // transfer it to the SFT.
    if (sftCFolio != address(0)) {
      // Lock the SFT into the TradeFloor contract
      IERC1155BurnMintable(address(_sftContract)).safeTransferFrom(
        address(this),
        address(_cfiBridge),
        tokenId,
        1,
        abi.encodePacked(sftCFolio)
      );

      // Reset the temporary state which allows holding ERC1155 token
      _setupCFolio = false;
    }
  }

  /**
   * @dev Claim rewards from all c-folio farms
   *
   * If lockPeriod > 0, Booster locks the token on behalf of sftToken and
   * provides extra rewards. Otherwise rewards are distributed in
   * rewardHandler.
   *
   * @param sftTokenId Valid SFT tokenId, must not be locked in TF
   * @param lockPeriod Lock time in seconds
   */
  function claimSFTRewards(uint256 sftTokenId, uint256 lockPeriod) external {
    // If lockPeriod > 0 rewards are managed by booster
    address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'WM: Invalid cfolio');

    address receiver = lockPeriod > 0 ? cfolio : _msgSender();

    bool[] memory lookup = new bool[](cfolioItemHandlers.length);
    (uint256[] memory items, uint256 itemsLength) = IWOWSCryptofolio(cfolio)
      .getCryptofolio(_cfiBridge);

    for (uint256 i = 0; i < itemsLength; ++i) {
      // Get the handler of this type
      uint256 handlerId = cfolioItemSfts[
        sftEvaluator.getCFolioItemType(items[i])
      ].handlerId;
      if (!lookup[handlerId]) {
        cfolioItemHandlers[handlerId].getRewards(
          _msgSender(),
          receiver,
          sftTokenId
        );
        lookup[handlerId] = true;
      }
    }

    // In case lockPeriod is set, all rewards are temporarily parked in
    // booster. Lock the parked rewards for the current msg.sender.
    if (lockPeriod > 0) {
      _booster.lock(receiver, lockPeriod);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // ERC1155Holder
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev We are a temorary token holder during CFolioToken mint step
   *
   * Only accept ERC1155 tokens during this setup.
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) external view returns (bytes4) {
    // Validate state
    require(_setupCFolio, 'Only during setup');

    // Call ancestor
    return this.onERC1155Received.selector;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Query prices for given levels
   */
  function getPrices(uint16[] memory levels)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](levels.length);
    for (uint256 i = 0; i < levels.length; ++i)
      result[i] = _pricePerLevel[levels[i]];
    return result;
  }

  /**
   * @dev retrieve mint information about cfolioItem
   */
  function getCFolioSpec(uint256[] calldata cFolioTypes)
    external
    view
    returns (
      uint256[] memory prices,
      uint128[] memory numMinted,
      uint128[] memory maxMintable
    )
  {
    uint256 length = cFolioTypes.length;
    prices = new uint256[](length);
    numMinted = new uint128[](length);
    maxMintable = new uint128[](length);

    for (uint256 i; i < length; ++i) {
      CFolioItemSft storage cfi = cfolioItemSfts[cFolioTypes[i]];
      prices[i] = cfi.price;
      numMinted[i] = cfi.numMinted;
      maxMintable[i] = cfi.maxMintable;
    }
  }

  /**
   * @dev Get all tokenIds from SFT and TF contract owned by account.
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory sftTokenIds, uint256[] memory tfTokenIds)
  {
    require(account != address(0), 'Null address');
    sftTokenIds = _sftContract.getTokenIds(account);
    tfTokenIds = ITradeFloor(tradeFloor).getTokenIds(account);
  }

  /**
   * @dev Get underlying information (cFolioItems / value) for given tokenIds.
   *
   * @param tokenIds the tokenIds information should be queried
   * @return result [%,MintTime,NumItems,[tokenId,type,numAssetValues,[assetValue]]]...
   */
  function getTokenInformation(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory result)
  {
    uint256[] memory cFolioItems;
    uint256[] memory oneCFolioItem = new uint256[](1);
    uint256 cfolioLength;
    uint256 rewardRate;
    uint256 timestamp;

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      if (tokenIds[i].isBaseCard()) {
        // Only main TradeFloor supported
        uint256 sftTokenId = tokenIds[i].toSftTokenId();
        address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
        if (address(cfolio) != address(0)) {
          (cFolioItems, cfolioLength) = IWOWSCryptofolio(cfolio).getCryptofolio(
            _cfiBridge
          );
        } else {
          cFolioItems = oneCFolioItem;
          cfolioLength = 0;
        }

        rewardRate = sftEvaluator.rewardRate(tokenIds[i]);
        (timestamp, ) = _sftContract.getTokenData(sftTokenId);
      } else {
        oneCFolioItem[0] = tokenIds[i];
        cfolioLength = 1;
        cFolioItems = oneCFolioItem; // Reference, no copy
        rewardRate = 0;
        timestamp = 0;
      }

      result = abi.encodePacked(result, rewardRate, timestamp, cfolioLength);

      for (uint256 j = 0; j < cfolioLength; ++j) {
        uint256 sftTokenId = cFolioItems[j].toSftTokenId();
        uint256 cfolioType = sftEvaluator.getCFolioItemType(sftTokenId);
        uint256[] memory amounts;

        address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
        if (address(cfolio) != address(0)) {
          address handler = IWOWSCryptofolio(cfolio)._tradefloors(0);
          if (handler != address(0))
            amounts = ICFolioItemHandler(handler).getAmounts(cfolio);
        }

        result = abi.encodePacked(
          result,
          cFolioItems[j],
          cfolioType,
          amounts.length,
          amounts
        );
      }
    }
  }

  /**
   * @dev Get CFIItemHandlerRewardInfo and Booster rewardInfo.
   */
  function getRewardInfo(address cfih, uint256[] calldata tokenIds)
    external
    view
    returns (
      bytes memory result,
      uint256[] memory boosterLocked,
      uint256[] memory boosterPending,
      uint256[] memory boosterApr,
      uint256[] memory boosterSecsLeft
    )
  {
    result = ICFolioItemHandler(cfih).getRewardInfo(tokenIds);
    (boosterLocked, boosterPending, boosterApr, boosterSecsLeft) = _booster
      .getRewardInfo(tokenIds);
  }

  /**
   * @dev Get balances of given ERC20 addresses.
   */
  function getErc20Balances(address account, address[] calldata erc20)
    external
    view
    returns (uint256[] memory amounts)
  {
    amounts = new uint256[](erc20.length);
    for (uint256 i = 0; i < erc20.length; ++i)
      amounts[i] = erc20[i] == address(0)
        ? 0
        : IERC20(erc20[i]).balanceOf(account);
  }

  /**
   * @dev Get allowances of given ERC20 addresses.
   */
  function getErc20Allowances(
    address account,
    address[] calldata spender,
    address[] calldata erc20
  ) external view returns (uint256[] memory amounts) {
    // Validate parameters
    require(spender.length == erc20.length, 'Length mismatch');

    amounts = new uint256[](spender.length);
    for (uint256 i = 0; i < spender.length; ++i)
      amounts[i] = erc20[i] == address(0)
        ? 0
        : IERC20(erc20[i]).allowance(account, spender[i]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  function _mint(
    address recipient,
    uint256 tokenId,
    uint256 price,
    uint256 cfolioType
  ) internal {
    // Transfer WOWS from user to reward handler
    if (price > 0)
      _wowsToken.safeTransferFrom(_msgSender(), address(rewardHandler), price);

    // Mint the token
    IERC1155BurnMintable(address(_sftContract)).mint(recipient, tokenId, 1, '');

    // Distribute the rewards
    if (price > 0) rewardHandler.distribute2(recipient, price, ALL);

    // Log event
    emit Mint(recipient, tokenId, price, cfolioType);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to C-folio item contracts
 */
interface IBooster {
  /**
   * @dev Return information about the reward state in Booster
   *
   * @param tokenIds The SFT or TF tokenId
   *
   * @return locked The total amounts locked
   * @return pending The pending amounts claimable
   * @return apr The APR of this lock pool
   * @return secsLeft Numbers of seconds until unlock, or -1 if unlocked
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    );

  /**
   * @dev Handles farm distribution, only callable from controller
   *
   * If recipient is booster contract, amount is temporarily stored and locked
   * in a second call.
   *
   * @param farm The reward farm that the call originates from
   * @param recipient The recipient of the rewards
   * @param amount The amount to distribute
   * @param fee The fee in 6 decimal notation
   */
  function distributeFromFarm(
    address farm,
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Locks temporary tokens owned by recipient for a specific duration
   * of seconds.
   *
   * @param recipient The recipient of the rewards
   * @param lockPeriod The lock period in seconds
   */
  function lock(address recipient, uint256 lockPeriod) external;

  /**
   * @dev Claim rewards either into wallet or re-lock them
   *
   * @param sftTokenId The tokenId that manages the rewards
   * @param reLock True to re-lock existing rewards to earn more
   */
  function claimRewards(uint256 sftTokenId, bool reLock) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

interface IRewardHandler {
  /**
   * @dev Get the amount allocated for the Booster
   *
   * @return The amount which is allocated for the Booster (18 decimals)
   */
  function getBoosterRewards() external view returns (uint256);

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the new implementation of distribute() which uses internal fees
   * defined in the {RewardHandler} contract.
   *
   * @param recipient The recipient of the reward
   * @param amount The amount of WOWS to transfer to the recipient
   * @param fee The reward fee in 1e6 factor notation
   */
  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the current implementation, needed for backward compatibility.
   *
   * Current ERC1155Minter and Controller call this function, later
   * reward handler clients should call the the new one with internal
   * fees specified in this contract.
   *
   * uint32 values are in 1e6 factor notation.
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint32 fee,
    uint32 toTeam,
    uint32 toMarketing,
    uint32 toBooster,
    uint32 toRewardPool
  ) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio and tokenId interface
 */
interface ITradeFloor {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
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

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/IAddressRegistry.sol';

pragma solidity >=0.7.0 <0.8.0;

contract AddressRegistry is IAddressRegistry, Ownable {
  mapping(bytes32 => address) public registry;

  constructor(address _owner) {
    transferOwnership(_owner);
  }

  function setRegistryEntry(bytes32 _key, address _location)
    external
    override
    onlyOwner
  {
    registry[_key] = _location;
  }

  function getRegistryEntry(bytes32 _key)
    external
    view
    override
    returns (address)
  {
    require(registry[_key] != address(0), 'no address for key');
    return registry[_key];
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../utils/ERC20Recovery.sol';

import './interfaces/IController.sol';
import './interfaces/IFarm.sol';
import './interfaces/IStakeFarm.sol';
import '../../interfaces/uniswap/IUniswapV2Pair.sol';

contract UniV2StakeFarm is
  IFarm,
  IStakeFarm,
  Context,
  Ownable,
  ReentrancyGuard,
  ERC20Recovery
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IUniswapV2Pair public stakingToken;
  uint256 public override periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public override rewardsDuration = 14 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 private availableRewards;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  // Unique name of this farm instance, used in controller
  string private _farmName;
  // Uniswap route to get price for token 0 in pair
  IUniswapV2Pair public immutable route;
  // The address of the controller
  IController public override controller;
  // The direction of the uniswap pairs
  uint8 public pairDirection;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _owner,
    string memory _name,
    address _stakingToken,
    address _rewardToken,
    address _controller,
    address _route
  ) {
    _farmName = _name;
    stakingToken = IUniswapV2Pair(_stakingToken);
    controller = IController(_controller);
    route = IUniswapV2Pair(_route);

    address routeLink;

    /**
     * @dev Calculate the sort order of the keys once to save gas in further steps
     *
     * Our token sort order is:
     * - stakeToken: token0[routeLink], token1[rewardToken]
     * - route:      token0[routeLink], token1[stableCoin]
     *
     * If the sort order differs, we set one bit for each of both
     */
    if (stakingToken.token0() == _rewardToken) {
      pairDirection = 1;
      routeLink = stakingToken.token1();
    } else routeLink = stakingToken.token0();

    if (
      address(_route) != address(0) &&
      IUniswapV2Pair(_route).token1() == routeLink
    ) pairDirection |= 2;
    transferOwnership(_owner);
  }

  /* ========== VIEWS ========== */

  function farmName() external view override returns (string memory) {
    return _farmName;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(_totalSupply)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  function getUIData(address _user) external view returns (uint256[9] memory) {
    (uint112 reserve0, uint112 reserve1, uint256 price) = _getTokenUiData();
    uint256[9] memory result = [
      // Pool
      stakingToken.totalSupply(),
      (uint256(reserve0)),
      (uint256(reserve1)),
      price,
      // Stake
      _totalSupply,
      _balances[_user],
      rewardsDuration,
      rewardRate.mul(rewardsDuration),
      earned(_user)
    ];
    return result;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount)
    external
    override
    nonReentrant
    updateReward(_msgSender())
  {
    require(amount > 0, 'Cannot stake 0');

    controller.onDeposit(amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[_msgSender()] = _balances[_msgSender()].add(amount);
    IERC20(address(stakingToken)).safeTransferFrom(
      _msgSender(),
      address(this),
      amount
    );

    emit Staked(_msgSender(), amount);
  }

  function unstake(uint256 amount)
    public
    override
    nonReentrant
    updateReward(_msgSender())
  {
    require(amount > 0, 'Cannot withdraw 0');

    controller.onWithdraw(amount);

    _totalSupply = _totalSupply.sub(amount);
    _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
    IERC20(address(stakingToken)).safeTransfer(_msgSender(), amount);

    emit Unstaked(_msgSender(), amount);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    updateReward(_msgSender())
    updateReward(recipient)
  {
    require(recipient != address(0), 'invalid address');
    require(amount > 0, 'zero amount');

    _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfered(_msgSender(), recipient, amount);
  }

  function getReward() public override nonReentrant updateReward(_msgSender()) {
    uint256 reward = rewards[_msgSender()];
    if (reward > 0) {
      rewards[_msgSender()] = 0;
      availableRewards = availableRewards.sub(reward);
      controller.payOutRewards(_msgSender(), reward);
      emit RewardPaid(_msgSender(), reward);
    }
  }

  function exit() external override {
    unstake(_balances[_msgSender()]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setController(address newController)
    external
    override
    onlyController
  {
    controller = IController(newController);
    emit ControllerChanged(newController);
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyController
    updateReward(address(0))
  {
    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      // solhint-disable-next-line not-rely-on-time
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }
    availableRewards = availableRewards.add(reward);

    // Ensure the provided reward amount is not more than the balance in the
    // contract.
    //
    // This keeps the reward rate in the right range, preventing overflows due
    // to very high values of rewardRate in the earned and rewardsPerToken
    // functions.
    //
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    //
    require(
      rewardRate <= availableRewards.div(rewardsDuration),
      'Provided reward too high'
    );

    // solhint-disable-next-line not-rely-on-time
    lastUpdateTime = block.timestamp;
    // solhint-disable-next-line not-rely-on-time
    periodFinish = block.timestamp.add(rewardsDuration);

    emit RewardAdded(reward);
  }

  // We don't have any slot handling
  // solhint-disable-next-line no-empty-blocks
  function weightSlotId(uint256 slotId, uint256 weight) external override {}

  // Added to support recovering LP Rewards from other systems to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount)
    external
    onlyOwner
  {
    // Cannot recover the staking token or the rewards token
    require(
      tokenAddress != address(stakingToken),
      'pool tokens not recoverable'
    );

    // Call ancestor
    _recoverERC20(owner(), tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration)
    external
    override
    onlyOwner
  {
    require(
      // solhint-disable-next-line not-rely-on-time
      periodFinish == 0 || block.timestamp > periodFinish,
      'reward period not finished'
    );
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  // Not yet implemented
  function recoverERC20(
    address,
    address,
    uint256
  ) public {}

  /* ========== PRIVATE ========== */

  function _ethAmount(uint256 amountToken) private view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = stakingToken.getReserves();

    // RouteLink is token1, swap
    if ((pairDirection & 1) != 0) reserve0 = reserve1;

    return (uint256(reserve0).mul(amountToken)).div(stakingToken.totalSupply());
  }

  /**
   * @dev Returns the reserves in order: ETH -> Token, ETH/stable
   */
  function _getTokenUiData()
    internal
    view
    returns (
      uint112,
      uint112,
      uint256
    )
  {
    (uint112 reserve0, uint112 reserve1, ) = stakingToken.getReserves();
    (uint112 reserve0R, uint112 reserve1R, ) = address(route) != address(0)
      ? route.getReserves()
      : (1, 1, 0);

    uint112 swap;

    // RouteLink is token1, swap
    if ((pairDirection & 1) != 0) {
      swap = reserve0;
      reserve0 = reserve1;
      reserve1 = swap;
    }

    // RouteLink is token1, swap
    if ((pairDirection & 2) != 0) {
      swap = reserve0R;
      reserve0R = reserve1R;
      reserve1R = swap;
    }

    return (reserve0, reserve1, uint256(reserve0R).mul(1e18).div(reserve1R));
  }

  /* ========== MODIFIERS ========== */

  modifier onlyController() {
    require(_msgSender() == address(controller), 'not controller');
    _;
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event Transfered(address indexed from, address indexed to, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event ControllerChanged(address newController);
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

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract ERC20Recovery {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Fired when a recipient receives recovered ERC-20 tokens
   *
   * @param recipient The target recipient receving the recovered coins
   * @param tokenAddress The address of the ERC-20 token
   * @param tokenAmount The amount of the token being recovered
   */
  event Recovered(
    address indexed recipient,
    address indexed tokenAddress,
    uint256 tokenAmount
  );

  //////////////////////////////////////////////////////////////////////////////
  // Internal interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Recover ERC20 token from contract which have been transfered
   * either by accident or via airdrop
   *
   * Proper access must be verified. All tokens used by the system must
   * be blocked from recovery.
   *
   * @param recipient The target recipient of the recovered coins
   * @param tokenAddress The address of the ERC-20 token
   * @param tokenAmount The amount of the token to recover
   */
  function _recoverERC20(
    address recipient,
    address tokenAddress,
    uint256 tokenAmount
  ) internal {
    // Validate parameters
    require(recipient != address(0), "Can't recover to address 0");

    // Update state
    IERC20(tokenAddress).safeTransfer(recipient, tokenAmount);

    // Dispatch event
    emit Recovered(recipient, tokenAddress, tokenAmount);
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

interface IController {
  /**
   * @dev Used to control fees and accessibility instead having an implementation
   * in each farm contract
   *
   * Deposit is only allowed if farm is open and not not paused. Must revert on
   * failure.
   *
   * @param amount Number of tokens the user wants to deposit
   *
   * @return fee The deposit fee (1e18 factor) on success
   */
  function onDeposit(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Used to control fees and accessibility instead having an
   * implementation in each farm contract
   *
   * Withdraw is only allowed if farm is not paused. Must revert on failure
   *
   * @param amount Number of tokens the user wants to withdraw
   *
   * @return fee The withdrawal fee (1e18 factor) on success
   */
  function onWithdraw(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Returns the paused state of the calling farm
   */
  function paused() external view returns (bool);

  /**
   * @dev Distribute rewards to sender and fee to internal contracts
   */
  function payOutRewards(address recipient, uint256 amount) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import './IController.sol';

interface IFarm {
  /**
   * @dev Return the farm's controller
   */
  function controller() external view returns (IController);

  /**
   * @dev Return a unique, case-sensitive farm name
   */
  function farmName() external view returns (string memory);

  /**
   * @dev Return when reward period is finished (UTC timestamp)
   */
  function periodFinish() external view returns (uint256);

  /**
   * @dev Return the rewards duration in seconds
   */
  function rewardsDuration() external view returns (uint256);

  /**
   * @dev Sets a new controller, can only be called by current controller
   */
  function setController(address newController) external;

  /**
   * @dev This function must be called initially and close at the time the
   * reward period ends
   */
  function notifyRewardAmount(uint256 reward) external;

  /**
   * @dev Set the duration of farm rewards, to continue rewards,
   * notifyRewardAmount() has to called for the next period
   */
  function setRewardsDuration(uint256 _rewardsDuration) external;

  /**
   * @dev Set the weight of investment token relative to 0
   */
  function weightSlotId(uint256 slotId, uint256 weight) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

/**
 * @title IStakeFarm
 *
 * @dev IStakeFarm is the business logic interface to staking farms.
 */

interface IStakeFarm {
  /**
   * @dev Stake amount of ERC20 tokens and earn rewards
   */
  function stake(uint256 amount) external;

  /**
   * @dev Unstake amount of previous staked tokens, rewards will not be claimed
   */
  function unstake(uint256 amount) external;

  /**
   * @dev Claim rewards harvested during stake time
   */
  function getReward() external;

  /**
   * @dev Unstake and getRewards in a single step
   */
  function exit() external;

  /**
   * @dev Transfer amount of stake from msg.sender to recipient.
   */
  function transfer(address recipient, uint256 amount) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  // solhint-disable-next-line func-name-mixedcase
  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Capped.sol';

import '../../interfaces/uniswap/IUniswapV2Router02.sol';
import '../../interfaces/uniswap/IUniswapV2Factory.sol';
import '../../interfaces/uniswap/IUniswapV2Pair.sol';

import '../investment/interfaces/ITxWorker.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IERC20WowsMintable.sol';

contract WowsToken is IERC20WowsMintable, ERC20Capped, AccessControl {
  using SafeMath for uint256;

  /**
   * @dev The ERC 20 token name used by wallets to identify the token
   */
  string private constant TOKEN_NAME = 'Wolves Of Wall Street';

  /**
   * @dev The ERC 20 token symbol used as an abbreviation of the token, such
   * as BTC, ETH, AUG or SJCX.
   */
  string private constant TOKEN_SYMBOL = 'WOWS';

  /**
   * @dev The number of decimal places to which the token will be calculated.
   * The most common number of decimals to consider is 18.
   */
  uint8 private constant TOKEN_DECIMALS = 18;

  /**
   * @dev 60.000 tokens maximal supply
   */
  uint256 private constant MAX_SUPPLY = 60_000 * 1e18;

  /**
   * @dev Role to allow minting of new tokens
   */
  bytes32 public constant MINTER_ROLE = 'minter_role';

  address public immutable uniV2Pair;
  bytes32 private immutable _uniV2PairCodeHash;

  /**
   * @dev transaction worker for low gas service tasks
   */
  ITxWorker public txWorker;

  /**
   * @dev If false, this pair is blocked
   */
  mapping(address => bool) private _uniV2Whitelist;

  /**
   * @dev Construct a token instance
   *
   * @param _addressRegistry registry to get required contracts
   */
  constructor(IAddressRegistry _addressRegistry)
    ERC20Capped(MAX_SUPPLY)
    ERC20(TOKEN_NAME, TOKEN_SYMBOL)
  {
    // Initialize ERC20 base
    _setupDecimals(TOKEN_DECIMALS);

    /*
     * Mint 3600 into teams wallet
     *
     *   1.) 1800 token for development costs (audits / bug-bounty ...)
     *   2.) 1800 token for marketing (influencer / design ...)
     */
    // reverts if address is invalid
    address marketingWallet = _addressRegistry.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    _mint(marketingWallet, 3600 * 1e18);

    /*
     * Mint 7500 token into teams wallet
     *
     *   1.) 500 tokens * 15 month = 7500 team rewards
     */
    // reverts if address is invalid
    address teamWallet = _addressRegistry.getRegistryEntry(
      AddressBook.TEAM_WALLET
    );
    _mint(teamWallet, 7500 * 1e18);

    // Multi-sig marketing wallet gets admin rights
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);

    // Reverts if address is invalid
    IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(
      _addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_ROUTER02)
    );

    // Create the UniV2 liquidity pool
    address _uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(
      address(this),
      _uniV2Router.WETH()
    );
    uniV2Pair = _uniV2Pair;

    // Retrieve the code hash of UniV2 pair which is same for all other univ2 pairs
    bytes32 codeHash;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codeHash := extcodehash(_uniV2Pair)
    }
    _uniV2PairCodeHash = codeHash;
  }

  /**
   * @dev Mint tokens
   *
   * @param account The account to receive the tokens
   * @param amount The amount to mint
   *
   * @return True if successful, reverts on failure
   */
  function mint(address account, uint256 amount)
    external
    override
    returns (bool)
  {
    // Mint is only allowed by addresses with minter role
    require(hasRole(MINTER_ROLE, msg.sender), 'Only minters');

    _mint(account, amount);

    return true;
  }

  /**
   * @dev Add ETH/WOLF univ2 pair address to whitelist
   *
   * @param enable True to enable the univ2 pair, false to disable
   */
  function enableUniV2Pair(bool enable) external override {
    require(hasRole(MINTER_ROLE, msg.sender), 'Only minters');
    _uniV2Whitelist[uniV2Pair] = enable;
  }

  /**
   * @dev Add univ2 pair address to whitelist
   *
   * @param pairAddress The address of the univ2 pair
   */
  function enableUniV2Pair(address pairAddress) external {
    require(
      hasRole(MINTER_ROLE, msg.sender) ||
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      'Only minters and admins'
    );
    _uniV2Whitelist[pairAddress] = true;
  }

  /**
   * @dev Remove univ2 pair address from whitelist
   */
  function disableUniV2Pair(address pairAddress) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');
    _uniV2Whitelist[pairAddress] = false;
  }

  /**
   * @dev Request the state of the univ2 pair address
   */
  function isUniV2PairEnabled(address pairAddress)
    external
    view
    returns (bool)
  {
    return _uniV2Whitelist[pairAddress];
  }

  /**
   * @dev Override to prevent creation of uniswap LP's with WOLF token
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    // Minters are always allowed to transfer
    require(
      hasRole(MINTER_ROLE, sender) ||
        hasRole(MINTER_ROLE, recipient) ||
        (_checkForUniV2Pair(sender) && _checkForUniV2Pair(recipient)),
      'Only minters and != pairs'
    );
    super._transfer(sender, recipient, amount);

    // check for low gas tasks
    if (address(txWorker) != address(0)) txWorker.onTransaction(0);
  }

  /**
   * @dev Check if recipient is either on the whitelist, or not an UniV2 pair
   *
   * Only minter and admin role are allowed to enable initial blacklisted
   * pairs. Goal is to let us initialize uniV2 pairs with a ratio defined
   * from concept.
   */
  function _checkForUniV2Pair(address recipient) public view returns (bool) {
    // Early exit if recipient is already whitelisted
    if (_uniV2Whitelist[recipient]) return true;

    // Compare contract code of recipient with
    bytes32 codeHash;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codeHash := extcodehash(recipient)
    }

    // Return true, if codehash != uniV2PairCodeHash
    return codeHash != _uniV2PairCodeHash;
  }

  function setTXWorker(address _txWorker) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');
    txWorker = ITxWorker(_txWorker);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

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

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap_) internal {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= cap(), "ERC20Capped: cap exceeded");
        }
    }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

/**
 * @title ITxWorker
 *
 * @dev ITxWorker is used to create contracts which need transactions
 * to perform maintance tasks. These tasks should be low gas as possible
 * to prevent expensive transaction for the users
 */

interface ITxWorker {
  /**
   * @dev called from external / public functions
   *
   * @param gasLevel level between 0 and 255 about how much gas can be
   * consumed. Implementation dependent. 0 = low gas
   */
  function onTransaction(uint8 gasLevel) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20WowsMintable is IERC20 {
  function mint(address account, uint256 amount) external returns (bool);

  function enableUniV2Pair(bool enable) external;
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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function WETH() external pure returns (address);

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

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
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
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../../interfaces/uniswap/IUniswapV2Router02.sol';
import '../../src/investment/interfaces/IRewardHandler.sol';
import '../../src/token/interfaces/IERC20WowsMintable.sol';
import '../../src/utils/AddressBook.sol';
import '../../src/utils/interfaces/IAddressRegistry.sol';

contract RewardHandler is Context, AccessControl, IRewardHandler {
  using SafeMath for uint256;
  using SafeERC20 for IERC20WowsMintable;

  //////////////////////////////////////////////////////////////////////////////
  // Roles
  //////////////////////////////////////////////////////////////////////////////

  // Role granted to distribute funds
  bytes32 public constant REWARD_ROLE = 'reward_role';

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // The fee is distributed to 4 channels:
  // 0.15 team
  uint32 private constant FEE_TO_TEAM = 15 * 1e4;
  // 0.15 marketing
  uint32 private constant FEE_TO_MARKETING = 15 * 1e4;
  // 0.4 booster
  uint32 private constant FEE_TO_BOOSTER = 4 * 1e5;
  // 0.3 back to reward pool (remaining fee remains in contract)
  // uint32 private constant FEE_TO_REWARDPOOL = 3 * 1e5;

  // Duration of one hour, in seconds
  uint32 private constant ONE_HOUR = 3600;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Minimal mint amount
  uint256 private _minimalMintAmount = 100 * 1e18;

  // Registry for addresses in the system
  IAddressRegistry private immutable _addressRegistry;

  // Amount to distribute
  uint256 private _distributeAmount;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Fired if we receive Ether
   */
  event Received(address, uint256);

  /**
   * @dev Fired on distribute (rewards -> recipient)
   */
  event RewardsDistributed(address indexed, uint256 amount, uint32 fee);

  /**
   * @dev Fired on distributeAll (collected fees -> internal)
   */
  event FeesDistributed(uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructor
   *
   * @param addressRegistry The registry for addresses in the system
   */
  constructor(IAddressRegistry addressRegistry) {
    // Initialize access
    address marketingWallet = addressRegistry.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);

    // Initialize state
    _addressRegistry = addressRegistry;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Public API
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the minimal mint amount to save mint calls
   *
   * @param newAmount The new minimal amount before mint() is called
   */
  function setMinimalMintAmount(uint256 newAmount) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    // Update state
    _minimalMintAmount = newAmount;
  }

  /**
   * @dev Distribute _distributeAmount to internal targets
   */
  function distributeAll() external {
    // Validate state
    require(_distributeAmount > 0, 'Nothing to distribute');

    _distribute();
  }

  /**
   * @dev Distribute _distributeAmount to internal targets, transfer all WOWS
   * to the new reward handler, and (optionally) destroy this contract
   *
   * @param newRewardHandler The reward handler that succeeds this one
   * @param destroy True to destroy this contract, false to distribute without
   * destroying
   */
  function terminate(address newRewardHandler, bool destroy) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    // Validate parameters
    require(newRewardHandler != address(0), "Can't transfer to address 0");

    // Distribute remaining fees
    IERC20WowsMintable rewardToken = _distribute();

    // Transfer WOWS to the new rewardHandler
    uint256 amountRewards = rewardToken.balanceOf(address(this));
    if (amountRewards > 0)
      rewardToken.safeTransfer(newRewardHandler, amountRewards);

    // Destroy contract
    if (destroy) {
      // Disable high-impact Slither detector "suicidal" here. Slither explains
      // that "RewardHandler.terminate() allows anyone to destruct the
      // contract", which is not the case due to validatation of the sender
      // having the {AccessControl-DEFAULT_ADMIN_ROLE} role.
      //
      // slither-disable-next-line suicidal
      selfdestruct(payable(newRewardHandler));
    }
  }

  /**
   * @dev Swap ETH or ERC20 token into rewardToken
   *
   * tokenAddress cannot be rewardToken.
   *
   * @param route Path containing ERC20 token addresses to swap route[0] into
   * reward tokens. The last address must be rewardToken address.
   */
  function swapIntoRewardToken(address[] calldata route) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    address rewardToken = _addressRegistry.getRegistryEntry(
      AddressBook.WOWS_TOKEN
    );

    // Get the UniV2 Router
    IUniswapV2Router02 router = IUniswapV2Router02(
      _addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_ROUTER02)
    );

    // Check for ETH swap (no route given)
    if (route.length == 0) {
      // Validate state
      uint256 amountETH = payable(address(this)).balance;
      require(amountETH > 0, 'Insufficient amount');

      address[] memory ethRoute = new address[](2);
      ethRoute[0] = router.WETH();
      ethRoute[1] = rewardToken;

      // Disable high-impact Slither detector "arbitrary-send" here. Slither
      // recommends that programmers "Ensure that an arbitrary user cannot
      // withdraw unauthorized funds." We accomplish this by using access
      // control to prevent unauthorized modification of the destination.
      //
      // slither-disable-next-line arbitrary-send
      uint256[] memory amounts = router.swapExactETHForTokens{
        value: amountETH
      }(
        0,
        ethRoute,
        address(this),
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + ONE_HOUR
      );

      // Update state
      _distributeAmount = _distributeAmount.add(amounts[1]);
    } else {
      // Validate parameters
      require(route.length >= 2, 'Invalid route');
      require(
        route[route.length - 1] == address(rewardToken),
        'Route terminator != rewardToken'
      );

      // Validate state
      uint256 amountToken = IERC20(route[0]).balanceOf(address(this));
      require(amountToken > 0, 'Insufficient amount');

      uint256[] memory amounts = router.swapExactTokensForTokens(
        amountToken,
        0,
        route,
        address(this),
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + ONE_HOUR
      );

      // Update state
      _distributeAmount = _distributeAmount.add(amounts[route.length - 1]);
    }
  }

  // We can receive ether and swap it later to rewardToken
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IRewardHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IRewardHandler-getBoosterRewards}
   */
  function getBoosterRewards() external view override returns (uint256) {
    IERC20WowsMintable rewardToken = IERC20WowsMintable(
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
    );
    address booster = _addressRegistry.getRegistryEntry(
      AddressBook.WOWS_BOOSTER_PROXY
    );
    return
      rewardToken.balanceOf(booster).add(
        _distributeAmount.mul(FEE_TO_BOOSTER).div(1e6)
      );
  }

  /**
   * @dev See {IRewardHandler-distribute2}
   */
  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) public override {
    // Validate access
    require(hasRole(REWARD_ROLE, _msgSender()), 'Only rewarders');

    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // If amount is zero there's nothing to do
    if (amount == 0) return;

    IERC20WowsMintable rewardToken = IERC20WowsMintable(
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
    );

    // Calculate absolute fee
    uint256 absFee = amount.mul(fee).div(1e6);

    // Calculate amount to send to the recipient
    uint256 recipientAmount = amount.sub(absFee);

    // Update state with accumulated fee to be distributed
    _distributeAmount = _distributeAmount.add(absFee);

    if (recipientAmount > 0) {
      // Check how much we have to mint
      uint256 balance = rewardToken.balanceOf(address(this));

      // Mint to this contract
      if (balance < recipientAmount) {
        uint256 mintAmount = recipientAmount > _minimalMintAmount
          ? recipientAmount
          : _minimalMintAmount;
        rewardToken.mint(address(this), mintAmount);
      }

      // Now send rewards to the user
      rewardToken.safeTransfer(recipient, recipientAmount);
    }
    // Emit event
    emit RewardsDistributed(recipient, amount, fee);
  }

  /**
   * @dev See {IRewardHandler-distribute}
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint32 fee,
    uint32,
    uint32,
    uint32,
    uint32
  ) external override {
    // Forward to new distribution function
    distribute2(recipient, amount, fee);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Distribute the accumulated fees
   *
   * @return The WOWS token address
   */
  function _distribute() internal returns (IERC20WowsMintable) {
    IERC20WowsMintable rewardToken = IERC20WowsMintable(
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
    );

    if (_distributeAmount > 0) {
      // Load addresses
      address marketingWallet = _addressRegistry.getRegistryEntry(
        AddressBook.MARKETING_WALLET
      );
      address teamWallet = _addressRegistry.getRegistryEntry(
        AddressBook.TEAM_WALLET
      );
      address booster = _addressRegistry.getRegistryEntry(
        AddressBook.WOWS_BOOSTER_PROXY
      );

      // Load state
      uint256 distributeAmount = _distributeAmount;

      // Update state
      _distributeAmount = 0;

      // Check how much / if we have to mint
      uint256 balance = rewardToken.balanceOf(address(this));
      if (balance < distributeAmount)
        rewardToken.mint(address(this), distributeAmount.sub(balance));

      // Distribute the fee
      rewardToken.safeTransfer(
        teamWallet,
        distributeAmount.mul(FEE_TO_TEAM).div(1e6)
      );
      rewardToken.safeTransfer(
        marketingWallet,
        distributeAmount.mul(FEE_TO_MARKETING).div(1e6)
      );
      rewardToken.safeTransfer(
        booster,
        distributeAmount.mul(FEE_TO_BOOSTER).div(1e6)
      );

      // Emit event
      emit FeesDistributed(distributeAmount);
    }
    return rewardToken;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/proxy/UpgradeableProxy.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

contract UpgradeProxy is Context, UpgradeableProxy {
  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 private constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Emitted when the admin account has changed.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
   */
  modifier ifAdmin() {
    if (_msgSender() == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    IAddressRegistry addressRegistry_,
    address _logic,
    bytes memory _data
  ) UpgradeableProxy(_logic, _data) {
    assert(
      _ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    );
    // Initialize {AccessControl}
    address marketingWallet = addressRegistry_.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    _setAdmin(marketingWallet);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Upgrade the implementation of the proxy.
   *
   * NOTE: Only the admin can call this function.
   */
  function upgradeTo(address newImplementation) external virtual ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
   * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
   * proxied contract.
   *
   * NOTE: Only the admin can call this function.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    virtual
    ifAdmin
  {
    _upgradeTo(newImplementation);
    Address.functionDelegateCall(newImplementation, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Returns the current admin.
   */
  function _admin() internal view virtual returns (address adm) {
    bytes32 slot = _ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Stores a new address in the EIP1967 admin slot.
   */
  function _setAdmin(address adm) private {
    bytes32 slot = _ADMIN_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, adm)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @dev Extension of OpenZeppelin's {ERC20} that allows anyone to mint tokens
 * to arbitrary accounts.
 *
 * FOR TESTING ONLY.
 */
abstract contract TestERC20Mintable is ERC20 {
  //////////////////////////////////////////////////////////////////////////////
  // Minting interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   */
  function mint(address account, uint256 amount) public {
    // Call ancestor
    _mint(account, amount);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '../token/TestERC20Mintable.sol';

// Mainnet address: 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
// Yearn vault address: 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e
contract USDC is TestERC20Mintable {
  constructor() ERC20('Funny USD Coin', 'USDC') {
    // Initialize {ERC20}
    _setupDecimals(6);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '../token/TestERC20Mintable.sol';

// Mainnet address: 0x0000000000085d4780b73119b644ae5ecd22b376
// Yearn vault address: 0x73a052500105205d34daf004eab301916da8190f
contract TrueUSD is TestERC20Mintable {
  constructor() ERC20('Funny TrueUSD', 'TUSD') {}
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '../token/TestERC20Mintable.sol';

// Mainnet address: 0x6b175474e89094c44da98b954eedeac495271d0f
// Yearn vault address: 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01
contract DAI is TestERC20Mintable {
  constructor() ERC20('Funny Dai Stablecoin', 'DAI') {}
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../utils/ERC20Recovery.sol';

import './interfaces/ICFolioFarm.sol';
import './interfaces/IController.sol';
import './interfaces/IFarm.sol';

/**
 * @notice Farm is owned by a CFolio contract.
 *
 * All state modifing calls are only allowed from this owner.
 */
contract CFolioFarm is IFarm, ICFolioFarm, Ownable, ERC20Recovery {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  uint256 public override periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public override rewardsDuration = 14 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 private availableRewards;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  // Unique name of this farm instance, used in controller
  string private _farmName;

  uint256[] private _totalSupplys;
  uint256[] public slotWeights;

  mapping(address => mapping(uint256 => uint256)) private _balances;

  // The address of the controller
  IController public override controller;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event RewardAdded(uint256 reward);

  event AssetAdded(
    address indexed user,
    uint256 amount,
    uint256 totalAmount,
    uint256 slotId
  );

  event AssetRemoved(
    address indexed user,
    uint256 amount,
    uint256 totalAmount,
    uint256 slotId
  );

  event ShareAdded(address indexed user, uint256 amount, uint256 slotId);

  event ShareRemoved(address indexed user, uint256 amount, uint256 slotId);

  event RewardPaid(
    address indexed account,
    address indexed user,
    uint256 reward
  );

  event RewardsDurationUpdated(uint256 newDuration);

  event ControllerChanged(address newController);

  event SlotWeightChanged(uint256 slotId, uint256 newWeight);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyController() {
    require(_msgSender() == address(controller), 'not controller');
    _;
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();

    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    address _owner,
    string memory _name,
    address _controller
  ) {
    // Validate parameters
    require(_owner != address(0), 'Invalid owner');
    require(_controller != address(0), 'Invalid controller');

    // Initialize {Ownable}
    transferOwnership(_owner);

    // Initialize state
    _farmName = _name;
    controller = IController(_controller);
    // TotalSupply for slot 0
    _totalSupplys.push(0);
    slotWeights.push(1E18);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Views
  //////////////////////////////////////////////////////////////////////////////

  function farmName() external view override returns (string memory) {
    return _farmName;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply();
  }

  function balanceOf(address account, uint256 slotId)
    external
    view
    override
    returns (uint256)
  {
    return _balances[account][slotId];
  }

  function balancesOf(address account)
    external
    view
    override
    returns (uint256[] memory result)
  {
    uint256 _slotCount = slotWeights.length;
    result = new uint256[](_slotCount);
    for (uint256 slotId = 0; slotId < _slotCount; ++slotId)
      result[slotId] = _balances[account][slotId];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function rewardPerToken() public view returns (uint256) {
    uint256 ts = _totalSupply();
    if (ts == 0) {
      return rewardPerTokenStored;
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(ts)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      _balance(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  function getUIData(address account)
    external
    view
    override
    returns (uint256[5] memory)
  {
    uint256[5] memory result = [
      _totalSupply(),
      _balance(account),
      rewardsDuration,
      rewardRate.mul(rewardsDuration),
      earned(account)
    ];
    return result;
  }

  function slotCount() external view override returns (uint256) {
    return slotWeights.length;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Mutators
  //////////////////////////////////////////////////////////////////////////////

  function addAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external override onlyOwner {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot add 0');
    require(!controller.paused(), 'CFolioFarm: Controller paused');

    // Update state
    _balances[account][slotId] = _balances[account][slotId].add(amount);

    // Dispatch event
    emit AssetAdded(account, amount, _balances[account][slotId], slotId);
  }

  function removeAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external override onlyOwner {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot remove 0');

    // Update state
    _balances[account][slotId] = _balances[account][slotId].sub(amount);

    // Dispatch event
    emit AssetRemoved(account, amount, _balances[account][slotId], slotId);
  }

  function addShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external override onlyOwner updateReward(account) {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot add 0');
    require(!controller.paused(), 'CFolioFarm: Controller paused');
    require(slotId < slotWeights.length, 'CFolioFarm: Invalid slotId');

    // Update state
    _totalSupplys[slotId] = _totalSupplys[slotId].add(amount);
    _balances[account][slotId] = _balances[account][slotId].add(amount);

    // Notify controller
    controller.onDeposit(amount);

    // Dispatch event
    emit ShareAdded(account, amount, slotId);
  }

  function removeShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) public override onlyOwner updateReward(account) {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot remove 0');
    require(slotId < slotWeights.length, 'CFolioFarm: Invalid slotId');

    // Update state
    _totalSupplys[slotId] = _totalSupplys[slotId].sub(amount);
    _balances[account][slotId] = _balances[account][slotId].sub(amount);

    // Notify controller
    controller.onWithdraw(amount);

    // Dispatch event
    emit ShareRemoved(account, amount, slotId);
  }

  function getReward(address account, address rewardRecipient)
    public
    override
    onlyOwner
    updateReward(account)
  {
    // Load state
    uint256 reward = rewards[account];

    if (reward > 0) {
      // Update state
      rewards[account] = 0;
      availableRewards = availableRewards.sub(reward);

      // Notify controller
      controller.payOutRewards(rewardRecipient, reward);

      // Dispatch event
      emit RewardPaid(account, rewardRecipient, reward);
    }
  }

  function weightSlotId(uint256 slotId, uint256 weight)
    external
    override
    onlyController
    updateReward(address(0))
  {
    uint256 _slotCount = slotWeights.length;
    require(slotId <= _slotCount, 'CFolioFarm: Invalid slotId');
    if (slotId == _slotCount) {
      _totalSupplys.push(0);
      slotWeights.push(weight);
    } else slotWeights[slotId] = weight;

    // Emit event
    emit SlotWeightChanged(slotId, weight);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Migrate functions
  //////////////////////////////////////////////////////////////////////////////

  function migrateSetAccountState(
    address account_,
    uint256 amount_,
    uint256 earned_
  ) external override onlyOwner {
    if (amount_ > 0) _balances[account_][0] = amount_;
    if (earned_ > 0) rewards[account_] = earned_;
  }

  function migrateSetGlobalState(
    uint256 totalSupply_,
    uint256 availableRewards_
  ) external override onlyOwner {
    _totalSupplys[0] = totalSupply_;
    availableRewards = availableRewards_;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Restricted functions
  //////////////////////////////////////////////////////////////////////////////

  function setController(address newController)
    external
    override
    onlyController
  {
    // Update state
    controller = IController(newController);

    // Dispatch event
    emit ControllerChanged(newController);

    if (newController == address(0))
      // slither-disable-next-line suicidal
      selfdestruct(payable(msg.sender));
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyController
    updateReward(address(0))
  {
    // Update state
    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      // solhint-disable-next-line not-rely-on-time
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }
    availableRewards = availableRewards.add(reward);

    // Validate state
    //
    // Ensure the provided reward amount is not more than the balance in the
    // contract.
    //
    // This keeps the reward rate in the right range, preventing overflows due
    // to very high values of rewardRate in the earned and rewardsPerToken
    // functions.
    //
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    //
    require(
      rewardRate <= availableRewards.div(rewardsDuration),
      'Provided reward too high'
    );

    // Update state
    // solhint-disable-next-line not-rely-on-time
    lastUpdateTime = block.timestamp;
    // solhint-disable-next-line not-rely-on-time
    periodFinish = block.timestamp.add(rewardsDuration);

    // Dispatch event
    emit RewardAdded(reward);
  }

  /**
   * @dev Added to support recovering LP Rewards from other systems to be
   * distributed to holders
   */
  function recoverERC20(
    address recipient,
    address tokenAddress,
    uint256 tokenAmount
  ) external onlyController {
    // Call ancestor
    _recoverERC20(recipient, tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration)
    external
    override
    onlyController
  {
    // Validate state
    require(
      // solhint-disable-next-line not-rely-on-time
      periodFinish == 0 || block.timestamp > periodFinish,
      'Reward period not finished'
    );

    // Update state
    rewardsDuration = _rewardsDuration;

    // Dispatch event
    emit RewardsDurationUpdated(rewardsDuration);
  }

  function _totalSupply() private view returns (uint256 ts) {
    ts = 0;
    for (uint256 i = 0; i < slotWeights.length; ++i)
      ts += _totalSupplys[i] * slotWeights[i];
    ts /= 1E18;
  }

  function _balance(address account) private view returns (uint256 balance) {
    balance = 0;
    mapping(uint256 => uint256) storage balances = _balances[account];

    for (uint256 i = 0; i < slotWeights.length; ++i)
      balance += balances[i] * slotWeights[i];
    balance /= 1e18;
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

/**
 * @title ICFolioFarm
 *
 * @dev ICFolioFarm is the business logic interface to c-folio farms.
 */
interface ICFolioFarm {
  /**
   * @dev Return number of slots
   */
  function slotCount() external view returns (uint256);

  /**
   * @dev Return total invested balance
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Return invested balance of account
   */
  function balanceOf(address account, uint256 slotId)
    external
    view
    returns (uint256);

  /**
   * @dev Return invested balances per slot of account
   */
  function balancesOf(address account) external view returns (uint256[] memory);

  /**
   * @dev Return total, balances[account], rewardDuration, rewardForDuration, earned[account]
   */
  function getUIData(address account) external view returns (uint256[5] memory);

  /**
   * @dev Increase amount of non-rewarded asset
   */
  function addAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Remove amount of previous added assets
   */
  function removeAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Increase amount of shares and earn rewards
   */
  function addShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Remove amount of previous added shares, rewards will not be claimed
   */
  function removeShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Claim rewards harvested during reward time
   */
  function getReward(address account, address rewardRecipient) external;

  /**
   * @dev Migrate shares / assets and rewards per account
   */
  function migrateSetAccountState(
    address account_,
    uint256 amount_,
    uint256 earned_
  ) external;

  /**
   * @dev Finalize migration, set summed amounts
   */
  function migrateSetGlobalState(
    uint256 totalSupply_,
    uint256 availableRewards_
  ) external;
}

/**
 * @title ICFolioFarmOwnable
 */

interface ICFolioFarmOwnable is ICFolioFarm {
  /**
   * @dev Transfer ownership
   */
  function transferOwnership(address newOwner) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../booster/interfaces/IBooster.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IController.sol';
import './interfaces/IFarm.sol';

contract Controller is IController, Context, Ownable {
  using SafeMath for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  IBooster private immutable _booster;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // We need the previous controller for calculation of pending rewards
  address public previousController;

  // The address which is alowed to call service functions
  address public worker;

  address private farmHead;
  struct Farm {
    address nextFarm;
    uint256 farmStartedAtBlock;
    uint256 farmEndedAtBlock;
    uint256 rewardCap;
    uint256 rewardProvided;
    uint256 rewardPerDuration;
    uint32 rewardFee;
    bool paused;
    bool active;
  }

  mapping(address => Farm) public farms;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event FarmRegistered(address indexed farm, bool paused);

  event FarmUpdated(address indexed farm);

  event FarmDisabled(address indexed farm);

  event FarmPaused(address indexed farm, bool pause);

  event FarmTransfered(address indexed farm, address indexed to);

  event Refueled(address indexed farm, uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyWorker() {
    require(_msgSender() == worker, 'not worker');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev rewardHandler is the instance which finally stores the reward token
   * and distributes them to the different recipients
   *
   * @param _addressRegistry IAdressRegistry to get system addresses
   * @param _previousController The previous controller
   */
  constructor(IAddressRegistry _addressRegistry, address _previousController) {
    // Initialize state
    previousController = _previousController;

    // Proxied booster address / immutable
    _booster = IBooster(
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_BOOSTER_PROXY)
    );

    // Initialize {Ownable}
    address _marketingWallet = _addressRegistry.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    transferOwnership(_marketingWallet);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  function setWorker(address _worker) external onlyOwner {
    worker = _worker;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IController}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IController-onDeposit}
   */
  function onDeposit(
    uint256 /* amount*/
  ) external view override returns (uint256 fee) {
    // Load state
    Farm storage farm = farms[_msgSender()];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Caller not a farm');
    require(farm.farmEndedAtBlock == 0, 'Farm closed');
    require(!farm.paused, 'Farm paused');

    return 0;
  }

  /**
   * @dev See {IController-onDeposit}
   */
  function onWithdraw(
    uint256 /* amount*/
  ) external view override returns (uint256 fee) {
    // Validate state
    require(!farms[_msgSender()].paused, 'Farm paused');

    return 0;
  }

  /**
   * @dev See {IController-paused}
   */
  function paused() external view override returns (bool) {
    return farms[_msgSender()].paused;
  }

  /**
   * @dev See {IController-payOutRewards}
   */
  function payOutRewards(address recipient, uint256 amount) external override {
    // Load state
    Farm storage farm = farms[_msgSender()];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Caller not a farm');
    require(recipient != address(0), 'Recipient 0 address');
    require(!farm.paused, 'Farm paused');
    require(
      amount.add(farm.rewardProvided) <= farm.rewardCap,
      'Reward cap reached'
    );

    // Update state
    _booster.distributeFromFarm(
      _msgSender(),
      recipient,
      amount,
      farm.rewardFee
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Farm management
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev registerFarm2 can be called from outside (for new Farms deployed with
   * this controller) or from transferFarm() call
   *
   * Contracts are active from the time of registering, but to provide rewards,
   * refuelFarms must be called (for new Farms / due Farms).
   *
   * Use this function also for updating reward parameters and / or fee.
   * _rewardProvided should be left 0, it is mainly used if a farm is
   * transferred.
   *
   * @param _farmAddress Contract address of farm
   * @param _rewardCap Maximum amount of tokens rewardable
   * @param _rewardPerDuration Refuel amount of tokens, duration is fixed in
   * farm contract
   * @param _rewardProvided Already provided rewards for this farm, should be 0
   * for external calls
   * @param _rewardFee Fee we take from the reward and distribute through
   * components (1e6 factor)
   * @param _farmEnd timestamp when farm was disabled (usually 0)
   */
  function registerFarm2(
    address _farmAddress,
    uint256 _rewardCap,
    uint256 _rewardPerDuration,
    uint256 _rewardProvided,
    uint32 _rewardFee,
    uint256 _farmEnd,
    bool _paused
  ) public {
    // Validate access
    require(
      _msgSender() == owner() || _msgSender() == previousController,
      'Not allowed'
    );

    // Validate parameters
    require(_farmAddress != address(0), 'Invalid farm (0)');
    require(IFarm(_farmAddress).controller() == this, 'Invalid farm (C)');

    // Farm existent, add new reward logic
    Farm storage farm = farms[_farmAddress];
    if (farm.farmStartedAtBlock > 0) {
      // Re-enable farm if disabled
      farm.farmEndedAtBlock = _farmEnd;
      farm.paused = false;
      farm.active = !_paused && _farmEnd == 0;
      farm.rewardCap = _rewardCap;
      farm.rewardFee = _rewardFee;
      farm.rewardPerDuration = _rewardPerDuration;
      if (_rewardProvided > 0) farm.rewardProvided = _rewardProvided;

      // Dispatch event
      emit FarmUpdated(_farmAddress);
    }
    // We have a new farm
    else {
      // If we have one with same name, deactivate old one
      bytes32 farmName = keccak256(
        abi.encodePacked(IFarm(_farmAddress).farmName())
      );
      address searchAddress = farmHead;
      while (
        searchAddress != address(0) &&
        farmName != keccak256(abi.encodePacked(IFarm(searchAddress).farmName()))
      ) searchAddress = farms[searchAddress].nextFarm;

      // If found (update), disable existing farm
      if (searchAddress != address(0)) {
        farms[searchAddress].farmEndedAtBlock = block.number;
        _rewardProvided = farms[searchAddress].rewardProvided;
      }

      // Insert the new Farm
      farm.nextFarm = farmHead;
      farm.farmStartedAtBlock = block.number;
      farm.farmEndedAtBlock = _farmEnd;
      farm.rewardCap = _rewardCap;
      farm.rewardProvided = _rewardProvided;
      farm.rewardPerDuration = _rewardPerDuration;
      farm.rewardFee = _rewardFee;
      farm.paused = _paused;
      farm.active = !_paused && _farmEnd == 0;
      farmHead = _farmAddress;

      // Dispatch event
      emit FarmRegistered(_farmAddress, _paused);
    }
  }

  /*
   * @dev backwards compatibility, see registerFarm2
   */
  function registerFarm(
    address _farmAddress,
    uint256 _rewardCap,
    uint256 _rewardPerDuration,
    uint256 _rewardProvided,
    uint32 _rewardFee
  ) external {
    registerFarm2(
      _farmAddress,
      _rewardCap,
      _rewardPerDuration,
      _rewardProvided,
      _rewardFee,
      0,
      false
    );
  }

  /**
   * @dev Note that disabled farms can only be enabled again by calling
   * registerFarm2() with new parameters
   *
   * This function is meant to finally end a farm.
   *
   * @param _farmAddress Contract address of farm to disable
   */
  function disableFarm(address _farmAddress) external onlyOwner {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Not a farm');

    // Update state
    farm.farmEndedAtBlock = block.number;

    // Dispatch event
    emit FarmDisabled(_farmAddress);

    _checkActive(farm);
  }

  /**
   * @dev This is an emergency pause, which should be called in case of serious
   * issues.
   *
   * Deposit / withdraw and rewards are disabled while pause is set to true.
   *
   * @param _farmAddress Contract address of farm to pause
   * @param _pause To pause / unpause a farm
   */
  function pauseFarm(address _farmAddress, bool _pause) external onlyOwner {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Not a farm');

    // Update state
    farm.paused = _pause;

    // Dispatch event
    emit FarmPaused(_farmAddress, _pause);

    _checkActive(farm);
  }

  /**
   * @dev Transfer farm to a new controller
   *
   * @param _farmAddress Contract address of farm to transfer
   * @param _newController The new controller which receives the farm
   */
  function transferFarm(address _farmAddress, address _newController)
    external
    onlyOwner
  {
    // Validate parameters
    require(_newController != address(0), 'newController = 0');
    require(_newController != address(this), 'newController = this');

    _transferFarm(_farmAddress, _newController);
  }

  /**
   * @dev Unlinks a farm (set controller to 0)
   *
   * @param _farmAddress Contract address of farm to transfer
   */
  function unlinkFarm(address _farmAddress) external onlyOwner {
    _transferFarm(_farmAddress, address(0));
  }

  /**
   * @dev Transfer all existing farms to a new controller
   *
   * @param _newController The new controller which receives the farms
   */
  function transferAllFarms(address _newController) external onlyOwner {
    require(_newController != address(0), 'newController = 0');
    require(_newController != address(this), 'newController = this');

    while (farmHead != address(0)) {
      _transferFarm(farmHead, _newController);
    }
  }

  /**
   * @dev Change the reward duration in a Farm
   *
   * @param farmAddress Contract address of farm to change duration
   * @param newDuration The new reward duration in seconds
   *
   * @notice In general a farm has to be in finished state to be able
   * to change the duration
   */
  function setFarmRewardDuration(address farmAddress, uint256 newDuration)
    external
    onlyOwner
  {
    // Validate parameters
    require(IFarm(farmAddress).controller() == this, 'Invalid farm (C)');

    // Update state
    IFarm(farmAddress).setRewardsDuration(newDuration);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Utility functions
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Refuel all farms which will expire in the next hour
   *
   * By default the preconfigured rewardPerDuration is used, but can be
   * overridden by rewards parameter.
   *
   * @notice If rewards parameer is provided, the value cannot exceed the
   * preconfigured rewardPerDuration.
   *
   * @param addresses Addresses to be used instead rewardPerDuration
   * @param rewards Amonts to be used instead rewardPerDuration
   */
  function refuelFarms(address[] calldata addresses, uint256[] calldata rewards)
    external
    onlyWorker
  {
    // Validate parameters
    require(addresses.length == rewards.length, 'C: Length mismatch');

    address iterAddress = farmHead;
    bool oneRefueled = false;
    while (iterAddress != address(0)) {
      // Refuel if farm end is one day ahead
      Farm storage farm = farms[iterAddress];

      if (
        farm.active &&
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + 3600 >= IFarm(iterAddress).periodFinish()
      ) {
        // Check for reward override
        uint256 i;
        while (i < addresses.length && addresses[i] != iterAddress) ++i;

        uint256 reward = (i < addresses.length &&
          rewards[i] < farm.rewardPerDuration)
          ? rewards[i]
          : farm.rewardPerDuration;

        // Update state
        IFarm(iterAddress).notifyRewardAmount(reward);
        farm.rewardProvided = farm.rewardProvided.add(reward);

        require(farm.rewardProvided <= farm.rewardCap, 'C: Cap reached');

        // Dispatch event
        emit Refueled(iterAddress, reward);

        oneRefueled = true;
      }
      iterAddress = farm.nextFarm;
    }
    require(oneRefueled, 'NOP');
  }

  function weightSlotWeights(
    address[] calldata _farms,
    uint256[] calldata slotIds,
    uint256[] calldata weights
  ) external onlyWorker {
    require(
      _farms.length == slotIds.length && _farms.length == weights.length,
      'C: Length mismatch'
    );
    for (uint256 i = 0; i < _farms.length; ++i) {
      require(farms[_farms[i]].farmStartedAtBlock != 0, 'C: Invalid farm');
      IFarm(_farms[i]).weightSlotId(slotIds[i], weights[i]);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Shortcut to check if a farm is active
   */
  function _checkActive(Farm storage farm) internal {
    farm.active = !(farm.paused || farm.farmEndedAtBlock > 0);
  }

  function _transferFarm(address _farmAddress, address _newController) private {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Farm not registered');

    // Update state
    IFarm(_farmAddress).setController(_newController);

    // Register this farm in the new controller
    if (_newController != address(0)) {
      Controller(_newController).registerFarm2(
        _farmAddress,
        farm.rewardCap,
        farm.rewardPerDuration,
        farm.rewardProvided,
        farm.rewardFee,
        farm.farmEndedAtBlock,
        farm.paused
      );
    }

    // Remove this farm from controller
    if (_farmAddress == farmHead) {
      farmHead = farm.nextFarm;
    } else {
      address searchAddress = farmHead;
      while (farms[searchAddress].nextFarm != _farmAddress)
        searchAddress = farms[searchAddress].nextFarm;
      farms[searchAddress].nextFarm = farm.nextFarm;
    }

    delete (farms[_farmAddress]);

    // Dispatch event
    emit FarmTransfered(_farmAddress, _newController);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '../../0xerc1155/interfaces/IERC1155.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../0xerc1155/utils/SafeMath.sol';
import '../../0xerc1155/access/AccessControl.sol';

import '../investment/interfaces/IRewardHandler.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/TokenIds.sol';

import './interfaces/IBooster.sol';

contract Booster is IBooster, AccessControl {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant CONTROLLER_ROLE = bytes32('CONTROLLER');

  // 30 days in seconds multiplied by 10 (10% per month)
  uint256 private constant MONTHLY_REWARD = 25920000;

  // Maximum rewards provided from tokenomics
  uint256 private constant MAX_TOKENOMICS_REWARDS = 7500000000000000000000;

  // SECONDS PER YEAR
  uint256 private constant SECONDS_PER_YEAR = 360 * 86400;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // The rewardHandler to distribute rewards
  IRewardHandler public rewardHandler;

  // The SFT contract to validate recipients
  IWOWSERC1155 public sftHolder;

  // Our timelock
  struct TimeLock {
    uint256 totalAmount;
    uint256 pendingAmount;
    uint256 providedAmount;
    uint256 last;
    uint256 end;
    uint256 apr;
    uint32 fee;
  }
  mapping(address => TimeLock) public timeLocks;

  // Reward definition (1 / 3 / 6 month)
  struct RewardDefinition {
    uint256 length; // in seconds
    uint256 apr; // 1E18 == 100%
  }
  RewardDefinition[] public rewardDefinitions;

  // Overall provided rewards
  uint256 public rewardsProvided;

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'B: Only admin');
    _;
  }

  modifier onlyController() {
    require(hasRole(CONTROLLER_ROLE, _msgSender()), 'B: Only controller');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Temporary tokens owned by recipient were locked
   *
   * Tokens are owned by recipient for a specific duration of seconds.
   *
   * @param recipient The recipient of the rewards
   * @param amountIn The amount of tokens in
   * @param amountLocked The amount of tokens locked (amount plus reward)
   */
  event TokensLocked(
    address indexed recipient,
    uint256 amountIn,
    uint256 amountLocked
  );

  /**
   * @dev More amount was added into existing lock pool
   *
   * @param recipient The SFT receiving the rewards
   * @param amount The amount of tokens claimed
   * @param amountLocked The amount of tokens locked
   */
  event MoreAdded(
    address indexed recipient,
    uint256 amount,
    uint256 amountLocked
  );

  /**
   * @dev Rrewards were claimed either into wallet or re-locked
   *
   * @param recipient The recipient of the rewards
   * @param amount The amount of tokens claimed
   */
  event RewardsClaimed(address indexed recipient, uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs implementation part and provides admin access
   * for a later selfDestruct call.
   */
  constructor(address admin) {
    // For administrative calls
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  /**
   * @dev One time initializer for proxy
   */
  function initialize(address admin, address rewardHandler_) external {
    // Validate parameters
    require(
      getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0,
      'B: Already initialized'
    );

    // For administrative calls
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setRewardHandler(rewardHandler_);

    // Reward definition: 180 days / 175% APR
    rewardDefinitions.push(RewardDefinition(15552000, 1750000000000000000));

    // Reward definition: 90 days / 130% APR
    rewardDefinitions.push(RewardDefinition(7776000, 1300000000000000000));

    // Reward definition: 30 days / 100% APR
    rewardDefinitions.push(RewardDefinition(2592000, 1000000000000000000));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IBooster}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IBooster-getRewardInfo}
   */
  function getRewardInfo(uint256[] memory tokenIds)
    external
    view
    override
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    )
  {
    locked = new uint256[](tokenIds.length);
    pending = new uint256[](tokenIds.length);
    apr = new uint256[](tokenIds.length);
    secsLeft = new uint256[](tokenIds.length);

    uint256 ts = _getTimestamp();

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      address cfolio = sftHolder.tokenIdToAddress(tokenIds[i].toSftTokenId());
      require(cfolio != address(0), 'B: Invalid tokenId');

      TimeLock storage currentLock = timeLocks[cfolio];
      locked[i] = currentLock.totalAmount;
      pending[i] = _getPendingAmount(currentLock, ts);
      apr[i] = currentLock.apr;
      secsLeft[i] = currentLock.end >= ts
        ? currentLock.end.sub(ts)
        : uint256(-1);
    }
  }

  /**
   * @dev See {IBooster-distributeFromFarm}
   */
  function distributeFromFarm(
    address, /* farm*/
    address recipient,
    uint256 amount,
    uint32 fee
  ) external override onlyController {
    // Validate input
    require(recipient != address(0), 'B: Invalid recipient');

    if (sftHolder.addressToTokenId(recipient) != uint256(-1)) {
      // Prepare locking amount into SFT
      TimeLock storage currentLock = timeLocks[recipient];

      if (currentLock.end != 0) {
        uint256 ts = _getTimestamp();

        // Update pending rewards
        _updatePendingRewards(currentLock, ts);

        // Add more
        require(currentLock.fee == fee, 'B: Fee change');

        // Add amount to total
        _addMore(recipient, currentLock, ts, amount);
      } else {
        // Validate state
        require(
          currentLock.totalAmount == 0 || currentLock.fee == fee,
          'B: Fee mismatch'
        );

        // Prepare for a new lock
        currentLock.fee = fee;
        currentLock.totalAmount = currentLock.totalAmount.add(amount);
      }
    } else {
      rewardHandler.distribute2(recipient, amount, fee);
    }
  }

  /**
   * @dev See {IBooster-lock}
   */
  function lock(address recipient, uint256 lockPeriod)
    external
    override
    onlyController
  {
    uint256 ts = _getTimestamp();

    TimeLock storage currentLock = timeLocks[recipient];

    // Verify that we have already updated lock (from preceeding
    // {distributeFromFarm} call)
    require(currentLock.end == 0 || currentLock.last == ts, 'B: Sync failure');

    if (currentLock.end == 0) {
      // Start a new lock session. Calculate the amount we provide.
      for (uint256 i = 0; i < rewardDefinitions.length; ++i) {
        if (lockPeriod >= rewardDefinitions[i].length) {
          uint256 reward = (
            currentLock.totalAmount.mul(rewardDefinitions[i].length).mul(
              rewardDefinitions[i].apr
            )
          ).div(SECONDS_PER_YEAR.mul(1E18));

          currentLock.totalAmount = currentLock.totalAmount.add(reward);
          currentLock.end = ts + rewardDefinitions[i].length;
          currentLock.apr = rewardDefinitions[i].apr;
          currentLock.last = ts;

          rewardsProvided.add(reward);

          // Validate state
          _verifyRewardsProvided();

          // Dispatch event
          emit TokensLocked(
            recipient,
            currentLock.totalAmount.sub(reward),
            currentLock.totalAmount
          );

          // Candidate found, return
          return;
        }
      }

      // We never should reach this line
      revert('B: LockPeriod wrong');
    }
  }

  /**
   * @dev See {IBooster-claimRewards}
   */
  function claimRewards(uint256 sftTokenId, bool reLock) external override {
    // Validate access
    address cfolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'B: Invalid cfolio');
    require(
      IERC1155(address(sftHolder)).balanceOf(_msgSender(), sftTokenId) == 1,
      'B: Access denied'
    );

    TimeLock storage currentLock = timeLocks[cfolio];
    uint256 ts = _getTimestamp();

    _updatePendingRewards(currentLock, ts);

    uint256 claimable = currentLock.pendingAmount;
    currentLock.pendingAmount = 0;
    currentLock.providedAmount.add(claimable);

    // Dispatch event
    emit RewardsClaimed(cfolio, claimable);

    // Update state
    if (reLock) {
      _addMore(cfolio, currentLock, ts, claimable);
    } else {
      rewardHandler.distribute2(_msgSender(), claimable, currentLock.fee);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Maintanance functions
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Self destruct implementation contract
   */
  function destructContract(address payable newContract) external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(newContract);
  }

  /**
   * @dev Set reward handler in case it will be upgraded
   */
  function setRewardHandler(address rewardHandler_) external onlyAdmin {
    _setRewardHandler(rewardHandler_);
  }

  /**
   * @dev Set sftHolder contract which is deployed after Booster
   */
  function setSftHolder(address sftHolder_) external onlyAdmin {
    // Validate input
    require(sftHolder_ != address(0), 'B: Invalid sftHolder');

    // Update state
    sftHolder = IWOWSERC1155(sftHolder_);
  }

  /**
   * @dev Replace reward definition.
   * Durations are required to be in descending order
   */
  function setRewardDefinition(
    uint256[] calldata durations,
    uint256[] calldata aprs
  ) external onlyAdmin {
    // Validate input
    require(durations.length == aprs.length, 'B: Length mismatch');

    // Update state
    delete (rewardDefinitions);
    for (uint256 i = 0; i < durations.length; ++i) {
      require(i == 0 || durations[i - 1] > durations[i], 'B: Wrong sorting');
      rewardDefinitions.push(RewardDefinition(durations[i], aprs[i]));
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Helper function to avoid disabling solhint in several places
   */
  function _getTimestamp() private view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp;
  }

  /**
   * @dev Internal setRewardhandler which checks for valid address
   */
  function _setRewardHandler(address rewardHandler_) internal {
    // Validate input
    require(rewardHandler_ != address(0), 'B: Invalid rewardHandler');

    // Update state
    rewardHandler = IRewardHandler(rewardHandler_);
  }

  /**
   * @dev Add more amount into existing lock pool
   *
   * Function will revert in case lock is closed because lock_.end is 0
   * and every subtraction with ts > 0 will fail in SafeMath
   */
  function _addMore(
    address recipient,
    TimeLock storage lock_,
    uint256 ts,
    uint256 amount
  ) private {
    // Following line reverts in SafeMath if timestamps are invalid
    uint256 reward = (amount.mul(lock_.end.sub(ts)).mul(lock_.apr)).div(
      SECONDS_PER_YEAR.mul(1E18)
    );

    // Update state
    lock_.totalAmount = lock_.totalAmount.add(amount).add(reward);
    rewardsProvided.add(reward);

    // Validate state
    _verifyRewardsProvided();

    // Dispatch event
    emit MoreAdded(recipient, amount, amount.add(reward));
  }

  /**
   * @dev Write all pending rewards into pendingAmount so we can
   * safely add more amounts or finalize the lock pool.
   */
  function _updatePendingRewards(TimeLock storage lock_, uint256 ts) private {
    lock_.pendingAmount = _getPendingAmount(lock_, ts);
    if (lock_.end != 0) {
      if (ts >= lock_.end) {
        lock_.end = 0;
        lock_.totalAmount = 0;
        lock_.providedAmount = 0;
      } else {
        lock_.last = ts;
      }
    }
  }

  /**
   * @dev Calculate the current pending amount
   */
  function _getPendingAmount(TimeLock storage lock_, uint256 ts)
    private
    view
    returns (uint256)
  {
    if (lock_.end != 0) {
      if (ts >= lock_.end) {
        return lock_.totalAmount.sub(lock_.providedAmount);
      } else {
        return
          lock_.pendingAmount.add(
            lock_.totalAmount.mul(ts.sub(lock_.last)).div(MONTHLY_REWARD)
          );
      }
    } else {
      return lock_.pendingAmount;
    }
  }

  /**
   * @dev Verify that we never exceed the token supply from tokenomics and fees
   */
  function _verifyRewardsProvided() private view {
    uint256 externalSupply = rewardHandler.getBoosterRewards();

    require(
      rewardsProvided <= externalSupply.add(MAX_TOKENOMICS_REWARDS),
      'B: Cap reached'
    );
  }
}

// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

import '../interfaces/IERC20.sol';
import '../utils/SafeMath.sol';
import '../utils/Address.sol';

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

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
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
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
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

    bytes memory returndata = address(token).functionCall(
      data,
      'SafeERC20: low-level call failed'
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
    }
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

import '../../0xerc1155/interfaces/IERC1155.sol';
import '../../0xerc1155/interfaces/IERC1155TokenReceiver.sol';
import '../../0xerc1155/utils/SafeMath.sol';

import '../investment/interfaces/ICFolioFarm.sol'; // WOWS rewards
import '../token/interfaces/IWOWSERC1155.sol'; // SFT contract
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemBridge.sol';
import './interfaces/ICFolioItemHandler.sol';
import './interfaces/ISFTEvaluator.sol';

interface ICFolioFarmDeprecated {
  /**
   * @dev Return invested balance of account
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Return pending rewards
   */
  function earned(address account) external view returns (uint256);
}

/**
 * @dev CFolioItemHandlerFarm manages CFolioItems, minted in the SFT contract.
 *
 * Minting CFolioItem SFTs is implemented in the WOWSSFTMinter contract, which
 * mints the SFT in the WowsERC1155 contract and calls setupCFolio in here.
 *
 * Normaly CFolioItem SFTs are locked in the main TradeFloor contract to allow
 * trading or transfer into a Base SFT card's c-folio.
 *
 * CFolioItem SFTs only earn rewards if they are inside the cfolio of a base
 * NFT. We get called from main TradeFloor every time an CFolioItem gets
 * transfered and calculate the new rewardable amount based on the reward %
 * of the base NFT.
 */
abstract contract CFolioItemHandlerFarm is ICFolioItemHandler, Context {
  using SafeMath for uint256;
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Route to SFT Minter. Only setup from SFT Minter allowed.
  address public sftMinter;

  // Registered sidechains
  mapping(address => mapping(uint256 => uint256)) public sideChains;

  // The TradeFloor contract which provides c-folio NFTs. This TradeFloor
  // contract calls the IMinterCallback interface functions.
  ICFolioItemBridge public immutable cfiBridge;

  // SFT evaluator
  ISFTEvaluator public immutable sftEvaluator;

  // Reward emitter
  ICFolioFarmOwnable public immutable cfolioFarm;

  // Admin
  address public immutable admin;

  // The SFT contract needed to check if the address is a c-folio
  IWOWSERC1155 public immutable sftHolder;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Emitted when a new minter is set by the admin
   *
   * @param minter The new minter
   */
  event NewMinter(address minter);

  /**
   * @dev Emitted when a new sidechain is registered
   *
   * @param sideChain The address of the root bridge
   * @param slotId The slotId, 0 for disable
   */
  event SideChainRegistered(address sideChain, uint256 slotId);

  /**
   * @dev Emitted when the contract is destructed
   *
   * @param thisContract The address of this contract
   */
  event CFolioItemHandlerDestructed(address thisContract);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyBridge() {
    require(_msgSender() == address(cfiBridge), 'CFHI: Only CFIB');
    _;
  }

  modifier onlyAdmin() {
    require(_msgSender() == admin, 'CFIH: Only admin');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerFarm
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry, bytes32 rewardFarmKey) {
    // TradeFloor
    cfiBridge = ICFolioItemBridge(
      addressRegistry.getRegistryEntry(AddressBook.CFOLIOITEM_BRIDGE_PROXY)
    );

    // Admin
    admin = addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);

    // The SFT holder
    sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );

    // The SFT minter
    sftMinter = addressRegistry.getRegistryEntry(AddressBook.SFT_MINTER);
    emit NewMinter(sftMinter);

    // SFT evaluator
    sftEvaluator = ISFTEvaluator(
      addressRegistry.getRegistryEntry(AddressBook.SFT_EVALUATOR_PROXY)
    );

    // WOWS rewards
    cfolioFarm = ICFolioFarmOwnable(
      addressRegistry.getRegistryEntry(rewardFarmKey)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemCallback} via {ICFolioItemHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemCallback-onCFolioItemsTransferedFrom}
   */
  function onCFolioItemsTransferedFrom(
    address from,
    address to,
    uint256[] calldata, /* tokenIds*/
    address[] calldata /* cfolioHandlers*/
  ) external override onlyBridge {
    // In case of transfer verify the target
    uint256 sftTokenId;

    if (
      to != address(0) &&
      (sftTokenId = sftHolder.addressToTokenId(to)) != uint256(-1)
    ) {
      _verifyTransferTarget(sftTokenId);
      _updateRewards(to, sftEvaluator.rewardRate(sftTokenId));
    }
    if (
      from != address(0) &&
      (sftTokenId = sftHolder.addressToTokenId(from)) != uint256(-1)
    ) {
      _updateRewards(from, sftEvaluator.rewardRate(sftTokenId));
    }
  }

  /**
   * @dev See {ICFolioItemCallback-appendHash}
   */
  function appendHash(address cfolioItem, bytes calldata current)
    external
    view
    override
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        current,
        address(this),
        cfolioFarm.balancesOf(cfolioItem)
      );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-sftUpgrade}
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external override {
    // Validate access
    require(_msgSender() == address(sftEvaluator), 'CFIH: Invalid caller');
    require(tokenId.isBaseCard(), 'CFIH: Invalid token');

    // CFolio address
    address cfolio = sftHolder.tokenIdToAddress(tokenId);

    // Update state
    _updateRewards(cfolio, newRate);
  }

  /**
   * @dev See {ICFolioItemHandler-setupCFolio}
   *
   * Note: We place a dummy ERC1155 token with ID 0 into the CFolioItem's
   * c-folio. The reason is that we want to know if a c-folio item gets burned,
   * as burning an empty c-folio will result in no transfers. This prevents
   * tokens from becoming inaccessible.
   *
   * Refer to the Minimal ERC1155 section below to learn which functions are
   * needed for this.
   */
  function setupCFolio(
    address payer,
    uint256 sftTokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate access
    require(_msgSender() == sftMinter, 'CFIH: Only sftMinter');

    // Validate parameters, no unmasking required, must be SFT
    address cFolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cFolio != address(0), 'CFIH: No cfolio');

    // Verify that this function is called the first time
    (, uint256 length) = IWOWSCryptofolio(cFolio).getCryptofolio(address(this));
    require(length == 0, 'CFIH: Not empty');

    // Transfer a dummy NFT token to cFolio so we get informed if the cFolio
    // gets burned
    IERC1155TokenReceiver(cFolio).onERC1155Received(
      address(this),
      address(0),
      0,
      1,
      ''
    );

    if (amounts.length > 0) {
      _deposit(cFolio, payer, amounts);
    }
  }

  /**
   * @dev See {ICFolioItemHandler-deposit}
   *
   * Note: tokenId can be owned by a base SFT
   * In this case base SFT cannot be locked
   *
   * There is only need to update rewards if tokenId
   * is part of an unlocked base SFT
   */
  function deposit(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    (address baseCFolio, address itemCFolio) = _verifyAssetAccess(
      baseTokenId,
      tokenId
    );

    // Call the implementation
    _deposit(itemCFolio, _msgSender(), amounts);

    // Update rewards if CFI is inside cfolio
    if (baseCFolio != address(0))
      _updateRewards(baseCFolio, sftEvaluator.rewardRate(baseTokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-withdraw}
   *
   * Note: tokenId can be owned by a base SFT. In this case, the base SFT
   * cannot be locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    (address baseCFolio, address itemCFolio) = _verifyAssetAccess(
      baseTokenId,
      tokenId
    );

    // Call the implementation
    _withdraw(itemCFolio, amounts);

    // Update rewards if CFI is inside cfolio
    if (baseCFolio != address(0))
      _updateRewards(baseCFolio, sftEvaluator.rewardRate(baseTokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-updateRewards}
   */
  function updateRewards(uint256 tokenId) external override {
    require(tokenId.isBaseCard(), 'CFIH: Invalid tokenId');

    address cFolio = sftHolder.tokenIdToAddress(tokenId.toSftTokenId());

    require(cFolio != address(0), 'CFIH: Invalid cfolio');
    _updateRewards(cFolio, sftEvaluator.rewardRate(tokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-getRewards}
   *
   * Note: tokenId must be a base SFT card
   *
   * We allow reward pull only for unlocked SFTs.
   */
  function getRewards(
    address owner,
    address recipient,
    uint256 tokenId
  ) external override {
    // Validate parameters
    require(recipient != address(0), 'CFIH: Invalid recipient');
    require(tokenId.isBaseCard(), 'CFIH: Invalid tokenId');

    // Verify that tokenId has a valid cFolio address
    uint256 sftTokenId = tokenId.toSftTokenId();
    address cfolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'CFHI: No cfolio');

    // Verify that the tokenId is owned by owner and caller is sftMinter.
    // This also verifies that the token is not locked in TradeFloor.
    require(
      _msgSender() == sftMinter &&
        IERC1155(address(sftHolder)).balanceOf(owner, sftTokenId) == 1,
      'CFHI: Forbidden'
    );

    cfolioFarm.getReward(cfolio, recipient);
  }

  /**
   * @dev See {ICFolioItemHandler-getRewardInfo}
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    override
    returns (bytes memory result)
  {
    uint256[5] memory uiData;

    // Get basic data once
    uiData = cfolioFarm.getUIData(address(0));

    // total / rewardDuration / rewardPerDuration
    result = abi.encodePacked(uiData[0], uiData[2], uiData[3]);

    uint256 length = tokenIds.length;
    if (length > 0) {
      // Iterate through all tokenIds and collect reward info
      for (uint256 i = 0; i < length; ++i) {
        uint256 sftTokenId = tokenIds[i].toSftTokenId();
        uint256 share = 0;
        uint256 earned = 0;
        if (sftTokenId.isBaseCard()) {
          address cfolio = sftHolder.tokenIdToAddress(sftTokenId);
          if (cfolio != address(0)) {
            uiData = cfolioFarm.getUIData(cfolio);
            share = uiData[1];
            earned = uiData[4];
          }
        }
        result = abi.encodePacked(result, share, earned);
      }
    }
  }

  /**
   * @dev See {ICFolioItemHandler-addAssets}
   */
  function addAssets(
    address cFolioItem,
    uint256 sideChainSlotId,
    uint256 amount
  ) external override {
    uint256 slotId = sideChains[_msgSender()][sideChainSlotId];
    require(slotId > 0, 'CFIH: Unregistered bridge');

    cfolioFarm.addAssets(cFolioItem, amount, slotId);
  }

  /**
   * @dev See {ICFolioItemHandler-removeAssets}
   */
  function removeAssets(address cFolioItem, uint256 sideChainSlotId)
    external
    override
    returns (uint256 amount)
  {
    uint256 slotId = sideChains[_msgSender()][sideChainSlotId];
    require(slotId > 0, 'CFIH: Unregistered bridge');

    amount = cfolioFarm.balanceOf(cFolioItem, slotId);
    cfolioFarm.removeAssets(cFolioItem, amount, slotId);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Deposit amounts
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256[] calldata amounts
  ) internal virtual;

  /**
   * @dev Withdraw amounts
   */
  function _withdraw(address itemCFolio, uint256[] calldata amounts)
    internal
    virtual;

  /**
   * @dev Verify if target base SFT is allowed
   */
  function _verifyTransferTarget(uint256 baseSftTokenId) internal virtual;

  //////////////////////////////////////////////////////////////////////////////
  // Maintanace
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Destruct implementation
   */
  function selfDestruct() external onlyAdmin {
    // Dispatch event
    CFolioItemHandlerDestructed(address(this));

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "CFolioItemHandlerFarm.selfDestruct() allows anyone to destruct the
    // contract", which is not the case due to the onlyAdmin modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(payable(admin));
  }

  /**
   * @dev Set a new SFT minter
   */
  function setMinter(address newMinter) external onlyAdmin {
    // Validate parameters
    require(newMinter != address(0), 'CFIH: Invalid');

    // Update state
    sftMinter = newMinter;

    // Dispatch event
    emit NewMinter(newMinter);
  }

  function registerSideChain(
    address sideChain,
    uint256 sideChainSlotId,
    uint256 slotId
  ) external onlyAdmin {
    require(sideChain != address(0), 'CFIH: Invalid');
    sideChains[sideChain][sideChainSlotId] = slotId;

    // Emit event
    emit SideChainRegistered(sideChain, slotId);
  }

  function migrateFrom(
    ICFolioFarmDeprecated oldFarm,
    address[] calldata farmers,
    uint256 totalRewards
  ) external onlyAdmin {
    uint256 totalAmount = cfolioFarm.totalSupply();

    for (uint256 i = 0; i < farmers.length; ++i) {
      uint256 tokenId = sftHolder.addressToTokenId(farmers[i]);
      if (tokenId != uint256(-1)) {
        uint256 amount = oldFarm.balanceOf(farmers[i]);
        uint256 rewards = tokenId.isBaseCard() ? oldFarm.earned(farmers[i]) : 0;

        if (amount > 0 || rewards > 0) {
          cfolioFarm.migrateSetAccountState(farmers[i], amount, rewards);

          if (tokenId.isBaseCard()) {
            totalAmount = totalAmount.add(amount);
            totalRewards = totalRewards.add(rewards);
          }
        }
      }
    }
    cfolioFarm.migrateSetGlobalState(totalAmount, totalRewards);
    log1(bytes32(totalAmount), bytes32(totalRewards));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Minimal ERC1155 implementation (called from SFTBase CFolio)
  //////////////////////////////////////////////////////////////////////////////

  // We do nothing for our dummy burn tokenId
  function setApprovalForAll(address, bool) external {}

  // Check for length == 1, and then return always 1
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    pure
    returns (uint256[] memory)
  {
    // Validate parameters
    require(_owners.length == 1 && _ids.length == 1, 'CFIH: Must be 1');

    uint256[] memory result = new uint256[](1);
    result[0] = 1;
    return result;
  }

  /**
   * @dev We don't allow burning non-empty c-folios
   */
  function burnBatch(
    address, /* account */
    uint256[] calldata tokenIds,
    uint256[] calldata
  ) external view {
    // Validate parameters
    require(tokenIds.length == 1, 'CFIH: Must be 1');

    // This call originates from the c-folio. We revert if there are investment
    // amounts left for this c-folio address.
    uint256[] memory balances = cfolioFarm.balancesOf(_msgSender());
    for (uint256 slotId = 0; slotId < balances.length; ++slotId)
      require(balances[slotId] == 0, 'CFIH: Not empty');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Run through all cFolioItems collected in cFolio and select the amount
   * of tokens. Update cfolioFarm.
   */
  function _updateRewards(address cfolio, uint32 rate) private {
    // Get c-folio items of this base cFolio
    (uint256[] memory tokenIds, uint256 length) = IWOWSCryptofolio(cfolio)
      .getCryptofolio(address(cfiBridge));

    // Marginal increase in gas per item is around 25K. Bounding items to 100
    // fits in sensible gas limits.
    require(length <= 100, 'CFIH: Too many items');

    // Get number of existing sidechain slots
    uint256 farmSlots = cfolioFarm.slotCount();

    // Calculate new reward amount
    uint256[] memory newRewardAmount = new uint256[](farmSlots);
    for (uint256 i = 0; i < length; ++i) {
      address secondaryCFolio = sftHolder.tokenIdToAddress(tokenIds[i]);
      require(secondaryCFolio != address(0), 'CFIH: Invalid tokenId');
      if (IWOWSCryptofolio(secondaryCFolio)._tradefloors(0) == address(this)) {
        uint256[] memory amounts = cfolioFarm.balancesOf(secondaryCFolio);
        for (uint256 slotId = 0; slotId < farmSlots; ++slotId)
          newRewardAmount[slotId] = newRewardAmount[slotId].add(
            amounts[slotId]
          );
      }
    }

    for (uint256 slotId = 0; slotId < farmSlots; ++slotId) {
      newRewardAmount[slotId] = newRewardAmount[slotId].mul(rate).div(1E6);

      // Calculate existing reward amount
      uint256 exitingRewardAmount = cfolioFarm.balanceOf(cfolio, slotId);

      // Compare amounts and add/remove shares
      if (newRewardAmount[slotId] > exitingRewardAmount) {
        // Update state
        cfolioFarm.addShares(
          cfolio,
          newRewardAmount[slotId].sub(exitingRewardAmount),
          slotId
        );
      } else if (newRewardAmount[slotId] < exitingRewardAmount) {
        // Update state
        cfolioFarm.removeShares(
          cfolio,
          exitingRewardAmount.sub(newRewardAmount[slotId]),
          slotId
        );
      }
    }
  }

  /**
   * @dev Verifies if an asset access operation is allowed
   *
   * @param baseTokenId Base card tokenId or uint(-1)
   * @param cfolioItemTokenId CFolioItem tokenId handled by this contract
   *
   * A tokenId is "unlocked" if msg.sender is the owner of a tokenId in SFT
   * contract. If baseTokenId is uint(-1), cfolioItemTokenId has to be be
   * unlocked, otherwise baseTokenId has to be unlocked and the locked
   * cfolioItemTokenId has to be inside its c-folio.
   */
  function _verifyAssetAccess(uint256 baseTokenId, uint256 cfolioItemTokenId)
    private
    view
    returns (address, address)
  {
    // Verify it's a cfolioItemTokenId
    require(cfolioItemTokenId.isCFolioCard(), 'CFHI: Not cFolioCard');

    // Verify that the tokenId is one of ours
    address cFolio = sftHolder.tokenIdToAddress(
      cfolioItemTokenId.toSftTokenId()
    );
    require(cFolio != address(0), 'CFIH: Invalid cFolioTokenId');
    require(
      IWOWSCryptofolio(cFolio)._tradefloors(0) == address(this),
      'CFIH: Not our SFT'
    );

    address baseCFolio = address(0);

    if (baseTokenId != uint256(-1)) {
      // Verify it's a c-folio base card
      require(baseTokenId.isBaseCard(), 'CFHI: Not baseCard');
      baseCFolio = sftHolder.tokenIdToAddress(baseTokenId.toSftTokenId());
      require(baseCFolio != address(0), 'CFIH: Invalid baseCFolioTokenId');

      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(sftHolder)).balanceOf(_msgSender(), baseTokenId) == 1,
        'CFHI: Access denied (B)'
      );

      // Verify that the cfiTokenId is owned by given baseCFolio.
      // In V2 we have unlocked CFIs in baseCfolio in contrast to V1
      require(
        cfiBridge.balanceOf(baseCFolio, cfolioItemTokenId) == 1,
        'CFHI: Access denied (CF)'
      );
    } else {
      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(sftHolder)).balanceOf(
          _msgSender(),
          cfolioItemTokenId
        ) == 1,
        'CFHI: Access denied'
      );
    }
    return (baseCFolio, cFolio);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to C-folio item bridge
 */
interface ICFolioItemBridge {
  /**
   * @notice Send multiple types of tokens from the _from address to the _to address (with safety call)
   * @param from     Source addresses
   * @param to       Target addresses
   * @param tokenIds IDs of each token type
   * @param amounts  Transfer amounts per token type
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external;

  /**
   * @notice Burn multiple types of tokens from the from
   * @param from     Source addresses
   * @param tokenIds IDs of each token type
   * @param amounts  Transfer amounts per token type
   */
  function burnBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external;

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);

  /**
   * @notice Get the balance of single account/token pair
   * @param account The address of the token holders
   * @param tokenId ID of the token
   * @return        The account's balance (0 or 1)
   */
  function balanceOf(address account, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param accounts The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return         The accounts's balances (0 or 1)
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    view
    returns (uint256[] memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../interfaces/curve/CurveDepositInterface.sol';

import './CFolioItemHandlerFarm.sol';

/**
 * @dev CFolioItemHandlerSC manages CFolioItems, minted in the SFT contract.
 *
 * See {CFolioItemHandlerFarm}.
 */
contract CFolioItemHandlerSC is CFolioItemHandlerFarm {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Curve Y pool token contract
  IERC20 public immutable curveYToken;

  // Curve Y pool deposit contract
  ICurveFiDepositY public immutable curveYDeposit;

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerSC
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry)
    CFolioItemHandlerFarm(addressRegistry, AddressBook.BOIS_REWARDS)
  {
    // The Y pool deposit contract
    curveYDeposit = ICurveFiDepositY(
      addressRegistry.getRegistryEntry(AddressBook.CURVE_Y_DEPOSIT)
    );

    // The Y pool token contract
    curveYToken = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.CURVE_Y_TOKEN)
    );
  }

  /**
   * @dev One time contract initializer
   */
  function initialize() public {
    // Approve stablecoin spending
    for (uint256 i = 0; i < 4; ++i) {
      address underlyingCoin = curveYDeposit.underlying_coins(int128(i));
      IERC20(underlyingCoin).safeApprove(address(curveYDeposit), uint256(-1));
    }

    // Approve yCRV spending
    curveYToken.approve(address(curveYDeposit), uint256(-1));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {CFolioItemHandlerFarm-_deposit}.
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256[] calldata amounts
  ) internal override {
    // Validate input
    require(amounts.length == 5, 'CFIHSC: Amount length invalid');

    // Keep track of how many Y pool tokens were received
    uint256 beforeBalance = curveYToken.balanceOf(address(this));

    // Keep track of amounts
    uint256[4] memory stableAmounts;
    uint256 totalStableAmount;

    // Update state
    for (uint256 i = 0; i < 4; ++i) {
      address underlyingCoin = curveYDeposit.underlying_coins(int128(i));

      IERC20(underlyingCoin).safeTransferFrom(payer, address(this), amounts[i]);

      uint256 stableAmount = IERC20(underlyingCoin).balanceOf(address(this));

      stableAmounts[i] = stableAmount;
      totalStableAmount += stableAmount;
    }

    if (totalStableAmount > 0) {
      // Call to external contract
      curveYDeposit.add_liquidity(stableAmounts, 0);

      // Validate state
      uint256 afterStableBalance = curveYToken.balanceOf(address(this));
      require(
        afterStableBalance > beforeBalance,
        'CFIHSC: No stable liquidity'
      );
    }

    // Handle Y pool
    uint256 yPoolAmount = amounts[4];

    // Update state
    if (yPoolAmount > 0) {
      curveYToken.safeTransferFrom(payer, address(this), yPoolAmount);
    }

    // Validate state
    uint256 afterBalance = curveYToken.balanceOf(address(this));
    require(afterBalance > beforeBalance, 'CFIFSC: No investment');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {addAssets} must only be called from Investment CFolios. This
    // call is allowed without any investment.
    cfolioFarm.addAssets(itemCFolio, afterBalance.sub(beforeBalance), 0);
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_withdraw}
   *
   * Note: tokenId can be owned by a base SFT. In this case, the base SFT
   * cannot be locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   *
   * @param itemCFolio The address of the target CFolioItem cryptofolio
   * @param amounts The amounts, with the tokens being DAI/USDC/USDT/TUSD/yCRV.
   *     yCRV must be specified, as yCRV tokens are held by this contract.
   *     If all four stablecoin amounts are 0, then yCRV is withdrawn to the
   *     sender's wallet. If exactly one of the four stablecoin amounts is > 0,
   *     then yCRV will be converted to the specified stablecoin. The amount in
   *     the array is the minimum amount of stablecoin tokens that must be
   *     withdrawn.
   */
  function _withdraw(address itemCFolio, uint256[] calldata amounts)
    internal
    override
  {
    // Validate input
    require(amounts.length == 5, 'CFIHSC: Amount length invalid');

    // Validate parameters
    uint256 yPoolAmount = amounts[4];
    require(yPoolAmount > 0, 'CFIHSC: yCRV amount is 0');

    // Get single coin and amount
    (int128 stableCoinIndex, uint256 stableCoinAmount) = _getStableCoinInfo(
      amounts
    );

    // Keep track of how many Y pool tokens were sent
    uint256 balanceBefore = curveYToken.balanceOf(address(this));

    // Update state
    if (stableCoinIndex != -1) {
      // Call to external contract
      curveYDeposit.remove_liquidity_one_coin(
        yPoolAmount,
        stableCoinIndex,
        stableCoinAmount,
        true
      );

      address underlyingCoin = curveYDeposit.underlying_coins(
        int128(stableCoinIndex)
      );
      uint256 underlyingCoinAmount = IERC20(underlyingCoin).balanceOf(
        address(this)
      );

      // Transfer stablecoins back to the sender
      IERC20(underlyingCoin).safeTransfer(_msgSender(), underlyingCoinAmount);
    } else {
      // No stablecoins were passed, sender is withdrawing Y pool tokens directly
      // Transfer Y pool tokens back to the sender
      curveYToken.safeTransfer(_msgSender(), yPoolAmount);
    }

    // Valiate state
    uint256 balanceAfter = curveYToken.balanceOf(address(this));
    require(balanceAfter < balanceBefore, 'Nothing withdrawn');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {removeAssets} must only be called from Investment CFolios.
    cfolioFarm.removeAssets(itemCFolio, balanceBefore.sub(balanceAfter), 0);
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_verifyTransferTarget}
   */
  function _verifyTransferTarget(uint256 baseSftTokenId)
    internal
    view
    override
  {
    (, uint8 level) = sftHolder.getTokenData(baseSftTokenId);

    require((LEVEL2BOIS & (uint256(1) << level)) > 0, 'CFIHSC: Bois only');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler} via {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-getAmounts}
   *
   * The returned token array is DAI/USDC/USDT/TUSD/yCRV. Tokens are held in
   * this contract as yCRV, so the fifth item will be the amount of yCRV. The
   * four stablecoin amounts are the amount that would be withdrawn if all
   * yCRV were converted to the corresponding stablecoin upon withdrawal. This
   * value is calculated by Curve.
   */
  function getAmounts(address cfolioItem)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](5);

    uint256 wrappedAmount = cfolioFarm.balanceOf(cfolioItem, 0);

    for (uint256 i = 0; i < 4; ++i) {
      result[i] = curveYDeposit.calc_withdraw_one_coin(
        wrappedAmount,
        int128(i)
      );
    }

    result[4] = wrappedAmount;

    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Get single coin and amount
   *
   * This is a helper function for {withdraw}. Per the documentation above, no
   * more than one stablecoin amount can be > 0. If more than one stablecoin
   * amount is specified, the revert condition below will be reached.
   *
   * If exactly one stablecoin amount is specified, then the return values will
   * be the index of that coin and its amount.
   *
   * If no stablecoin amounts are > 0, then a coin index of -1 is returned,
   * with a 0 amount.
   *
   * @param amounts The amounts array: DAI/USDC/USDT/TUSD/yCRV
   *
   * @return stableCoinIndex The index of the stablecoin with amount > 0, or -1
   *     if all four stablecoin amounts are 0
   * @return stableCoinAmount The amount of the stablecoin, or 0 if all four
   *     stablecoin amounts are 0
   */
  function _getStableCoinInfo(uint256[] calldata amounts)
    private
    pure
    returns (int128 stableCoinIndex, uint256 stableCoinAmount)
  {
    stableCoinIndex = -1;

    for (uint128 i = 0; i < 4; ++i) {
      if (amounts[i] > 0) {
        require(stableCoinIndex == -1, 'Multiple amounts > 0');
        stableCoinIndex = int8(i);
        stableCoinAmount = amounts[i];
      }
    }
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/* solhint-disable func-name-mixedcase */
abstract contract ICurveFiDepositY {
  function add_liquidity(uint256[4] calldata uAmounts, uint256 minMintAmount)
    external
    virtual;

  function remove_liquidity(uint256 amount, uint256[4] calldata minUAmounts)
    external
    virtual;

  function remove_liquidity_imbalance(
    uint256[4] calldata uAmounts,
    uint256 maxBurnAmount
  ) external virtual;

  function calc_withdraw_one_coin(uint256 wrappedAmount, int128 coinIndex)
    external
    view
    virtual
    returns (uint256 underlyingAmount);

  function remove_liquidity_one_coin(
    uint256 wrappedAmount,
    int128 coinIndex,
    uint256 minAmount,
    bool donateDust
  ) external virtual;

  function coins(int128 i) external view virtual returns (address);

  function underlying_coins(int128 i) external view virtual returns (address);

  function underlying_coins() external view virtual returns (address[4] memory);

  function curve() external view virtual returns (address);

  function token() external view virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// mainnet:

pragma solidity >=0.7.0 <0.8.0;

import '../0xerc1155/utils/SafeERC20.sol';

contract FarmRewards {
  using SafeERC20 for IERC20;

  address private admin_;
  IERC20 private token_;
  address private recipient_;
  uint256 public claimed;
  uint256 public startTime;
  bool public paused;

  constructor(
    address admin,
    address token,
    address recipient
  ) {
    admin_ = admin;
    token_ = IERC20(token);
    recipient_ = recipient;
    startTime = block.timestamp;
    paused = false;
  }

  function pause(bool _pause) external {
    require(msg.sender == admin_, 'Only admin');
    paused = _pause;
  }

  function get() external {
    require(!paused, 'Paused');
    require(msg.sender == recipient_, 'Only recipient');

    uint256 payOut = _calculate();
    require(payOut > claimed, 'Nothing to claim');

    uint256 toTransfer = payOut - claimed;

    claimed = payOut;

    token_.safeTransfer(recipient_, toTransfer);
  }

  function _calculate() private view returns (uint256 result) {
    result = 200;
    uint256 monthPassed = (block.timestamp - startTime) / (86400 * 30);
    if (monthPassed > 5) monthPassed = 5;
    if (monthPassed > 0) result += (150 + (monthPassed - 1) * 100);
    result = result * 1e18;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/utils/SafeERC20.sol';

import './CFolioItemHandlerFarm.sol';

/**
 * @dev CFolioItemHandlerLP manages CFolioItems, minted in the SFT contract.
 *
 * See {CFolioItemHandlerFarm}.
 */
contract CFolioItemHandlerLP is CFolioItemHandlerFarm {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // The token staked here (WOWS/WETH UniV2 Pair)
  IERC20 public immutable stakingToken;

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerLP
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry)
    CFolioItemHandlerFarm(addressRegistry, AddressBook.WOLVES_REWARDS)
  {
    // The ERC-20 token we stake
    stakingToken = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_PAIR)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {CFolioItemHandlerFarm-_deposit}.
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256[] calldata amounts
  ) internal override {
    // Validate parameters
    require(amounts.length == 1 && amounts[0] > 0, 'CFIHLP: invalid amount');
    // Transfer LP token to this contract
    stakingToken.safeTransferFrom(payer, address(this), amounts[0]);

    // Record assets in the Farm contract. They don't earn rewards.
    //
    // NOTE: {addAssets} must only be called from investment CFolios.
    cfolioFarm.addAssets(itemCFolio, amounts[0], 0);
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_withdraw}.
   */
  function _withdraw(address itemCFolio, uint256[] calldata amounts)
    internal
    override
  {
    // Validate parameters
    require(amounts.length == 1 && amounts[0] > 0, 'CFIHLP: invalid amount');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {removeAssets} must only be called from Investment CFolios.
    cfolioFarm.removeAssets(itemCFolio, amounts[0], 0);

    // Transfer LP token from this contract.
    stakingToken.safeTransfer(_msgSender(), amounts[0]);
  }

  /**
   * @dev Verify if target base SFT is allowed
   */
  function _verifyTransferTarget(uint256 baseSftTokenId)
    internal
    view
    override
  {
    (, uint8 level) = sftHolder.getTokenData(baseSftTokenId);

    require((LEVEL2WOLF & (uint256(1) << level)) > 0, 'CFIHLP: Wolves only');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler} via {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-getAmounts}
   */
  function getAmounts(address cfolioItem)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](1);

    result[0] = cfolioFarm.balanceOf(cfolioItem, 0);

    return result;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';

abstract contract IYERC20 is IERC20 {
  //Y-token functions
  function deposit(uint256 amount) external virtual;

  function withdraw(uint256 shares) external virtual;

  function getPricePerFullShare() external view virtual returns (uint256);

  function token() external virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC1155MintBurn } from '../../0xerc1155/interfaces/IERC1155MintBurn.sol';
import { Address } from '../../0xerc1155/utils/Address.sol';
import { FxBaseChildTunnel } from '../../polygonFx/tunnel/FxBaseChildTunnel.sol';

contract WowsERC1155ChildTunnel is FxBaseChildTunnel {
  using Address for address;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant DEPOSIT = keccak256('DEPOSIT');
  bytes32 public constant DEPOSIT_BATCH = keccak256('DEPOSIT_BATCH');
  bytes32 public constant WITHDRAW = keccak256('WITHDRAW');
  bytes32 public constant WITHDRAW_BATCH = keccak256('WITHDRAW_BATCH');
  bytes32 public constant MAP_TOKEN = keccak256('MAP_TOKEN');

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  IERC1155MintBurn private immutable childToken_;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  address public rootToken;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event TokenMapped(address indexed rootToken, address indexed childToken);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(address _fxChild, address _token) FxBaseChildTunnel(_fxChild) {
    require(_token.isContract(), 'CT: Not a contract');
    childToken_ = IERC1155MintBurn(_token);
  }

  function withdraw(
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public {
    require(rootToken != address(0x0), 'CT: Token not mapped');

    childToken_.burn(msg.sender, id, amount);

    bytes memory message = abi.encode(
      WITHDRAW,
      abi.encode(rootToken, childToken_, msg.sender, id, amount, data)
    );
    _sendMessageToRoot(message);
  }

  function withdrawBatch(
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public {
    require(rootToken != address(0x0), 'CT: Token not mapped');

    childToken_.batchBurn(msg.sender, ids, amounts);

    bytes memory message = abi.encode(
      WITHDRAW_BATCH,
      abi.encode(rootToken, childToken_, msg.sender, ids, amounts, data)
    );
    _sendMessageToRoot(message);
  }

  function _processMessageFromRoot(
    uint256, /* stateId */
    address sender,
    bytes memory data
  ) internal override validateSender(sender) {
    (bytes32 syncType, bytes memory syncData) = abi.decode(
      data,
      (bytes32, bytes)
    );

    if (syncType == MAP_TOKEN) {
      _mapToken(syncData);
    } else if (syncType == DEPOSIT) {
      _syncDeposit(syncData);
    } else if (syncType == DEPOSIT_BATCH) {
      _syncDepositBatch(syncData);
    } else {
      revert('CT: Invalid sync type');
    }
  }

  function _mapToken(bytes memory syncData) internal {
    address _rootToken = abi.decode(syncData, (address));

    require(rootToken == address(0), 'CT: Already mapped');

    rootToken = _rootToken;

    emit TokenMapped(rootToken, address(childToken_));
  }

  function _syncDeposit(bytes memory syncData) internal {
    (
      address _rootToken, /*address depositor*/
      ,
      address user,
      uint256 id,
      uint256 amount,
      bytes memory data
    ) = abi.decode(
        syncData,
        (address, address, address, uint256, uint256, bytes)
      );

    require(_rootToken == rootToken, 'CT: Invalid rootToken');

    childToken_.mint(user, id, amount, data);
  }

  function _syncDepositBatch(bytes memory syncData) internal {
    (
      address _rootToken, /*address depositor */
      ,
      address user,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
    ) = abi.decode(
        syncData,
        (address, address, address, uint256[], uint256[], bytes)
      );

    require(_rootToken == rootToken, 'CT: Invalid rootToken');

    childToken_.batchMint(user, ids, amounts, data);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * Recommended interface for public facing minting and burning functions.
 * These public methods should have restricted access.
 */
interface IERC1155MintBurn {
  /***************************************|
  |        Public Minting Functions       |
  |______________________________________*/

  /**
   * @dev Mint _amount of tokens of a given id if not frozen and if max supply not exceeded
   * @param _to     The address to mint tokens to.
   * @param _id     Token id to mint
   * @param _amount The amount to be minted
   * @param _data   Byte array of data to pass to recipient if it's a contract
   */
  function mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to      The address to mint tokens to.
   * @param _ids     Array of ids to mint
   * @param _amounts Array of amount of tokens to mint per id
   * @param _data    Byte array of data to pass to recipient if it's a contract
   */
  function batchMint(
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  /***************************************|
  |        Public Minting Functions       |
  |______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function burn(
    address _from,
    uint256 _id,
    uint256 _amount
  ) external;

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function batchBurn(
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
  // MessageTunnel on L1 will get data from this event
  event MessageSent(bytes message);

  // fx child
  address public fxChild;

  // fx root tunnel
  address public fxRootTunnel;

  constructor(address _fxChild) {
    fxChild = _fxChild;
  }

  // Sender must be fxRootTunnel in case of ERC20 tunnel
  modifier validateSender(address sender) {
    require(
      sender == fxRootTunnel,
      'FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT'
    );
    _;
  }

  // set fxRootTunnel if not set already
  function setFxRootTunnel(address _fxRootTunnel) external {
    require(
      fxRootTunnel == address(0x0),
      'FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET'
    );
    fxRootTunnel = _fxRootTunnel;
  }

  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external override {
    require(msg.sender == fxChild, 'FxBaseChildTunnel: INVALID_SENDER');
    _processMessageFromRoot(stateId, rootMessageSender, data);
  }

  /**
   * @notice Emit message that can be received on Root Tunnel
   * @dev Call the internal function when need to emit message
   * @param message bytes message that will be sent to Root Tunnel
   * some message examples -
   *   abi.encode(tokenId);
   *   abi.encode(tokenId, tokenMetadata);
   *   abi.encode(messageType, messageData);
   */
  function _sendMessageToRoot(bytes memory message) internal {
    emit MessageSent(message);
  }

  /**
   * @notice Process message received from Root Tunnel
   * @dev function needs to be implemented to handle message as per requirement
   * This is called by onStateReceive function.
   * Since it is called via a system call, any event will not be emitted during its execution.
   * @param stateId unique state id
   * @param sender root message sender
   * @param message bytes message that was sent from Root Tunnel
   */
  function _processMessageFromRoot(
    uint256 stateId,
    address sender,
    bytes memory message
  ) internal virtual;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC1155.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import '../../0xerc1155/utils/Address.sol';
import '../../0xerc1155/utils/Context.sol';

import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemBridge.sol';
import './interfaces/ICFolioItemHandler.sol';

/**
 * @dev Minimalistic ERC1155 Holder for use only with WOWSCryptofolio
 *
 * This contract receives CFIs from the sftHolder contract for a
 * CFolio and performs all required Handle actions.
 */
contract CFolioItemBridge is ICFolioItemBridge, Context, ERC1155Holder {
  using TokenIds for uint256;
  using Address for address;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // SFT contract
  IAddressRegistry private immutable _addressRegistry;

  // SFT contract
  IWOWSERC1155 private immutable _sftHolder;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Our balances
  mapping(uint256 => address) private _owners;

  // Operator Functions
  mapping(address => mapping(address => bool)) private _operators;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event BridgeTransfer(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event BridgeApproval(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Construct the contract
   *
   * @param addressRegistry Registry containing our system addresses
   *
   */
  constructor(IAddressRegistry addressRegistry) {
    _addressRegistry = addressRegistry;

    // The SFTHolder contract
    _sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of minimal IERC1155
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemBridge-safeBatchTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external override {
    // Validate parameters
    require(
      (_msgSender() == from) || isApprovedForAll(from, _msgSender()),
      'CFIB: Not approved'
    );
    require(to != address(0), 'CFIB: Invalid recipient');
    require(tokenIds.length == amounts.length, 'CFIB: Length mismatch');

    // Transfer
    uint256 length = tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      require(_owners[tokenIds[i]] == from, 'CFIB: Not owner');
      _owners[tokenIds[i]] = to;
    }
    _onTransfer(address(this), from, to, tokenIds, amounts);
  }

  /**
   * @dev See {ICFolioItemBridge-burnBatch}
   */
  function burnBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      'CFIB: Not approved'
    );
    require(tokenIds.length == amounts.length, 'CFIB: Length mismatch');

    // Transfer
    uint256 length = tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      require(_owners[tokenIds[i]] == from, 'CFIB: Not owner');
      _owners[tokenIds[i]] = address(0);
    }
    _onTransfer(address(this), from, address(0), tokenIds, amounts);
  }

  /**
   * @dev See {ICFolioItemBridge-setApprovalForAll}
   */
  function setApprovalForAll(address _operator, bool _approved)
    external
    override
  {
    // Update operator status
    _operators[_msgSender()][_operator] = _approved;
    emit BridgeApproval(_msgSender(), _operator, _approved);
  }

  /**
   * @dev See {ICFolioItemBridge-isApprovedForAll}
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    return _operators[_owner][_operator];
  }

  /**
   * @dev See {ICFolioItemBridge-balanceOf}
   */
  function balanceOf(address account, uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    return _owners[tokenId] == account ? 1 : 0;
  }

  /**
   * @dev See {ICFolioItemBridge-balanceOfBatch}
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    view
    override
    returns (uint256[] memory)
  {
    require(accounts.length == tokenIds.length, 'CFIB: Length mismatch');

    // Variables
    uint256[] memory batchBalances = new uint256[](accounts.length);

    // Iterate over each account and token ID
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = _owners[tokenIds[i]] == accounts[i] ? 1 : 0;
    }

    return batchBalances;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155TokenReceiver} via {ERC1155Holder}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155Received}
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(operator, tokenIds, amounts, data);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    _onTokensReceived(operator, tokenIds, amounts, data);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  function _onTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    uint256 tokenId;
    // Verify that recipient is null or a cFolio
    if (to != address(0)) {
      tokenId = _sftHolder.addressToTokenId(to);
      require(
        tokenId != uint256(-1) && tokenId.isBaseCard(),
        'CFIB: Only baseCard'
      );
    }

    // Count SFT tokenIds
    uint256 length = tokenIds.length;
    uint256 numUniqueCFolioHandlers = 0;
    address[] memory uniqueCFolioHandlers = new address[](length);
    address[] memory cFolioHandlers = new address[](length);

    // Invoke callbacks / count SFTs
    for (uint256 i = 0; i < length; ++i) {
      tokenId = tokenIds[i];
      require(tokenId.isCFolioCard(), 'CFIB: Only cfolioItems');

      // CFolio SFTs always have one tradefloor / 1 CFolio dummy
      // which is needed to notify the CFolioHandler on SFT burn
      address cfolio = _sftHolder.tokenIdToAddress(tokenId.toSftTokenId());
      require(cfolio != address(0), 'CFIB: Invalid cfolio');

      address cFolioHandler = IWOWSCryptofolio(cfolio)._tradefloors(0);

      uint256 iter = numUniqueCFolioHandlers;
      while (iter > 0 && uniqueCFolioHandlers[iter - 1] != cFolioHandler)
        --iter;
      if (iter == 0) {
        require(cFolioHandler != address(0), 'Invalid CFH address');
        uniqueCFolioHandlers[numUniqueCFolioHandlers++] = cFolioHandler;
      }
      cFolioHandlers[i] = cFolioHandler;
    }

    // On Burn we need to transfer SFT ownership back
    if (to == address(0)) {
      IERC1155(address(_sftHolder)).safeBatchTransferFrom(
        address(this),
        _msgSender(),
        tokenIds,
        amounts,
        ''
      );
    } else if (to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(
        _msgSender(),
        from,
        tokenIds,
        amounts,
        ''
      );
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, 'CFIB: CallOn failed');
    }

    // Handle CFolioItem transfers only if we are not migrating
    // Migration takes place if we are called from tradeFloor.
    // Remove the following condition if everything is migrated
    if (
      operator !=
      _addressRegistry.getRegistryEntry(AddressBook.TRADE_FLOOR_PROXY)
    )
      for (uint256 i = 0; i < numUniqueCFolioHandlers; ++i) {
        ICFolioItemHandler(uniqueCFolioHandlers[i]).onCFolioItemsTransferedFrom(
            from,
            to,
            tokenIds,
            cFolioHandlers
          );
      }

    emit BridgeTransfer(_msgSender(), from, to, tokenIds, amounts);
  }

  /**
   * @dev SFT token arrived, provide an NFT
   */
  function _onTokensReceived(
    address operator,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    // We only support tokens from our SFT Holder contract
    require(_msgSender() == address(_sftHolder), 'CFIB: Invalid');

    // Validate parameters
    require(tokenIds.length == amounts.length, 'CFIB: Lengths mismatch');
    require(data.length == 20, 'CFIB: Destination invalid');

    address sftRecipient = _getAddress(data);
    require(sftRecipient != address(0), 'CFIB: Invalid data address');

    // Update state
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      // Validate params
      require(amounts[i] == 1, 'CFIB: Amount invalid');
      uint256 tokenId = tokenIds[i];
      // Mint a token
      require(_owners[tokenId] == address(0), 'CFIB: already minted');
      _owners[tokenId] = sftRecipient;
    }
    _onTransfer(operator, address(0), sftRecipient, tokenIds, amounts);
  }

  /**
   * @dev Get the address from the user data parameter
   *
   * @param data Per ERC-1155, the data parameter is additional data with no
   * specified format, and is sent unaltered in the call to
   * {IERC1155Receiver-onERC1155Received} on the receiver of the minted token.
   */
  function _getAddress(bytes memory data) public pure returns (address addr) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      addr := mload(add(data, 20))
    }
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/utils/Context.sol';

import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ISFTEvaluator.sol';
import './interfaces/ICFolioItemHandler.sol';

contract SFTEvaluator is ISFTEvaluator, Context {
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Attention: Proxy implementation: Only add new state at the end

  // Admin
  address public immutable admin;

  // The SFT contract we need for level
  IWOWSERC1155 private immutable _sftHolder;

  // The cfolioItem bridge contract
  address private immutable _cfiBridge;

  // Current reward weight of a baseCard
  mapping(uint256 => uint256) private _rewardRates;

  // cfolioType -> cfolioItem
  mapping(uint256 => uint256) private _cfolioItemTypes;

  // SFT minter
  address public sftMinter;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event RewardRate(uint256 indexed tokenId, uint32 rate);

  event UpdatedCFolioType(uint256 indexed tokenId, uint256 cfolioItemType);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(IAddressRegistry addressRegistry) {
    // The SFT holder
    _sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );

    // Admin
    admin = addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);

    // CFolioItemBridge
    _cfiBridge = addressRegistry.getRegistryEntry(
      AddressBook.CFOLIOITEM_BRIDGE_PROXY
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ISFTEvaluator}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ISFTEvaluator-rewardRate}.
   */
  function rewardRate(uint256 tokenId) external view override returns (uint32) {
    // Validate parameters
    require(tokenId.isBaseCard(), 'Invalid tokenId');

    uint256 sftTokenId = tokenId.toSftTokenId();

    // Load state
    return
      _rewardRates[sftTokenId] == 0
        ? _baseRate(sftTokenId)
        : uint32(_rewardRates[sftTokenId]);
  }

  /**
   * @dev See {ISFTEvaluator-getCFolioItemType}.
   */
  function getCFolioItemType(uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    // Validate parameters
    require(tokenId.isCFolioCard(), 'Invalid tokenId');

    // Load state
    return _cfolioItemTypes[tokenId.toSftTokenId()];
  }

  /**
   * @dev See {ISFTEvaluator-setRewardRate}.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged)
    external
    override
  {
    // Validate parameters
    require(tokenId.isBaseCard(), 'Invalid tokenId');

    // We allow upgrades of locked and unlocked SFTs
    uint256 sftTokenId = tokenId.toSftTokenId();

    // Load state
    (
      uint32 untimed,
      uint32 timed // solhint-disable-next-line not-rely-on-time
    ) = _baseRates(sftTokenId, uint64(block.timestamp - 60 days));

    // First implementation, check timed auto upgrade only
    if (untimed != timed) {
      // Update state
      _rewardRates[sftTokenId] = timed;

      IWOWSCryptofolio cFolio = IWOWSCryptofolio(
        _sftHolder.tokenIdToAddress(sftTokenId)
      );
      require(address(cFolio) != address(0), 'SFTE: invalid tokenId');

      // Run through all cfolioItems of cfiBridge
      (uint256[] memory cFolioItems, uint256 length) = cFolio.getCryptofolio(
        _cfiBridge
      );
      if (length > 0) {
        // Bound loop to 100 c-folio items to fit in sensible gas limits
        require(length <= 100, 'SFTE: Too many items');

        address[] memory calledHandlers = new address[](length);
        uint256 numCalledHandlers = 0;

        for (uint256 i = 0; i < length; ++i) {
          // Secondary c-folio items have one tradefloor which is the handler
          address handler = IWOWSCryptofolio(
            _sftHolder.tokenIdToAddress(cFolioItems[i].toSftTokenId())
          )._tradefloors(0);
          require(
            address(handler) != address(0),
            'SFTE: invalid cfolioItemHandler'
          );

          // Check if we have called this handler already
          uint256 j = numCalledHandlers;
          while (j > 0 && calledHandlers[j - 1] != handler) --j;
          if (j == 0) {
            ICFolioItemHandler(handler).sftUpgrade(sftTokenId, timed);
            calledHandlers[numCalledHandlers++] = handler;
          }
        }
      }

      // Fire an event
      emit RewardRate(tokenId, timed);
    } else {
      // Revert if requested
      require(!revertUnchanged, 'Rate unchanged');
    }
  }

  /**
   * @dev Set SFT minter, admin only.
   *
   * @param newMinter The new SFTMinter implementation
   */
  function setMinter(address newMinter) external {
    // Access control
    require(_msgSender() == admin, 'SFTE: Forbidden');

    // Set state
    sftMinter = newMinter;
  }

  /**
   * @dev See {ISFTEvaluator-setCFolioType}.
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType)
    external
    override
  {
    require(tokenId.isCFolioCard(), 'Invalid tokenId');
    require(_msgSender() == sftMinter, 'SFTE: Minter only');

    _cfolioItemTypes[tokenId] = cfolioItemType;

    // Dispatch event
    emit UpdatedCFolioType(tokenId, cfolioItemType);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  function _baseRate(uint256 sftTokenId) private view returns (uint32) {
    (uint32 untimed, ) = _baseRates(sftTokenId, 0);
    return untimed;
  }

  function _baseRates(uint256 tokenId, uint64 upgradeTime)
    private
    view
    returns (uint32 untimed, uint32 timed)
  {
    uint32[4] memory rates = [
      uint32(25e4),
      uint32(50e4),
      uint32(75e4),
      uint32(1e6)
    ];

    // Load state
    (uint64 time, uint8 level) = _sftHolder.getTokenData(
      tokenId.toSftTokenId()
    );

    uint32 update = (level & 3) <= 1 && time <= upgradeTime ? 125e3 : 0;

    return (rates[(level & 3)], rates[(level & 3)] + update);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../access/TestTetherOwnable.sol';

import './TestTetherIERC20.sol';

/*
 * Tether is not fully consistent with OZ's IERC20 interface. Therefore, we
 * can't derive from OZ's {ERC20} contract, and need a basic implementation
 * that matches mainnet behavior (0xdac17f958d2ee523a2206206994597c13d831ec7).
 *
 * This file contains three contracts:
 *
 *   - {TestBasicToken} - derived from {BasicToken} of the mainnet contract
 *   - {TestStandardToken} - derived from {StandardToken} of the mainnet contract
 *   - {TestTetherToken} - derived from {TetherToken} of the mainnet contract
 *
 * To create the contracts below, the code of Tether's three contracts was
 * imported unmodified. Then, the following transformations were performed:
 *
 *   - Mechanical removal of {Ownable} functionality
 *   - Mechanical removal of {Pausable} functionality
 *   - Mechanical removal of {Blacklist} functionality
 *   - Mechanical removal of {UpgradedStandardToken} functionality
 *   - Mechanical removal of {TetherToken-deprecated} functionality
 *   - Modernization to compile with Solidity >= 0.7.0
 *   - Addition of `solhint-disable-next-line reason-string` comments
 *   - Automated formatting with prettier-plugin-solidity
 *
 * Ref: https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7#code
 *
 * FOR TESTING ONLY.
 */

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract TestBasicToken is TestTetherOwnable, TestTetherIERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  // additional variables for use if transaction fees ever became necessary
  uint256 public basisPointsRate = 0;
  uint256 public maximumFee = 0;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    // solhint-disable-next-line reason-string
    require(!(msg.data.length < size + 4));
    _;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    public
    override
    onlyPayloadSize(2 * 32)
  {
    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    uint256 sendAmount = _value.sub(fee);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      Transfer(msg.sender, owner, fee);
    }
    Transfer(msg.sender, _to, sendAmount);
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return balance An uint representing the amount owned by the passed address.
   */
  function balanceOf(address _owner)
    public
    view
    override
    returns (uint256 balance)
  {
    return balances[_owner];
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract TestStandardToken is TestBasicToken {
  using SafeMath for uint256;

  mapping(address => mapping(address => uint256)) public allowed;

  uint256 public constant MAX_UINT = 2**256 - 1;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override onlyPayloadSize(3 * 32) {
    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }
    uint256 sendAmount = _value.sub(fee);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      Transfer(_from, owner, fee);
    }
    Transfer(_from, _to, sendAmount);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    override
    onlyPayloadSize(2 * 32)
  {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    // solhint-disable-next-line reason-string
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return remaining A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }
}

contract TestTetherToken is TestStandardToken {
  string public name;
  string public symbol;
  uint256 public decimals;
  address public upgradedAddress;

  //  The contract can be initialized with a number of tokens
  //  All the tokens are deposited to the owner address
  //
  // @param _balance Initial supply of the contract
  // @param _name Token Name
  // @param _symbol Token symbol
  // @param _decimals Token decimals
  constructor(
    uint256 _initialSupply,
    string memory _name,
    string memory _symbol,
    uint256 _decimals
  ) {
    _totalSupply = _initialSupply;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    balances[owner] = _initialSupply;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  // Issue a new amount of tokens
  // these tokens are deposited into the owner address
  //
  // @param _amount Number of tokens to be issued
  function issue(uint256 amount) public {
    // solhint-disable-next-line reason-string
    require(_totalSupply + amount > _totalSupply);
    // solhint-disable-next-line reason-string
    require(balances[owner] + amount > balances[owner]);

    balances[owner] += amount;
    _totalSupply += amount;
    Issue(amount);
  }

  // Called when new token are issued
  event Issue(uint256 amount);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title TestTetherOwnable
 *
 * @dev Ownership is not needed nor implemented for the test Tether token.
 * Transfer fees are issued to the owner, so set owner to address(0) to burn
 * the fees.
 *
 * This contract is a replacement for the {Ownable} contract of mainnet
 * Tether (0xdac17f958d2ee523a2206206994597c13d831ec7).
 *
 * See https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7#code
 *
 * FOR TESTING ONLY.
 */
contract TestTetherOwnable {
  /**
   * @dev Fees sent to the owner are burned
   */
  address public owner = address(0);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title TestTetherIERC20 interface
 *
 * @dev Because Tether is not fully consistent with OZ's IERC20 interface, a
 * specialized IERC20 interface is needed. The interface below comes from the
 * mainnet Tether contract (0xdac17f958d2ee523a2206206994597c13d831ec7).
 *
 * Functions from {ERC20Basic} and {ERC20} of the Tether contract are
 * concatenated and modernized to form the interface here.
 *
 * Ref: https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7#code
 *
 * FOR TESTING ONLY.
 */
abstract contract TestTetherIERC20 {
  uint256 public _totalSupply;

  function totalSupply() public view virtual returns (uint256);

  function balanceOf(address who) public view virtual returns (uint256);

  function transfer(address to, uint256 value) public virtual;

  function allowance(address owner, address spender)
    public
    view
    virtual
    returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public virtual;

  function approve(address spender, uint256 value) public virtual;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import './TestTetherToken.sol';

/**
 * @dev Extension of {TestTetherToken} that allows anyone to mint tokens to
 * arbitrary accounts.
 *
 * FOR TESTING ONLY.
 */
contract TestTetherMintable is TestTetherToken {
  /**
   *  The contract can be initialized with a number of tokens
   *  All the tokens are deposited to the owner address
   *
   * @param _initialSupply Initial supply of the contract
   * @param _name Token Name
   * @param _symbol Token symbol
   * @param _decimals Token decimals
   */
  constructor(
    uint256 _initialSupply,
    string memory _name,
    string memory _symbol,
    uint256 _decimals
  ) TestTetherToken(_initialSupply, _name, _symbol, _decimals) {}

  //////////////////////////////////////////////////////////////////////////////
  // Minting interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Creates `amount` tokens and assigns them to `account`, increasing the
   * total supply.
   *
   * Emits a {TestTetherToken-Issue} event.
   */
  function mint(address to, uint256 amount) public {
    // Tokens are issued to the owner
    owner = to;
    super.issue(amount);
    owner = address(0);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '../token/TestTetherMintable.sol';

// Mainnet address: 0xdac17f958d2ee523a2206206994597c13d831ec7
// Yearn vault address: 0x83f798e925BcD4017Eb265844FDDAbb448f1707D
contract TetherToken is TestTetherMintable {
  constructor()
    TestTetherMintable(100000000000, 'Funny Tether USD', 'USDT', 6)
  {}
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../../interfaces/uniswap/IUniswapV2Factory.sol';
import '../../interfaces/uniswap/IUniswapV2Router02.sol';

import '../investment/interfaces/IStakeFarm.sol';
import '../token/interfaces/IERC20WowsMintable.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/AddressBook.sol';
import '../utils/ERC20Recovery.sol';

/**
 * @title Crowdsale
 *
 * @dev Crowdsale is a base contract for managing a token crowdsale, allowing
 * investors to purchase tokens with ether. This contract implements such
 * functionality in its most fundamental form and can be extended to provide
 * additional functionality and/or custom behavior.
 *
 * The external interface represents the basic interface for purchasing tokens,
 * and conforms the base architecture for crowdsales. It is *not* intended to
 * be modified / overridden.
 *
 * The internal interface conforms the extensible and modifiable surface of
 * crowdsales. Override the methods to add functionality. Consider using 'super'
 * where appropriate to concatenate behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, ERC20Recovery {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20WowsMintable;

  // The token being sold
  IERC20WowsMintable public token;

  // Address where funds are collected
  address payable private _wallet;

  // How many token units a buyer gets per wei.
  //
  // The rate is the conversion between wei and the smallest and indivisible
  // token unit. So, if you are using a rate of 1 with a ERC20Detailed token
  // with 3 decimals called TOK 1 wei will give you 1 unit, or 0.001 TOK.
  //
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  uint256 public cap;
  uint256 public investMin;
  uint256 public walletCap;

  uint256 public openingTime;
  uint256 public closingTime;

  // Per wallet investment (in wei)
  mapping(address => uint256) private _walletInvest;

  /**
   * Event for token purchase logging
   *
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * Event for add liquidity logging
   *
   * @param beneficiary who got the tokens
   * @param amountToken how many token were added
   * @param amountETH how many ETH were added
   * @param liquidity how many pool tokens were created
   */
  event LiquidityAdded(
    address indexed beneficiary,
    uint256 amountToken,
    uint256 amountETH,
    uint256 liquidity
  );

  /**
   * Event for stake liquidity logging
   *
   * @param beneficiary who got the tokens
   * @param liquidity how many pool tokens were created
   */
  event Staked(address indexed beneficiary, uint256 liquidity);

  // Uniswap Router for providing liquidity
  IUniswapV2Router02 public immutable uniV2Router;
  IERC20 public immutable uniV2Pair;

  IStakeFarm public immutable stakeFarm;

  // Rate of tokens to insert into the UNISwapv2 liquidity pool
  //
  // Because they will be devided, expanding by multiples of 10
  // is fine to express decimal values.
  //
  uint256 private tokenForLp;
  uint256 private ethForLp;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen() {
    require(isOpen(), 'not open');
    _;
  }

  /**
   * @dev Crowdsale constructor
   *
   * @param _addressRegistry IAdressRegistry to get wallet and uniV2Router02
   * @param _rate Number of token units a buyer gets per wei
   *
   * The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   *
   * @param _token Address of the token being sold
   * @param _cap Max amount of wei to be contributed
   * @param _investMin minimum investment in wei
   * @param _walletCap Max amount of wei to be contributed per wallet
   * @param _lpEth numerator of liquidity pair
   * @param _lpToken denominator of liquidity pair
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(
    IAddressRegistry _addressRegistry,
    uint256 _rate,
    IERC20WowsMintable _token,
    uint256 _cap,
    uint256 _investMin,
    uint256 _walletCap,
    uint256 _lpEth,
    uint256 _lpToken,
    uint256 _openingTime,
    uint256 _closingTime
  ) {
    require(_rate > 0, 'rate is 0');
    require(address(_token) != address(0), 'token is addr(0)');
    require(_cap > 0, 'cap is 0');
    require(_lpEth > 0, 'lpEth is 0');
    require(_lpToken > 0, 'lpToken is 0');

    // solhint-disable-next-line not-rely-on-time
    require(_openingTime >= block.timestamp, 'opening > now');
    require(_closingTime > _openingTime, 'open > close');

    // Reverts if address is invalid
    IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(
      _addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_ROUTER02)
    );
    uniV2Router = _uniV2Router;

    // Get our liquidity pair
    address _uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).getPair(
      address(_token),
      _uniV2Router.WETH()
    );
    require(_uniV2Pair != address(0), 'invalid pair');
    uniV2Pair = IERC20(_uniV2Pair);

    // Reverts if address is invalid
    address _marketingWallet = _addressRegistry.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    _wallet = payable(_marketingWallet);

    // Reverts if address is invalid
    address _stakeFarm = _addressRegistry.getRegistryEntry(
      AddressBook.WETH_WOWS_STAKE_FARM
    );
    stakeFarm = IStakeFarm(_stakeFarm);

    rate = _rate;
    token = _token;
    cap = _cap;
    investMin = _investMin;
    walletCap = _walletCap;
    ethForLp = _lpEth;
    tokenForLp = _lpToken;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Fallback function ***DO NOT OVERRIDE***
   *
   * Note that other contracts will transfer funds with a base gas stipend
   * of 2300, which is not enough to call buyTokens. Consider calling
   * buyTokens directly when purchasing tokens from a contract.
   */
  receive() external payable {
    // A payable receive() function follows the OpenZeppelin strategy, in which
    // it is designed to buy tokens.
    //
    // However, because we call out to uniV2Router from the crowdsale contract,
    // re-imbursement of ETH from UniswapV2Pair must not buy tokens.
    //
    // Instead it must be payed to this contract as a first step and will then
    // be transferred to the recipient in _addLiquidity().
    //
    if (_msgSender() != address(uniV2Router)) buyTokens(_msgSender());
  }

  /**
   * @dev Checks whether the cap has been reached
   *
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @return True if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   *
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp > closingTime;
  }

  /**
   * @dev Provide a collection of UI relevant values to reduce # of queries
   *
   * @return ethRaised Amount eth raised (wei)
   * @return timeOpen Time presale opens (unix timestamp seconds)
   * @return timeClose Time presale closes (unix timestamp seconds)
   * @return timeNow Current time (unix timestamp seconds)
   * @return userEthInvested Amount of ETH users have already spent (wei)
   * @return userTokenAmount Amount of token held by user (token::decimals)
   */
  function getStates(address beneficiary)
    public
    view
    returns (
      uint256 ethRaised,
      uint256 timeOpen,
      uint256 timeClose,
      uint256 timeNow,
      uint256 userEthInvested,
      uint256 userTokenAmount
    )
  {
    uint256 tokenAmount = beneficiary == address(0)
      ? 0
      : token.balanceOf(beneficiary);
    uint256 ethInvest = _walletInvest[beneficiary];

    return (
      weiRaised,
      openingTime,
      closingTime,
      // solhint-disable-next-line not-rely-on-time
      block.timestamp,
      ethInvest,
      tokenAmount
    );
  }

  /**
   * @dev Low level token purchase ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokens(address beneficiary) public payable nonReentrant {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // Calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // Update state
    weiRaised = weiRaised.add(weiAmount);
    _walletInvest[beneficiary] = _walletInvest[beneficiary].add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

    _forwardFunds(weiAmount);
  }

  /**
   * @dev Low level token purchase and liquidity staking ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokensAddLiquidity(address payable beneficiary)
    public
    payable
    nonReentrant
  {
    uint256 weiAmount = msg.value;

    // The ETH amount we buy WOWS token for
    uint256 buyAmount = weiAmount.mul(tokenForLp).div(
      rate.mul(ethForLp).add(tokenForLp)
    );

    // The ETH amount we invest for liquidity (ETH + WOLF)
    uint256 investAmount = weiAmount.sub(buyAmount);

    _preValidatePurchase(beneficiary, buyAmount);

    // Calculate token amount to be created
    uint256 tokens = _getTokenAmount(buyAmount);

    // Verify that the ratio is in 0.1% limit
    uint256 tokensReverse = investAmount.mul(tokenForLp).div(ethForLp);
    require(
      tokens < tokensReverse || tokens.sub(tokensReverse) < tokens.div(1000),
      'ratio wrong'
    );
    require(
      tokens > tokensReverse || tokensReverse.sub(tokens) < tokens.div(1000),
      'ratio wrong'
    );

    // Update state
    weiRaised = weiRaised.add(buyAmount);
    _walletInvest[beneficiary] = _walletInvest[beneficiary].add(buyAmount);

    _processLiquidity(beneficiary, investAmount, tokens);

    _forwardFunds(buyAmount);
  }

  /**
   * @dev Low level token liquidity staking ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * approve() must be called before to let us transfer msgsenders tokens.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function addLiquidity(address payable beneficiary)
    public
    payable
    nonReentrant
    onlyWhileOpen
  {
    uint256 weiAmount = msg.value;
    require(beneficiary != address(0), 'beneficiary is the zero address');
    require(weiAmount != 0, 'weiAmount is 0');

    // Calculate number of tokens
    uint256 tokenAmount = weiAmount.mul(tokenForLp).div(ethForLp);
    require(token.balanceOf(_msgSender()) >= tokenAmount, 'insufficient token');

    // Get the tokens from msg.sender
    token.safeTransferFrom(_msgSender(), address(this), tokenAmount);

    // Step 1: add liquidity
    uint256 lpToken = _addLiquidity(
      address(this),
      beneficiary,
      weiAmount,
      tokenAmount
    );

    // Step 2: we now own the liquidity tokens, stake them
    uniV2Pair.approve(address(stakeFarm), lpToken);
    stakeFarm.stake(lpToken);

    // Step 3: transfer the stake to the user
    stakeFarm.transfer(beneficiary, lpToken);

    emit Staked(beneficiary, lpToken);
  }

  /**
   * @dev Finalize presale / create liquidity pool
   */
  function finalizePresale() external {
    require(hasClosed(), 'not closed');

    uint256 ethBalance = address(this).balance;
    require(ethBalance > 0, 'no eth balance');

    // Calculate how many token we add into liquidity pool
    uint256 tokenToLp = (ethBalance.mul(tokenForLp)).div(ethForLp);

    // Calculate amount unsold token
    uint256 tokenUnsold = cap.sub(weiRaised).mul(rate);

    // Mint token we spend
    require(
      token.mint(address(this), tokenToLp.add(tokenUnsold)),
      'minting failed'
    );

    _addLiquidity(_wallet, _wallet, ethBalance, tokenToLp);

    // Transfer all tokens from this contract to _wallet
    uint256 tokenInContract = token.balanceOf(address(this));
    if (tokenInContract > 0) token.safeTransfer(_wallet, tokenInContract);

    // Finally whitelist uniV2 LP pool on token contract
    token.enableUniV2Pair(true);
  }

  /**
   * @dev Added to support recovering LP Rewards from other systems to be distributed to holders
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(msg.sender == _wallet, 'restricted to wallet');
    require(hasClosed(), 'not closed');
    // Cannot recover the staking token or the rewards token
    require(tokenAddress != address(token), 'native tokens unrecoverable');

    // Call ancestor
    _recoverERC20(_wallet, tokenAddress, tokenAmount);
  }

  /**
   * @dev Change the closing time which gives you the possibility
   * to either shorten or enlarge the presale period
   */
  function setClosingTime(uint256 newClosingTime) external {
    require(msg.sender == _wallet, 'restricted to wallet');
    require(newClosingTime > openingTime, 'close < open');

    closingTime = newClosingTime;
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert
   * state when conditions are not met
   *
   * Use `super` in contracts that inherit from Crowdsale to extend their validations.
   *
   * Example from CappedCrowdsale.sol's _preValidatePurchase method:
   *     super._preValidatePurchase(beneficiary, weiAmount);
   *     require(weiRaised().add(weiAmount) <= cap);
   *
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address beneficiary, uint256 weiAmount)
    internal
    view
    onlyWhileOpen
  {
    require(beneficiary != address(0), 'beneficiary zero address');
    require(weiAmount != 0, 'weiAmount is 0');
    require(weiRaised.add(weiAmount) <= cap, 'cap exceeded');
    require(weiAmount >= investMin, 'invest too small');
    require(
      _walletInvest[beneficiary].add(weiAmount) <= walletCap,
      'wallet-cap exceeded'
    );

    // Silence state mutability warning without generating bytecode - see
    // https://github.com/ethereum/solidity/issues/2691
    this;
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed
   *
   * Doesn't necessarily emit/send tokens.
   *
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount)
    internal
  {
    require(token.mint(address(this), _tokenAmount), 'minting failed');
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed
   *
   * This function adds liquidity and stakes the liquidity in our initial farm.
   *
   * @param beneficiary Address receiving the tokens
   * @param ethAmount Amount of ETH provided
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processLiquidity(
    address payable beneficiary,
    uint256 ethAmount,
    uint256 tokenAmount
  ) internal {
    require(token.mint(address(this), tokenAmount), 'minting failed');

    // Step 1: add liquidity
    uint256 lpToken = _addLiquidity(
      address(this),
      beneficiary,
      ethAmount,
      tokenAmount
    );

    // Step 2: we now own the liquidity tokens, stake them
    // Allow stakeFarm to own our tokens
    uniV2Pair.approve(address(stakeFarm), lpToken);
    stakeFarm.stake(lpToken);

    // Step 3: transfer the stake to the user
    stakeFarm.transfer(beneficiary, lpToken);

    emit Staked(beneficiary, lpToken);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   *
   * @param weiAmount Value in wei to be converted into tokens
   *
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 weiAmount) internal {
    _wallet.transfer(weiAmount.div(2));
  }

  function _addLiquidity(
    address tokenOwner,
    address payable remainingReceiver,
    uint256 ethBalance,
    uint256 tokenBalance
  ) internal returns (uint256) {
    // Add Liquidity, receiver of pool tokens is _wallet
    token.approve(address(uniV2Router), tokenBalance);

    (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniV2Router
      .addLiquidityETH{ value: ethBalance }(
      address(token),
      tokenBalance,
      tokenBalance.mul(90).div(100),
      ethBalance.mul(90).div(100),
      tokenOwner,
      // solhint-disable-next-line not-rely-on-time
      block.timestamp + 86400
    );

    emit LiquidityAdded(tokenOwner, amountToken, amountETH, liquidity);

    // Send remaining ETH to the team wallet
    if (amountETH < ethBalance)
      remainingReceiver.transfer(ethBalance.sub(amountETH));

    // Send remaining WOWS token to team wallet
    if (amountToken < tokenBalance)
      token.safeTransfer(remainingReceiver, tokenBalance.sub(amountToken));

    return liquidity;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

