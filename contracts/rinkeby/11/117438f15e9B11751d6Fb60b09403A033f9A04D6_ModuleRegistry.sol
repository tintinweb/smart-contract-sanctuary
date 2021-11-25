pragma solidity >=0.5.4 <0.9.0;

/**
 * ERC20 contract interface.
 */
interface ERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
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
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {
  // The owner
  address public owner;

  event OwnerChanged(address indexed _newOwner);

  /**
   * @notice Throws if the sender is not the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, 'Must be owner');
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @notice Lets the owner transfer ownership of the contract to a new owner.
   * @param _newOwner The new owner.
   */
  function changeOwner(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), 'Address must not be null');
    owner = _newOwner;
    emit OwnerChanged(_newOwner);
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
import '../infrastructure/base/Owned.sol';
import '../../lib_0.5/other/ERC20.sol';

/**
 * @title ModuleRegistry
 * @notice Registry of authorised modules.
 * Modules must be registered before they can be authorised on a wallet.
 * @author Julien Niset - <[email protected]>
 */
contract ModuleRegistry is Owned {
  mapping(address => Info) internal modules;
  mapping(address => Info) internal upgraders;

  event ModuleRegistered(address indexed module, bytes32 name);
  event ModuleDeRegistered(address module);
  event UpgraderRegistered(address indexed upgrader, bytes32 name);
  event UpgraderDeRegistered(address upgrader);

  struct Info {
    bool exists;
    bytes32 name;
  }

  /**
   * @notice Registers a module.
   * @param _module The module.
   * @param _name The unique name of the module.
   */
  function registerModule(address _module, bytes32 _name) external onlyOwner {
    require(!modules[_module].exists, 'MR: module already exists');
    modules[_module] = Info({exists: true, name: _name});
    emit ModuleRegistered(_module, _name);
  }

  /**
   * @notice Deregisters a module.
   * @param _module The module.
   */
  function deregisterModule(address _module) external onlyOwner {
    require(modules[_module].exists, 'MR: module does not exist');
    delete modules[_module];
    emit ModuleDeRegistered(_module);
  }

  /**
   * @notice Registers an upgrader.
   * @param _upgrader The upgrader.
   * @param _name The unique name of the upgrader.
   */
  function registerUpgrader(address _upgrader, bytes32 _name)
    external
    onlyOwner
  {
    require(!upgraders[_upgrader].exists, 'MR: upgrader already exists');
    upgraders[_upgrader] = Info({exists: true, name: _name});
    emit UpgraderRegistered(_upgrader, _name);
  }

  /**
   * @notice Deregisters an upgrader.
   * @param _upgrader The _upgrader.
   */
  function deregisterUpgrader(address _upgrader) external onlyOwner {
    require(upgraders[_upgrader].exists, 'MR: upgrader does not exist');
    delete upgraders[_upgrader];
    emit UpgraderDeRegistered(_upgrader);
  }

  /**
   * @notice Utility method enbaling the owner of the registry to claim any ERC20 token that was sent to the
   * registry.
   * @param _token The token to recover.
   */
  function recoverToken(address _token) external onlyOwner {
    uint256 total = ERC20(_token).balanceOf(address(this));
    ERC20(_token).transfer(msg.sender, total);
  }

  /**
   * @notice Gets the name of a module from its address.
   * @param _module The module address.
   * @return the name.
   */
  function moduleInfo(address _module) external view returns (bytes32) {
    return modules[_module].name;
  }

  /**
   * @notice Gets the name of an upgrader from its address.
   * @param _upgrader The upgrader address.
   * @return the name.
   */
  function upgraderInfo(address _upgrader) external view returns (bytes32) {
    return upgraders[_upgrader].name;
  }

  /**
   * @notice Checks if a module is registered.
   * @param _module The module address.
   * @return true if the module is registered.
   */
  function isRegisteredModule(address _module) external view returns (bool) {
    return modules[_module].exists;
  }

  /**
   * @notice Checks if a list of modules are registered.
   * @param _modules The list of modules address.
   * @return true if all the modules are registered.
   */
  function isRegisteredModule(address[] calldata _modules)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < _modules.length; i++) {
      if (!modules[_modules[i]].exists) {
        return false;
      }
    }
    return true;
  }

  /**
   * @notice Checks if an upgrader is registered.
   * @param _upgrader The upgrader address.
   * @return true if the upgrader is registered.
   */
  function isRegisteredUpgrader(address _upgrader)
    external
    view
    returns (bool)
  {
    return upgraders[_upgrader].exists;
  }
}