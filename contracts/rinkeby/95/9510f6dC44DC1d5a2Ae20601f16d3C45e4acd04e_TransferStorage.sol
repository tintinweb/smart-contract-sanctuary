// Copyright (C) 2020  Argent Labs Ltd. <https://argent.xyz>

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
 * @title ITransferStorage
 * @notice TransferStorage interface
 */
interface ITransferStorage {
  function setWhitelist(
    address _wallet,
    address _target,
    uint256 _value
  ) external;

  function getWhitelist(address _wallet, address _target)
    external
    view
    returns (uint256);
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

pragma solidity ^0.5.4;

import './Storage.sol';
import '../../infrastructure/storage/ITransferStorage.sol';

/**
 * @title TransferStorage
 * @notice Contract storing the state of wallets related to transfers (limit and whitelist).
 * The contract only defines basic setters and getters with no logic. Only modules authorised
 * for a wallet can modify its state.
 * @author Julien Niset - <[email protected]>
 */
contract TransferStorage is ITransferStorage, Storage {
  // wallet specific storage
  mapping(address => mapping(address => uint256)) internal whitelist;

  // *************** External Functions ********************* //

  /**
   * @notice Lets an authorised module add or remove an account from the whitelist of a wallet.
   * @param _wallet The target wallet.
   * @param _target The account to add/remove.
   * @param _value The epoch time at which an account starts to be whitelisted, or zero if the account is not whitelisted
   */
  function setWhitelist(
    address _wallet,
    address _target,
    uint256 _value
  ) external onlyModule(_wallet) {
    whitelist[_wallet][_target] = _value;
  }

  /**
   * @notice Gets the whitelist state of an account for a wallet.
   * @param _wallet The target wallet.
   * @param _target The account.
   * @return The epoch time at which an account starts to be whitelisted, or zero if the account is not whitelisted
   */
  function getWhitelist(address _wallet, address _target)
    external
    view
    returns (uint256)
  {
    return whitelist[_wallet][_target];
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