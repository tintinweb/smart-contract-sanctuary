pragma solidity ^0.4.23;

library StringUtils {

  /**
   * @notice Returns true if and only if source string
   *      contains the specified query substring.
   * @param source the string to look in.
   * @param query the substring to search for.
   * @return true if this string contains `query`, false otherwise
   */
  function contains(string source, string query) internal pure returns (bool) {
    // delegate call to `indexOf` and verify the result is not -1
    return indexOf(source, query) != -1;
  }

  /**
   * @notice Returns the index within source ASCII string of the
   *      first occurrence of the query substring.
   *      If source string doesn&#39;t contain query substring, then -1 is returned.
   * @param source the string to look in.
   * @param query the substring to search for.
   * @return the index of the first occurrence of the specified substring,
   *      or -1 if there is no such occurrence.
   */
  function indexOf(string source, string query) internal pure returns (int256) {
    // delegate call to `indexOf` with a zero `fromIndex`
    return indexOf(source, query, 0);
  }

  /**
   * @notice Returns the index within source ASCII string of the
   *      first occurrence of the query substring, starting at the specified index.
   *      If source string doesn&#39;t contain query substring, then -1 is returned.
   * @param source the string to look in.
   * @param query the substring to search for.
   * @param fromIndex the index from which to start the search.
   * @return the index of the first occurrence of the specified substring,
   *      or -1 if there is no such occurrence.
   */
  function indexOf(string source, string query, uint256 fromIndex) internal pure returns (int256) {
    // convert source into bytes, that&#39;s why only ASCII is supported
    bytes memory sourceBytes = bytes(source);

    // convert query into bytes, that&#39;s why only ASCII is supported
    bytes memory queryBytes = bytes(query);

    // empty string exists in any string at index zero
    if(queryBytes.length == 0) {
      // index zero
      return 0;
    }

    // ensure query string is not longer than source string
    if(sourceBytes.length < queryBytes.length) {
      // if query is longer, it cannot be a substring
      return -1;
    }

    // search for a substring match, index `i` points to position in `source`
    for(uint256 i = fromIndex; i < sourceBytes.length - queryBytes.length; i++) {
      // index `j` points to position in `query`
      uint256 j = 0;
      // search for substring at position `i`
      while(j < queryBytes.length && queryBytes[j] == sourceBytes[j + i]) {
        // increment index `j`
        j++;
      }
      // check for full substring match
      if(j == queryBytes.length) {
        // substring found, return an index `i` as a result
        return int256(i);
      }
    }

    // substring match not found, return -1
    return -1;
  }

}

/**
 * @dev Access control module provides an API to check
 *      if specific operation is permitted globally and
 *      if particular user&#39;s has a permission to execute it
 */
