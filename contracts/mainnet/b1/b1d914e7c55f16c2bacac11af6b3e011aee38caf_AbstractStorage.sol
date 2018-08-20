pragma solidity ^0.4.23;

interface RegistryInterface {
  function getLatestVersion(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name)
      external view returns (bytes32 latest_name);
  function getVersionImplementation(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name, bytes32 version_name)
      external view returns (address index, bytes4[] selectors, address[] implementations);
}

contract AbstractStorage {

  // Special storage locations - applications can read from 0x0 to get the execution id, and 0x20
  // to get the sender from which the call originated
  bytes32 private exec_id;
  address private sender;

  // Keeps track of the number of applicaions initialized, so that each application has a unique execution id
  uint private nonce;

  /// EVENTS ///

  event ApplicationInitialized(bytes32 indexed execution_id, address indexed index, address script_exec);
  event ApplicationExecution(bytes32 indexed execution_id, address indexed script_target);
  event DeliveredPayment(bytes32 indexed execution_id, address indexed destination, uint amount);

  /// CONSTANTS ///

  // STORAGE LOCATIONS //

  bytes32 internal constant EXEC_PERMISSIONS = keccak256(&#39;script_exec_permissions&#39;);
  bytes32 internal constant APP_IDX_ADDR = keccak256(&#39;index&#39;);

  // ACTION REQUESTORS //

  bytes4 internal constant EMITS = bytes4(keccak256(&#39;Emit((bytes32[],bytes)[])&#39;));
  bytes4 internal constant STORES = bytes4(keccak256(&#39;Store(bytes32[])&#39;));
  bytes4 internal constant PAYS = bytes4(keccak256(&#39;Pay(bytes32[])&#39;));
  bytes4 internal constant THROWS = bytes4(keccak256(&#39;Error(string)&#39;));

  // SELECTORS //

  bytes4 internal constant REG_APP
      = bytes4(keccak256(&#39;registerApp(bytes32,address,bytes4[],address[])&#39;));
  bytes4 internal constant REG_APP_VER
      = bytes4(keccak256(&#39;registerAppVersion(bytes32,bytes32,address,bytes4[],address[])&#39;));
  bytes4 internal constant UPDATE_EXEC_SEL
      = bytes4(keccak256(&#39;updateExec(address)&#39;));
  bytes4 internal constant UPDATE_INST_SEL
      = bytes4(keccak256(&#39;updateInstance(bytes32,bytes32,bytes32)&#39;));

  // Creates an instance of a registry application and returns the execution id
  function createRegistry(address _registry_idx, address _implementation) external returns (bytes32) {
    bytes32 new_exec_id = keccak256(++nonce);
    put(new_exec_id, keccak256(msg.sender, EXEC_PERMISSIONS), bytes32(1));
    put(new_exec_id, APP_IDX_ADDR, bytes32(_registry_idx));
    put(new_exec_id, keccak256(REG_APP, &#39;implementation&#39;), bytes32(_implementation));
    put(new_exec_id, keccak256(REG_APP_VER, &#39;implementation&#39;), bytes32(_implementation));
    put(new_exec_id, keccak256(UPDATE_INST_SEL, &#39;implementation&#39;), bytes32(_implementation));
    put(new_exec_id, keccak256(UPDATE_EXEC_SEL, &#39;implementation&#39;), bytes32(_implementation));
    emit ApplicationInitialized(new_exec_id, _registry_idx, msg.sender);
    return new_exec_id;
  }

  /// APPLICATION INSTANCE INITIALIZATION ///

  /*
  Executes an initialization function of an application, generating a new exec id that will be associated with that address

  @param _sender: The sender of the transaction, as reported by the script exec contract
  @param _app_name: The name of the application which will be instantiated
  @param _provider: The provider under which the application is registered
  @param _registry_id: The execution id of the registry app
  @param _calldata: The calldata to forward to the application
  @return new_exec_id: A new, unique execution id paired with the created instance of the application
  @return version: The name of the version of the instance
  */
  function createInstance(address _sender, bytes32 _app_name, address _provider, bytes32 _registry_id, bytes _calldata) external payable returns (bytes32 new_exec_id, bytes32 version) {
    // Ensure valid input -
    require(_sender != 0 && _app_name != 0 && _provider != 0 && _registry_id != 0 && _calldata.length >= 4, &#39;invalid input&#39;);

    // Create new exec id by incrementing the nonce -
    new_exec_id = keccak256(++nonce);

    // Sanity check - verify that this exec id is not linked to an existing application -
    assert(getIndex(new_exec_id) == address(0));

    // Set the allowed addresses and selectors for the new instance, from the script registry -
    address index;
    (index, version) = setImplementation(new_exec_id, _app_name, _provider, _registry_id);

    // Set the exec id and sender addresses for the target application -
    setContext(new_exec_id, _sender);

    // Execute application, create a new exec id, and commit the returned data to storage -
    require(address(index).delegatecall(_calldata) == false, &#39;Unsafe execution&#39;);
    // Get data returned from call revert and perform requested actions -
    executeAppReturn(new_exec_id);

    // Emit event
    emit ApplicationInitialized(new_exec_id, index, msg.sender);

    // If execution reaches this point, newly generated exec id should be valid -
    assert(new_exec_id != bytes32(0));

    // Ensure that any additional balance is transferred back to the sender -
    if (address(this).balance > 0)
      address(msg.sender).transfer(address(this).balance);
  }

  /*
  Executes an initialized application associated with the given exec id, under the sender&#39;s address and with
  the given calldata

  @param _sender: The address reported as the call sender by the script exec contract
  @param _exec_id: The execution id corresponding to an instance of the application
  @param _calldata: The calldata to forward to the application
  @return n_emitted: The number of events emitted on behalf of the application
  @return n_paid: The number of destinations ETH was forwarded to on behalf of the application
  @return n_stored: The number of storage slots written to on behalf of the application
  */
  function exec(address _sender, bytes32 _exec_id, bytes _calldata) external payable returns (uint n_emitted, uint n_paid, uint n_stored) {
    // Ensure valid input and input size - minimum 4 bytes
    require(_calldata.length >= 4 && _sender != address(0) && _exec_id != bytes32(0));

    // Get the target address associated with the given exec id
    address target = getTarget(_exec_id, getSelector(_calldata));
    require(target != address(0), &#39;Uninitialized application&#39;);

    // Set the exec id and sender addresses for the target application -
    setContext(_exec_id, _sender);

    // Execute application and commit returned data to storage -
    require(address(target).delegatecall(_calldata) == false, &#39;Unsafe execution&#39;);
    (n_emitted, n_paid, n_stored) = executeAppReturn(_exec_id);

    // If no events were emitted, no wei was forwarded, and no storage was changed, revert -
    if (n_emitted == 0 && n_paid == 0 && n_stored == 0)
      revert(&#39;No state change occured&#39;);

    // Emit event -
    emit ApplicationExecution(_exec_id, target);

    // Ensure that any additional balance is transferred back to the sender -
    if (address(this).balance > 0)
      address(msg.sender).transfer(address(this).balance);
  }

  /// APPLICATION RETURNDATA HANDLING ///

  /*
  This function parses data returned by an application and executes requested actions. Because applications
  are assumed to be stateless, they cannot emit events, store data, or forward payment. Therefore, these
  steps to execution are handled in the storage contract by this function.

  Returned data can execute several actions requested by the application through the use of an &#39;action requestor&#39;:
  Some actions mirror nested dynamic return types, which are manually encoded and decoded as they are not supported
  1. THROWS  - App requests storage revert with a given message
      --Format: bytes
        --Payload is simply an array of bytes that will be reverted back to the caller
  2. EMITS   - App requests that events be emitted. Can provide topics to index, as well as arbitrary length data
      --Format: Event[]
        --Event format: [uint n_topics][bytes32 topic_0]...[bytes32 topic_n][uint data.length][bytes data]
  3. STORES  - App requests that data be stored to its storage. App storage locations are hashed with the app&#39;s exec id
      --Format: bytes32[]
        --bytes32[] consists of a data location followed by a value to place at that location
        --as such, its length must be even
        --Ex: [value_0][location_0]...[value_n][location_n]
  4. PAYS    - App requests that ETH sent to the contract be forwarded to other addresses.
      --Format: bytes32[]
        --bytes32[] consists of an address to send ETH to, followed by an amount to send to that address
        --As such, its length must be even
        --Ex: [amt_0][bytes32(destination_0)]...[amt_n][bytes32(destination_n)]

  Returndata is structured as an array of bytes, beginning with an action requestor (&#39;THROWS&#39;, &#39;PAYS&#39;, etc)
  followed by that action&#39;s appropriately-formatted data (see above). Up to 3 actions with formatted data can be placed
  into returndata, and each must be unique (i.e. no two &#39;EMITS&#39; actions).

  If the THROWS action is requested, it must be the first event requested. The event will be parsed
  and logged, and no other actions will be executed. If the THROWS requestor is not the first action
  requested, this function will throw

  @param _exec_id: The execution id which references this application&#39;s storage
  @return n_emitted: The number of events emitted on behalf of the application
  @return n_paid: The number of destinations ETH was forwarded to on behalf of the application
  @return n_stored: The number of storage slots written to on behalf of the application
  */
  function executeAppReturn(bytes32 _exec_id) internal returns (uint n_emitted, uint n_paid, uint n_stored) {
    uint _ptr;      // Will be a pointer to the data returned by the application call
    uint ptr_bound; // Will be the maximum value of the pointer possible (end of the memory stored in the pointer)
    (ptr_bound, _ptr) = getReturnedData();
    // If the application reverted with an error, we can check directly for its selector -
    if (getAction(_ptr) == THROWS) {
      // Execute THROWS request
      doThrow(_ptr);
      // doThrow should revert, so we should never reach this point
      assert(false);
    }

    // Ensure there are at least 64 bytes stored at the pointer
    require(ptr_bound >= _ptr + 64, &#39;Malformed returndata - invalid size&#39;);
    _ptr += 64;

    // Iterate over returned data and execute actions
    bytes4 action;
    while (_ptr <= ptr_bound && (action = getAction(_ptr)) != 0x0) {
      if (action == EMITS) {
        // If the action is EMITS, and this action has already been executed, throw
        require(n_emitted == 0, &#39;Duplicate action: EMITS&#39;);
        // Otherwise, emit events and get amount of events emitted
        // doEmit returns the pointer incremented to the end of the data portion of the action executed
        (_ptr, n_emitted) = doEmit(_ptr, ptr_bound);
        // If 0 events were emitted, returndata is malformed: throw
        require(n_emitted != 0, &#39;Unfulfilled action: EMITS&#39;);
      } else if (action == STORES) {
        // If the action is STORES, and this action has already been executed, throw
        require(n_stored == 0, &#39;Duplicate action: STORES&#39;);
        // Otherwise, store data and get amount of slots written to
        // doStore increments the pointer to the end of the data portion of the action executed
        (_ptr, n_stored) = doStore(_ptr, ptr_bound, _exec_id);
        // If no storage was performed, returndata is malformed: throw
        require(n_stored != 0, &#39;Unfulfilled action: STORES&#39;);
      } else if (action == PAYS) {
        // If the action is PAYS, and this action has already been executed, throw
        require(n_paid == 0, &#39;Duplicate action: PAYS&#39;);
        // Otherwise, forward ETH and get amount of addresses forwarded to
        // doPay increments the pointer to the end of the data portion of the action executed
        (_ptr, n_paid) = doPay(_exec_id, _ptr, ptr_bound);
        // If no destinations recieved ETH, returndata is malformed: throw
        require(n_paid != 0, &#39;Unfulfilled action: PAYS&#39;);
      } else {
        // Unrecognized action requested. returndata is malformed: throw
        revert(&#39;Malformed returndata - unknown action&#39;);
      }
    }
    assert(n_emitted != 0 || n_paid != 0 || n_stored != 0);
  }

  /// HELPERS ///

  /*
  Reads application information from the script registry, and sets up permissions for the new instance&#39;s various functions

  @param _new_exec_id: The execution id being created, for which permissions will be registered
  @param _app_name: The name of the new application instance - corresponds to an application registered by the provider under that name
  @param _provider: The address of the account that registered an application under the given name
  @param _registry_id: The exec id of the registry from which the information will be read
  */
  function setImplementation(bytes32 _new_exec_id, bytes32 _app_name, address _provider, bytes32 _registry_id) internal returns (address index, bytes32 version) {
    // Get the index address for the registry app associated with the passed-in exec id
    index = getIndex(_registry_id);
    require(index != address(0) && index != address(this), &#39;Registry application not found&#39;);
    // Get the name of the latest version from the registry app at the given address
    version = RegistryInterface(index).getLatestVersion(
      address(this), _registry_id, _provider, _app_name
    );
    // Ensure the version name is valid -
    require(version != bytes32(0), &#39;Invalid version name&#39;);

    // Get the allowed selectors and addresses for the new instance from the registry app
    bytes4[] memory selectors;
    address[] memory implementations;
    (index, selectors, implementations) = RegistryInterface(index).getVersionImplementation(
      address(this), _registry_id, _provider, _app_name, version
    );
    // Ensure a valid index address for the new instance -
    require(index != address(0), &#39;Invalid index address&#39;);
    // Ensure a nonzero number of allowed selectors and implementing addresses -
    require(selectors.length == implementations.length && selectors.length != 0, &#39;Invalid implementation length&#39;);

    // Set the index address for the new instance -
    bytes32 seed = APP_IDX_ADDR;
    put(_new_exec_id, seed, bytes32(index));
    // Loop over implementing addresses, and map each function selector to its corresponding address for the new instance
    for (uint i = 0; i < selectors.length; i++) {
      require(selectors[i] != 0 && implementations[i] != 0, &#39;invalid input - expected nonzero implementation&#39;);
      seed = keccak256(selectors[i], &#39;implementation&#39;);
      put(_new_exec_id, seed, bytes32(implementations[i]));
    }

    return (index, version);
  }

  // Returns the index address of an application using a given exec id, or 0x0
  // if the instance does not exist
  function getIndex(bytes32 _exec_id) public view returns (address) {
    bytes32 seed = APP_IDX_ADDR;
    function (bytes32, bytes32) view returns (address) getter;
    assembly { getter := readMap }
    return getter(_exec_id, seed);
  }

  // Returns the address to which calldata with the given selector will be routed
  function getTarget(bytes32 _exec_id, bytes4 _selector) public view returns (address) {
    bytes32 seed = keccak256(_selector, &#39;implementation&#39;);
    function (bytes32, bytes32) view returns (address) getter;
    assembly { getter := readMap }
    return getter(_exec_id, seed);
  }

  struct Map { mapping(bytes32 => bytes32) inner; }

  // Receives a storage pointer and returns the value mapped to the seed at that pointer
  function readMap(Map storage _map, bytes32 _seed) internal view returns (bytes32) {
    return _map.inner[_seed];
  }

  // Maps the seed to the value within the execution id&#39;s storage
  function put(bytes32 _exec_id, bytes32 _seed, bytes32 _val) internal {
    function (bytes32, bytes32, bytes32) puts;
    assembly { puts := putMap }
    puts(_exec_id, _seed, _val);
  }

  // Receives a storage pointer and maps the seed to the value at that pointer
  function putMap(Map storage _map, bytes32 _seed, bytes32 _val) internal {
    _map.inner[_seed] = _val;
  }

  /// APPLICATION EXECUTION ///

  function getSelector(bytes memory _calldata) internal pure returns (bytes4 sel) {
    assembly {
      sel := and(
        mload(add(0x20, _calldata)),
        0xffffffff00000000000000000000000000000000000000000000000000000000
      )
    }
  }

  /*
  After validating that returned data is larger than 32 bytes, returns a pointer to the returned data
  in memory, as well as a pointer to the end of returndata in memory

  @return ptr_bounds: The pointer cannot be this value and be reading from returndata
  @return _returndata_ptr: A pointer to the returned data in memory
  */
  function getReturnedData() internal pure returns (uint ptr_bounds, uint _returndata_ptr) {
    assembly {
      // returndatasize must be minimum 96 bytes (offset, length, and requestor)
      if lt(returndatasize, 0x60) {
        mstore(0, 0x20)
        mstore(0x20, 24)
        mstore(0x40, &#39;Insufficient return size&#39;)
        revert(0, 0x60)
      }
      // Get memory location to which returndata will be copied
      _returndata_ptr := msize
      // Copy returned data to pointer location
      returndatacopy(_returndata_ptr, 0, returndatasize)
      // Get maximum memory location value for returndata
      ptr_bounds := add(_returndata_ptr, returndatasize)
      // Set new free-memory pointer to point after the returndata in memory
      // Returndata is automatically 32-bytes padded
      mstore(0x40, add(0x20, ptr_bounds))
    }
  }

  /*
  Returns the value stored in memory at the pointer. Used to determine the size of fields in returned data

  @param _ptr: A pointer to some location in memory containing returndata
  @return length: The value stored at that pointer
  */
  function getLength(uint _ptr) internal pure returns (uint length) {
    assembly { length := mload(_ptr) }
  }

  // Executes the THROWS action, reverting any returned data back to the caller
  function doThrow(uint _ptr) internal pure {
    assert(getAction(_ptr) == THROWS);
    assembly { revert(_ptr, returndatasize) }
  }

  /*
  Parses and executes a PAYS action copied from returndata and located at the pointer
  A PAYS action provides a set of addresses and corresponding amounts of ETH to send to those
  addresses. The sender must ensure the call has sufficient funds, or the call will fail
  PAYS actions follow a format of: [amt_0][address_0]...[amt_n][address_n]

  @param _ptr: A pointer in memory to an application&#39;s returned payment request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @return ptr: An updated pointer, pointing to the end of the PAYS action request in memory
  @return n_paid: The number of destinations paid out to from the returned PAYS request
  */
  function doPay(bytes32 _exec_id, uint _ptr, uint _ptr_bound) internal returns (uint ptr, uint n_paid) {
    // Ensure ETH was sent with the call
    require(msg.value > 0);
    assert(getAction(_ptr) == PAYS);
    _ptr += 4;
    // Get number of destinations
    uint num_destinations = getLength(_ptr);
    _ptr += 32;
    address pay_to;
    uint amt;
    // Loop over PAYS actions and process each one
    while (_ptr <= _ptr_bound && n_paid < num_destinations) {
      // Get the payment destination and amount from the pointer
      assembly {
        amt := mload(_ptr)
        pay_to := mload(add(0x20, _ptr))
      }
      // Invalid address was passed as a payment destination - throw
      if (pay_to == address(0) || pay_to == address(this))
        revert(&#39;PAYS: invalid destination&#39;);

      // Forward ETH and increment n_paid
      address(pay_to).transfer(amt);
      n_paid++;
      // Increment pointer
      _ptr += 64;
      // Emit event
      emit DeliveredPayment(_exec_id, pay_to, amt);
    }
    ptr = _ptr;
    assert(n_paid == num_destinations);
  }

  /*
  Parses and executes a STORES action copied from returndata and located at the pointer
  A STORES action provides a set of storage locations and corresponding values to store at those locations
  true storage locations within this contract are first hashed with the application&#39;s execution id to prevent
  storage overlaps between applications sharing the contract
  STORES actions follow a format of: [location_0][val_0]...[location_n][val_n]

  @param _ptr: A pointer in memory to an application&#39;s returned storage request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @param _exec_id: The execution id under which storage is located
  @return ptr: An updated pointer, pointing to the end of the STORES action request in memory
  @return n_stored: The number of storage locations written to from the returned STORES request
  */
  function doStore(uint _ptr, uint _ptr_bound, bytes32 _exec_id) internal returns (uint ptr, uint n_stored) {
    assert(getAction(_ptr) == STORES && _exec_id != bytes32(0));
    _ptr += 4;
    // Get number of locations to which data will be stored
    uint num_locations = getLength(_ptr);
    _ptr += 32;
    bytes32 location;
    bytes32 value;
    // Loop over STORES actions and process each one
    while (_ptr <= _ptr_bound && n_stored < num_locations) {
      // Get storage location and value to store from the pointer
      assembly {
        location := mload(_ptr)
        value := mload(add(0x20, _ptr))
      }
      // Store the data to the location hashed with the exec id
      store(_exec_id, location, value);
      // Increment n_stored and pointer
      n_stored++;
      _ptr += 64;
    }
    ptr = _ptr;
    require(n_stored == num_locations);
  }

  /*
  Parses and executes an EMITS action copied from returndata and located at the pointer
  An EMITS action is a list of bytes that are able to be processed and passed into logging functions (log0, log1, etc)
  EMITS actions follow a format of: [Event_0][Event_1]...[Event_n]
    where each Event_i follows the format: [topic_0]...[topic_4][data.length]<data>
    -The topics array is a bytes32 array of maximum length 4 and minimum 0
    -The final data parameter is a simple bytes array, and is emitted as a non-indexed parameter

  @param _ptr: A pointer in memory to an application&#39;s returned emit request
  @param _ptr_bound: The upper bound on the value for _ptr before it is reading invalid data
  @return ptr: An updated pointer, pointing to the end of the EMITS action request in memory
  @return n_emitted: The number of events logged from the returned EMITS request
  */
  function doEmit(uint _ptr, uint _ptr_bound) internal returns (uint ptr, uint n_emitted) {
    assert(getAction(_ptr) == EMITS);
    _ptr += 4;
    // Converts number of events that will be emitted
    uint num_events = getLength(_ptr);
    _ptr += 32;
    bytes32[] memory topics;
    bytes memory data;
    // Loop over EMITS actions and process each one
    while (_ptr <= _ptr_bound && n_emitted < num_events) {
      // Get array of topics and additional data from the pointer
      assembly {
        topics := _ptr
        data := add(add(_ptr, 0x20), mul(0x20, mload(topics)))
      }
      // Get size of the Event&#39;s data in memory
      uint log_size = 32 + (32 * (1 + topics.length)) + data.length;
      assembly {
        switch mload(topics)                // topics.length
          case 0 {
            // Log Event.data array with no topics
            log0(
              add(0x20, data),              // data(ptr)
              mload(data)                   // data.length
            )
          }
          case 1 {
            // Log Event.data array with 1 topic
            log1(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics))      // topics[0]
            )
          }
          case 2 {
            // Log Event.data array with 2 topics
            log2(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics)),     // topics[0]
              mload(add(0x40, topics))      // topics[1]
            )
          }
          case 3 {
            // Log Event.data array with 3 topics
            log3(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics)),     // topics[0]
              mload(add(0x40, topics)),     // topics[1]
              mload(add(0x60, topics))      // topics[2]
            )
          }
          case 4 {
            // Log Event.data array with 4 topics
            log4(
              add(0x20, data),              // data(ptr)
              mload(data),                  // data.length
              mload(add(0x20, topics)),     // topics[0]
              mload(add(0x40, topics)),     // topics[1]
              mload(add(0x60, topics)),     // topics[2]
              mload(add(0x80, topics))      // topics[3]
            )
          }
          default {
            // Events must have 4 or fewer topics
            mstore(0, &#39;EMITS: invalid topic count&#39;)
            revert(0, 0x20)
          }
      }
      // Event emitted - increment n_emitted and pointer
      n_emitted++;
      _ptr += log_size;
    }
    ptr = _ptr;
    require(n_emitted == num_events);
  }

  // Return the bytes4 action requestor stored at the pointer, and cleans the remaining bytes
  function getAction(uint _ptr) internal pure returns (bytes4 action) {
    assembly {
      // Get the first 4 bytes stored at the pointer, and clean the rest of the bytes remaining
      action := and(mload(_ptr), 0xffffffff00000000000000000000000000000000000000000000000000000000)
    }
  }

  // Sets the execution id and sender address in special storage locations, so that
  // they are able to be read by the target application
  function setContext(bytes32 _exec_id, address _sender) internal {
    // Ensure the exec id and sender are nonzero
    assert(_exec_id != bytes32(0) && _sender != address(0));
    exec_id = _exec_id;
    sender = _sender;
  }

  // Stores data to a given location, with a key (exec id)
  function store(bytes32 _exec_id, bytes32 _location, bytes32 _data) internal {
    // Get true location to store data to - hash of location hashed with exec id
    _location = keccak256(_location, _exec_id);
    // Store data at location
    assembly { sstore(_location, _data) }
  }

  // STORAGE READS //

  /*
  Returns data stored at a given location
  @param _location: The address to get data from
  @return data: The data stored at the location after hashing
  */
  function read(bytes32 _exec_id, bytes32 _location) public view returns (bytes32 data_read) {
    _location = keccak256(_location, _exec_id);
    assembly { data_read := sload(_location) }
  }

  /*
  Returns data stored in several nonconsecutive locations
  @param _locations: A dynamic array of storage locations to read from
  @return data_read: The corresponding data stored in the requested locations
  */
  function readMulti(bytes32 _exec_id, bytes32[] _locations) public view returns (bytes32[] data_read) {
    data_read = new bytes32[](_locations.length);
    for (uint i = 0; i < _locations.length; i++) {
      data_read[i] = read(_exec_id, _locations[i]);
    }
  }
}