pragma solidity 0.4.24;

// File: contracts/ERC20.sol

/**
 * @title ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/SafeMath.sol

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

// File: contracts/FlyCoin.sol

/**
 * FLYCoin ERC20 token
 * Based on the OpenZeppelin Standard Token
 */

contract MigrationSource {
  function vacate(address _addr) public returns (uint256 o_balance);
}

contract FLYCoin is MigrationSource, ERC20 {
  using SafeMath for uint256;

  string public constant name = "FLYCoin";
  string public constant symbol = "FLY";
  
  // picked to have 15 digits which will fit in a double full precision
  uint8 public constant decimals = 5;
  
  uint internal totalSupply_ = 3000000000000000;

  address public owner;

  mapping(address => User) public users;
  
  MigrationSource public migrateFrom;
  address public migrateTo;

  struct User {
    uint256 balance;
      
    mapping(address => uint256) authorized;
  }

  modifier only_owner(){
    require(msg.sender == owner);
    _;
  }

  modifier value_less_than_balance(address _user, uint256 _value){
    User storage user = users[_user];
    require(_value <= user.balance);
    _;
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  event OptIn(address indexed owner, uint256 value);
  event Vacate(address indexed owner, uint256 value);

  constructor() public {
    owner = msg.sender;
    User storage user = users[owner];
    user.balance = totalSupply_;
    emit Transfer(0, owner, totalSupply_);
  }

  function totalSupply() public view returns (uint256){
    return totalSupply_;
  }

  function balanceOf(address _addr) public view returns (uint256 balance) {
    return users[_addr].balance;
  }

  function transfer(address _to, uint256 _value) public value_less_than_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public value_less_than_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[_from];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    user.authorized[msg.sender] = user.authorized[msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success){
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (users[msg.sender].authorized[_spender] == 0));
    users[msg.sender].authorized[_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _user, address _spender) public view returns (uint256){
    return users[_user].authorized[_spender];
  }

  function setOwner(address _addr) public only_owner {
    owner = _addr;
  }

  // Sets the contract address that this contract will migrate
  // from when the optIn() interface is used.
  //
  function setMigrateFrom(address _addr) public only_owner {
    require(migrateFrom == MigrationSource(0));
    migrateFrom = MigrationSource(_addr);
  }

  // Sets the contract address that is allowed to call vacate on this
  // contract.
  //
  function setMigrateTo(address _addr) public only_owner {
    migrateTo = _addr;
  }

  // Called by a token holding address, this method migrates the
  // tokens from an older version of the contract to this version.
  //
  // NOTE - allowances (approve) are *not* transferred.  If you gave
  // another address an allowance in the old contract you need to
  // re-approve it in the new contract.
  //
  function optIn() public returns (bool success) {
    require(migrateFrom != MigrationSource(0));
    User storage user = users[msg.sender];
    
    uint256 balance = migrateFrom.vacate(msg.sender);

    emit OptIn(msg.sender, balance);
    
    user.balance = user.balance.add(balance);
    totalSupply_ = totalSupply_.add(balance);

    return true;
  }

  // The vacate method is called by a newer version of the FLYCoin
  // contract to extract the token state for an address and migrate it
  // to the new contract.
  //
  function vacate(address _addr) public returns (uint256 o_balance){
    require(msg.sender == migrateTo);
    User storage user = users[_addr];

    require(user.balance > 0);

    o_balance = user.balance;
    totalSupply_ = totalSupply_.sub(user.balance);
    user.balance = 0;

    emit Vacate(_addr, o_balance);
  }

  // Don&#39;t accept ETH. Starting from Solidity 0.4.0, contracts without a fallback function automatically revert payments
}