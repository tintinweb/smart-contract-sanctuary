pragma solidity ^0.4.24;
contract ObsToken {
  mapping(address => uint256) balances;
  string public constant NAME = &quot;ObsToken&quot;;
  string public constant SYMBOL = &quot;OBT&quot;;
  uint256 totalSupply_;
  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor(uint256 INITIAL_SUPPLY, address _owner) public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[_owner] = INITIAL_SUPPLY;
    emit Transfer(0x0, _owner, INITIAL_SUPPLY);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}