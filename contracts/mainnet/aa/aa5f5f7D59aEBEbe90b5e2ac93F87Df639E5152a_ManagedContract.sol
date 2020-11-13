// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./Lockable.sol";

contract ManagedContract is Lockable {

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) Lockable(_contractRegistry, _registryAdmin) public {}

    modifier onlyMigrationManager {
        require(isManager("migrationManager"), "sender is not the migration manager");

        _;
    }

    modifier onlyFunctionalManager {
        require(isManager("functionalManager"), "sender is not the functional manager");

        _;
    }

    function refreshContracts() virtual external {}

}