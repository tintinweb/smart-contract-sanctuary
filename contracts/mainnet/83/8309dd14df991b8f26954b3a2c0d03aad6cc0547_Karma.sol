pragma solidity ^0.4.18;

/** SafeMath libs are inspired by:
  *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  * There is debate as to whether this lib should use assert or require:
  *  https://github.com/OpenZeppelin/zeppelin-solidity/issues/565

  * `require` is used in these libraries for the following reasons:
  *   - overflows should not be checked in contract function bodies; DRY
  *   - "valid" user input can cause overflows, which should not assert()
  */
library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

library SafeMath64 {
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a);
    return a - b;
  }

  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a);
    return c;
  }
}


// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


// https://github.com/ethereum/EIPs/issues/179
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// https://github.com/ethereum/EIPs/issues/20
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/DetailedERC20.sol
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


/** KarmaToken has the following properties:
  *
  * User Creation:
  * - Self-registration
  *   - Owner signs hash(address, username, endowment), and sends to user
  *   - User registers with username, endowment, and signature to create new account.
  * - Mod creates new user.
  * - Users are first eligible to withdraw dividends for the period after account creation.
  *
  * Karma/Token Rules:
  * - Karma is created by initial user creation endowment.
  * - Karma can also be minted by mod into an existing account.
  * - Karma can only be transferred to existing account holder.
  * - Karma implements the ERC20 token interface.
  *
  * Dividends:
  * - each user can withdraw a dividend once per month.
  * - dividend is total contract value minus owner cut at end of the month, divided by total number of users at end of month.
  * - owner cut is determined at beginning of new period.
  * - user has 1 month to withdraw their dividend from the previous month.
  * - if user does not withdraw their dividend, their share will be given to owner.
  * - mod can place a user on a 1 month "timeout", whereby they won&#39;t be eligible for a dividend.

  * Eg: 10 eth is sent to the contract in January, owner cut is 30%. 
  * There are 70 token holders on Jan 31. At any time in February, each token holder can withdraw .1 eth for their January 
  * dividend (unless they were given a "timeout" in January).
  */
