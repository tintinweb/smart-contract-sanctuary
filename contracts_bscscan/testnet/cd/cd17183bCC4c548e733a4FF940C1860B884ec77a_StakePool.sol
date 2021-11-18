/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: StakeContract.sol

pragma solidity ^0.4.24;


/* @title Mock Staking Contract for testing Staking Pool Contract */
contract StakeContract {
  using SafeMath for uint;

  /** @dev creates contract
    */
  constructor() public { }

  /** @dev trigger notification of withdrawal
    */
  event NotifyWithdrawalSC(
    address sender,
    uint startBal,
    uint finalBal,
    uint request
  );

  /** @dev withdrawal funds out of pool
    * @param wdValue amount to withdraw
    * not payable, not receiving funds
    */
  function withdraw(uint wdValue) public {
    uint startBalance = address(this).balance;
    uint finalBalance = address(this).balance.sub(wdValue);

    // transfer & send will hit payee fallback function if a contract
    msg.sender.transfer(wdValue);

    emit NotifyWithdrawalSC(
      msg.sender,
      startBalance,
      finalBalance,
      wdValue
    );
  }

    event FallBackSC(
      address sender,
      uint value,
      uint blockNumber
    );

  function () external payable {
    // only 2300 gas available
    // storage data costs at least 5000 for initialized values, 20k for new
    emit FallBackSC(msg.sender, msg.value, block.number);
  }
}

// File: StakePool.sol

pragma solidity 0.4.24;




/* @title Staking Pool Contract
 * Open Zeppelin Pausable is Ownable.  contains address owner */
