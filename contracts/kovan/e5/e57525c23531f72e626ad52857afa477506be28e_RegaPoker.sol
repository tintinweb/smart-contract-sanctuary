/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: AGPL-3.0
// The RegaPoker
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.6.12;

interface IlkReg {
    function list() external returns (bytes32[] memory);
    function pip(bytes32) external returns (address);
}

interface Chainlog {
    function getAddress(bytes32) external returns (address);
}

interface OSMLike {
    function src() external returns (address);
}

contract RegaPoker {

    string   constant ssig = "poke(bytes32)";
    string   constant osig = "poke()";
    string   constant rsig = "src()";

    Chainlog constant  cl = Chainlog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    address  immutable spot;
    IlkReg   immutable ir;

    bytes32[] public ilks;
    address[] public osms;

    constructor() public {
        ir = IlkReg(cl.getAddress("ILK_REGISTRY"));
        spot = cl.getAddress("MCD_SPOT");
    }

    function refresh() external {
        bytes32[] memory _ilks = ilks = ir.list();
        address[] memory _osms = new address[](_ilks.length);
        for (uint256 i = 0; i < _ilks.length; i++) {
            _osms[i] = ir.pip(_ilks[i]);
        }
        osms = _osms;
    }

    function poke() external {
        bytes32[] memory _ilks = ilks;
        address[] memory _osms = osms;
        bool _ok;
        for (uint256 i = 0; i < _ilks.length; i++) {
            (_ok,) = _osms[i].call(abi.encodeWithSignature(osig));
            (_ok,) = spot.call(abi.encodeWithSignature(ssig, _ilks[i]));
        }
    }

    // Backwards compatibility
    function pokeTemp() external {
        this.poke();
    }
}