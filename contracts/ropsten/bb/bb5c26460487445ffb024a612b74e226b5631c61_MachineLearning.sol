pragma solidity ^0.4.24;

    contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }

contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
   
    uint256 public totalSupply;
    function balanceOf(address _owner) constant  public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
       
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
       
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MachineLearning is owned, SafeMath, StandardToken {
    string public name = "MACHINE LEARNING5";                               
    string public symbol = "MACHINE LEARNING5";                                      
    address public MachineLearningAddress = this;                            
    uint8 public decimals = 0;                                            
    uint256 public totalSupply = 100000;   
    mapping (address => bool) public Professore;
    event Prof(address target, bool negozio);
   
    constructor() public {
        balances[msg.sender] = totalSupply; 
    }
    function AggiungiProfessore (address target) onlyOwner public {
        Professore[target] = true;
        emit Prof(target, true);
    }
    function RimuoviProfessore (address target) onlyOwner public {
        Professore[target] = false;
        emit Prof(target, false);
    }
    function AumentaQuantitaVoti(uint value, address to) onlyOwner public returns (bool) {
    totalSupply = safeAdd(totalSupply, value);
    balances[to] = safeAdd(balances[to], value);
    emit Transfer(0, to, value);
    return true;
    }   

    function transfer(address _to, uint256 _value) public returns (bool success) {
if (Professore[_to] || Professore[msg.sender]) {   
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {              
            balances[msg.sender] = safeSub(balances[msg.sender], _value);  
            balances[_to] = safeAdd(balances[_to], _value);           
            emit Transfer(msg.sender, _to, _value);                         
            return true;
            }
        } else { revert(); }
    }
}