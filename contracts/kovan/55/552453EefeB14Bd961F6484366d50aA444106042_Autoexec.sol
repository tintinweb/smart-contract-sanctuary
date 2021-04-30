/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
/// Autoexec.sol -- Adjust the DC IAM for all MCD collateral types

// Copyright (C) 2020  Brian McMichael

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
pragma solidity ^0.6.12;

interface Chainlog {
    function getAddress(bytes32) external returns (address);
}

interface AutoLine {
    function exec(bytes32) external returns (uint256);
}

interface IlkReg {
    function list() external returns (bytes32[] memory);
}

contract Autoexec {

    Chainlog private constant  cl = Chainlog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    IlkReg   private immutable ir;
    AutoLine private immutable al;

    constructor() public {
        ir = IlkReg(cl.getAddress("ILK_REGISTRY"));
        al = AutoLine(cl.getAddress("MCD_IAM_AUTO_LINE"));
    }

    function bat() public {
        bytes32[] memory _ilks = ir.list();
        for (uint256 i = 0; i < _ilks.length; i++) {
            al.exec(_ilks[i]);
        }
    }

    function registry() external view returns (address) {
        return address(ir);
    }

    function autoline() external view returns (address) {
        return address(al);
    }
}