pragma solidity ^0.4.24;
contract Token1002Template {
  address public owner;
  string public name;
  string public symbol;
  uint public decimals;
  uint256 public totalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  mapping (address => uint256) public balanceOf;
  
  constructor(uint256 initialSupply, string tokenName, string tokenSymbol, uint decimalUnits) public {
    owner = msg.sender;
    totalSupply = initialSupply;
    balanceOf[msg.sender] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  function transfer(address _to, uint256 _value) public {
    require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }

    function batchTransfer(address[] _to, uint _value) public{
        require(balanceOf[msg.sender] >= _to.length * _value);
        require(_to.length > 0);
        for(uint256 i=0 ; i< _to.length; i++){
           transfer(_to[i], _value);
         }
    }
}