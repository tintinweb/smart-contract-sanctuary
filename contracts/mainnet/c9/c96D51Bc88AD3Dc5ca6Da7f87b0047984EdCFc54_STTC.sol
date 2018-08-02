pragma solidity ^0.4.16;
contract owned{
    address public owner;
    
    constructor()public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require (msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner)onlyOwner public{
        if(newOwner != address(0)){
            owner = newOwner;
        }
    }
}

contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract TokenDemo is Token,owned {
    
    string public name;                  
    uint8 public decimals;              
    string public symbol;            
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    constructor(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
    totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);        
    balances[owner] = totalSupply; 
        
        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        uint previousBalances = balances[msg.sender] + balances[_to];
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value; 
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract STTC is TokenDemo{
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);
    
    constructor(
      uint256 initialSupply,
      string tokenName,
      uint8 decimalUnits,
      string tokenSymbol,
      address centralMinter
    ) TokenDemo (initialSupply, tokenName, decimalUnits,tokenSymbol) public {
         if(centralMinter != 0 ){
             owner = centralMinter;
         } 
         balances[owner] = totalSupply;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);
        uint previousBalances = balances[msg.sender] + balances[_to];
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        return true;
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {

        balances[target] += mintedAmount;
        totalSupply += mintedAmount;

        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

}