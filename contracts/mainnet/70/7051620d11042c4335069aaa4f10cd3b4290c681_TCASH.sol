pragma solidity ^0.4.16;

  contract ERC20 {
     function totalSupply() constant returns (uint256 totalsupply);
     function balanceOf(address _owner) constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
     function approve(address _spender, uint256 _value) returns (bool success);
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }
  
  contract TCASH is ERC20 {
     string public constant symbol = "TCASH";
     string public constant name = "Tcash";
     uint8 public constant decimals = 8;
     uint256 _totalSupply = 88000000 * 10**8;
     

     address public owner;
  
     mapping(address => uint256) balances;
  
     mapping(address => mapping (address => uint256)) allowed;
     
  
     function TCASH() {
         owner = msg.sender;
         balances[owner] = 88000000 * 10**8;
     }
     
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
     
    function distributeTCASH(address[] addresses) onlyOwner {
         for (uint i = 0; i < addresses.length; i++) {
           if (balances[owner] >= 100000000
             && balances[addresses[i]] + 100000000 > balances[addresses[i]]) {
             balances[owner] -= 100000000;
             balances[addresses[i]] += 100000000;
             Transfer(owner, addresses[i], 100000000);
           }
         }
     }
     
  
     function totalSupply() constant returns (uint256 totalsupply) {
         totalsupply = _totalSupply;
     }
  

     function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
     }
 
     function transfer(address _to, uint256 _amount) returns (bool success) {
         require(balances[msg.sender] >= _amount);
         require(_amount > 0);
         require(balances[_to] + _amount > balances[_to]);
         balances[msg.sender] -= _amount;
         balances[_to] += _amount;
         Transfer(msg.sender, _to, _amount);
         return true;
     }
     
     
     function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) returns (bool success) {
         require(balances[_from] >= _amount);
         require(allowed[_from][msg.sender] >= _amount);
         require(_amount > 0);
         require(balances[_to] + _amount > balances[_to]);
         balances[_from] -= _amount;
         allowed[_from][msg.sender] -= _amount;
         balances[_to] += _amount;
         Transfer(_from, _to, _amount);
         return true;
     }
 
     function approve(address _spender, uint256 _amount) returns (bool success) {
         require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
    }
}