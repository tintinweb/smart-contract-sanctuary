/*
                    |   _|_)                             
  __|  _ \  _ \  _` |  |   | __ \   _` | __ \   __|  _ \ 
\__ \  __/  __/ (   |  __| | |   | (   | |   | (     __/ 
____/\___|\___|\__,_| _|  _|_|  _|\__,_|_|  _|\___|\___| 
* Home: https://superseed.cc
* https://t.me/superseedgroup
* https://twitter.com/superseedtoken
* https://superseedtoken.medium.com
* MIT License
* ===========
*
* Copyright (c) 2020 Superseed
* SPDX-License-Identifier: MIT
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
pragma solidity ^0.7.0;

import "./Seed.sol";

abstract contract ReentrancyGuard {
  bool private _entered;

  modifier noReentrancy() {
    require(!_entered);
    _entered = true;
    _;
    _entered = false;
  }
}

interface ISeedBorrower {
  function loaned(uint256 amount, uint256 owed) external;
}

contract SeedLoan is ReentrancyGuard, Ownable {
  Seed private _SEED;
  using SafeMath for uint256;
  uint256 internal _feeDivisor = 100;
  
  event Loaned(uint256 amount, uint256 profit);

  constructor(address SEED, address seedStake) Ownable(seedStake) {
    _SEED = Seed(SEED);
  }

  // loan out SEED from the staked funds
  function loan(uint256 amount) external noReentrancy {
    // set a profit of 1%
    uint256 profit = amount.div(_feeDivisor);
    uint256 owed = amount.add(profit);
    // transfer the funds
    require(_SEED.transferFrom(owner(), msg.sender, amount));

    // call the loaned function
    ISeedBorrower(msg.sender).loaned(amount, owed);

    // transfer back to the staking pool
    require(_SEED.transferFrom(msg.sender, owner(), amount));
    // take the profit
    require(_SEED.transferFrom(msg.sender, address(this), profit));
    // burn it, distributing its value to the ecosystem
    require(_SEED.burn(profit));

    emit Loaned(amount, profit);
  }
}
