pragma solidity ^0.4.13;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract TokenSafe {
  mapping (uint256 => uint256) allocations;
  mapping (address => bool) isAddressInclude;
  uint256 public unlockTimeLine;
  uint256 public constant firstTimeLine = 1514044800;
  uint256 public constant secondTimeLine = 1521820800;
  uint256 public constant thirdTimeLine = 1529769600;
  address public originalContract;
  uint256 public constant exponent = 10**8;
  uint256 public constant limitAmount = 1500000000*exponent;
  uint256 public balance = 1500000000*exponent;


  function TokenSafe(address _originalContract) {
    originalContract = _originalContract;
    //init amount available for 1,3,6th month
    //33.3%
    allocations[1] = 333;
    //66.6%
    allocations[2] = 666;
    //100%
    allocations[3] = 1000;

    isAddressInclude[0x5527CCB20a12546A3f03517076339060B997B468] = true;
    isAddressInclude[0xb94a75e6fd07bfba543930a500e1648c2e8c9622] = true;
    isAddressInclude[0x59c582aefb682e0f32c9274a6cd1c2aa45353a1f] = true;
  }

  function unlock() external{
    require(now > firstTimeLine); //prevent untimely call
    require(isAddressInclude[msg.sender] == true); //prevent address unauthorized

    if(now >= firstTimeLine){
        unlockTimeLine = 1;
    }
    if(now >= secondTimeLine){
        unlockTimeLine = 2;
    }
    if (now >= thirdTimeLine){
        unlockTimeLine = 3;
    }

    uint256 balanceShouldRest = limitAmount - limitAmount * allocations[unlockTimeLine] / 1000;
    uint256 canWithdrawAmount = balance - balanceShouldRest;

    require(canWithdrawAmount > 0);

    if (!StandardToken(originalContract).transfer(msg.sender, canWithdrawAmount )){
        //failed
        revert();
    }

    //success
    balance = balance - canWithdrawAmount;

  }

}