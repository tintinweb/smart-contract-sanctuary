pragma solidity ^0.4.20;

contract Token {
    function totalSupply() constant returns (uint256 supply) {}

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is Token {

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value > 0 && _balances[msg.sender] >= _value) {
            _balances[msg.sender] -= _value;
            _balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } 
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_value > 0 && _balances[_from] >= _value && _allowed[_from][msg.sender] >= _value ) {
            _balances[_to] += _value;
            _balances[_from] -= _value;
            _allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return _allowed[_owner][_spender];
    }
}

contract CorvinusCoin is BasicToken { 

    string public _fullName;                   
    uint8 public _decimals;                
    string public _ticker;                 
    string public _version; 
    uint256 public _tokenPerEther;     
    uint256 public _totalEtherInWei;         
    address public _funds;           

    function CorvinusCoin() {
        _balances[msg.sender] = 1000000000000000000000;               
        totalSupply = 1000000000000000000000;                       
        _fullName = "CorvinusCoin";                                  
        _decimals = 20;                                             
        _ticker = "BCE";                                           
        _tokenPerEther = 10;                                    
        _funds = msg.sender;                                
    }

    function() payable {
        _totalEtherInWei = _totalEtherInWei + msg.value;
        uint256 amount = msg.value * _tokenPerEther;

        if (_balances[_funds] < amount) {
            return;
        }

        _balances[_funds] = _balances[_funds] - amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        Transfer(_funds, msg.sender, amount);
        _funds.transfer(msg.value);                               
    }
}