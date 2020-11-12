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

import "./BaseFeature.sol";
import "./GuardianUtils.sol";
import "./ILockStorage.sol";
import "./IGuardianStorage.sol";

/**
 * @title LockManager
 * @notice Feature to manage the state of a wallet's lock.
 * Other features can use the state of the lock to determine if their operations
 * should be authorised or blocked. Only the guardians of a wallet can lock and unlock it.
 * The lock automatically unlocks after a given period. The lock state is stored on a separate
 * contract to facilitate its use by other features.
 * @author Julien Niset - <julien@argent.xyz>
 * @author Olivier Van Den Biggelaar - <olivier@argent.xyz>
 */
contract LockManager is BaseFeature {

    bytes32 constant NAME = "LockManager";

    // The lock period
    uint256 public lockPeriod;
    // the guardian storage
    IGuardianStorage public guardianStorage;

    // *************** Events *************************** //

    event Locked(address indexed wallet, uint64 releaseAfter);
    event Unlocked(address indexed wallet);

    // *************** Modifiers ************************ //

    /**
     * @notice Throws if the wallet is not locked.
     */
    modifier onlyWhenLocked(address _wallet) {
        require(lockStorage.isLocked(_wallet), "LM: wallet must be locked");
        _;
    }

    /**
     * @notice Throws if the caller is not a guardian for the wallet.
     */
    modifier onlyGuardianOrFeature(address _wallet) {
        bool isGuardian = guardianStorage.isGuardian(_wallet, msg.sender);
        require(isFeatureAuthorisedInVersionManager(_wallet, msg.sender) || isGuardian, "LM: must be guardian or feature");
        _;
    }

    // *************** Constructor ************************ //

    constructor(
        ILockStorage _lockStorage,
        IGuardianStorage _guardianStorage,
        IVersionManager _versionManager,
        uint256 _lockPeriod
    )
        BaseFeature(_lockStorage, _versionManager, NAME) public {
        guardianStorage = _guardianStorage;
        lockPeriod = _lockPeriod;
    }

    // *************** External functions ************************ //

    /**
     * @notice Lets a guardian lock a wallet.
     * @param _wallet The target wallet.
     */
    function lock(address _wallet) external onlyGuardianOrFeature(_wallet) onlyWhenUnlocked(_wallet) {
        setLock(_wallet, block.timestamp + lockPeriod);
        emit Locked(_wallet, uint64(block.timestamp + lockPeriod));
    }

    /**
     * @notice Lets a guardian unlock a locked wallet.
     * @param _wallet The target wallet.
     */
    function unlock(address _wallet) external onlyGuardianOrFeature(_wallet) onlyWhenLocked(_wallet) {
        address locker = lockStorage.getLocker(_wallet);
        require(locker == address(this), "LM: cannot unlock a wallet that was locked by another feature");
        setLock(_wallet, 0);
        emit Unlocked(_wallet);
    }

    /**
     * @notice Returns the release time of a wallet lock or 0 if the wallet is unlocked.
     * @param _wallet The target wallet.
     * @return _releaseAfter The epoch time at which the lock will release (in seconds).
     */
    function getLock(address _wallet) external view returns(uint64 _releaseAfter) {
        uint256 lockEnd = lockStorage.getLock(_wallet);
        if (lockEnd > block.timestamp) {
            _releaseAfter = uint64(lockEnd);
        }
    }

    /**
     * @notice Checks if a wallet is locked.
     * @param _wallet The target wallet.
     * @return _isLocked `true` if the wallet is locked otherwise `false`.
     */
    function isLocked(address _wallet) external view returns (bool _isLocked) {
        return lockStorage.isLocked(_wallet);
    }

    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address, bytes calldata) external view override returns (uint256, OwnerSignature) {
        return (1, OwnerSignature.Disallowed);
    }

    // *************** Internal Functions ********************* //

    function setLock(address _wallet, uint256 _releaseAfter) internal {
        versionManager.invokeStorage(
            _wallet,
            address(lockStorage),
            abi.encodeWithSelector(lockStorage.setLock.selector, _wallet, address(this), _releaseAfter)
        );
    }
}