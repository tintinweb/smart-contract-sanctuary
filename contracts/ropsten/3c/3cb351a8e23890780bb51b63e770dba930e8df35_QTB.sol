// Copyright (C) QTB Team
contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSMath {

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

}

contract QTB is ERC20,DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    string   public  symbol;
    string   public  name;
    uint256  public  decimals = 18;
    address  public  owner;
    bool     public  stopped;
    


    function QTB(string _symbol,string _name,address _owner) {
        symbol=_symbol;
        name=_name;
        owner=_owner;
    }

    modifier auth {
        assert (msg.sender==owner);
        _;
    }
    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() auth  {
        stopped = true;
    }
    function start() auth  {
        stopped = false;
    }

    function totalSupply() constant returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) constant returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) stoppable returns (bool) {
        assert(_balances[msg.sender] >= wad);

        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(msg.sender, dst, wad);

        return true;
    }

    function transferFrom(address src, address dst, uint wad)stoppable returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);

        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint256 wad) stoppable returns (bool) {
        _approvals[msg.sender][guy] = wad;

        Approval(msg.sender, guy, wad);

        return true;
    }
    function mint(address dst,uint128 wad) auth stoppable {
        _balances[dst] = add(_balances[dst], wad);
        _supply = add(_supply, wad);
    }

    event LogSetOwner     (address indexed owner);

    function setOwner(address owner_) auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }
}