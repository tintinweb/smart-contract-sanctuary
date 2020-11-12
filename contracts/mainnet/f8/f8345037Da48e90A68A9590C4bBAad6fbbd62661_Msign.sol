pragma solidity 0.6.4;

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

    struct proposal_t {
        address code;
        bytes   data;
        uint256 done;
        mapping(address => uint256) signers;
    }

    mapping(bytes32 => proposal_t) public proposals;
    uint256 private _weight;
    EnumerableSet.AddressSet private _signers;

    constructor(
        uint256 _length,
        address[] memory _accounts
    ) public {
        require(_length >= 1, "Msign.Length not valid");
        require(_length == _accounts.length, "Msign.Args fault");
        for (uint256 i = 0; i < _length; ++i) {
            require(_signers.add(_accounts[i]), "Msign.Duplicate signer");
        }
    }

    //single sign auth
    modifier ssignauth() {
        require(_signers.contains(msg.sender), "Msign.Invalid signer");
        _;
    }

    //multi sign auth
    modifier msignauth(bytes32 id) {
        require(mulsignweight(id) >= threshold(), "Msign.Threshold unreached");
        _;
    }

    modifier auth() {
        require(msg.sender == address(this));
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
        ssignauth
        returns (bytes32)
    {
        require(code != address(0), "Msign.Invalid args");
        require(data.length >= 4, "Msign.Invalid args");
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
        require(proposals[id].done == 0, "Msign.Proposal has been executed");
        proposals[id].done = 1;
        (success, result) = proposals[id].code.call(proposals[id].data);
        require(success, "Msign.Execute fail");
        emit Execute(msg.sender, id);
    }

    function sign(bytes32 id) public ssignauth {
        require(proposals[id].signers[msg.sender] == 0, "Msign.Duplicate sign");
        proposals[id].signers[msg.sender] = 1;
        emit Sign(msg.sender, id);
    }

    function enable(address account) public auth {
        require(_signers.add(account), "Msign.Duplicate signer");
        emit Enable(msg.sender, account);
    }

    function disable(address account) public auth {
        require(_signers.remove(account), "Msign.Disable nonexist");
        require(_signers.length() >= 1, "Msign.Invalid set");
        emit Disable(msg.sender, account);
    }

    function mulsignweight(bytes32 id) public view returns (uint256) {
        uint256 _weights = 0;
        for (uint256 i = 0; i < _signers.length(); ++i) {
            _weights += proposals[id].signers[_signers.at(i)];
        }
        return _weights;
    }

    function threshold() public view returns (uint256) {
        return (_signers.length() / 2) + 1;
    }

    function signers() public view returns (address[] memory) {
        address[] memory values = new address[](_signers.length());
        for (uint256 i = 0; i < _signers.length(); ++i) {
            values[i] = _signers.at(i);
        }
        return values;
    }

    function signable(address signer) public view returns (bool) {
        return _signers.contains(signer);
    }
}