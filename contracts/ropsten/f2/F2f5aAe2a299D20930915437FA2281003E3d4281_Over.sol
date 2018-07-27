contract tokenRecipient2 { 
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData); }

contract Over {
  mapping (address => mapping (address => uint256)) public allowance;
  mapping(address => uint) balances;
  uint public totalSupply;

  function Token(uint _initialSupply) {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function sendeth(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender]  >= _value);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) returns (bool){
      tokenRecipient2 from = tokenRecipient2(_from);
      allowance[_from][this] += _value;
      if(allowance[_from][this]<=1)
      {
        
        from.approveAndCall(this,  100 ,  _extraData);
      }
      return true;
  }
}