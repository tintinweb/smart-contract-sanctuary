pragma solidity ^0.4.11;
 
 
contract ERC223Token { 
         using SafeMath for uint;
         
    mapping(address => uint) balances; // List of user balances.
    
    address  public owner;
    uint public constant totalSupply = 100000000;
    uint public constant decimals = 18;
    string public constant name = " LIRAX";
    string public constant symbol = "LRX";


    
    function transfer(address _to, uint _value, bytes _data) {
        
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        // Transfer(msg.sender, _to, _value, _data);
    }
    
    
    
    
   
    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {

            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        //Transfer(msg.sender, _to, _value, empty);
    }

 
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
        //  function balanceOf(address tokenOwner) public constant returns (uint balance) {
        // return balances[tokenOwner];
    

    } 
}








contract  LIRAX  {
  string public name;
  string public symbol;
  uint256 public decimals;
  string public  totalSupply;
  // uint public constant _totalSupply = 500000000;
//   uint256 public constant initialSupply = 500 * (6 ** uint256(decimals));
//   address public icoContract;

  function Lirux(
    string _name,
    string _symbol,
    uint256 _decimals,
    string  _totalSupply 
  )
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;  
  }

}


contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}




contract ERC223ReceivingContract { 

    function tokenFallback(address _from, uint _value, bytes _data);
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