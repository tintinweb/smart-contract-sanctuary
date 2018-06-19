pragma solidity ^0.4.23;

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

contract DSNote {
    event LogNote(
        bytes4   indexed sig,
        address  indexed guy,
        bytes32  indexed foo,
        bytes32  indexed bar,
        uint wad,
        bytes fax
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

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}

contract ERC20Events {
    event Approval(address indexed from, address indexed to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);

    function balanceOf(address guy) public view returns (uint);

    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint value) public returns (bool);

    function transfer(address dst, uint value) public returns (bool);

    function transferFrom(
        address src, address dst, uint value
    ) public returns (bool);
}

contract DCUCoin is ERC20, DSMath, DSStop {
    string public    name;
    string public    symbol;
    uint8 public     decimals = 18;
    uint256 internal supply;
    mapping(address => uint256)                      balances;
    mapping(address => mapping(address => uint256))  approvals;

    constructor(uint256 token_supply, string token_name, string token_symbol) public {
        balances[msg.sender] = token_supply;
        supply = token_supply;
        name = token_name;
        symbol = token_symbol;
    }

    function() public payable {
        revert();
    }

    function setName(string token_name) auth public {
        name = token_name;
    }

    function totalSupply() constant public returns (uint256) {
        return supply;
    }

    function balanceOf(address src) public view returns (uint) {
        return balances[src];
    }

    function allowance(address src, address guy) public view returns (uint) {
        return approvals[src][guy];
    }

    function transfer(address dst, uint value) public stoppable returns (bool) {
        // uint never less than 0. The negative number will become to a big positive number
        require(value < supply);
        require(balances[msg.sender] >= value);

        balances[msg.sender] = sub(balances[msg.sender], value);
        balances[dst] = add(balances[dst], value);

        emit Transfer(msg.sender, dst, value);

        return true;
    }

    function transferFrom(address src, address dst, uint value) public stoppable returns (bool)
    {
        // uint never less than 0. The negative number will become to a big positive number
        require(value < supply);
        require(approvals[src][msg.sender] >= value);
        require(balances[src] >= value);

        approvals[src][msg.sender] = sub(approvals[src][msg.sender], value);
        balances[src] = sub(balances[src], value);
        balances[dst] = add(balances[dst], value);

        emit Transfer(src, dst, value);

        return true;
    }

    function approve(address guy, uint value) public stoppable returns (bool) {
        // uint never less than 0. The negative number will become to a big positive number
        require(value < supply);

        approvals[msg.sender][guy] = value;

        emit Approval(msg.sender, guy, value);

        return true;
    }
}