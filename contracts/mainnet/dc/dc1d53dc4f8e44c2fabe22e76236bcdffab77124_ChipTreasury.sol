pragma solidity 0.4.23;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
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

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

// File: contracts/ChipTreasury.sol

contract ChipTreasury is Pausable {
  using SafeMath for uint256;

  mapping(uint => Chip) public chips;
  uint                  public numChipsMinted;
  uint                  public numChipsClaimed;

  struct Chip {
    bytes32 hash;
    bool claimed;
  }

  event Deposit(address indexed sender, uint value);
  event Withdrawal(address indexed to, uint value);
  event TokenWithdrawal(address indexed to, address indexed token, uint value);

  event ChipMinted(uint indexed chipId);
  event ChipHashReplaced(uint indexed chipId, bytes32 newHash, bytes32 oldhash);
  event ChipClaimAttempt(address indexed sender, uint indexed chipId);
  event ChipClaimSuccess(address indexed sender, uint indexed chipId);

  constructor () public {
    paused = true;
  }

  function () public payable {
    if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  }

  function claimChip (uint chipId, string password) public whenNotPaused {
    emit ChipClaimAttempt(msg.sender, chipId);
    // 1. Conditions
    require(isClaimed(chipId) == false);       // chip is unclaimed
    require(isChipPassword(chipId, password)); // sender has chip password

    // 2. Effects
    uint chipValue = getChipValue();           // get chip value
    numChipsClaimed = numChipsClaimed.add(1);  // increase claimed count
    chips[chipId].claimed = true;              // mark chip as claimed

    // 3. Interaction
    msg.sender.transfer(chipValue);            // send ether to the sender
    emit ChipClaimSuccess(msg.sender, chipId);
  }

  // NOTE: You must prefix hashes with &#39;0x&#39;
  function mintChip (bytes32 hash) public onlyOwner {
    chips[numChipsMinted] = Chip(hash, false);
    emit ChipMinted(numChipsMinted);
    numChipsMinted = numChipsMinted.add(1);
  }

  // Mint function that allows for transactions to come in out-of-order
  // However it is unsafe because a mistakenly high chipId could throw off numChipsMinted permanently
  // NOTE: You must prefix hashes with &#39;0x&#39;
  function mintChipUnsafely (uint chipId, bytes32 hash) public onlyOwner whenPaused {
    require(chips[chipId].hash == ""); // chip hash must initially be unset
    chips[chipId].hash = hash;
    emit ChipMinted(chipId);
    numChipsMinted = numChipsMinted.add(1);
  }

  // In case you mess something up during minting (╯&#176;□&#176;）╯︵ ┻━┻
  // NOTE: You must prefix hashes with &#39;0x&#39;
  function replaceChiphash (uint chipId, bytes32 newHash) public onlyOwner whenPaused {
    require(chips[chipId].hash != ""); // chip hash must not be unset
    bytes32 oldHash = chips[chipId].hash;
    chips[chipId].hash = newHash;
    emit ChipHashReplaced(chipId, newHash, oldHash);
  }

  function withdrawFunds (uint value) public onlyOwner {
    owner.transfer(value);
    emit Withdrawal(owner, value);
  }

  function withdrawTokens (address token, uint value) public onlyOwner {
    StandardToken(token).transfer(owner, value);
    emit TokenWithdrawal(owner, token, value);
  }

  function isClaimed (uint chipId) public view returns(bool) {
    return chips[chipId].claimed;
  }

  function getNumChips () public view returns(uint) {
    return numChipsMinted.sub(numChipsClaimed);
  }

  function getChipIds (bool isChipClaimed) public view returns(uint[]) {
    uint[] memory chipIdsTemp = new uint[](numChipsMinted);
    uint count = 0;
    uint i;

    // filter chips by isChipClaimed status
    for (i = 0; i < numChipsMinted; i++) {
      if (isChipClaimed == chips[i].claimed) {
        chipIdsTemp[count] = i;
        count += 1;
      }
    }

    // return array of filtered chip ids
    uint[] memory _chipIds = new uint[](count);
    for (i = 0; i < count; i++) _chipIds[i] = chipIdsTemp[i];
    return _chipIds;
  }

  function getChipValue () public view returns(uint) {
    uint numChips = getNumChips();
    if (numChips > 0) return address(this).balance.div(numChips);
    return 0;
  }

  function isChipPassword (uint chipId, string password) internal view returns(bool) {
    return chips[chipId].hash == keccak256(password);
  }

}