// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "Ownable.sol";
import "IModuleRegistry.sol";

contract ModuleRegistry is Ownable, IModuleRegistry {
    mapping(address => bool) internal _modules;

    function isModuleRegistered(address module)
        external
        view
        override
        returns (bool)
    {
        return _modules[module];
    }

    function registerModule(address module) external override onlyOwner {
        if (_modules[module]) {
            return;
        }

        _modules[module] = true;

        emit ModuleRegistered(module);
    }

    function deregisterModule(address module) external override onlyOwner {
        if (!_modules[module]) {
            return;
        }

        delete _modules[module];

        emit ModuleDeregistered(module);
    }
}