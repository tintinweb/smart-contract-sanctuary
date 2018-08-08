// hevm: flattened sources of src/update.sol
pragma solidity ^0.4.24;

////// lib/ds-exec/src/exec.sol
// exec.sol - base contract used by anything that wants to do "untyped" calls

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity ^0.4.23; */

contract DSExec {
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            revert();
        }
    }

    // Convenience aliases
    function exec( address t, bytes c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

////// lib/ds-note/src/note.sol
/// note.sol -- the `note&#39; modifier, for logging calls as events

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

/* pragma solidity ^0.4.23; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

////// src/update.sol
// DaiUpdate.sol - increase debt ceiling and update oracles

// Copyright (C) 2018 DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.4.24; */

/* import "ds-exec/exec.sol"; */
/* import "ds-note/note.sol"; */

contract DaiUpdate is DSExec, DSNote {

    uint256 constant public CAP    = 100000000 * 10 ** 18; // 100,000,000 DAI
    address constant public MOM    = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C; // SaiMom
    address constant public PIP    = 0x40C449c0b74eA531371290115296e7E28b99cf0f; // ETH/USD OSM
    address constant public PEP    = 0x5C1fc813d9c1B5ebb93889B3d63bA24984CA44B7; // MKR/USD OSM
    address constant public MKRUSD = 0x99041F808D598B782D5a3e498681C2452A31da08; // MKR/USD Medianizer
    address constant public FEED1  = 0xa3E22729A22a8fFEdccBbD614B7430615976E463; // New MKR Feed 1
    address constant public FEED2  = 0x1ec3140C163b6fee00833Ba8ae30A7ba12201063; // New MKR Feed 2

    bool public done;

    function run() public note {
        require(!done);
        // increase cap to 100,000,000
        exec(MOM, abi.encodeWithSignature("setCap(uint256)", CAP), 0);
       
        // set PIP to be the new ETH/USD OSM
        exec(MOM, abi.encodeWithSignature("setPip(address)", PIP), 0);
        
        // set PEP to be the new MKR/USD OSM
        exec(MOM, abi.encodeWithSignature("setPep(address)", PEP), 0);

        // Set 2 new feeds for MKR/USD Medianizer
        exec(MKRUSD, abi.encodeWithSignature("set(address)", FEED1), 0);
        exec(MKRUSD, abi.encodeWithSignature("set(address)", FEED2), 0);
        
        // Set MKR/USD Medianizer to be 3/5 feeds
        exec(MKRUSD, abi.encodeWithSignature("setMin(uint96)", 3), 0);

        done = true;
    }
}