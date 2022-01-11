/* ENTER COPYRIGHT INFORMATION HERE */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import './common/IModule.sol';
import '../wallet/IWallet.sol';

/**
 * @title SimpleUpgrader
 * @notice Temporary module used to add/remove other modules.
 * @author Olivier VDB - <[email protected]>, Julien Niset - <[email protected]>
 */
contract SimpleUpgrader is IModule {
  address[] public toDisable;
  address[] public toEnable;

  // *************** Constructor ********************** //

  constructor(address[] memory _toDisable, address[] memory _toEnable) {
    toDisable = _toDisable;
    toEnable = _toEnable;
  }

  // *************** External/Public Functions ********************* //

  /**
   * @notice Perform the upgrade for a wallet. This method gets called when SimpleUpgrader is temporarily added as a module.
   * @param _wallet The target wallet.
   */
  function init(address _wallet) external override {
    require(msg.sender == _wallet, 'SU: only wallet can call init');

    uint256 i = 0;
    //add new modules
    for (; i < toEnable.length; i++) {
      IWallet(_wallet).authoriseModule(toEnable[i], true);
    }
    //remove old modules
    for (i = 0; i < toDisable.length; i++) {
      IWallet(_wallet).authoriseModule(toDisable[i], false);
    }
    // SimpleUpgrader did its job, we no longer need it as a module
    IWallet(_wallet).authoriseModule(address(this), false);
  }

  /**
   * @inheritdoc IModule
   */
  function addModule(
    address, /*_wallet*/
    address /*_module*/
  ) external pure override {
    revert('SU: method not implemented');
  }

  /**
   * @inheritdoc IModule
   */
  function supportsStaticCall(
    bytes4 /*_methodId*/
  ) external pure override returns (bool _isSupported) {
    return false;
  }
}

/* ENTER COPYRIGHT INFORMATION HERE */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

/**
 * @title IModule
 * @notice Interface for a Module.
 * @author Julien Niset - <[email protected]>, Olivier VDB - <[email protected]>
 */
interface IModule {
  /**
   * @notice Adds a module to a wallet. Cannot execute when wallet is locked (or under recovery)
   * @param _wallet The target wallet.
   * @param _module The modules to authorise.
   */
  function addModule(address _wallet, address _module) external;

  /**
   * @notice Inits a Module for a wallet by e.g. setting some wallet specific parameters in storage.
   * @param _wallet The wallet.
   */
  function init(address _wallet) external;

  /**
   * @notice Returns whether the module implements a callback for a given static call method.
   * @param _methodId The method id.
   */
  function supportsStaticCall(bytes4 _methodId)
    external
    view
    returns (bool _isSupported);
}

/* ENTER COPYRIGHT INFORMATION HERE */

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