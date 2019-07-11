/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

// hevm: flattened sources of src/spell.sol
pragma solidity >=0.4.23;

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

/* pragma solidity >=0.4.23; */

contract DSExec {
    function tryExec( address target, bytes memory data, uint value)
             internal
             returns (bool ok)
    {
        assembly {
            ok := call(gas, target, value, add(data, 0x20), mload(data), 0, 0)
        }
    }
    function exec( address target, bytes memory data, uint value)
             internal
    {
        if(!tryExec(target, data, value)) {
            revert("ds-exec-call-failed");
        }
    }

    // Convenience aliases
    function exec( address t, bytes memory c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes memory c )
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

/* pragma solidity >=0.4.23; */

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
            wad := callvalue
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

////// src/spell.sol
// spell.sol - An un-owned object that performs one action one time only

// Copyright (C) 2017, 2018 DappHub, LLC

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

/* pragma solidity >=0.4.23; */

/* import "ds-exec/exec.sol"; */
/* import "ds-note/note.sol"; */

contract DSSpell is DSExec, DSNote {
    address public whom;
    uint256 public mana;
    bytes   public data;
    bool    public done;

    constructor(address whom_, uint256 mana_, bytes memory data_) public {
        whom = whom_;
        mana = mana_;
        data = data_;
    }
    // Only marked &#39;done&#39; if CALL succeeds (not exceptional condition).
    function cast() public note {
        require(!done, "ds-spell-already-cast");
        exec(whom, data, mana);
        done = true;
    }
}