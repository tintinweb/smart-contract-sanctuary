// GYM Ledger Token Contract - Project website: www.gymledger.com

// Token distribution:

//    Private Investors = 10%
//    GYM Ledger Token Sale = 20%
//    Ecosystem Development = 30%
//    Long Term Fund (Future Growth, Partnerships, EtC) = 25%
//    Advisors and Development = 15%

// GYM Reward, LLC

pragma solidity ^0.4.25;

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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Valid address is required");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "Valid address is required");
    require(_value <= balances[msg.sender], "Not enougth balance");

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
    require(_to != address(0), "Valid address is required");
    require(_value <= balances[_from], "Not enough balance");
    require(_value <= allowed[_from][msg.sender], "Amount exeeds allowance");

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

contract LGRToken is Ownable, StandardToken {
  string public constant name = "GYM Ledger Token";
  string public constant symbol = "LGR";
  uint8 public constant decimals = 18;
  uint256 public constant MAX_SUPPLY = 100000000 * (10 ** uint256(decimals));
  bool public paused;
  address public minter;

  event Minted(address indexed to, uint256 amount);
  event Paused(bool paused);

  modifier notPaused() {
    require(paused == false, "Token is paused");
    _;
  }

  modifier canMint() {
    require((msg.sender == owner || msg.sender == minter), "You are not authorized");
    _;
  }

  constructor() public {        
    paused = false;              
  }

  function pause(bool _paused) public onlyOwner {
    paused = _paused;
    emit Paused(paused);
  }

  function setMinter(address _minter) public onlyOwner {
    minter = _minter;
  }

  function mintTo(address _to, uint256 _amount) public canMint {
    require((totalSupply + _amount) <= MAX_SUPPLY, "Invalid amount");
    balances[_to] = balances[_to].add(_amount);
    totalSupply = totalSupply.add(_amount);
    emit Minted(_to, _amount);
  }

  function transfer(address _to, uint256 _value) public notPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public notPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}