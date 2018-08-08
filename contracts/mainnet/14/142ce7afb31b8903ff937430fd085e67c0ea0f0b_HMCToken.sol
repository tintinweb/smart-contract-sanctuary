pragma solidity ^0.4.20;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Frozen is Pausable {
    event FrozenFunds(address target, bool frozen);
    
    mapping (address => bool) public frozenAccount;
    function freezeAccount(address target, bool freeze) onlyOwner whenNotPaused public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    modifier whenNotFrozen() {
        require(!frozenAccount[msg.sender]);
        _;
    }
}

contract PausableFrozenToken is StandardToken, Frozen {

  function transfer(address _to, uint256 _value) public whenNotPaused whenNotFrozen returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused whenNotFrozen returns (bool) {
    require(!frozenAccount[_from]);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused whenNotFrozen returns (bool) {
    return super.approve(_spender, _value);
  }
}

contract HMCToken is PausableFrozenToken {
    string public name = "HMC";
    string public symbol = "HMC";
    uint8 public decimals = 18;

    function HMCToken() {
      totalSupply = 1000000000 * (10**(uint256(decimals)));
      balances[msg.sender] = totalSupply;    
    }

    function () {
        revert();
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}