contract AccessControl {
  /// @notice Role manager is responsible for assigning the roles
  /// @dev Role ROLE_ROLE_MANAGER allows executing addOperator/removeOperator
  uint256 private constant ROLE_ROLE_MANAGER = 0x10000000;

  /// @notice Feature manager is responsible for enabling/disabling
  ///      global features of the smart contract
  /// @dev Role ROLE_FEATURE_MANAGER allows enabling/disabling global features
  uint256 private constant ROLE_FEATURE_MANAGER = 0x20000000;

  /// @dev Bitmask representing all the possible permissions (super admin role)
  uint256 private constant FULL_PRIVILEGES_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /// @dev A bitmask of globally enabled features
  uint256 public features;

  /// @notice Privileged addresses with defined roles/permissions
  /// @notice In the context of ERC20/ERC721 tokens these can be permissions to
  ///      allow minting tokens, transferring on behalf and so on
  /// @dev Maps an address to the permissions bitmask (role), where each bit
  ///      represents a permission
  /// @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
  ///      represents all possible permissions
  mapping(address => uint256) public userRoles;

  /// @dev Fired in updateFeatures()
  event FeaturesUpdated(address indexed _by, uint256 _requested, uint256 _actual);

  /// @dev Fired in addOperator(), removeOperator(), addRole(), removeRole()
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _role);

  /**
   * @dev Creates an access controlled instance
   */
  constructor() public {
    // contract creator has full privileges
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

  /**
   * @dev Updates set of the globally enabled features (`f`),
   *      taking into account sender&#39;s permissions.
   * @dev Requires sender to have `ROLE_FEATURE_MANAGER` permission.
   * @param mask bitmask representing a set of features to enable/disable
   */
  function updateFeatures(uint256 mask) public {
    // call sender nicely - caller
    address caller = msg.sender;
    // read caller&#39;s permissions
    uint256 p = userRoles[caller];

    // caller should have a permission to update global features
    require(__hasRole(p, ROLE_FEATURE_MANAGER));

    // taking into account caller&#39;s permissions,
    // 1) enable features requested
    features |= p & mask;
    // 2) disable features requested
    features &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ mask));

    // fire an event
    emit FeaturesUpdated(caller, mask, features);
  }

  /**
   * @dev Adds a new `operator` - an address which has
   *      some extended privileges over the smart contract,
   *      for example token minting, transferring on behalf, etc.
   * @dev Newly added `operator` cannot have any permissions which
   *      transaction sender doesn&#39;t have.
   * @dev Requires transaction sender to have `ROLE_ROLE_MANAGER` permission.
   * @dev Cannot update existing operator. Throws if `operator` already exists.
   * @param operator address of the operator to add
   * @param role bitmask representing a set of permissions which
   *      newly created operator will have
   */
  function addOperator(address operator, uint256 role) public {
    // call sender gracefully - `manager`
    address manager = msg.sender;

    // read manager&#39;s permissions (role)
    uint256 permissions = userRoles[manager];

    // check that `operator` doesn&#39;t exist
    require(userRoles[operator] == 0);

    // manager must have a ROLE_ROLE_MANAGER role
    require(__hasRole(permissions, ROLE_ROLE_MANAGER));

    // recalculate permissions (role) to set:
    // we cannot create an operator more powerful then calling `manager`
    uint256 r = role & permissions;

    // check if we still have some permissions (role) to set
    require(r != 0);

    // create an operator by persisting his permissions (roles) to storage
    userRoles[operator] = r;

    // fire an event
    emit RoleUpdated(manager, operator, userRoles[operator]);
  }

  /**
   * @dev Deletes an existing `operator`.
   * @dev Requires sender to have `ROLE_ROLE_MANAGER` permission.
   * @param operator address of the operator to delete
   */
  function removeOperator(address operator) public {
    // call sender gracefully - `manager`
    address manager = msg.sender;

    // check if an `operator` exists
    require(userRoles[operator] != 0);

    // do not allow transaction sender to remove himself
    // protects from an accidental removal of all the operators
    require(operator != manager);

    // manager must have a ROLE_ROLE_MANAGER role
    // and he must have all the permissions operator has
    require(__hasRole(userRoles[manager], ROLE_ROLE_MANAGER | userRoles[operator]));

    // perform operator deletion
    delete userRoles[operator];

    // fire an event
    emit RoleUpdated(manager, operator, 0);
  }

  /**
   * @dev Updates an existing `operator`, adding a specified role to it.
   * @dev Note that `operator` cannot receive permission which
   *      transaction sender doesn&#39;t have.
   * @dev Requires transaction sender to have `ROLE_ROLE_MANAGER` permission.
   * @dev Cannot create a new operator. Throws if `operator` doesn&#39;t exist.
   * @dev Existing permissions of the `operator` are preserved
   * @param operator address of the operator to update
   * @param role bitmask representing a set of permissions which
   *      `operator` will have
   */
  function addRole(address operator, uint256 role) public {
    // call sender gracefully - `manager`
    address manager = msg.sender;

    // read manager&#39;s permissions (role)
    uint256 permissions = userRoles[manager];

    // check that `operator` exists
    require(userRoles[operator] != 0);

    // manager must have a ROLE_ROLE_MANAGER role
    require(__hasRole(permissions, ROLE_ROLE_MANAGER));

    // recalculate permissions (role) to add:
    // we cannot make an operator more powerful then calling `manager`
    uint256 r = role & permissions;

    // check if we still have some permissions (role) to add
    require(r != 0);

    // update operator&#39;s permissions (roles) in the storage
    userRoles[operator] |= r;

    // fire an event
    emit RoleUpdated(manager, operator, userRoles[operator]);
  }

  /**
   * @dev Updates an existing `operator`, removing a specified role from it.
   * @dev Note that  permissions which transaction sender doesn&#39;t have
   *      cannot be removed.
   * @dev Requires transaction sender to have `ROLE_ROLE_MANAGER` permission.
   * @dev Cannot remove all permissions. Throws on such an attempt.
   * @param operator address of the operator to update
   * @param role bitmask representing a set of permissions which
   *      will be removed from the `operator`
   */
  function removeRole(address operator, uint256 role) public {
    // call sender gracefully - `manager`
    address manager = msg.sender;

    // read manager&#39;s permissions (role)
    uint256 permissions = userRoles[manager];

    // check that we&#39;re not removing all the `operator`s permissions
    // this is not really required and just causes inconveniences is function use
    //require(userRoles[operator] ^ role != 0);

    // manager must have a ROLE_ROLE_MANAGER role
    require(__hasRole(permissions, ROLE_ROLE_MANAGER));

    // recalculate permissions (role) to remove:
    // we cannot revoke permissions which calling `manager` doesn&#39;t have
    uint256 r = role & permissions;

    // check if we still have some permissions (role) to revoke
    require(r != 0);

    // update operator&#39;s permissions (roles) in the storage
    userRoles[operator] &= FULL_PRIVILEGES_MASK ^ r;

    // fire an event
    emit RoleUpdated(manager, operator, userRoles[operator]);
  }

  /// @dev Checks if requested feature is enabled globally on the contract
  function __isFeatureEnabled(uint256 featureRequired) internal constant returns(bool) {
    // delegate call to `__hasRole`
    return __hasRole(features, featureRequired);
  }

  /// @dev Checks if transaction sender `msg.sender` has all the required permissions `roleRequired`
  function __isSenderInRole(uint256 roleRequired) internal constant returns(bool) {
    // read sender&#39;s permissions (role)
    uint256 userRole = userRoles[msg.sender];

    // delegate call to `__hasRole`
    return __hasRole(userRole, roleRequired);
  }

  /// @dev Checks if user role `userRole` contain all the permissions required `roleRequired`
  function __hasRole(uint256 userRole, uint256 roleRequired) internal pure returns(bool) {
    // check the bitmask for the role required and return the result
    return userRole & roleRequired == roleRequired;
  }
}


