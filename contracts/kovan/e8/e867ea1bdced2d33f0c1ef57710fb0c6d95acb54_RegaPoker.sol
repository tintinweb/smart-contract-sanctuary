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

    string   constant osig = "poke(bytes32)";
    string   constant ssig = "poke()";
    string   constant rsig = "src()";

    Chainlog constant  cl = Chainlog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    address  immutable spot;
    IlkReg   immutable ir;

    bytes32[] public ilks;
    address[] public osms;

    event Debug(bytes debug);
    event Debug(address);
    event Debug(bytes20);

    constructor() public {
        ir = IlkReg(cl.getAddress("ILK_REGISTRY"));
        spot = cl.getAddress("MCD_SPOT");
    }

    function try_opoke(address _osm) internal returns (bool ok) {
        (ok,) = _osm.call(abi.encodeWithSignature(osig));
    }

    function try_spoke(bytes32 _ilk) internal returns (bool ok) {
        (ok,) = spot.call(abi.encodeWithSignature(ssig, _ilk));
    }

    function try_src(address _osm) internal returns (address src) {
        (bool _ok, bytes memory _src) = _osm.call(abi.encodeWithSignature(rsig));
        emit Debug(_src);
        emit Debug(bytesToBytes20(_src));
        emit Debug(bytesToAddress(_src));
        src = (_ok) ? bytesToAddress(_src) : address(0);
    }

    function bytesToBytes20(bytes memory _b) internal pure returns (bytes20 _result) {
        assembly {
            _result := mload(add(_b, 44))
        }
    }

    function bytesToAddress(bytes memory _b) internal pure returns (address) {
        return address(bytesToBytes20(_b));
    }

    function refresh() external {
        bytes32[] memory _ilks = ilks = ir.list();
        address[] memory _osms = new address[](_ilks.length);
        for (uint256 i = 0; i < _ilks.length; i++) {
            _osms[i] = try_src(ir.pip(_ilks[i]));
        }
        osms = _osms;
    }

    function poke() external {
        bytes32[] memory _ilks = ilks;
        address[] memory _osms = osms;
        for (uint256 i = 0; i < _ilks.length; i++) {
            if (_osms[i] != address(0)) {
                try_opoke(_osms[i]);
            }
            try_spoke(_ilks[i]);
        }
    }

    // Backwards compatibility
    function pokeTemp() external {
        this.poke();
    }
}