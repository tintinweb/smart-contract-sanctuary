// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "./Permissions.sol";

contract Roles is Modifier {
    address public multiSend;

    mapping(address => uint16) public defaultRoles;
    mapping(uint16 => Role) internal roles;

    event AssignRoles(address module, uint16[] roles);
    event SetMulitSendAddress(address multiSendAddress);

    event AllowTarget(
        uint16 role,
        address targetAddress,
        bool canSend,
        bool canDelegate
    );
    event AllowTargetPartially(
        uint16 role,
        address targetAddress,
        bool canSend,
        bool canDelegate
    );
    event RevokeTarget(uint16 role, address targetAddress);

    event ScopeAllowFunction(
        uint16 role,
        address targetAddress,
        bytes4 selector
    );
    event ScopeRevokeFunction(
        uint16 role,
        address targetAddress,
        bytes4 selector
    );
    event ScopeFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        bool[] paramIsScoped,
        bool[] paramIsDynamic,
        Comparison[] paramCompType,
        bytes[] paramCompValue
    );

    event ScopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex,
        bool isDynamic,
        Comparison compType,
        bytes compValue
    );
    event ScopeParameterAsOneOf(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex,
        bool isDynamic,
        bytes[] compValues
    );
    event UnscopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex
    );

    event RolesModSetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address target
    );
    event SetDefaultRole(address module, uint16 defaultRole);

    /// `setUpModules` has already been called
    error SetUpModulesAlreadyCalled();

    /// Arrays must be the same length
    error ArraysDifferentLength();

    /// Sender is not a member of the role
    error NoMembership();

    /// Sender is allowed to make this call, but the internal transaction failed
    error ModuleTransactionFailed();

    /// @param _owner Address of the owner
    /// @param _avatar Address of the avatar (e.g. a Gnosis Safe)
    /// @param _target Address of the contract that will call exec function
    constructor(
        address _owner,
        address _avatar,
        address _target
    ) {
        bytes memory initParams = abi.encode(_owner, _avatar, _target);
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public override {
        (address _owner, address _avatar, address _target) = abi.decode(
            initParams,
            (address, address, address)
        );
        __Ownable_init();

        avatar = _avatar;
        target = _target;

        transferOwnership(_owner);
        setupModules();

        emit RolesModSetup(msg.sender, _owner, _avatar, _target);
    }

    function setupModules() internal {
        if (modules[SENTINEL_MODULES] != address(0)) {
            revert SetUpModulesAlreadyCalled();
        }
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    /// @dev Set the address of the expected multisend library
    /// @notice Only callable by owner.
    /// @param _multiSend address of the multisend library contract
    function setMultiSend(address _multiSend) external onlyOwner {
        multiSend = _multiSend;
        emit SetMulitSendAddress(multiSend);
    }

    /// @dev Allows all calls made to an address.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param canSend allows/disallows whether or not a target address can be sent to (incluces fallback/receive functions).
    /// @param canDelegate allows/disallows whether or not delegate calls can be made to a target address.
    function allowTarget(
        uint16 role,
        address targetAddress,
        bool canSend,
        bool canDelegate
    ) external onlyOwner {
        roles[role].targets[targetAddress] = TargetAddress(
            Clearance.TARGET,
            canSend,
            canDelegate
        );
        emit AllowTarget(role, targetAddress, canSend, canDelegate);
    }

    /// @dev Partially allows calls to a Target - subject to function scoping rules.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Address to be allowed
    /// @param canSend allows/disallows whether or not a target address can be sent to (incluces fallback/receive functions).
    /// @param canDelegate allows/disallows whether or not delegate calls can be made to a target address.
    function allowTargetPartially(
        uint16 role,
        address targetAddress,
        bool canSend,
        bool canDelegate
    ) external onlyOwner {
        roles[role].targets[targetAddress] = TargetAddress(
            Clearance.FUNCTION,
            canSend,
            canDelegate
        );
        emit AllowTargetPartially(role, targetAddress, canSend, canDelegate);
    }

    /// @dev Disallows all calls made to an address.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Address to be disallowed
    function revokeTarget(uint16 role, address targetAddress)
        external
        onlyOwner
    {
        roles[role].targets[targetAddress] = TargetAddress(
            Clearance.NONE,
            false,
            false
        );
        emit RevokeTarget(role, targetAddress);
    }

    /// @dev Allows a specific function, on a specific address, to be called.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Scoped address on which a function signature should be allowed/disallowed.
    /// @param functionSig Function signature to be allowed/disallowed.
    function scopeAllowFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig
    ) external onlyOwner {
        Permissions.scopeAllowFunction(roles[role], targetAddress, functionSig);
        emit ScopeAllowFunction(role, targetAddress, functionSig);
    }

    /// @dev Disallows a specific function, on a specific address from being called.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Scoped address on which a function signature should be allowed/disallowed.
    /// @param functionSig Function signature to be allowed/disallowed.
    function scopeRevokeFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig
    ) external onlyOwner {
        Permissions.scopeRevokeFunction(
            roles[role],
            targetAddress,
            functionSig
        );
        emit ScopeRevokeFunction(role, targetAddress, functionSig);
    }

    /// @dev Sets and enforces scoping for an allowed function, on a specific address
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Address to be scoped/unscoped.
    /// @param functionSig first 4 bytes of the sha256 of the function signature.
    /// @param isParamScoped false for un-scoped, true for scoped.
    /// @param isParamDynamic false for static, true for dynamic.
    /// @param paramCompType Any, or EqualTo, GreaterThan, or LessThan compValue.
    function scopeFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        bool[] calldata isParamScoped,
        bool[] calldata isParamDynamic,
        Comparison[] calldata paramCompType,
        bytes[] calldata paramCompValue
    ) external onlyOwner {
        Permissions.scopeFunction(
            roles[role],
            targetAddress,
            functionSig,
            isParamScoped,
            isParamDynamic,
            paramCompType,
            paramCompValue
        );
        emit ScopeFunction(
            role,
            targetAddress,
            functionSig,
            isParamScoped,
            isParamDynamic,
            paramCompType,
            paramCompValue
        );
    }

    /// @dev Sets and enforces scoping for a single parameter on an allowed function
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Address to be scoped/unscoped.
    /// @param functionSig first 4 bytes of the sha256 of the function signature.
    /// @param paramIndex the index of the parameter to scope
    /// @param isDynamic false for value, true for dynamic.
    /// @param compType Any, or EqualTo, GreaterThan, or LessThan compValue.
    /// @param compValue The reference value used while comparing and authorizing
    function scopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex,
        bool isDynamic,
        Comparison compType,
        bytes calldata compValue
    ) external onlyOwner {
        Permissions.scopeParameter(
            roles[role],
            targetAddress,
            functionSig,
            paramIndex,
            isDynamic,
            compType,
            compValue
        );
        emit ScopeParameter(
            role,
            targetAddress,
            functionSig,
            paramIndex,
            isDynamic,
            compType,
            compValue
        );
    }

    /// @dev Sets and enforces scoping of type OneOf for a single parameter on an allowed function
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Address to be scoped/unscoped.
    /// @param functionSig first 4 bytes of the sha256 of the function signature.
    /// @param paramIndex the index of the parameter to scope
    /// @param isDynamic false for value, true for dynamic.
    /// @param compValues The reference values used while comparing and authorizing
    function scopeParameterAsOneOf(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex,
        bool isDynamic,
        bytes[] calldata compValues
    ) external onlyOwner {
        Permissions.scopeParameterAsOneOf(
            roles[role],
            targetAddress,
            functionSig,
            paramIndex,
            isDynamic,
            compValues
        );
        emit ScopeParameterAsOneOf(
            role,
            targetAddress,
            functionSig,
            paramIndex,
            isDynamic,
            compValues
        );
    }

    /// @dev Unsets scoping for a single parameter on an allowed function
    /// @notice Only callable by owner.
    /// @notice If no parameter remains scoped after this call, access to the function is revoked.
    /// @param role Role to set for.
    /// @param targetAddress Address to be scoped/unscoped.
    /// @param functionSig first 4 bytes of the sha256 of the function signature.
    /// @param paramIndex the index of the parameter to scope
    function unscopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex
    ) external onlyOwner {
        Permissions.unscopeParameter(
            roles[role],
            targetAddress,
            functionSig,
            paramIndex
        );
        emit UnscopeParameter(role, targetAddress, functionSig, paramIndex);
    }

    /// @dev Assigns and revokes roles to a given module.
    /// @param module Module on which to assign/revoke roles.
    /// @param _roles Roles to assign/revoke.
    /// @param memberOf Assign (true) or revoke (false) corresponding _roles.
    function assignRoles(
        address module,
        uint16[] calldata _roles,
        bool[] calldata memberOf
    ) external onlyOwner {
        if (_roles.length != memberOf.length) {
            revert ArraysDifferentLength();
        }
        for (uint16 i = 0; i < _roles.length; i++) {
            roles[_roles[i]].members[module] = memberOf[i];
        }
        if (!isModuleEnabled(module)) {
            enableModule(module);
        }
        emit AssignRoles(module, _roles);
    }

    /// @dev Sets the default role used for a module if it calls execTransactionFromModule() or execTransactionFromModuleReturnData().
    /// @param module Address of the module on which to set default role.
    /// @param role Role to be set as default.
    function setDefaultRole(address module, uint16 role) external onlyOwner {
        defaultRoles[module] = role;
        emit SetDefaultRole(module, role);
    }

    /// @dev Passes a transaction to the modifier.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public override moduleOnly returns (bool success) {
        checkPermission(to, value, data, operation, defaultRoles[msg.sender]);
        return exec(to, value, data, operation);
    }

    /// @dev Passes a transaction to the modifier, expects return data.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public override moduleOnly returns (bool, bytes memory) {
        checkPermission(to, value, data, operation, defaultRoles[msg.sender]);
        return execAndReturnData(to, value, data, operation);
    }

    /// @dev Passes a transaction to the modifier assuming the specified role. Reverts if the passed transaction fails.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param role Identifier of the role to assume for this transaction.
    /// @notice Can only be called by enabled modules
    function execTransactionWithRole(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint16 role,
        bool shouldRevert
    ) public moduleOnly returns (bool success) {
        checkPermission(to, value, data, operation, role);
        success = exec(to, value, data, operation);
        if (shouldRevert && !success) {
            revert ModuleTransactionFailed();
        }
    }

    /// @dev Passes a transaction to the modifier assuming the specified role. expects return data.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param role Identifier of the role to assume for this transaction.
    /// @notice Can only be called by enabled modules
    function execTransactionWithRoleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint16 role,
        bool shouldRevert
    ) public moduleOnly returns (bool success, bytes memory returnData) {
        checkPermission(to, value, data, operation, role);
        (success, returnData) = execAndReturnData(to, value, data, operation);
        if (shouldRevert && !success) {
            revert ModuleTransactionFailed();
        }
    }

    function checkPermission(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint16 role
    ) internal view {
        Role storage _role = roles[role];

        if (!_role.members[msg.sender]) {
            revert NoMembership();
        }
        if (to == multiSend) {
            Permissions.checkMultisendTransaction(_role, data);
        } else {
            Permissions.checkTransaction(_role, to, value, data, operation);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Modifier Interface - A contract that sits between a Aodule and an Avatar and enforce some additional logic.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "./Module.sol";

abstract contract Modifier is Module {
    event EnabledModule(address module);
    event DisabledModule(address module);

    address internal constant SENTINEL_MODULES = address(0x1);

    // Mapping of modules
    mapping(address => address) internal modules;

    /*
    --------------------------------------------------
    You must override at least one of following two virtual functions,
    execTransactionFromModule() and execTransactionFromModuleReturnData().
    */

    /// @dev Passes a transaction to the modifier.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public virtual moduleOnly returns (bool success) {}

    /// @dev Passes a transaction to the modifier, expects return data.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    )
        public
        virtual
        moduleOnly
        returns (bool success, bytes memory returnData)
    {}

    /*
    --------------------------------------------------
    */

    modifier moduleOnly() {
        require(modules[msg.sender] != address(0), "Module not authorized");
        _;
    }

    /// @dev Disables a module on the modifier
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed
    /// @notice This can only be called by the owner
    function disableModule(address prevModule, address module)
        public
        onlyOwner
    {
        require(
            module != address(0) && module != SENTINEL_MODULES,
            "Invalid module"
        );
        require(modules[prevModule] == module, "Module already disabled");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Enables a module that can add transactions to the queue
    /// @param module Address of the module to be enabled
    /// @notice This can only be called by the owner
    function enableModule(address module) public onlyOwner {
        require(
            module != address(0) && module != SENTINEL_MODULES,
            "Invalid module"
        );
        require(modules[module] == address(0), "Module already enabled");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address _module) public view returns (bool) {
        return SENTINEL_MODULES != _module && modules[_module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next)
    {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (
            currentModule != address(0x0) &&
            currentModule != SENTINEL_MODULES &&
            moduleCount < pageSize
        ) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

enum Clearance {
    NONE,
    TARGET,
    FUNCTION
}

enum Comparison {
    EqualTo,
    GreaterThan,
    LessThan,
    OneOf
}

struct TargetAddress {
    Clearance clearance;
    bool canSend;
    bool canDelegate;
}

struct Role {
    mapping(address => bool) members;
    mapping(address => TargetAddress) targets;
    mapping(bytes32 => uint256) functions;
    mapping(bytes32 => bytes32) compValues;
    mapping(bytes32 => bytes32[]) compValuesOneOf;
}

library Permissions {
    uint256 internal constant SCOPE_WILDCARD = 2**256 - 1;
    // 62 bit mask
    uint256 internal constant IS_SCOPED_MASK =
        uint256(0x3fffffffffffffff << (62 + 124));

    /// Arrays must be the same length
    error ArraysDifferentLength();

    /// Function signature too short
    error FunctionSignatureTooShort();

    /// Role not allowed to delegate call to target address
    error DelegateCallNotAllowed();

    /// Role not allowed to call target address
    error TargetAddressNotAllowed();

    /// Role not allowed to call this function on target address
    error FunctionNotAllowed();

    /// Role not allowed to send to target address
    error SendNotAllowed();

    /// Role not allowed to use bytes for parameter
    error ParameterNotAllowed();

    /// Role not allowed to use bytes for parameter
    error ParameterNotOneOfAllowed();

    /// Role not allowed to use bytes less than value for parameter
    error ParameterLessThanAllowed();

    /// Role not allowed to use bytes greater than value for parameter
    error ParameterGreaterThanAllowed();

    /// only multisend txs with an offset of 32 bytes are allowed
    error UnacceptableMultiSendOffset();

    /// OneOf Comparison must be set via dedicated function
    error UnsuitableOneOfComparison();

    /// Not possible to define gt/lt for Dynamic types
    error UnsuitableRelativeComparison();

    /*
     *
     * CHECKERS
     *
     */

    /// @dev Splits a multisend data blob into transactions and forwards them to be checked.
    /// @param data the packed transaction data (created by utils function buildMultiSendSafeTx).
    /// @param role Role to check for.
    function checkMultisendTransaction(Role storage role, bytes memory data)
        public
        view
    {
        Enum.Operation operation;
        address to;
        uint256 value;
        bytes memory out;
        uint256 dataLength;

        uint256 offset;
        assembly {
            offset := mload(add(data, 36))
        }
        if (offset != 32) {
            revert UnacceptableMultiSendOffset();
        }

        // transaction data (1st tx operation) reads at byte 100,
        // 4 bytes (multisend_id) + 32 bytes (offset_multisend_data) + 32 bytes multisend_data_length
        // increment i by the transaction data length
        // + 85 bytes of the to, value, and operation bytes until we reach the end of the data
        for (uint256 i = 100; i < data.length; i += (85 + dataLength)) {
            assembly {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                operation := shr(0xf8, mload(add(data, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                to := shr(0x60, mload(add(data, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                value := mload(add(data, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                dataLength := mload(add(data, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                out := add(data, add(i, 0x35))
            }
            checkTransaction(role, to, value, out, operation);
        }
    }

    function checkTransaction(
        Role storage role,
        address targetAddress,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public view {
        TargetAddress memory target = role.targets[targetAddress];

        // CLEARANCE: transversal - checks
        if (value > 0 && !target.canSend) {
            revert SendNotAllowed();
        }

        if (operation == Enum.Operation.DelegateCall && !target.canDelegate) {
            revert DelegateCallNotAllowed();
        }

        if (data.length != 0 && data.length < 4) {
            revert FunctionSignatureTooShort();
        }

        /*
         * For each address we have three clearance checks:
         * Forbidden     - nothing was setup
         * AddressPass   - all calls to this address are go, nothing more to check
         * FunctionCheck - some functions on this address are allowed
         */

        // isForbidden
        if (target.clearance == Clearance.NONE) {
            revert TargetAddressNotAllowed();
        }

        // isAddressPass
        if (target.clearance == Clearance.TARGET) {
            // good to go
            return;
        }

        //isFunctionCheck
        if (target.clearance == Clearance.FUNCTION) {
            uint256 scopeConfig = role.functions[
                keyForFunctions(targetAddress, bytes4(data))
            ];

            if (scopeConfig == SCOPE_WILDCARD) {
                return;
            } else {
                checkParameters(role, scopeConfig, targetAddress, data);
            }
        }
    }

    /// @dev Will revert if a transaction has a parameter that is not allowed
    /// @param role reference to role storage
    /// @param targetAddress Address to check.
    /// @param data the transaction data to check
    function checkParameters(
        Role storage role,
        uint256 scopeConfig,
        address targetAddress,
        bytes memory data
    ) public view {
        if (scopeConfig & IS_SCOPED_MASK == 0) {
            // is there no single param scoped?
            // either config bug or unset
            // semantically the same, not allowed
            revert FunctionNotAllowed();
        }

        bytes4 functionSig = bytes4(data);
        uint8 paramCount = unpackParamCount(scopeConfig);

        for (uint8 i = 0; i < paramCount; i++) {
            (
                bool isParamScoped,
                bool isParamDynamic,
                Comparison compType
            ) = unpackParamEntry(scopeConfig, i);

            if (!isParamScoped) {
                continue;
            }

            bytes32 key = keyForCompValues(targetAddress, functionSig, i);
            bytes32 value;
            if (isParamDynamic) {
                value = pluckDynamicParamValue(data, i);
            } else {
                value = pluckParamValue(data, i);
            }

            if (compType != Comparison.OneOf) {
                compare(compType, role.compValues[key], value);
            } else {
                compareOneOf(role.compValuesOneOf[key], value);
            }
        }
    }

    function compare(
        Comparison compType,
        bytes32 compValue,
        bytes32 value
    ) internal pure {
        if (compType == Comparison.EqualTo && value != compValue) {
            revert ParameterNotAllowed();
        } else if (compType == Comparison.GreaterThan && value <= compValue) {
            revert ParameterLessThanAllowed();
        } else if (compType == Comparison.LessThan && value >= compValue) {
            revert ParameterGreaterThanAllowed();
        }
    }

    function compareOneOf(bytes32[] storage compValue, bytes32 value)
        internal
        view
    {
        for (uint256 i = 0; i < compValue.length; i++) {
            if (value == compValue[i]) return;
        }
        revert ParameterNotOneOfAllowed();
    }

    /*
     *
     * SETTERS
     *
     */
    function scopeAllowFunction(
        Role storage role,
        address targetAddress,
        bytes4 functionSig
    ) external {
        role.functions[
            keyForFunctions(targetAddress, functionSig)
        ] = SCOPE_WILDCARD;
    }

    function scopeRevokeFunction(
        Role storage role,
        address targetAddress,
        bytes4 functionSig
    ) external {
        // would a delete be more performant?
        role.functions[keyForFunctions(targetAddress, functionSig)] = 0;
    }

    function scopeFunction(
        Role storage role,
        address targetAddress,
        bytes4 functionSig,
        bool[] calldata isParamScoped,
        bool[] calldata isParamDynamic,
        Comparison[] calldata paramCompType,
        bytes[] calldata paramCompValue
    ) external {
        if (
            isParamScoped.length != isParamDynamic.length ||
            isParamScoped.length != paramCompType.length ||
            isParamScoped.length != paramCompValue.length
        ) {
            revert ArraysDifferentLength();
        }

        for (uint256 i = 0; i < isParamDynamic.length; i++) {
            if (isParamScoped[i]) {
                enforceCompType(isParamDynamic[i], paramCompType[i]);
            }
        }

        uint256 scopeConfig = resetScopeConfig(
            isParamScoped,
            isParamDynamic,
            paramCompType
        );

        // set scopeConfig
        role.functions[
            keyForFunctions(targetAddress, functionSig)
        ] = scopeConfig;

        // set respective compValues
        for (uint8 i = 0; i < paramCompType.length; i++) {
            role.compValues[
                keyForCompValues(targetAddress, functionSig, i)
            ] = maybeCompressCompValue(paramCompValue[i]);
        }
    }

    function scopeParameter(
        Role storage role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex,
        bool isDynamic,
        Comparison compType,
        bytes calldata compValue
    ) external {
        enforceCompType(isDynamic, compType);

        // set scopeConfig
        bytes32 key = keyForFunctions(targetAddress, functionSig);
        uint256 scopeConfig = setScopeConfig(
            role.functions[key],
            paramIndex,
            true,
            isDynamic,
            compType
        );
        role.functions[key] = scopeConfig;

        // set compValue
        role.compValues[
            keyForCompValues(targetAddress, functionSig, paramIndex)
        ] = maybeCompressCompValue(compValue);
    }

    function scopeParameterAsOneOf(
        Role storage role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex,
        bool isDynamic,
        bytes[] calldata compValues
    ) external {
        // set scopeConfig
        bytes32 key = keyForFunctions(targetAddress, functionSig);
        uint256 scopeConfig = setScopeConfig(
            role.functions[key],
            paramIndex,
            true,
            isDynamic,
            Comparison.OneOf
        );
        role.functions[key] = scopeConfig;

        // set compValue
        key = keyForCompValues(targetAddress, functionSig, paramIndex);

        role.compValuesOneOf[key] = new bytes32[](compValues.length);
        for (uint256 i = 0; i < compValues.length; i++) {
            role.compValuesOneOf[key][i] = maybeCompressCompValue(
                compValues[i]
            );
        }
    }

    function unscopeParameter(
        Role storage role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex
    ) external {
        // set scopeConfig
        bytes32 key = keyForFunctions(targetAddress, functionSig);
        uint256 scopeConfig = setScopeConfig(
            role.functions[key],
            paramIndex,
            false,
            false,
            Comparison(0)
        );
        role.functions[key] = scopeConfig;

        // set compValue
        key = keyForCompValues(targetAddress, functionSig, paramIndex);
        delete role.compValues[key];
        delete role.compValuesOneOf[key];
    }

    /*
     *
     * HELPERS
     *
     */
    function pluckDynamicParamValue(bytes memory data, uint256 paramIndex)
        internal
        pure
        returns (bytes32)
    {
        // get the pointer to the start of the buffer
        uint256 offset = 32 + 4 + paramIndex * 32;
        uint256 start;
        assembly {
            start := add(32, add(4, mload(add(data, offset))))
        }

        uint256 length;
        assembly {
            length := mload(add(data, start))
        }

        if (length > 32) {
            return keccak256(slice(data, start, start + length));
        } else {
            bytes32 content;
            assembly {
                content := mload(add(add(data, start), 32))
            }
            return content;
        }
    }

    function pluckParamValue(bytes memory data, uint256 paramIndex)
        internal
        pure
        returns (bytes32)
    {
        uint256 offset = 32 + 4 + paramIndex * 32;
        bytes32 value;
        assembly {
            value := mload(add(data, offset))
        }
        return value;
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes memory result) {
        result = new bytes(end - start);
        uint256 i;
        for (uint256 j = start; j < end; j++) {
            result[i++] = data[j];
        }
    }

    function resetScopeConfig(
        bool[] memory isParamScoped,
        bool[] memory isParamDynamic,
        Comparison[] memory paramCompType
    ) internal pure returns (uint256) {
        uint8 paramCount = uint8(isParamScoped.length);
        uint256 scopeConfig = packParamCount(0, paramCount);
        for (uint8 i = 0; i < paramCount; i++) {
            scopeConfig = packParamEntry(
                scopeConfig,
                i,
                isParamScoped[i],
                isParamDynamic[i],
                paramCompType[i]
            );
        }

        return scopeConfig;
    }

    function setScopeConfig(
        uint256 scopeConfig,
        uint8 paramIndex,
        bool isScoped,
        bool isDynamic,
        Comparison compType
    ) internal pure returns (uint256) {
        if (scopeConfig == SCOPE_WILDCARD) scopeConfig = 0;
        uint8 prevParamCount = unpackParamCount(scopeConfig);

        uint8 nextParamCount = paramIndex + 1 > prevParamCount
            ? paramIndex + 1
            : prevParamCount;

        return
            packParamEntry(
                packParamCount(scopeConfig, nextParamCount),
                paramIndex,
                isScoped,
                isDynamic,
                compType
            );
    }

    function packParamEntry(
        uint256 config,
        uint8 paramIndex,
        bool isScoped,
        bool isDynamic,
        Comparison compType
    ) internal pure returns (uint256) {
        // we restrict paramCount to 62:
        // 8   bits -> length
        // 62  bits -> isParamScoped
        // 62  bits -> isParamDynamic
        // 124 bits -> two bits for each compType 62*2 = 124
        uint256 isScopedMask = 1 << (paramIndex + 62 + 124);
        uint256 isDynamicMask = 1 << (paramIndex + 124);
        uint256 compTypeMask = 3 << (paramIndex * 2);

        if (isScoped) {
            config |= isScopedMask;
        } else {
            config &= ~isScopedMask;
        }

        if (isDynamic) {
            config |= isDynamicMask;
        } else {
            config &= ~isDynamicMask;
        }

        config &= ~compTypeMask;
        config |= uint256(compType) << (paramIndex * 2);

        return config;
    }

    function unpackParamEntry(uint256 config, uint8 paramIndex)
        internal
        pure
        returns (
            bool isScoped,
            bool isDynamic,
            Comparison compType
        )
    {
        uint256 isScopedMask = 1 << (paramIndex + 62 + 124);
        uint256 isDynamicMask = 1 << (paramIndex + 124);
        uint256 compTypeMask = 3 << (2 * paramIndex);

        isScoped = (config & isScopedMask) != 0;
        isDynamic = (config & isDynamicMask) != 0;
        compType = Comparison((config & compTypeMask) >> (2 * paramIndex));
    }

    function packParamCount(uint256 config, uint8 paramCount)
        internal
        pure
        returns (uint256)
    {
        // 8   bits -> length
        // 62  bits -> isParamScoped
        // 62  bits -> isParamDynamic
        // 124 bits -> two bits represents for each compType 62*2 = 124
        uint256 left = (uint256(paramCount) << (62 + 62 + 124));
        uint256 right = (config << 8) >> 8;
        return left | right;
    }

    function unpackParamCount(uint256 config) internal pure returns (uint8) {
        return uint8(config >> 248);
    }

    function enforceCompType(bool isDynamic, Comparison compType)
        internal
        pure
    {
        if (compType == Comparison.OneOf) {
            revert UnsuitableOneOfComparison();
        }

        if (
            isDynamic &&
            (compType == Comparison.GreaterThan ||
                compType == Comparison.LessThan)
        ) {
            revert UnsuitableRelativeComparison();
        }
    }

    function keyForFunctions(address targetAddress, bytes4 functionSig)
        public
        pure
        returns (bytes32)
    {
        // fits in 32 bytes
        return bytes32(abi.encodePacked(targetAddress, functionSig));
    }

    function keyForCompValues(
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex
    ) public pure returns (bytes32) {
        // fits in 32 bytes
        return
            bytes32(abi.encodePacked(targetAddress, functionSig, paramIndex));
    }

    function maybeCompressCompValue(bytes calldata compValue)
        internal
        pure
        returns (bytes32)
    {
        return
            compValue.length > 32 ? keccak256(compValue) : bytes32(compValue);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    event ChangedGuard(address guard);

    address public guard;

    /// @dev Set a guard that checks transactions before execution
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            require(
                BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId),
                "Guard does not implement IERC165"
            );
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}