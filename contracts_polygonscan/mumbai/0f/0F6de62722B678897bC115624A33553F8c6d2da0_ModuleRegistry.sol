// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "Ownable.sol";

import "IModuleRegistry.sol";

contract ModuleRegistry is Ownable, IModuleRegistry {
    mapping(address => bool) internal _modules;

    function isRegistered(address module)
        external
        view
        override
        returns (bool)
    {
        return _modules[module];
    }

    function register(address module) external override onlyOwner {
        if (_modules[module]) {
            return;
        }

        _modules[module] = true;

        emit Registered(module);
    }

    function deregister(address module) external override onlyOwner {
        if (!_modules[module]) {
            return;
        }

        delete _modules[module];

        emit Deregistered(module);
    }
}