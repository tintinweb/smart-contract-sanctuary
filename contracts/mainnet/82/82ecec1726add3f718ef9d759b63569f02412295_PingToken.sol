pragma solidity ^0.4.18;
contract PingToken {
  
  event Pong(uint256 pong);
  event Transfer(address indexed from, address indexed to, uint256 value);
uint256 public pings;
  uint256 public totalSupply;
  
  string public constant name = "PingToken";
  string public constant symbol = "PING";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals)); // 100M
  
  mapping(address => uint256) balances;
function PingToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
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
function ping() external returns (uint256) {
    // 1 token to use ping function
    uint256 cost = 1 * (10 ** uint256(decimals));
    require(cost <= balances[msg.sender]);
    totalSupply -= cost;
    balances[msg.sender] -= cost;
    pings++;
    emit Pong(pings);
    return pings;
  }
}