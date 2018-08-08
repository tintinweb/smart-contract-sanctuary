pragma solidity ^0.4.16;

contract ERC20 {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns(uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

library SafeMath {

  function safemul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safediv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function safesub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeadd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply = 1000;
    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping(address => uint)) internal _allowances;
    
    constructor(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }
    
    function name() public constant returns (string) {
        return _name;
    }
    
    function symbol() public constant returns (string) {
        return _symbol;
    }
    
    function decimals() public constant returns (uint8){
        return _decimals;
    }
    
    function totalSupply() public constant returns (uint){
        return _totalSupply;
    }
    
    function balanceOf(address _addr) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract PapaBoxToken is Token("PaPB", "Papa Box Beta", 6, 10 ** 15 ), ERC20 {
    using SafeMath for uint256;
    
    constructor() public {
        _balanceOf[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address addr) public constant returns(uint) {
        return _balanceOf[addr];
    }
    
    function transfer(address _to, uint _value) public returns (bool){
        if(_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            !isContract(_to)) {
                
            _balanceOf[msg.sender] = _balanceOf[msg.sender].safesub(_value);
            _balanceOf[_to] = _balanceOf[_to].safeadd(_value);
            
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    
    function isContract(address _addr) private constant returns(bool) {
        uint codeSize;
        _addr = _addr;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool)  {
        if(_allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            _allowances[_from][msg.sender] >= _value) {
                
                _balanceOf[_from] = _balanceOf[_from].safesub(_value);
                _balanceOf[_to] = _balanceOf[_to].safeadd(_value);
                return true;
            }
            return false;
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value; 
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return _allowances[_owner][_spender];
    }
    
}