pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/grapevine/crowdsale/TokenTimelockController.sol

/**
 * @title TokenTimelock Controller
 * @dev This contract allows to create/read/revoke TokenTimelock contracts and to claim the amounts vested.
 **/
contract TokenTimelockController is Ownable {
  using SafeMath for uint;

  struct TokenTimelock {
    uint256 amount;
    uint256 releaseTime;
    bool released;
    bool revocable;
    bool revoked;
  }

  event TokenTimelockCreated(
    address indexed beneficiary, 
    uint256 releaseTime, 
    bool revocable, 
    uint256 amount
  );

  event TokenTimelockRevoked(
    address indexed beneficiary
  );

  event TokenTimelockBeneficiaryChanged(
    address indexed previousBeneficiary, 
    address indexed newBeneficiary
  );
  
  event TokenTimelockReleased(
    address indexed beneficiary,
    uint256 amount
  );

  uint256 public constant TEAM_LOCK_DURATION_PART1 = 1 * 365 days;
  uint256 public constant TEAM_LOCK_DURATION_PART2 = 2 * 365 days;
  uint256 public constant INVESTOR_LOCK_DURATION = 6 * 30 days;

  mapping (address => TokenTimelock[]) tokenTimeLocks;
  
  ERC20 public token;
  address public crowdsale;
  bool public activated;

  /// @notice Constructor for TokenTimelock Controller
  constructor(ERC20 _token) public {
    token = _token;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }
  
  modifier onlyWhenActivated() {
    require(activated);
    _;
  }

  modifier onlyValidTokenTimelock(address _beneficiary, uint256 _id) {
    require(_beneficiary != address(0));
    require(_id < tokenTimeLocks[_beneficiary].length);
    require(!tokenTimeLocks[_beneficiary][_id].revoked);
    _;
  }

  /**
   * @dev Function to set the crowdsale address
   * @param _crowdsale address The address of the crowdsale.
   */
  function setCrowdsale(address _crowdsale) external onlyOwner {
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

  /**
   * @dev Function to activate the controller.
   * It can be called only by the crowdsale address.
   */
  function activate() external onlyCrowdsale {
    activated = true;
  }

  /**
   * @dev Creates a lock for the provided _beneficiary with the provided amount
   * The creation can be peformed only if:
   * - the sender is the address of the crowdsale;
   * - the _beneficiary and _tokenHolder are valid addresses;
   * - the _amount is greater than 0 and was appoved by the _tokenHolder prior to the transaction.
   * The investors will have a lock with a lock period of 6 months.
   * @param _beneficiary Address that will own the lock.
   * @param _amount the amount of the locked tokens.
   * @param _start when the lock should start.
   * @param _tokenHolder the account that approved the amount for this contract.
   */
  function createInvestorTokenTimeLock(
    address _beneficiary,
    uint256 _amount, 
    uint256 _start,
    address _tokenHolder
  ) external onlyCrowdsale returns (bool)
    {
    require(_beneficiary != address(0) && _amount > 0);
    require(_tokenHolder != address(0));

    TokenTimelock memory tokenLock = TokenTimelock(
      _amount,
      _start.add(INVESTOR_LOCK_DURATION),
      false,
      false,
      false
    );
    tokenTimeLocks[_beneficiary].push(tokenLock);
    require(token.transferFrom(_tokenHolder, this, _amount));
    
    emit TokenTimelockCreated(
      _beneficiary,
      tokenLock.releaseTime,
      false,
      _amount);
    return true;
  }

  /**
   * @dev Creates locks for the provided _beneficiary with the provided amount
   * The creation can be peformed only if:
   * - the sender is the owner of the contract;
   * - the _beneficiary and _tokenHolder are valid addresses;
   * - the _amount is greater than 0 and was appoved by the _tokenHolder prior to the transaction.
   * The team members will have two locks with 1 and 2 years lock period, each having half of the amount.
   * @param _beneficiary Address that will own the lock.
   * @param _amount the amount of the locked tokens.
   * @param _start when the lock should start.
   * @param _tokenHolder the account that approved the amount for this contract.
   */
  function createTeamTokenTimeLock(
    address _beneficiary,
    uint256 _amount, 
    uint256 _start,
    address _tokenHolder
  ) external onlyOwner returns (bool)
    {
    require(_beneficiary != address(0) && _amount > 0);
    require(_tokenHolder != address(0));

    uint256 amount = _amount.div(2);
    TokenTimelock memory tokenLock1 = TokenTimelock(
      amount,
      _start.add(TEAM_LOCK_DURATION_PART1),
      false,
      true,
      false
    );
    tokenTimeLocks[_beneficiary].push(tokenLock1);

    TokenTimelock memory tokenLock2 = TokenTimelock(
      amount,
      _start.add(TEAM_LOCK_DURATION_PART2),
      false,
      true,
      false
    );
    tokenTimeLocks[_beneficiary].push(tokenLock2);

    require(token.transferFrom(_tokenHolder, this, _amount));
    
    emit TokenTimelockCreated(
      _beneficiary,
      tokenLock1.releaseTime,
      true,
      amount);
    emit TokenTimelockCreated(
      _beneficiary,
      tokenLock2.releaseTime,
      true,
      amount);
    return true;
  }

  /**
   * @dev Revokes the lock for the provided _beneficiary and _id.
   * The revoke can be peformed only if:
   * - the sender is the owner of the contract;
   * - the controller was activated by the crowdsale contract;
   * - the _beneficiary and _id reference a valid lock;
   * - the lock was not revoked;
   * - the lock is revokable;
   * - the lock was not released.
   * @param _beneficiary Address owning the lock.
   * @param _id id of the lock.
   */
  function revokeTokenTimelock(
    address _beneficiary,
    uint256 _id) 
    external onlyWhenActivated onlyOwner onlyValidTokenTimelock(_beneficiary, _id)
  {
    require(tokenTimeLocks[_beneficiary][_id].revocable);
    require(!tokenTimeLocks[_beneficiary][_id].released);
    TokenTimelock storage tokenLock = tokenTimeLocks[_beneficiary][_id];
    tokenLock.revoked = true;
    require(token.transfer(owner, tokenLock.amount));
    emit TokenTimelockRevoked(_beneficiary);
  }

  /**
   * @dev Returns the number locks of the provided _beneficiary.
   * @param _beneficiary Address owning the locks.
   */
  function getTokenTimelockCount(address _beneficiary) view external returns (uint) {
    return tokenTimeLocks[_beneficiary].length;
  }

  /**
   * @dev Returns the details of the lock referenced by the provided _beneficiary and _id.
   * @param _beneficiary Address owning the lock.
   * @param _id id of the lock.
   */
  function getTokenTimelockDetails(address _beneficiary, uint256 _id) view external returns (
    uint256 _amount,
    uint256 _releaseTime,
    bool _released,
    bool _revocable,
    bool _revoked) 
    {
    require(_id < tokenTimeLocks[_beneficiary].length);
    _amount = tokenTimeLocks[_beneficiary][_id].amount;
    _releaseTime = tokenTimeLocks[_beneficiary][_id].releaseTime;
    _released = tokenTimeLocks[_beneficiary][_id].released;
    _revocable = tokenTimeLocks[_beneficiary][_id].revocable;
    _revoked = tokenTimeLocks[_beneficiary][_id].revoked;
  }

  /**
   * @dev Changes the beneficiary of the _id&#39;th lock of the sender with the provided newBeneficiary.
   * The release can be peformed only if:
   * - the controller was activated by the crowdsale contract;
   * - the sender and _id reference a valid lock;
   * - the lock was not revoked;
   * @param _id id of the lock.
   * @param _newBeneficiary Address of the new beneficiary.
   */
  function changeBeneficiary(uint256 _id, address _newBeneficiary) external onlyWhenActivated onlyValidTokenTimelock(msg.sender, _id) {
    tokenTimeLocks[_newBeneficiary].push(tokenTimeLocks[msg.sender][_id]);
    if (tokenTimeLocks[msg.sender].length > 1) {
      tokenTimeLocks[msg.sender][_id] = tokenTimeLocks[msg.sender][tokenTimeLocks[msg.sender].length.sub(1)];
      delete(tokenTimeLocks[msg.sender][tokenTimeLocks[msg.sender].length.sub(1)]);
    }
    tokenTimeLocks[msg.sender].length--;
    emit TokenTimelockBeneficiaryChanged(msg.sender, _newBeneficiary);
  }

  /**
   * @dev Releases the tokens for the calling sender and _id.
   * The release can be peformed only if:
   * - the controller was activated by the crowdsale contract;
   * - the sender and _id reference a valid lock;
   * - the lock was not revoked;
   * - the lock was not released before;
   * - the lock period has passed.
   * @param _id id of the lock.
   */
  function release(uint256 _id) external {
    releaseFor(msg.sender, _id);
  }

   /**
   * @dev Releases the tokens for the provided _beneficiary and _id.
   * The release can be peformed only if:
   * - the controller was activated by the crowdsale contract;
   * - the _beneficiary and _id reference a valid lock;
   * - the lock was not revoked;
   * - the lock was not released before;
   * - the lock period has passed.
   * @param _beneficiary Address owning the lock.
   * @param _id id of the lock.
   */
  function releaseFor(address _beneficiary, uint256 _id) public onlyWhenActivated onlyValidTokenTimelock(_beneficiary, _id) {
    TokenTimelock storage tokenLock = tokenTimeLocks[_beneficiary][_id];
    require(!tokenLock.released);
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= tokenLock.releaseTime);
    tokenLock.released = true;
    require(token.transfer(_beneficiary, tokenLock.amount));
    emit TokenTimelockReleased(_beneficiary, tokenLock.amount);
  }
}