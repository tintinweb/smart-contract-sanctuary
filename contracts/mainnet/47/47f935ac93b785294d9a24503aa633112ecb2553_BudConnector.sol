/**
 *Submitted for verification at Etherscan.io on 2020-10-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-07
*/

/* Copyright 2020, Smart future labs.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

pragma solidity ^0.5.12;

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
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
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
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
            return authority.canCall(src, address(this), sig);
        }
    }
}

interface OSMLike {
    function peep() external view returns (bytes32, bool);
    function hop()  external view returns(uint16);
    function zzz()  external view returns(uint64);
}

interface Spotty {
    function ilks(bytes32) external view returns (PipLike pip, uint256 mat);
}

interface PipLike {
    function read() external view returns (bytes32);
}

interface EndLike {
    function spot() external view returns (Spotty);
}

contract BudConnector is DSAuth {

    mapping(address => bool) public authorized;
    OSMLike public osm;
    EndLike public end;

    constructor(OSMLike osm_, EndLike end_) public {
        osm = osm_;
        end = end_;
    }

    function authorize(address addr) external auth {
        authorized[addr] = true;
    }

    function peep() external view returns (bytes32, bool) {
        require(authorized[msg.sender], "!authorized");
        return osm.peep(); 
    }

    function read(bytes32 ilk) external view returns (bytes32) {
        require(authorized[msg.sender], "!authorized");
        (PipLike pip,) = end.spot().ilks(ilk);
        return pip.read();
    }

    function hop() external view returns(uint16) {
        return osm.hop();
    }

    function zzz() external view returns(uint64) {
        return osm.zzz();
    }
}