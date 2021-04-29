/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.8.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
  /**
   * return if the forwarder is trusted to forward relayed transactions to us.
   * the forwarder is required to verify the sender's signature, and verify
   * the call is not a replay.
   */
  function isTrustedForwarder(address forwarder) public view virtual returns (bool);

  /**
   * return the sender of this call.
   * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
   * of the msg.data.
   * otherwise, return `msg.sender`
   * should be used in the contract anywhere instead of msg.sender
   */
  function _msgSender() internal view virtual returns (address);

  /**
   * return the msg.data of this call.
   * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
   * of the msg.data - so this method will strip those 20 bytes off.
   * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
   * should be used in the contract instead of msg.data, where this difference matters.
   */
  function _msgData() internal view virtual returns (bytes memory);

  function versionRecipient() external view virtual returns (string memory);
}



/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
  /*
   * Forwarder singleton we accept calls from
   */
  address public trustedForwarder;

  function isTrustedForwarder(address forwarder) public view override returns (bool) {
    return forwarder == trustedForwarder;
  }

  /**
   * return the sender of this call.
   * if the call came through our trusted forwarder, return the original sender.
   * otherwise, return `msg.sender`.
   * should be used in the contract anywhere instead of msg.sender
   */
  function _msgSender() internal view virtual override returns (address ret) {
    if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
      // At this point we know that the sender is a trusted forwarder,
      // so we trust that the last bytes of msg.data are the verified sender address.
      // extract sender address from the end of msg.data
      assembly {
        ret := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return msg.sender;
    }
  }

  /**
   * return the msg.data of this call.
   * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
   * of the msg.data - so this method will strip those 20 bytes off.
   * otherwise, return `msg.data`
   * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
   * signing or hashing the
   */
  function _msgData() internal view virtual override returns (bytes memory ret) {
    if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
      return msg.data[0:msg.data.length - 20];
    } else {
      return msg.data;
    }
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


contract Registry is BaseRelayRecipient {
  using EnumerableSet for EnumerableSet.Bytes32Set;
  string public override versionRecipient = "2.0.0";

  struct UrlEntry {
    string url;
    bool initialized;
  }

  // TODO: Can probably save gas costs by reducing indexes and making anonymous events if needed.
  event RegisterName(address indexed owner, bytes32 indexed username);

  event ModifyName(bytes32 indexed username);

  event TransferName(address indexed from, address indexed to, bytes32 indexed username);

  // Enumeration of all registered usernames in our contract.
  EnumerableSet.Bytes32Set private usernames;

  /// @notice Mapping of byte32 encoded usernames to urls that they own.
  mapping(bytes32 => UrlEntry) public usernameToUrl;

  /// @notice Mapping of addresses to registered usernames that they own.
  mapping(address => bytes32) public addressToUsername;

  /// @notice Deploy with the TrustedForwarded for your Network
  /// https://docs.opengsn.org/networks.html
  constructor(address _forwarder) {
    trustedForwarder = _forwarder;
  }

  /// @notice Find the profile URL for a username
  /// @dev Returns empty string "" for a username that has not been registered.
  /// @param username the username string (e.g. alice) encoded as byte32.
  function lookupUrl(bytes32 username) public view returns (string memory) {
    return usernameToUrl[username].url;
  }

  /// @notice Returns the number of usernames currently registered in the contract.
  function usernamesLength() public view returns (uint256) {
    return usernames.length();
  }

  /// @notice Returns a username from the list of registered usernames from an index.
  /// @dev indexes are not guaranteed to be consistent over blocks, and range from 0 to usernamesLength().
  /// @param idx the index for the username.
  function usernamesAtIndex(uint8 idx) public view returns (bytes32) {
    return usernames.at(idx);
  }

  /// @notice Register a new username.
  /// @param username the username string (e.g. alice) encoded as byte32.
  /// @param url the url string that points to the user's profile.
  function register(bytes32 username, string memory url) public {
    require(username != 0, "Username cannot be empty");
    require(_isAllowedAsciiString(username) == true, "Username must be lowercase alphanumeric");
    require(addressToUsername[_msgSender()] == 0, "Sender already registered a username");
    require(usernameToUrl[username].initialized == false, "This username was already registered");

    addressToUsername[_msgSender()] = username;
    usernameToUrl[username] = UrlEntry({url: url, initialized: true});
    usernames.add(username);
    emit RegisterName(_msgSender(), username);
  }

  /// @notice Modify an existing username.
  /// @param url the updated url string that points to the user's profile.
  function modify(string memory url) public {
    bytes32 usernameFromAddress = addressToUsername[_msgSender()];
    require(usernameFromAddress != 0, "Sender does not own any username");
    usernameToUrl[usernameFromAddress] = UrlEntry({url: url, initialized: true});
    emit ModifyName(usernameFromAddress);
  }

  /// @notice Transfer ownership of your username to another address that does not currently own a username.
  /// @param to the Ethereum address that ownership should be transferred to.
  function transfer(address to) public {
    bytes32 username = addressToUsername[_msgSender()];
    require(username != 0, "Sender does not own any username");
    require(addressToUsername[to] == 0, "Receiver already owns a username");

    addressToUsername[_msgSender()] = 0;
    addressToUsername[to] = username;
    emit TransferName(_msgSender(), to, username);
  }

  /// @notice Checks if a string contains valid username ASCII characters [0-1], [a-z] and _.
  /// @param str the string to be checked.
  /// @return true if the string contains only valid characters, false otherwise.
  function _isAllowedAsciiString(bytes32 str) internal pure returns (bool) {
    for (uint256 i = 0; i < str.length; i++) {
      uint8 charInt = uint8(str[i]);
      if ((charInt >= 1 && charInt <= 47) || (charInt >= 58 && charInt <= 94) || charInt == 96 || charInt >= 123) {
        return false;
      }
    }
    return true;
  }
}