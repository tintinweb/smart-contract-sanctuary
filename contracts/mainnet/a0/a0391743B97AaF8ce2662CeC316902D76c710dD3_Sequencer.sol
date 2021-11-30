/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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
pragma solidity 0.8.9;

// Coordination between Keeper Networks
// Only one should be active at a time
// Use the block number to switch between networks
contract Sequencer {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;

        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;

        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "Sequencer/not-authorized");
        _;
    }

    mapping (bytes32 => bool) public networks;
    bytes32[] public activeNetworks;
    uint256 public window;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event AddNetwork(bytes32 indexed network);
    event RemoveNetwork(bytes32 indexed network);

    constructor () {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what == "window") {
            window = data;
        } else revert("Sequencer/file-unrecognized-param");

        emit File(what, data);
    }
    function addNetwork(bytes32 network) external auth {
        require(!networks[network], "Sequencer/network-exists");

        activeNetworks.push(network);
        networks[network] = true;

        emit AddNetwork(network);
    }
    function removeNetwork(uint256 index) external auth {
        require(index < activeNetworks.length, "Sequencer/index-too-high");

        bytes32 network = activeNetworks[index];
        if (index != activeNetworks.length - 1) {
            activeNetworks[index] = activeNetworks[activeNetworks.length - 1];
        }
        activeNetworks.pop();
        networks[network] = false;

        emit RemoveNetwork(network);
    }

    // --- Views ---
    function isMaster(bytes32 network) external view returns (bool) {
        if (activeNetworks.length == 0) return false;

        return network == activeNetworks[(block.number / window) % activeNetworks.length];
    }
    function count() external view returns (uint256) {
        return activeNetworks.length;
    }
    function list() external view returns (bytes32[] memory) {
        return activeNetworks;
    }

}