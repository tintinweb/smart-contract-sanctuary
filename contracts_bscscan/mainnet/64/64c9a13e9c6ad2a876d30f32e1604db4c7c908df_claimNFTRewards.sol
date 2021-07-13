/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity ^0.4.18;

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
    assert(c >= a);
    return c;
  }
}

// File: contracts/Owned.sol

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

  // owner address to enable admin functions
  mapping (address => bool) public isOwner;

  address[] public owners;

  address public operator;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function setOperator(address _operator) external onlyOwner {
    require(_operator != address(0));
    operator = _operator;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

// File: contracts/Token.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.8;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/claimPrize.sol

contract claimNFTRewards is Owned {

  mapping (address => bool) public users;

  mapping (address => uint256) public social;

  uint256 public levPerUser;

  Token public token;

  bool public dropEnabled;

  event Redeemed(address user, uint tokens);

  modifier isDropEnabled{
    require(dropEnabled);
    _;
  }

  function claimNFTRewards(address[] owners, address _token, uint256 _levPerUser) public {
    require(_token != address(0x0));
    require(_levPerUser > 0);
    setOwners(owners);
    token = Token(_token);
    levPerUser = _levPerUser;
  }

  function addUsers(address[] _users) onlyOwner public {
    require(_users.length > 0);
    for (uint i = 0; i < _users.length; i++) {
      users[_users[i]] = true;
    }
  }

  function addSocial(address[] _users, uint256[] _tokens) onlyOwner public {
    require(_users.length > 0 && _users.length == _tokens.length);
    for (uint i = 0; i < _users.length; i++) {
      social[_users[i]] += _tokens[i];
    }
  }

  function removeUsers(address[] _users) onlyOwner public {
    require(_users.length > 0);
    for (uint i = 0; i < _users.length; i++) {
      users[_users[i]] = false;
    }
  }
  
    function removeSocial(address[] _users) onlyOwner public {
      require(_users.length > 0);
    for (uint i = 0; i < _users.length; i++) {
        social[_users[i]] = 0;
    }
  }


  function toggleDrop() onlyOwner public {
    dropEnabled = !dropEnabled;
  }


  function balanceOf(address user) public constant returns (uint256) {
    uint256 levs = social[user];
    if (users[user]) levs += levPerUser;
    return levs;
  }

  function transferTokens(address _address, uint256 _amount) onlyOwner public {
    token.transfer(_address, _amount);
  }
  
  function setLevPerUser(uint256 newLevPerUser) public onlyOwner() {
    levPerUser = newLevPerUser;
  }
  
    function redeemTokens() isDropEnabled public {
    uint256 balance = balanceOf(msg.sender);
    require(balance > 0);
    users[msg.sender] = false; 
    social[msg.sender] = 0;
    token.transfer(msg.sender, balance);
    Redeemed(msg.sender, balance);
  }

}