/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.5.0;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
  uint c = a * b;
  _assert(a == 0 || c / a == b);
  return c;
}

function div(uint a, uint b) internal pure returns (uint) {
  // _assert(b > 0); // Solidity automatically throws when dividing by 0
  uint c = a / b;
  // _assert(a == b * c + a % b); // There is no case in which this doesn't hold
  return c;
}

function sub(uint a, uint b) internal pure returns (uint) {
  _assert(b <= a);
  return a - b;
}

function add(uint a, uint b) internal pure returns (uint) {
  uint c = a + b;
  _assert(c >= a);
  return c;
}

function max64(uint64 a, uint64 b) internal pure returns (uint64) {
  return a >= b ? a : b;
}

function min64(uint64 a, uint64 b) internal pure returns (uint64) {
  return a < b ? a : b;
}

function max256(uint256 a, uint256 b) internal pure returns (uint256) {
  return a >= b ? a : b;
}

function min256(uint256 a, uint256 b) internal pure returns (uint256) {
  return a < b ? a : b;
}

function _assert(bool assertion) internal pure {
  if (!assertion) {
    revert();
  }
}
}

contract ERC223Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transfer(address to, uint tokens, bytes memory data) public returns (bool success);
  function transfer(address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens, bytes data);
}

contract ERC223ReceivingContract {
  function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract DOROCOIN is ERC223Interface {
  using SafeMath for uint;
string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;
    
  mapping(address => uint) balances; // List of user balances.
  
  /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "DORO";
        symbol = "MLD";
        decimals = 18;
        _totalSupply = 200000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
    }

  function totalSupply() public view returns (uint) {
    return 2**18;
  }

  function transfer(address _to, uint _value, bytes memory _data) public returns (bool) {
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    uint codeLength;

    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(_to)
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if(codeLength>0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, _data);
      return true;
    }
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    uint codeLength;
    bytes memory empty;

    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(_to)
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if(codeLength>0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, empty);
      return true;
    }
    emit Transfer(msg.sender, _to, _value, empty);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}