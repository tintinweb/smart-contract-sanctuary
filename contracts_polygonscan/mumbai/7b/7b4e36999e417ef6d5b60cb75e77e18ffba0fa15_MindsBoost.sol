pragma solidity ^0.4.24;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) external restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) external restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

pragma solidity ^0.4.24;

import './MindsToken.sol';
import './MindsBoostStorage.sol';

contract MindsBoost {

  struct Boost {
    address sender;
    address receiver;
    uint value;
    uint256 checksum;
    bool locked; //if the user has already interacted with
  }

  MindsToken public token;
  MindsBoostStorage public s;

  /**
   * event for boost being created
   * @param guid - the guid of the boost
   */
  event BoostSent(uint256 guid);

  /**
   * event for boost being accepted
   * @param guid - the guid of the boost
   */
  event BoostAccepted(uint256 guid);

  /**
   * event for boost being rejected
   * @param guid - the guid of the boost
   */
  event BoostRejected(uint256 guid);

  /**
   * event for boost being revoked
   * @param guid - the guid of the boost
   */
  event BoostRevoked(uint256 guid);

  constructor(address _storage, address _token) public {
    s = MindsBoostStorage(_storage);
    token = MindsToken(_token);
  }

  function canIBoost() public view returns (bool) {
    uint balance = token.balanceOf(msg.sender);
    uint allowed = token.allowance(msg.sender, address(this));

    if (allowed > 0 && balance > 0) {
      return true;
    }

    return false;
  }

  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) public returns (bool) {

    require(msg.sender == address(token));

    uint256 _guid = 0;
    address _receiver = 0x0;
    uint256 _checksum = 0;

    assembly {
      // Load the raw bytes into the respective variables to avoid any sort of costly
      // conversion.
      _checksum := mload(add(_extraData, 0x60))
      _guid := mload(add(_extraData, 0x40))
      _receiver := mload(add(_extraData, 0x20))
    }

    require(_receiver != 0x0);

    return boostFrom(_from, _guid, _receiver, _value, _checksum);
  }

  function boost(uint256 guid, address receiver, uint amount, uint256 checksum) public returns (bool) {
    return boostFrom(msg.sender, guid, receiver, amount, checksum);
  }

  function boostFrom(address sender, uint256 guid, address receiver, uint amount, uint256 checksum) private returns (bool) {

    //make sure our boost is for over 0
    require(amount > 0);

    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //must not exists
    require(_boost.sender == 0);
    require(_boost.receiver == 0);

    //spend tokens and store here
    token.transferFrom(sender, address(this), amount);

    //allow this contract to spend those tokens later
    token.approve(address(this), amount);

    //store boost
    s.upsert(guid, sender, receiver, amount, checksum, false);

    //send event
    emit BoostSent(guid);
    return true;
  }

  function accept(uint256 guid) public {

    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //do not do anything if we've aleady started accepting/rejecting
    require(_boost.locked == false);

    //check the receiver is the person accepting
    require(_boost.receiver == msg.sender);
    
    //lock
    s.upsert(guid, _boost.sender, _boost.receiver, _boost.value,  _boost.checksum, true);

    //send tokens to the receiver
    token.transferFrom(address(this), _boost.receiver, _boost.value);

    //send event
    emit BoostAccepted(guid);
  }

  function reject(uint256 guid) public {
    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //do not do anything if we've aleady started accepting/rejecting
    require(_boost.locked == false);

    //check the receiver is the person accepting
    require(_boost.receiver == msg.sender);
    
    //lock
    s.upsert(guid, _boost.sender, _boost.receiver, _boost.value, _boost.checksum, true);

    //send tokens back to sender
    token.transferFrom(address(this), _boost.sender, _boost.value);

    //send event
    emit BoostRejected(guid);
  }

  function revoke(uint256 guid) public {
    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //do not do anything if we've aleady started accepting/rejecting
    require(_boost.locked == false);

    //check the receiver is the person accepting
    require(_boost.sender == msg.sender);
    
    //lock
    s.upsert(guid, _boost.sender, _boost.receiver, _boost.value, _boost.checksum, true);

    //send tokens back to sender
    token.transferFrom(address(this), _boost.sender, _boost.value);

    //send event
    emit BoostRevoked(guid);
  }

}

pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract MindsToken is MintableToken {

    string public constant name = "Minds";
    string public constant symbol = "MINDS";
    uint8 public constant decimals = 18;

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the spender function
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}

pragma solidity ^0.4.24;

import './MindsToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract MindsBoostStorage is Ownable {

  struct Boost {
    address sender;
    address receiver;
    uint value;
    uint256 checksum;
    bool locked; //if the user has already interacted with
  }

  // Mapping of boosts by guid
  mapping(uint256 => Boost) public boosts;

  // Allowed contracts
  mapping(address => bool) public contracts;

  /**
   * Save the boost to the storage
   * @param guid The guid of the boost
   * @param sender The sender of the boost
   * @param receiver The receiver of the boost
   * @param value The value of the boost
   * @param locked If the boost is locked or not
   * @return bool
   */
  function upsert(uint256 guid, address sender, address receiver, uint value, uint256 checksum, bool locked) public returns (bool) {

    //only allow if transaction from an approved contract
    require(contracts[msg.sender]);

    Boost memory _boost = Boost(
      sender,
      receiver,
      value,
      checksum,
      locked
    );

    boosts[guid] = _boost;
    return true;
  }

  /**
   * Modify the allowed contracts that can write to this contract
   * @param addr The address of the contract
   * @param allowed True/False
   */
  function modifyContracts(address addr, bool allowed) public onlyOwner {
    contracts[addr] = allowed;
  }

}

pragma solidity ^0.4.24;

import "./StandardToken.sol";
import "../../ownership/Ownable.sol";


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

pragma solidity ^0.4.24;

import "./BasicToken.sol";
import "./ERC20.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

pragma solidity ^0.4.24;


import "./ERC20Basic.sol";
import "../../math/SafeMath.sol";


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

pragma solidity ^0.4.24;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.24;

import './MindsToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract MindsWithdraw is Ownable {

  struct Withdrawal {
    address requester;
    uint256 user_guid;
    uint256 gas;
    uint256 amount;
  }

  MindsToken public token;

  /** Address which receives the gas **/
  address public forwardAddress;
 
  mapping(uint256 => Withdrawal) public requests;

  /**
   * event upon requesting a withdrawal
   * @param requester who requested the withdrawal
   * @param user_guid the minds user guid of the requester
   * @param gas the amount in ethereum that was sent to cover the gas
   * @param amount weis requested
   */
  event WithdrawalRequest(address requester, uint256 user_guid, uint256 gas, uint256 amount);

  /**
   * event upon completing a withdrawal
   * @param requester who requested the withdrawal
   * @param user_guid the minds user guid of the requester
   * @param amount weis requested
   */
  event WithdrawalComplete(address requester, uint256 user_guid, uint256 amount);

  constructor(address _token, address _forwardAddress) public {
    token = MindsToken(_token);
    forwardAddress = _forwardAddress;
  }

  function request(uint256 user_guid, uint256 amount) public payable {
    
    uint256 gas = msg.value;

    require(gas > 0);
    require(amount > 0);

    Withdrawal memory _withdrawal = Withdrawal(
      msg.sender,
      user_guid,
      msg.value,
      amount
    );
    
    requests[user_guid] = _withdrawal;

    //forward funds to our address to cover gas
    forwardAddress.transfer(gas);

    emit WithdrawalRequest(msg.sender, user_guid, msg.value, amount);
  }

  // do nothing if we get sent ether
  function() external payable { 
    msg.sender.transfer(msg.value);
  }

  function complete(address requester, uint256 user_guid, uint256 gas, uint256 amount) public returns (bool) {
    
    require(requests[user_guid].user_guid == user_guid);
    require(requests[user_guid].gas == gas);
    require(requests[user_guid].amount == amount);

    token.transferFrom(msg.sender, requester, amount);

    emit WithdrawalComplete(requester, user_guid, amount);
    
    //zero the requested withdrawl amaount
    requests[user_guid].amount = 0;

    return true;
  }

  /**
   * Set the forward address to receive the gas
   * @param addr The address to receive the gas
   */
  function setForwardAddress(address addr) public onlyOwner {
    forwardAddress = addr;
  }

}

