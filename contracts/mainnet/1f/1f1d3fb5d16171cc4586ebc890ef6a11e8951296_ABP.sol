/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity 0.4.23;

// File: contracts/token/ERC20Basic.sol

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20.sol

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/DetailedERC20.sol

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: contracts/token/Ownable.sol

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    require(newOwner != owner);

    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/token/SafeMath.sol

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); // overflow check
    return c;
  }
}

// File: contracts/token/MVLToken.sol

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 _totalSupply;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0);
    require(_value <= balances[msg.sender]);


    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20Token is BasicToken, ERC20 {
  using SafeMath for uint256;
  mapping (address => mapping (address => uint256)) allowed;

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value == 0 || allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is BasicToken, Ownable {
  // events
  event Burn(address indexed burner, uint256 amount);

  // reduce sender balance and Token total supply
  function burn(uint256 _value) onlyOwner public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }
}

contract TokenLock is Ownable {
  using SafeMath for uint256;

  bool public transferEnabled = false; // indicates that token is transferable or not

//   bool public noTokenLocked = false; // indicates all token is released or not

 
  mapping (address => bool) public lockAddresses;

   modifier canTransfer(address _sender) {
    require((_sender == owner) || (transferEnabled));
    if(lockAddresses[_sender]) {
      revert();
    }
    _;
  }

  function setLockAddress(address addr, bool state) onlyOwner /*inReleaseState(false)*/ public {
    lockAddresses[addr] = state;
  }

  function enableTransfer(bool _enable) public onlyOwner {
    transferEnabled = _enable;
  }

  // calculate the amount of tokens an address can use

}

contract ABP is BurnableToken, DetailedERC20, ERC20Token, TokenLock {
  using SafeMath for uint256;

  // events
  event Approval(address indexed owner, address indexed spender, uint256 value);

  string public constant symbol = "ABP";
  string public constant name = "Ai Bitcoin Pick";
  uint8 public constant decimals = 18;
  uint256 public constant TOTAL_SUPPLY = 20*(10**8)*(10**uint256(decimals));

  constructor() DetailedERC20(name, symbol, decimals) public {
    _totalSupply = TOTAL_SUPPLY;

    // initial supply belongs to owner
    balances[owner] = _totalSupply;
    emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  // override function using canTransfer on the sender address
//   function transfer(address _to, uint256 _value) onlyValidDestination(_to) canTransfer(msg.sender, _value) public returns (bool success) {
  function transfer(address _to, uint256 _value) canTransfer(msg.sender) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  // transfer tokens from one address to another
//   function transferFrom(address _from, address _to, uint256 _value) onlyValidDestination(_to) canTransfer(_from, _value) public returns (bool success) {
  function transferFrom(address _from, address _to, uint256 _value)  canTransfer(_from) public returns (bool success) {
    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // this will throw if we don't have enough allowance

    // this event comes from BasicToken.sol
    emit Transfer(_from, _to, _value);

    return true;
  }

  function() public payable { // don't send eth directly to token contract
    revert();
  }
}