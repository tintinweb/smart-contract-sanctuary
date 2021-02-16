/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// File: contracts\timelock\IDSPause.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

/**
 * @title IDSPause
 * @author Alexander Schlindwein
 *
 * @dev Interface for the timelock
 */
interface IDSPause {
    function setOwner(address owner) external;
    function setDelay(uint delay) external;
    function soul(address usr) external view returns (bytes32 tag);
    function plot(address usr, bytes32 tag, bytes memory fax, uint eta) external;
    function drop(address usr, bytes32 tag, bytes memory fax, uint eta) external;
    function exec(address usr, bytes32 tag, bytes memory fax, uint eta) external returns (bytes memory out);
}

// File: contracts\timelock\DSPauseProxy.sol

// Copyright (C) 2019 David Terry <[email protected]>
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

// Updated by Alexander Schlindwein


contract DSPauseProxy {
    address public _owner;
    modifier auth { require(msg.sender == _owner, "ds-pause-proxy-unauthorized"); _; }
    constructor() public { _owner = msg.sender; }

    function exec(address usr, bytes memory fax)
        public auth
        returns (bytes memory out)
    {
        bool ok;
        (ok, out) = usr.delegatecall(fax);
        require(ok, "ds-pause-delegatecall-error");
    }
}

// File: contracts\timelock\DSPause.sol

// Copyright (C) 2019 David Terry <[email protected]>
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

// Updated by Alexander Schlindwein


contract DSPause is IDSPause {

    address public _owner;
    mapping (bytes32 => bool) public _plans;
    DSPauseProxy public _proxy;
    uint         public _delay;

    modifier wait { require(msg.sender == address(_proxy), "ds-pause-undelayed-call"); _; }
    modifier auth { require(msg.sender == _owner, "ds-pause-unauthorized"); _; }

    constructor(uint delay, address owner) public {
        require(owner != address(0), "invalid-params");
        _delay = delay;
        _owner = owner;
        _proxy = new DSPauseProxy();
    }

    function setOwner(address owner) public wait override {
        require(owner != address(0), "invalid-params");
        _owner = owner;
    }

    function setDelay(uint delay) public wait override {
        _delay = delay;
    }

    function hash(address usr, bytes32 tag, bytes memory fax, uint eta)
        internal pure
        returns (bytes32)
    {
        return keccak256(abi.encode(usr, tag, fax, eta));
    }

    function soul(address usr)
        public view override
        returns (bytes32 tag)
    {
        assembly { tag := extcodehash(usr) }
    }

    function plot(address usr, bytes32 tag, bytes memory fax, uint eta)
        public auth override
    {
        require(eta >= add(now, _delay), "ds-pause-delay-not-respected");
        _plans[hash(usr, tag, fax, eta)] = true;
    }

    function drop(address usr, bytes32 tag, bytes memory fax, uint eta)
        public auth override
    {
        _plans[hash(usr, tag, fax, eta)] = false;
    }

    function exec(address usr, bytes32 tag, bytes memory fax, uint eta)
        public auth override
        returns (bytes memory out)
    {
        require(_plans[hash(usr, tag, fax, eta)], "ds-pause-unplotted-plan");
        require(soul(usr) == tag,                   "ds-pause-wrong-codehash");
        require(now >= eta,                          "ds-pause-premature-exec");

        _plans[hash(usr, tag, fax, eta)] = false;

        out = _proxy.exec(usr, fax);
        require(_proxy._owner() == address(this), "ds-pause-illegal-storage-change");
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x, "ds-pause-addition-overflow");
    }
}