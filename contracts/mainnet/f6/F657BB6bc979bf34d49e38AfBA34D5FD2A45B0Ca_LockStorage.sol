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

pragma solidity ^0.6.12;
import "./BaseWallet.sol";
import "./Storage.sol";
import "./ILockStorage.sol";

/**
 * @title LockStorage
 * @dev Contract storing the state of wallets related to guardians and lock.
 * The contract only defines basic setters and getters with no logic. Only modules authorised
 * for a wallet can modify its state.
 * @author Julien Niset - <julien@argent.xyz>
 * @author Olivier Van Den Biggelaar - <olivier@argent.xyz>
 */
contract LockStorage is ILockStorage, Storage {

    struct LockStorageConfig {
        // the lock's release timestamp
        uint256 lock;
        // the module that set the last lock
        address locker;
    }
    
    // wallet specific storage
    mapping (address => LockStorageConfig) internal configs;

    // *************** External Functions ********************* //

    /**
     * @dev Lets an authorised module set the lock for a wallet.
     * @param _wallet The target wallet.
     * @param _locker The feature doing the lock.
     * @param _releaseAfter The epoch time at which the lock should automatically release.
     */
    function setLock(address _wallet, address _locker, uint256 _releaseAfter) external override onlyModule(_wallet) {
        configs[_wallet].lock = _releaseAfter;
        if (_releaseAfter != 0 && _locker != configs[_wallet].locker) {
            configs[_wallet].locker = _locker;
        }
    }

    /**
     * @dev Checks if the lock is set for a wallet.
     * @param _wallet The target wallet.
     * @return true if the lock is set for the wallet.
     */
    function isLocked(address _wallet) external view override returns (bool) {
        return configs[_wallet].lock > now;
    }

    /**
     * @dev Gets the time at which the lock of a wallet will release.
     * @param _wallet The target wallet.
     * @return the time at which the lock of a wallet will release, or zero if there is no lock set.
     */
    function getLock(address _wallet) external view override returns (uint256) {
        return configs[_wallet].lock;
    }

    /**
     * @dev Gets the address of the last module that modified the lock for a wallet.
     * @param _wallet The target wallet.
     * @return the address of the last module that modified the lock for a wallet.
     */
    function getLocker(address _wallet) external view override returns (address) {
        return configs[_wallet].locker;
    }
}