// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;

import "Pausable.sol";

import "Ownable.sol";
import "CoboSafeModule.sol";

contract CoboSafeFactory is TransferOwnable, Pausable {
    string public constant NAME = "Cobo Safe Factory";
    string public constant VERSION = "0.2.2";

    address[] public modules;
    mapping(address => address) public safeToModule;

    event NewModule(
        address indexed safe,
        address indexed module,
        address indexed sender
    );

    function modulesSize() public view returns (uint256) {
        return modules.length;
    }

    function createModule(address _safe)
        external
        whenNotPaused
        returns (address _module)
    {
        require(safeToModule[_safe] == address(0), "Module already created");
        bytes memory bytecode = type(CoboSafeModule).creationCode;
        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(_safe)
        );
        uint256 moduleIndex = modulesSize();
        bytes32 salt = keccak256(abi.encodePacked(address(this), moduleIndex));

        assembly {
            _module := create2(
                0,
                add(creationCode, 32),
                mload(creationCode),
                salt
            )
        }
        require(_module != address(0), "Failed to create module");
        modules.push(_module);
        safeToModule[_safe] = _module;

        emit NewModule(_safe, _module, _msgSender());
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract TransferOwnable is Ownable {
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "EnumerableSet.sol";
import "GnosisSafe.sol";
import "Ownable.sol";

/// @title A GnosisSafe module that implements Cobo's role based access control policy
/// @author Cobo Safe Dev Team ([email protected])
/// @notice Use this module to access Gnosis Safe with role based access control policy
/// @dev This contract implements the core data structure and its related features.
contract CoboSafeModule is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "Cobo Safe Module";
    string public constant VERSION = "0.2.2";

    // Below are predefined roles: ROLE_HARVESTER
    //
    // Gnosis safe owners need to call to `grantRole(ROLE_XXX, delegate)` to grant permission to a delegate.

    // 'harvesters\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    bytes32 public constant ROLE_HARVESTER =
        0x6861727665737465727300000000000000000000000000000000000000000000;

    /// @notice Event fired when a delegate is added
    /// @dev Event fired when a delegate is added via `grantRole` method
    /// @param delegate the delegate being added
    /// @param sender the owner who added the delegate
    event DelegateAdded(address indexed delegate, address indexed sender);

    /// @notice Event fired when a delegate is removed
    /// @dev Event fired when a delegate is remove via `revokeRole` method
    /// @param delegate the delegate being removed
    /// @param sender the owner who removed the delegate
    event DelegateRemoved(address indexed delegate, address indexed sender);

    /// @notice Event fired when a role is added
    /// @dev Event fired when a role is being added via `addRole` method
    /// @param role the role being added
    /// @param sender the owner who added the role
    event RoleAdded(bytes32 indexed role, address indexed sender);

    /// @notice Event fired when a role is grant to a delegate
    /// @dev Event fired when a role is grant to a delegate via `grantRole`
    /// @param role the role being granted
    /// @param delegate the delegate being granted the given role
    /// @param sender the owner who granted the role to the given delegate
    event RoleGranted(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    /// @notice Event fired when a role is revoked from a delegate
    /// @dev Event fired when a role is revoked from a delegate via `revokeRole`
    /// @param role the role being revoked
    /// @param delegate the delegate being revoked the given role
    /// @param sender the owner who revoked the role from the given delegate
    event RoleRevoked(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    /// @notice Event fired after a transaction is successfully executed by a delegate
    /// @dev Event fired after a transaction is successfully executed by a delegate via `execTransaction` method
    /// @param to the targate contract to execute the transaction
    /// @param value the ether value to be sent to the target contract when executing the transaction
    /// @param operation use `call` or `delegatecall` to execute the transaction on the contract
    /// @param data input data to execute the transaction on the given contract
    /// @param sender the delegate who execute the transaction
    event ExecTransaction(
        address indexed to,
        uint256 value,
        Enum.Operation operation,
        bytes data,
        address indexed sender
    );

    /// @notice Event fired when a role is associated with a contract and its function list
    /// @dev Event fired when a role is associated with a contract and its function list via `assocRoleWithContractFuncs`
    /// @param role the role to be associated with the given contract and function list
    /// @param _contract the target contract to be associated with the role
    /// @param funcList a list of function signatures of the given contract to be associated with the role
    /// @param sender the owner who associated the role with the contract and its function list
    event AssocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    /// @notice Event fired when a role is disassociate from a contract and its function list
    /// @dev Event fired when a role is disassociate from a contract and its function list via `dissocRoleFromContractFuncs`
    /// @param role the role to be disassociated from the given contract and function list
    /// @param _contract the target contract to be disassociated from the role
    /// @param funcList a list of function signatures of the given contract to be disassociated from the role
    /// @param sender the owner who disassociated the role from the contract and its function list
    event DissocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    /// @dev Tracks the set of granted delegates. The set is dynamically added
    ///      to or removed from by  `grantRole` and `rokeRole`.  `isDelegate`
    ///      also uses it to test if a caller is a valid delegate or not
    EnumerableSet.AddressSet delegateSet;

    /// @dev Tracks what roles each delegate owns. The mapping is dynamically
    ///      added to or removed from by  `grantRole` and `rokeRole`. `hasRole`
    ///      also uses it to test if a delegate is granted a given role or not
    mapping(address => EnumerableSet.Bytes32Set) delegateToRoles;

    /// @dev Tracks the set of roles. The set keeps track of all defined roles.
    ///      It is updated by `addRole`, and possibly by `removeRole` if to be
    ///      supported. All role based access policy checks against the set for
    ///      role validity.
    EnumerableSet.Bytes32Set roleSet;

    /// @dev Tracks the set of contract address. The set keeps track of contracts
    ///      which have been associated with a role. It is updated by
    ///      `assocRoleWithContractFuncs` and `dissocRoleFromContractFuncs`
    EnumerableSet.AddressSet contractSet;

    /// @dev mapping from `contract address` => `function selectors`
    mapping(address => EnumerableSet.Bytes32Set) contractToFuncs;

    /// @dev mapping from `contract address` => `function selectors` => `list of roles`
    mapping(address => mapping(bytes32 => EnumerableSet.Bytes32Set)) funcToRoles;

    /// @dev modifier to assert only delegate is allow to proceed
    modifier onlyDelegate() {
        require(isDelegate(_msgSender()), "must be delegate");
        _;
    }

    /// @dev modifier to assert the given role must be predefined
    /// @param role the role to be checked
    modifier roleDefined(bytes32 role) {
        require(roleSet.contains(role), "unrecognized role");
        _;
    }

    /// @notice Contructor function for CoboSafeModule
    /// @dev When this module is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance. The instance is
    ///      supposed to call `enableModule` on the constructed module instance
    ///      in order for it to function properly.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    constructor(address payable _safe) {
        require(_safe != address(0), "invalid safe address");

        // Add default role. Use `addRole` to make sure `RoleAdded` event is fired
        addRole(ROLE_HARVESTER);

        // make the given safe the owner of the current module.
        _transferOwnership(_safe);
    }

    /// @notice Checks if an address is a permitted delegate
    /// @dev the address must have been granted role via `grantRole` in order to become a delegate
    /// @param delegate the address to be checked
    /// @return true|false
    function isDelegate(address delegate) public view returns (bool) {
        return delegateSet.contains(delegate);
    }

    /// @notice Grant a role to a delegate
    /// @dev Granting a role to a delegate will give delegate permission to call
    ///      contract functions associated with the role. Only owner can grant
    ///      role and the must be predefined and not granted to the delegate
    ///      already. on success, `RoleGranted` event would be fired and
    ///      possibly `DelegateAdded` as well if this is the first role being
    ///      granted to the delegate.
    /// @param role the role to be granted
    /// @param delegate the delegate to be granted role
    function grantRole(bytes32 role, address delegate)
        external
        onlyOwner
        roleDefined(role)
    {
        require(!_hasRole(role, delegate), "role already granted");

        delegateToRoles[delegate].add(role);

        // We need to emit `DelegateAdded` before `RoleGranted` to allow
        // subgraph event handler to process in sensible order.
        if (delegateSet.add(delegate)) {
            emit DelegateAdded(delegate, _msgSender());
        }

        emit RoleGranted(role, delegate, _msgSender());
    }

    /// @notice Revoke a role from a delegate
    /// @dev Revoking a role from a delegate will remove the permission the
    ///      delegate has to call contract functions associated with the role.
    ///      Only owner can revoke the role.  The role has to be predefined and
    ///      granted to the delegate before revoking, otherwise the function
    ///      will be reverted. `RoleRevoked` event would be fired and possibly
    ///      `DelegateRemoved` as well if this is the last role the delegate
    ///      owns.
    /// @param role the role to be granted
    /// @param delegate the delegate to be granted role
    function revokeRole(bytes32 role, address delegate)
        external
        onlyOwner
        roleDefined(role)
    {
        require(_hasRole(role, delegate), "role has not been granted");

        delegateToRoles[delegate].remove(role);

        // We need to make sure `RoleRevoked` is fired before `DelegateRemoved`
        // to make sure the event handlers in subgraphs are triggered in the
        // right order.
        emit RoleRevoked(role, delegate, _msgSender());

        if (delegateToRoles[delegate].length() == 0) {
            delegateSet.remove(delegate);
            emit DelegateRemoved(delegate, _msgSender());
        }
    }

    /// @notice Test if a delegate has a role
    /// @dev The role has be predefined or the function will be reverted.
    /// @param role the role to be checked
    /// @param delegate the delegate to be checked
    /// @return true|false
    function hasRole(bytes32 role, address delegate)
        external
        view
        roleDefined(role)
        returns (bool)
    {
        return _hasRole(role, delegate);
    }

    /// @notice Test if a delegate has a role (internal version)
    /// @dev This does the same check as hasRole, but avoid the checks on if the
    ///      role is defined. Internal functions can call this to save gas consumptions
    /// @param role the role to be checked
    /// @param delegate the delegate to be checked
    /// @return true|false
    function _hasRole(bytes32 role, address delegate)
        internal
        view
        returns (bool)
    {
        return delegateToRoles[delegate].contains(role);
    }

    /// @notice Add a new role
    /// @dev only owner can call this function, the role has to be a new role.
    ///      On success, `RoleAdded` event will be fired
    /// @param role the role to be added
    function addRole(bytes32 role) public onlyOwner {
        require(!roleSet.contains(role), "role exists");

        roleSet.add(role);

        emit RoleAdded(role, _msgSender());
    }

    /// @notice Call Gnosis Safe to execute a transaction
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract method `to`::`func`, where `func`
    ///      is the function selector contained in first 4 bytes of `data`.
    ///      The function can only be called by delegates.
    /// @param to The target contract to be called by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    ///
    /// TODO: implement EIP712 signature.
    function execTransaction(address to, bytes calldata data)
        external
        onlyDelegate
    {
        _execTransaction(to, data);
    }

    /// @notice Batch execute multiple transaction via Gnosis Safe
    /// @dev This is batch version of the `execTransaction` function to allow
    ///      the delegates to bundle multiple calls into a single transaction and
    ///      sign only once. Batch execute the transactions, one failure cause the
    ///      batch reverted. Only delegates are allowed to call this.
    /// @param toList list of contract addresses to be called
    /// @param dataList list of input data associated with each contract call
    function batchExecTransactions(
        address[] calldata toList,
        bytes[] calldata dataList
    ) external onlyDelegate {
        require(
            toList.length > 0 && toList.length == dataList.length,
            "invalid inputs"
        );

        for (uint256 i = 0; i < toList.length; i++) {
            _execTransaction(toList[i], dataList[i]);
        }
    }

    /// @dev The internal implementation of `execTransaction` and
    ///      `batchExecTransactions`, that invokes gnosis safe to forward to
    ///      transaction to target contract method `to`::`func`, where `func` is
    ///      the function selector contained in first 4 bytes of `data`.  The
    ///      function checks if the calling delegate has the required permission
    ///      to call the designated contract function before invoking Gnosis
    ///      Safe.
    /// @param to The target contract to be called by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    function _execTransaction(address to, bytes memory data) internal {
        bytes4 selector;
        assembly {
            selector := mload(add(data, 0x20))
        }

        require(
            _hasPermission(_msgSender(), to, selector),
            "permission denied"
        );

        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        require(
            GnosisSafe(payable(owner())).execTransactionFromModule(
                to,
                0,
                data,
                Enum.Operation.Call
            ),
            "failed in execution in safe"
        );

        emit ExecTransaction(to, 0, Enum.Operation.Call, data, _msgSender());
    }

    /// @dev Internal function to check if a delegate has the permission to call a given contract function
    /// @param delegate the delegate to be checked
    /// @param to the target contract
    /// @param selector the function selector of the contract function to be called
    /// @return true|false
    function _hasPermission(
        address delegate,
        address to,
        bytes4 selector
    ) internal view returns (bool) {
        bytes32[] memory roles = getRolesByDelegate(delegate);
        EnumerableSet.Bytes32Set storage funcRoles = funcToRoles[to][selector];
        for (uint256 index = 0; index < roles.length; index++) {
            if (funcRoles.contains(roles[index])) {
                return true;
            }
        }
        return false;
    }

    /// @dev Public function to check if a delegate has the permission to call a given contract function
    /// @param delegate the delegate to be checked
    /// @param to the target contract
    /// @param selector the function selector of the contract function to be called
    /// @return true|false
    function hasPermission(
        address delegate,
        address to,
        bytes4 selector
    ) external view returns (bool) {
        if (!isDelegate(delegate)) {
            return false;
        }

        return _hasPermission(delegate, to, selector);
    }

    /// @notice Associate a role with given contract funcs
    /// @dev only owners are allowed to call this function, the given role has
    ///      to be predefined. On success, the role will be associated with the
    ///      given contract function, `AssocContractFuncs` event will be fired.
    /// @param role the role to be associated
    /// @param _contract the contract address to be associated with the role
    /// @param funcList the list of contract functions to be associated with the role
    function assocRoleWithContractFuncs(
        bytes32 role,
        address _contract,
        string[] calldata funcList
    ) external onlyOwner roleDefined(role) {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            funcToRoles[_contract][funcSelector32].add(role);
            contractToFuncs[_contract].add(funcSelector32);
        }

        contractSet.add(_contract);

        emit AssocContractFuncs(role, _contract, funcList, _msgSender());
    }

    /// @notice Dissociate a role from given contract funcs
    /// @dev only owners are allowed to call this function, the given role has
    ///      to be predefined. On success, the role will be disassociated from
    ///      the given contract function, `DissocContractFuncs` event will be
    ///      fired.
    /// @param role the role to be disassociated
    /// @param _contract the contract address to be disassociated from the role
    /// @param funcList the list of contract functions to be disassociated from the role
    function dissocRoleFromContractFuncs(
        bytes32 role,
        address _contract,
        string[] calldata funcList
    ) external onlyOwner roleDefined(role) {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            funcToRoles[_contract][funcSelector32].remove(role);

            if (funcToRoles[_contract][funcSelector32].length() <= 0) {
                contractToFuncs[_contract].remove(funcSelector32);
            }
        }

        if (contractToFuncs[_contract].length() <= 0) {
            contractSet.remove(_contract);
        }

        emit DissocContractFuncs(role, _contract, funcList, _msgSender());
    }

    /// @notice Get all the delegates who are currently granted any role
    /// @return list of delegate addresses
    function getAllDelegates() public view returns (address[] memory) {
        bytes32[] memory store = delegateSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a delegate, return all the roles granted to the delegate
    /// @return list of roles
    function getRolesByDelegate(address delegate)
        public
        view
        returns (bytes32[] memory)
    {
        return delegateToRoles[delegate]._inner._values;
    }

    /// @notice Get all the roles defined in the module
    /// @return list of roles
    function getAllRoles() external view returns (bytes32[] memory) {
        return roleSet._inner._values;
    }

    /// @notice Get all the contracts ever associated with any role
    /// @return list of contract addresses
    function getAllContracts() public view returns (address[] memory) {
        bytes32[] memory store = contractSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a contract, list all the function selectors of this contract associated with a role
    /// @param _contract the contract
    /// @return list of function selectors in the contract ever associated with a role
    function getFuncsByContract(address _contract)
        public
        view
        returns (bytes4[] memory)
    {
        bytes32[] memory store = contractToFuncs[_contract]._inner._values;
        bytes4[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a function, list all the roles that have permission to access to them
    /// @param _contract the contract address
    /// @param funcSelector the function selector
    /// @return list of roles
    function getRolesByContractFunction(address _contract, bytes4 funcSelector)
        public
        view
        returns (bytes32[] memory)
    {
        return funcToRoles[_contract][funcSelector]._inner._values;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);
}