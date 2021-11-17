// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./PositionsManagerStorageForCompound.sol";

/**
 *  @title UpdatePositions.
 *  @dev Allows to move the logic from the positions manager to this contract.
 */
contract UpdatePositions is ReentrancyGuard, PositionsManagerStorageForCompound {
    using RedBlackBinaryTree for RedBlackBinaryTree.Tree;
    using EnumerableSet for EnumerableSet.AddressSet;

    /** @dev Updates borrowers tree with the new balances of a given account.
     *  @param _cTokenAddress The address of the market on which Morpho want to update the borrower lists.
     *  @param _account The address of the borrower to move.
     */
    function updateBorrowerList(address _cTokenAddress, address _account) external {
        uint256 onPool = borrowBalanceInOf[_cTokenAddress][_account].onPool;
        uint256 inP2P = borrowBalanceInOf[_cTokenAddress][_account].inP2P;
        uint256 numberOfBorrowersOnPool = borrowersOnPool[_cTokenAddress].numberOfKeys();
        uint256 numberOfBorrowersInP2P = borrowersInP2P[_cTokenAddress].numberOfKeys();
        bool isOnPool = borrowersOnPool[_cTokenAddress].keyExists(_account);
        bool isInP2P = borrowersInP2P[_cTokenAddress].keyExists(_account);

        // Check pool
        bool isOnPoolAndValueChanged = isOnPool &&
            borrowersOnPool[_cTokenAddress].getValueOfKey(_account) != onPool;
        if (isOnPoolAndValueChanged) borrowersOnPool[_cTokenAddress].remove(_account);
        if (onPool > 0 && (isOnPoolAndValueChanged || !isOnPool)) {
            if (numberOfBorrowersOnPool <= NMAX) {
                numberOfBorrowersOnPool++;
                borrowersOnPool[_cTokenAddress].insert(_account, onPool);
            } else {
                (uint256 minimum, address minimumAccount) = borrowersOnPool[_cTokenAddress]
                    .getMinimum();
                if (onPool > minimum) {
                    borrowersOnPool[_cTokenAddress].remove(minimumAccount);
                    borrowersOnPoolBuffer[_cTokenAddress].add(minimumAccount);
                    borrowersOnPool[_cTokenAddress].insert(_account, onPool);
                } else borrowersOnPoolBuffer[_cTokenAddress].add(_account);
            }
        }
        if (onPool == 0 && borrowersOnPoolBuffer[_cTokenAddress].contains(_account))
            borrowersOnPoolBuffer[_cTokenAddress].remove(_account);

        // Check P2P
        bool isInP2PAndValueChanged = isInP2P &&
            borrowersInP2P[_cTokenAddress].getValueOfKey(_account) != inP2P;
        if (isInP2PAndValueChanged) borrowersInP2P[_cTokenAddress].remove(_account);
        if (inP2P > 0 && (isInP2PAndValueChanged || !isInP2P)) {
            if (numberOfBorrowersInP2P <= NMAX) {
                numberOfBorrowersInP2P++;
                borrowersInP2P[_cTokenAddress].insert(_account, inP2P);
            } else {
                (uint256 minimum, address minimumAccount) = borrowersInP2P[_cTokenAddress]
                    .getMinimum();
                if (inP2P > minimum) {
                    borrowersInP2P[_cTokenAddress].remove(minimumAccount);
                    borrowersInP2PBuffer[_cTokenAddress].add(minimumAccount);
                    borrowersInP2P[_cTokenAddress].insert(_account, inP2P);
                } else borrowersInP2PBuffer[_cTokenAddress].add(_account);
            }
        }
        if (inP2P == 0 && borrowersInP2PBuffer[_cTokenAddress].contains(_account))
            borrowersInP2PBuffer[_cTokenAddress].remove(_account);

        // Add user to the trees if possible
        if (borrowersOnPoolBuffer[_cTokenAddress].length() > 0 && numberOfBorrowersOnPool <= NMAX) {
            address account = borrowersOnPoolBuffer[_cTokenAddress].at(0);
            uint256 value = borrowBalanceInOf[_cTokenAddress][account].onPool;
            borrowersOnPoolBuffer[_cTokenAddress].remove(account);
            borrowersOnPool[_cTokenAddress].insert(account, value);
        }
        if (borrowersInP2PBuffer[_cTokenAddress].length() > 0 && numberOfBorrowersInP2P <= NMAX) {
            address account = borrowersInP2PBuffer[_cTokenAddress].at(0);
            uint256 value = borrowBalanceInOf[_cTokenAddress][account].inP2P;
            borrowersInP2PBuffer[_cTokenAddress].remove(account);
            borrowersInP2P[_cTokenAddress].insert(account, value);
        }
    }

    /** @dev Updates suppliers tree with the new balances of a given account.
     *  @param _cTokenAddress The address of the market on which Morpho want to update the supplier lists.
     *  @param _account The address of the supplier to move.
     */
    function updateSupplierList(address _cTokenAddress, address _account) external {
        uint256 onPool = supplyBalanceInOf[_cTokenAddress][_account].onPool;
        uint256 inP2P = supplyBalanceInOf[_cTokenAddress][_account].inP2P;
        uint256 numberOfSuppliersOnPool = suppliersOnPool[_cTokenAddress].numberOfKeys();
        uint256 numberOfSuppliersInP2P = suppliersInP2P[_cTokenAddress].numberOfKeys();
        bool isOnPool = suppliersOnPool[_cTokenAddress].keyExists(_account);
        bool isInP2P = suppliersInP2P[_cTokenAddress].keyExists(_account);

        // Check pool
        bool isOnPoolAndValueChanged = isOnPool &&
            suppliersOnPool[_cTokenAddress].getValueOfKey(_account) != onPool;
        if (isOnPoolAndValueChanged) suppliersOnPool[_cTokenAddress].remove(_account);
        if (onPool > 0 && (isOnPoolAndValueChanged || !isOnPool)) {
            if (numberOfSuppliersOnPool <= NMAX) {
                numberOfSuppliersOnPool++;
                suppliersOnPool[_cTokenAddress].insert(_account, onPool);
            } else {
                (uint256 minimum, address minimumAccount) = suppliersOnPool[_cTokenAddress]
                    .getMinimum();
                if (onPool > minimum) {
                    suppliersOnPool[_cTokenAddress].remove(minimumAccount);
                    suppliersOnPoolBuffer[_cTokenAddress].add(minimumAccount);
                    suppliersOnPool[_cTokenAddress].insert(_account, onPool);
                } else suppliersOnPoolBuffer[_cTokenAddress].add(_account);
            }
        }
        if (onPool == 0 && suppliersOnPoolBuffer[_cTokenAddress].contains(_account))
            suppliersOnPoolBuffer[_cTokenAddress].remove(_account);

        // Check P2P
        bool isInP2PAndValueChanged = isInP2P &&
            suppliersInP2P[_cTokenAddress].getValueOfKey(_account) != inP2P;
        if (isInP2PAndValueChanged) suppliersInP2P[_cTokenAddress].remove(_account);
        if (inP2P > 0 && (isInP2PAndValueChanged || !isInP2P)) {
            if (numberOfSuppliersInP2P <= NMAX) {
                numberOfSuppliersInP2P++;
                suppliersInP2P[_cTokenAddress].insert(_account, inP2P);
            } else {
                (uint256 minimum, address minimumAccount) = suppliersInP2P[_cTokenAddress]
                    .getMinimum();
                if (inP2P > minimum) {
                    suppliersInP2P[_cTokenAddress].remove(minimumAccount);
                    suppliersInP2PBuffer[_cTokenAddress].add(minimumAccount);
                    suppliersInP2P[_cTokenAddress].insert(_account, inP2P);
                } else suppliersInP2PBuffer[_cTokenAddress].add(_account);
            }
        }
        if (inP2P == 0 && suppliersInP2PBuffer[_cTokenAddress].contains(_account))
            suppliersInP2PBuffer[_cTokenAddress].remove(_account);

        // Add user to the trees if possible
        if (suppliersOnPoolBuffer[_cTokenAddress].length() > 0 && numberOfSuppliersOnPool <= NMAX) {
            address account = suppliersOnPoolBuffer[_cTokenAddress].at(0);
            uint256 value = supplyBalanceInOf[_cTokenAddress][account].onPool;
            suppliersOnPoolBuffer[_cTokenAddress].remove(account);
            suppliersOnPool[_cTokenAddress].insert(account, value);
        }
        if (suppliersInP2PBuffer[_cTokenAddress].length() > 0 && numberOfSuppliersInP2P <= NMAX) {
            address account = suppliersInP2PBuffer[_cTokenAddress].at(0);
            uint256 value = supplyBalanceInOf[_cTokenAddress][account].inP2P;
            suppliersInP2PBuffer[_cTokenAddress].remove(account);
            suppliersInP2P[_cTokenAddress].insert(account, value);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./libraries/RedBlackBinaryTree.sol";
import {IComptroller} from "./interfaces/compound/ICompound.sol";
import "./interfaces/IMarketsManagerForCompound.sol";
import "./interfaces/IUpdatePositions.sol";

/**
 *  @title MorphoPositionsManagerForComp.
 *  @dev Smart contract interacting with Comp to enable P2P supply/borrow positions that can fallback on Comp's pool using cToken tokens.
 */
contract PositionsManagerStorageForCompound {
    /* Structs */

    struct SupplyBalance {
        uint256 inP2P; // In p2pUnit, a unit that grows in value, to keep track of the interests/debt increase when users are in p2p.
        uint256 onPool; // In cToken.
    }

    struct BorrowBalance {
        uint256 inP2P; // In p2pUnit.
        uint256 onPool; // In cdUnit, a unit that grows in value, to keep track of the debt increase when users are in Comp. Multiply by current borrowIndex to get the underlying amount.
    }

    /* Storage */

    uint16 public NMAX = 1000;
    uint8 public constant CTOKEN_DECIMALS = 8;
    mapping(address => RedBlackBinaryTree.Tree) internal suppliersInP2P; // Suppliers in peer-to-peer.
    mapping(address => RedBlackBinaryTree.Tree) internal suppliersOnPool; // Suppliers on Comp.
    mapping(address => RedBlackBinaryTree.Tree) internal borrowersInP2P; // Borrowers in peer-to-peer.
    mapping(address => RedBlackBinaryTree.Tree) internal borrowersOnPool; // Borrowers on Comp.
    mapping(address => EnumerableSet.AddressSet) internal suppliersInP2PBuffer; // Buffer of suppliers in peer-to-peer.
    mapping(address => EnumerableSet.AddressSet) internal suppliersOnPoolBuffer; // Buffer of suppliers on Comp.
    mapping(address => EnumerableSet.AddressSet) internal borrowersInP2PBuffer; // Buffer of borrowers in peer-to-peer.
    mapping(address => EnumerableSet.AddressSet) internal borrowersOnPoolBuffer; // Buffer of borrowers on Comp.
    mapping(address => mapping(address => SupplyBalance)) public supplyBalanceInOf; // For a given market, the supply balance of user.
    mapping(address => mapping(address => BorrowBalance)) public borrowBalanceInOf; // For a given market, the borrow balance of user.
    mapping(address => mapping(address => bool)) public accountMembership; // Whether the account is in the market or not.
    mapping(address => address[]) public enteredMarkets; // Markets entered by a user.
    mapping(address => uint256) public threshold; // Thresholds below the ones suppliers and borrowers cannot enter markets.

    IUpdatePositions public updatePositions;
    IComptroller public comptroller;
    IMarketsManagerForCompound public marketsManagerForCompound;
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

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity 0.8.7;

// A Solidity Red-Black Tree library to store and maintain a sorted data structure in a Red-Black binary search tree,
// with O(log 2n) insert, remove and search time (and gas, approximately) based on https://github.com/rob-Hitchens/OrderStatisticsTree
// Copyright (c) Rob Hitchens. the MIT License.
// Significant portions from BokkyPooBahsRedBlackTreeLibrary,
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

library RedBlackBinaryTree {
    struct Node {
        address parent; // The parent node of the current node.
        address leftChild; // The left child of the current node.
        address rightChild; // The right child of the current node.
        bool red; // Whether the current node is red or black.
    }

    struct Tree {
        uint256 count; // The number of nodes in the tree.
        uint256 minimum; // The minimum value of the tree.
        address minimumKey; // The key related to the minimum value.
        uint256 maximum; // The maximum value of the tree.
        address maximumKey; // Key related to the maximum value.
        address root; // the ddress of the root node.
        mapping(address => Node) nodes; // Maps user's address to node.
        mapping(address => uint256) keyToValue; // Maps key to its value.
    }

    /** @dev Returns the address of the smallest value in the tree `_self`.
     *  @param _self The tree to search in.
     */
    function first(Tree storage _self) public view returns (address key) {
        key = _self.root;
        if (key == address(0)) return address(0);
        while (_self.nodes[key].leftChild != address(0)) {
            key = _self.nodes[key].leftChild;
        }
    }

    /** @dev Returns the address of the highest value in the tree `_self`.
     *  @param _self The tree to search in.
     */
    function last(Tree storage _self) public view returns (address key) {
        key = _self.root;
        if (key == address(0)) return address(0);
        while (_self.nodes[key].rightChild != address(0)) {
            key = _self.nodes[key].rightChild;
        }
    }

    /** @dev Returns the address of the next user after `_key`.
     *  @param _self The tree to search in.
     *  @param _key The address to search after.
     */
    function next(Tree storage _self, address _key) public view returns (address cursor) {
        require(_key != address(0), "RBBT(1):key-is-nul-address");
        if (_self.nodes[_key].rightChild != address(0)) {
            cursor = subTreeMin(_self, _self.nodes[_key].rightChild);
        } else {
            cursor = _self.nodes[_key].parent;
            while (cursor != address(0) && _key == _self.nodes[cursor].rightChild) {
                _key = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    /** @dev Returns the address of the previous user above `_key`.
     *  @param _self The tree to search in.
     *  @param _key The address to search before.
     */
    function prev(Tree storage _self, address _key) public view returns (address cursor) {
        require(_key != address(0), "RBBT(2):start-value=0");
        if (_self.nodes[_key].leftChild != address(0)) {
            cursor = subTreeMax(_self, _self.nodes[_key].leftChild);
        } else {
            cursor = _self.nodes[_key].parent;
            while (cursor != address(0) && _key == _self.nodes[cursor].leftChild) {
                _key = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    /** @dev Returns whether the `_key` exists in the tree or not.
     *  @param _self The tree to search in.
     *  @param _key The key to search.
     *  @return Whether the `_key` exists in the tree or not.
     */
    function keyExists(Tree storage _self, address _key) public view returns (bool) {
        return _self.keyToValue[_key] != 0;
    }

    /** @dev Returns the number of keys in the tree.
     *  @param _self The tree to search in.
     *  @return The number of keys.
     */
    function numberOfKeys(Tree storage _self) public view returns (uint256) {
        return _self.count;
    }

    /** @dev Returns the value related to the given the `_key`.
     *  @param _self The tree to search in.
     *  @param _key The key to search for.
     *  @return The value related to the given the `_key`. 0 if the key does not exist.
     */
    function getValueOfKey(Tree storage _self, address _key) public view returns (uint256) {
        return _self.keyToValue[_key];
    }

    /** @dev Returns the minimum value of the tree and the related address.
     *  @param _self The tree to search in.
     *  @return (The minimum of the tree, The address related to the minimum).
     */
    function getMinimum(Tree storage _self) public view returns (uint256, address) {
        return (_self.minimum, _self.minimumKey);
    }

    /** @dev Returns the maximum value of the tree and the related address.
     *  @param _self The tree to search in.
     *  @return (The minimum of the tree, The address related to the maximum).
     */
    function getMaximum(Tree storage _self) public view returns (uint256, address) {
        return (_self.maximum, _self.maximumKey);
    }

    /** @dev Returns true if A>B according to the order relationship.
     *  @param _valueA value for user A.
     *  @param _addressA Address for user A.
     *  @param _valueB value for user B.
     *  @param _addressB Address for user B.
     */
    function compare(
        uint256 _valueA,
        address _addressA,
        uint256 _valueB,
        address _addressB
    ) public pure returns (bool) {
        if (_valueA == _valueB) {
            if (_addressA > _addressB) {
                return true;
            }
        }
        if (_valueA > _valueB) {
            return true;
        }
        return false;
    }

    /** @dev Returns whether or not there is any key in the tree.
     *  @param _self The tree to search in.
     *  @return Whether or not a key exist in the tree.
     */
    function isNotEmpty(Tree storage _self) public view returns (bool) {
        return _self.root != address(0);
    }

    /** @dev Inserts the `_key` with `_value` in the tree.
     *  @param _self The tree in which to add the (key, value) pair.
     *  @param _key The key to add.
     *  @param _value The value to add.
     */
    function insert(
        Tree storage _self,
        address _key,
        uint256 _value
    ) public {
        require(_value != 0, "RBBT:value-cannot-be-0");
        require(_self.keyToValue[_key] == 0, "RBBT:account-already-in");
        if (_self.minimum == 0 || compare(_self.minimum, _self.minimumKey, _value, _key)) {
            _self.minimumKey = _key;
            _self.minimum = _value;
        }
        if (_self.maximum == 0 || compare(_value, _key, _self.maximum, _self.maximumKey)) {
            _self.maximumKey = _key;
            _self.maximum = _value;
        }
        _self.count++;
        _self.keyToValue[_key] = _value;
        address cursor;
        address probe = _self.root;
        while (probe != address(0)) {
            cursor = probe;
            if (compare(_self.keyToValue[probe], probe, _value, _key)) {
                probe = _self.nodes[probe].leftChild;
            } else {
                probe = _self.nodes[probe].rightChild;
            }
        }
        Node storage nValue = _self.nodes[_key];
        nValue.parent = cursor;
        nValue.leftChild = address(0);
        nValue.rightChild = address(0);
        nValue.red = true;
        if (cursor == address(0)) {
            _self.root = _key;
        } else if (compare(_self.keyToValue[cursor], cursor, _value, _key)) {
            _self.nodes[cursor].leftChild = _key;
        } else {
            _self.nodes[cursor].rightChild = _key;
        }
        insertFixup(_self, _key);
    }

    /** @dev Removes the `_key` in the tree and its related value if no-one shares the same value.
     *  @param _self The tree in which to remove the (key, value) pair.
     *  @param _key The key to remove.
     */
    function remove(Tree storage _self, address _key) public {
        uint256 value = _self.keyToValue[_key];
        require(value != 0, "RBBT:account-not-exist");
        if (value == _self.minimum && _key == _self.minimumKey) {
            address newMinimumKey = next(_self, _key);
            _self.minimumKey = newMinimumKey;
            _self.minimum = _self.keyToValue[newMinimumKey];
        }
        if (value == _self.maximum && _key == _self.maximumKey) {
            address newMaximumKey = prev(_self, _key);
            _self.maximumKey = newMaximumKey;
            _self.maximum = _self.keyToValue[newMaximumKey];
        }
        _self.count--;
        _self.keyToValue[_key] = 0;
        address probe;
        address cursor;
        if (
            _self.nodes[_key].leftChild == address(0) || _self.nodes[_key].rightChild == address(0)
        ) {
            cursor = _key;
        } else {
            cursor = _self.nodes[_key].rightChild;
            while (_self.nodes[cursor].leftChild != address(0)) {
                cursor = _self.nodes[cursor].leftChild;
            }
        }
        if (_self.nodes[cursor].leftChild != address(0)) {
            probe = _self.nodes[cursor].leftChild;
        } else {
            probe = _self.nodes[cursor].rightChild;
        }
        address cursorParent = _self.nodes[cursor].parent;
        _self.nodes[probe].parent = cursorParent;
        if (cursorParent != address(0)) {
            if (cursor == _self.nodes[cursorParent].leftChild) {
                _self.nodes[cursorParent].leftChild = probe;
            } else {
                _self.nodes[cursorParent].rightChild = probe;
            }
        } else {
            _self.root = probe;
        }
        bool doFixup = !_self.nodes[cursor].red;
        if (cursor != _key) {
            replaceParent(_self, cursor, _key);
            _self.nodes[cursor].leftChild = _self.nodes[_key].leftChild;
            _self.nodes[_self.nodes[cursor].leftChild].parent = cursor;
            _self.nodes[cursor].rightChild = _self.nodes[_key].rightChild;
            _self.nodes[_self.nodes[cursor].rightChild].parent = cursor;
            _self.nodes[cursor].red = _self.nodes[_key].red;
            (cursor, _key) = (_key, cursor);
        }
        if (doFixup) {
            removeFixup(_self, probe);
        }
        delete _self.nodes[cursor];
    }

    /** @dev Returns the minimum of the subtree beginning at a given node.
     *  @param _self The tree to search in.
     *  @param _key The value of the node to start at.
     */
    function subTreeMin(Tree storage _self, address _key) private view returns (address) {
        while (_self.nodes[_key].leftChild != address(0)) {
            _key = _self.nodes[_key].leftChild;
        }
        return _key;
    }

    /** @dev Returns the maximum of the subtree beginning at a given node.
     *  @param _self The tree to search in.
     *  @param _key The address of the node to start at.
     */
    function subTreeMax(Tree storage _self, address _key) private view returns (address) {
        while (_self.nodes[_key].rightChild != address(0)) {
            _key = _self.nodes[_key].rightChild;
        }
        return _key;
    }

    /** @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's rightChild child), C (B's leftChild child).
     *       After leftChild rotation: B (Root), A (B's leftChild child), C (B's rightChild child)
     *  @param _self The tree to apply the rotation to.
     *  @param _key The address of the node to rotate.
     */
    function rotateLeft(Tree storage _self, address _key) private {
        address cursor = _self.nodes[_key].rightChild;
        address keyParent = _self.nodes[_key].parent;
        address cursorLeft = _self.nodes[cursor].leftChild;
        _self.nodes[_key].rightChild = cursorLeft;

        if (cursorLeft != address(0)) {
            _self.nodes[cursorLeft].parent = _key;
        }
        _self.nodes[cursor].parent = keyParent;
        if (keyParent == address(0)) {
            _self.root = cursor;
        } else if (_key == _self.nodes[keyParent].leftChild) {
            _self.nodes[keyParent].leftChild = cursor;
        } else {
            _self.nodes[keyParent].rightChild = cursor;
        }
        _self.nodes[cursor].leftChild = _key;
        _self.nodes[_key].parent = cursor;
    }

    /** @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's leftChild child), C (B's rightChild child).
             After rightChild rotation: B (Root), A (B's rightChild child), C (B's leftChild child)
     *  @param _self The tree to apply the rotation to.
     *  @param _key The address of the node to rotate.
     */
    function rotateRight(Tree storage _self, address _key) private {
        address cursor = _self.nodes[_key].leftChild;
        address keyParent = _self.nodes[_key].parent;
        address cursorRight = _self.nodes[cursor].rightChild;
        _self.nodes[_key].leftChild = cursorRight;
        if (cursorRight != address(0)) {
            _self.nodes[cursorRight].parent = _key;
        }
        _self.nodes[cursor].parent = keyParent;
        if (keyParent == address(0)) {
            _self.root = cursor;
        } else if (_key == _self.nodes[keyParent].rightChild) {
            _self.nodes[keyParent].rightChild = cursor;
        } else {
            _self.nodes[keyParent].leftChild = cursor;
        }
        _self.nodes[cursor].rightChild = _key;
        _self.nodes[_key].parent = cursor;
    }

    /** @dev Makes sure there is no violation of the tree properties after an insertion.
     *  @param _self The tree to check and correct if needed.
     *  @param _key The address of the user that was inserted.
     */
    function insertFixup(Tree storage _self, address _key) private {
        address cursor;
        while (_key != _self.root && _self.nodes[_self.nodes[_key].parent].red) {
            address keyParent = _self.nodes[_key].parent;
            if (keyParent == _self.nodes[_self.nodes[keyParent].parent].leftChild) {
                cursor = _self.nodes[_self.nodes[keyParent].parent].rightChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[keyParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    _key = _self.nodes[keyParent].parent;
                } else {
                    if (_key == _self.nodes[keyParent].rightChild) {
                        _key = keyParent;
                        rotateLeft(_self, _key);
                    }
                    keyParent = _self.nodes[_key].parent;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    rotateRight(_self, _self.nodes[keyParent].parent);
                }
            } else {
                cursor = _self.nodes[_self.nodes[keyParent].parent].leftChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[keyParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    _key = _self.nodes[keyParent].parent;
                } else {
                    if (_key == _self.nodes[keyParent].leftChild) {
                        _key = keyParent;
                        rotateRight(_self, _key);
                    }
                    keyParent = _self.nodes[_key].parent;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    rotateLeft(_self, _self.nodes[keyParent].parent);
                }
            }
        }
        _self.nodes[_self.root].red = false;
    }

    /** @dev Replace the parent of A by B's parent.
     *  @param _self The tree to work with.
     *  @param _a The node that will get the new parents.
     *  @param _b The node that gives its parent.
     */
    function replaceParent(
        Tree storage _self,
        address _a,
        address _b
    ) private {
        address bParent = _self.nodes[_b].parent;
        _self.nodes[_a].parent = bParent;
        if (bParent == address(0)) {
            _self.root = _a;
        } else {
            if (_b == _self.nodes[bParent].leftChild) {
                _self.nodes[bParent].leftChild = _a;
            } else {
                _self.nodes[bParent].rightChild = _a;
            }
        }
    }

    /** @dev Makes sure there is no violation of the tree properties after removal.
     *  @param _self The tree to check and correct if needed.
     *  @param _key The address requested in the function remove.
     */
    function removeFixup(Tree storage _self, address _key) private {
        address cursor;
        while (_key != _self.root && !_self.nodes[_key].red) {
            address keyParent = _self.nodes[_key].parent;
            if (_key == _self.nodes[keyParent].leftChild) {
                cursor = _self.nodes[keyParent].rightChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[keyParent].red = true;
                    rotateLeft(_self, keyParent);
                    cursor = _self.nodes[keyParent].rightChild;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].leftChild].red &&
                    !_self.nodes[_self.nodes[cursor].rightChild].red
                ) {
                    _self.nodes[cursor].red = true;
                    _key = keyParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].rightChild].red) {
                        _self.nodes[_self.nodes[cursor].leftChild].red = false;
                        _self.nodes[cursor].red = true;
                        rotateRight(_self, cursor);
                        cursor = _self.nodes[keyParent].rightChild;
                    }
                    _self.nodes[cursor].red = _self.nodes[keyParent].red;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[cursor].rightChild].red = false;
                    rotateLeft(_self, keyParent);
                    _key = _self.root;
                }
            } else {
                cursor = _self.nodes[keyParent].leftChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[keyParent].red = true;
                    rotateRight(_self, keyParent);
                    cursor = _self.nodes[keyParent].leftChild;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].rightChild].red &&
                    !_self.nodes[_self.nodes[cursor].leftChild].red
                ) {
                    _self.nodes[cursor].red = true;
                    _key = keyParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].leftChild].red) {
                        _self.nodes[_self.nodes[cursor].rightChild].red = false;
                        _self.nodes[cursor].red = true;
                        rotateLeft(_self, cursor);
                        cursor = _self.nodes[keyParent].leftChild;
                    }
                    _self.nodes[cursor].red = _self.nodes[keyParent].red;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[cursor].leftChild].red = false;
                    rotateRight(_self, keyParent);
                    _key = _self.root;
                }
            }
        }
        _self.nodes[_key].red = false;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

