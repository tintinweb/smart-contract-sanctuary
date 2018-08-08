pragma solidity ^0.4.18;

contract PieTokenBase {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);

    function PieTokenBase() public {
        
    }
    
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint wad) public returns (bool) {
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);

        Transfer(src, dst, wad);
        
        return true;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        Approval(msg.sender, guy, wad);
        
        return true;
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x - y) <= x);
    }
}

contract PieToken is PieTokenBase {
    string  public  symbol = "PIE";
    string  public name = "CANDY PIE";
    uint256  public  decimals = 18; 
    address public owner;

    function PieToken() public {
        _supply = 10*(10**8)*(10**18);
        owner = msg.sender;
        _balances[msg.sender] = _supply;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return super.transfer(dst, wad);
    }

    function transferFrom( address src, address dst, uint wad ) public returns (bool) {
        return super.transferFrom(src, dst, wad);
    }

    function approve(address guy, uint wad) public returns (bool) {
        return super.approve(guy, wad);
    }

    function burn(uint128 wad) public {
        require(msg.sender==owner);
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }
}