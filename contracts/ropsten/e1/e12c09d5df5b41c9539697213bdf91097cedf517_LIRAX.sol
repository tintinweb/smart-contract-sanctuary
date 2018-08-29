pragma solidity ^0.4.18;

//https://github.com/ethereum/EIPs/issues/223 - ok
contract LIRAX {
    string public name = "LIRAX";
    uint8 public decimals = 18;
    string public symbol = "LRX";
    //string public version = "GBC 1.0";
    uint256 public totalSupply;
    mapping(address => uint) balancesOf;
    event LogAddTokenEvent(address indexed to, uint value);
    event LogDestroyEvent(address indexed from, uint value);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

    function LIRAX(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        balancesOf[msg.sender] = _totalSupply;
    }

    // Get the total token supply
    function totalSupply() public constant returns (uint256 _supply){
        return totalSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool ok){
        require(balancesOf[msg.sender] >= _value);
        balancesOf[msg.sender] -= _value;
        balancesOf[_to] += _value;
        return true;
    }

    function balanceOf(address who) public view returns (uint balance) {
        return balancesOf[who];
    }

    function add(address _to, uint256 _value) public {
        totalSupply += _value;
        balancesOf[_to] += _value;

        LogAddTokenEvent(_to, _value);
    }

    function destroy(address _from, uint256 _value) public {
        totalSupply -= _value;
        balancesOf[_from] -= _value;
        LogDestroyEvent(_from, _value);
    }
}


library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}