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

import "./Proxy.sol";
import "./BaseWallet.sol";
import "./Owned.sol";
import "./Managed.sol";
import "./IGuardianStorage.sol";
import "./IModuleRegistry.sol";
import "./IVersionManager.sol";

/**
 * @title WalletFactory
 * @notice The WalletFactory contract creates and assigns wallets to accounts.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract WalletFactory is Owned, Managed {

    // The address of the module dregistry
    address public moduleRegistry;
    // The address of the base wallet implementation
    address public walletImplementation;
    // The address of the GuardianStorage
    address public guardianStorage;

    // *************** Events *************************** //

    event ModuleRegistryChanged(address addr);
    event WalletCreated(address indexed wallet, address indexed owner, address indexed guardian);

    // *************** Constructor ********************** //

    /**
     * @notice Default constructor.
     */
    constructor(address _moduleRegistry, address _walletImplementation, address _guardianStorage) public {
        require(_moduleRegistry != address(0), "WF: ModuleRegistry address not defined");
        require(_walletImplementation != address(0), "WF: WalletImplementation address not defined");
        require(_guardianStorage != address(0), "WF: GuardianStorage address not defined");
        moduleRegistry = _moduleRegistry;
        walletImplementation = _walletImplementation;
        guardianStorage = _guardianStorage;
    }

    // *************** External Functions ********************* //
    /**
     * @notice Lets the manager create a wallet for an owner account.
     * The wallet is initialised with the version manager module, a version number and a first guardian.
     * The wallet is created using the CREATE opcode.
     * @param _owner The account address.
     * @param _versionManager The version manager module
     * @param _guardian The guardian address.
     * @param _version The version of the feature bundle.
     */
    function createWallet(
        address _owner,
        address _versionManager,
        address _guardian,
        uint256 _version
    )
        external
        onlyManager
    {
        validateInputs(_owner, _versionManager, _guardian, _version);
        Proxy proxy = new Proxy(walletImplementation);
        address payable wallet = address(proxy);
        configureWallet(BaseWallet(wallet), _owner, _versionManager, _guardian, _version);
    }
     
    /**
     * @notice Lets the manager create a wallet for an owner account at a specific address.
     * The wallet is initialised with the version manager module, the version number and a first guardian.
     * The wallet is created using the CREATE2 opcode.
     * @param _owner The account address.
     * @param _versionManager The version manager module
     * @param _guardian The guardian address.
     * @param _salt The salt.
     * @param _version The version of the feature bundle.
     */
    function createCounterfactualWallet(
        address _owner,
        address _versionManager,
        address _guardian,
        bytes32 _salt,
        uint256 _version
    )
        external
        onlyManager
        returns (address _wallet)
    {
        validateInputs(_owner, _versionManager, _guardian, _version);
        bytes32 newsalt = newSalt(_salt, _owner, _versionManager, _guardian, _version);
        Proxy proxy = new Proxy{salt: newsalt}(walletImplementation);
        address payable wallet = address(proxy);
        configureWallet(BaseWallet(wallet), _owner, _versionManager, _guardian, _version);
        return wallet;
    }

    /**
     * @notice Gets the address of a counterfactual wallet with a first default guardian.
     * @param _owner The account address.
     * @param _versionManager The version manager module
     * @param _guardian The guardian address.
     * @param _salt The salt.
     * @param _version The version of feature bundle.
     * @return _wallet The address that the wallet will have when created using CREATE2 and the same input parameters.
     */
    function getAddressForCounterfactualWallet(
        address _owner,
        address _versionManager,
        address _guardian,
        bytes32 _salt,
        uint256 _version
    )
        external
        view
        returns (address _wallet)
    {
        validateInputs(_owner, _versionManager, _guardian, _version);
        bytes32 newsalt = newSalt(_salt, _owner, _versionManager, _guardian, _version);
        bytes memory code = abi.encodePacked(type(Proxy).creationCode, uint256(walletImplementation));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), newsalt, keccak256(code)));
        _wallet = address(uint160(uint256(hash)));
    }

    /**
     * @notice Lets the owner change the address of the module registry contract.
     * @param _moduleRegistry The address of the module registry contract.
     */
    function changeModuleRegistry(address _moduleRegistry) external onlyOwner {
        require(_moduleRegistry != address(0), "WF: address cannot be null");
        moduleRegistry = _moduleRegistry;
        emit ModuleRegistryChanged(_moduleRegistry);
    }

    /**
     * @notice Inits the module for a wallet by doing nothing.
     * The method can only be called by the wallet itself.
     * @param _wallet The wallet.
     */
    function init(BaseWallet _wallet) external pure {
        //do nothing
    }

    // *************** Internal Functions ********************* //

    /**
     * @notice Helper method to configure a wallet for a set of input parameters.
     * @param _wallet The target wallet
     * @param _owner The account address.
     * @param _versionManager The version manager module
     * @param _guardian The guardian address.
     * @param _version The version of the feature bundle.
     */
    function configureWallet(
        BaseWallet _wallet,
        address _owner,
        address _versionManager,
        address _guardian,
        uint256 _version
    )
        internal
    {
        // add the factory to modules so it can add a guardian and upgrade the wallet to the required version
        address[] memory extendedModules = new address[](2);
        extendedModules[0] = _versionManager;
        extendedModules[1] = address(this);

        // initialise the wallet with the owner and the extended modules
        _wallet.init(_owner, extendedModules);

        // add guardian
        IGuardianStorage(guardianStorage).addGuardian(address(_wallet), _guardian);

        // upgrade the wallet
        IVersionManager(_versionManager).upgradeWallet(address(_wallet), _version);

        // remove the factory from the authorised modules
        _wallet.authoriseModule(address(this), false);

        // emit event
        emit WalletCreated(address(_wallet), _owner, _guardian);
    }

    /**
     * @notice Generates a new salt based on a provided salt, an owner, a list of modules and an optional guardian.
     * @param _salt The slat provided.
     * @param _owner The owner address.
     * @param _versionManager The version manager module
     * @param _guardian The guardian address.
     * @param _version The version of feature bundle
     */
    function newSalt(bytes32 _salt, address _owner, address _versionManager, address _guardian, uint256 _version) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_salt, _owner, _versionManager, _guardian, _version));
    }

    /**
     * @notice Throws if the owner, guardian, version or version manager is invalid.
     * @param _owner The owner address.
     * @param _versionManager The version manager module
     * @param _guardian The guardian address
     * @param _version The version of feature bundle
     */
    function validateInputs(address _owner, address _versionManager, address _guardian, uint256 _version) internal view {
        require(_owner != address(0), "WF: owner cannot be null");
        require(IModuleRegistry(moduleRegistry).isRegisteredModule(_versionManager), "WF: invalid _versionManager");
        require(_guardian != (address(0)), "WF: guardian cannot be null");
        require(_version > 0, "WF: invalid _version");
    }
}
