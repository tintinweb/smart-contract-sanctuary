/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract poolBet {
  //Add state variables
  uint counter;

  //Add mappings
  mapping(address => uint) public amount;
  mapping(address => uint[]) public poolAddressMapping;
  mapping(address => string) public userMapping;
  mapping(uint => Pool) public poolMapping;

  //Add events
  event CreateUser(address indexed user, string username);
  event CreatePool(uint indexed id, string poolName, address moderator, uint betAmount);
  event Deposit(address indexed user, string name, uint amount, uint poolId);
  event RecognizeWinner(address indexed user, address indexed winningAddress, string winner, uint poolId);
  event UndoRecognizeWinner(address indexed user, address indexed winningAddress, string winner, uint poolId);
  event AssignWinner(address indexed winningAddress, string winner, uint poolId);
  event WithdrawDeposit(address indexed user, string name, uint amount, uint poolId);
  event WithdrawWins(address indexed user, string name, uint amount, uint poolId);

  //constructor
  constructor() {
  }

  enum BetState {
    UNLOCKED,
    LOCKED,
    WINNER_PROPOSED,
    SETTLED
  }

  struct Pool {
    uint id;
    uint betAmount;
    uint totalAmount;
    bool isWinnerRecognized;
    bool isLocked;
    bool isActive;
    string name;
    address moderator;
    address winner;
    address[] depositors;
    mapping(address => bool) isApproved;
    mapping(address => bool) isDeposited;
  }

  /**
  --- Key interactions
  createPool(name, moderator, betAmount)
  createUser(username)
  addToPool payable (pool, address)
  lockPool(pool)
  unlockPool(pool)
  listAllPools()
  listUsersByPool(pool)
  recognizeWinner(address, pool)
  assignWinner(pool)
  withdrawFunds
  withdrawWins

  --- Interactions for enabling buttons in GUI
  canDeposit()
  canWithdraw()
  canLock()
  canUnlock()
  canRecognizeWinner()
  canUndoRecognizeWinner()
  canAssignWinner()
  canWithdrawWins()
  **/

  function getId() private returns(uint) {
    return ++counter; 
  }
    
  function createUser(string memory username) public virtual onlyNewUsers {
    userMapping[msg.sender] = username;
    emit CreateUser(msg.sender, username);
  }

  function createPool(string memory name, uint betAmount) public {
    uint id = getId();
    Pool storage newPool = poolMapping[id];
    newPool.id = id;
    newPool.name = name;
    newPool.moderator = msg.sender;
    newPool.betAmount = betAmount * 1e18;
    newPool.totalAmount = 0;
    newPool.isWinnerRecognized = false;
    newPool.isActive = false;
    newPool.isLocked = false;
    newPool.isApproved[msg.sender] = false;
    newPool.isDeposited[msg.sender] = false;
    poolAddressMapping[msg.sender].push(newPool.id);

    emit CreatePool(newPool.id, newPool.name, newPool.moderator, newPool.betAmount);
  }
  
  /*----------------------------------------
  -- Modifiers
  ----------------------------------------*/
  modifier onlyModerator(uint poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(msg.sender == currentPool.moderator, "Error, only the moderator can call this function");
    _;
  }

  modifier onlyNewUsers() {
    bool isUsernameAssigned = (bytes(userMapping[msg.sender]).length>0) ? true: false;
    require(!isUsernameAssigned, "The wallet already has a username registered!");
    _;
  }

  function listPoolsByUser(address user) public view returns (uint[] memory) {
    return poolAddressMapping[user];
  }

  function listUsersByPool(uint poolId) public view returns (address[] memory) {
    Pool storage currentPool = poolMapping[poolId];
    return currentPool.depositors;
  }

  function canDeposit(uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return !currentPool.isLocked && !currentPool.isDeposited[msg.sender];
  }

  function canWithdraw(uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return !currentPool.isLocked && currentPool.isDeposited[msg.sender];
  }

  function canLock(uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return msg.sender == currentPool.moderator && !currentPool.isLocked;
  }

  function canUnlock(uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return msg.sender == currentPool.moderator && currentPool.isLocked;
  }

  function canRecognizeWinner(address user, uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return !currentPool.isWinnerRecognized
    && user != address(0)
    && currentPool.winner == user
    && currentPool.isDeposited[msg.sender]
    && !currentPool.isApproved[msg.sender];
  }

  function canUndoRecognizeWinner(address user, uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return currentPool.isWinnerRecognized
    && user != address(0)
    && currentPool.winner == user
    && currentPool.isDeposited[msg.sender]
    && currentPool.isApproved[msg.sender];
  }

  function canAssignWinner(uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return msg.sender == currentPool.moderator
    && currentPool.winner == address(0)
    && !currentPool.isWinnerRecognized;
  }

  function canWithdrawWins(uint poolId) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return currentPool.isWinnerRecognized
    && !currentPool.isLocked
    && currentPool.isActive
    && msg.sender == currentPool.winner
    && currentPool.winner != address(0)
    && amount[msg.sender] > 0
    && currentPool.totalAmount > 0;
  }

  function lockPool(uint poolId) public virtual onlyModerator(poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(!currentPool.isLocked, 'Error, pool is already locked!');
    currentPool.isLocked = true;
  }

  function unlockPool(uint poolId) public virtual onlyModerator(poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(currentPool.isLocked, 'Error, pool is already unlocked!');
    currentPool.isLocked = false;
  }

  function deposit(uint poolId) payable public {
    
    Pool storage currentPool = poolMapping[poolId];

    //Check if pool is unlocked
    //Depositing only allowed when the pool is unlocked
    require(!currentPool.isLocked, 'Error, pool needs to be unlocked before depositing funds!');

    //Check to see if the winner has not already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set! Cannot deposit now!');

    //Check if msg.sender didn't already deposited funds to the pool
    //Only 1 deposit per wallet allowed
    require(currentPool.isDeposited[msg.sender] == false, 'Error, deposit already found for the current user! Cannot deposit again!');

    //Check if msg.value is == betAmount
    require(msg.value == currentPool.betAmount, 'Error, deposit must be equal to betAmount!');

    currentPool.depositors.push(msg.sender);
    currentPool.isDeposited[msg.sender] = true;
    currentPool.totalAmount = currentPool.totalAmount + msg.value;

    amount[msg.sender] = amount[msg.sender] + msg.value;

    bool poolIdExists = false;
    for(uint i; i< poolAddressMapping[msg.sender].length; i++) {
      if(poolAddressMapping[msg.sender][i] == poolId) {
        poolIdExists = true;
      }
    }

    if(!poolIdExists) {
      poolAddressMapping[msg.sender].push(poolId);
    }

    if(currentPool.isActive || currentPool.totalAmount > 0) {
      currentPool.isActive = true;
    }

    emit Deposit(msg.sender, userMapping[msg.sender], msg.value, poolId);
  }

  function recognizeWinner(address user, uint poolId) public {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the msg.sender is a depositor in the pool.
    require(currentPool.isDeposited[msg.sender], 'Error, you need to be a depositor in this pool to recognize a winner!');

    //Check that the address is not the default address but a real addreses
    require(currentPool.winner != address(0), 'Error, the winner is currently address zero and therefore invalid!');

    //Check that the address sent in the request is the same as the one assigned in the pool by the moderator
    require(currentPool.winner == user, 'Error, the winner requested to be recognized does not match the winner assigned by the moderator!');

    //Check to see if the depositor has already recognized the winner previously
    require(!currentPool.isApproved[msg.sender], 'Error, the winner has already been recognized by you!');

    //Check to see if the winner has already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set!');

    currentPool.isApproved[msg.sender] = true; 

    if(isWinnerRecognizedByAll(poolId)) {
      currentPool.isWinnerRecognized = true;
    }

    emit RecognizeWinner(msg.sender, user, userMapping[user], poolId);
  }

  function undoRecognizeWinner(address user, uint poolId) public {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the msg.sender is a depositor in the pool.
    require(currentPool.isDeposited[msg.sender], 'Error, you need to be a depositor in this pool to undo recognizing a winner!');

    //Check that the address is not the default address but a real addreses
    require(currentPool.winner != address(0), 'Error, the winner is currently address zero and therefore invalid!');

    //Check that the address sent in the request is the same as the one assigned in the pool by the moderator
    require(currentPool.winner == user, 'Error, the winner requested to be recognized does not match the winner assigned by the moderator!');

    currentPool.isApproved[msg.sender] = true;

    emit UndoRecognizeWinner(msg.sender, user, userMapping[user], poolId);
  }

  function assignWinner(address user, uint poolId) public virtual onlyModerator(poolId) {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the address is not the default address but a real addreses
    require(currentPool.winner == address(0), 'Error, the winner is currently address zero and therefore invalid!');

    //Check to see if the winner has not already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set!');

    //Check to see if the winner is a depositor in the pool.
    require(currentPool.isDeposited[user], 'Error, The winner must be a depositor in the bet pool!');

    currentPool.winner = user;

    emit AssignWinner(user, userMapping[user], poolId);
  }

  //Check if all depositors have recognized the winner here for the pool.
  function isWinnerRecognizedByAll(uint poolId) private view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    for (uint i; i< currentPool.depositors.length; i++) {
      if (!currentPool.isApproved[currentPool.depositors[i]]) {
        return false;
      }
    }
    return true;
  }

  function withdrawDeposit(uint poolId) public virtual  {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the pool must be active and unlocked for a withdraw of deposit to be successful
    require(!currentPool.isLocked && currentPool.isActive, 'Error, pool is either unlocked or inactive! Cannot withdraw now!');

    //Check to see if the winner has not already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set! Cannot withdraw now!');

    //User must have had a deposit in the pool to withdraw
    require(currentPool.isDeposited[msg.sender] = true, 'Error, only depositors can withdraw their deposited funds!');

    //User must have had an amount in the amount mapping
    require(amount[msg.sender] > 0 wei);

    payable(msg.sender).transfer(currentPool.betAmount);
    currentPool.totalAmount = currentPool.totalAmount - currentPool.betAmount;

    //Iterate and remove depositor from depositors list in pool
    for (uint i; i< currentPool.depositors.length; i++) {
      if (currentPool.depositors[i] == msg.sender) {
        currentPool.depositors[i] = currentPool.depositors[currentPool.depositors.length - 1];
        currentPool.depositors.pop();
      }
    }

    currentPool.isDeposited[msg.sender] = false;

    //Check if user has funds and remove funds from user amount mapping
    if(amount[msg.sender] > 0 wei) {
      amount[msg.sender] = amount[msg.sender] - currentPool.betAmount;
    }

    if(currentPool.totalAmount <= 0) {
      currentPool.isActive = false;
    }

    emit WithdrawDeposit(msg.sender, userMapping[msg.sender], currentPool.betAmount, poolId);
  }

  function withdrawWins(uint poolId) public {
    Pool storage currentPool = poolMapping[poolId];
    //Check that the pool must be active and unlocked for a withdraw of deposit to be successful
    require(!currentPool.isLocked && currentPool.isActive, 'Error, pool is either unlocked or inactive! Cannot withdraw now!');
    
    //Check that the msg.sender is the winner. The check that the winner is a depositor is done in assignWinner
    require(msg.sender == currentPool.winner, 'Error, only the winner can withdraw funds!');

    //Check that the winner is recognized by all bet pool participants
    require(currentPool.isWinnerRecognized, 'Error, The winner must be recognized by all bet pool particiapants!');

    //Should it be greater than 0 or greater than 0 wei?
    require(amount[msg.sender] > 0 && currentPool.totalAmount > 0, 'Error, No wins to withdraw!');

    payable(msg.sender).transfer(currentPool.totalAmount);
    currentPool.totalAmount = 0;

    address depositorAddress;
    //Remove amount for each depositor from amount mapping
    //Remove isDeposited for each user for pool
    for(uint i; i< currentPool.depositors.length; i++) {
      depositorAddress = currentPool.depositors[i];
      amount[depositorAddress] =  amount[depositorAddress] - currentPool.betAmount;
      currentPool.isDeposited[depositorAddress] = false;
    }

    //Deactivate pool
    currentPool.isActive = false;

    emit WithdrawWins(msg.sender, userMapping[msg.sender], currentPool.totalAmount, poolId);
  }
}