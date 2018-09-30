pragma solidity 0.4.24;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
// assert(a == b * c + a % b); 
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


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
require(_to != address(0));
require(_value <= balances[msg.sender]);

// SafeMath.sub will throw if there is not enough balance.
balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
require(_to != address(0));
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);

balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
emit Transfer(_from, _to, _value);
return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
return true;
  }

        function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
uint oldValue = allowed[msg.sender][_spender];
if (_subtractedValue > oldValue) {
  allowed[msg.sender][_spender] = 0;
} else {
  allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
}
emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
return true;
  }

    }

contract Ownable {
   address public owner;


   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  function Ownable() public {
owner = msg.sender;
  }

   modifier onlyOwner() {
require(msg.sender == owner);
_;
  }


  function transferOwnership(address newOwner) public onlyOwner {
require(newOwner != address(0));
emit OwnershipTransferred(owner, newOwner);
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
emit Pause();
  }

   function unpause() onlyOwner whenPaused public {
paused = false;
emit Unpause();
  }
 }

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
return super.transfer(_to, _value);
  }

   function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
return super.transferFrom(_from, _to, _value);
   }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
return super.increaseApproval(_spender, _addedValue);
  }

   function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
return super.decreaseApproval(_spender, _subtractedValue);
 }
}

contract Uptrennd is StandardToken, PausableToken {
   string public constant name = &#39;Uptrennd&#39;;                                      // Set the token name for display
   string public constant symbol = &#39;1UP&#39;;                                       // Set the token symbol for display
   uint8 public constant decimals = 18;                                          // Set the number of decimals for display
   uint256 public constant INITIAL_SUPPLY = 10000000000 * 1**uint256(decimals);  // 50 billions 

  function Uptrennd() public{
totalSupply = INITIAL_SUPPLY;                               // Set the total supply
balances[msg.sender] = INITIAL_SUPPLY;                      // Creator address is assigned all
emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

   function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
require(_to != address(0));
return super.transfer(_to, _value);
   }

   function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
require(_to != address(0));
return super.transferFrom(_from, _to, _value);
   }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
return super.approve(_spender, _value);
  }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) public returns (bool)
{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0x0), _value);
    return true;
    }
 }