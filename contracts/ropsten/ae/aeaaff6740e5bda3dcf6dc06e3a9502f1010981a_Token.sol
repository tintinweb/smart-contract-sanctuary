pragma solidity 0.4.24;


/**
 * @title ERC20
 * @dev ERC20 interface
 */
contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Token is ERC20 {

	uint256  public  totalSupply = 1000000000 * 1 ether;

	mapping  (address => uint256)             public          _balances;
    mapping  (address => mapping (address => uint256)) public  _approvals;


    string   public  name = "Test Token";
    string   public  symbol = "TT";
    uint256  public  decimals = 18;

    address  public  owner ;

    event Mint(uint256 wad);
    event Burn(uint256 wad);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    constructor () public{
        owner = msg.sender;
		_balances[owner] = totalSupply;
	}

	modifier onlyOwner() {
	    require(msg.sender == owner);
	    _;
	}

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public constant returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        require (dst != address(0));
        require (wad > 0);
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = _balances[msg.sender] - wad;
        _balances[dst] = _balances[dst] + wad;
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require (src != address(0));
        require (dst != address(0));
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = _approvals[src][msg.sender] - wad;
        _balances[src] = _balances[src] - wad;
        _balances[dst] = _balances[dst] + wad;
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        require (guy != address(0));
        require (wad > 0);
        _approvals[msg.sender][guy] = wad;
        
        emit Approval(msg.sender, guy, wad);
        
        return true;
    }

    function burn(uint256 wad) public onlyOwner {
        require (wad > 0);
        _balances[msg.sender] = _balances[msg.sender] - wad;
        totalSupply = totalSupply - wad;
        emit Burn(wad);
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}