interface ICErc20 {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256); // The user's underlying balance, representing their assets in the protocol, is equal to the user's cToken balance multiplied by the Exchange Rate.

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function underlying() external view returns (address);
}

interface ICEth {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface IComptroller {
    function liquidationIncentiveMantissa() external returns (uint256);

    function closeFactorMantissa() external returns (uint256);

    function oracle() external returns (address);

    function markets(address)
        external
        returns (
            bool,
            uint256,
            bool
        );

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address,
        address,
        uint256,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function checkMembership(address, address) external view returns (bool);
}

interface IInterestRateModel {
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICToken {
    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

interface IMarketsManagerForCompound {
    function isCreated(address _marketAddress) external returns (bool);

    function p2pBPY(address _marketAddress) external returns (uint256);

    function collateralFactor(address _marketAddress) external returns (uint256);

    function liquidationIncentive(address _marketAddress) external returns (uint256);

    function p2pUnitExchangeRate(address _marketAddress) external returns (uint256);

    function lastUpdateBlockNumber(address _marketAddress) external returns (uint256);

    function threshold(address _marketAddress) external returns (uint256);

    function updateP2pUnitExchangeRate(address _marketAddress) external returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

interface IUpdatePositions {
    function updateBorrowerList(address _cTokenAddress, address _account) external;

    function updateSupplierList(address _cTokenAddress, address _account) external;
}