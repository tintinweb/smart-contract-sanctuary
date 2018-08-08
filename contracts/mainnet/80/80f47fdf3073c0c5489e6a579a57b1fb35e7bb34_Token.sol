pragma solidity ^0.4.11;
 
contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
   
   
    function tokenFallback(address _from, uint _value, bytes _data){
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
 
    }
}
 
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
 
    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) throw;
        return x + y;
    }
 
    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) throw;
        return x - y;
    }
 
    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) throw;
        return x * y;
    }
}
 
contract Token is SafeMath{
 
  mapping(address => uint) balances;
 
  string public symbol = "";
  string public name = "";
  uint8 public decimals = 18;
  uint256 public totalSupply = 0;
  address owner = 0;
  bool setupDone = false;
 
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
 
  function Token(address adr) {
        owner = adr;        
    }
   
    function SetupToken(string _tokenName, string _tokenSymbol, uint256 _tokenSupply)
    {
        if (msg.sender == owner && setupDone == false)
        {
            symbol = _tokenSymbol;
            name = _tokenName;
            totalSupply = _tokenSupply * 1000000000000000000;
            balances[owner] = totalSupply;
            setupDone = true;
        }
    }
 
  function name() constant returns (string _name) {
      return name;
  }
 
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
 
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
 
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }
 
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
     
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
 
  function transfer(address _to, uint _value) returns (bool success) {
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}
 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
     
      if (balanceOf(_addr) >=0 )
     
      assembly {
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }
 
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) throw;
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
 
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) throw;
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}
 
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}