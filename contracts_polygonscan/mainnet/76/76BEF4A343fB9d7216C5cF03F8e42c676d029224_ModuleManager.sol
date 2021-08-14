// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "Ownable.sol";
import "IModuleManager.sol";
import "IModuleRegistry.sol";

contract ModuleManager is Ownable, IModuleManager {
    IModuleRegistry internal immutable _registry;

    struct ModuleState {
        bool isEnabled;
        bool isFixed;
    }

    mapping(address => ModuleState) internal _moduleStates;
    mapping(bytes4 => address) internal _delegates;

    constructor(address registry) {
        require(
            registry != address(0),
            "ModuleManager: registry must not be the zero address"
        );

        _registry = IModuleRegistry(registry);
    }

    function isModuleEnabled(address module)
        external
        view
        override
        returns (bool)
    {
        return _moduleStates[module].isEnabled;
    }

    function isModuleFixed(address module)
        external
        view
        override
        returns (bool)
    {
        return _moduleStates[module].isFixed;
    }

    function enableModule(address module) external override onlyOwner {
        if (_moduleStates[module].isEnabled) {
            return;
        }

        require(
            _registry.isModuleRegistered(module),
            "ModuleManager: unregistered module"
        );

        _moduleStates[module].isEnabled = true;

        emit ModuleEnabled(module);
    }

    function disableModule(address module) external override onlyOwner {
        if (!_moduleStates[module].isEnabled) {
            return;
        }

        require(!_moduleStates[module].isFixed, "ModuleManager: fixed module");

        delete _moduleStates[module];

        emit ModuleDisabled(module);
    }

    function fixModule(address module) external override onlyOwner {
        if (_moduleStates[module].isFixed) {
            return;
        }

        require(
            _moduleStates[module].isEnabled,
            "ModuleManager: disabled module"
        );

        _moduleStates[module].isFixed = true;

        emit ModuleFixed(module);
    }

    function getDelegate(bytes4 methodID)
        external
        view
        override
        returns (address)
    {
        return _delegates[methodID];
    }

    function enableDelegation(bytes4 methodID, address module)
        external
        override
        onlyOwner
    {
        if (_delegates[methodID] == module) {
            return;
        }

        require(
            _moduleStates[module].isEnabled,
            "ModuleManager: disabled module"
        );

        _delegates[methodID] = module;

        emit DelegationEnabled(methodID, module);
    }

    function disableDelegation(bytes4 methodID) external override onlyOwner {
        if (_delegates[methodID] == address(0)) {
            return;
        }

        delete _delegates[methodID];

        emit DelegationDisabled(methodID);
    }
}