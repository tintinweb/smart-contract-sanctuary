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
pragma solidity >=0.5.4 <0.9.0;

interface IGuardianStorage {
  /**
   * @notice Lets an authorised module add a guardian to a wallet.
   * @param _wallet The target wallet.
   * @param _guardian The guardian to add.
   */
  function addGuardian(address _wallet, address _guardian) external;

  /**
   * @notice Lets an authorised module revoke a guardian from a wallet.
   * @param _wallet The target wallet.
   * @param _guardian The guardian to revoke.
   */
  function revokeGuardian(address _wallet, address _guardian) external;

  /**
   * @notice Checks if an account is a guardian for a wallet.
   * @param _wallet The target wallet.
   * @param _guardian The account.
   * @return true if the account is a guardian for a wallet.
   */
  function isGuardian(address _wallet, address _guardian)
    external
    view
    returns (bool);

  function isLocked(address _wallet) external view returns (bool);

  function getLock(address _wallet) external view returns (uint256);

  function getLocker(address _wallet) external view returns (address);

  function setLock(address _wallet, uint256 _releaseAfter) external;

  function getGuardians(address _wallet)
    external
    view
    returns (address[] memory);

  function guardianCount(address _wallet) external view returns (uint256);
}

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

pragma solidity ^0.5.4;

import './Storage.sol';
import '../../infrastructure/storage/IGuardianStorage.sol';

/**
 * @title GuardianStorage
 * @notice Contract storing the state of wallets related to guardians and lock.
 * The contract only defines basic setters and getters with no logic. Only modules authorised
 * for a wallet can modify its state.
 * @author Julien Niset - <[email protected]>
 * @author Olivier Van Den Biggelaar - <[email protected]>
 */
contract GuardianStorage is IGuardianStorage, Storage {
  struct GuardianStorageConfig {
    // the list of guardians
    address[] guardians;
    // the info about guardians
    mapping(address => GuardianInfo) info;
    // the lock's release timestamp
    uint256 lock;
    // the module that set the last lock
    address locker;
  }

  struct GuardianInfo {
    bool exists;
    uint128 index;
  }

  // wallet specific storage
  mapping(address => GuardianStorageConfig) internal configs;

  // *************** External Functions ********************* //

  /**
   * @notice Lets an authorised module add a guardian to a wallet.
   * @param _wallet The target wallet.
   * @param _guardian The guardian to add.
   */
  function addGuardian(address _wallet, address _guardian)
    external
    onlyModule(_wallet)
  {
    GuardianStorageConfig storage config = configs[_wallet];
    config.info[_guardian].exists = true;
    config.info[_guardian].index = uint128(
      config.guardians.push(_guardian) - 1
    );
  }

  /**
   * @notice Lets an authorised module revoke a guardian from a wallet.
   * @param _wallet The target wallet.
   * @param _guardian The guardian to revoke.
   */
  function revokeGuardian(address _wallet, address _guardian)
    external
    onlyModule(_wallet)
  {
    GuardianStorageConfig storage config = configs[_wallet];
    address lastGuardian = config.guardians[config.guardians.length - 1];
    if (_guardian != lastGuardian) {
      uint128 targetIndex = config.info[_guardian].index;
      config.guardians[targetIndex] = lastGuardian;
      config.info[lastGuardian].index = targetIndex;
    }
    config.guardians.length--;
    delete config.info[_guardian];
  }

  /**
   * @notice Returns the number of guardians for a wallet.
   * @param _wallet The target wallet.
   * @return the number of guardians.
   */
  function guardianCount(address _wallet) external view returns (uint256) {
    return configs[_wallet].guardians.length;
  }

  /**
   * @notice Gets the list of guaridans for a wallet.
   * @param _wallet The target wallet.
   * @return the list of guardians.
   */
  function getGuardians(address _wallet)
    external
    view
    returns (address[] memory)
  {
    GuardianStorageConfig storage config = configs[_wallet];
    address[] memory guardians = new address[](config.guardians.length);
    for (uint256 i = 0; i < config.guardians.length; i++) {
      guardians[i] = config.guardians[i];
    }
    return guardians;
  }

  /**
   * @notice Checks if an account is a guardian for a wallet.
   * @param _wallet The target wallet.
   * @param _guardian The account.
   * @return true if the account is a guardian for a wallet.
   */
  function isGuardian(address _wallet, address _guardian)
    external
    view
    returns (bool)
  {
    return configs[_wallet].info[_guardian].exists;
  }

  /**
   * @notice Lets an authorised module set the lock for a wallet.
   * @param _wallet The target wallet.
   * @param _releaseAfter The epoch time at which the lock should automatically release.
   */
  function setLock(address _wallet, uint256 _releaseAfter)
    external
    onlyModule(_wallet)
  {
    configs[_wallet].lock = _releaseAfter;
    if (_releaseAfter != 0 && msg.sender != configs[_wallet].locker) {
      configs[_wallet].locker = msg.sender;
    }
  }

  /**
   * @notice Checks if the lock is set for a wallet.
   * @param _wallet The target wallet.
   * @return true if the lock is set for the wallet.
   */
  function isLocked(address _wallet) external view returns (bool) {
    return configs[_wallet].lock > block.timestamp;
  }

  /**
   * @notice Gets the time at which the lock of a wallet will release.
   * @param _wallet The target wallet.
   * @return the time at which the lock of a wallet will release, or zero if there is no lock set.
   */
  function getLock(address _wallet) external view returns (uint256) {
    return configs[_wallet].lock;
  }

  /**
   * @notice Gets the address of the last module that modified the lock for a wallet.
   * @param _wallet The target wallet.
   * @return the address of the last module that modified the lock for a wallet.
   */
  function getLocker(address _wallet) external view returns (address) {
    return configs[_wallet].locker;
  }
}

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

