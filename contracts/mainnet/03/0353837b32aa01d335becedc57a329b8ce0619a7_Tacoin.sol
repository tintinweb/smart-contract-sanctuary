pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);

  function name() public constant returns (string _name);
  function symbol() public constant returns (string _symbol);
  function decimals() public constant returns (uint8 _decimals);
  function totalSupply() public constant returns (uint256 _supply);

  function approve(address _spender, uint _value) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint); 
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) external returns (bool);
  
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract Tacoin is ERC223 {
  using SafeMath for uint;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) internal _allowances;

  string public name = "Tacoin";
  string public symbol = "TACO";
  uint8 public decimals = 18;
  uint256 public totalSupply = 10000000000000000000000000;

function Tacoin (
        uint256 initialSupply, 
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10000000000000000000000000  ** uint256(18);  
        balances[msg.sender] = totalSupply = 10000000000000000000000000;                
        name = tokenName = "Tacoin";                                   
        symbol = tokenSymbol = "TACO";                               
    }

  // Function to access name of token .
  function name() public constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() public constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() public constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public constant returns (uint256 _totalSupply) {
      return totalSupply;
  }
  
  function approve(address _spender, uint _value) external returns (bool) {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].add(_value);
        Approval(msg.sender, _spender, _value);
        return true;
  
  }
  function allowance(address _owner, address _spender) external constant returns (uint) {
        return _allowances[_owner][_spender];
    }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private constant returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
  function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        if (_allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            _allowances[_from][msg.sender] >= _value &&
            balances[_from] >= _value) {
            balances[_from] = balances[_from].sub(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }
  
}