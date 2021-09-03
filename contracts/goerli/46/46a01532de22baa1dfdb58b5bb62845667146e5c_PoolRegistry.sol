/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/registry.sol

pragma solidity >=0.5.15 >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

////// lib/tinlake-auth/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

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
/* pragma solidity >=0.5.15; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
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

/* pragma solidity >=0.5.15 <0.6.0; */

/* import "ds-note/note.sol"; */

contract Auth is DSNote {
    mapping (address => uint) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
}

////// src/registry.sol
/* pragma solidity ^0.5.15; */
/* pragma experimental ABIEncoderV2; */

/* import "tinlake-auth/auth.sol"; */

contract PoolRegistry is Auth {
    struct Pool {
        address pool;
        bool    live;
        string  name;
        string  data;
    }

    event PoolCreated(address pool, bool live, string name, string data);
    event PoolUpdated(address pool, bool live, string name, string data);

    Pool[] public pools;
    mapping (address => uint) public lookup;


    constructor() public {
        wards[msg.sender] = 1;
        pools.push(Pool(address(this), false, "registry", ""));
    }

    function file(address pool, bool live, string memory name, string memory data) public auth {
        Pool memory p = Pool(pool, live, name, data);
        if (address(this) == pool) {
            pools[0] = p;
            return;
        }

        uint index = lookup[pool];
        if (index > 0) {
            pools[index] = p;
            emit PoolUpdated(pool, live, name, data);
        } else {
            pools.push(p);
            lookup[pool] = pools.length -1;
            emit PoolCreated(pool, live, name, data);
        }
    }

    function find(address pool) public view returns (bool live, string memory name, string memory data) {
        require(lookup[pool]>0, "pool-not-found");
        Pool memory p = pools[lookup[pool]];
        return (p.live, p.name, p.data);
    }

}