pragma solidity ^0.4.24;

import './MindsToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract MindsWireStorage is Ownable {

  struct Wire {
    uint timestamp;
    uint value;
  }

  // Mapping of wires by receiver
  mapping(address => mapping(address => Wire[])) public wires;

  // Allowed contracts
  mapping(address => bool) public contracts;

  /**
   * Insert the wire to the storage
   * @param sender The sender
   * @param receiver The receiver
   * @param value The value of the wire
   * @return bool
   */
  function insert(address sender, address receiver, uint value) public returns (bool) {

    //only allow if transaction from an approved contract
    require(contracts[msg.sender]);

    Wire memory wire = Wire(
      block.timestamp, 
      value
    );

    wires[receiver][sender].push(wire);
    return true;
  }

  /**
   * Return the count of wires
   * @param receiver The receiver
   * @param sender The sender
   * @return uint
   */
  function countWires(address receiver, address sender) public view returns (uint) {
    return wires[receiver][sender].length;
  }

  /**
   * Modify the allowed contracts that can write to this contract
   * @param addr The address of the contract
   * @param allowed True/False
   */
  function modifyContracts(address addr, bool allowed) public onlyOwner {
    contracts[addr] = allowed;
  }

}

pragma solidity ^0.4.24;

import './MindsToken.sol';
import './MindsWireStorage.sol';
import './Whitelist.sol';

contract MindsWire is Whitelist {

  struct Wire {
    uint timestamp;
    uint value;
  }

  MindsToken public token;
  MindsWireStorage public s;

  /**
   * event for wire sending
   * @param sender who sent the wire
   * @param receiver who receive the wire
   * @param amount weis sent
   */
  event WireSent(address sender, address receiver, uint256 amount);

  constructor(address _storage, address _token) public {
    s = MindsWireStorage(_storage);
    token = MindsToken(_token);
  }

  function canIWire() public view returns (bool) {
    uint balance = token.balanceOf(msg.sender);
    uint allowed = token.allowance(msg.sender, address(this));

    if (allowed > 0 && balance > 0) {
      return true;
    }

    return false;
  }

  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) public returns (bool) {

    require(msg.sender == address(token));

    address _receiver = 0x0;
    assembly {
      // Load the raw bytes into the respective variables to avoid any sort of costly
      // conversion.
      _receiver := mload(add(_extraData, 0x20))
    }

    require(_receiver != 0x0);

    return wireFrom(_from, _receiver, _value);
  }

  /**
   * Users call this function to send a wire
   */
  function wire(address receiver, uint amount) public returns (bool) {
    return wireFrom(msg.sender, receiver, amount);
  }

  /**
   * Internal function to send the wire
   */
  function wireFrom(address sender, address receiver, uint amount) internal returns (bool) {

    require(amount > 0);

    token.transferFrom(sender, receiver, amount);
    s.insert(sender, receiver, amount);
    emit WireSent(sender, receiver, amount);
    return true;
  }

  /**
   * Used by servers that act as delegates. Must be whitelisted
   */
  function wireFromDelegate(address sender, address receiver, uint amount) public 
    onlyIfWhitelisted(msg.sender) returns (bool) {
      return wireFrom(sender, receiver, amount);
  }

  function hasSent(address receiver, uint amount, uint timestamp) public view returns (bool) {
    uint total;

    Wire memory _wire;

    uint len = s.countWires(receiver, msg.sender);

    for (uint i = 0; i < len; i++) {
      (_wire.timestamp, _wire.value) = s.wires(receiver, msg.sender, i);

      if (_wire.timestamp >= timestamp) {
        total += _wire.value;
      }
    }

    if (total >= amount) {
      return true;
    }

    return false;
  }

}

pragma solidity ^0.4.24;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ownership/rbac/RBAC.sol";


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

pragma solidity ^0.4.24;

import "./Roles.sol";


/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 * It's also recommended that you define constants in the contract, like ROLE_ADMIN below,
 * to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

pragma solidity ^0.4.24;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

pragma solidity ^0.4.24;

import './MindsToken.sol';

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './Whitelist.sol'; //until new zeppelin version

