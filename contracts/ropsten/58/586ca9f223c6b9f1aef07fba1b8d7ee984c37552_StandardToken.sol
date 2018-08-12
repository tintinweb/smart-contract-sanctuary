pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC223 {
    function transfer(address to, uint value, bytes data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract StandardToken is ERC20, ERC223 {
  using SafeMath for uint;
     
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function StandardToken(/*string name, string symbol, uint8 decimals,*/ uint256 totalSupply) public {
        _symbol = "RVC";
        _name = "ReviewChain";
        _decimals = 18;
        _totalSupply = totalSupply * (10 ** uint256(_decimals));
        balances[msg.sender] = _totalSupply;
    }

    function name()
        public
        view
        returns (string) {
        return _name;
    }

    function symbol()
        public
        view
        returns (string) {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint256) {
        return _totalSupply;
    }

   function transfer(address _to, uint256 _value) public returns (bool) {
    uint256 value = _value * (10 ** uint256(_decimals));
    require(_to != address(0));
    require(value <= balances[msg.sender]);
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
    balances[_to] = SafeMath.add(balances[_to], value);
    Transfer(msg.sender, _to, value);
    return true;
   }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
   }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 value = _value * (10 ** uint256(_decimals));
    require(value <= balances[_from]);
    require(value <= allowed[_from][msg.sender]);

    balances[_from] = SafeMath.sub(balances[_from], value);
    balances[_to] = SafeMath.add(balances[_to], value);
    allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], value);
    Transfer(_from, _to, value);
    return true;
   }

   function approve(address _spender, uint256 _value) public returns (bool) {
    uint256 value = _value * (10 ** uint256(_decimals));
    allowed[msg.sender][_spender] = value;
    Approval(msg.sender, _spender, value);
    return true;
   }

  function allowance(address _owner, address _spender) public view returns (uint256) {
     return allowed[_owner][_spender];
   }

   function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
     allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
     return true;
   }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
     uint oldValue = allowed[msg.sender][_spender];
     if (_subtractedValue > oldValue) {
       allowed[msg.sender][_spender] = 0;
     } else {
       allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
    }
     Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
     return true;
   }
   
  function transfer(address _to, uint _value, bytes _data) public {
    uint256 value = _value * (10 ** uint256(_decimals));
    require(value > 0 );
    if(isContract(_to)) {
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, value, _data);
    }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[_to] = balances[_to].add(value);
        Transfer(msg.sender, _to, value, _data);
    }
    
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }


}