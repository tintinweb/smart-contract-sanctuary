pragma solidity 0.4.24;

pragma solidity ^0.4.11;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}













/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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







/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}







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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



/**
 * @title Element Token
 * @dev ERC20 Element Token)
 *
 * All initial tokens are assigned to the creator of
 * this contract.
 *
 */
contract ElementToken is StandardToken, Pausable {

  string public name = &#39;&#39;;               // Set the token name for display
  string public symbol = &#39;&#39;;             // Set the token symbol for display
  uint8 public decimals = 0;             // Set the token symbol for display

  /**
   * @dev Don&#39;t allow tokens to be sent to the contract
   */
  modifier rejectTokensToContract(address _to) {
    require(_to != address(this));
    _;
  }

  /**
   * @dev ElementToken Constructor
   * Runs only on initial contract creation.
   */
  function ElementToken(string _name, string _symbol, uint256 _tokens, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _tokens * 10**uint256(decimals);          // Set the total supply
    balances[msg.sender] = totalSupply;                      // Creator address is assigned all
    Transfer(0x0, msg.sender, totalSupply);                  // create Transfer event for minting
  }

  /**
   * @dev Transfer token for a specified address when not paused
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) rejectTokensToContract(_to) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another when not paused
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) rejectTokensToContract(_to) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender when not paused.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * Adding whenNotPaused
   */
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  /**
   * Adding whenNotPaused
   */
  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}


