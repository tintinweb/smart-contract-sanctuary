/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

/**************************************************************************
 *            ____        _                              
 *           / ___|      | |     __ _  _   _   ___  _ __ 
 *          | |    _____ | |    / _` || | | | / _ \| '__|
 *          | |___|_____|| |___| (_| || |_| ||  __/| |   
 *           \____|      |_____|\__,_| \__, | \___||_|   
 *                                     |___/             
 * 
 **************************************************************************
 *
 * The MIT License (MIT)
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2021 Cyril Lapinte
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************
 *
 * Flatten Contract: TimeLock
 *
 *
 **************************************************************************/

// File: @c-layer/common/contracts/operable/Ownable.sol


pragma solidity ^0.6.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * @dev functions, this simplifies the implementation of "user permissions".
 *
 *
 * Error messages
 *   OW01: Message sender is not the owner
 *   OW02: New owner must be valid
*/
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "OW01");
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "OW02");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


// File: @c-layer/governance/contracts/lock/TimeLock.sol


pragma solidity ^0.6.0;


/**
 * @title TimeLock
 * @dev Time locked contract
 *
 * Error messages
 *   TL01: Contract is locked
 *   TL02: Target must be defined
 *   TL03: Cannot be locked in the past
 *   TL04: Execution must be successfull
 */
contract TimeLock is Ownable {

  address payable public target;
  uint64 public lockedUntil;

  modifier whenUnlocked() {
    require(lockedUntil < currentTime(), "TL01");
    _;
  }

  constructor(address payable _target, uint64 _lockedUntil) public {
    require(_target != address(0), "TL02");
    require(_lockedUntil > currentTime(), "TL03");
    lockedUntil = _lockedUntil;
    target = _target;
  }

  receive() external payable {
    require(callInternal(), "TL04");
  }

  fallback() external payable {
    require(callInternal(), "TL04");
  }

  function callInternal() internal onlyOwner whenUnlocked returns (bool) {
    (bool success, ) =
    // solhint-disable-next-line avoid-call-value, avoid-low-level-calls
    target.call{value: msg.value}(msg.data);
    return success;
  }

  /**
   * @dev current time
   */
  function currentTime() internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return now;
  }
}