// SPDX-License-Identifier: MIT
/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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

    IERC20 constant _token = IERC20(address(0x3A1c1d1c06bE03cDDC4d3332F7C20e1B37c97CE9));
    address private _beneficiary = address(0x8875c123547bc477ec76F1FF09b4E1e787E11D35);
    Batch[5] private _batches;

    constructor() {
        // October, 2020
        _batches[0] = Batch(200000 * COIN, 1601510400, false);
        // November, 2020
        _batches[1] = Batch(300000 * COIN, 1604188800, false);
        // December, 2020
        _batches[2] = Batch(350000 * COIN, 1606780800, false);
        // March, 2021
        _batches[3] = Batch(350000 * COIN, 1614556800, false);
        // June, 2021
        _batches[4] = Batch(300000 * COIN, 1622505600, false);
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