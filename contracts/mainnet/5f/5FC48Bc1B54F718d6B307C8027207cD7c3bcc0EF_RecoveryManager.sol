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

import "./Utils.sol";
import "./BaseFeature.sol";
import "./IGuardianStorage.sol";

/**
 * @title RecoveryManager
 * @notice Feature to manage the recovery of a wallet owner.
 * Recovery is executed by a consensus of the wallet's guardians and takes 24 hours before it can be finalized.
 * Once finalised the ownership of the wallet is transfered to a new address.
 * @author Julien Niset - <julien@argent.xyz>
 * @author Olivier Van Den Biggelaar - <olivier@argent.xyz>
 */
contract RecoveryManager is BaseFeature {

    bytes32 constant NAME = "RecoveryManager";

    bytes4 constant internal EXECUTE_RECOVERY_PREFIX = bytes4(keccak256("executeRecovery(address,address)"));
    bytes4 constant internal FINALIZE_RECOVERY_PREFIX = bytes4(keccak256("finalizeRecovery(address)"));
    bytes4 constant internal CANCEL_RECOVERY_PREFIX = bytes4(keccak256("cancelRecovery(address)"));
    bytes4 constant internal TRANSFER_OWNERSHIP_PREFIX = bytes4(keccak256("transferOwnership(address,address)"));

    struct RecoveryConfig {
        address recovery;
        uint64 executeAfter;
        uint32 guardianCount;
    }

    // Wallet specific storage
    mapping (address => RecoveryConfig) internal recoveryConfigs;

    // Recovery period
    uint256 public recoveryPeriod;
    // Lock period
    uint256 public lockPeriod;
    // Guardian Storage
    IGuardianStorage public guardianStorage;

    // *************** Events *************************** //

    event RecoveryExecuted(address indexed wallet, address indexed _recovery, uint64 executeAfter);
    event RecoveryFinalized(address indexed wallet, address indexed _recovery);
    event RecoveryCanceled(address indexed wallet, address indexed _recovery);
    event OwnershipTransfered(address indexed wallet, address indexed _newOwner);

    // *************** Modifiers ************************ //

    /**
     * @notice Throws if there is no ongoing recovery procedure.
     */
    modifier onlyWhenRecovery(address _wallet) {
        require(recoveryConfigs[_wallet].executeAfter > 0, "RM: there must be an ongoing recovery");
        _;
    }

    /**
     * @notice Throws if there is an ongoing recovery procedure.
     */
    modifier notWhenRecovery(address _wallet) {
        require(recoveryConfigs[_wallet].executeAfter == 0, "RM: there cannot be an ongoing recovery");
        _;
    }

    // *************** Constructor ************************ //

    constructor(
        ILockStorage _lockStorage,
        IGuardianStorage _guardianStorage,
        IVersionManager _versionManager,
        uint256 _recoveryPeriod,
        uint256 _lockPeriod
    )
        BaseFeature(_lockStorage, _versionManager, NAME)
        public
    {
        // For the wallet to be secure we must have recoveryPeriod >= securityPeriod + securityWindow
        // where securityPeriod and securityWindow are the security parameters of adding/removing guardians
        // and confirming large transfers.
        require(_lockPeriod >= _recoveryPeriod, "RM: insecure security periods");
        recoveryPeriod = _recoveryPeriod;
        lockPeriod = _lockPeriod;
        guardianStorage = _guardianStorage;
    }

    // *************** External functions ************************ //

    /**
     * @notice Lets the guardians start the execution of the recovery procedure.
     * Once triggered the recovery is pending for the security period before it can be finalised.
     * Must be confirmed by N guardians, where N = ((Nb Guardian + 1) / 2).
     * @param _wallet The target wallet.
     * @param _recovery The address to which ownership should be transferred.
     */
    function executeRecovery(address _wallet, address _recovery) external onlyWalletFeature(_wallet) notWhenRecovery(_wallet) {
        validateNewOwner(_wallet, _recovery);
        RecoveryConfig storage config = recoveryConfigs[_wallet];
        config.recovery = _recovery;
        config.executeAfter = uint64(block.timestamp + recoveryPeriod);
        config.guardianCount = uint32(guardianStorage.guardianCount(_wallet));
        setLock(_wallet, block.timestamp + lockPeriod);
        emit RecoveryExecuted(_wallet, _recovery, config.executeAfter);
    }

    /**
     * @notice Finalizes an ongoing recovery procedure if the security period is over.
     * The method is public and callable by anyone to enable orchestration.
     * @param _wallet The target wallet.
     */
    function finalizeRecovery(address _wallet) external onlyWhenRecovery(_wallet) {
        RecoveryConfig storage config = recoveryConfigs[address(_wallet)];
        require(uint64(block.timestamp) > config.executeAfter, "RM: the recovery period is not over yet");
        address recoveryOwner = config.recovery;
        delete recoveryConfigs[_wallet];

        versionManager.setOwner(_wallet, recoveryOwner);
        setLock(_wallet, 0);

        emit RecoveryFinalized(_wallet, recoveryOwner);
    }

    /**
     * @notice Lets the owner cancel an ongoing recovery procedure.
     * Must be confirmed by N guardians, where N = ((Nb Guardian + 1) / 2) - 1.
     * @param _wallet The target wallet.
     */
    function cancelRecovery(address _wallet) external onlyWalletFeature(_wallet) onlyWhenRecovery(_wallet) {
        RecoveryConfig storage config = recoveryConfigs[address(_wallet)];
        address recoveryOwner = config.recovery;
        delete recoveryConfigs[_wallet];
        setLock(_wallet, 0);

        emit RecoveryCanceled(_wallet, recoveryOwner);
    }

    /**
     * @notice Lets the owner transfer the wallet ownership. This is executed immediately.
     * @param _wallet The target wallet.
     * @param _newOwner The address to which ownership should be transferred.
     */
    function transferOwnership(address _wallet, address _newOwner) external onlyWalletFeature(_wallet) onlyWhenUnlocked(_wallet) {
        validateNewOwner(_wallet, _newOwner);
        versionManager.setOwner(_wallet, _newOwner);

        emit OwnershipTransfered(_wallet, _newOwner);
    }

    /**
    * @notice Gets the details of the ongoing recovery procedure if any.
    * @param _wallet The target wallet.
    */
    function getRecovery(address _wallet) external view returns(address _address, uint64 _executeAfter, uint32 _guardianCount) {
        RecoveryConfig storage config = recoveryConfigs[_wallet];
        return (config.recovery, config.executeAfter, config.guardianCount);
    }

    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address _wallet, bytes calldata _data) external view override returns (uint256, OwnerSignature) {
        bytes4 methodId = Utils.functionPrefix(_data);
        if (methodId == EXECUTE_RECOVERY_PREFIX) {
            uint walletGuardians = guardianStorage.guardianCount(_wallet);
            require(walletGuardians > 0, "RM: no guardians set on wallet");
            uint numberOfSignaturesRequired = Utils.ceil(walletGuardians, 2);
            return (numberOfSignaturesRequired, OwnerSignature.Disallowed);
        }
        if (methodId == FINALIZE_RECOVERY_PREFIX) {
            return (0, OwnerSignature.Anyone);
        }
        if (methodId == CANCEL_RECOVERY_PREFIX) {
            uint numberOfSignaturesRequired = Utils.ceil(recoveryConfigs[_wallet].guardianCount + 1, 2);
            return (numberOfSignaturesRequired, OwnerSignature.Optional);
        }
        if (methodId == TRANSFER_OWNERSHIP_PREFIX) {
            uint majorityGuardians = Utils.ceil(guardianStorage.guardianCount(_wallet), 2);
            uint numberOfSignaturesRequired = SafeMath.add(majorityGuardians, 1);
            return (numberOfSignaturesRequired, OwnerSignature.Required);
        }

        revert("RM: unknown method");
    }

    // *************** Internal Functions ********************* //

    function validateNewOwner(address _wallet, address _newOwner) internal view {
        require(_newOwner != address(0), "RM: new owner address cannot be null");
        require(!guardianStorage.isGuardian(_wallet, _newOwner), "RM: new owner address cannot be a guardian");
    }

    function setLock(address _wallet, uint256 _releaseAfter) internal {
        versionManager.invokeStorage(
            _wallet,
            address(lockStorage),
            abi.encodeWithSelector(lockStorage.setLock.selector, _wallet, address(this), _releaseAfter)
        );
    }

}