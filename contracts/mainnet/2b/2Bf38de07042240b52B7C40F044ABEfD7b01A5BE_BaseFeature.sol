// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.s

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IWallet.sol";
import "./IModuleRegistry.sol";
import "./ILockStorage.sol";
import "./IFeature.sol";
import "./ERC20.sol";
import "./IVersionManager.sol";

/**
 * @title BaseFeature
 * @notice Base Feature contract that contains methods common to all Feature contracts.
 * @author Julien Niset - <julien@argent.xyz>, Olivier VDB - <olivier@argent.xyz>
 */
contract BaseFeature is IFeature {

    // Empty calldata
    bytes constant internal EMPTY_BYTES = "";
    // Mock token address for ETH
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // The address of the Lock storage
    ILockStorage internal lockStorage;
    // The address of the Version Manager
    IVersionManager internal versionManager;

    event FeatureCreated(bytes32 name);

    /**
     * @notice Throws if the wallet is locked.
     */
    modifier onlyWhenUnlocked(address _wallet) {
        require(!lockStorage.isLocked(_wallet), "BF: wallet locked");
        _;
    }

    /**
     * @notice Throws if the sender is not the VersionManager.
     */
    modifier onlyVersionManager() {
        require(msg.sender == address(versionManager), "BF: caller must be VersionManager");
        _;
    }

    /**
     * @notice Throws if the sender is not the owner of the target wallet.
     */
    modifier onlyWalletOwner(address _wallet) {
        require(isOwner(_wallet, msg.sender), "BF: must be wallet owner");
        _;
    }

    /**
     * @notice Throws if the sender is not an authorised feature of the target wallet.
     */
    modifier onlyWalletFeature(address _wallet) {
        require(versionManager.isFeatureAuthorised(_wallet, msg.sender), "BF: must be a wallet feature");
        _;
    }

    /**
     * @notice Throws if the sender is not the owner of the target wallet or the feature itself.
     */
    modifier onlyWalletOwnerOrFeature(address _wallet) {
        // Wrapping in an internal method reduces deployment cost by avoiding duplication of inlined code
        verifyOwnerOrAuthorisedFeature(_wallet, msg.sender);
        _;
    }

    constructor(
        ILockStorage _lockStorage,
        IVersionManager _versionManager,
        bytes32 _name
    ) public {
        lockStorage = _lockStorage;
        versionManager = _versionManager;
        emit FeatureCreated(_name);
    }

    /**
    * @inheritdoc IFeature
    */
    function recoverToken(address _token) external virtual override {
        uint total = ERC20(_token).balanceOf(address(this));
        _token.call(abi.encodeWithSelector(ERC20(_token).transfer.selector, address(versionManager), total));
    }

    /**
     * @notice Inits the feature for a wallet by doing nothing.
     * @dev !! Overriding methods need make sure `init()` can only be called by the VersionManager !!
     * @param _wallet The wallet.
     */
    function init(address _wallet) external virtual override  {}

    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address, bytes calldata) external virtual view override returns (uint256, OwnerSignature) {
        revert("BF: disabled method");
    }

    /**
     * @inheritdoc IFeature
     */
    function getStaticCallSignatures() external virtual override view returns (bytes4[] memory _sigs) {}

    /**
     * @inheritdoc IFeature
     */
    function isFeatureAuthorisedInVersionManager(address _wallet, address _feature) public override view returns (bool) {
        return versionManager.isFeatureAuthorised(_wallet, _feature);
    }

    /**
    * @notice Checks that the wallet address provided as the first parameter of _data matches _wallet
    * @return false if the addresses are different.
    */
    function verifyData(address _wallet, bytes calldata _data) internal pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet = abi.decode(_data[4:], (address));
        return dataWallet == _wallet;
    }
    
     /**
     * @notice Helper method to check if an address is the owner of a target wallet.
     * @param _wallet The target wallet.
     * @param _addr The address.
     */
    function isOwner(address _wallet, address _addr) internal view returns (bool) {
        return IWallet(_wallet).owner() == _addr;
    }

    /**
     * @notice Verify that the caller is an authorised feature or the wallet owner.
     * @param _wallet The target wallet.
     * @param _sender The caller.
     */
    function verifyOwnerOrAuthorisedFeature(address _wallet, address _sender) internal view {
        require(isFeatureAuthorisedInVersionManager(_wallet, _sender) || isOwner(_wallet, _sender), "BF: must be owner or feature");
    }

    /**
     * @notice Helper method to invoke a wallet.
     * @param _wallet The target wallet.
     * @param _to The target address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data)
        internal
        returns (bytes memory _res) 
    {
        _res = versionManager.checkAuthorisedFeatureAndInvokeWallet(_wallet, _to, _value, _data);
    }

}