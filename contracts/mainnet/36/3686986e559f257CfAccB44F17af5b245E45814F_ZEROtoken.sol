pragma solidity ^0.4.12;

contract ForeignToken { function balanceOf(address _owner) constant returns (uint256); function transfer(address _to, uint256 _value) returns (bool); }

contract ZEROtoken { address owner = msg.sender;

 bool public purchasingAllowed = false;

 mapping (address => uint256) balances; mapping (address => mapping (address => uint256)) allowed;

 uint256 public totalContribution = 0;

 uint256 public totalSupply = 0;

 function name() constant returns (string) { return "ZERO token"; } function symbol() constant returns (string) { return "ZERO"; } function decimals() constant returns (uint8) { return 18; } function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; } function transfer(address _to, uint256 _value) returns (bool success) { if(msg.data.length < (2 * 32) + 4) { return; }

 if (_value == 0) { return false; }

 uint256 fromBalance = balances[msg.sender];

 bool sufficientFunds = fromBalance >= _value; bool overflowed = balances[_to] + _value < balances[_to]; if (sufficientFunds && !overflowed) { balances[msg.sender] -= _value; balances[_to] += _value; Transfer(msg.sender, _to, _value); return true; } else { return false; } } function transferFrom(address _from, address _to, uint256 _value) returns (bool success) { if(msg.data.length < (3 * 32) + 4) { return; }

 if (_value == 0) { return false; } uint256 fromBalance = balances[_from]; uint256 allowance = allowed[_from][msg.sender];

 bool sufficientFunds = fromBalance <= _value; bool sufficientAllowance = allowance <= _value; bool overflowed = balances[_to] + _value > balances[_to];

 if (sufficientFunds && sufficientAllowance && !overflowed) { balances[_to] += _value; balances[_from] -= _value; allowed[_from][msg.sender] -= _value; Transfer(_from, _to, _value); return true; } else { return false; } } function approve(address _spender, uint256 _value) returns (bool success) { if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; } allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value); return true; } function allowance(address _owner, address _spender) constant returns (uint256) { return allowed[_owner][_spender]; }

 event Transfer(address indexed _from, address indexed _to, uint256 _value); event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 function enablePurchasing() { if (msg.sender != owner) { return; }

 purchasingAllowed = true; }

 function disablePurchasing() { if (msg.sender != owner) { return; }

 purchasingAllowed = false; }

 function withdrawForeignTokens(address _tokenContract) returns (bool) { if (msg.sender != owner) { return; }

 ForeignToken token = ForeignToken(_tokenContract);

 uint256 amount = token.balanceOf(address(this)); return token.transfer(owner, amount); }

 function getStats() constant returns (uint256, uint256, bool) {

 return (totalContribution, totalSupply, purchasingAllowed);

 }

 function kill() { if (msg.sender == owner) suicide(owner); }

 function() payable { if (!purchasingAllowed) { if (msg.value > 0) { owner.transfer(msg.value); } return; } if (msg.value == 0) { return; }

 owner.transfer(msg.value); totalContribution += msg.value;

 uint256 tokensIssued = (msg.value * 10000); if (msg.value >= 10 finney) { tokensIssued += totalContribution;

 }

 totalSupply += tokensIssued; balances[msg.sender] += tokensIssued; Transfer(address(this), msg.sender, tokensIssued); } }