/**
 * @notice DeedStamp allows to create a proof of existence for a deed document (register)
 * @notice Each proof is attached to its address which allow to query for documents by address
 */
contract DeedStamp is AccessControl {
  /// @dev Using library `StringUtils` for string manipulations
  using StringUtils for string;

  /// @notice Deed registrant is responsible for registering deeds
  /// @dev Role ROLE_DEED_REGISTRANT allows registering deeds within smart contract
  uint32 private constant ROLE_DEED_REGISTRANT = 0x00000001;

  /**
   * @notice Proof of existence mapping
   * @dev A mapping of deed document hash to a timestamp when
   *      the document was added to this mapping
   * @dev Zero value in the mapping indicates
   *      the document&#39;s proof of existence doesn&#39;t exist
   * @dev Non-zero value in the mapping indicates
   *      a unix timestamp when the document was added
   * @dev Unix timestamp – number of seconds that have passed since Jan 1, 1970
   */
  mapping(uint256 => uint256) private documentRegistry;

  /**
   * @notice Property address index mapping
   * @dev A mapping of property address hash to an array of
   *      deed documents associated with this address
   * @dev Each document from the mapping must have a corresponded
   *      unix timestamp in the proof of existence mapping
   * @dev To obtain timestamps of all the deeds for an address
   *      an index can be used together with proof of existence mapping
   */
  mapping(uint256 => string[]) private addressRegistry;

  /**
   * @notice Iterable storage for all property addresses registered
   * @dev Unordered, doesn&#39;t contain duplicates (entries with equal hash)
   * @dev May be used as an entry point to iterate over all the deeds
   *      stored in smart contract:
   *      for propertyAddress in knownPropertyAddresses
   *        for document in addressRegistry[propertyAddress]
   *          unix timestamp is documentRegistry[document]
   */
  string[] public knownPropertyAddresses;

  /// @dev Fired in `registerDeed`
  event DeedRegistered(string propertyAddress, string document);

  /**
   * @notice Creates a proof of existence for a deed document `document`
   * @notice Allows to specify property address `propertyAddress` as a first argument
   * @notice A `document` may not necessarily represent a document itself,
   *      it can also be its metadata or just a hash
   * @dev Creates a mapping between a document and unix timestamp of the current time
   *      (timestamp of the Ethereum transaction which creates that mapping)
   * @dev Additionally stores a mapping between property address and the document
   * @dev Requires sender to have ROLE_DEED_REGISTRANT permission
   * @dev Throws if deed document doesn&#39;t contain specified property address inside
   * @dev Throws if proof of existence for the deed document already exists
   * @param propertyAddress a property address, must be included into the document
   * @param document a deed document to create a proof of existence for
   *      by putting it into the registry
   */
  function registerDeed(string propertyAddress, string document) public {
    // check that the call is made by a deed registrant
    require(__isSenderInRole(ROLE_DEED_REGISTRANT));

    // calculate the hash
    uint256 documentHash = uint256(keccak256(document));

    // ensure document doesn&#39;t exist in the document registry mapping
    require(documentRegistry[documentHash] == 0);

    // ensure the document contains a property address specified
    require(document.contains(propertyAddress));

    // store proof of existence in the registry
    documentRegistry[documentHash] = now;

    // calculate property address hash
    uint256 propertyAddressHash = uint256(keccak256(propertyAddress));

    // if property address is new (doesn&#39;t exist in address index mapping)
    if(addressRegistry[propertyAddressHash].length == 0) {
      // add it to array of know property addresses
      knownPropertyAddresses.push(propertyAddress);
    }

    // store property address in the property address index
    addressRegistry[propertyAddressHash].push(document);

    // emit an event
    emit DeedRegistered(propertyAddress, document);
  }

  /**
   * @notice Proves an existence of the document by checking
   *      if it exists in a proof of existence mapping
   * @param document a deed document to verify existence
   * @return true if and only if document exists
   */
  function verifyDeed(string document) public constant returns (bool) {
    // calculate the hash
    uint256 documentHash = uint256(keccak256(document));

    // verify if proof of existence timestamp is not zero
    return documentRegistry[documentHash] > 0;
  }

  /**
   * @notice Returns a unix timestamp when the proof of existence for a document was created
   * @dev This is a unix timestamp of the document addition to the registry
   * @param document a deed document to get the proof of existence creation date for
   * @return a unix timestamp when the proof of existence was created
   */
  function getDeedTimestamp(string document) public constant returns (uint256) {
    // calculate the hash
    uint256 documentHash = uint256(keccak256(document));

    // lookup the registry
    uint256 timestamp = documentRegistry[documentHash];

    // ensure the document exists
    require(timestamp > 0);

    // return the timestamp
    return timestamp;
  }

  /**
   * @notice Returns number of deeds registered for a particular address
   * @dev May be used together with `getDeedByAddress` or `getDeedTimestampByAddress` for iteration
   * @param propertyAddress a property address to lookup deeds for
   * @return number of deeds registered for the property address specified
   */
  function getNumberOfDeedsByAddress(string propertyAddress) public constant returns (uint256) {
    // calculate property address hash
    uint256 propertyAddressHash = uint256(keccak256(propertyAddress));

    // lookup the registry
    return addressRegistry[propertyAddressHash].length;
  }

  /**
   * @notice Gets the deed by property address and chronological index
   * @dev Should be used together with `getNumberOfDeedsByAddress` for iteration
   *      over the deed document for a particular address
   * @dev Throws if index is equal or bigger than `getNumberOfDeedsByAddress(propertyAddress)`
   * @param propertyAddress a property address to lookup deed for
   * @param i a chronological index, starting at zero
   */
  function getDeedByAddress(string propertyAddress, uint256 i) public constant returns (string) {
    // calculate property address hash
    uint256 propertyAddressHash = uint256(keccak256(propertyAddress));

    // lookup the registry
    return addressRegistry[propertyAddressHash][i];
  }

  /**
   * @notice Gets the last deed by property address
   * @dev Throws if no deeds exist for the address specified
   * @param propertyAddress a property address to lookup last deed for
   */
  function getLastDeedByAddress(string propertyAddress) public constant returns (string) {
    // calculate property address hash
    uint256 propertyAddressHash = uint256(keccak256(propertyAddress));

    // lookup the registry
    return addressRegistry[propertyAddressHash][addressRegistry[propertyAddressHash].length - 1];
  }
  /**
   * @notice Gets the deed registration timestamp by property address and chronological index
   * @dev Should be used together with `getNumberOfDeedsByAddress` for iteration
   *      over the deed timestamps for a particular address
   * @dev Throws if index is equal or bigger than `getNumberOfDeedsByAddress(propertyAddress)`
   * @param propertyAddress a property address to lookup deed timestamp for
   * @param i a chronological index, starting at zero
   */
  function getDeedTimestampByAddress(string propertyAddress, uint256 i) public constant returns (uint256) {
    // get the deed, delegate to `getDeedByAddress`
    string memory deed = getDeedByAddress(propertyAddress, i);

    // lookup for timestamp, delegate to `getDeedTimestamp`
    return getDeedTimestamp(deed);
  }

  /**
   * @notice Gets the last deed registration timestamp by property address
   * @dev Throws if no deeds exist for the address specified
   * @param propertyAddress a property address to lookup last deed timestamp for
   */
  function getLastDeedTimestampByAddress(string propertyAddress) public constant returns (uint256) {
    // calculate property address hash
    uint256 propertyAddressHash = uint256(keccak256(propertyAddress));

    // lookup the registry for the last deed
    string memory deed = addressRegistry[propertyAddressHash][addressRegistry[propertyAddressHash].length - 1];

    // lookup for timestamp, delegate to `getDeedTimestamp`
    return getDeedTimestamp(deed);
  }

  /**
   * @dev A convenient way to to get last element of the `knownPropertyAddresses` array
   * @return knownPropertyAddresses[knownPropertyAddresses.length - 1]
   */
  function lastKnownPropertyAddress() public constant returns (string) {
    // no need to verify if array length is greater than zero
    // if it is zero - an exception is thrown
    return knownPropertyAddresses[knownPropertyAddresses.length - 1];
  }

  /**
   * @dev A convenient way to get number of elements in the `knownPropertyAddresses` array
   * @return knownPropertyAddresses.length
   */
  function getNumberOfKnownPropertyAddresses() public constant returns (uint256) {
    return knownPropertyAddresses.length;
  }

}