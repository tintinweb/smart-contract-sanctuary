/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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

contract MultiSignature {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Activate(address indexed sender, bytes32 indexed id);
    event Execute(address indexed sender, bytes32 indexed id);
    event Sign(address indexed sender, bytes32 indexed id);
    event Cancel(address indexed sender, bytes32 indexed id);
    event AddedAdmin(address indexed sender, address indexed account);
    event RemovedAdmin(address indexed sender, address indexed account);
    event SetThreshold(address indexed sender, uint256 newThreshold);

    struct Proposal {
        address author;
        address code;
        bytes data;
        bool pending;
        mapping(address => uint256) signers;
    }

    mapping(bytes32 => Proposal) public proposals;
    EnumerableSet.AddressSet private _accounts;
    uint256 public threshold;

    constructor(uint256 newThreshold, address[] memory newAccounts) public {
        uint256 count = newAccounts.length;
        require(count >= 1, "invalid-accounts-length");
        require(newThreshold >= 1 && newThreshold <= count, "invalid-threshold");
        threshold = newThreshold;
        for (uint256 i = 0; i < count; ++i)
            require(_accounts.add(newAccounts[i]), "account-duplication");
    }

    modifier onlyMultiSignature() {
        require(msg.sender == address(this), "multi-signature-permission-denied");
        _;
    }

    modifier onlyAdmin() {
        require(_accounts.contains(msg.sender), "admin-permission-denied");
        _;
    }

    function activate(address code, bytes memory data) public onlyAdmin {
        require(code != address(0), "activate-with-invalid-code");
        require(data.length >= 4, "activate-with-invalid-data");
        bytes32 id = getHash(code, data);
        if (proposals[id].pending) _clean(id);
        proposals[id].author = msg.sender;
        proposals[id].code = code;
        proposals[id].data = data;
        proposals[id].pending = true;
        emit Activate(msg.sender, id);
    }

    function execute(bytes32 id) public returns (bool success, bytes memory result)
    {
        require(proposals[id].pending, "proposal-not-activated");
        require(getWeight(id) >= threshold, "insufficient-weight");
        (success, result) = proposals[id].code.call(proposals[id].data);
        require(success, "proposal-execute-failed");
        _clean(id);
        emit Execute(msg.sender, id);
    }

    function sign(bytes32 id) public onlyAdmin {
        require(proposals[id].pending, "proposal-not-activated");
        require(proposals[id].signers[msg.sender] == 0, "signature-duplication");
        proposals[id].signers[msg.sender] = 1;
        emit Sign(msg.sender, id);
    }

    function cancel(bytes32 id) public {
        require(proposals[id].author == msg.sender, "author-permission-denied");
        _clean(id);
        emit Cancel(msg.sender, id);
    }

    function addAdmin(address account) public onlyMultiSignature {
        require(_accounts.add(account), "account-duplication");
        emit AddedAdmin(msg.sender, account);
    }

    function removeAdmin(address account) public onlyMultiSignature {
        require(_accounts.remove(account), "account-not-exist");
        require(_accounts.length() >= threshold, "account-must-morethan-threshold");
        emit RemovedAdmin(msg.sender, account);
    }

    function setThreshold(uint256 newThreshold) public onlyMultiSignature {
        require(newThreshold >= 1 && newThreshold <= _accounts.length(), "invalid-threshold");
        threshold = newThreshold;
        emit SetThreshold(msg.sender, newThreshold);
    }

    function getWeight(bytes32 id) public view returns (uint256) {
        uint256 weights = 0;
        for (uint256 i = 0; i < _accounts.length(); ++i)
            weights += proposals[id].signers[_accounts.at(i)];
        return weights;
    }

    function getHash(address code, bytes memory data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(code, data));
    }

    function getAdmins() public view returns (address[] memory) {
        address[] memory admines = new address[](_accounts.length());
        for (uint256 i = 0; i < _accounts.length(); ++i)
            admines[i] = _accounts.at(i);
        return admines;
    }

    function isAdmin(address signer) public view returns (bool) {
        return _accounts.contains(signer);
    }

    function _clean(bytes32 id) internal {
        for (uint256 i = 0; i < _accounts.length(); ++i)
            proposals[id].signers[_accounts.at(i)] = 0;
        delete proposals[id];
    }
}