pragma solidity ^0.5.4;

import '../../wallet/IWallet.sol';

/**
 * @title Storage
 * @notice Base contract for the storage of a wallet.
 * @author Julien Niset - <[email protected]>
 */
contract Storage {
  /**
   * @notice Throws if the caller is not an authorised module.
   */
  modifier onlyModule(address _wallet) {
    // solhint-disable-next-line reason-string
    require(
      IWallet(_wallet).authorised(msg.sender),
      'TS: must be an authorized module to call this method'
    );
    _;
  }
}

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
pragma solidity >=0.5.4 <0.9.0;

/**
 * @title IWallet
 * @notice Interface for the BaseWallet
 */
interface IWallet {
  /**
   * @notice Returns the wallet owner.
   * @return The wallet owner address.
   */
  function owner() external view returns (address);

  /**
   * @notice Returns the number of authorised modules.
   * @return The number of authorised modules.
   */
  function modules() external view returns (uint256);

  /**
   * @notice Sets a new owner for the wallet.
   * @param _newOwner The new owner.
   */
  function setOwner(address _newOwner) external;

  /**
   * @notice Checks if a module is authorised on the wallet.
   * @param _module The module address to check.
   * @return `true` if the module is authorised, otherwise `false`.
   */
  function authorised(address _module) external view returns (bool);

  /**
   * @notice Returns the module responsible for a static call redirection.
   * @param _sig The signature of the static call.
   * @return the module doing the redirection
   */
  function enabled(bytes4 _sig) external view returns (address);

  /**
   * @notice Enables/Disables a module.
   * @param _module The target module.
   * @param _value Set to `true` to authorise the module.
   */
  function authoriseModule(address _module, bool _value) external;

  /**
   * @notice Enables a static method by specifying the target module to which the call must be delegated.
   * @param _module The target module.
   * @param _method The static method signature.
   */
  function enableStaticCall(address _module, bytes4 _method) external;
}