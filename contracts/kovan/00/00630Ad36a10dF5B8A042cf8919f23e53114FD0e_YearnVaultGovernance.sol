// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IProtocolGovernance.sol";
import "./interfaces/IVaultGovernance.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @notice Internal contract for managing different params.
/// @dev The contract should be overriden by the concrete VaultGovernance,
/// define different params structs and use abi.decode / abi.encode to serialize
/// to bytes in this contract. It also should emit events on params change.
abstract contract VaultGovernance is IVaultGovernance {
    InternalParams internal _internalParams;
    InternalParams private _stagedInternalParams;
    uint256 internal _internalParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedStrategyParams;
    mapping(uint256 => bytes) internal _stagedDelayedStrategyParams;
    mapping(uint256 => uint256) internal _delayedStrategyParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedProtocolPerVaultParams;
    mapping(uint256 => bytes) internal _stagedDelayedProtocolPerVaultParams;
    mapping(uint256 => uint256) internal _delayedProtocolPerVaultParamsTimestamp;

    bytes internal _delayedProtocolParams;
    bytes internal _stagedDelayedProtocolParams;
    uint256 internal _delayedProtocolParamsTimestamp;

    mapping(uint256 => bytes) internal _strategyParams;
    bytes internal _protocolParams;

    IVaultFactory public factory;
    bool public initialized;

    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    constructor(InternalParams memory internalParams_) {
        _internalParams = internalParams_;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @inheritdoc IVaultGovernance
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedStrategyParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedProtocolPerVaultParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolParamsTimestamp() external view returns (uint256) {
        return _delayedProtocolParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParamsTimestamp() external view returns (uint256) {
        return _internalParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParams() external view returns (InternalParams memory) {
        return _internalParams;
    }

    /// @inheritdoc IVaultGovernance
    function stagedInternalParams() external view returns (InternalParams memory) {
        return _stagedInternalParams;
    }

    // -------------------  PUBLIC, MUTATING  -------------------

    /// @inheritdoc IVaultGovernance
    function initialize(IVaultFactory factory_) external {
        require(!initialized, Exceptions.INITIALIZATION);
        factory = factory_;
        initialized = true;
    }

    /// @inheritdoc IVaultGovernance
    function deployVault(
        address[] memory vaultTokens,
        bytes memory options,
        address owner
    ) public virtual returns (IVault vault, uint256 nft) {
        require(initialized, Exceptions.INITIALIZATION);
        IProtocolGovernance protocolGovernance = IProtocolGovernance(_internalParams.protocolGovernance);
        require(protocolGovernance.permissionless() || protocolGovernance.isAdmin(msg.sender), Exceptions.PERMISSIONLESS_OR_ADMIN);
        vault = factory.deployVault(vaultTokens, options);
        address nftOwner = owner;
        nft = _internalParams.registry.registerVault(address(vault), nftOwner);
        vault.initialize(nft);
        emit DeployedVault(tx.origin, msg.sender, vaultTokens, options, nftOwner, address(vault), nft);
    }

    /// @inheritdoc IVaultGovernance
    function stageInternalParams(InternalParams memory newParams) external {
        _requireProtocolAdmin();
        _stagedInternalParams = newParams;
        _internalParamsTimestamp = block.timestamp + _internalParams.protocolGovernance.governanceDelay();
        emit StagedInternalParams(tx.origin, msg.sender, newParams, _internalParamsTimestamp);
    }

    /// @inheritdoc IVaultGovernance
    function commitInternalParams() external {
        _requireProtocolAdmin();
        require(_internalParamsTimestamp > 0, Exceptions.NULL);
        require(block.timestamp >= _internalParamsTimestamp, Exceptions.TIMESTAMP);
        _internalParams = _stagedInternalParams;
        delete _internalParamsTimestamp;
        emit CommitedInternalParams(tx.origin, msg.sender, _internalParams);
    }

    // -------------------  INTERNAL  -------------------

    /// @notice Set Delayed Strategy Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _stagedDelayedStrategyParams[nft] = params;
        uint256 delayFactor = _delayedStrategyParams[nft].length == 0 ? 0 : 1;
        _delayedStrategyParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Strategy Params
    function _commitDelayedStrategyParams(uint256 nft) internal {
        _requireAtLeastStrategy(nft);
        require(_delayedStrategyParamsTimestamp[nft] > 0, Exceptions.NULL);
        require(block.timestamp >= _delayedStrategyParamsTimestamp[nft], Exceptions.TIMESTAMP);
        _delayedStrategyParams[nft] = _stagedDelayedStrategyParams[nft];
        delete _stagedDelayedStrategyParams[nft];
        delete _delayedStrategyParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Per Vault Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedProtocolPerVaultParams(uint256 nft, bytes memory params) internal {
        _requireProtocolAdmin();
        _stagedDelayedProtocolPerVaultParams[nft] = params;
        uint256 delayFactor = _delayedProtocolPerVaultParams[nft].length == 0 ? 0 : 1;
        _delayedProtocolPerVaultParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Per Vault Params
    function _commitDelayedProtocolPerVaultParams(uint256 nft) internal {
        _requireProtocolAdmin();
        require(_delayedProtocolPerVaultParamsTimestamp[nft] > 0, Exceptions.NULL);
        require(block.timestamp >= _delayedProtocolPerVaultParamsTimestamp[nft], Exceptions.TIMESTAMP);
        _delayedProtocolPerVaultParams[nft] = _stagedDelayedProtocolPerVaultParams[nft];
        delete _stagedDelayedProtocolPerVaultParams[nft];
        delete _delayedProtocolPerVaultParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Params
    /// @param params New params
    function _stageDelayedProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        uint256 delayFactor = _delayedProtocolParams.length == 0 ? 0 : 1;
        _stagedDelayedProtocolParams = params;
        _delayedProtocolParamsTimestamp =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Params
    function _commitDelayedProtocolParams() internal {
        _requireProtocolAdmin();
        require(_delayedProtocolParamsTimestamp > 0, Exceptions.NULL);
        require(block.timestamp >= _delayedProtocolParamsTimestamp, Exceptions.TIMESTAMP);
        _delayedProtocolParams = _stagedDelayedProtocolParams;
        delete _stagedDelayedProtocolParams;
        delete _delayedProtocolParamsTimestamp;
    }

    /// @notice Set immediate strategy params
    /// @dev Should require nft > 0
    /// @param nft Nft of the vault
    /// @param params New params
    function _setStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _strategyParams[nft] = params;
    }

    /// @notice Set immediate protocol params
    /// @param params New params
    function _setProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        _protocolParams = params;
    }

    function _requireAtLeastStrategy(uint256 nft) internal view {
        require(
            (_internalParams.protocolGovernance.isAdmin(msg.sender) ||
                _internalParams.registry.getApproved(nft) == msg.sender ||
                (_internalParams.registry.ownerOf(nft) == msg.sender)),
            Exceptions.REQUIRE_AT_LEAST_ADMIN
        );
    }

    function _requireProtocolAdmin() internal view {
        require(_internalParams.protocolGovernance.isAdmin(msg.sender), Exceptions.ADMIN);
    }

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StagedInternalParams(address indexed origin, address indexed sender, InternalParams params, uint256 when);

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param params New params that were staged for commit
    event CommitedInternalParams(address indexed origin, address indexed sender, InternalParams params);

    /// @notice Emitted when New Vault is deployed
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param vaultTokens Vault tokens for this vault
    /// @param options Options for deploy. The details of the options structure are specified in subcontracts
    /// @param owner Owner of the VaultRegistry NFT for this vault
    /// @param vaultAddress Address of the new Vault
    /// @param vaultNft VaultRegistry NFT for the new Vault
    event DeployedVault(
        address indexed origin,
        address indexed sender,
        address[] vaultTokens,
        bytes options,
        address owner,
        address vaultAddress,
        uint256 vaultNft
    );
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IProtocolGovernance.sol";
import "./interfaces/IYearnVaultGovernance.sol";
import "./VaultGovernance.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @notice Governance that manages all Aave Vaults params and can deploy a new Aave Vault.
contract YearnVaultGovernance is IYearnVaultGovernance, VaultGovernance {
    mapping(address => address) private _yTokens;

    /// @notice Creates a new contract
    /// @param internalParams_ Initial Internal Params
    /// @param delayedProtocolParams_ Initial Protocol Params
    constructor(InternalParams memory internalParams_, DelayedProtocolParams memory delayedProtocolParams_)
        VaultGovernance(internalParams_)
    {
        _delayedProtocolParams = abi.encode(delayedProtocolParams_);
    }

    /// @inheritdoc IYearnVaultGovernance
    function yTokenForToken(address token) external view returns (address) {
        address yToken = _yTokens[token];
        if (yToken != address(0)) {
            return yToken;
        }
        IYearnVaultRegistry yearnRegistry = delayedProtocolParams().yearnVaultRegistry;
        try yearnRegistry.latestVault(token) returns (address _vault) {
            return _vault;
        } catch (bytes memory) {
            return address(0);
        }
    }

    /// @inheritdoc IYearnVaultGovernance
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory) {
        if (_stagedDelayedProtocolParams.length == 0) {
            return DelayedProtocolParams({yearnVaultRegistry: IYearnVaultRegistry(address(0))});
        }
        return abi.decode(_stagedDelayedProtocolParams, (DelayedProtocolParams));
    }

    /// @inheritdoc IYearnVaultGovernance
    function delayedProtocolParams() public view returns (DelayedProtocolParams memory) {
        return abi.decode(_delayedProtocolParams, (DelayedProtocolParams));
    }

    /// @inheritdoc IYearnVaultGovernance
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external {
        _stageDelayedProtocolParams(abi.encode(params));
        emit StageDelayedProtocolParams(tx.origin, msg.sender, params, _delayedProtocolParamsTimestamp);
    }

    /// @inheritdoc IYearnVaultGovernance
    function commitDelayedProtocolParams() external {
        _commitDelayedProtocolParams();
        emit CommitDelayedProtocolParams(
            tx.origin,
            msg.sender,
            abi.decode(_delayedProtocolParams, (DelayedProtocolParams))
        );
    }

    /// @inheritdoc IYearnVaultGovernance
    function setYTokenForToken(address token, address yToken) external {
        _requireProtocolAdmin();
        _yTokens[token] = yToken;
        emit SetYToken(tx.origin, msg.sender, token, yToken);
    }

    /// @notice Emitted when new yToken is set
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param token ERC-20 token for the yToken
    /// @param yToken yToken for ERC-20 token
    event SetYToken(address indexed origin, address indexed sender, address indexed token, address yToken);

    /// @notice Emitted when new DelayedProtocolParams are staged for commit
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StageDelayedProtocolParams(
        address indexed origin,
        address indexed sender,
        DelayedProtocolParams params,
        uint256 when
    );

    /// @notice Emitted when new DelayedProtocolParams are committed
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param params New params that are committed
    event CommitDelayedProtocolParams(address indexed origin, address indexed sender, DelayedProtocolParams params);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "./IDefaultAccessControl.sol";
import "./IVaultRegistry.sol";

interface IProtocolGovernance is IDefaultAccessControl {
    /// @notice CommonLibrary protocol params.
    /// @param permissionless If `true` anyone can spawn vaults, o/w only Protocol Governance Admin
    /// @param maxTokensPerVault Max different token addresses that could be managed by the protocol
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury Protocol treasury address for collecting management fees
    struct Params {
        bool permissionless;
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @notice Addresses allowed to claim liquidity mining rewards from.
    function claimAllowlist() external view returns (address[] memory);

    /// @notice Pending addresses to be added to claimAllowlist.
    function pendingClaimAllowlistAdd() external view returns (address[] memory);

    /// @notice Addresses of tokens allowed for vaults.
    function tokenWhitelist() external view returns (address[] memory);

    /// @notice Pending addresses to be added to tokenWhitelist.
    function pendingTokenWhitelistAdd() external view returns (address[] memory);

    /// @notice Addresses allowed to claim liquidity mining rewards from.
    function vaultGovernances() external view returns (address[] memory);

    /// @notice Pending addresses to be added to vaultGovernances.
    function pendingVaultGovernancesAdd() external view returns (address[] memory);

    /// @notice Check if address is allowed to claim.
    function isAllowedToClaim(address addr) external view returns (bool);

    /// @notice Check if address is an approved token.
    function isAllowedToken(address addr) external view returns (bool);

    /// @notice Check if address is a registered vault governance.
    function isVaultGovernance(address addr) external view returns (bool);

    /// @notice If `false` only admins can deploy new vaults, o/w anyone can deploy a new vault.
    function permissionless() external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    // -------------------  PUBLIC, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Set new pending params.
    /// @param newParams newParams to set
    function setPendingParams(Params memory newParams) external;

    /// @notice Stage addresses for claim allow list.
    /// @param addresses Addresses to add
    function setPendingClaimAllowlistAdd(address[] calldata addresses) external;

    /// @notice Stage addresses for token whitelist.
    /// @param addresses Addresses to add
    function setPendingTokenWhitelistAdd(address[] calldata addresses) external;

    /// @notice Stage addresses for vault governances.
    /// @param addresses Addresses to add
    function setPendingVaultGovernancesAdd(address[] calldata addresses) external;

    // -------------------  PUBLIC, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Commit pending params.
    function commitParams() external;

    /// @notice Commit pending ClaimAllowlistAdd params.
    function commitClaimAllowlistAdd() external;

    /// @notice Commit pending tokenWhitelistAdd params.
    function commitTokenWhitelistAdd() external;

    /// @notice Commit pending VaultGovernancesAdd params.
    function commitVaultGovernancesAdd() external;

    /// @notice Remove from claim allow list immediately.
    function removeFromClaimAllowlist(address addr) external;

    /// @notice Remove from token whitelist immediately.
    function removeFromTokenWhitelist(address addr) external;

    /// @notice Remove from vault governances immediately.
    function removeFromVaultGovernances(address addr) external;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "./IVaultGovernance.sol";

interface IVault {
    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// @return tokenAmounts Total available balances for multiple tokens (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory tokenAmounts);

    /// @notice Initialize contract with vault nft
    /// @param nft VaultRegistry NFT for this vault
    function initialize(uint256 nft) external;

    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// For example, for Yearn this operation will take yUSDC from
    /// the Yearn protocol, convert it to USDC and send to `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT. There's a subtle difference however - while vault owner
    /// can pull the tokens to any address, Strategy can only pull to other vault in the Vault System (a set of vaults united by the Gateway Vault)
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice This method is for claiming accidentally accumulated tokens on the contact's balance.
    /// @dev Can only be called by Protocol Governance.
    /// @param to Address that will receive the tokens
    /// @param tokens Tokens to claim. Each token must be other than those in vaultTokens
    function reclaimTokens(address to, address[] memory tokens) external;

    /// @notice Claim liquidity mining rewards.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param from Address of the reward pool
    /// @param data Abi encoded call to the `from` address
    function claimRewards(address from, bytes memory data) external;

    function isVaultToken(address token) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "./IVaultGovernance.sol";
import "./IVault.sol";

interface IVaultFactory {
    /// @notice Deploy a new vault.
    /// @param vaultTokens ERC20 tokens under vault management
    /// @param options Reserved additional deploy options. Should be 0x0
    function deployVault(address[] memory vaultTokens, bytes memory options) external returns (IVault vault);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";
import "./IVaultRegistry.sol";
import "./IVaultFactory.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @notice Checks if contract is initialized.
    /// @dev Uninitialized contracts cannot deploy vaults
    function initialized() external view returns (bool);

    /// @notice Vault factory for this Vault Governance.
    function factory() external view returns (IVaultFactory);

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  PUBLIC, MUTATING  -------------------

    /// @notice Instantly initialize governance with factory.
    /// @dev Can only be called by initial deployer and only once.
    /// Required to be called before any function starts working.
    /// @param factory new factory
    function initialize(IVaultFactory factory) external;

    /// @notice Deploy a new vault.
    /// @param vaultTokens ERC20 tokens under vault management
    /// @param options Reserved additional deploy options. Should be 0x0.
    /// @param owner Owner of the registry vault nft. If it is address(0) then vault will own his own nft
    /// @return vault Address of the new vault
    /// @return nft Nft of the vault in the vault registry
    function deployVault(
        address[] memory vaultTokens,
        bytes memory options,
        address owner
    ) external returns (IVault vault, uint256 nft);

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: None
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";
import "./IVaultFactory.sol";
import "./IVaultGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Approve nft to new address
    /// @dev This can be called only by the Protocol Governance. It is used to disable the strategy for a vault
    /// @param newAddress address that will be approved
    /// @param nft for re-approval
    function adminApprove(address newAddress, uint256 nft) external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "./external/yearn/IYearnVaultRegistry.sol";
import "./IVaultGovernance.sol";

interface IYearnVaultGovernance is IVaultGovernance {
    /// @notice Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param yearnVaultRegistry Reference to Yearn Vault Registry
    struct DelayedProtocolParams {
        IYearnVaultRegistry yearnVaultRegistry;
    }

    /// @notice Determines a corresponding Yearn vault for token
    /// @param token ERC-20 token for the yToken
    /// @return If there's a yToken returns its address, otherwise returns 0
    function yTokenForToken(address token) external view returns (address);

    /// @notice Delayed Protocol Params staged for commit after delay.
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function delayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Stage Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @dev Can only be called after delayedProtocolParamsTimestamp.
    /// @param params New params
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external;

    /// @notice Commit Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function commitDelayedProtocolParams() external;

    /// @notice Sets the manual override for yToken vaults map
    /// @dev Can only be called by Protocol Admin
    /// @param token ERC-20 token for yToken
    /// @param yToken for ERC-20 token
    function setYTokenForToken(address token, address yToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IYearnVaultRegistry {
    function latestVault(address vault) external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

/// @notice Exceptions stores project`s smart-contracts exceptions
library Exceptions {
    string constant GOVERNANCE_OR_DELEGATE = "GD";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant GOVERNANCE_OR_DELEGATE_ADDRESS_ZERO = "ZMG";
    string constant EMPTY_PARAMS = "P0";
    string constant ADMIN = "ADM";
    string constant ADMIN_ADDRESS_ZERO = "ZADM";
    string constant VAULT_FACTORY_ADDRESS_ZERO = "ZVF";
    string constant APPROVED_OR_OWNER = "IO";
    string constant INCONSISTENT_LENGTH = "L";
    string constant LIMIT_OVERFLOW = "LIM";
    string constant SORTED_AND_UNIQUE = "SAU";
    string constant ERC20_INSUFFICIENT_BALANCE = "ERC20: transfer amount exceeds balance";
    string constant VALID_PULL_DESTINATION = "INTRA";
    string constant CONTRACT_REQUIRED = "C";
    string constant SHOULD_BE_CALLED_BY_VAULT_GOVERNANCE = "VG";
    string constant REQUIRE_AT_LEAST_ADMIN = "RST";
    string constant NULL_OR_NOT_INITIALIZED = "NA";
    string constant REDIRECTS_AND_VAULT_TOKENS_LENGTH = "RL";
    string constant INITIALIZATION = "INIT";
    string constant PERMISSIONLESS_OR_ADMIN = "POA";
    string constant TOKEN_NOT_IN_PROJECT = "TPS";
    string constant WEIGHTS_LENGTH_IS_ZERO = "KGT0";
    string constant AMOUNTS_LENGTH_IS_ZERO = "NGT0";
    string constant MATRIX_NOT_RECTANGULAR = "NV";
    string constant TOTAL_SUPPLY_IS_ZERO = "TS0";
    string constant ALLOWED_TO_CLAIM = "AC";
    string constant OTHER_VAULT_TOKENS = "OWT";
    string constant SUB_VAULT_INITIALIZED = "SBIN";
    string constant SUB_VAULT_LENGTH = "SBL";
    string constant NFT_ZERO = "NFT0";
    string constant YEARN_VAULTS = "YV";
    string constant LOCKED_NFT = "LCKD";
    string constant TOKEN_OWNER = "TO";
    string constant NOT_VAULT_TOKEN = "VT";
    string constant NOT_STRATEGY_TREASURY = "ST";
    string constant ZERO_STRATEGY_ADDRESS = "ZS";
    string constant NFT_VAULT_REGISTRY = "NFTVR";
    string constant ZERO_TOKEN = "ZT";
    string constant INITIALIZE_SUB_VAULT = "INITSV";
    string constant INITIALIZE_OWNER = "INITOWN";
    string constant LIMIT_PER_ADDRESS = "LPA";
    string constant MAX_MANAGEMENT_FEE = "MMF";
    string constant MAX_PERFORMANCE_FEE = "MPFF";
    string constant MAX_PROTOCOL_FEE = "MPF";
    string constant TOKEN_LENGTH = "TL";
    string constant IO_LENGTH = "IOL";
    string constant YEARN_VAULT = "YV";
    string constant MAX_GOVERNANCE_DELAY = "MD";
    string constant OWNER_VAULT_NFT = "OWV";
}