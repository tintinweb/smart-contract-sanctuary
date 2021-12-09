/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;


// 
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

contract Msign {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Activate(address indexed sender, bytes32 id);
    event Execute(address indexed sender, bytes32 id);
    event Sign(address indexed sender, bytes32 id);
    event Enable(address indexed sender, address indexed account);
    event Disable(address indexed sender, address indexed account);
    event Assign(address indexed sender, uint256 oldthreshold, uint256 newthreshold);

    struct proposal_t {
        address code;
        bytes   data;
        uint256 done;
        mapping(address => uint256) signers;
    }

    mapping(bytes32 => proposal_t) public proposals;
    EnumerableSet.AddressSet private _signers;
    uint256 public threshold;

    constructor(uint256 _threshold, address[] memory _accounts) public {
        uint256 _length = _accounts.length;
        require(_length >= 1, "Msign.constructor.EID00085");
        require(_threshold >= 1 && _threshold <= _length, "Msign.constructor.EID00089");
        threshold = _threshold;
        for (uint256 i = 0; i < _length; ++i) {
            require(_signers.add(_accounts[i]), "Msign.constructor.EID00015");
        }
    }

    modifier auth() {
        require(msg.sender == address(this), "Msign.auth.EID00001");
        _;
    }
    modifier signerauth() {
        require(_signers.contains(msg.sender), "Msign.ssignauth.EID00082");
        _;
    }
    modifier msignauth(bytes32 id) {
        require(mulsignweight(id) >= threshold, "Msign.mulsignauth.EID00083");
        _;
    }

    function gethash(address code, bytes memory data)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(code, data));
    }

    function activate(address code, bytes memory data)
        public
        signerauth
        returns (bytes32)
    {
        require(code != address(0), "Msign.activate.code.EID00090");
        require(data.length >= 4, "Msign.activate.data.EID00090");
        bytes32 _hash = gethash(code, data);
        proposals[_hash].code = code;
        proposals[_hash].data = data;
        emit Activate(msg.sender, _hash);
        return _hash;
    }

    function execute(bytes32 id)
        public
        msignauth(id)
        returns (bool success, bytes memory result)
    {
        require(proposals[id].done == 0, "Msign.execute.EID00022");
        proposals[id].done = 1;
        (success, result) = proposals[id].code.call(proposals[id].data);
        require(success, "Msign.execute.EID00020");
        emit Execute(msg.sender, id);
    }

    function sign(bytes32 id) public signerauth {
        require(proposals[id].signers[msg.sender] == 0, "Msign.sign.EID00084");
        proposals[id].signers[msg.sender] = 1;
        emit Sign(msg.sender, id);
    }

    function enable(address account) public auth {
        require(_signers.add(account), "Msign.enable.EID00015");
        emit Enable(msg.sender, account);
    }

    function disable(address account) public auth {
        require(_signers.remove(account), "Msign.disable.EID00016");
        require(_signers.length() >= 1, "Msign.disable.EID00085");
        emit Disable(msg.sender, account);
    }

    function assign(uint256 _threshold) public auth {
        require(_threshold >= 1 && _threshold <= _signers.length(), "Msign.assign.EID00089");
        emit Assign(msg.sender, threshold, _threshold);
        threshold = _threshold;  
    }

    function mulsignweight(bytes32 id) public view returns (uint256) {
        uint256 _weights = 0;
        for (uint256 i = 0; i < _signers.length(); ++i) {
            _weights += proposals[id].signers[_signers.at(i)];
        }
        return _weights;
    }

    function signers() public view returns (address[] memory) {
        address[] memory values = new address[](_signers.length());
        for (uint256 i = 0; i < _signers.length(); ++i) {
            values[i] = _signers.at(i);
        }
        return values;
    }

    function isSigner(address signer) public view returns (bool) {
        return _signers.contains(signer);
    }
}