contract Karma is Ownable, DetailedERC20("KarmaToken", "KARMA", 0) {
  // SafeMath libs are responsible for checking overflow.
  using SafeMath for uint256;
  using SafeMath64 for uint64;

  struct User {
    bytes20 username;
    uint64 karma; 
    uint16 canWithdrawPeriod;
    uint16 birthPeriod;
  }

  // Manage users.
  mapping(address => User) public users;
  mapping(bytes20 => address) public usernames;

  // Manage dividend payments.
  uint256 public epoch; // Timestamp at start of new period.
  uint256 dividendPool; // Total amount of dividends to pay out for last period.
  uint256 public dividend; // Per-user share of last period&#39;s dividend.
  uint256 public ownerCut; // Percentage, in basis points, of owner cut of this period&#39;s payments.
  uint64 public numUsers; // Number of users created before this period.
  uint64 public newUsers; // Number of users created during this period.
  uint16 public currentPeriod = 1;

  address public moderator;

  mapping(address => mapping (address => uint256)) internal allowed;

  event Mint(address indexed to, uint256 amount);
  event PeriodEnd(uint16 period, uint256 amount, uint64 users);
  event Payment(address indexed from, uint256 amount);
  event Withdrawal(address indexed to, uint16 indexed period, uint256 amount);
  event NewUser(address addr, bytes20 username, uint64 endowment);

  modifier onlyMod() {
    require(msg.sender == moderator);
    _;
  }

  function Karma(uint256 _startEpoch) public {
    epoch = _startEpoch;
    moderator = msg.sender;
  }

  function() payable public {
    Payment(msg.sender, msg.value);
  }

  /** 
   * Owner Functions 
   */

  function setMod(address _newMod) public onlyOwner {
    moderator = _newMod;
  }

  // Owner should call this on 1st of every month.
  // _ownerCut is new owner cut for new period.
  function newPeriod(uint256 _ownerCut) public onlyOwner {
    require(now >= epoch + 28 days);
    require(_ownerCut <= 10000);

    uint256 unclaimedDividend = dividendPool;
    uint256 ownerRake = (this.balance-unclaimedDividend) * ownerCut / 10000;

    dividendPool = this.balance - unclaimedDividend - ownerRake;

    // Calculate dividend.
    uint64 existingUsers = numUsers;
    if (existingUsers == 0) {
      dividend = 0;
    } else {
      dividend = dividendPool / existingUsers;
    }

    numUsers = numUsers.add(newUsers);
    newUsers = 0;
    currentPeriod++;
    epoch = now;
    ownerCut = _ownerCut;

    msg.sender.transfer(ownerRake + unclaimedDividend);
    PeriodEnd(currentPeriod-1, this.balance, existingUsers);
  }

  /**
    * Mod Functions
    */

  function createUser(address _addr, bytes20 _username, uint64 _amount) public onlyMod {
    newUser(_addr, _username, _amount);
  }

  // Send karma to existing account.
  function mint(address _addr, uint64 _amount) public onlyMod {
    require(users[_addr].canWithdrawPeriod != 0);

    users[_addr].karma = users[_addr].karma.add(_amount);
    totalSupply = totalSupply.add(_amount);
    Mint(_addr, _amount);
  }

  // If a user has been bad, they won&#39;t be able to receive a dividend :(
  function timeout(address _addr) public onlyMod {
    require(users[_addr].canWithdrawPeriod != 0);

    users[_addr].canWithdrawPeriod = currentPeriod + 1;
  }

  /**
    * User Functions
    */

  // Owner will sign hash(address, username, amount), and address owner uses this 
  // signature to register their account.
  function register(bytes20 _username, uint64 _endowment, bytes _sig) public {
    require(recover(keccak256(msg.sender, _username, _endowment), _sig) == owner);
    newUser(msg.sender, _username, _endowment);
  }

  // User can withdraw their share of donations from the previous month.
  function withdraw() public {
    require(users[msg.sender].canWithdrawPeriod != 0);
    require(users[msg.sender].canWithdrawPeriod < currentPeriod);

    users[msg.sender].canWithdrawPeriod = currentPeriod;
    dividendPool -= dividend;
    msg.sender.transfer(dividend);
    Withdrawal(msg.sender, currentPeriod-1, dividend);
  }

  /**
    * ERC20 Functions
    */

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return users[_owner].karma;
  }

  // Contrary to most ERC20 implementations, require that recipient is existing user.
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(users[_to].canWithdrawPeriod != 0);
    require(_value <= users[msg.sender].karma);

    // Type assertion to uint64 is safe because we require that _value is < uint64 above.
    users[msg.sender].karma = users[msg.sender].karma.sub(uint64(_value));
    users[_to].karma = users[_to].karma.add(uint64(_value));
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  // Contrary to most ERC20 implementations, require that recipient is existing user.
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(users[_to].canWithdrawPeriod != 0);
    require(_value <= users[_from].karma);
    require(_value <= allowed[_from][msg.sender]);

    users[_from].karma = users[_from].karma.sub(uint64(_value));
    users[_to].karma = users[_to].karma.add(uint64(_value));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
    * Private Functions
    */

  // Ensures that username isn&#39;t taken, and account doesn&#39;t already exist for 
  // user&#39;s address.
  function newUser(address _addr, bytes20 _username, uint64 _endowment) private {
    require(usernames[_username] == address(0));
    require(users[_addr].canWithdrawPeriod == 0);

    users[_addr].canWithdrawPeriod = currentPeriod + 1;
    users[_addr].birthPeriod = currentPeriod;
    users[_addr].karma = _endowment;
    users[_addr].username = _username;
    usernames[_username] = _addr;

    newUsers = newUsers.add(1);
    totalSupply = totalSupply.add(_endowment);
    NewUser(_addr, _username, _endowment);
  }

  // https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/ECRecovery.sol
  function recover(bytes32 hash, bytes sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
}