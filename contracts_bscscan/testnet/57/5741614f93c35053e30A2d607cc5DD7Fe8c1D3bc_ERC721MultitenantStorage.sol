// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../Roles.sol";
import "./IERC721MultitenantStorage.sol";
import "../Mintable.sol";

contract ERC721MultitenantStorage is
    IERC721MultitenantStorage,
    OwnableUpgradeable, AccessControlEnumerableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using Counters for Counters.Counter;
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(
        string => mapping(bytes32 => EnumerableSetUpgradeable.AddressSet)
    ) private _roleMembersByApp;

    // Mapping owner address to token count
    mapping(
        string => mapping(address => EnumerableSetUpgradeable.UintSet)
    ) private _tokensByOwner;

    // Mapping from token ID to owner address
    mapping(
        string => mapping(uint256 => address)
    ) private _owners;

    mapping(
        string => mapping(uint256 => string)
    ) private _tokenURI;

    mapping(
        string => Counters.Counter
    ) private _tokenIdTracker;

    // Mapping from token ID to approved address
    mapping(
        string => mapping(uint256 => address)
    ) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(
        string => mapping(address => mapping(address => bool))
    ) private _operatorApprovals;

    mapping(
        string => bool
    ) private _paused;

    mapping(
        string => EnumerableSetUpgradeable.UintSet
    ) private _appTokens;

    mapping(
        string => mapping(uint256 => EnumerableSetUpgradeable.UintSet)
    ) private _tokenEditions;
    mapping(
        string => mapping(uint256 => uint256)
    ) private _maxTokenSupply;
    mapping(
        string => mapping(uint256 => uint256)
    ) private _parentToken;

    mapping(
        string => mapping(uint256 => string)
    ) private _tokenCertificate;

    function _normaliseRole(
        string memory role
    ) internal pure returns (bytes32) {
        return keccak256(bytes(role));
    }
    function grantRole(
        string memory role,
        address account
    ) external override onlyOwner {
        super.grantRole(
            _normaliseRole(role),
            account
        );
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function annulRole(
        string memory role,
        address account
    ) external override onlyOwner {
        super.revokeRole(
            _normaliseRole(role),
            account
        );
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function possessRole(
        string memory role,
        address account
    ) external view override onlyRole(Roles.ROLE_ADMIN) returns (bool) {
        return super.hasRole(
            _normaliseRole(role),
            account
        );
    }

    function initialize() external initializer {
        __Ownable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, owner());
        _setupRole(Roles.ROLE_ADMIN, owner());
    }

    function registerApp(
        string calldata app,
        address[] memory minters,
        address[] memory pausers,
        address admin
    ) external override onlyRole(Roles.ROLE_ADMIN) {
        _grantRoleForApp(
            app,
            Roles.ROLE_ADMIN,
            admin
        );
        for (uint32 i = 0; i < minters.length; i++) {
            _grantRoleForApp(
                app,
                Roles.ROLE_MINTER,
                minters[i]
            );
        }
        for (uint32 i = 0; i < pausers.length; i++) {
            _grantRoleForApp(
                app,
                Roles.ROLE_PAUSER,
                pausers[i]
            );
        }
    }

    function grantRoleForApp(
        string memory app,
        bytes32 role,
        address account
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) {
        _grantRoleForApp(
            app,
            role,
            account
        );
    }

    function _grantRoleForApp(
        string memory app,
        bytes32 role,
        address account
    ) internal {
        _roleMembersByApp[app][role].add(account);
    }

    function hasAppRole(
        string memory app,
        bytes32 role,
        address account
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (bool) {
        return _roleMembersByApp[app][
            role
        ].contains(account);
    }

    function revokeRoleFromApp(
        string memory app,
        bytes32 role,
        address account
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) {
        _roleMembersByApp[app][role].remove(account);
    }

    function getAppRoleMemberCount(
        string memory app,
        bytes32 role
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        return _roleMembersByApp[app][role].length();
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
    function getAppRoleMember(
        string memory app,
        bytes32 role,
        uint256 index
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (address) {
        return _roleMembersByApp[app][role].at(index);
    }

    /**
     * @dev See { IERC721-balanceOf }.
     */
    function balanceOf(
        string calldata app,
        address owner
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        return _tokensByOwner[app][owner].length();
    }

    /**
     * @dev See { IERC721-ownerOf }.
     */
    function ownerOf(
        string calldata app,
        uint256 tokenId
    ) public view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (address) {
        return _ownerOf(app, tokenId);
    }

    function _ownerOf(
        string calldata app,
        uint256 tokenId
    ) internal view returns (address) {
        return _owners[app][tokenId];
    }

    /**
     * @dev See { IERC721Metadata-tokenURI }.
     */
    function tokenURI(
        string calldata app,
        uint256 tokenId
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (string memory) {
        return _tokenURI[app][tokenId];
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(
        string calldata app
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (bool) {
        return _paused[app];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
        string calldata app,
        address to,
        uint256 tokenId
    ) external onlyRole(
        Roles.ROLE_ADMIN
    ) override {
        _approve(
            app,
            to,
            tokenId
        );
    }

    function _approve(
        string calldata app,
        address to,
        uint256 tokenId
    ) internal {
        _tokenApprovals[app][tokenId] = to;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        string calldata app,
        uint256 tokenId
    ) external view onlyRole(
        Roles.ROLE_ADMIN
    ) override returns (address) {
        return _tokenApprovals[app][tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        string calldata app,
        address owner,
        address operator
    ) external view onlyRole(
        Roles.ROLE_ADMIN
    ) override returns (bool) {
        return _operatorApprovals[app][owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        string calldata app,
        address owner,
        address operator,
        bool approved
    ) external onlyRole(
        Roles.ROLE_ADMIN
    ) override {
        _operatorApprovals[app][owner][operator] = approved;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        string calldata app,
        address from,
        address to,
        uint256 tokenId
    ) external onlyRole(
        Roles.ROLE_ADMIN
    ) override {
        // Clear approvals from the previous owner
        _approve(app, address(0), tokenId);

        _tokensByOwner[app][from].remove(tokenId);
        _tokensByOwner[app][to].add(tokenId);
        _owners[app][tokenId] = to;
    }

    function mint(
        string calldata app,
        Mintable.TokenData memory tokenData
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        if (_tokenIdTracker[app].current() == 0) {
            _tokenIdTracker[app].increment();
        }
        uint256 tokenId = _tokenIdTracker[app].current();

        if (tokenData.editionOf > 0) {
            _tokenEditions[app][tokenData.editionOf].add(tokenId);
            _parentToken[app][tokenId] = tokenData.editionOf;
        } else {
            _maxTokenSupply[app][tokenId] = tokenData.maxTokenSupply;
            _tokenEditions[app][tokenId].add(tokenId);
            _parentToken[app][tokenId] = 0;
        }

        _tokensByOwner[app][tokenData.to].add(tokenId);
        _owners[app][tokenId] = tokenData.to;
        _tokenURI[app][tokenId] = tokenData.tokenMetadataURI;

        _tokenIdTracker[app].increment();

        _appTokens[app].add(tokenId);

        return tokenId;
    }

    function nextTokenId(
        string calldata app
    ) external override view onlyRole(
        Roles.ROLE_ADMIN
    ) returns(uint256) {
        uint256 tokenId = _tokenIdTracker[app].current();

        if (tokenId == 0) {
            return 1;
        }

        return tokenId;
    }

    function burn(
        string calldata app,
        uint256 tokenId
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) {
        uint256 parentToken = _parentToken[app][tokenId];

        // burn all token editions
        if (parentToken == 0) {
            for (uint256 i = 0; i < _tokenEditions[app][tokenId].length(); i++) {
                uint256 edition = _tokenEditions[app][tokenId].at(i);
                address owner = ownerOf(app, edition);
                _approve(app, address(0), edition);
                _tokensByOwner[app][owner].remove(edition);
                delete _owners[app][edition];
                delete _tokenURI[app][edition];
                _appTokens[app].remove(edition);
            }
            delete _tokenEditions[app][tokenId];
        } else {
            // burn edition
            address owner = ownerOf(app, tokenId);
            _approve(app, address(0), tokenId);
            _tokensByOwner[app][owner].remove(tokenId);
            delete _owners[app][tokenId];
            delete _tokenURI[app][tokenId];
            _appTokens[app].remove(tokenId);
            _tokenEditions[app][parentToken].remove(tokenId);
        }
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause(
        string calldata app
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) {
        _paused[app] = true;
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause(
        string calldata app
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) {
        _paused[app] = false;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply(
        string calldata app
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        return _appTokens[app].length();
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(
        string calldata app,
        address owner,
        uint256 index
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256 tokenId) {
        return _tokensByOwner[app][owner].at(index);
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(
        string calldata app,
        uint256 index
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        return _appTokens[app].at(index);
    }

    /**
    * @dev Returns the total amount of token editions including parent token
    */
    function tokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        uint256 _tokenSupply = _tokenEditions[app][tokenId].length();
        if (_tokenSupply == 0) {
            return 1;
        }

        return _tokenSupply;
    }

    function maxTokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view override onlyRole(
        Roles.ROLE_ADMIN
    ) returns (uint256) {
        return _maxTokenSupply[app][tokenId];
    }

    function setTokenCertificate(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI
    ) external override onlyRole(
        Roles.ROLE_ADMIN
    ) {
        _tokenCertificate[app][tokenId] = certificateURI;
    }

    function getTokenCertificate(
        string calldata app,
        uint256 tokenId
    ) external override view onlyRole(
        Roles.ROLE_ADMIN
    ) returns (string memory) {
        return _tokenCertificate[app][tokenId];
    }
}

// SPDX-License-Identifier: MIT

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
library EnumerableSetUpgradeable {
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

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Royalties {
    struct RoyaltyReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
        uint256 resalePercentage;
        uint256 CAPPS;
        uint256 fixedCut;
    }

    struct BuyOutReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Roles {
    bytes32 constant ROLE_OWNER = keccak256(bytes("ROLE_OWNER"));
    bytes32 constant ROLE_CREATOR = keccak256(bytes("ROLE_CREATOR"));

    bytes32 constant ROLE_MINTER = keccak256(bytes("ROLE_MINTER"));
    bytes32 constant ROLE_PAUSER = keccak256(bytes("ROLE_PAUSER"));
    bytes32 constant ROLE_ADMIN = keccak256(bytes(ROLE_ADMIN_STR));

    bytes32 constant ROLE_CASH_TRANSFERER = keccak256(bytes(ROLE_CASH_TRANSFERER_STR));

    string constant ROLE_ADMIN_STR = "ROLE_ADMIN";
    string constant ROLE_CASH_TRANSFERER_STR = "ROLE_CASH_TRANSFERER";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ODRL {
    struct Party {
        string role;
        address wallet;
    }
    struct Policy {
        string action;
        uint256 target;
        Party permission;
    }

    string constant ACTION_BUY_OUT = "Buy out the NFT";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Royalties.sol";
import "./ODRL.sol";

library Mintable {
    struct TokenData {
        string tokenMetadataURI;
        uint256 editionOf;
        uint256 maxTokenSupply;
        address to;
    }
    struct TokenDataWithRoyalties {
        string tokenMetadataURI;
        uint256 editionOf;
        uint256 maxTokenSupply;
        address to;
        Royalties.RoyaltyReceiver[] royaltyReceivers;
        ODRL.Policy[] sellableRights;
        ODRL.Policy[] otherRights;
    }
    struct TokenDataWithBuyOut {
        string tokenMetadataURI;
        uint256 editionOf;
        uint256 maxTokenSupply;
        address to;
        Royalties.RoyaltyReceiver[] royaltyReceivers;
        ODRL.Policy[] sellableRights;
        ODRL.Policy[] otherRights;
        uint256 buyOutPrice;
        Royalties.BuyOutReceiver[] buyOutReceivers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Mintable.sol";

interface IERC721MultitenantStorage {
    function registerApp(
        string calldata app,
        address[] memory minters,
        address[] memory pausers,
        address admin
    ) external;

    function balanceOf(
        string calldata app,
        address owner
    ) external view returns (uint256);

    function ownerOf(
        string calldata app,
        uint256 tokenId
    ) external view returns (address);

    function tokenURI(
        string calldata app,
        uint256 tokenId
    ) external view returns (string memory);

    function paused(
        string calldata app
    ) external view returns (bool);

    function approve(
        string calldata app,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(
        string calldata app,
        uint256 tokenId
    ) external view returns (address);

    function isApprovedForAll(
        string calldata app,
        address owner,
        address operator
    ) external view  returns (bool);

    function setApprovalForAll(
        string calldata app,
        address owner,
        address operator,
        bool approved
    ) external;

    function transferFrom(
        string calldata app,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        string calldata app,
        Mintable.TokenData memory tokenData
    ) external returns (uint256);

    function nextTokenId(
        string calldata app
    ) external view returns(uint256);

    function burn(
        string calldata app,
        uint256 tokenId
    ) external;

    function pause(
        string calldata app
    ) external;

    function unpause(
        string calldata app
    ) external;

    function totalSupply(
        string calldata app
    ) external view returns (uint256);

    function tokenOfOwnerByIndex(
        string calldata app,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    function tokenByIndex(
        string calldata app,
        uint256 index
    ) external view returns (uint256);

    function tokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);

    function maxTokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);

    function grantRoleForApp(
        string memory app,
        bytes32 role,
        address account
    ) external;

    function hasAppRole(
        string memory app,
        bytes32 role,
        address account
    ) external view returns (bool);

    function revokeRoleFromApp(
        string memory app,
        bytes32 role,
        address account
    ) external;

    function getAppRoleMemberCount(
        string memory app,
        bytes32 role
    ) external view  returns (uint256);

    function getAppRoleMember(
        string memory app,
        bytes32 role,
        uint256 index
    ) external view  returns (address);

    function grantRole(
        string memory role,
        address account
    ) external;

    function annulRole(
        string memory role,
        address account
    ) external;

    function possessRole(
        string memory role,
        address account
    ) external view returns (bool);

    function setTokenCertificate(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI
    ) external;

    function getTokenCertificate(
        string calldata app,
        uint256 tokenId
    ) external view returns (string memory);
}