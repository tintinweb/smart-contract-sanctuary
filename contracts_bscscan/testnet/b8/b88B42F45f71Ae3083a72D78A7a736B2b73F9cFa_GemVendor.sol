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
        return msg.data;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGemVendor.sol";
import "./interfaces/IGem.sol";

contract GemVendor is IGemVendor, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    IGem public gemContract;
    
    mapping(uint => EnumerableSet.UintSet) private _itemsOfVendor;
    mapping(uint => bool) private items;
    
    constructor(IGem _gemContract) {
        gemContract = _gemContract;
    }
    
    modifier onlyGemContract() {
        require(address(gemContract) == msg.sender, "GemVendor: not from Gem");
        _;
    }
    
    /**
     * @dev Owner adds a list of items to the vendor.
     * @param vendorId id of vendor.
     * @param itemIds list id of items.
     */
    function addItemsToVendor(uint vendorId, uint[] memory itemIds) external onlyOwner override {
        for(uint i = 0; i < itemIds.length; i++){
            require(!items[itemIds[i]], "GemVendor: Item is existed");
            IGem.Item memory item = gemContract.getItem(itemIds[i]);
            require(item.tier == 1, "GemVendor: cannot add");
            require(item.minted < item.maxSupply, "GemVendor: Item is reached max supply");
            
            _itemsOfVendor[vendorId].add(itemIds[i]);
            items[itemIds[i]] = true;
        }
        emit ItemsAdded(vendorId, itemIds);
    }

    /**
     * @dev Owner removes a list of items from the vendor.
     * @param vendorId id of vendor.
     * @param itemIds list id of items.
     */
    function removeItemsFromVendor(uint vendorId, uint[] memory itemIds) external onlyOwner override {
        for(uint i = 0; i < itemIds.length; i++){
            require(items[itemIds[i]], "GemVendor: Item does not exist");
            _itemsOfVendor[vendorId].remove(itemIds[i]);
            items[itemIds[i]] = false;
        }
        emit ItemsRemoved(vendorId, itemIds);
    }

    /**
     * @dev Only `gemContract` mints random items.
     * @param account address of buyer who want to buy random item .
     * @param vendorId id of vendor.
     * @param amount amount of item which buyer want to buy.
     */
    function mintRandomItems(address account, uint vendorId, uint amount) external override onlyGemContract returns (uint) {
        uint[] memory vendorItemIds = _getVendorItemIds(vendorId);
        uint length = vendorItemIds.length;
        uint minted = 0;
        for(uint i = 0; i < amount; i++){
            uint random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % length;
            uint itemId = _itemsOfVendor[vendorId].at(random);
            IGem.Item memory item = gemContract.getItem(itemId);
            if (item.minted < item.maxSupply) {
                IGem(gemContract).mint(account, itemId, 1);
                minted++;
                if (item.minted + 1 == item.maxSupply) {
                    _itemsOfVendor[vendorId].remove(itemId);
                    items[itemId] = false;
                    length -= 1;
                }
            }
        }
        return minted;
    }
    
    /**
     * @dev User gets all items in a given vendor.
     * @param vendorId id of vendor.
     */
    function getVendorItemIds(uint vendorId) external view override returns (uint[] memory) {
        return _getVendorItemIds(vendorId);
    }
    
    function _getVendorItemIds(uint vendorId) internal view returns (uint[] memory) {
        uint[] memory vendorItemIds = new uint[](_itemsOfVendor[vendorId].length());
        for(uint i = 0; i < _itemsOfVendor[vendorId].length(); i++){
            vendorItemIds[i] = _itemsOfVendor[vendorId].at(i);
        }
        return vendorItemIds;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGem {
    enum GemType { GEM1, GEM2, GEM3, GEM4, GEM5}
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }

    struct Item {
        string name;
        uint16 maxSupply;
        uint16 minted;
        uint16 burnt;
        uint8 tier;
        uint8 upgradeAmount;
        Rarity rarity;
        GemType gemType;
    }

    event ItemCreated(uint indexed itemId, string name, uint16 maxSupply, Rarity rarity);
    event ItemUpgradable(uint indexed itemId, uint indexed nextTierItemId, uint8 upgradeAmount);

    /**
     * @notice Create an item.
     */
    function createItem(string memory name, uint16 maxSupply, Rarity rarity, GemType gemType) external;

    /**
     * @notice Add next tier item to existing one.
     */
    function addNextTierItem(uint itemId, uint8 upgradeAmount) external;

    /**
     * @notice Burns the same items to upgrade its tier.
     *
     * Requirements:
     * - sufficient token balance.
     * - Item must have its next tier.
     * - Sender's balance must have at least `upgradeAmount`
     */
    function upgradeItem(uint itemId) external;

    /**
     * @notice Pays some fee to get random items.
     */
    function rollGemGacha(uint vendorId, uint amount) external;

    /**
     * @notice Mints items and returns true if it's run out of stock.
     */
    function mint(address account, uint itemId, uint16 amount) external returns (bool);

    /**
     * @notice Burns ERC1155 gem since it is equipped to the hero.
     */
    function putItemsIntoStorage(address account, uint[] memory itemIds) external;

    /**
     * @notice Returns ERC1155 gem back to the owner.
     */
    function returnItems(address account, uint[] memory itemIds) external;

    /**
     * @notice Gets item information.
     */
    function getItem(uint itemId) external view returns (Item memory item);
    
    /**
     * @notice Gets gem type.
     */
    function getGemType(uint itemId) external view returns (GemType);

    /**
     * @notice Check if item is out of stock.
     */
    function isOutOfStock(uint itemId, uint16 amount) external view returns (bool);
}

pragma solidity ^0.8.0;

import "./IGem.sol";

interface IGemVendor {
    event ItemsAdded(uint indexed vendorId, uint[] itemIds);
    event ItemsRemoved(uint indexed vendorId, uint[] itemIds);
    event ItemsReceived(uint indexed vendorId, uint[] itemIds);

    /**
     * @notice Adds a list of items to the vendor.
     *
     * Requirements:
     * - Only `tier` 1 items can be added.
     * - Item's `minted` must not equal or bigger than `maxSupply`.
     */
    function addItemsToVendor(uint vendorId, uint[] memory itemIds) external;

    /**
     * @notice Removes a list of items from the vendor.
     */
    function removeItemsFromVendor(uint vendorId, uint[] memory itemIds) external;

    /**
     * @notice Mints random items.
     *
     * Requirements:
     * - Only `gemContract` can call this function.
     */
    function mintRandomItems(address account, uint vendorId, uint amount) external returns (uint);

    /**
     * @notice Gets all items in a given vendor.
     */
    function getVendorItemIds(uint vendorId) external view returns (uint[] memory);
}