contract StakePool is Pausable {
  using SafeMath for uint;

  /** @dev address of staking contract
    * this variable is set at construction, and can be changed only by owner.*/
  address private stakeContract;
  /** @dev staking contract object to interact with staking mechanism.
    * this is a mock contract.  */
  StakeContract private sc;

  /** @dev track total staked amount */
  uint private totalStaked;
  /** @dev track total deposited to pool */
  uint private totalDeposited;

  /** @dev track balances of ether deposited to pool */
  mapping(address => uint) private depositedBalances;
  /** @dev track balances of ether staked */
  mapping(address => uint) private stakedBalances;
  /** @dev track user request to enter next staking period */
  mapping(address => uint) private requestStake;
  /** @dev track user request to exit current staking period */
  mapping(address => uint) private requestUnStake;

  /** @dev track users
    * users must be tracked in this array because mapping is not iterable */
  address[] private users;
  /** @dev track index by address added to users */
  mapping(address => uint) private userIndex;

  /** @dev notify when funds received from staking contract
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
   */
  event NotifyFallback(address sender, uint amount);

  /** @dev notify that StakeContract address has been changed 
    * @param oldSC old address of the staking contract
    * @param newSC new address of the staking contract
   */
  event NotifyNewSC(address oldSC, address newSC);

  /** @dev trigger notification of deposits
    * @param sender  msg.sender for the transaction
    * @param amount  msg.value for the transaction
    * @param balance the users balance including this deposit
   */
  event NotifyDeposit(address sender, uint amount, uint balance);

  /** @dev trigger notification of staked amount
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
    */
  event NotifyStaked(address sender, uint amount);

  /** @dev trigger notification of change in users staked balances
    * @param user            address of user
    * @param previousBalance users previous staked balance
    * @param newStakeBalence users new staked balance
    */
  event NotifyUpdate(address user, uint previousBalance, uint newStakeBalence);

  /** @dev trigger notification of withdrawal
    * @param sender   address of msg.sender
    * @param startBal users starting balance
    * @param finalBal users final balance after withdrawal
    * @param request  users requested withdraw amount
    */
  event NotifyWithdrawal(
    address sender,
    uint startBal,
    uint finalBal,
    uint request);

  /** @dev trigger notification of earnings to be split
    * @param earnings uint staking earnings for pool
    */
   event NotifyEarnings(uint earnings);


  /** @dev contract constructor
    * @param _stakeContract the address of the staking contract/mechanism
    */
  constructor(address _stakeContract) public {
    require(_stakeContract != address(0));
    stakeContract = _stakeContract;
    sc = StakeContract(stakeContract);
    // set owner to users[0] because unknown user will return 0 from userIndex
    // this also allows owners to withdraw their own earnings using same
    // functions as regular users
    users.push(owner);
  }

  /** @dev payable fallback
    * it is assumed that only funds received will be from stakeContract */
  function () external payable {
    emit NotifyFallback(msg.sender, msg.value);
  }

  /************************ USER MANAGEMENT **********************************/

  /** @dev test if user is in current user list
    * @param _user address of user to test if in list
    * @return true if user is on record, otherwise false
    */
  function isExistingUser(address _user) internal view returns (bool) {
    if ( userIndex[_user] == 0) {
      return false;
    }
    return true;
  }

  /** @dev remove a user from users array
    * @param _user address of user to remove from the list
    */
  function removeUser(address _user) internal {
    if (_user == owner ) return;
    uint index = userIndex[_user];
    // user is not last user
    if (index < users.length.sub(1)) {
      address lastUser = users[users.length.sub(1)];
      users[index] = lastUser;
      userIndex[lastUser] = index;
    }
    // this line removes last user
    users.length = users.length.sub(1);
  }

  /** @dev add a user to users array
    * @param _user address of user to add to the list
    */
  function addUser(address _user) internal {
    if (_user == owner ) return;
    if (isExistingUser(_user)) return;
    users.push(_user);
    // new user is currently last in users array
    userIndex[_user] = users.length.sub(1);
  }

  /************************ USER MANAGEMENT **********************************/

  /** @dev set staking contract address
    * @param _stakeContract new address to change staking contract / mechanism
    */
  function setStakeContract(address _stakeContract) external onlyOwner {
    require(_stakeContract != address(0));
    address oldSC = stakeContract;
    stakeContract = _stakeContract;
    sc = StakeContract(stakeContract);
    emit NotifyNewSC(oldSC, stakeContract);
  }

  /** @dev stake funds to stakeContract
    */
  function stake() external onlyOwner {
    // * update mappings
    // * send total balance to stakeContract
    uint toStake;
    for (uint i = 0; i < users.length; i++) {
      uint amount = requestStake[users[i]];
      toStake = toStake.add(amount);
      stakedBalances[users[i]] = stakedBalances[users[i]].add(amount);
      requestStake[users[i]] = 0;
    }

    // track total staked
    totalStaked = totalStaked.add(toStake);

    address(sc).transfer(toStake);

    emit NotifyStaked(msg.sender, toStake);
  }

  /** @dev unstake funds from stakeContract
    */
  function unstake() external onlyOwner {
    uint unStake;
    for (uint i = 0; i < users.length; i++) {
      uint amount = requestUnStake[users[i]];
      unStake = unStake.add(amount);
      stakedBalances[users[i]] = stakedBalances[users[i]].sub(amount);
      depositedBalances[users[i]] = depositedBalances[users[i]].add(amount);
      requestUnStake[users[i]] = 0;
    }

    // track total staked
    totalStaked = totalStaked.sub(unStake);

    sc.withdraw(unStake);

    emit NotifyStaked(msg.sender, -unStake);
  }

  /** @dev calculated new stakedBalances
    * @return true if calc is successful, otherwise false
    */
  function calcNewBalances() external onlyOwner {
    uint earnings = address(sc).balance.sub(totalStaked);
    emit NotifyEarnings(earnings);
    uint ownerProfit = earnings.div(100);
    earnings = earnings.sub(ownerProfit);

    if (totalStaked > 0 && earnings > 0) {
      for (uint i = 0; i < users.length; i++) {
        uint currentBalance = stakedBalances[users[i]];
        stakedBalances[users[i]] =
          currentBalance.add(
            earnings.mul(currentBalance).div(totalStaked)
          );
        emit NotifyUpdate(users[i], currentBalance, stakedBalances[users[i]]);
      }
      uint ownerBalancePrior = stakedBalances[owner];
      stakedBalances[owner] = stakedBalances[owner].add(ownerProfit);
      emit NotifyUpdate(owner, ownerBalancePrior, stakedBalances[owner]);
      totalStaked = address(sc).balance;
    }
  }

  /** @dev deposit funds to the contract
    */
  function deposit() external payable whenNotPaused {
    depositedBalances[msg.sender] = depositedBalances[msg.sender].add(msg.value);
    emit NotifyDeposit(msg.sender, msg.value, depositedBalances[msg.sender]);
  }

  /** @dev withdrawal funds out of pool
    * @param wdValue amount to withdraw
    */
  function withdraw(uint wdValue) external whenNotPaused {
    require(wdValue > 0);
    require(depositedBalances[msg.sender] >= wdValue);
    uint startBalance = depositedBalances[msg.sender];
    depositedBalances[msg.sender] = depositedBalances[msg.sender].sub(wdValue);
    checkIfUserIsLeaving(msg.sender);

    msg.sender.transfer(wdValue);

    emit NotifyWithdrawal(
      msg.sender,
      startBalance,
      depositedBalances[msg.sender],
      wdValue
    );
  }

  /** @dev if user has no deposit and no staked funds they are leaving the 
    * pool.  Remove them from user list.
    * @param _user address of user to check
    */
  function checkIfUserIsLeaving(address _user) internal {
    if (depositedBalances[_user] == 0 && stakedBalances[_user] == 0) {
      removeUser(_user);
    }
  }

  /** @dev user can request to enter next staking period */
  function requestNextStakingPeriod() external whenNotPaused {
    require(depositedBalances[msg.sender] > 0);

    addUser(msg.sender);
    uint amount = depositedBalances[msg.sender];
    depositedBalances[msg.sender] = 0;
    requestStake[msg.sender] = requestStake[msg.sender].add(amount);
    emit NotifyStaked(msg.sender, requestStake[msg.sender]);
  }

  /** @dev user can request to exit at end of current staking period
    * @param amount requested amount to withdraw from staking contract
   */
  function requestExitAtEndOfCurrentStakingPeriod(uint amount) external whenNotPaused {
    require(stakedBalances[msg.sender] >= amount);
    requestUnStake[msg.sender] = requestUnStake[msg.sender].add(amount);
    emit NotifyStaked(msg.sender, requestUnStake[msg.sender]);
  }

  /** @dev retreive current state of users funds
    * @return array of values describing the current state of user
   */
  function getState() external view returns (uint[]) {
    uint[] memory state = new uint[](4);
    state[0] = depositedBalances[msg.sender];
    state[1] = requestStake[msg.sender];
    state[2] = requestUnStake[msg.sender];
    state[3] = stakedBalances[msg.sender];
    return state;
  }
}