/**
 * @title ERC900 Simple Staking Interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract ERC900 {
  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

  function stake(uint256 amount, bytes data) public;
  function stakeFor(address user, uint256 amount, bytes data) public;
  function unstake(uint256 amount, bytes data) public;
  function totalStakedFor(address addr) public view returns (uint256);
  function totalStaked() public view returns (uint256);
  function token() public view returns (address);
  function supportsHistory() public pure returns (bool);

  // NOTE: Not implementing the optional functions
  // function lastStakedFor(address addr) public view returns (uint256);
  // function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
  // function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

contract AirdropComponent {

  using SafeMath for uint256;

  // Token used for airdropping and staking
  ElementToken elementToken;

  // The number of seconds in six months (according to 365.25 days / 2)
  // Used to determine lockInDuration
  uint256 SIX_MONTHS_IN_SECONDS = 15778800;

  // The duration of lock-in (in seconds)
  // Used for locking both staked and airdropped tokens
  uint256 public lockInDuration = SIX_MONTHS_IN_SECONDS;

  // mapping for the approved airdrop users
  mapping (address => AirdropContainer) public approvedUsers;

  // tracks total number of tokens that have been airdropped
  uint256 public totalAirdropped;

  // event for withdrawing unstaked airdropped tokens
  event Withdrawn(address indexed user, uint256 amount, bytes data);

  // event for airdropping tokens
  event Airdropped(address indexed user, uint256 amount, bytes data);

  // Struct for personal airdropped token data (i.e., tokens airdropped to this address)
  // airdropTimestamp - when the token was initially airdropped to this address
  // unlockTimestamp - when the token unlocks (in seconds since Unix epoch)
  // amount - the amount of unstaked tokens airdropped to this address
  struct Airdrop {
    uint256 airdropTimestamp;
    uint256 unlockTimestamp;
    uint256 amount;
  }

  // Struct for all airdrop metadata for a particular address
  // airdrop - struct containing personal airdrop token data
  // unstaked - whether this address has unstaked airdropped tokens
  // airdropped - whether this address has been airdropped (only one airdrop per address allowed)
  struct AirdropContainer {
    Airdrop airdrop;
    bool unstaked;
    bool airdropped;
  }

  /**
   * @dev Modifier that checks if airdrop token sender can transfer tokens
   * from their balance in the elementToken contract to the stakingLockup
   * contract on behalf of a particular address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
  modifier canAirdrop(address _address, uint256 _amount) {
    require(
      elementToken.transferFrom(_address, this, _amount),
      &quot;Insufficient token balance of sender&quot;);
    _;
  }

  /**
   * @dev Modifier that checks if approved airdrop user has already been airdropped.
   * @param _address address to check in approvedUsers mapping
   */
  modifier checkAirdrop(address _address) {
      require(!approvedUsers[_address].airdropped, &quot;User already airdropped&quot;);
      _;
  }

  /**
   * @dev Helper function that returns the timestamp for when a user&#39;s airdropped tokens will unlock
   * @param _address address of airdropped user
   * @return uint256 timestamp
   */
  function _getPersonalAirdropUnlockTimestamp(address _address) internal view returns (uint256) {
    (uint256 timestamp,) = _getPersonalAirdrop(_address);

    return timestamp;
  }

  /**
   * @dev Helper function that returns the amount of airdropped tokens for an address
   * @param _address address of airdropped user
   * @return uint256 amount
   */
  function _getPersonalAirdropAmount(address _address) internal view returns (uint256) {
    (,uint256 amount) = _getPersonalAirdrop(_address);

    return amount;
  }

  /**
   * @notice Helper function that airdrops a certain amount of tokens to each user in a list
   * of approved user addresses. This MUST transfer the given amount from the caller to each user.
   * @notice MUST trigger Airdropped event
   * @param _users address[] the addresses of approved users to be airdropped
   * @param _amount uint256 the amount of tokens to airdrop to each user
   * @param _data bytes optional data to include in the Airdropped event
   */
  function _transferAirdrop(address[] _users, uint256 _amount, bytes _data) internal {

    uint256 listSize = _users.length;

    for (uint256 i = 0; i < listSize; i++) {
        airdropWithLockup(_users[i], _amount, _data);
    }
  }

  /**
   * @notice Helper function that withdraws a certain amount of tokens, this SHOULD return the given
   * amount of tokens to the user, if withdrawing is currently not possible the function MUST revert.
   * @notice MUST trigger Withdrawn event
   * @dev Withdrawing tokens is an atomic operation—either all of the tokens, or none of the tokens.
   * @param _amount uint256 the amount of tokens to withdraw
   * @param _data bytes optional data to include in the Withdrawn event
   */
  function _withdrawAirdrop(uint256 _amount, bytes _data) internal {
    Airdrop storage airdrop = approvedUsers[msg.sender].airdrop;

    // Check that the airdropped tokens are unlocked & matches the given withdraw amount
    require(
      airdrop.unlockTimestamp <= now,
      &quot;The airdrop hasn&#39;t unlocked yet&quot;);

    require(
      airdrop.amount == _amount,
      &quot;The withdrawal amount does not match the current airdrop amount&quot;);

    // Transfer the unstaked airdopped tokens from this contract back to the sender
    // Notice that we are using transfer instead of transferFrom here, so
    //  no approval is needed beforehand.
    require(
      elementToken.transfer(msg.sender, _amount),
      &quot;Unable to withdraw airdrop&quot;);

    // Reset personal airdrop amount to 0
    airdrop.amount = 0;

    // sender no longer has unstaked airdropped tokens
    approvedUsers[msg.sender].unstaked = false;

    emit Withdrawn(
      msg.sender,
      _amount,
      _data);
  }

  /**
   * @dev Helper function to return specific personal airdrop token data for an address
   * @param _address address to query
   * @return (uint256 unlockTimestamp, uint256 amount)
   */
  function _getPersonalAirdrop(
    address _address
  )
    view
    internal
    returns(uint256, uint256)
  {
    Airdrop storage airdrop = approvedUsers[_address].airdrop;

    return (
      airdrop.unlockTimestamp,
      airdrop.amount
    );
  }

    /**
   * @dev Helper function to airdrop and lockup tokens for a given address
   * @param _address The address being airdropped
   * @param _amount uint256 The number of tokens being airdropped
   * @param _data bytes The optional data emitted in the Airdropped event
   */
  function airdropWithLockup(
      address _address,
      uint256 _amount,
      bytes _data
    )
      internal
      checkAirdrop(_address)
      canAirdrop(msg.sender, _amount)
    {

    // sets the personal airdrop token data for the address recipient
    approvedUsers[_address].airdrop = Airdrop(now, now.add(lockInDuration), _amount);

    // the address recipient has now been airdropped and has unstaked airdropped tokens
    approvedUsers[_address].airdropped = true;
    approvedUsers[_address].unstaked = true;
    totalAirdropped = totalAirdropped.add(_amount);

    emit Airdropped(
      _address,
      _amount,
      _data);
  }
}

