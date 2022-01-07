/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IMerge {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(uint256[] calldata values_) external;
    function massOf(uint256 tokenId) external view returns (uint256);
    function tokenOf(address account) external view returns (uint256);
    function getValueOf(uint256 tokenId) external view returns (uint256);
    function decodeClass(uint256 value) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isWhitelisted(address account) external view returns (bool);
    function isBlacklisted(address account) external view returns (bool);
}

contract MergeFaucet is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet redTokens;
    EnumerableSet.UintSet yellowTokens;
    EnumerableSet.UintSet blueTokens;
    EnumerableSet.UintSet tokenIds;
    mapping(uint256 => uint256[]) public classes;  // class to tokenIds;
    uint256 public curTokenId;
    address public merge;
    uint256 constant private CLASS_MULTIPLIER = 100 * 1000 * 1000; // 100 million
    uint256 constant private MAX_MASS_EXCL = CLASS_MULTIPLIER - 1;

    function init(address merge_) public onlyOwner {
        merge = merge_;
    }

    function mint(uint256[] calldata values_) external {

        IMerge(merge).mint(values_);

        uint256 class;
        uint256 _tokenId = curTokenId;
        uint256 tier;

        for (uint256 i = 0; i < values_.length; i++) {
            if (isSentinelMass(values_[i])) {
                // Skip certain values
            } else {
                _tokenId++;
                tier = _tierOf(values_[i]);
                if (tier == 4) {
                    redTokens.add(_tokenId);
                } else if (tier == 3) {
                    yellowTokens.add(_tokenId);
                } else if (tier == 2) {
                    blueTokens.add(_tokenId);
                } else {
                    class = _classOf(_tokenId);
                    classes[class].push(_tokenId);
                }
                tokenIds.add(_tokenId);
            }
        }
        curTokenId = _tokenId;
    }

    function claim() public {
        uint256 n = tokenIds.length();
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp))) % n;
        uint256 _tokenId = tokenIds.at(index);
        IMerge(merge).safeTransferFrom(address(this), _msgSender(), _tokenId);
        uint256 tier = _tierOf(_valueOf(_tokenId));
        if (tier == 4) {
            redTokens.remove(_tokenId);
        } else if (tier == 3) {
            yellowTokens.remove(_tokenId);
        } else if (tier == 2) {
            blueTokens.remove(_tokenId);
        }
        tokenIds.remove(_tokenId);
    }

    function claimExact(uint256 tier, uint256 class) public {
        if (tier == 4) {
            uint256 n = redTokens.length();
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp))) % n;
            uint256 _tokenId = redTokens.at(index);
            IMerge(merge).safeTransferFrom(address(this), _msgSender(), _tokenId);
            redTokens.remove(_tokenId);
            tokenIds.remove(_tokenId);
        } else if (tier == 3) {
            uint256 n = yellowTokens.length();
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp))) % n;
            uint256 _tokenId = yellowTokens.at(index);
            IMerge(merge).safeTransferFrom(address(this), _msgSender(), _tokenId);
            yellowTokens.remove(_tokenId);
            tokenIds.remove(_tokenId);
        } else if (tier == 2) {
            uint256 n = blueTokens.length();
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp))) % n;
            uint256 _tokenId = blueTokens.at(index);
            IMerge(merge).safeTransferFrom(address(this), _msgSender(), _tokenId);
            blueTokens.remove(_tokenId);
            tokenIds.remove(_tokenId);
        } else if (tier == 1) {
            uint256[] memory tokens = classes[class];
            uint256 _tokenId;
            for (uint256 i = 0; i < tokens.length; i++) {
                if (tokenIds.contains(tokens[i])) {
                    _tokenId = tokens[i];
                    IMerge(merge).safeTransferFrom(address(this), _msgSender(), _tokenId);
                    tokenIds.remove(_tokenId);
                    break;
                }
            }
        }
    }

    function isSentinelMass(uint256 value) private pure returns (bool) {
        return (value % CLASS_MULTIPLIER) == MAX_MASS_EXCL;
    }

    /**
     * @dev Retrieves the value of token with `tokenId`.
     */
    function _valueOf(uint256 tokenId) private view returns (uint256) {
        return IMerge(merge).getValueOf(tokenId);
    }

    /**
     * @dev Retrieves the class/tier of token with `tokenId`.
     */
    function _tierOf(uint256 value) private view returns (uint256) {
        return IMerge(merge).decodeClass(value);
    }

    /**
     * @dev Retrieves the class of token with `tokenId`, i.e., the last two digits
     * of `tokenId`.
     */
    function _classOf(uint256 tokenId) private pure returns (uint256) {
        return tokenId % 100;
    }
}