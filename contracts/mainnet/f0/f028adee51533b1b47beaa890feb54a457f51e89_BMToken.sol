pragma solidity ^0.4.16;

contract BMToken {
    string  public  name = "BMChain Token";
    string  public  symbol = "BMT";
    uint256  public  decimals = 18;

    uint256 _supply = 0;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _approvals;

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);

    address ico_contract;
    address public owner;

    function BMToken(){
        ico_contract = address(0x0);
        owner = msg.sender;
    }

    modifier isOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwner(address new_owner) isOwner
    {
        assert(new_owner!=address(0x0));
        assert(new_owner!=address(this));
        owner = new_owner;
    }

    function setICOContract(address new_address) isOwner
    {
        assert(ico_contract==address(0x0));
        assert(new_address!=address(0x0));
        assert(new_address!=address(this));
        ico_contract = new_address;
    }

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function totalSupply() constant external returns (uint256) {
        return _supply;
    }

    function balanceOf(address src) constant external returns (uint256) {
        return _balances[src];
    }

    function allowance(address src, address where) constant external returns (uint256) {
        return _approvals[src][where];
    }

    function transfer(address where, uint amount) external returns (bool) {
        assert(where != address(this));
        assert(where != address(0));
        assert(_balances[msg.sender] >= amount);

        _balances[msg.sender] = sub(_balances[msg.sender], amount);
        _balances[where] = add(_balances[where], amount);

        Transfer(msg.sender, where, amount);

        return true;
    }

    function transferFrom(address src, address where, uint amount) external returns (bool) {
        assert(where != address(this));
        assert(where != address(0));
        assert(_balances[src] >= amount);
        assert(_approvals[src][msg.sender] >= amount);

        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], amount);
        _balances[src] = sub(_balances[src], amount);
        _balances[where] = add(_balances[where], amount);

        Transfer(src, where, amount);

        return true;
    }

    function approve(address where, uint256 amount) external returns (bool) {
        assert(where != address(this));
        assert(where != address(0));
        _approvals[msg.sender][where] = amount;

        Approval(msg.sender, where, amount);

        return true;
    }

    function mintTokens(address holder, uint256 amount) external
    {
        assert(msg.sender == ico_contract);
        _balances[holder] = add(_balances[holder], amount);
        _supply = add(_supply, amount);
        Transfer(address(0x0), holder, amount);
    }
}