pragma solidity ^0.4.2;

contract Evocoin{

  string public constant name = "Evocoin transit";
  string public constant symbol = "EVCTS";
  uint8 public constant decimals = 5;
  uint public constant totalSupply = 7500000000*10**5;
  uint userIndex = 0;
  address public constant owner = 0x34A4933de38bF3830C7848aBb182d553F5a5D523;
  
  struct user{
    address _adress;
    uint _value;
  }

  mapping (address => mapping (address => uint)) allowed;
  mapping (address => uint) balances;
  mapping (uint => user) users;
    
  function Evocoin() public {
    balances[owner] = totalSupply;
    Transfer(address(this), owner, totalSupply);
  }

  function transferFrom(address _from, address _to, uint _value) public {
    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
    require(_to != address(0x0));
    
    balances[_to] +=_value;
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint _value) public {
    require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
    require(_to != address(0x0));
    
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
  function buyout() public { 
    require(msg.sender!=owner);
    require(balances[msg.sender] > 0);
    
    uint _value = balances[msg.sender];
    balances[msg.sender] = 0;
    balances[owner] += _value;
    
    users[userIndex]._adress = msg.sender;
    users[userIndex]._value = _value;
    ++userIndex;
    
    Transfer(msg.sender, owner, _value);
  }
  
  function getTransferedUser(uint _id) public view returns(address, uint){
    return (users[_id]._adress, users[_id]._value);
  }
  
  function isTransferedUser(address _adress) public view returns(bool){
    uint i;
    for(i=0; i<userIndex; i++){
        if (users[i]._adress == _adress)
            return true;
    }
    return false;
  }
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}