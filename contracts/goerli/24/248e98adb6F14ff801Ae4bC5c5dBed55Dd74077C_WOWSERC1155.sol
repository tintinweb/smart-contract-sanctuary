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
    // solhint-disable-next-line no-inline-assembly
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
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

  //////////////////////////////////////////////////////////////////////////////
  // Asset access
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Adds investments into a cFolioItem SFT
   *
   * Transfers amounts of assets from users wallet to the contract. In general,
   * an Approval call is required before the function is called.
   *
   * @param from must be msg.sender for calls not from sftMinter
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function deposit(
    address from,
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
   * @dev Update investment values from sidechain
   *
   * Must be called from a registered root tunnel
   *
   * @param tokenId cFolioItem tokenId
   * @param amounts Investment amounts, implementation specific
   */
  function update(uint256 tokenId, uint256[] calldata amounts) external;

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
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/interfaces/IERC1155TokenReceiver.sol';
import '../../0xerc1155/utils/Address.sol';

import './interfaces/IWOWSCryptofolio.sol';
import './interfaces/IWOWSERC1155.sol';
import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../utils/Clones.sol';
import '../utils/TokenIds.sol';

contract WOWSERC1155 is IWOWSERC1155, AccessControl {
  using TokenIds for uint256;
  using Address for address;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // Role to mint new tokens
  bytes32 public constant MINTER_ROLE = 'MINTER_ROLE';

  // Role which is allowed to call chain related functions
  bytes32 public constant CHAIN_ROLE = 'CHAIN_ROLE';

  // Token receiver return value
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Pause all transfer operations
  bool public pause;

  // Card state of custom NFT's
  mapping(uint256 => uint8) private _customLevels;

  struct ListKey {
    uint256 index;
  }

  // Per-token data
  struct TokenInfo {
    address owner; // Make sure we only mint 1
    uint64 timestamp;
    ListKey listKey; // Next tokenId in the owner linkedList
  }
  mapping(uint256 => TokenInfo) private _tokenInfos;

  struct ExternalNft {
    address collection;
    uint256 tokenId;
  }
  mapping(uint256 => ExternalNft) public externalNfts;

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

  // cfolioType of cfolioItem
  mapping(uint256 => uint256) private _cfolioItemTypes;

  // Our master cryptofolio used for clones
  address public cryptofolio;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'SFT: Only admin');
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), 'SFT: Only minter');
    _;
  }

  modifier onlyChain() {
    require(hasRole(CHAIN_ROLE, _msgSender()), 'SFT: Only chain operator');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Fired on each transfer operation
  event SftTokenTransfer(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] tokenIds
  );

  // Fired if the type of a CFolioItem is set
  event UpdatedCFolioType(uint256 indexed tokenId, uint256 cfolioItemType);

  // Fired if a Cryptofolio clone was set
  event CryptofolioSet(address cryptofolio);

  // Fired if a SidechainTunnel was set
  event SidechainTunnelSet(address sidechainTunnel);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /*
   * @dev URI is for WOWS predefined NFT's
   *
   * The other token URI's must be set separately.
   */
  constructor(address owner) {
    // Initialize {AccessControl}
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
  }

  function initialize(address owner) public {
    // Check for one time initialization
    require(
      getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0,
      'SFT: Already initialized'
    );

    // Initialize {AccessControl}
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * See {IWOWSERC1155-mintBatch}.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external override onlyMinter {
    // Validate parameters
    require(to != address(0), 'SFT: Zero address');

    _tokenTransfer(address(0), to, tokenIds, data);
  }

  /**
   * See {IWOWSERC1155-burnBatch}.
   */
  function burnBatch(address account, uint256[] calldata tokenIds)
    external
    override
  {
    // Validate access
    require(account == _msgSender(), 'SFT: Caller not owner');

    _tokenTransfer(account, address(0), tokenIds, '');
  }

  /**
   * See {IWOWSERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external override {
    require(from != address(0) && to != address(0), 'SFT: Null address');
    require(amount == 1, 'SFT: Wrong amount');

    _tokenTransfer(from, to, _toArray(tokenId), data);
  }

  /**
   * See {IWOWSERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external override {
    require(from != address(0) && to != address(0), 'SFT: Null address');
    require(
      amounts.length == 0 || tokenIds.length == amounts.length,
      'SFT: Length mismatch'
    );
    if (amounts.length > 0) {
      for (uint256 i = 0; i < amounts.length; ++i)
        require(amounts[i] == 1, 'SFT: Wrong amount');
    }

    _tokenTransfer(from, to, tokenIds, data);
  }

  /**
   * @dev See {IWOWSERC1155-addressToTokenId}.
   */
  function addressToTokenId(address tokenAddress)
    public
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
   * @dev See {IWOWSERC1155-setCustomCardLevel}.
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel)
    public
    override
    onlyMinter
  {
    // Validate parameter
    require(!tokenId.isCustomCard(), 'SFT: Only custom cards');

    // Update state
    _customLevels[tokenId] = cardLevel;
  }

  /**
   * @dev See {IWOWSERC1155-setCFolioType}.
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType)
    external
    override
    onlyMinter
  {
    require(tokenId.isCFolioCard(), 'SFT: Invalid tokenId');

    _cfolioItemTypes[tokenId] = cfolioItemType;

    // Dispatch event
    emit UpdatedCFolioType(tokenId, cfolioItemType);
  }

  /**
   * @dev See {IWOWSERC1155-setExternalNft}.
   */
  function setExternalNft(
    uint256 tokenId,
    address externalCollection,
    uint256 externalTokenId
  ) external override onlyMinter {
    ExternalNft storage nft = externalNfts[tokenId];

    nft.collection = externalCollection;
    nft.tokenId = externalTokenId;
  }

  /**
   * @dev See {IWOWSERC1155-deleteExternalNft}.
   */
  function deleteExternalNft(uint256 tokenId) external override onlyMinter {
    delete (externalNfts[tokenId]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

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
    public
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

  /**
   * @dev See {IWOWSERC1155-getCFolioItemType}.
   */
  function getCFolioItemType(uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    // Validate parameters
    require(tokenId.isCFolioCard(), 'SFT: Invalid tokenId');

    // Load state
    return _cfolioItemTypes[tokenId.toSftTokenId()];
  }

  /**
   * @dev See {IWOWSERC1155-balanceOf}.
   */
  function balanceOf(address owner, uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    return _tokenInfos[tokenId].owner == owner ? 1 : 0;
  }

  /**
   * @dev See {IWOWSERC1155-balanceOfBatch}.
   */
  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata tokenIds
  ) external view override returns (uint256[] memory) {
    require(owners.length == tokenIds.length, 'SFT: Length mismatch');
    uint256[] memory result = new uint256[](owners.length);

    for (uint256 i = 0; i < owners.length; ++i)
      result[i] = _tokenInfos[tokenIds[i]].owner == owners[i] ? 1 : 0;

    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Maintanance
  //////////////////////////////////////////////////////////////////////////////

  // Pause all transfer operations
  function setPause(bool _pause) external onlyAdmin {
    pause = _pause;
  }

  // Set Cryptofolio clone
  function setCryptofolio(address newCryptofolio) external onlyAdmin {
    cryptofolio = newCryptofolio;
    emit CryptofolioSet(cryptofolio);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Handles transfer of an SFT token
   */
  function _tokenTransfer(
    address from,
    address to,
    uint256[] memory tokenIds,
    bytes memory data
  ) private {
    require(!pause, 'SFT: Paused!');

    uint256 numUniqueCFolioHandlers = 0;
    address[] memory uniqueCFolioHandlers = new address[](tokenIds.length);
    address[] memory cFolioHandlers = new address[](tokenIds.length);
    uint256 toTokenId = to == address(0) ? uint256(-1) : addressToTokenId(to);
    uint256 timestampPosition = 1;

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];

      // Load state
      address tokenAddress = _tokenIdToAddress[tokenId];
      TokenInfo storage tokenInfo = _tokenInfos[tokenId];

      // Minting
      if (from == address(0)) {
        // Validate state
        require(tokenInfo.owner == address(0), 'SFT: Already minted');

        // solhint-disable-next-line not-rely-on-time
        tokenInfo.timestamp = uint64(block.timestamp);

        // Create a new WOWSCryptofolio by cloning masterTokenReceiver
        // The clone itself is a minimal delegate proxy.
        if (tokenAddress == address(0)) {
          tokenAddress = Clones.clone(cryptofolio);
          _tokenIdToAddress[tokenId] = tokenAddress;
          if (tokenId.isCFolioCard()) {
            require(data.length == 20, 'SFT: Invalid data');
            address handler = _getAddress(data);
            require(handler != address(0), 'SFT: Invalid address');
            IWOWSCryptofolio(tokenAddress).setHandler(handler);
          } else if (data.length >= 64) {
            //Migration / Bridge. First uint is recipient
            tokenInfo.timestamp = uint64(_getUint256(data, timestampPosition));
            timestampPosition = _nextTimestamp(data, timestampPosition);
          }
        }
        _addressToTokenId[tokenAddress] = tokenId;
      }
      // Burning
      else {
        if (to == address(0)) {
          // Make sure underlying assets gets burned
          if (tokenId.isBaseCard()) {
            uint256[] memory cfolioItems = getTokenIds(tokenAddress);
            if (cfolioItems.length > 0) {
              _tokenTransfer(tokenAddress, to, cfolioItems, data);
            }
          }
        }
        // Allow transfer only if from is either owner or owner of cfolio.
        require(
          tokenInfo.owner == from || _cfolioOwner(tokenInfo.owner) == from,
          'SFT: Access denied'
        );
      }
      // Update state
      tokenInfo.owner = to;

      if (!tokenId.isBaseCard()) {
        address handler = IWOWSCryptofolio(tokenAddress).handler();
        uint256 iter = numUniqueCFolioHandlers;
        while (iter > 0 && uniqueCFolioHandlers[iter - 1] != handler) --iter;
        if (iter == 0) {
          require(handler != address(0), 'SFT: Invalid handler');
          uniqueCFolioHandlers[numUniqueCFolioHandlers++] = handler;
        }
        cFolioHandlers[i] = handler;
      } else {
        // Avoid cfolio as child of cfolio
        require(toTokenId == uint256(-1), 'SFT: Invalid to');
      }

      // Remove tokenId from List
      if (from != address(0)) {
        // Load state
        Owned storage fromList = _owned[from];

        // Validate state
        require(fromList.count > 0, 'SFT: Count mismatch');

        ListKey storage key = fromList.listKey;
        uint256 count = fromList.count;

        // Search the token which links to tokenId
        for (; count > 0 && key.index != tokenId; --count)
          key = _tokenInfos[key.index].listKey;
        require(key.index == tokenId, 'SFT: Key mismatch');

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

    // Notify to that NFT's has arrived
    if (to.isContract()) {
      uint256[] memory amounts = new uint256[](tokenIds.length);
      for (uint256 i = 0; i < tokenIds.length; ++i) amounts[i] = 1;
      bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(
        msg.sender,
        from,
        tokenIds,
        amounts,
        data
      );
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, 'SFTE: Unsupported');
    }

    for (uint256 i = 0; i < numUniqueCFolioHandlers; ++i) {
      ICFolioItemHandler(uniqueCFolioHandlers[i]).onCFolioItemsTransferedFrom(
        from,
        to,
        tokenIds,
        cFolioHandlers
      );
    }
    emit SftTokenTransfer(_msgSender(), from, to, tokenIds);
  }

  /**
   * @dev Get the level of a given token
   *
   * @param tokenId The ID of the token
   *
   * @return level The level of the token
   */
  function _getLevel(uint256 tokenId) private view returns (uint8 level) {
    if (tokenId.isCustomCard()) {
      level = _customLevels[tokenId];
    } else {
      level = uint8(tokenId >> 24);
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
   * @dev Get the uint256 from the user data parameter
   */
  function _getUint256(bytes memory data, uint256 index)
    private
    pure
    returns (uint256 val)
  {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      val := mload(add(data, mul(0x20, add(index, 1))))
    }
  }

  /**
   * @dev Convert uint to uint[](1)
   */
  function _toArray(uint256 value)
    private
    pure
    returns (uint256[] memory result)
  {
    result = new uint256[](1);
    result[0] = value;
  }

  /**
   * @dev Return owner of cfolio
   */
  function _cfolioOwner(address cfolio) private view returns (address) {
    uint256 tokenId = addressToTokenId(cfolio);
    if (tokenId == uint256(-1)) return address(0);
    return _tokenInfos[tokenId].owner;
  }

  /**
   * @dev Skip migrationdata until next timestamp
   */
  function _nextTimestamp(bytes memory data, uint256 currentIndex)
    private
    pure
    returns (uint256 newIndex)
  {
    // Skip CFolioItems
    newIndex = currentIndex + _getUint256(data, currentIndex + 1) + 2;
    // Skip BoosterData
    if (_getUint256(data, newIndex++) > 0) newIndex += 6;
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
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 */
interface IWOWSCryptofolio {
  //////////////////////////////////////////////////////////////////////////////
  // Getter
  //////////////////////////////////////////////////////////////////////////////
  /**
   * @dev Return the handler (CFIH) of the underlying NFT
   */
  function handler() external view returns (address);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////
  /**
   * @dev Set the handler of the underlying NFT
   *
   * This function is called during I-NFT setup
   *
   * @param newHandler The new handler of the underlying NFT,
   */
  function setHandler(address newHandler) external;
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
 * @notice Sft holder contract
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

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

  /**
   * @dev Returns the cFolioItemType of a given cFolioItem tokenId
   */
  function getCFolioItemType(uint256 tokenId) external view returns (uint256);

  /**
   * @notice Get the balance of an account's Tokens
   * @param owner  The address of the token holder
   * @param tokenId ID of the Token
   * @return The _owner's balance of the token type requested
   */
  function balanceOf(address owner, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param owners The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return       The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata tokenIds
  ) external view returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Mints tokenIds into 'to' account
   * @dev Emits SftTokenTransfer Event
   *
   * Throws if sender has no MINTER_ROLE
   * 'data' holds the CFolioItemHandler if CFI's are minted
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external;

  /**
   * @notice Burns tokenIds owned by 'account'
   * @dev Emits SftTokenTransfer Event
   *
   * Burns all owned CFolioItems
   * Throws if CFolioItems have assets
   */
  function burnBatch(address account, uint256[] calldata tokenIds) external;

  /**
   * @notice Transfers amount of an id from the from address to the 'to' address specified
   * @dev Emits SftTokenTransfer Event
   * Throws if 'to' is the zero address
   * Throws if 'from' is not the current owner
   * If 'to' is a smart contract, ERC1155TokenReceiver interface will checked
   * @param from    Source address
   * @param to      Target address
   * @param tokenId ID of the token type
   * @param amount  Transfered amount
   * @param data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev Batch version of {safeTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;

  /**
   * @dev Sets the cfolioItemType of a cfolioItem tokenId, not yet used
   * sftHolder tokenId expected (without hash)
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType_) external;

  /**
   * @dev Sets external NFT for display tokenId
   * By default NFT is rendered using our internal metadata
   *
   * Throws if not called from MINTER role
   */
  function setExternalNft(
    uint256 tokenId,
    address externalCollection,
    uint256 externalTokenId
  ) external;

  /**
   * @dev Deletes external NFT settings
   *
   * Throws if not called from MINTER role
   */
  function deleteExternalNft(uint256 tokenId) external;
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
      mstore(
        ptr,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(ptr, 0x14), shl(0x60, master))
      mstore(
        add(ptr, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      instance := create(0, ptr, 0x37)
    }
    require(instance != address(0), 'ERC1167: create failed');
  }

  /**
   * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
   *
   * This function uses the create2 opcode and a `salt` to deterministically deploy
   * the clone. Using the same `master` and `salt` multiple time will revert, since
   * the clones cannot be deployed twice at the same address.
   */
  function cloneDeterministic(address master, bytes32 salt)
    internal
    returns (address instance)
  {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(ptr, 0x14), shl(0x60, master))
      mstore(
        add(ptr, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      instance := create2(0, ptr, 0x37, salt)
    }
    require(instance != address(0), 'ERC1167: create2 failed');
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
   */
  function predictDeterministicAddress(
    address master,
    bytes32 salt,
    address deployer
  ) internal pure returns (address predicted) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(ptr, 0x14), shl(0x60, master))
      mstore(
        add(ptr, 0x28),
        0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
      )
      mstore(add(ptr, 0x38), shl(0x60, deployer))
      mstore(add(ptr, 0x4c), salt)
      mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
      predicted := keccak256(add(ptr, 0x37), 0x55)
    }
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
   */
  function predictDeterministicAddress(address master, bytes32 salt)
    internal
    view
    returns (address predicted)
  {
    return predictDeterministicAddress(master, salt, address(this));
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

library TokenIds {
  // 128 bit underlying hash
  uint256 public constant HASH_MASK = (1 << 128) - 1;

  function isBaseCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 64);
  }

  function isStockCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 32);
  }

  function isCustomCard(uint256 tokenId) internal pure returns (bool) {
    return
      (tokenId & HASH_MASK) >= (1 << 32) && (tokenId & HASH_MASK) < (1 << 64);
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

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
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