/**
 * @title ERC900 Staking Interface w/ Added Functionality
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 * Includes stakeForWithLockup for handling lockup of staking.
 * Inherits AirdropComponent for handling token airdrops to approvedUsers
 * and converting unstaked airdropped tokens into stakable and withdrawable tokens.
 */
contract StakingLockup is ERC900, AirdropComponent {

  // tracks total number of tokens that have been staked
  uint256 totalstaked;

  // To save on gas, rather than create a separate mapping for totalStakedFor & personalStakes,
  //  both data structures are stored in a single mapping for a given addresses.
  //
  // It&#39;s possible to have a non-existing personalStakes, but have tokens in totalStakedFor
  //  if other users are staking on behalf of a given address.
  mapping (address => StakeContainer) public stakeHolders;

  // Struct for personal stakes (i.e., stakes made by this address)
  // lockedTimestamp - when the stake was initially locked
  // unlockedTimestamp - when the stake unlocks (in seconds since Unix epoch)
  // amount - the amount of tokens in the stake
  // stakedFor - the address the stake was staked for
  struct Stake {
    uint256 lockedTimestamp;
    uint256 unlockedTimestamp;
    uint256 amount;
    address stakedFor;
  }

  // Struct for all stake metadata at a particular address
  // totalStakedFor - the number of tokens staked for this address
  // personalStakeIndex - the index in the personalStakes array.
  // personalStakes - append only array of stakes made by this address
  // exists - whether or not there are stakes that involve this address
  struct StakeContainer {
    uint256 totalStakedFor;
    uint256 personalStakeIndex;
    Stake[] personalStakes;
    bool exists;
  }

  /**
   * @dev Modifier that checks that this contract can transfer tokens from the
   *  balance in the elementToken contract for the given address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
  modifier canStake(address _address, uint256 _amount) {
    require(
      elementToken.transferFrom(_address, this, _amount),
      &quot;Stake required&quot;);

    _;
  }

  /**
   * @dev Modifier that checks if the staking user has enough unstaked airdropped tokens
   * available to stake for the amount given.
   * @param _address address to transfer unstaked airdropped tokens from
   * @param _amount uint256 the number of tokens to stake
   */
  modifier canStakeAirdrop(address _address, uint256 _amount) {
    require(approvedUsers[_address].airdrop.amount >= _amount,
      &quot;Insufficient airdrop token balance&quot;);

    _;
  }

  /**
   * @dev Modifier that checks if a staking user has already staked.
   * Used for ensuring a user can only stake once for themselves.
   */
  modifier checkStake() {
      require(!stakeHolders[msg.sender].exists, &quot;User already staked&quot;);
      _;
  }

  /**
   * @dev Constructor function
   * @param _elementToken ERC20 The address of the token contract used for airdropping and staking
   */
  constructor(ElementToken _elementToken) public {
    elementToken = _elementToken;
  }

  /**
   * @dev Returns the timestamps for when active personal stakes for an address will unlock
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of timestamps
   */
  function getPersonalStakeUnlockedTimestamps(address _address) external view returns (uint256[]) {
    uint256[] memory timestamps;
    (timestamps,,) = getPersonalStakes(_address);

    return timestamps;
  }

  /**
   * @dev Returns the stake amount for active personal stakes for an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of amounts
   */
  function getPersonalStakeAmounts(address _address) external view returns (uint256[]) {
    uint256[] memory amounts;
    (,amounts,) = getPersonalStakes(_address);

    return amounts;
  }

  /**
   * @dev Returns the addresses that each personal stake was created for by an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return address[] array of amounts
   */
  function getPersonalStakeForAddresses(address _address) external view returns (address[]) {
    address[] memory stakedFor;
    (,,stakedFor) = getPersonalStakes(_address);

    return stakedFor;
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stake(uint256 _amount, bytes _data) public checkStake() {
    stakeForWithLockup(
      msg.sender,
      _amount,
      _data);
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
   * @notice MUST trigger Staked event
   * @param _user address the address the tokens are staked for
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stakeFor(address _user, uint256 _amount, bytes _data) public {
    stakeForWithLockup(
      _user,
      _amount,
      _data);
  }

  /**
   * @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
   * @notice MUST trigger Unstaked event
   * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
   * @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
   *  transferred back to their account, and their personalStakeIndex will increment to the next active stake.
   * @param _amount uint256 the amount of tokens to unstake
   * @param _data bytes optional data to include in the Unstake event
   */
  function unstake(uint256 _amount, bytes _data) public {
    Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

    // Check that the current stake has unlocked & matches the unstake amount
    require(
      personalStake.unlockedTimestamp <= now,
      &quot;The current stake hasn&#39;t unlocked yet&quot;);

    require(
      personalStake.amount == _amount,
      &quot;The unstake amount does not match the current stake&quot;);

    // Transfer the staked tokens from this contract back to the sender
    // Notice that we are using transfer instead of transferFrom here, so
    //  no approval is needed beforehand.
    require(
      elementToken.transfer(msg.sender, _amount),
      &quot;Unable to withdraw stake&quot;);

    // Reducing totalStakedFor by the total amount of tokens staked
    stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor]
      .totalStakedFor.sub(personalStake.amount);

    // Reset personalStake amount to 0
    personalStake.amount = 0;
    stakeHolders[msg.sender].personalStakeIndex++;

    // Allows a user to stake again for themselves
    stakeHolders[msg.sender].exists = false;

    // Reducing totalstaked by the amount of tokens unstaked
    totalstaked = totalstaked.sub(_amount);

    emit Unstaked(
      msg.sender,
      _amount,
      totalStakedFor(msg.sender),
      _data);
  }

  /**
   * @notice Returns the current total of tokens staked for an address
   * @param _address address The address to query
   * @return uint256 The number of tokens staked for the given address
   */
  function totalStakedFor(address _address) public view returns (uint256) {
    return stakeHolders[_address].totalStakedFor;
  }

  /**
   * @notice Returns the current total of tokens staked
   * @return uint256 The number of tokens staked in the contract
   */
  function totalStaked() public view returns (uint256) {
    return totalstaked;
  }

  /**
   * @notice Address of the token being used by the interface
   * @return address The address of the ERC20 token used
   */
  function token() public view returns (address) {
    return elementToken;
  }

    /**
   * @notice MUST return true if the optional history functions are implemented, otherwise false
   * @dev Since we don&#39;t implement the optional interface, this always returns false
   * @return bool Whether or not the optional history functions are implemented
   */
  function supportsHistory() public pure returns (bool) {
    return false;
  }

  /**
   * @dev Helper function to get specific properties of all of the personal stakes created by an address
   * @param _address address The address to query
   * @return (uint256[], uint256[], address[])
   *  timestamps array, amounts array, stakedFor array
   */
  function getPersonalStakes(
    address _address
  )
    view
    public
    returns(uint256[], uint256[], address[])
  {
    StakeContainer storage stakeContainer = stakeHolders[_address];

    uint256 arraySize = stakeContainer.personalStakes.length - stakeContainer.personalStakeIndex;
    uint256[] memory unlockedTimestamps = new uint256[](arraySize);
    uint256[] memory amounts = new uint256[](arraySize);
    address[] memory stakedFor = new address[](arraySize);

    for (uint256 i = stakeContainer.personalStakeIndex; i < stakeContainer.personalStakes.length; i++) {
      uint256 index = i - stakeContainer.personalStakeIndex;
      unlockedTimestamps[index] = stakeContainer.personalStakes[i].unlockedTimestamp;
      amounts[index] = stakeContainer.personalStakes[i].amount;
      stakedFor[index] = stakeContainer.personalStakes[i].stakedFor;
    }

    return (
      unlockedTimestamps,
      amounts,
      stakedFor
    );
  }

    /**
   * @dev Helper function to create stakes and lockup for a given address
   * @param _address The address the stake is being created for
   * @param _amount uint256 The number of tokens being staked
   * @param _data bytes The optional data emitted in the Staked event
   */
  function stakeForWithLockup(
      address _address,
      uint256 _amount,
      bytes _data
    )
      internal
      canStake(msg.sender, _amount)
    {
      if(!stakeHolders[msg.sender].exists) {
          stakeHolders[msg.sender].exists = true;
      }

    // Adding to totalStakedFor by the total amount of tokens staked
    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);

    // Adding to totalstaked by the total amount of tokens staked
    totalstaked = totalstaked.add(_amount);

    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        now,
        now.add(lockInDuration),
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }

  /**
   * @dev Returns the timestamps for when active personal stakes for an address will unlock
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address of airdropped user
   * @return uint256 timestamp
   */
  function getPersonalAirdropUnlockTimestamp(address _address) external view returns (uint256) {
    return _getPersonalAirdropUnlockTimestamp(_address);
  }

  /**
   * @dev Returns the stake amount for active personal stakes for an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address of airdropped user
   * @return uint256 amount
   */
  function getPersonalAirdropAmount(address _address) external view returns (uint256) {
    return _getPersonalAirdropAmount(_address);
  }

  /**
   * @notice Airdrops a certain amount of tokens to each user in a list
   * of approved user addresses. This MUST transfer the given amount from the caller to each user.
   * @notice MUST trigger Airdropped event
   * @param _users address[] the addresses of approved users to be airdropped
   * @param _amount uint256 the amount of tokens to airdrop to each user
   * @param _data bytes optional data to include in the Airdropped event
   */
  function transferAirdrop(address[] _users, uint256 _amount, bytes _data) public {
        _transferAirdrop(_users, _amount, _data);
  }

  /**
   * @notice Withdraws a certain amount of tokens, this SHOULD return the given
   * amount of tokens to the user, if withdrawing is currently not possible the function MUST revert.
   * @notice MUST trigger Withdrawn event
   * @dev Withdrawing tokens is an atomic operation—either all of the tokens, or none of the tokens.
   * @param _amount uint256 the amount of tokens to withdraw
   * @param _data bytes optional data to include in the Withdrawn event
   */
  function withdrawAirdrop(uint256 _amount, bytes _data) public {
    _withdrawAirdrop(_amount, _data);
  }

  /**
   * @dev Returns specific personal airdrop token data for an address
   * @param _address address to query
   * @return (uint256 unlockTimestamp, uint256 amount)
   */
  function getPersonalAirdrop(
    address _address
  )
    view
    public
    returns(uint256, uint256)
  {
    return _getPersonalAirdrop(_address);
  }

  /**
   * @notice Stakes a certain amount of airdropped tokens,
   * user MUST have the given amount in their airdrop balance.
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stakeAirdrop(uint256 _amount, bytes _data) public checkStake() {
    stakeAirdropWhileLocked(
      msg.sender,
      _amount,
      _data);
  }

  /**
   * @notice Stakes a certain amount of airdropped tokens,
   * caller MUST have the given amount in their airdrop balance.
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
 function stakeForAirdrop(address _user, uint256 _amount, bytes _data) public {
    stakeAirdropWhileLocked(
      _user,
      _amount,
      _data);
  }

   /**
   * @dev Helper function to create stakes and lockup for a given address.
   * Handles conversion of internal airdrop token data to internal stakeholder data
   * @param _address The address the stake is being created for
   * @param _amount uint256 The number of tokens being staked
   * @param _data bytes The optional data emitted in the Staked event
   */
  function stakeAirdropWhileLocked(
      address _address,
      uint256 _amount,
      bytes _data
    )
      internal
      canStakeAirdrop(msg.sender, _amount)
    {
    Airdrop storage airdrop = approvedUsers[msg.sender].airdrop;

    if(!stakeHolders[msg.sender].exists) {
          stakeHolders[msg.sender].exists = true;
    }

    // Reducing personal airdrop amount by the amount of staked tokens
    airdrop.amount = airdrop.amount.sub(_amount);

    // If all airdropped tokens are gone, user has no more unstaked airdrop tokens
    if(airdrop.amount == 0) {
        approvedUsers[msg.sender].unstaked = false;
    }

    // Adding to totalStakedFor by the total amount of tokens staked
    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);

    // Adding to totalstaked by the total amount of tokens staked
    totalstaked = totalstaked.add(_amount);

    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        airdrop.airdropTimestamp,
        airdrop.unlockTimestamp,
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }
}