contract MindsTokenSaleEvent is Whitelist {

  using SafeMath for uint256;

  // The token being sold
  MindsToken public token;

  // address where funds are collected
  address public wallet;

  // how many mei per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  // outstanding token purchases addresses
  mapping(address => uint256) public outstanding;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param tokens amount of tokens purchased
   * @param weiAmount amount of wei sent
   * @param rate the rate 
   */
  event TokenPurchase(
    address purchaser,
    uint256 tokens,
    uint256 weiAmount,
    uint256 rate
  );

  /**
   * Event for token issuance
   * @param purchaser Address who purchased the tokens
   * @param tokens amount of tokens purchased
   * @param rate the rate used
   */
  event TokenIssue(
    address purchaser,
    uint256 tokens,
    uint256 rate
  );

  /**
   * Event for declining token
   * @param purchaser Address who purchased the tokens
   * @param tokens amount of tokens purchased
   * @param weiAmount the amount of wei refunded
   * @param rate the rate used for the refund
   */
  event TokenDecline(
    address purchaser,
    uint256 tokens,
    uint256 weiAmount,
    uint256 rate
  );

  /**
   * Event for rate change
   * @param newRate the rate changed
   */
  event RateModified(
    uint256 newRate
  );

  constructor(uint256 _rate, address _wallet, address _token) public {
    require(_rate > 0);
    require(_wallet != address(0));

    token = MindsToken(_token);
    rate = _rate;
    wallet = _wallet;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender, rate);
  }

  // low level token purchase function
  function buyTokens(address beneficiary, uint256 _rate) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    require(_rate == rate); // Ensure the sender has sent the correct rate variable

    uint256 weiAmount = msg.value;

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // increase outstanding purchases and emit event
    increaseOutstandingPurchases(beneficiary, tokens);

    // send funds
    forwardFunds();

    // send event
    emit TokenPurchase(beneficiary, tokens, weiAmount, rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value > 0;
    return nonZeroPurchase;
  }

  // Issue tokens

  function issue(address beneficiary, uint256 tokens) external 
    onlyIfWhitelisted(msg.sender) {
    
    // check that there is outstanding tokens to issue
    require(areTokensOutstanding(beneficiary, tokens));

    decreaseOutstandingPurchases(beneficiary, tokens);

    // send our tokens
    token.transferFrom(wallet, beneficiary, tokens);
    emit TokenIssue(beneficiary, tokens, rate);
  }

  // Decline the tokens

  function decline(address beneficiary, uint256 tokens, uint256 _rate) external 
    payable
    onlyIfWhitelisted(msg.sender) {

    require(_rate > 0); // Ensure rate is above 0

    decreaseOutstandingPurchases(beneficiary, tokens);

    //refund the ETH value
    uint256 weiAmount = tokens.div(_rate);

    require(msg.value == weiAmount); // Check that the senders rate is correct

    beneficiary.transfer(weiAmount); // This will deduct from the *SENDER*
   
    emit TokenDecline(beneficiary, tokens, weiAmount, _rate);
  }

  // Modify the rate

  function modifyRate(uint256 _rate) external 
    onlyIfWhitelisted(msg.sender) {

    require(_rate > 0); // Ensure rate is above 0

    rate = _rate;

    emit RateModified(_rate);
  }

  // Return the current rate

  function getRate() public view returns (uint256) {
    return rate;
  }

  // Check that enough tokens have been purchased

  function areTokensOutstanding(address beneficiary, uint256 tokens) internal view returns (bool) {
    bool hasOutstanding = outstanding[beneficiary] > 0;
    bool isValid = tokens > 0;
    bool isEnough = tokens <= outstanding[beneficiary];
    return isValid && isEnough && hasOutstanding;
  }

  // Increase the number of purchased tokens awaiting issuance

  function increaseOutstandingPurchases(address beneficiary, uint256 tokens) internal {
    outstanding[beneficiary] = outstanding[beneficiary].add(tokens);
  }

  // Decrease the number of purchased tokens awaiting issuance

  function decreaseOutstandingPurchases(address beneficiary, uint256 tokens) internal {
    outstanding[beneficiary] = outstanding[beneficiary].sub(tokens);
  }

}