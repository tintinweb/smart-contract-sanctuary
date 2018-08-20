pragma solidity 0.4.24;

contract AbcdEfg {
  mapping (uint256 => bytes) public marks;
  string public constant name = "abcdEfg";
  string public constant symbol = "a2g";
  uint8 public constant decimals = 0;
  string public constant memo = "Fit in the words here!Fit in the words here!Fit in the words here!Fit in the words here!";
  
  mapping (address => uint256) private balances;
  mapping (address => uint256) private marked;
  uint256 private totalSupply_ = 1000;
  uint256 private markId = 0;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  
  constructor() public {
    balances[msg.sender] = totalSupply_;
  } 
  
  function () public {
      mark();
  }

  function mark() internal {
    markId ++;
    marked[msg.sender] ++;
    marks[markId] = abi.encodePacked(msg.sender, msg.data);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value + marked[msg.sender] <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

}