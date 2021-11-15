// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

// SPDX-License-Identifier: MIT
pragma solidity >0.8.5 <0.9.0;

import "openzeppelin-solidity/contracts/utils/math/Math.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";

contract Committee {
    function recoverSigner(
        bytes32 data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual pure returns (address) {
        return ecrecover(data, v, r, s);
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MIN_COMMITTEE_SIZE = 8;
    uint256 public constant MAX_COMMITTEE_SIZE = 50;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Action {
        bool addition;
        address address_;
    }

    struct NodeProps {
        bool applied;
        bool verified;
        bytes32 parentHash;
        Action action;
    }

    struct Node {
        uint256 version;
        NodeProps props;
        EnumerableSet.AddressSet signers;
        mapping(address => Signature) signatures;
    }

    bytes32 public immutable rootHash;

    bytes32 private _headHash;
    bytes32[] private _hashes;
    EnumerableSet.AddressSet private _members;
    mapping(bytes32 => Node) private _nodes;

    function committeeSize() public view returns (uint256) {
        return _members.length();
    }

    function requiredSignaturesCount() public virtual view returns (uint256) {
        return (_members.length() * 2) / 3 + 1;
    }

    function version() public view returns (uint256) {
        return _hashes.length - 1;
    }

    function headHash() public view returns (bytes32) {
        return _headHash;
    }

    function snapshot() public view returns (bytes32 root, address[] memory members) {
        return (_headHash, getCommitteeMembers(0, type(uint256).max));
    }

    function isCommitteeMember(address address_) public view returns (bool) {
        return _members.contains(address_);
    }

    function getNodeSignersCount(bytes32 nodeHash) public view returns (uint256) {
        return _nodes[nodeHash].signers.length();
    }

    function getCommitteeMembers(uint256 fromIndex, uint256 limit) public view returns (address[] memory) {
        uint256 committeeSize_ = committeeSize();
        if (fromIndex >= committeeSize_) return new address[](0);
        uint256 length = Math.min(limit, committeeSize_ - fromIndex);
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) result[i] = _members.at(fromIndex + i);
        return result;
    }

    function getNodeSigners(
        bytes32 nodeHash,
        uint256 fromIndex,
        uint256 limit
    ) public view returns (address[] memory) {
        Node storage node_ = _nodes[nodeHash];
        uint256 signersCount_ = node_.signers.length();
        if (fromIndex >= signersCount_) return new address[](0);
        uint256 length = Math.min(limit, signersCount_ - fromIndex);
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) result[i] = node_.signers.at(fromIndex + i);
        return result;
    }

    function getAppliedNodesHashes(uint256 fromVersion, uint256 limit) public view returns (bytes32[] memory) {
        uint256 hashesCount = _hashes.length;
        if (fromVersion >= hashesCount) return new bytes32[](0);
        uint256 length = Math.min(limit, hashesCount - fromVersion);
        bytes32[] memory result = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) result[i] = _hashes[fromVersion + i];
        return result;
    }

    function getAppliedNodes(uint256 fromVersion, uint256 limit) public view returns (NodeProps[] memory) {
        bytes32[] memory hashes = getAppliedNodesHashes(fromVersion, limit);
        uint256 length = hashes.length;
        NodeProps[] memory result = new NodeProps[](length);
        for (uint256 i = 0; i < length; i++) result[i] = _nodes[hashes[i]].props;
        return result;
    }

    function getNode(bytes32 hash_) public view returns (uint256 version_, NodeProps memory props) {
        Node storage node_ = _nodes[hash_];
        return (node_.version, node_.props);
    }

    function getNodeSignatures(
        bytes32 nodeHash,
        uint256 fromIndex,
        uint256 limit
    ) public view returns (Signature[] memory signatures_, address[] memory signers_) {
        Node storage node_ = _nodes[nodeHash];
        uint256 signersCount_ = node_.signers.length();
        if (fromIndex >= signersCount_) return (signatures_, signers_);
        uint256 length = Math.min(limit, signersCount_ - fromIndex);
        signatures_ = new Signature[](length);
        signers_ = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address signer = node_.signers.at(fromIndex + i);
            signatures_[i] = node_.signatures[signer];
            signers_[i] = signer;
        }
    }

    event MemberAdded(address indexed address_);
    event MemberRemoved(address indexed address_);
    event NodeSigned(bytes32 indexed nodeHash, address indexed signer, bytes32 r, bytes32 s, uint8 v);
    event NodeVerified(bytes32 indexed nodeHash, bytes32 indexed parentHash, address indexed address_, bool addition);
    event NodeApplied(bytes32 indexed hash_);
    event SignerRemoved(bytes32 indexed nodeHash, address indexed signer);

    constructor(address[] memory members, bytes32 rootHash_) {
        rootHash = rootHash_;
        _headHash = rootHash_;
        _hashes.push(rootHash_);
        uint256 membersCount = members.length;
        require(membersCount >= MIN_COMMITTEE_SIZE, "Members count lt required");
        require(membersCount <= MAX_COMMITTEE_SIZE, "Members count gt allowed");
        for (uint256 i = 0; i < membersCount; i++) _addMember(members[i]);
    }

    function sign(bytes32 hash_, Signature[] memory signatures_) public returns (bool success) {
        Node storage node_ = _nodes[hash_];
        uint256 signaturesCount = signatures_.length;
        for (uint256 i = 0; i < signaturesCount; i++) {
            Signature memory signature = signatures_[i];
            address signer = recoverSigner(_getPrefixedHash(hash_), signature.v, signature.r, signature.s);
            node_.signers.add(signer);
            node_.signatures[signer] = signature;
            emit NodeSigned(hash_, signer, signature.r, signature.s, signature.v);
        }
        return true;
    }

    function verify(bytes32 parentHash, Action memory action) public returns (bool success) {
        _verify(parentHash, action);
        return true;
    }

    function removeExcessSignatures(bytes32 nodeHash_, address[] memory signers) public returns (bool success) {
        Node storage node_ = _nodes[nodeHash_];
        require(node_.props.verified, "Node not verified");
        require(node_.props.parentHash == _headHash, "Not incomming node");
        uint256 signersCount = signers.length;
        for (uint256 i = 0; i < signersCount; i++) {
            address signer = signers[i];
            require(!isCommitteeMember(signer), "Signer is committee member");
            node_.signers.remove(signer);
            emit SignerRemoved(nodeHash_, signer);
        }
        return true;
    }

    function commit(Action memory action) public returns (bool success) {
        bytes32 newHeadHash;
        Node storage node_;
        (newHeadHash, node_) = _verify(_headHash, action);
        uint256 validSignaturesCount = 0;
        for (uint256 i = 0; i < node_.signers.length(); i++) {
            address signer = node_.signers.at(i);
            if (_members.contains(signer)) validSignaturesCount += 1;
        }
        require(validSignaturesCount >= requiredSignaturesCount(), "Not enough signatures");
        if (action.addition) {
            require(!_members.contains(action.address_), "Already committee member");
            require(_members.length() < MAX_COMMITTEE_SIZE, "Members count gt allowed");
            _addMember(action.address_);
        } else {
            require(_members.contains(action.address_), "Not committee member");
            require(_members.length() > MIN_COMMITTEE_SIZE, "Members count lt required");
            _members.remove(action.address_);
            emit MemberRemoved(action.address_);
        }
        _hashes.push(newHeadHash);
        _headHash = newHeadHash;
        node_.props.applied = true;
        emit NodeApplied(newHeadHash);
        return true;
    }

    function _getPrefixedHash(bytes32 hash_) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hash_));
    }

    function _addMember(address address_) private {
        _members.add(address_);
        emit MemberAdded(address_);
    }

    function _verify(bytes32 parentHash, Action memory action) private returns (bytes32 hash_, Node storage node_) {
        hash_ = keccak256(abi.encodePacked(parentHash, action.addition, action.address_));
        node_ = _nodes[hash_];
        Node storage parent = _nodes[parentHash];
        require(parentHash == rootHash || parent.props.verified, "Parent node not verified");
        node_.version = parent.version + 1;
        node_.props.parentHash = parentHash;
        node_.props.action = action;
        node_.props.verified = true;
        emit NodeVerified(hash_, parentHash, action.address_, action.addition);
    }
}

