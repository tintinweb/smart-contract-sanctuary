// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract AccessControl is Ownable, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;
    mapping(bytes32 => mapping(address => bool)) private _roles;
    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roleMembers[role].length();
    }

    function grantRole(bytes32 role, address account) public onlyOwner {
        _grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function revokeRole(bytes32 role, address account) public onlyOwner {
        _revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    function renounceRole(bytes32 role, address account) public {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../common/AccessControl.sol";

contract SharkGenes is AccessControl {
    uint8 GENES_VERSION = 1;

    // types
    uint8 public constant TYPE_SHARK = 0;
    uint8 public constant TYPE_SKIN = 1;

    // numerators
    uint256 hundredNumerator = 100;

    // probabilities
    uint8 public constant VARIATION_RATE = 5;
    uint8 public constant ETHNIC_RATE = 50;
    uint32[] public PART_GENETIC_RATE = [37500, 9375, 3125, 37500, 9375, 3125];
    uint32 public constant PART_GENETIC_RATE_TOTAL = 100000;

    // positions
    uint8 public constant POS_VERSION = 0;
    uint8 public constant POS_ETHNIC = 1;
    uint8 public constant POS_STAR = 2;
    uint8 public constant POS_BODY = 3;

    // limit
    uint8 public MAX_STAR = 6;

    // ranges
    uint8 public constant RANGE_ETHNIC = 6;
    uint8 public constant RANGE_BODY = 4;
    uint8[] public RANGE_HEAD = [6, 6, 6, 6, 6, 6];
    uint8[] public RANGE_MOUTH = [4, 4, 4, 4, 4, 4];
    uint8[] public RANGE_GORSAL = [6, 6, 6, 6, 6, 6];
    uint8[] public RANGE_TAIL = [6, 6, 6, 6, 6, 6];
    uint8[] public RANGE_VENTRAL = [4, 4, 4, 4, 4, 4];
    uint8[] public RANGE_NECK = [4, 4, 4, 4, 4, 4];

    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    event SetMaxStar(uint8 indexed starLimit);

    constructor() {
    }

    function setMaxStar(uint8 starLimit) external onlyOwner {
        require(starLimit != MAX_STAR);
        MAX_STAR = starLimit;

        emit SetMaxStar(starLimit);
    }

    function born(uint8 star) external view onlyRole(WHITELIST_ROLE) returns (uint256) {
        require (star >= 1 && star <= MAX_STAR, "Born: star error");

        uint256 seed;

        uint8[32] memory _genes;
        // version
        _genes[POS_VERSION] = _formatVersion(GENES_VERSION, TYPE_SHARK);
        // ethnic
        _genes[POS_ETHNIC] = uint8(_rand(RANGE_ETHNIC, seed++));
        // star
        _genes[POS_STAR] = star;
        // body
        _genes[POS_BODY] = uint8(_rand(RANGE_BODY, seed++));
        // head
        (_genes[4], _genes[5],_genes[6]) = _genParts(RANGE_HEAD, new uint8[](0), seed++);
        // mouth
        (_genes[7], _genes[8],_genes[9]) = _genParts(RANGE_MOUTH, new uint8[](0), seed++);
        // gorsal
        (_genes[10], _genes[11],_genes[12]) = _genParts(RANGE_GORSAL, new uint8[](0), seed++);
        // tail
        (_genes[13], _genes[14],_genes[15]) = _genParts(RANGE_TAIL, new uint8[](0), seed++);
        // ventral
        (_genes[16], _genes[17],_genes[18]) = _genParts(RANGE_VENTRAL, new uint8[](0), seed++);
        // neck
        (_genes[19], _genes[20],_genes[21]) = _genParts(RANGE_NECK, new uint8[](0), seed++);

        return _format(_genes);
    }

    function breeding(
        uint256 sireGenes,
        uint256 matronGenes
    )
        external
        view
        onlyRole(WHITELIST_ROLE)
        returns (uint256)
    {
        uint256 seed;
        
        uint8[32] memory sire = _parse(sireGenes);
        uint8[32] memory matron = _parse(matronGenes);
        _checkBreedingCondition(sire, matron);

        uint8[32] memory _genes;
        // version
        _genes[POS_VERSION] = _formatVersion(GENES_VERSION, TYPE_SHARK);
        //star
        _genes[POS_STAR] = sire[POS_STAR] + 1;
        // ethnic & body
        if (uint8(_rand(hundredNumerator, seed++)) < ETHNIC_RATE) {
            _genes[POS_ETHNIC] = sire[POS_ETHNIC];
            _genes[POS_BODY] = sire[POS_BODY];
        } else {
            _genes[POS_ETHNIC] = matron[POS_ETHNIC];
            _genes[POS_BODY] = matron[POS_BODY];
        }
        // head
        uint8[] memory parentParts = new uint8[](6);
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[4],sire[5],sire[6],matron[4],matron[5],matron[6]);
        (_genes[4], _genes[5],_genes[6]) = _genParts(RANGE_HEAD, parentParts, seed++);
        // mouth
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[7],sire[8],sire[9],matron[7],matron[8],matron[9]);
        (_genes[7], _genes[8],_genes[9]) = _genParts(RANGE_MOUTH, parentParts, seed++);
        // gorsal
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[10],sire[11],sire[12],matron[10],matron[11],matron[12]);
        (_genes[10], _genes[11],_genes[12]) = _genParts(RANGE_GORSAL, parentParts, seed++);
        // tail
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[13],sire[14],sire[15],matron[13],matron[14],matron[15]);
        (_genes[13], _genes[14],_genes[15]) = _genParts(RANGE_TAIL, parentParts, seed++);
        // ventral
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[16],sire[17],sire[18],matron[16],matron[17],matron[18]);
        (_genes[16], _genes[17],_genes[18]) = _genParts(RANGE_VENTRAL, parentParts, seed++);
        // neck
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[19],sire[20],sire[21],matron[19],matron[20],matron[21]);
        (_genes[19], _genes[20],_genes[21]) = _genParts(RANGE_NECK, parentParts, seed++);

        return _format(_genes);
    }

    function _genParts(
        uint8[] memory range,
        uint8[] memory parentParts,
        uint256 seed
    )
        internal
        view
        returns (uint8 D, uint8 R1, uint8 R2)
    {
        seed *= 10;
        if (parentParts.length == 0) {
            return _genNewParts(range, seed);
        }
        return _genGeneticsParts(range, parentParts, seed);
    }

    function _genGeneticsParts(
        uint8[] memory range,
        uint8[] memory parentParts,
        uint256 seed
    )
        internal
        view
        returns (uint8 D, uint8 R1, uint8 R2)
    {
        seed *= 10;

        uint8[] memory parts = _drawParts(parentParts, 3, seed++);
        for (uint8 i = 0; i < 3; i++) {
            if (_checkVariation(seed++)) {
                parts[i] = _genNewPart(range, seed++);
            }
        }
        return (parts[0], parts[1], parts[2]);
    }

    function _genNewParts(
        uint8[] memory range,
        uint256 seed
    )
        internal
        view 
        returns (uint8 D, uint8 R1, uint8 R2)
    {
        seed *= 10;
        return (
            _genNewPart(range, seed++),
            _genNewPart(range, seed++),
            _genNewPart(range, seed++)
        );
    }

    function _genNewPart(uint8[] memory range,  uint256 seed) internal view returns (uint8 part) {
        seed *= 10;
        uint8 part1 = uint8(_rand(range.length, seed++));
        uint8 part2 = uint8(_rand(range[part1], seed++));
        return part1 << 5 | part2;
    }

    function _drawParts(uint8[] memory parentParts, uint8 n, uint256 seed)
        internal
        view 
        returns(uint8[] memory)
    {
        assert(parentParts.length >= n);
        assert(parentParts.length == PART_GENETIC_RATE.length);

        uint8[] memory result = new uint8[](n);

        seed *= 10;

        uint32[6] memory rates = [
            PART_GENETIC_RATE[0],
            PART_GENETIC_RATE[1],
            PART_GENETIC_RATE[2],
            PART_GENETIC_RATE[3],
            PART_GENETIC_RATE[4],
            PART_GENETIC_RATE[5]
        ];
        uint256 total = PART_GENETIC_RATE_TOTAL;
        uint256 sum;

        for (uint i = 0; i < n; i++) {
            uint256 randVal = _rand(total, seed++); // 2000

            sum = 0;
            for (uint8 j = 0; j < parentParts.length; j++) {
                sum += rates[j];
                if (randVal < sum) {
                    result[i] = parentParts[j];

                    total -= rates[j];
                    rates[j] = 0;

                    break;
                }
            }
        }
        return result;
    }

    function _checkVariation(uint256 seed) internal view returns(bool) {
        return _rand(hundredNumerator, seed) < VARIATION_RATE;
    }

    function _checkBreedingCondition(uint8[32] memory sire, uint8[32] memory matron) internal view {
        require(sire[POS_STAR] == matron[POS_STAR], "Breeding: star not matched");
        require(sire[POS_STAR] < MAX_STAR, "Breeding: star limit");
        // only shark can be breed
        (,uint8 sireType) = _parseVersion(sire[POS_VERSION]);
        (,uint8 matronType) = _parseVersion(sire[POS_VERSION]);
        require(sireType == TYPE_SHARK && matronType == TYPE_SHARK, "Breeding: only shark");
    }

    function _parse(uint256 genes) internal pure returns(uint8[32] memory) {
        uint8[32] memory parts;
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = uint8(genes >> ((parts.length - i - 1) * 8));
        }
        return parts;
    }

    function _parsePart(uint256 genes, uint8 index) internal pure returns (uint8) {
        return uint8((genes << index * 8) >> 248);
    }

    function _parseVersion(
        uint8 version
    )
        internal 
        pure 
        returns(uint8, uint8)
    {
        uint8 _version = version >> 4;
        uint8 _type = version & 15;

        return (_version, _type);
    }

    function _format(uint8[32] memory parts) internal pure returns(uint256) {
        uint256 genes;
        for (uint i = 0; i < parts.length; i++) {
            genes |= (uint256(parts[i]) << 256 - (i + 1) * 8);
        }
        return genes;
    }

    function _formatVersion(
        uint8 _version,
        uint8 _type
    )
        internal 
        pure 
        returns(uint8)
    {
        return _version << 4 | _type;
    }

    function _rand(uint256 length, uint256 seed) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp +
            block.difficulty +
            uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp +
            block.gaslimit +
            uint256(keccak256(abi.encodePacked(msg.sender))) / block.timestamp +
            seed
        ))) % length;
    }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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