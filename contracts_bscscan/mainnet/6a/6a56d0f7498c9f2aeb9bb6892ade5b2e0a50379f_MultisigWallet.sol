/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: No License (None)
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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {

    struct AddressSet {
        // Storage of set values
        address[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (address => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
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
    function remove(AddressSet storage set, address value) internal returns (bool) {
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

            address lastvalue = set._values[lastIndex];

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
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns 1-based index of value in the set. O(1).
     */
    function indexOf(AddressSet storage set, address value) internal view returns (uint256) {
        return set._indexes[value];
    }


    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
}

contract MultisigWallet {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct Ballot {
        uint128 votes;      // bitmap of unique votes (max 127 votes)
        uint64 expire;      // time when ballot expire
        uint8 yea;          // number of votes `Yea`
    }

    EnumerableSet.AddressSet owners; // founders may transfer contract's ownership
    uint256 public ownersSetCounter;   // each time when change owners increase the counter
    uint256 public expirePeriod = 3 days;
    mapping(bytes32 => Ballot) public ballots;
 
    event SetOwner(address owner, bool isEnable);
    event CreateBallot(bytes32 ballotHash, uint256 expired);
    event Execute(bytes32 ballotHash, address to, uint256 value, bytes data);


    modifier onlyThis() {
        require(address(this) == msg.sender, "Only multisig allowed");
        _;
    }
    
    constructor (address[] memory _owners) {
        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Zero address");
            owners.add(_owners[i]);
        }
    }

    // get number of owners
    function getOwnersNumber() external view returns(uint256) {
        return owners.length();
    }

    // returns list of owners addresses
    function getOwners() external view returns(address[] memory) {
        return owners._values;
    }

    // add owner
    function addOwner(address owner) external onlyThis{
        require(owner != address(0), "Zero address");
        require(owners.length() < 127, "Too many owners");
        require(owners.add(owner), "Owner already added");
        ownersSetCounter++; // change owners set
        emit SetOwner(owner, true);
    }

    // remove owner
    function removeOwner(address owner) external onlyThis{
        require(owners.length() > 1, "Remove all owners is not allowed");
        require(owners.remove(owner), "Owner does not exist");
        ownersSetCounter++; // change owners set
        emit SetOwner(owner, false);
    }
    
    function setExpirePeriod(uint256 period) external onlyThis {
        require(period >= 1 days, "Too short period");  // avoid deadlock in case of set too short period
        expirePeriod = period;
    }

    function vote(address to, uint256 value, bytes calldata data) external {
        uint256 index = owners.indexOf(msg.sender);
        require(index != 0, "Only owner");
        bytes32 ballotHash = keccak256(abi.encodePacked(to, value, data, ownersSetCounter));
        Ballot memory b = ballots[ballotHash];
        if (b.expire == 0 || b.expire < uint64(block.timestamp)) { // if no ballot or ballot expired - create new ballot
            b.expire = uint64(block.timestamp + expirePeriod);
            b.votes = 0;
            b.yea = 0;
            emit CreateBallot(ballotHash, b.expire);
        }
        uint256 mask = 1 << index;
        if (b.votes & mask == 0) {  // this owner don't vote yet.
            b.votes = uint128(b.votes | mask); // record owner's vote
            b.yea += 1; // increase total votes "Yea"
        }

        if (b.yea >= owners.length() / 2 + 1) {   // vote "Yea" > 50% of owners
            delete ballots[ballotHash];
            execute(to, value, data);
            emit Execute(ballotHash, to, value, data);
        } else {
            // update ballot
            ballots[ballotHash] = b;
        }
    }

    function execute(address to, uint256 value, bytes memory data) internal {
        (bool success,) = to.call{value: value}(data);
        require(success, "Execute error");
    }
}