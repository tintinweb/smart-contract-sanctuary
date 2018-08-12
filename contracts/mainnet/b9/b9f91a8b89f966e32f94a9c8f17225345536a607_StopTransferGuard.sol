pragma solidity ^0.4.13;

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

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
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

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}

contract TokenTransferGuard {
    function onTokenTransfer(address _from, address _to, uint _amount) public returns (bool);
}

contract StopTransferGuard is DSStop, TokenTransferGuard {
    
    mapping (address => bool) public isBlack;

    function StopTransferGuard(address[] _blacks) public {
        for (uint i=0; i<_blacks.length; i++) {
            isBlack[_blacks[i]] = true;
        }
    }
    
    function onTokenTransfer(address _from, address _to, uint _amount) public returns (bool)
    {
        if (!stopped && isBlack[_from])
        {
            return false;
        }
        
        return true;
    }
    
    function addBlack(address black) public auth
    {
        isBlack[black] = true;
    }
    
    function removeBlack(address black) public auth
    {
        isBlack[black] = false;
    }
}