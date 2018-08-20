pragma solidity ^0.4.24;

contract VerityToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MasterDataProviderLock {
  address public owner;
  address public tokenAddress;
  bool public allFundsCanBeUnlocked = false;
  uint public lastLockingTime;

  // amount => lockedUntil
  mapping(uint => uint) public validLockingAmountToPeriod;
  mapping(address => mapping(string => uint)) lockingData;

  event Withdrawn(address indexed withdrawer, uint indexed withdrawnAmount);
  event FundsLocked(
    address indexed user,
    uint indexed lockedAmount,
    uint indexed lockedUntil
  );
  event AllFundsCanBeUnlocked(
    uint indexed triggeredTimestamp,
    bool indexed canAllFundsBeUnlocked
  );

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyOnceLockingPeriodIsOver(address _user) {
    require(
      (now >= lockingData[_user]["lockedUntil"] || allFundsCanBeUnlocked)
    );
    _;
  }

  modifier checkValidLockingAmount(uint _funds) {
    require(validLockingAmountToPeriod[_funds] != 0);
    _;
  }

  modifier checkUsersTokenBalance(uint _fundsToTransfer) {
    require(
      _fundsToTransfer <= VerityToken(tokenAddress).balanceOf(msg.sender)
    );
    _;
  }

  modifier onlyOncePerUser(address _user) {
    require(
      lockingData[_user]["amount"] == 0 &&
        lockingData[_user]["lockedUntil"] == 0
    );
    _;
  }

  modifier checkValidLockingTime() {
    require(now <= lastLockingTime);
    _;
  }

  modifier lastLockingTimeIsInTheFuture(uint _lastLockingTime) {
    require(now < _lastLockingTime);
    _;
  }

  modifier checkLockIsNotTerminated() {
    require(allFundsCanBeUnlocked == false);
    _;
  }

  constructor(
    address _tokenAddress,
    uint _lastLockingTime,
    uint[3] _lockingAmounts,
    uint[3] _lockingPeriods
  )
    public
    lastLockingTimeIsInTheFuture(_lastLockingTime)
  {
    owner = msg.sender;
    tokenAddress = _tokenAddress;
    lastLockingTime = _lastLockingTime;

    // expects "ether" format. Number is converted to wei:  num * 10**18
    setValidLockingAmountToPeriod(_lockingAmounts, _lockingPeriods);
  }

  function lockFunds(uint _tokens)
    public
    checkValidLockingTime()
    checkLockIsNotTerminated()
    checkUsersTokenBalance(_tokens)
    checkValidLockingAmount(_tokens)
    onlyOncePerUser(msg.sender)
  {
    require(
      VerityToken(tokenAddress).transferFrom(msg.sender, address(this), _tokens)
    );

    lockingData[msg.sender]["amount"] = _tokens;
    lockingData[msg.sender]["lockedUntil"] = validLockingAmountToPeriod[_tokens];

    emit FundsLocked(
      msg.sender,
      _tokens,
      validLockingAmountToPeriod[_tokens]
    );
  }

  function withdrawFunds()
    public
    onlyOnceLockingPeriodIsOver(msg.sender)
  {
    uint amountToBeTransferred = lockingData[msg.sender]["amount"];
    lockingData[msg.sender]["amount"] = 0;
    VerityToken(tokenAddress).transfer(msg.sender, amountToBeTransferred);

    emit Withdrawn(
      msg.sender,
      amountToBeTransferred
    );
  }

  function terminateTokenLock() public onlyOwner() {
    allFundsCanBeUnlocked = true;

    emit AllFundsCanBeUnlocked(
      now,
      allFundsCanBeUnlocked
    );
  }

  function getUserData(address _user) public view returns (uint[2]) {
    return [lockingData[_user]["amount"], lockingData[_user]["lockedUntil"]];
  }

  function setValidLockingAmountToPeriod(
    uint[3] _lockingAmounts,
    uint[3] _lockingPeriods
  )
  private
  {
    validLockingAmountToPeriod[_lockingAmounts[0] * 10 ** 18] = _lockingPeriods[0];
    validLockingAmountToPeriod[_lockingAmounts[1] * 10 ** 18] = _lockingPeriods[1];
    validLockingAmountToPeriod[_lockingAmounts[2] * 10 ** 18] = _lockingPeriods[2];
  }
}