pragma solidity ^0.4.24;

contract Ownable {
  address private _owner;

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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



contract MidnightRun is Ownable {
  using SafeMath
  for uint;

  modifier isHuman() {
    uint32 size;
    address investor = msg.sender;
    assembly {
      size: = extcodesize(investor)
    }
    if (size > 0) {
      revert("Inhuman");
    }
    _;
  }

  event DailyDividendPayout(address indexed _address, uint value, uint periodCount, uint percent, uint time);
  event ReferralPayout(address indexed _addressFrom, address indexed _addressTo, uint value, uint percent, uint time);
  event MidnightRunPayout(address indexed _address, uint value, uint totalValue, uint userValue, uint time);

  uint public period = 24 hours;
  uint public startTime = 1538089200; //  TH, 27 Sep 2018 23:00:00 +0000 UTC

  uint public dailyDividendPercent = 3000; //30%
  uint public referredDividendPercent = 3300; //33%

  uint public referrerPercent = 250; //2.5%
  uint public minBetLevel = 0.01 ether;

  uint public referrerAndOwnerPercent = 2000; //20%
  uint public currentStakeID = 1;

  struct DepositInfo {
    uint value;
    uint firstBetTime;
    uint lastBetTime;
    uint lastPaymentTime;
    uint nextPayAfterTime;
    bool isExist;
    uint id;
    uint referrerID;
  }

  mapping(address => DepositInfo) public investorToDepostIndex;
  mapping(uint => address) public idToAddressIndex;

  // Jackpot
  uint public midnightPrizePercent = 1000; //10%
  uint public midnightPrize = 0;
  uint public nextPrizeTime = startTime + period;

  uint public currentPrizeStakeID = 0;

  struct MidnightRunDeposit {
    uint value;
    address user;
  }
  mapping(uint => MidnightRunDeposit) public stakeIDToDepositIndex;

 /**
  * Constructor no need for unnecessary work in here.
  */
  constructor() public {
  }

  /**
   * Fallback and entrypoint for deposits.
   */
  function() public payable isHuman {
    if (msg.value == 0) {
      collectPayoutForAddress(msg.sender);
    } else {
      uint refId = 1;
      address referrer = bytesToAddress(msg.data);
      if (investorToDepostIndex[referrer].isExist) {
        refId = investorToDepostIndex[referrer].id;
      }
      deposit(refId);
    }
  }

/**
 * Reads the given bytes into an addtress
 */
  function bytesToAddress(bytes bys) private pure returns(address addr) {
    assembly {
      addr: = mload(add(bys, 20))
    }
  }

/**
 * Put some funds into the contract for the prize
 */
  function addToMidnightPrize() public payable onlyOwner {
    midnightPrize += msg.value;
  }

/**
 * Get the time of the next payout - calculated
 */
  function getNextPayoutTime() public view returns(uint) {
    if (now<startTime) return startTime + period;
    return startTime + ((now.sub(startTime)).div(period)).mul(period) + period;
  }

/**
 * Make a deposit into the contract
 */
  function deposit(uint _referrerID) public payable isHuman {
    require(_referrerID <= currentStakeID, "Who referred you?");
    require(msg.value >= minBetLevel, "Doesn&#39;t meet minimum stake.");

    // when is next midnight ?
    uint nextPayAfterTime = getNextPayoutTime();

    if (investorToDepostIndex[msg.sender].isExist) {
      if (investorToDepostIndex[msg.sender].nextPayAfterTime < now) {
        collectPayoutForAddress(msg.sender);
      }
      investorToDepostIndex[msg.sender].value += msg.value;
      investorToDepostIndex[msg.sender].lastBetTime = now;
    } else {
      DepositInfo memory newDeposit;

      newDeposit = DepositInfo({
        value: msg.value,
        firstBetTime: now,
        lastBetTime: now,
        lastPaymentTime: 0,
        nextPayAfterTime: nextPayAfterTime,
        isExist: true,
        id: currentStakeID,
        referrerID: _referrerID
      });

      investorToDepostIndex[msg.sender] = newDeposit;
      idToAddressIndex[currentStakeID] = msg.sender;

      currentStakeID++;
    }

    if (now > nextPrizeTime) {
      doMidnightRun();
    }

    currentPrizeStakeID++;

    MidnightRunDeposit memory midnitrunDeposit;
    midnitrunDeposit.user = msg.sender;
    midnitrunDeposit.value = msg.value;

    stakeIDToDepositIndex[currentPrizeStakeID] = midnitrunDeposit;

    // contribute to the Midnight Run Prize
    midnightPrize += msg.value.mul(midnightPrizePercent).div(10000);
    // Is there a referrer to be paid?
    if (investorToDepostIndex[msg.sender].referrerID != 0) {

      uint refToPay = msg.value.mul(referrerPercent).div(10000);
      // Referral Fee
      idToAddressIndex[investorToDepostIndex[msg.sender].referrerID].transfer(refToPay);
      // Team and advertising fee
      owner().transfer(msg.value.mul(referrerAndOwnerPercent - referrerPercent).div(10000));
      emit ReferralPayout(msg.sender, idToAddressIndex[investorToDepostIndex[msg.sender].referrerID], refToPay, referrerPercent, now);
    } else {
      // Team and advertising fee
      owner().transfer(msg.value.mul(referrerAndOwnerPercent).div(10000));
    }
  }



/**
 * Collect payout for the msg.sender
 */
  function collectPayout() public isHuman {
    collectPayoutForAddress(msg.sender);
  }

/**
 * Collect payout for the given address
 */
  function getRewardForAddress(address _address) public onlyOwner {
    collectPayoutForAddress(_address);
  }

/**
 *
 */
  function collectPayoutForAddress(address _address) internal {
    require(investorToDepostIndex[_address].isExist == true, "Who are you?");
    require(investorToDepostIndex[_address].nextPayAfterTime < now, "Not yet.");

    uint periodCount = now.sub(investorToDepostIndex[_address].nextPayAfterTime).div(period).add(1);
    uint percent = dailyDividendPercent;

    if (investorToDepostIndex[_address].referrerID > 0) {
      percent = referredDividendPercent;
    }

    uint toPay = periodCount.mul(investorToDepostIndex[_address].value).div(10000).mul(percent);

    investorToDepostIndex[_address].lastPaymentTime = now;
    investorToDepostIndex[_address].nextPayAfterTime += periodCount.mul(period);

    // protect contract - this could result in some bad luck - but not much
    if (toPay.add(midnightPrize) < address(this).balance.sub(msg.value))
    {
      _address.transfer(toPay);
      emit DailyDividendPayout(_address, toPay, periodCount, percent, now);
    }
  }

/**
 * Perform the Midnight Run
 */
  function doMidnightRun() public isHuman {
    require(now>nextPrizeTime , "Not yet");

    // set the next prize time to the next payout time (MidnightRun)
    nextPrizeTime = getNextPayoutTime();

    if (currentPrizeStakeID > 5) {
      uint toPay = midnightPrize;
      midnightPrize = 0;

      if (toPay > address(this).balance){
        toPay = address(this).balance;
      }

      uint totalValue = stakeIDToDepositIndex[currentPrizeStakeID].value + stakeIDToDepositIndex[currentPrizeStakeID - 1].value + stakeIDToDepositIndex[currentPrizeStakeID - 2].value + stakeIDToDepositIndex[currentPrizeStakeID - 3].value + stakeIDToDepositIndex[currentPrizeStakeID - 4].value;

      stakeIDToDepositIndex[currentPrizeStakeID].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 1].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 1].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 1].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 1].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 1].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 2].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 2].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 2].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 2].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 2].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 3].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 3].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 3].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 3].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 3].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 4].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 4].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 4].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 4].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 4].value, now);
    }
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}