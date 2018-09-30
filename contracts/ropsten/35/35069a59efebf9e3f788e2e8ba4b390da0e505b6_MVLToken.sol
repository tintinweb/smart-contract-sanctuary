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
  address public admin;

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

  modifier onlyOwnerOrAdmin() {
    require(msg.sender != address(0) && (msg.sender == owner || msg.sender == admin));
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    require(newOwner != owner);
    require(newOwner != admin);

    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function setAdmin(address newAdmin) onlyOwner public {
    require(admin != newAdmin);
    require(owner != newAdmin);

    admin = newAdmin;
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0);
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
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
  bool public noTokenLocked = false; // indicates all token is released or not

  struct TokenLockInfo { // token of `amount` cannot be moved before `time`
    uint256 amount; // locked amount
    uint256 time; // unix timestamp
  }

  struct TokenLockState {
    uint256 latestReleaseTime;
    TokenLockInfo[] tokenLocks; // multiple token locks can exist
  }

  mapping(address => TokenLockState) lockingStates;
  event AddTokenLock(address indexed to, uint256 time, uint256 amount);

  function unlockAllTokens() public onlyOwner {
    noTokenLocked = true;
  }

  function enableTransfer(bool _enable) public onlyOwner {
    transferEnabled = _enable;
  }

  // calculate the amount of tokens an address can use
  function getMinLockedAmount(address _addr) view public returns (uint256 locked) {
    uint256 i;
    uint256 a;
    uint256 t;
    uint256 lockSum = 0;

    // if the address has no limitations just return 0
    TokenLockState storage lockState = lockingStates[_addr];
    if (lockState.latestReleaseTime < now) {
      return 0;
    }

    for (i=0; i<lockState.tokenLocks.length; i++) {
      a = lockState.tokenLocks[i].amount;
      t = lockState.tokenLocks[i].time;

      if (t > now) {
        lockSum = lockSum.add(a);
      }
    }

    return lockSum;
  }

  function addTokenLock(address _addr, uint256 _value, uint256 _release_time) onlyOwnerOrAdmin public {
    require(_addr != address(0));
    require(_value > 0);
    require(_release_time > now);

    TokenLockState storage lockState = lockingStates[_addr]; // assigns a pointer. change the member value will update struct itself.
    if (_release_time > lockState.latestReleaseTime) {
      lockState.latestReleaseTime = _release_time;
    }
    lockState.tokenLocks.push(TokenLockInfo(_value, _release_time));

    emit AddTokenLock(_addr, _release_time, _value);
  }
}

contract MVLToken is BurnableToken, DetailedERC20, ERC20Token, TokenLock {
  using SafeMath for uint256;

  // events
  event Approval(address indexed owner, address indexed spender, uint256 value);

  string public constant symbol = "MVL";
  string public constant name = "Mass Vehicle Ledger Token";
  uint8 public constant decimals = 18;
  uint256 public constant TOTAL_SUPPLY = 3*(10**10)*(10**uint256(decimals));

  constructor() DetailedERC20(name, symbol, decimals) public {
    _totalSupply = TOTAL_SUPPLY;

    // initial supply belongs to owner
    balances[owner] = _totalSupply;
    emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  // modifiers
  // checks if the address can transfer tokens
  modifier canTransfer(address _sender, uint256 _value) {
    require(_sender != address(0));
    require(
      (_sender == owner || _sender == admin) || (
        transferEnabled && (
          noTokenLocked ||
          canTransferIfLocked(_sender, _value)
        )
      )
    );

    _;
  }

  function setAdmin(address newAdmin) onlyOwner public {
    address oldAdmin = admin;
    super.setAdmin(newAdmin);
    approve(oldAdmin, 0);
    approve(newAdmin, TOTAL_SUPPLY);
  }

  modifier onlyValidDestination(address to) {
    require(to != address(0x0));
    require(to != address(this));
    require(to != owner);
    _;
  }

  function canTransferIfLocked(address _sender, uint256 _value) public view returns(bool) {
    uint256 after_math = balances[_sender].sub(_value);
    return after_math >= getMinLockedAmount(_sender);
  }

  // override function using canTransfer on the sender address
  function transfer(address _to, uint256 _value) onlyValidDestination(_to) canTransfer(msg.sender, _value) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  // transfer tokens from one address to another
  function transferFrom(address _from, address _to, uint256 _value) onlyValidDestination(_to) canTransfer(_from, _value) public returns (bool success) {
    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // this will throw if we don&#39;t have enough allowance

    // this event comes from BasicToken.sol
    emit Transfer(_from, _to, _value);

    return true;
  }

  function() public payable { // don&#39;t send eth directly to token contract
    revert();
  }
}