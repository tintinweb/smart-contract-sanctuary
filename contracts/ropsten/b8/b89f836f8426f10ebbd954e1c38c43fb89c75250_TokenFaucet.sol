pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    using SafeMath for uint256;
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender,  uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract TestToken is StandardToken {
    event Mint(address indexed to, uint256 amount);

    uint256 public constant PRICE = 4000;

    // metadata
    string public constant name = "Infinite Test Token";
    string public constant symbol = "TEST";
    uint8 public constant decimals = 18;
    string public version = "1.1";

    event CreatedToken();

    function TestToken() {
        CreatedToken();
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable {
        uint256 tokens = msg.value * PRICE;
        balances[beneficiary] += tokens;
        Transfer(0x0, beneficiary, tokens);
        Mint(beneficiary, tokens);
        totalSupply += tokens;
        msg.sender.transfer(msg.value);
    }
}

contract TokenFaucet {
    TestToken public token;
    address public owner;
    
    constructor(TestToken _token) public {
        token = _token;
        owner = msg.sender;
    }
    
    function setOwner(address _owner) external {
        require(msg.sender == owner);
        require(_owner != address(0));
        owner = _owner;
    }
    
    function withdrawEth(address _to, uint256 _amount) external {
        require(msg.sender == owner);
        _to.transfer(_amount);
    }

    function request(uint256 _tokens) external {
        _mint();
        require(token.transfer(msg.sender, _tokens));
    }
    
    function _mint() internal {
        token.call.value(address(this).balance)();
        token.call.value(address(this).balance)();
        token.call.value(address(this).balance)();
    }
    
    function() external {
        _mint();
        require(token.transfer(msg.sender, 4000 * 10 ** 18));
    }
}