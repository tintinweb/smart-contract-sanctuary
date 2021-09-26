/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: linear_vester.sol

/*
Simple linear vesting with an end date. 50% after half of time, 70% after 70% etc.
*/
contract LinearVester {
  IERC20 public immutable lockedToken;
  address immutable public beneficiary;

  bool public locked = false;
  uint public startTimestamp;
  uint public endTimestamp;
  uint public startingAmount;
  uint public withdrawnAmount;

  constructor(IERC20 token) {
    lockedToken = token;
    beneficiary = msg.sender;
  }

  function createLockup(uint256 amount, uint256 _endTimestamp) external {
    require(msg.sender == beneficiary);
    require(!locked);
    require(lockedToken.transferFrom(msg.sender, address(this), amount));
    startingAmount = amount;
    endTimestamp = _endTimestamp;
    startTimestamp = block.timestamp;
    require(startTimestamp < endTimestamp);
    locked = true;
  }

  function getUnlocked() public view returns (uint256) {
    if(block.timestamp >= endTimestamp) {
      return startingAmount;
    }
    uint duration = endTimestamp - startTimestamp;
    uint passed = block.timestamp - startTimestamp;
    uint vestedAmount = startingAmount*passed/duration;
    return vestedAmount;
  }

  function withdrawVested() external {
    require(msg.sender == beneficiary);
    uint toWithdraw;
    if(block.timestamp >= endTimestamp) {
      //vesting ended - everything
      toWithdraw = lockedToken.balanceOf(address(this));
    }
    else {
      toWithdraw = getUnlocked()-withdrawnAmount;
    }
    require(lockedToken.transfer(beneficiary, toWithdraw));
    withdrawnAmount += toWithdraw;
  }
}

/* MIT License
* ===========
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/