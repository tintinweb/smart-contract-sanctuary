/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/interfaces/IERC721Token.sol

// SPDX-License-Identifier: MIT

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.6.12;


interface IERC721Token {

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///      This event emits when NFTs are created (`from` == 0) and destroyed
    ///      (`to` == 0). Exception: during contract creation, any number of NFTs
    ///      may be created and assigned without emitting Transfer. At the time of
    ///      any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///      reaffirmed. The zero address indicates there is no approved address.
    ///      When a Transfer event emits, this also indicates that the approved
    ///      address for that NFT (if any) is reset to none.
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///      The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///      except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      perator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
    external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
    external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved)
    external;

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner)
    external
    view
    returns (uint256);

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external;

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address);

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
    external
    view
    returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool);
}

// File: contracts/interfaces/IERC721Receiver.sol


/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.6.12;


interface IERC721Receiver {

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
    external
    returns (bytes4);
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

pragma solidity ^0.6.0;

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
 * As of v2.5.0, only `address` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.AddressSet;`.
 *
 * @author Alberto Cuesta Cañada
 */
library EnumerableSet {

    struct AddressSet {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (address => uint256) index;
        address[] values;
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        if (!contains(set, value)) {
            set.values.push(value);
            // The element is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set.index[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                address lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        address[] memory output = new address[](set.values.length);
        for (uint256 i; i < set.values.length; i++){
            output[i] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(AddressSet storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return set.values[index];
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

pragma solidity ^0.6.0;



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
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked programatically by calling the `internal`
 * {_grantRole} and {_revokeRole} functions.
 *
 * This can also be achieved dynamically via the `external` {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRoke}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `grantRole`, it is the admin role bearer
     *   - if using `_grantRole`, its meaning is system-dependent
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     *   - if using `_renounceRole`, its meaning is system-dependent
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
        return _roles[role].members.get(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Calls {_grantRole} internally.
     *
     * Requirements:
     *
     * - the caller must have `role`'s admin role.
     */
    function grantRole(bytes32 role, address account) external virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Calls {_revokeRole} internally.
     *
     * Requirements:
     *
     * - the caller must have `role`'s admin role.
     */
    function revokeRole(bytes32 role, address account) external virtual {
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
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev Sets `adminRole` as `role`'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }
}

// File: contracts/EphimeraAccessControls.sol

pragma solidity 0.6.12;


contract EphimeraAccessControls is AccessControl {
    // Role definitions
    bytes32 public constant GALLERY_ROLE = keccak256("GALLERY_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant CONTRACT_WHITELIST_ROLE = keccak256(
        "CONTRACT_WHITELIST_ROLE"
    );

    // Relationship mappings
    mapping(address => mapping(address => bool)) public galleryToArtistMapping;
    mapping(address => mapping(address => bool))
        public artistToGalleriesMapping;

    // Events
    event ArtistAddedToGallery(
        address indexed gallery,
        address indexed artist,
        address indexed caller
    );

    event ArtistRemovedFromGallery(
        address indexed gallery,
        address indexed artist,
        address indexed caller
    );

    event NewAdminAdded(address indexed admin);

    event AdminRemoved(address indexed admin);

    event NewArtistAdded(address indexed artist);

    event ArtistRemoved(address indexed artist);

    event NewGalleryAdded(address indexed gallery);

    event GalleryRemoved(address indexed gallery);

    constructor() public {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /////////////
    // Lookups //
    /////////////

    function hasGalleryRole(address _address) public view returns (bool) {
        return hasRole(GALLERY_ROLE, _address);
    }

    function hasCreatorRole(address _address) public view returns (bool) {
        return hasRole(CREATOR_ROLE, _address);
    }

    function hasAdminRole(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function hasContractWhitelistRole(address _address)
        public
        view
        returns (bool)
    {
        return hasRole(CONTRACT_WHITELIST_ROLE, _address);
    }

    function isArtistPartOfGallery(address _gallery, address _artist)
        public
        view
        returns (bool)
    {
        return galleryToArtistMapping[_gallery][_artist];
    }

    ///////////////
    // Modifiers //
    ///////////////

    modifier onlyAdminRole() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "EphimeraAccessControls: sender must be an admin"
        );
        _;
    }

    function addAdminRole(address _address) public onlyAdminRole {
        require(
            !hasAdminRole(_address),
            "EphimeraAccessControls: Account already has an admin role"
        );
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit NewAdminAdded(_address);
    }

    function removeAdminRole(address _address) public onlyAdminRole {
        require(
            hasAdminRole(_address),
            "EphimeraAccessControls: Account is not an admin"
        );
        _revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRemoved(_address);
    }

    function addContractWhitelistRole(address _address) public onlyAdminRole {
        require(
            !hasContractWhitelistRole(_address),
            "EphimeraAccessControls: Address has contractWhitelist role"
        );
        _grantRole(CONTRACT_WHITELIST_ROLE, _address);
    }

    function removeContractWhitelistRole(address _address)
        public
        onlyAdminRole
    {
        require(
            hasContractWhitelistRole(_address),
            "EphimeraAccessControls: Address must have contractWhitelist role"
        );
        _revokeRole(CONTRACT_WHITELIST_ROLE, _address);
    }

    function addGalleryRole(address _address) public onlyAdminRole {
        require(
            !hasCreatorRole(_address),
            "EphimeraAccessControls: Address already has creator role and cannot have gallery role at the same time"
        );
        require(
            !hasGalleryRole(_address),
            "EphimeraAccessControls: Address already has gallery role"
        );

        _grantRole(GALLERY_ROLE, _address);
        emit NewGalleryAdded(_address);
    }

    function removeGalleryRole(address _address) public onlyAdminRole {
        require(
            hasGalleryRole(_address),
            "EphimeraAccessControls: Address must have gallery role"
        );
        _revokeRole(GALLERY_ROLE, _address);
        emit GalleryRemoved(_address);
    }

    function addCreatorRole(address _address) public onlyAdminRole {
        require(
            !hasGalleryRole(_address),
            "EphimeraAccessControls: Address already has gallery role and cannot have creator role at the same time"
        );

        require(
            !hasCreatorRole(_address),
            "EphimeraAccessControls: Address already has creator role"
        );

        _grantRole(CREATOR_ROLE, _address);
        emit NewArtistAdded(_address);
    }

    function removeCreatorRole(address _address) public onlyAdminRole {
        require(
            hasCreatorRole(_address),
            "EphimeraAccessControls: Address must have creator role"
        );
        _revokeRole(CREATOR_ROLE, _address);
        emit ArtistRemoved(_address);
    }

    /* Allows the DEFAULT_ADMIN_ROLE that controls all roles to be overridden thereby creating hierarchies */
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole)
        external
        onlyAdminRole
    {
        _setRoleAdmin(_role, _adminRole);
    }

    function addArtistToGallery(address _gallery, address _artist)
        external
        onlyAdminRole
    {
        require(
            hasRole(GALLERY_ROLE, _gallery),
            "EphimeraAccessControls: Gallery address specified does not have the gallery role"
        );
        require(
            hasRole(CREATOR_ROLE, _artist),
            "EphimeraAccessControls: Artist address specified does not have the creator role"
        );
        require(
            !isArtistPartOfGallery(_gallery, _artist),
            "EphimeraAccessControls: Artist cannot be added twice to one gallery"
        );
        galleryToArtistMapping[_gallery][_artist] = true;
        artistToGalleriesMapping[_artist][_gallery] = true;

        emit ArtistAddedToGallery(_gallery, _artist, _msgSender());
    }

    function removeArtistFromGallery(address _gallery, address _artist)
        external
        onlyAdminRole
    {
        require(
            isArtistPartOfGallery(_gallery, _artist),
            "EphimeraAccessControls: Artist is not part of the gallery"
        );
        galleryToArtistMapping[_gallery][_artist] = false;
        artistToGalleriesMapping[_artist][_gallery] = false;

        emit ArtistRemovedFromGallery(_gallery, _artist, _msgSender());
    }
}

// File: contracts/EphimeraToken.sol

pragma solidity 0.6.12;







/**
 * @title Ephimera Token contract (ephimera.com)
 * @author Ephimera 
 * @dev Ephimera's ERC-721 contract
 */
contract EphimeraToken is IERC721Token, ERC165, Context {
    using SafeMath for uint256;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // Function selector for ERC721Receiver.onERC721Received 0x150b7a02
    bytes4 constant internal ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @dev the first token ID is 1
    uint256 public tokenPointer; 

    // Token name
    string public name = "Ephimera";

    // Token symbol
    string public symbol = "EPH";

    uint256 public totalSupply;

    // Mapping of tokenId => owner
    mapping(uint256 => address) internal owners;

    // Mapping of tokenId => approved address
    mapping(uint256 => address) internal approvals;

    // Mapping of owner => number of tokens owned
    mapping(address => uint256) internal balances;

    // Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;

    mapping(uint256 => uint256) public tokenTransferCount;

    EphimeraAccessControls public accessControls;

    constructor (EphimeraAccessControls _accessControls) public {
        accessControls = _accessControls;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == ERC721_RECEIVED);
        }
    }

    /// @notice sets URI of token metadata (e.g. IPFS hash of a token)
    /// @dev links an NFT to metadata URI
    /// @param _tokenId the identifier for an NFT 
    /// @param _uri data that the NFT is representing
    function setTokenURI(uint256 _tokenId, string calldata _uri) external {
        require(owners[_tokenId] != address(0), "EphimeraToken.setTokenURI: token does not exist.");
        require(accessControls.hasAdminRole(_msgSender()), "EphimeraToken.setTokenURI: caller is not a admin.");
        tokenURIs[_tokenId] = _uri;
    }

    /// @notice creates a new Ephimera art piece
    /// @dev mints a new NFT
    /// @param _to the address that the NFT is going to be issued to
    /// @param _uri data that the NFT is representing
    /// @return return an NFT id
    function mint(
        address _to,
        string calldata _uri
    ) external returns (uint256) {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(accessControls.hasContractWhitelistRole(_msgSender()), "EphimeraToken.mint: caller is not whitelisted.");

        tokenPointer = tokenPointer.add(1);
        uint256 tokenId = tokenPointer;

        // Mint
        owners[tokenId] = _to;
        balances[_to] = balances[_to].add(1);

        // MetaData
        tokenURIs[tokenId] = _uri;
        totalSupply = totalSupply.add(1);

        tokenTransferCount[tokenId] = 1;

        // Single Transfer event for a single token
        emit Transfer(address(0), _to, tokenId);

        return tokenId;
    }

    /// @notice gets the data URI of a token
    /// @dev queries an NFT's URI
    /// @param _tokenId the identifier for an NFT
    /// @return return an NFT's tokenURI 
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURIs[_tokenId];
    }

    /// @notice checks if an art exists
    /// @dev checks if an NFT exists
    /// @param _tokenId the identifier for an NFT 
    /// @return returns true if an NFT exists, else returns false
    function exists(uint256 _tokenId) external view returns (bool) {
        return owners[_tokenId] != address(0);
    }

    /// @notice allows owner and only owner of an art piece to delete it. 
    ///     This token will be gone forever; USE WITH CARE
    /// @dev owner can burn an NFT
    /// @param _tokenId the identifier for an NFT 
    function burn(uint256 _tokenId) external {
        require(_msgSender() == ownerOf(_tokenId), 
            "EphimeraToken.burn: Caller must be owner."
        );
        _burn(_tokenId);
    }

    function _burn(uint256 _tokenId)
    internal
    {
        address owner = owners[_tokenId];
        require(
            owner != address(0),
            "ERC721_ZERO_OWNER_ADDRESS"
        );

        owners[_tokenId] = address(0);
        balances[owner] = balances[owner].sub(1);
        totalSupply = totalSupply.sub(1);

        // clear metadata
        if (bytes(tokenURIs[_tokenId]).length != 0) {
            delete tokenURIs[_tokenId];
        }

        emit Transfer(
            owner,
            address(0),
            _tokenId
        );
    }

    /// @notice transfers the ownership of an NFT from one address to another address
    /// @dev wrapper function for the safeTransferFrom function below setting data to "".
    /// @param _from the current owner of the NFT
    /// @param _to the new owner
    /// @param _tokenId the identifier for the NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice transfers the ownership of an NFT from one address to another address
    /// @dev throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from the current owner of the NFT
    /// @param _to the new owner
    /// @param _tokenId the identifier for the NFT to transfer
    /// @param _data additional data with no specified format; sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
    override
    public
    {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @notice change or reaffirm the approved address for an NFT
    /// @dev the zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved the new approved NFT controller
    /// @param _tokenId the identifier of the NFT to approve
    function approve(address _approved, uint256 _tokenId)
    override
    external
    {
        address owner = ownerOf(_tokenId);
        require(_approved != owner, "ERC721: approval to current owner");
        
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        approvals[_tokenId] = _approved;
        emit Approval(
            owner,
            _approved,
            _tokenId
        );
    }

    /// @notice enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    /// @dev emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator address to add to the set of authorized operators
    /// @param _approved true if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved)
    override
    external
    {
        require(_operator != _msgSender(), "ERC721: approve to caller");

        operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(
            _msgSender(),
            _operator,
            _approved
        );
    }

    /// @notice count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner an address to query
    /// @return the number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner)
    override
    external
    view
    returns (uint256)
    {
        require(
            _owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return balances[_owner];
    }

    /// @notice transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from the current owner of the NFT
    /// @param _to the new owner
    /// @param _tokenId the identifier of the NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    override
    public
    {
        require(
            _to != address(0),
            "ERC721_ZERO_TO_ADDRESS"
        );

        address owner = ownerOf(_tokenId);
        require(
            _from == owner,
            "ERC721_OWNER_MISMATCH"
        );

        address spender = _msgSender();
        address approvedAddress = getApproved(_tokenId);
        require(
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            approvedAddress == spender,
            "ERC721_INVALID_SPENDER"
        );

        if (approvedAddress != address(0)) {
            approvals[_tokenId] = address(0);
        }

        owners[_tokenId] = _to;
        balances[_from] = balances[_from].sub(1);
        balances[_to] = balances[_to].add(1);

        tokenTransferCount[_tokenId] = tokenTransferCount[_tokenId].add(1);

        emit Transfer(
            _from,
            _to,
            _tokenId
        );
    }

    /// @notice find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @param _tokenId the identifier for an NFT
    /// @return the address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
    override
    public
    view
    returns (address)
    {
        address owner = owners[_tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /// @notice get the approved address for a single NFT
    /// @dev throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId the NFT to find the approved address for
    /// @return the approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
    override
    public
    view
    returns (address)
    {
        require(owners[_tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return approvals[_tokenId];
    }

    /// @notice query if an address is an authorized operator for another address
    /// @param _owner the address that owns the NFTs
    /// @param _operator the address that acts on behalf of the owner
    /// @return true if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
    override
    public
    view
    returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }
}