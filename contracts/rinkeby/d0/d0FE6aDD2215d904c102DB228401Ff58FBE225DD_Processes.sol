/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../lib/governance-primitives/GovernancePrimitive.sol";
import "../permissions/Permissions.sol";
import "../executor/Executor.sol";
import "../../lib/component/IDAO.sol";

/// @title The processes contract defining the flow of every interaction with the DAO
/// @author Samuel Furter - Aragon Association - 2021
/// @notice This contract is a central point of the Aragon DAO framework and handles all the processes and stores the different process types with his governance primitives a DAO can have.
/// @dev A list of process types are stored here pluss it validates if the passed actions in a proposal are valid.
contract Processes is UpgradableComponent { 

    bytes32 public constant PROCESSES_START_ROLE = keccak256("PROCESSES_START_ROLE");
    bytes32 public constant PROCESSES_SET_ROLE = keccak256("PROCESSES_SET_ROLE");

    event ProcessStarted(GovernancePrimitive.Proposal indexed proposal, uint256 indexed executionId);
    event ProcessSet(string indexed name, Process indexed process);

    struct Process {
        GovernancePrimitive governancePrimitive; // The primitve to execute for example a simple yes/no voting.
        Permissions.GovernancePrimitivePermissions permissions; // A struct with all permission hashes for any possible governance primitive permission.
        AllowedActions[] allowedActions; // Allowed actions this process can call
        bytes metadata; // The IPFS hash that points to a JSON file that describes this specific governance process.
    }

    struct AllowedActions {
        address to; // Allowed contract to call
        bytes4[] methods; // The method signatures of the allowed method calls
    }
    
    mapping(string => Process) public processes; // All existing governance processes in this DAO

    constructor() initializer {}

    /// @dev Used for UUPS upgradability pattern
    /// @param _dao The DAO contract of the current DAO
    function initialize(IDAO _dao) public override initializer {
        Component.initialize(_dao);
    }

    /// @notice Starts the given process resp. primitive by the given proposal
    /// @dev Checks the passed actions, gets the governance primitive of this process, and starts it
    /// @param proposal The proposal for execution submitted by the user.
    /// @return process The Process struct stored
    /// @return executionId The id of the newly created execution.
    function start(GovernancePrimitive.Proposal calldata proposal) 
        external 
        authP(PROCESSES_START_ROLE) 
        returns (Process memory process, uint256 executionId) 
    {
        process = processes[proposal.processName];
        require(checkActions(proposal.actions, process.allowedActions), "Not allowed action!");

        executionId = GovernancePrimitive(process.governancePrimitive).start(process, proposal);
        
        emit ProcessStarted(proposal, executionId);

        return (process, executionId);
    }

    /// @notice Adds a new process to the DAO
    /// @param name The name of the new process
    /// @param process The process struct defining the new DAO process
    function setProcess(string calldata name, Process calldata process) 
        public 
        authP(PROCESSES_SET_ROLE) 
    {
        processes[name] = process;

        emit ProcessSet(name, process);
    }

    // TODO: Optimize this!
    /// @notice Checks if the passed actions are allowed to be executed with the selected process
    /// @dev Checks the passed actions, gets the governance primitive of this process, and starts it
    /// @param actions The proposal for execution submitted by the user.
    /// @param allowedActions The proposal for execution submitted by the user.
    /// @return valid Returns the validity bool value after validating the actions
    function checkActions(Executor.Action[] calldata actions, AllowedActions[] memory allowedActions) 
        internal pure 
        returns (bool valid) 
    {
        uint256 actionsLength = actions.length;
        uint256 allowedActionsLength = allowedActions.length;
        bool allowed = false;

        for (uint256 i = 0; i < actionsLength; i++) { // FOR EVERY PROPOSAL ACTION
            Executor.Action calldata action = actions[i];
            for (uint256 k = 0; k < allowedActionsLength; k++) { // FOR EVERY ALLOWED CONTRACT
                AllowedActions memory allowedAction = allowedActions[k];
                if (action.to == allowedAction.to) { // CONTRACT MATCHED
                    uint256 methodsLength = allowedAction.methods.length;
                    for (uint256 y = 0; y < methodsLength; y++) { // CHECK FOR EVERY ALLOWD METHOD OF A CONTRACT
                        if (bytes4(action.data[:4]) == allowedAction.methods[y]) { // METHOD FOUND STOP SEARCHING
                            allowed = true;
                            break;
                        } else { // METHOD NOT FOUND
                            allowed = false;
                        }
                    }

                    if (allowed) {
                        break;
                    }
                }
            }
            
            if (!allowed) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../src/permissions/Permissions.sol";
import "../../src/processes/Processes.sol";
import "../../src/executor/Executor.sol";
import "../../src/DAO.sol";
import "../component/Component.sol";

/// @title Abstract implementation of the governance primitive
/// @author Samuel Furter - Aragon Association - 2021
/// @notice This contract can be used to implement concrete stoppable governance primitives and being fully compatible with the DAO framework and UI of Aragon
/// @dev You only have to define the specific custom logic for your needs in _start, _execute, and _stop
abstract contract GovernancePrimitive is Component {

    bytes32 public constant CREATE_PRIMITIVE_START_ROLE = keccak256("CREATE_PRIMITIVE_START_ROLE");
    bytes32 public constant PRIMITIVE_EXECUTE_ROLE = keccak256("PRIMITIVE_EXECUTE_ROLE");

    string internal constant ERROR_EXECUTION_STATE_WRONG = "ERROR_EXECUTION_STATE_WRONG";
    string internal constant ERROR_NOT_ALLOWED_TO_EXECUTE = "ERROR_NOT_ALLOWED_TO_EXECUTE";
    string internal constant ERROR_NOT_ALLOWED_TO_START = "ERROR_NOT_ALLOWED_TO_START";
    string internal constant ERROR_NO_EXECUTION = "ERROR_NO_EXECUTION";
    
    // The states a execution can have
    enum State {
        RUNNING, 
        STOPPED,
        HALTED,
        EXECUTED
    }

    struct Proposal {
        string processName; // The hash of the process that should get called
        Executor.Action[] actions; // The actions that should get executed in the end
        bytes metadata; // IPFS hash pointing to the metadata as description, title, image etc. 
        bytes additionalArguments; // Optional additional arguments a process resp. governance primitive does need
    }

    struct Execution { // A execution contains the process to execute, the proposal passed by the user, and the state of the execution.
        uint256 id;
        Processes.Process process;
        Proposal proposal;
        State state;
    }

    uint256 private executionsCounter;
    mapping(uint256 => Execution) private executions;

    event GovernancePrimitiveStarted(Execution indexed execution, uint256 indexed executionId);
    event GovernancePrimitiveExecuted(Execution indexed execution, uint256 indexed executionId);

    modifier executionExist(uint256 _id) {
        require(_id < executionsCounter, ERROR_NO_EXECUTION);
        _;
    }

    /// @notice If called the governance primitive starts a new execution.
    /// @dev The state of the container does get changed to RUNNING, the execution struct gets created, and the concrete implementation in _start called.
    /// @param process The process definition.
    /// @param proposal The proposal for execution submitted by the user.
    /// @return executionId The id of the newly created execution.
    function start(Processes.Process calldata process, Proposal calldata proposal) 
        external 
        authP(CREATE_PRIMITIVE_START_ROLE) 
        returns (uint256 executionId) 
    {
        require(
            dao.checkPermission(process.permissions.start),
            ERROR_NOT_ALLOWED_TO_START
        );

        executionsCounter++;

        // the reason behind this - https://matrix.to/#/!poXqlbVpQfXKWGseLY:gitter.im/$6IhWbfjcTqmLoqAVMopWFuIhlQwsoaIRxmsXhhmsaSs?via=gitter.im&via=matrix.org&via=ekpyron.org
        Execution storage execution = executions[executionsCounter];
        execution.id = executionsCounter;
        execution.process = process;
        execution.proposal = proposal;
        execution.state = State.RUNNING;

        Execution memory _execution = execution;

        _start(_execution); // "Hook" to add logic in start of a concrete implementation.

        emit GovernancePrimitiveStarted(execution, executionId);

        return executionsCounter;
    }
    
    /// @notice If called the proposed actions do get executed.
    /// @dev The state of the container does get changed to EXECUTED, the pre-execute method _execute does get called, and the actions executed.
    /// @param executionId The id of the execution struct.
    function execute(uint256 executionId) public executionExist(executionId) authP(PRIMITIVE_EXECUTE_ROLE) {
        Execution storage execution = _getExecution(executionId);
        
        require(execution.state == State.RUNNING, ERROR_EXECUTION_STATE_WRONG);
        require(
            dao.checkPermission(execution.process.permissions.execute),
            ERROR_NOT_ALLOWED_TO_EXECUTE
        );

        execution.state = State.EXECUTED;

        _execute(execution); // "Hook" to add logic in execute of a concrete implementation

        // Executor(dao.executor.address).execute(execution.proposal.actions);

        emit GovernancePrimitiveExecuted(execution, executionId);
    }

    /// @dev Internal helper and abstraction to get a execution struct.
    /// @param executionId The id of the execution struct.
    function _getExecution(uint256 executionId) internal view returns (Execution storage execution) {
        return executions[executionId];
    }

    /// @dev The concrete implementation of stop.
    /// @param execution The execution struct with all the informations needed.
    function _start(Execution memory execution) internal virtual;

    /// @dev The concrete pre-execution call.
    /// @param execution The execution struct with all the informations needed.
    function _execute(Execution memory execution) internal virtual;
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../lib/permissions/PermissionValidator.sol";
import "../../lib/component/IDAO.sol";
import "../../lib/component/UpgradableComponent.sol";


// TODO: Add update, remove etc. role
/// @title The permissions contract responsible to handle all the governance process related permissions.
/// @author Samuel Furter - Aragon Association - 2021
/// @notice This contract is a central point of the Aragon DAO framework and handles all the permissions and stores the different groups a DAO can have.
contract Permissions is UpgradableComponent {
    
    bytes32 public constant PERMISSIONS_SET_ROLE = keccak256("PERMISSIONS_SET_ROLE");
    bytes32 public constant PERMISSIONS_ADD_VALIDATOR_ROLE = keccak256("PERMISSIONS_ADD_VALIDATOR_ROLE");

    event RoleSet(string indexed role, Permission indexed permission);

    // The operator used to combine the validators accordingly to the the users wish
    enum Operator { 
        OR, 
        AND,
        NAND,
        NOR
    }
   
    // A permission consists out of a logical operator that defines how the set of validators should get interpreted
    struct Permission {
        Operator operator;
        PermissionValidator[] validators; // ERC20Validator, NFTValidator, e.t.c
        bytes[] data;
    }

    // The different permissions to define depending on the type of governance primitive
    struct GovernancePrimitivePermissions {
        string start;
        string execute;
        string halt;
        string forward;
        string stop;
        string vote;
    }

    mapping(string => Permission) public permissions;

    constructor() initializer {}

    /// @dev Used for UUPS upgradability pattern
    /// @param _dao The DAO contract of the current DAO
    function initialize(IDAO _dao) public override initializer {
        Component.initialize(_dao);
    }

    /// @notice Adds a new role based on the permission validations passed.
    /// @dev Here you simple pass the role name and the permission struct with his logical operator and the validators set.
    /// @param role The name of the role as string
    /// @param permission The permission struct to define the permission validation rules
    function setRole(string calldata role, Permission calldata permission) external authP(PERMISSIONS_SET_ROLE) {
        permissions[role] = permission; // Group1 => [AND, ERC20Validator]

        emit RoleSet(role, permission);
    }

    // TODO: This method is not gas efficient
    /// @notice Checks the permissions of the caller.
    /// @dev Based on the stored permission struct does it go through all validators and checks the validity of the caller.
    /// @param role The name of the role as string
    /// @return valid The validity check result returned as bool
    function checkPermission(string calldata role) external view returns (bool valid) {
        PermissionValidator[] memory validators = permissions[role].validators;
        Operator operator = permissions[role].operator;
        bytes[] memory data = permissions[role].data;

        uint256 validatorsLength = validators.length;
        uint8 succeeds = 0;

        for (uint256 i = 0; i < validatorsLength; i++) {
            PermissionValidator validator = validators[i];
            if(PermissionValidator(validator).isValid(msg.sender, data[i])) {
                succeeds += 1;
            }
        }

        if(operator == Operator.AND && succeeds == validatorsLength) {
            return true;
        }

        if(operator == Operator.OR && succeeds >= 1) {
            return true;
        }

        if(operator == Operator.NAND && succeeds < validatorsLength) {
            return true;
        }

        if(operator == Operator.NOR && succeeds == 0) {
           return true;
        }

        return false;
    }

}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../lib/component/UpgradableComponent.sol";
import "../../lib/component/IDAO.sol";

/// @title Implementation of the Executor
/// @author Sarkawt Azad - Aragon Association - 2021
/// @notice This contract represent the execution layer.
contract Executor is UpgradableComponent {

  bytes32 public constant EXEC_ROLE = keccak256("EXEC_ROLE");

  event Executed(
    address indexed actor,
    Action[] indexed actions,
    bytes[] execResults
  );

  string private constant ERROR_ACTION_CALL_FAILED = "EXCECUTOR_ACTION_CALL_FAILED";

  struct Action {
    address to; // Address to call.
    uint256 value; // Value to be sent with the call. for example (ETH)
    bytes data;
  }

  constructor() initializer {}

  /// @dev Used for UUPS upgradability pattern
  /// @param _dao The DAO contract of the current DAO
  function initialize(IDAO _dao) public override initializer {
    Component.initialize(_dao);
  } 

  /// @notice If called, the list of provided actions will be executed.
  /// @dev It run a loop through the array of acctions and execute one by one.
  /// @dev If one acction fails, all will be reverted.
  /// @param actions The aray of actions
  function execute(Action[] memory actions) external authP(EXEC_ROLE) {
    bytes[] memory execResults = new bytes[](actions.length);

    for (uint256 i = 0; i < actions.length; i++) {
      (bool success, bytes memory response) = actions[i].to.call{ value: actions[i].value }(actions[i].data);

      require(success, ERROR_ACTION_CALL_FAILED);

      execResults[i] = response;
    }

    emit Executed(msg.sender, actions, execResults);
  }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

interface IDAO {
    // ACL handling permission
    function hasPermission(address _where, address _who, bytes32 _role, bytes memory data) external returns(bool);
    // DAO Level membershipm permission
    function checkPermission(string calldata role) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../lib/governance-primitives/GovernancePrimitive.sol";
import "./permissions/Permissions.sol";
import "./processes/Processes.sol";
import "./executor/Executor.sol";
import "../lib/component/UpgradableComponent.sol";
import "../lib/acl/ACL.sol";
import "../lib/component/IDAO.sol";

/// @title The public interface of the Aragon DAO framework.
/// @author Samuel Furter - Aragon Association - 2021
/// @notice This contract is the entry point to the Aragon DAO framework and provides our users a simple and use to use public interface.
/// @dev Public API of the Aragon DAO framework
contract DAO is IDAO, Initializable, UUPSUpgradeable, ACL {
    
    bytes32 public constant DAO_CONFIG_ROLE = keccak256("DAO_CONFIG_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");

    event NewProposal(GovernancePrimitive.Proposal indexed proposal, Processes.Process indexed process, address indexed submitter, uint256 executionId);
    event SetMetadata(bytes metadata);

    bytes public metadata;
    Processes public processes;
    Permissions public permissions;
    Executor public executor;

    constructor() initializer {}

    /// @dev Used for UUPS upgradability pattern
    /// @param _metadata IPFS hash that points to all the metadata (logo, description, tags, etc.) of a DAO
    /// @param _processes All the processes a DAO has
    /// @param _permissions All roles a DAO has
    /// @param _executor The executor to interact with any internal or third party contract
    function initialize(
        bytes calldata _metadata,
        Processes _processes,
        Permissions _permissions,
        Executor _executor,
        address _aclRoot
    ) public initializer {
        processes = _processes;
        permissions = _permissions;
        executor = _executor;

        ACL.initACL(_aclRoot);

        emit SetMetadata(_metadata);
    }

    function _authorizeUpgrade(address /*_newImplementation*/) internal virtual override {
        require(willPerform(address(this), msg.sender, UPGRADE_ROLE, msg.data), "auth:check");
    }

    modifier authP(bytes32 role)  {
        require(willPerform(address(this), msg.sender, role, msg.data), "auth: check");
        _;
    }

    function hasPermission(address _where, address _who, bytes32 _role, bytes memory data) public override returns(bool) {
        return willPerform(_where, _who, _role, data);
    }

    function checkPermission(string calldata _role) external view override returns(bool) {
        return permissions.checkPermission(_role);
    }

    /// @notice If called a new governance process based on the submitted proposal does get kicked off
    /// @dev Validates the permissions, validates the actions passed, and start a new process execution based on the proposal.
    /// @param proposal The proposal submission of the user
    /// @return process The started process with his definition
    /// @return executionId The execution id
    function start(GovernancePrimitive.Proposal calldata proposal) external returns (Processes.Process memory process, uint256 executionId) {
        return processes.start(proposal);
    }

    /// @notice If called a executable proposal does get executed.
    /// @dev Some governance primitives needed to be executed with a additional user based call.
    /// @param executionID The executionId
    /// @param governancePrimitive The primitive to call execute.
    function execute(uint256 executionID, GovernancePrimitive governancePrimitive) external {
        GovernancePrimitive(governancePrimitive).execute(executionID);
    }

    /// @notice Update the DAO metadata
    /// @dev Sets a new IPFS hash
    /// @param _metadata The IPFS hash of the new metadata object
    function setMetadata(bytes calldata _metadata) external authP(DAO_CONFIG_ROLE) {
        emit SetMetadata(_metadata);   
    }

    /// @notice Adds a new role to the permission management
    /// @dev Based on the name and the passed Permission struct does a new entry get added in Permissions
    /// @param role The name of the role as string
    /// @param permission The struct defining the logical operator and validators set for this role
    function addRole(string calldata role, Permissions.Permission calldata permission) external authP(DAO_CONFIG_ROLE) {
        permissions.setRole(role, permission);
    }

    /// @notice Adds a new process to the DAO
    /// @dev Based on the name and the passed Process struct does a new entry get added in Processes
    /// @param name The name of the process as string
    /// @param process The struct defining the governance primitive, allowed actions, permissions, and metadata IPFS hash to describe the process 
    function setProcess(string calldata name, Processes.Process calldata process) external authP(DAO_CONFIG_ROLE) {
        processes.setProcess(name, process);
    }

    /// @notice Sets a new executor address in case it needs to get replaced at all
    /// @dev Updates the executor contract property
    /// @param _executor The address of the new executor
    function setExecutor(Executor _executor) external authP(DAO_CONFIG_ROLE) {
        executor = _executor;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TimeHelpers.sol";
import "./IDAO.sol";

abstract contract Component is TimeHelpers {
    IDAO internal dao;
    
    function initialize(IDAO _dao) public virtual  {
        dao = _dao;
    }

    modifier authP(bytes32 role)  {
        require(dao.hasPermission(address(this), msg.sender, role, msg.data), "auth: check");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Abstract implementation of the permission validator
/// @author Samuel Furter - Aragon Association - 2021
/// @notice This contract can be used to implement concrete permission validators and being fully compatible with the DAO framework and UI of Aragon
/// @dev You only have to define the specific custom logic for your needs in isValid
abstract contract PermissionValidator {
      /// @notice The method to initialize the validator.
      /// @dev Inherited contracts can override this and implement their own initialization logic.
      /// @param data The encoded data that each inherited contract decodes.
      function initialize(bytes memory data) external virtual {}
      /// @notice The method to validate a user permission.
      /// @dev The state of the container does get changed to RUNNING, the execution struct gets created, and the concrete implementation in _start called.
      /// @param caller The caler of this contract
      /// @return valid Returns a bool depending on the validity of the permission
      function isValid(address caller, bytes memory data) external view virtual returns(bool valid);
}

/*
 * SPDX-License-Identifier:    MIT
 */


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Component.sol";

abstract contract UpgradableComponent is Component, UUPSUpgradeable, Initializable {

    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    
    function _authorizeUpgrade(address /*_newImplementation*/) internal virtual override authP(UPGRADE_ROLE) {
    
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

import "./Uint256Helpers.sol";

contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

library Uint256Helpers {
    uint256 private constant MAX_UINT64 = type(uint64).max;

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

// import "../initializable/Initializable.sol";
import "./IACLOracle.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library ACLData {
    enum BulkOp { Grant, Revoke, Freeze }

    struct BulkItem {
        BulkOp op;
        bytes4 role;
        address who;
    }
}

contract ACL is Initializable {
    bytes32 public constant ROOT_ROLE =
        this.grant.selector
        ^ this.revoke.selector
        ^ this.freeze.selector
        ^ this.bulk.selector
    ;

    // "Who" constants
    address internal constant ANY_ADDR = address(type(uint160).max);

    // "Access" flags
    address internal constant UNSET_ROLE = address(0);
    address internal constant FREEZE_FLAG = address(1); // Also used as "who"
    address internal constant ALLOW_FLAG = address(2);
        
    // hash(where, who, role) => Access flag(unset or allow) or ACLOracle (any other address denominates auth via ACLOracle)
    mapping (bytes32 => address) internal authPermissions;
    // hash(where, role) => true(role froze on the where), false(role is not frozen on the where)
    mapping (bytes32 => bool) internal freezePermissions;

    event Granted(bytes32 indexed role, address indexed actor, address indexed who, address where, IACLOracle oracle);
    event Revoked(bytes32 indexed role, address indexed actor, address indexed who, address where);
    event Frozen(bytes32 indexed role, address indexed actor, address where);

    modifier auth(address _where, bytes32 _role) {
        require(willPerform(_where, msg.sender, _role, msg.data), "acl: auth");
        _;
    }

    function initACL(address _who) internal initializer {
        _initializeACL(address(this),  _who);
    }
    
    function grant(address _where, address _who, bytes32 _role) external auth(_where, ROOT_ROLE) {
        _grant(_where, _who, _role);
    }

    function grantWithOracle(address _where, address _who, bytes32 _role, IACLOracle _oracle) external auth(_where, ROOT_ROLE) {
        _grantWithOracle(_where, _who, _role, _oracle);
    }

    function revoke(address _where, address _who, bytes32 _role) external auth(_where, ROOT_ROLE) {
        _revoke(_where, _who, _role);
    }

    function freeze(address _where, bytes32 _role) external auth(_where, ROOT_ROLE) {
        _freeze(_where, _role);
    }

    function bulk(address _where, ACLData.BulkItem[] calldata items) external auth(_where, ROOT_ROLE) {
        for (uint256 i = 0; i < items.length; i++) {
            ACLData.BulkItem memory item = items[i];

            if (item.op == ACLData.BulkOp.Grant) _grant(_where, item.who, item.role);
            else if (item.op == ACLData.BulkOp.Revoke) _revoke(_where, item.who, item.role);
            else if (item.op == ACLData.BulkOp.Freeze) _freeze(_where, item.role);
        }
    }

    function willPerform(address _where, address _who, bytes32 _role, bytes memory _data) internal returns (bool) {
        return _checkRole(_where, _who, _role, _data) // check if _who is eligible for _role on _where
            || _checkRole(_where, ANY_ADDR, _role, _data) // check if anyone is eligible for _role on _where
            || _checkRole(ANY_ADDR, _who, _role, _data); // check if _who is eligible for _role on any contract.
    }

    function isFrozen(address _where, bytes32 _role) public view returns (bool) {
        return freezePermissions[freezeHash(_where, _role)];
    }

    function _initializeACL(address _where, address _who) internal {
        _grant(_where, _who, ROOT_ROLE);
    }

    function _grant(address _where, address _who, bytes32 _role) internal {
        _grantWithOracle(_where, _who, _role, IACLOracle(ALLOW_FLAG));
    }

    function _grantWithOracle(address _where, address _who, bytes32 _role, IACLOracle _oracle) internal {
        require(!isFrozen(_where, _role), "acl: frozen");

        bytes32 permission = permissionHash(_where, _who, _role);
        require(authPermissions[permission] == UNSET_ROLE, "acl: role already granted");
        authPermissions[permission] = address(_oracle);

        emit Granted(_role, msg.sender, _who, _where, _oracle);
    }

    function _revoke(address _where, address _who, bytes32 _role) internal {
        require(!isFrozen(_where, _role), "acl: frozen");

        bytes32 permission = permissionHash(_where, _who, _role);
        require(authPermissions[permission] != UNSET_ROLE, "acl: role already revoked");
        authPermissions[permission] = UNSET_ROLE;

        emit Revoked(_role, msg.sender, _who, _where);
    }

    function _freeze(address _where, bytes32 _role) internal {
        require(!isFrozen(_where,_role), "acl: frozen");

        bytes32 permission = freezeHash(_where, _role);
        require(!freezePermissions[permission], "acl: role already freeze");
        freezePermissions[freezeHash(_where, _role)] = true;

        emit Frozen(_role, msg.sender, _where);
    }

    function _checkRole(address _where, address _who, bytes32 _role, bytes memory _data) internal returns (bool) {
        address accessFlagOrAclOracle = authPermissions[permissionHash(_where, _who, _role)];
        
        if (accessFlagOrAclOracle != UNSET_ROLE) return false;
        if (accessFlagOrAclOracle == ALLOW_FLAG) return true;

        // Since it's not a flag, assume it's an ACLOracle and try-catch to skip failures
        try IACLOracle(accessFlagOrAclOracle).willPerform(_where, _who, _role, _data) returns (bool allowed) {
            if (allowed) return true;
        } catch { }
        
        return false;
    }

    function permissionHash(address _where, address _who, bytes32 _role) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("PERMISSION", _who, _where, _role));
    }

    function freezeHash(address _where, bytes32 _role) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("FREEZE", _where, _role));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.0;

interface IACLOracle {
    function willPerform(address where, address who, bytes32 role, bytes calldata data) external returns (bool allowed);
}