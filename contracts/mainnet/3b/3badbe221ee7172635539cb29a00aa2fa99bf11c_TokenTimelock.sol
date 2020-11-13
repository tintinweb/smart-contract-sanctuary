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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenTimelock {
    uint256 constant COIN = 10 ** 18;

    struct Batch {
      uint256 amount;
      uint256 time;
      bool spent;
    }

    IERC20 constant _token = IERC20(address(0xf6f8A2c3D57E77f6d2B3bc27AdF1D19ca4179163));
    address private _beneficiary = address(0x218A97D337dEcBd8E11f205E7EE8f7E5769d5d84);
    Batch[5] private _batches;

    constructor() {
        // 12, 2020
        _batches[0] = Batch(100000 * COIN, 1606780800, false);
        // 1, 2021
        _batches[1] = Batch(150000 * COIN, 1609459200, false);
        // 2, 2021
        _batches[2] = Batch(150000 * COIN, 1612137600, false);
        // 3, 2021
        _batches[3] = Batch(150000 * COIN, 1614556800, false);
        // 4, 2021
        _batches[4] = Batch(150000 * COIN, 1617235200, false);
    }

    function updateBeneficiary(address newBeneficiary) external {
        require(msg.sender == _beneficiary);
        _beneficiary = newBeneficiary;
    }

    function release(uint b) external {
        require(!_batches[b].spent);
        require(block.timestamp >= _batches[b].time);
        require(_token.transfer(_beneficiary, _batches[b].amount));
        _batches[b].spent = true;
    }
}