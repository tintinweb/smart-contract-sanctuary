pragma solidity ^0.4.25;



library SafeMath {
 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
   
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ALLChainToken {
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;
    using SafeMath for uint256;
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 private constant MAX_UINT256 = 2**256 -1 ;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    bool lock = false;

    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        owner = msg.sender;
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        
    }
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier isLock {
        require(!lock);
        _;
    }
    
    function setLock(bool _lock) onlyOwner public{
        lock = _lock;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(balances[msg.sender] >= _value);
        require(msg.sender == _to || balances[_to] <= MAX_UINT256 - _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value);
        require(_from == _to || balances[_to] <= MAX_UINT256 -_value);
        require(allowance >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(
        address _owner
    ) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}