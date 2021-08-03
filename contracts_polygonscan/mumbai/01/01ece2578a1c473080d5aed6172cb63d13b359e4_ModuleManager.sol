// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "Ownable.sol";

import "IModuleManager.sol";
import "IModuleRegistry.sol";

contract ModuleManager is Ownable, IModuleManager {
    IModuleRegistry internal immutable _registry;

    mapping(address => bool) internal _modules;
    address public override staticCallExecutor;

    constructor(address registry) {
        require(
            registry != address(0),
            "ModuleManager: registry is zero address"
        );

        _registry = IModuleRegistry(registry);
    }

    function isEnabled(address module) external view override returns (bool) {
        return _modules[module];
    }

    function enable(address module) external override onlyOwner {
        if (_modules[module]) {
            return;
        }

        require(
            _registry.isRegistered(module),
            "ModuleManager: module not registered"
        );

        _modules[module] = true;

        emit Enabled(module);
    }

    function disable(address module) external override onlyOwner {
        if (!_modules[module]) {
            return;
        }

        delete _modules[module];

        emit Disabled(module);
    }

    function setStaticCallExecutor(address module) external override onlyOwner {
        if (module == staticCallExecutor) {
            return;
        }

        require(
            _registry.isRegistered(module),
            "ModuleManager: module not registered"
        );

        staticCallExecutor = module;

        emit StaticCallExecutorChanged(module);
    }
}