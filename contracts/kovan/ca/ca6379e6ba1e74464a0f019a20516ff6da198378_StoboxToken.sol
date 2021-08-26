/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity 0.4.25;

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
  constructor() public {
    owner = msg.sender;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only the Contract owner can perform this action");
    _;
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "New owner cannot be current owner");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title BEP20Basic
 * @dev Simpler version of BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract BEP20Basic {

  /// Total amount of tokens
  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _amount) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);

}

/**
 * @title BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract BEP20 is BEP20Basic {

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

  function approve(address _spender, uint256 _amount) public returns (bool success);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is BEP20Basic {

  using SafeMath for uint256;
  uint balanceOfParticipant;
  uint lockedAmount;
  uint allowedAmount;
  bool lockupIsActive = false;
  uint256 lockupStartTime;

  // balances for each address
  mapping(address => uint256) balances;

  struct Lockup {
    uint256 lockupAmount;
  }
  Lockup lockup;
  mapping(address => Lockup) lockupParticipants;
  event LockupStarted(uint256 indexed lockupStartTime);

  function requireWithinLockupRange(address _spender, uint256 _amount) internal {
    if (lockupIsActive) {
      uint timePassed = now - lockupStartTime;
      balanceOfParticipant = balances[_spender];
      lockedAmount = lockupParticipants[_spender].lockupAmount;
      allowedAmount = lockedAmount;
      if (timePassed < 92 days) {
        allowedAmount = lockedAmount.mul(5).div(100);
      } else if (timePassed >= 92 days && timePassed < 183 days) {
        allowedAmount = lockedAmount.mul(30).div(100);
      } else if (timePassed >= 183 days && timePassed < 365 days) {
        allowedAmount = lockedAmount.mul(55).div(100);
      }
      require(
        balanceOfParticipant.sub(_amount) >= lockedAmount.sub(allowedAmount),
        "Must maintain correct % of PVC during lockup periods"
      );
    }
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _amount The amount to be transferred.
  */
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != msg.sender, "Cannot transfer to self");
    require(_to != address(this), "Cannot transfer to Contract");
    require(_to != address(0), "Cannot transfer to 0x0");
    require(
      balances[msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to],
      "Cannot transfer (Not enough balance)"
    );

    requireWithinLockupRange(msg.sender, _amount);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
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

/**
 * @title Standard BEP20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BEP20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
  * @dev Transfer tokens from one address to another
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _amount uint256 the amount of tokens to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_from != msg.sender, "Cannot transfer from self, use transfer function instead");
    require(_from != address(this) && _to != address(this), "Cannot transfer from or to Contract");
    require(_to != address(0), "Cannot transfer to 0x0");
    require(balances[_from] >= _amount, "Not enough balance to transfer from");
    require(allowed[_from][msg.sender] >= _amount, "Not enough allowance to transfer from");
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to], "Amount must be > 0 to transfer from");

    requireWithinLockupRange(_from, _amount);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

  /**
  * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
  *
  * Beware that changing an allowance with this method brings the risk that someone may use both the old
  * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
  * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  * @param _spender The address which will spend the funds.
  * @param _amount The amount of tokens to be spent.
  */
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    require(_spender != msg.sender, "Cannot approve an allowance to self");
    require(_spender != address(this), "Cannot approve contract an allowance");
    require(_spender != address(0), "Cannot approve 0x0 an allowance");
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  * @param _owner address The address which owns the funds.
  * @param _spender address The address which will spend the funds.
  * @return A uint256 specifying the amount of tokens still available for the spender.
  */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken, Ownable {

  event Burn(address indexed burner, uint256 value);

  /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
  function burn(uint256 _value) public onlyOwner {
    require(_value <= balances[msg.sender], "Not enough balance to burn");
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
  }

}

/**
 * @title Brainz
 * @dev Token representing Brainz.
 */
contract StoboxToken is BurnableToken {

  string public name;
  string public symbol;
  uint8 public decimals = 18;
  
  /**
  * @dev users sending ether to this contract will be reverted. Any ether sent to the contract will be sent back to the caller
  */
  function() external payable {
    revert("Cannot send Ether to this contract");
  }
    
  /**
  * @dev Constructor function to initialize the initial supply of token to the creator of the contract
  */
  constructor(address wallet) public {
    owner = wallet;
    totalSupply = uint(100000000).mul(10 ** uint256(decimals)); //Update total supply with the decimal amount
    name = "Stobox Token";
    symbol = "STBU";
    balances[wallet] = totalSupply;
    
    //Emitting transfer event since assigning all tokens to the creator also corresponds to the transfer of tokens to the creator
    emit Transfer(address(0), msg.sender, totalSupply);
  }
    
  /**
  * @dev helper method to get token details, name, symbol and totalSupply in one go
  */
  function getTokenDetail() public view returns (string memory, string memory, uint256) {
    return (name, symbol, totalSupply);
  }

  function vest(address[] memory _owners, uint[] memory _amounts) public onlyOwner {
    require(_owners.length == _amounts.length, "Length of addresses & token amounts are not the same");
    for (uint i = 0; i < _owners.length; i++) {
      _amounts[i] = _amounts[i].mul(10 ** 18);
      require(_owners[i] != address(0), "Vesting funds cannot be sent to 0x0");
      require(_amounts[i] > 0, "Amount must be > 0");
      require(balances[owner] > _amounts[i], "Not enough balance to vest");
      require(balances[_owners[i]].add(_amounts[i]) > balances[_owners[i]], "Internal vesting error");

      // SafeMath.sub will throw if there is not enough balance.
      balances[owner] = balances[owner].sub(_amounts[i]);
      balances[_owners[i]] = balances[_owners[i]].add(_amounts[i]);
      emit Transfer(owner, _owners[i], _amounts[i]);
      lockup = Lockup({ lockupAmount: _amounts[i] });
      lockupParticipants[_owners[i]] = lockup;
    }
  }

  function initiateLockup() public onlyOwner {
    uint256 currentTime = now;
    lockupIsActive = true;
    lockupStartTime = currentTime;
    emit LockupStarted(currentTime);
  }

  function lockupActive() public view returns (bool) {
    return lockupIsActive;
  }

  function lockupAmountOf(address _owner) public view returns (uint256) {
    return lockupParticipants[_owner].lockupAmount;
  }

}