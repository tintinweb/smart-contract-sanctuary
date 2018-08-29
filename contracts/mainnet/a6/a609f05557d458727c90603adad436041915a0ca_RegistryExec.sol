pragma solidity ^0.4.23;

interface StorageInterface {
  function getTarget(bytes32 exec_id, bytes4 selector)
      external view returns (address implementation);
  function getIndex(bytes32 exec_id) external view returns (address index);
  function createInstance(address sender, bytes32 app_name, address provider, bytes32 registry_exec_id, bytes calldata)
      external payable returns (bytes32 instance_exec_id, bytes32 version);
  function createRegistry(address index, address implementation) external returns (bytes32 exec_id);
  function exec(address sender, bytes32 exec_id, bytes calldata)
      external payable returns (uint emitted, uint paid, uint stored);
}

interface RegistryInterface {
  function getLatestVersion(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name)
      external view returns (bytes32 latest_name);
  function getVersionImplementation(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name, bytes32 version_name)
      external view returns (address index, bytes4[] selectors, address[] implementations);
}

contract ScriptExec {

  /// DEFAULT VALUES ///

  address public app_storage;
  address public provider;
  bytes32 public registry_exec_id;
  address public exec_admin;

  /// APPLICATION INSTANCE METADATA ///

  struct Instance {
    address current_provider;
    bytes32 current_registry_exec_id;
    bytes32 app_exec_id;
    bytes32 app_name;
    bytes32 version_name;
  }

  // Maps the execution ids of deployed instances to the address that deployed them -
  mapping (bytes32 => address) public deployed_by;
  // Maps the execution ids of deployed instances to a struct containing their metadata -
  mapping (bytes32 => Instance) public instance_info;
  // Maps an address that deployed app instances to metadata about the deployed instance -
  mapping (address => Instance[]) public deployed_instances;
  // Maps an application name to the exec ids under which it is deployed -
  mapping (bytes32 => bytes32[]) public app_instances;

  /// EVENTS ///

  event AppInstanceCreated(address indexed creator, bytes32 indexed execution_id, bytes32 app_name, bytes32 version_name);
  event StorageException(bytes32 indexed execution_id, string message);

  // Modifier - The sender must be the contract administrator
  modifier onlyAdmin() {
    require(msg.sender == exec_admin);
    _;
  }

  // Payable function - for abstract storage refunds
  function () public payable { }

  /*
  Configure various defaults for a script exec contract
  @param _exec_admin: A privileged address, able to set the target provider and registry exec id
  @param _app_storage: The address to which applications will be stored
  @param _provider: The address under which applications have been initialized
  */
  function configure(address _exec_admin, address _app_storage, address _provider) public {
    require(app_storage == 0, "ScriptExec already configured");
    require(_app_storage != 0, &#39;Invalid input&#39;);
    exec_admin = _exec_admin;
    app_storage = _app_storage;
    provider = _provider;

    if (exec_admin == 0)
      exec_admin = msg.sender;
  }

  /// APPLICATION EXECUTION ///

  bytes4 internal constant EXEC_SEL = bytes4(keccak256(&#39;exec(address,bytes32,bytes)&#39;));

  /*
  Executes an application using its execution id and storage address.

  @param _exec_id: The instance exec id, which will route the calldata to the appropriate destination
  @param _calldata: The calldata to forward to the application
  @return success: Whether execution succeeded or not
  */
  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success);

  bytes4 internal constant ERR = bytes4(keccak256(&#39;Error(string)&#39;));

  // Return the bytes4 action requestor stored at the pointer, and cleans the remaining bytes
  function getAction(uint _ptr) internal pure returns (bytes4 action) {
    assembly {
      // Get the first 4 bytes stored at the pointer, and clean the rest of the bytes remaining
      action := and(mload(_ptr), 0xffffffff00000000000000000000000000000000000000000000000000000000)
    }
  }

  // Checks to see if an error message was returned with the failed call, and emits it if so -
  function checkErrors(bytes32 _exec_id) internal {
    // If the returned data begins with selector &#39;Error(string)&#39;, get the contained message -
    string memory message;
    bytes4 err_sel = ERR;
    assembly {
      // Get pointer to free memory, place returned data at pointer, and update free memory pointer
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, returndatasize)
      mstore(0x40, add(ptr, returndatasize))

      // Check value at pointer for equality with Error selector -
      if eq(mload(ptr), and(err_sel, 0xffffffff00000000000000000000000000000000000000000000000000000000)) {
        message := add(0x24, ptr)
      }
    }
    // If no returned message exists, emit a default error message. Otherwise, emit the error message
    if (bytes(message).length == 0)
      emit StorageException(_exec_id, "No error recieved");
    else
      emit StorageException(_exec_id, message);
  }

  // Checks data returned by an application and returns whether or not the execution changed state
  function checkReturn() internal pure returns (bool success) {
    success = false;
    assembly {
      // returndata size must be 0x60 bytes
      if eq(returndatasize, 0x60) {
        // Copy returned data to pointer and check that at least one value is nonzero
        let ptr := mload(0x40)
        returndatacopy(ptr, 0, returndatasize)
        if iszero(iszero(mload(ptr))) { success := 1 }
        if iszero(iszero(mload(add(0x20, ptr)))) { success := 1 }
        if iszero(iszero(mload(add(0x40, ptr)))) { success := 1 }
      }
    }
    return success;
  }

  /// APPLICATION INITIALIZATION ///

  /*
  Initializes an instance of an application. Uses default app provider and registry app.
  Uses latest app version by default.
  @param _app_name: The name of the application to initialize
  @param _init_calldata: Calldata to be forwarded to the application&#39;s initialization function
  @return exec_id: The execution id (within the application&#39;s storage) of the created application instance
  @return version: The name of the version of the instance
  */
  function createAppInstance(bytes32 _app_name, bytes _init_calldata) external returns (bytes32 exec_id, bytes32 version) {
    require(_app_name != 0 && _init_calldata.length >= 4, &#39;invalid input&#39;);
    (exec_id, version) = StorageInterface(app_storage).createInstance(
      msg.sender, _app_name, provider, registry_exec_id, _init_calldata
    );
    // Set various app metadata values -
    deployed_by[exec_id] = msg.sender;
    app_instances[_app_name].push(exec_id);
    Instance memory inst = Instance(
      provider, registry_exec_id, exec_id, _app_name, version
    );
    instance_info[exec_id] = inst;
    deployed_instances[msg.sender].push(inst);
    // Emit event -
    emit AppInstanceCreated(msg.sender, exec_id, _app_name, version);
  }

  /// ADMIN FUNCTIONS ///

  /*
  Allows the exec admin to set the registry exec id from which applications will be initialized -
  @param _exec_id: The new exec id from which applications will be initialized
  */
  function setRegistryExecID(bytes32 _exec_id) public onlyAdmin() {
    registry_exec_id = _exec_id;
  }

  /*
  Allows the exec admin to set the provider from which applications will be initialized in the given registry exec id
  @param _provider: The address under which applications to initialize are registered
  */
  function setProvider(address _provider) public onlyAdmin() {
    provider = _provider;
  }

  // Allows the admin to set a new admin address
  function setAdmin(address _admin) public onlyAdmin() {
    require(_admin != 0);
    exec_admin = _admin;
  }

  /// STORAGE GETTERS ///

  // Returns a list of execution ids under which the given app name was deployed
  function getInstances(bytes32 _app_name) public view returns (bytes32[] memory) {
    return app_instances[_app_name];
  }

  /*
  Returns the number of instances an address has created
  @param _deployer: The address that deployed the instances
  @return uint: The number of instances deployed by the deployer
  */
  function getDeployedLength(address _deployer) public view returns (uint) {
    return deployed_instances[_deployer].length;
  }

  // The function selector for a simple registry &#39;registerApp&#39; function
  bytes4 internal constant REGISTER_APP_SEL = bytes4(keccak256(&#39;registerApp(bytes32,address,bytes4[],address[])&#39;));

  /*
  Returns the index address and implementing address for the simple registry app set as the default
  @return indx: The index address for the registry application - contains getters for the Registry, as well as its init funciton
  @return implementation: The address implementing the registry&#39;s functions
  */
  function getRegistryImplementation() public view returns (address index, address implementation) {
    index = StorageInterface(app_storage).getIndex(registry_exec_id);
    implementation = StorageInterface(app_storage).getTarget(registry_exec_id, REGISTER_APP_SEL);
  }

  /*
  Returns the functions and addresses implementing those functions that make up an application under the give execution id
  @param _exec_id: The execution id that represents the application in storage
  @return index: The index address of the instance - holds the app&#39;s getter functions and init functions
  @return functions: A list of function selectors supported by the application
  @return implementations: A list of addresses corresponding to the function selectors, where those selectors are implemented
  */
  function getInstanceImplementation(bytes32 _exec_id) public view
  returns (address index, bytes4[] memory functions, address[] memory implementations) {
    Instance memory app = instance_info[_exec_id];
    index = StorageInterface(app_storage).getIndex(app.current_registry_exec_id);
    (index, functions, implementations) = RegistryInterface(index).getVersionImplementation(
      app_storage, app.current_registry_exec_id, app.current_provider, app.app_name, app.version_name
    );
  }
}

contract RegistryExec is ScriptExec {

  struct Registry {
    address index;
    address implementation;
  }

  // Maps execution ids to its registry app metadata
  mapping (bytes32 => Registry) public registry_instance_info;
  // Maps address to list of deployed Registry instances
  mapping (address => Registry[]) public deployed_registry_instances;

  /// EVENTS ///

  event RegistryInstanceCreated(address indexed creator, bytes32 indexed execution_id, address index, address implementation);

  /// APPLICATION EXECUTION ///

  bytes4 internal constant EXEC_SEL = bytes4(keccak256(&#39;exec(address,bytes32,bytes)&#39;));

  /*
  Executes an application using its execution id and storage address.

  @param _exec_id: The instance exec id, which will route the calldata to the appropriate destination
  @param _calldata: The calldata to forward to the application
  @return success: Whether execution succeeded or not
  */
  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success) {
    // Get function selector from calldata -
    bytes4 sel = getSelector(_calldata);
    // Ensure no registry functions are being called -
    require(
      sel != this.registerApp.selector &&
      sel != this.registerAppVersion.selector &&
      sel != UPDATE_INST_SEL &&
      sel != UPDATE_EXEC_SEL
    );

    // Call &#39;exec&#39; in AbstractStorage, passing in the sender&#39;s address, the app exec id, and the calldata to forward -
    if (address(app_storage).call.value(msg.value)(abi.encodeWithSelector(
      EXEC_SEL, msg.sender, _exec_id, _calldata
    )) == false) {
      // Call failed - emit error message from storage and return &#39;false&#39;
      checkErrors(_exec_id);
      // Return unspent wei to sender
      address(msg.sender).transfer(address(this).balance);
      return false;
    }

    // Get returned data
    success = checkReturn();
    // If execution failed,
    require(success, &#39;Execution failed&#39;);

    // Transfer any returned wei back to the sender
    address(msg.sender).transfer(address(this).balance);
  }

  // Returns the first 4 bytes of calldata
  function getSelector(bytes memory _calldata) internal pure returns (bytes4 selector) {
    assembly {
      selector := and(
        mload(add(0x20, _calldata)),
        0xffffffff00000000000000000000000000000000000000000000000000000000
      )
    }
  }

  /// REGISTRY FUNCTIONS ///

  /*
  Creates an instance of a registry application and returns its execution id
  @param _index: The index file of the registry app (holds getters and init functions)
  @param _implementation: The file implementing the registry&#39;s functionality
  @return exec_id: The execution id under which the registry will store data
  */
  function createRegistryInstance(address _index, address _implementation) external onlyAdmin() returns (bytes32 exec_id) {
    // Validate input -
    require(_index != 0 && _implementation != 0, &#39;Invalid input&#39;);

    // Creates a registry from storage and returns the registry exec id -
    exec_id = StorageInterface(app_storage).createRegistry(_index, _implementation);

    // Ensure a valid execution id returned from storage -
    require(exec_id != 0, &#39;Invalid response from storage&#39;);

    // If there is not already a default registry exec id set, set it
    if (registry_exec_id == 0)
      registry_exec_id = exec_id;

    // Create Registry struct in memory -
    Registry memory reg = Registry(_index, _implementation);

    // Set various app metadata values -
    deployed_by[exec_id] = msg.sender;
    registry_instance_info[exec_id] = reg;
    deployed_registry_instances[msg.sender].push(reg);
    // Emit event -
    emit RegistryInstanceCreated(msg.sender, exec_id, _index, _implementation);
  }

  /*
  Registers an application as the admin under the provider and registry exec id
  @param _app_name: The name of the application to register
  @param _index: The index file of the application - holds the getters and init functions
  @param _selectors: The selectors of the functions which the app implements
  @param _implementations: The addresses at which each function is located
  */
  function registerApp(bytes32 _app_name, address _index, bytes4[] _selectors, address[] _implementations) external onlyAdmin() {
    // Validate input
    require(_app_name != 0 && _index != 0, &#39;Invalid input&#39;);
    require(_selectors.length == _implementations.length && _selectors.length != 0, &#39;Invalid input&#39;);
    // Check contract variables for valid initialization
    require(app_storage != 0 && registry_exec_id != 0 && provider != 0, &#39;Invalid state&#39;);

    // Execute registerApp through AbstractStorage -
    uint emitted;
    uint paid;
    uint stored;
    (emitted, paid, stored) = StorageInterface(app_storage).exec(msg.sender, registry_exec_id, msg.data);

    // Ensure zero values for emitted and paid, and nonzero value for stored -
    require(emitted == 0 && paid == 0 && stored != 0, &#39;Invalid state change&#39;);
  }

  /*
  Registers a version of an application as the admin under the provider and registry exec id
  @param _app_name: The name of the application under which the version will be registered
  @param _version_name: The name of the version to register
  @param _index: The index file of the application - holds the getters and init functions
  @param _selectors: The selectors of the functions which the app implements
  @param _implementations: The addresses at which each function is located
  */
  function registerAppVersion(bytes32 _app_name, bytes32 _version_name, address _index, bytes4[] _selectors, address[] _implementations) external onlyAdmin() {
    // Validate input
    require(_app_name != 0 && _version_name != 0 && _index != 0, &#39;Invalid input&#39;);
    require(_selectors.length == _implementations.length && _selectors.length != 0, &#39;Invalid input&#39;);
    // Check contract variables for valid initialization
    require(app_storage != 0 && registry_exec_id != 0 && provider != 0, &#39;Invalid state&#39;);

    // Execute registerApp through AbstractStorage -
    uint emitted;
    uint paid;
    uint stored;
    (emitted, paid, stored) = StorageInterface(app_storage).exec(msg.sender, registry_exec_id, msg.data);

    // Ensure zero values for emitted and paid, and nonzero value for stored -
    require(emitted == 0 && paid == 0 && stored != 0, &#39;Invalid state change&#39;);
  }

  // Update instance selectors, index, and addresses
  bytes4 internal constant UPDATE_INST_SEL = bytes4(keccak256(&#39;updateInstance(bytes32,bytes32,bytes32)&#39;));

  /*
  Updates an application&#39;s implementations, selectors, and index address. Uses default app provider and registry app.
  Uses latest app version by default.

  @param _exec_id: The execution id of the application instance to be updated
  @return success: The success of the call to the application&#39;s updateInstance function
  */
  function updateAppInstance(bytes32 _exec_id) external returns (bool success) {
    // Validate input. Only the original deployer can update an application -
    require(_exec_id != 0 && msg.sender == deployed_by[_exec_id], &#39;invalid sender or input&#39;);

    // Get instance metadata from exec id -
    Instance memory inst = instance_info[_exec_id];

    // Call &#39;exec&#39; in AbstractStorage, passing in the sender&#39;s address, the execution id, and
    // the calldata to update the application -
    if(address(app_storage).call(
      abi.encodeWithSelector(EXEC_SEL,            // &#39;exec&#39; selector
        inst.current_provider,                    // application provider address
        _exec_id,                                 // execution id to update
        abi.encodeWithSelector(UPDATE_INST_SEL,   // calldata for Registry updateInstance function
          inst.app_name,                          // name of the applcation used by the instance
          inst.version_name,                      // name of the current version of the application
          inst.current_registry_exec_id           // registry exec id when the instance was instantiated
        )
      )
    ) == false) {
      // Call failed - emit error message from storage and return &#39;false&#39;
      checkErrors(_exec_id);
      return false;
    }
    // Check returned data to ensure state was correctly changed in AbstractStorage -
    success = checkReturn();
    // If execution failed, revert state and return an error message -
    require(success, &#39;Execution failed&#39;);

    // If execution was successful, the version was updated. Get the latest version
    // and set the exec id instance info -
    address registry_idx = StorageInterface(app_storage).getIndex(inst.current_registry_exec_id);
    bytes32 latest_version  = RegistryInterface(registry_idx).getLatestVersion(
      app_storage,
      inst.current_registry_exec_id,
      inst.current_provider,
      inst.app_name
    );
    // Ensure nonzero latest version -
    require(latest_version != 0, &#39;invalid latest version&#39;);
    // Set current version -
    instance_info[_exec_id].version_name = latest_version;
  }

  // Update instance script exec contract
  bytes4 internal constant UPDATE_EXEC_SEL = bytes4(keccak256(&#39;updateExec(address)&#39;));

  /*
  Updates an application&#39;s script executor from this Script Exec to a new address

  @param _exec_id: The execution id of the application instance to be updated
  @param _new_exec_addr: The new script exec address for this exec id
  @returns success: The success of the call to the application&#39;s updateExec function
  */
  function updateAppExec(bytes32 _exec_id, address _new_exec_addr) external returns (bool success) {
    // Validate input. Only the original deployer can migrate the script exec address -
    require(_exec_id != 0 && msg.sender == deployed_by[_exec_id] && address(this) != _new_exec_addr && _new_exec_addr != 0, &#39;invalid input&#39;);

    // Call &#39;exec&#39; in AbstractStorage, passing in the sender&#39;s address, the execution id, and
    // the calldata to migrate the script exec address -
    if(address(app_storage).call(
      abi.encodeWithSelector(EXEC_SEL,                            // &#39;exec&#39; selector
        msg.sender,                                               // sender address
        _exec_id,                                                 // execution id to update
        abi.encodeWithSelector(UPDATE_EXEC_SEL, _new_exec_addr)   // calldata for Registry updateExec
      )
    ) == false) {
      // Call failed - emit error message from storage and return &#39;false&#39;
      checkErrors(_exec_id);
      return false;
    }
    // Check returned data to ensure state was correctly changed in AbstractStorage -
    success = checkReturn();
    // If execution failed, revert state and return an error message -
    require(success, &#39;Execution failed&#39;);
  }
}