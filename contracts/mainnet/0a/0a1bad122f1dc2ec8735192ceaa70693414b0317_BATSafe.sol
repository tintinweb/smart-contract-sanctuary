pragma solidity ^0.4.10;

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


/*  ERC 20 token */
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


// requires 5,050,000 BAT deposited here
contract BATSafe {
  mapping (address => uint256) allocations;
  uint256 public unlockDate;
  address public BAT;
  uint256 public constant exponent = 10**18;

  function BATSafe(address _BAT) {
    BAT = _BAT;
    unlockDate = now + 6 * 31 days;
    allocations[0x29940Eec1d3E79e4E20574bB69f4bDF382E60E8A] = 1250000;
    allocations[0x16733a097bC4aE65356083e2919D9aAD32b9106D] = 800000;
    allocations[0xB228d4dEe3fD0667F0161FeF769ad44d8F433Bc9] = 200000;
    allocations[0x245B07814af3d708538D9A1f183450197F0FEBdd] = 200000;
    allocations[0xb29458e5CaaCc3963D286Eb357CEf0734ff22504] = 200000;
    allocations[0x31cC98831574d37966b05f9BE44bc14CA303FcCD] = 200000;
    allocations[0x24f430377A8497cFaD9Ea2839941D6248c3d5275] = 200000;
    allocations[0x7C350e02319eC6703B120160C3B712821A661f62] = 200000;
    allocations[0x0DBaC4B5C00C8aAe3c030878c51524C6ED3d2a51] = 200000;
    allocations[0xdFEb81B6c32c808D53914Ad1A462d6b6439E4230] = 200000;
    allocations[0xE4d59Aa22c99051BC25e51CDC844d851A0C72aAD] = 200000;
    allocations[0x76C12809FA051F5edf2a864de8890C26BFb952c2] = 200000;
    allocations[0xC6204459C59D8e498284337012fc023b7680E7a3] = 200000;
    allocations[0x92b79d1A09Dde9F5b5Ada7aDE3fe8eB1e56a4D79] = 200000;
    allocations[0xEE575340dAbE28f989d9521CEb8ca92c4Cd76047] = 200000;
    allocations[0xb3C7372Bf84D1f13C602b1Fe76A9Ea9B415Be908] = 200000;
    allocations[0x2761B6a570dB5175668Bd622F0248E6c32b158B7] = 200000;
  }

  function unlock() external {
    if(now < unlockDate) throw;
    uint256 entitled = allocations[msg.sender];
    allocations[msg.sender] = 0;
    if(!StandardToken(BAT).transfer(msg.sender, entitled * exponent)) throw;
  }

}