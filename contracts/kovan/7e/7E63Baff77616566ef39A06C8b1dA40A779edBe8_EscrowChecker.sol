/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Ternio: EscrowChecker.sol
*
* Latest source (may be newer): https://github.com/Ternioio/ternio/blob/master/contracts/EscrowChecker.sol
* Docs: https://docs.ternio.io/contracts/EscrowChecker
*
* Contract Dependencies: (none)
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2021 Ternio
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



pragma solidity ^0.5.16;


interface ITernioEscrow {
    function numVestingEntries(address account) external view returns (uint);

    function getVestingScheduleEntry(address account, uint index) external view returns (uint[2] memory);
}


contract EscrowChecker {
    ITernioEscrow public ternio_escrow;

    constructor(ITernioEscrow _esc) public {
        ternio_escrow = _esc;
    }

    function checkAccountSchedule(address account) public view returns (uint[16] memory) {
        uint[16] memory _result;
        uint schedules = ternio_escrow.numVestingEntries(account);
        for (uint i = 0; i < schedules; i++) {
            uint[2] memory pair = ternio_escrow.getVestingScheduleEntry(account, i);
            _result[i * 2] = pair[0];
            _result[i * 2 + 1] = pair[1];
        }
        return _result;
    }
}