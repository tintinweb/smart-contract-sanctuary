// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

import "./IModule.sol";
import "./IVersionManager.sol";
import "./IModuleRegistry.sol";
import "./ILockStorage.sol";
import "./IWallet.sol";

/**
 * @title UpgraderToVersionManager
 * @notice Temporary module used to add the VersionManager and remove other modules.
 * @author Olivier VDB - <olivier@argent.xyz>, Julien Niset - <julien@argent.xyz>
 */
contract UpgraderToVersionManager is IModule {

    IModuleRegistry private registry;
    ILockStorage private lockStorage;
    address[] public toDisable;
    address public versionManager;

    // *************** Constructor ********************** //

    constructor(
        IModuleRegistry _registry,
        ILockStorage _lockStorage,
        address[] memory _toDisable,
        address _versionManager
    )
        public
    {
        registry = _registry;
        lockStorage = _lockStorage;
        toDisable = _toDisable;
        versionManager = _versionManager;
    }

    // *************** External/Public Functions ********************* //

    /**
     * @notice Perform the upgrade for a wallet. This method gets called when UpgradeToVersionManager is temporarily added as a module.
     * @param _wallet The target wallet.
     */
    function init(address _wallet) public override {
        require(msg.sender == _wallet, "SU: only wallet can call init");
        require(!lockStorage.isLocked(_wallet), "SU: wallet locked");
        require(registry.isRegisteredModule(versionManager), "SU: VersionManager not registered");

        // add VersionManager
        IWallet(_wallet).authoriseModule(versionManager, true);

        // upgrade wallet from version 0 to version 1
        IVersionManager(versionManager).upgradeWallet(_wallet, 1);

        // remove old modules
        for (uint256 i = 0; i < toDisable.length; i++) {
            IWallet(_wallet).authoriseModule(toDisable[i], false);
        }
        // SimpleUpgrader did its job, we no longer need it as a module
        IWallet(_wallet).authoriseModule(address(this), false);
    }

    /**
     * @inheritdoc IModule
     */
    function addModule(address _wallet, address _module) external override {}
}