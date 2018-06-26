pragma solidity ^0.4.19;

library SafeMath {
    function mul(uint a, uint b) internal pure  returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure  returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Lpktransfer is Ownable {

  using SafeMath for uint;
  mapping(address => uint) balances;
  event Transfer(address indexed from, address indexed to, uint value);
  /* mapping(address => mapping(address => uint)) allowed; */

  function transferFrom(address _from, address _to, uint _tokens) public returns (bool success) {
    require(balances[_from] >= _tokens); // Check if the sender has enough
    balances[_from] = balances[_from].sub(_tokens);
    /* allowed[from][msg.sender] = allowed[from][msg.sender].sub(_tokens); */
    balances[_to] = balances[_to].add(_tokens);
    Transfer(_from, _to, _tokens);
    return true;
  }

  function balanceOf(address _owner) public view returns(uint balance) {
      return balances[_owner];
  }
}