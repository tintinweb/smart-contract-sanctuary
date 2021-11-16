/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

interface IItemFactory {
    function rarityDecimal() external view returns (uint256);

    function totalSupply(uint256 boxType) external view returns (uint256);

    function addItem(
        uint256 boxType,
        uint256 itemType,
        uint256 itemId,
        uint256 rarity
    ) external;

    function artifactsLength(uint256 itemType_)
        external
        view
        returns (uint256);

    function artifactIdAt(uint256 itemType_, uint256 index_)
        external
        view
        returns (uint256);

    function getRandomArtifactValue(uint256 randomness_, uint256 artifactId_)
        external
        view
        returns (uint256);

    function getRandomItem(uint256 randomness, uint256 boxType)
        external
        view
        returns (uint256 itemId, uint256 itemType);

    event ItemAdded(
        uint256 indexed boxType,
        uint256 indexed itemType,
        uint256 indexed itemId,
        uint256 rarity
    );
}

contract ItemFactory is Ownable, IItemFactory {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet private _supportedBoxTypes;
    EnumerableSet.UintSet private _supportedItemTypes;
    EnumerableSet.UintSet private _supportedArtifactIds;

    uint256 private immutable _rarityDecimal;
    mapping(uint256 => Items) private _items;
    mapping(uint256 => EnumerableSet.UintSet) private _artifactIds;
    mapping(uint256 => uint256) private _artifactRanges;
    mapping(uint256 => uint256) private _itemTypes;

    struct RarityInfo {
        uint256 zeroIndex;
        uint256 rarity;
    }

    // Items for specific type
    struct Items {
        uint256 totalRarity;
        uint256[] itemIds;
        mapping(uint256 => RarityInfo) itemIdToRarity;
    }

    constructor(uint256 rarityDecimal_) {
        require(
            rarityDecimal_ > uint256(0),
            "ItemFactory: rarityDecimal_ is 0"
        );

        _rarityDecimal = rarityDecimal_;

        _supportedBoxTypes.add(1); // characters
        _supportedBoxTypes.add(2); // cars
        _supportedBoxTypes.add(3); // weapons
        _supportedBoxTypes.add(4); // characters, cars, weapons

        _supportedItemTypes.add(1); // characters
        _supportedItemTypes.add(2); // cars
        _supportedItemTypes.add(3); // weapons

        _addTypeArtifact(1, 1, 18); // clothes
        _addTypeArtifact(1, 2, 20); // wristband
        _addTypeArtifact(2, 3, 11); // gun
        _addTypeArtifact(2, 4, 11); // flag
    }

    modifier onlySupportedBoxType(uint256 boxType_) {
        require(
            _supportedBoxTypes.contains(boxType_),
            "ItemFactory: unsupported box type"
        );
        _;
    }

    modifier onlySupportedItemType(uint256 itemType_) {
        require(
            _supportedItemTypes.contains(itemType_),
            "ItemFactory: unsupported item type"
        );
        _;
    }

    function _addTypeArtifact(
        uint256 itemType_,
        uint256 artifactId_,
        uint256 artifactRange_
    ) private {
        require(_supportedArtifactIds.add(artifactId_));
        require(_artifactIds[itemType_].add(artifactId_));
        _artifactRanges[artifactId_] = artifactRange_;
    }

    function supportedBoxTypes() external view returns (uint256[] memory) {
        return _supportedBoxTypes.values();
    }

    function rarityDecimal() external view returns (uint256) {
        return _rarityDecimal;
    }

    function totalSupply(uint256 boxType_) external view returns (uint256) {
        return _items[boxType_].itemIds.length;
    }

    function artifactsLength(uint256 itemType_)
        external
        view
        returns (uint256)
    {
        return _artifactIds[itemType_].length();
    }

    function artifactIdAt(uint256 itemType_, uint256 index_)
        external
        view
        returns (uint256)
    {
        return _artifactIds[itemType_].at(index_);
    }

    function getRandomArtifactValue(uint256 randomness_, uint256 artifactId_)
        external
        view
        returns (uint256)
    {
        uint256 _artifactRange = _artifactRanges[artifactId_];
        require(_artifactRange > 0);
        return (randomness_ % _artifactRange) + 1;
    }

    function addBoxType(uint256 boxType_) external onlyOwner {
        bool success = _supportedBoxTypes.add(boxType_);
        require(success, "ItemFactory: item type is already supported");
    }

    function addTypeArtifact(
        uint256 itemType_,
        uint256 artifactId_,
        uint256 artifactLength_
    ) public onlyOwner onlySupportedItemType(itemType_) {
        require(artifactLength_ > 0);
        _addTypeArtifact(itemType_, artifactId_, artifactLength_);
    }

    function addItem(
        uint256 boxType_,
        uint256 itemType_,
        uint256 itemId_,
        uint256 rarity_
    )
        external
        onlyOwner
        onlySupportedBoxType(boxType_)
        onlySupportedItemType(itemType_)
    {
        require(itemId_ > uint256(0), "ItemFactory: itemId_ is 0");
        require(rarity_ > uint256(0), "ItemFactory: rarity_ is 0");

        Items storage _itemsForSpecificType = _items[boxType_];
        require(
            _itemsForSpecificType.itemIdToRarity[itemId_].rarity == uint256(0),
            "ItemFactory: itemId_ is already existed"
        );

        // Add item type mapping
        _itemTypes[itemId_] = itemType_;

        // Update artifacts for current type
        _itemsForSpecificType.itemIds.push(itemId_);

        // Update rarity info for item
        _itemsForSpecificType
            .itemIdToRarity[itemId_]
            .zeroIndex = _itemsForSpecificType.totalRarity;
        _itemsForSpecificType.itemIdToRarity[itemId_].rarity = rarity_;

        // Update total rarity
        _itemsForSpecificType.totalRarity += rarity_;

        emit ItemAdded(boxType_, itemType_, itemId_, rarity_);
    }

    function getRandomItem(uint256 randomness_, uint256 boxType_)
        public
        view
        onlySupportedBoxType(boxType_)
        returns (uint256 _itemId, uint256 _itemType)
    {
        Items storage _itemsForSpecificType = _items[boxType_];
        require(
            _itemsForSpecificType.totalRarity > 0,
            "ItemFactory: add items for this type before using function"
        );

        uint256 _randomNumber = randomness_ % _itemsForSpecificType.totalRarity;

        for (uint256 i = 0; i < _itemsForSpecificType.itemIds.length; i++) {
            RarityInfo storage _rarityInfo = _itemsForSpecificType
                .itemIdToRarity[_itemsForSpecificType.itemIds[i]];

            if (
                _rarityInfo.zeroIndex <= _randomNumber &&
                _randomNumber < _rarityInfo.zeroIndex + _rarityInfo.rarity
            ) {
                _itemId = _itemsForSpecificType.itemIds[i];
                _itemType = _itemTypes[_itemId];
                break;
            }
        }
    }
}