// hevm: flattened sources of src/burner.sol
pragma solidity ^0.4.24;

////// lib/ds-guard/lib/ds-auth/src/auth.sol
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

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

////// lib/ds-guard/src/guard.sol
// guard.sol -- simple whitelist implementation of DSAuthority

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

/* import "ds-auth/auth.sol"; */

contract DSGuardEvents {
    event LogPermit(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );

    event LogForbid(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );
}

contract DSGuard is DSAuth, DSAuthority, DSGuardEvents {
    bytes32 constant public ANY = bytes32(uint(-1));

    mapping (bytes32 => mapping (bytes32 => mapping (bytes32 => bool))) acl;

    function canCall(
        address src_, address dst_, bytes4 sig
    ) public view returns (bool) {
        bytes32 src = bytes32(src_);
        bytes32 dst = bytes32(dst_);

        return acl[src][dst][sig]
            || acl[src][dst][ANY]
            || acl[src][ANY][sig]
            || acl[src][ANY][ANY]
            || acl[ANY][dst][sig]
            || acl[ANY][dst][ANY]
            || acl[ANY][ANY][sig]
            || acl[ANY][ANY][ANY];
    }

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(address src, address dst, bytes32 sig) public {
        permit(bytes32(src), bytes32(dst), sig);
    }
    function forbid(address src, address dst, bytes32 sig) public {
        forbid(bytes32(src), bytes32(dst), sig);
    }

}

contract DSGuardFactory {
    mapping (address => bool)  public  isGuard;

    function newGuard() public returns (DSGuard guard) {
        guard = new DSGuard();
        guard.setOwner(msg.sender);
        isGuard[guard] = true;
    }
}