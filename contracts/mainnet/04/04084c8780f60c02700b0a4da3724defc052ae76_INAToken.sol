/* 
@INATOKEN DEVELOPMENT TEAM
@COPYRIGHT 2018
 */
 
 pragma solidity ^0.4.4;

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


contract ERC20Token is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


contract INAToken is ERC20Token {
    uint price = 0.0000000000000005 ether;
    address owner = msg.sender;
    string public name;                   
    uint8 public decimals;                
    string public symbol;                
    string public version = &#39;H0.1&#39;;       
    

  function() public payable {
    require( msg.value > 0 );
    uint toMint = msg.value/price;
    balances[msg.sender] += toMint;
    balances[owner] -= toMint;
    emit Transfer(0, msg.sender, toMint);
    withdraw();
   }
   
   function withdraw() public {
    address myAddress = this;
    uint256 etherBalance = myAddress.balance;
    owner.transfer(etherBalance);
}

    function INAToken(
         ) {
        balances[msg.sender] = 50000000000e8;               
        totalSupply = 50000000000e8;                      
        name = "INATOKEN";                                   
        decimals = 8;                            
        symbol = "INA";                               
    }

   
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}