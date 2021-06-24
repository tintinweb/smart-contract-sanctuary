/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: AGPL-3.0
// The OmegaPoker
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

contract OmegaPoker {

    bytes4   constant spotselector = 0x1504460f;  // "poke(bytes32)"
    bytes4   constant osmselector  = 0x18178358;  // "poke()"
    bytes4   constant srcselector  = 0x2e7dc6af;  // "src()"

    Chainlog constant cl = Chainlog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    bytes32[] public ilks;
    address[] public osms;

    IlkReg    public immutable registry;
    address   public immutable spot;

    constructor() public {
        registry = IlkReg(cl.getAddress("ILK_REGISTRY"));
        spot     = cl.getAddress("MCD_SPOT");
    }

    function osmCount() external view returns (uint256) {
        return osms.length;
    }

    function ilkCount() external view returns (uint256) {
        return ilks.length;
    }

    function refresh() external {
        delete osms;
        delete ilks;
        bytes32[] memory _ilks = registry.list();
        for (uint256 i = 0; i < _ilks.length; i++) {

            address _pip = registry.pip(_ilks[i]);

            // OSM's and LP oracles have src() function
            (bool ok,) = _pip.call(abi.encodeWithSelector(srcselector));

            if (ok) {
                ilks.push(_ilks[i]);

                bool exists;
                for (uint j = 0; j < osms.length; j++) {
                    if (osms[j] == _pip) {
                        exists = true;
                    }
                }

                if (!exists) {
                    osms.push(_pip);
                }
            }
        }
    }

    function poke() external {
        bytes32[] memory _ilks = ilks;
        address[] memory _osms = osms;
        bool _ok;
        for (uint256 i = 0; i < _ilks.length; i++) {
            (_ok,) = spot.call(abi.encodeWithSelector(spotselector, _ilks[i]));
        }
        for (uint256 i = 0; i < _osms.length; i++) {
            (_ok,) = _osms[i].call(abi.encodeWithSelector(osmselector));
        }

    }
}