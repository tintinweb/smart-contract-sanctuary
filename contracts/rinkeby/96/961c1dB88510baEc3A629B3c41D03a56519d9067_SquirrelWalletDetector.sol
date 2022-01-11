// Copyright (C) 2018  Squirrel Labs Ltd. <https://squirrel.xyz>

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
pragma solidity ^0.8.3;
import './base/Owned.sol';

interface ISquirrelWallet {
  /**
   * @notice Returns the implementation of the wallet.
   * @return The wallet implementation.
   */
  function implementation() external view returns (address);
}

/**
 * @title SquirrelWalletDetector
 * @notice Simple contract to detect if a given address represents an Squirrel wallet.
 * The `isSquirrelWallet` method returns true if the codehash matches one of the deployed Proxy
 * and if the target implementation matches one of the deployed BaseWallet.
 * Only the owner of the contract can add code hash and implementations.
 * @author Julien Niset - <[email protected]>
 */
contract SquirrelWalletDetector is Owned {
  // The accepted code hashes
  bytes32[] private codes;
  // The accepted implementations
  address[] private implementations;
  // mapping to efficiently check if a code is accepted
  mapping(bytes32 => Info) public acceptedCodes;
  // mapping to efficiently check is an implementation is accepted
  mapping(address => Info) public acceptedImplementations;

  struct Info {
    bool exists;
    uint128 index;
  }

  // emits when a new accepted code is added
  event CodeAdded(bytes32 indexed code);
  // emits when a new accepted implementation is added
  event ImplementationAdded(address indexed implementation);

  constructor(bytes32[] memory _codes, address[] memory _implementations) {
    for (uint256 i = 0; i < _codes.length; i++) {
      addCode(_codes[i]);
    }
    for (uint256 j = 0; j < _implementations.length; j++) {
      addImplementation(_implementations[j]);
    }
  }

  /**
   * @notice Adds a new accepted code hash.
   * @param _code The new code hash.
   */
  function addCode(bytes32 _code) public onlyOwner {
    require(_code != bytes32(0), 'AWR: empty _code');
    Info storage code = acceptedCodes[_code];
    if (!code.exists) {
      codes.push(_code);
      code.exists = true;
      code.index = uint128(codes.length - 1);
      emit CodeAdded(_code);
    }
  }

  /**
   * @notice Adds a new accepted implementation.
   * @param _impl The new implementation.
   */
  function addImplementation(address _impl) public onlyOwner {
    require(_impl != address(0), 'AWR: empty _impl');
    Info storage impl = acceptedImplementations[_impl];
    if (!impl.exists) {
      implementations.push(_impl);
      impl.exists = true;
      impl.index = uint128(implementations.length - 1);
      emit ImplementationAdded(_impl);
    }
  }

  /**
   * @notice Adds a new accepted code hash and implementation from a deployed Squirrel wallet.
   * @param _squirrelWallet The deployed Squirrel wallet.
   */
  function addCodeAndImplementationFromWallet(address _squirrelWallet)
    external
    onlyOwner
  {
    bytes32 codeHash;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codeHash := extcodehash(_squirrelWallet)
    }
    addCode(codeHash);
    address implementation = ISquirrelWallet(_squirrelWallet).implementation();
    addImplementation(implementation);
  }

  /**
   * @notice Gets the list of accepted implementations.
   */
  function getImplementations() public view returns (address[] memory) {
    return implementations;
  }

  /**
   * @notice Gets the list of accepted code hash.
   */
  function getCodes() public view returns (bytes32[] memory) {
    return codes;
  }

  /**
   * @notice Checks if an address is an Squirrel wallet
   * @param _wallet The target wallet
   */
  function isSquirrelWallet(address _wallet) external view returns (bool) {
    bytes32 codeHash;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codeHash := extcodehash(_wallet)
    }
    return
      acceptedCodes[codeHash].exists &&
      acceptedImplementations[ISquirrelWallet(_wallet).implementation()].exists;
  }
}

/* ENTER COPYRIGHT INFORMATION HERE */

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