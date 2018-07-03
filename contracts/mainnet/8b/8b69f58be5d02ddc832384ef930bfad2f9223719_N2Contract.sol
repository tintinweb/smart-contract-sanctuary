pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ReentrancyGuard {
  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}

contract AccessControl {
  /// @dev Emited when contract is upgraded
  event ContractUpgrade(address newContract);

  address public owner;

  // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
  bool public paused = false;

  /**
   * @dev The AccessControl constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function AccessControl() public {
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
    owner = newOwner;
  }

  /// @dev Modifier to allow actions only when the contract IS NOT paused
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS paused
  modifier whenPaused() {
    require(paused);
    _;
  }

  /// @dev Called by owner role to pause the contract. Used only when
  ///  a bug or exploit is detected and we need to limit damage.
  function pause() external onlyOwner whenNotPaused {
    paused = true;
  }

  /// @dev Unpauses the smart contract. Can only be called owner.
  /// @notice This is public rather than external so it can be called by
  ///  derived contracts.
  function unpause() public onlyOwner whenPaused {
    // can&#39;t unpause if contract was upgraded
    paused = false;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract BasicToken is AccessControl, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract LockableToken is StandardToken, ReentrancyGuard {
  struct LockedBalance {
    address owner;
    uint256 value;
    uint256 releaseTime;
  }

  mapping (uint => LockedBalance) public lockedBalances;
  uint public lockedBalanceCount;

  event TransferLockedToken(address indexed from, address indexed to, uint256 value, uint256 releaseTime);
  event ReleaseLockedBalance(address indexed owner, uint256 value, uint256 releaseTime);

  /**
  * @dev transfer and lock token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @param _releaseTime The time to be locked.
  */
  function transferLockedToken(address _to, uint256 _value, uint256 _releaseTime) public whenNotPaused nonReentrant returns (bool) {
    require(_releaseTime > now);
    //require(_releaseTime.sub(1 years) < now);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    lockedBalances[lockedBalanceCount] = LockedBalance({owner: _to, value: _value, releaseTime: _releaseTime});
    lockedBalanceCount++;
    emit TransferLockedToken(msg.sender, _to, _value, _releaseTime);
    return true;
  }

  /**
  * @dev Gets the locked balance of the specified address.
  * @param _owner The address to query the the locked balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function lockedBalanceOf(address _owner) public constant returns (uint256 value) {
    for (uint i = 0; i < lockedBalanceCount; i++) {
      LockedBalance storage lockedBalance = lockedBalances[i];
      if (_owner == lockedBalance.owner) {
        value = value.add(lockedBalance.value);
      }
    }
    return value;
  }

  /**
  * @dev Release the locked balance if its releaseTime arrived.
  * @return An uint256 representing the amount.
  */
  function releaseLockedBalance() public whenNotPaused returns (uint256 releaseAmount) {
    uint index = 0;
    while (index < lockedBalanceCount) {
      if (now >= lockedBalances[index].releaseTime) {
        releaseAmount += lockedBalances[index].value;
        unlockBalanceByIndex(index);
      } else {
        index++;
      }
    }
    return releaseAmount;
  }

  function unlockBalanceByIndex(uint index) internal {
    LockedBalance storage lockedBalance = lockedBalances[index];
    balances[lockedBalance.owner] = balances[lockedBalance.owner].add(lockedBalance.value);
    emit ReleaseLockedBalance(lockedBalance.owner, lockedBalance.value, lockedBalance.releaseTime);
    lockedBalances[index] = lockedBalances[lockedBalanceCount - 1];
    delete lockedBalances[lockedBalanceCount - 1];
    lockedBalanceCount--;
  }
}

contract ReleaseableToken is LockableToken {
  uint256 public createTime;
  uint256 public nextReleaseTime;
  uint256 public nextReleaseAmount;
  uint256 standardDecimals = 10000;
  uint256 public totalSupply;
  uint256 public releasedSupply;

  function ReleaseableToken(uint256 initialSupply, uint256 initReleasedSupply, uint256 firstReleaseAmount) public {
    createTime = now;
    nextReleaseTime = now;
    nextReleaseAmount = firstReleaseAmount;
    totalSupply = standardDecimals.mul(initialSupply);
    releasedSupply = standardDecimals.mul(initReleasedSupply);
    balances[msg.sender] = standardDecimals.mul(initReleasedSupply);
  }

  /**
  * @dev Release a part of the frozen token(totalSupply - releasedSupply) every 26 weeks.
  * @return An uint256 representing the amount.
  */
  function release() public whenNotPaused returns(uint256 _releaseAmount) {
    require(nextReleaseTime <= now);

    uint256 releaseAmount = 0;
    uint256 remainderAmount = totalSupply.sub(releasedSupply);
    if (remainderAmount > 0) {
      releaseAmount = standardDecimals.mul(nextReleaseAmount);
      if (releaseAmount > remainderAmount)
        releaseAmount = remainderAmount;
      releasedSupply = releasedSupply.add(releaseAmount);
      balances[owner] = balances[owner].add(releaseAmount);
      emit Release(msg.sender, releaseAmount, nextReleaseTime);
      nextReleaseTime = nextReleaseTime.add(26 * 1 weeks);
      nextReleaseAmount = nextReleaseAmount.sub(nextReleaseAmount.div(4));
    }
    return releaseAmount;
  }

  event Release(address receiver, uint256 amount, uint256 releaseTime);
}

contract N2Contract is ReleaseableToken {
  string public name = &#39;N2Chain&#39;;
  string public symbol = &#39;N2C&#39;;
  uint8 public decimals = 4;

  // Set in case the core contract is broken and an upgrade is required
  address public newContractAddress;

  function N2Contract() public ReleaseableToken(1000000000, 200000000, 200000000) {}

  /// @dev Used to mark the smart contract as upgraded, in case there is a serious
  ///  breaking bug. This method does nothing but keep track of the new contract and
  ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
  ///  contract to update to the new contract address in that case. (This contract will
  ///  be paused indefinitely if such an upgrade takes place.)
  /// @param _v2Address new address
  function setNewAddress(address _v2Address) external onlyOwner whenPaused {
    newContractAddress = _v2Address;
    emit ContractUpgrade(_v2Address);
  }

  /// @dev Override unpause so it requires all external contract addresses
  ///  to be set before contract can be unpaused. Also, we can&#39;t have
  ///  newContractAddress set either, because then the contract was upgraded.
  /// @notice This is public rather than external so we can call super.unpause
  ///  without using an expensive CALL.
  function unpause() public onlyOwner whenPaused {
    require(newContractAddress == address(0));

    // Actually unpause the contract.
    super.unpause();
  }
}