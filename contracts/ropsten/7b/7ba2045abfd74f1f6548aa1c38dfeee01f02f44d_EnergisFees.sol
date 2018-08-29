pragma solidity ^0.4.24;

// File: contracts/PeriodUtil.sol

/**
 * @title PeriodUtil
 * 
 * Interface used for Period calculation to allow better automated testing of Fees Contract
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract PeriodUtil {
    /**
    * @dev calculates the Period index for the given timestamp
    * @return Period count since EPOCH
    * @param timestamp The time in seconds since EPOCH (blocktime)
    */
    function getPeriodIdx(uint256 timestamp) public pure returns (uint256);
    
    /**
    * @dev Timestamp of the period start
    * @return Time in seconds since EPOCH of the Period Start
    * @param periodIdx Period Index to find the start timestamp of
    */
    function getPeriodStartTimestamp(uint256 periodIdx) public pure returns (uint256);

    /**
    * @dev Returns the Cycle count of the given Periods. A set of time creates a cycle, eg. If period is weeks the cycle can be years.
    * @return The Cycle Index
    * @param timestamp The time in seconds since EPOCH (blocktime)
    */
    function getPeriodCycle(uint256 timestamp) public pure returns (uint256);

    /**
    * @dev Amount of Tokens per time unit since the start of the given periodIdx
    * @return Tokens per Time Unit from the given periodIdx start till now
    * @param tokens Total amount of tokens from periodIdx start till now (blocktime)
    * @param periodIdx Period IDX to use for time start
    */
    function getRatePerTimeUnits(uint256 tokens, uint256 periodIdx) public view returns (uint256);

    /**
    * @dev Amount of time units in each Period, for exampe if units is hour and period is week it will be 168
    * @return Amount of time units per period
    */
    function getUnitsPerPeriod() public pure returns (uint256);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/EnergisFees.sol

/**
 * @title EnergisFees
 * 
 * Used to process transaction
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract EnergisFees is Ownable {

    using SafeMath for uint256;

    struct PaymentHistory {
        // If set 
        bool paid;
        // Payment to Fees
        uint256 fees;
        // Payment to Reward
        uint256 reward;
        // End of period token balance
        uint256 endBalance;
    }

    mapping (uint256 => PaymentHistory) payments;
    address public constant tokenAddress = 0xe1819b653793dDaBbFFed4AED5752fc447d4A1e9;
    PeriodUtil public constant periodUtil = PeriodUtil(0x458dD5413fE6bBb2BFf85E43947017753Cd24e39);
    // Last week that has been executed
    uint256 public lastPeriodExecIdx;
    // Last Year that has been processed
    uint256 public lastPeriodCycleExecIdx;
    // Amount of time in seconds grase processing time
    uint256 constant grasePeriod = 3600;

    // Wallet for Fees payments
    address public constant feesWallet = 0x967F4aAAa326C7e1acE0AeEE7ECd73f6580283da;
    // Wallet for Reward payments
    address public constant rewardWallet = 0x967F4aAAa326C7e1acE0AeEE7ECd73f6580283da;
    
    // Percentage amount of the weeks received tokens to go to Fees
    uint256 internal constant FEES_PER = 20;
    // Max Amount of Tokens to be payed out per week
    uint256 internal constant FEES_MAX_AMOUNT = 1200000 * (10**18);
    // Min Amount of Fees to pay out per week
    uint256 internal constant FEES_TOKEN_MIN_AMOUNT = 24000 * (10**18);
    // Min Percentage Prev Week to pay out per week
    uint256 internal constant FEES_TOKEN_MIN_PERPREV = 95;
    // Rewards Percentage of Period Received
    uint256 internal constant REWARD_PER = 70;
    
    /**
     */
    constructor () public {
        assert(grasePeriod > 0);
        // GrasePeriod must be less than period
        uint256 va1 = periodUtil.getPeriodStartTimestamp(1);
        uint256 va2 = periodUtil.getPeriodStartTimestamp(0);
        assert(grasePeriod < (va1 - va2));

        // Set the previous period values;
        lastPeriodExecIdx = getWeekIdx() - 1;
        lastPeriodCycleExecIdx = getYearIdx();
        PaymentHistory storage prevPayment = payments[lastPeriodExecIdx];
        prevPayment.fees = 0;
        prevPayment.reward = 0;
        prevPayment.paid = true;
        prevPayment.endBalance = 0;
    }

    /**
     * @dev Call when Fees processing needs to happen. Can only be called by the contract Owner
     */
    function process() public onlyOwner {
        uint256 currPeriodIdx = getWeekIdx();

        // Has the previous period been calculated?
        if (lastPeriodExecIdx == (currPeriodIdx - 1)) {
            // Nothing to do previous week has Already been processed
            return;
        }

        if ((currPeriodIdx - lastPeriodExecIdx) == 2) {
            paymentOnTime(currPeriodIdx);
            // End Of Year Payment
            if (lastPeriodCycleExecIdx < getYearIdx()) {
                processEndOfYear(currPeriodIdx - 1);
            }
        }
        else {
            uint256 availableTokens = currentBalance();
            // Missed Full Period! Very Bad!
            PaymentHistory memory lastExecPeriod = payments[lastPeriodExecIdx];
            uint256 tokensReceived = availableTokens.sub(lastExecPeriod.endBalance);
            // Average amount of tokens received per hour till now
            uint256 tokenHourlyRate = periodUtil.getRatePerTimeUnits(tokensReceived, lastPeriodExecIdx + 1);

            PaymentHistory memory prePeriod;

            for (uint256 calcPeriodIdx = lastPeriodExecIdx + 1; calcPeriodIdx < currPeriodIdx; calcPeriodIdx++) {
                prePeriod = payments[calcPeriodIdx - 1];
                uint256 periodTokenReceived = periodUtil.getUnitsPerPeriod().mul(tokenHourlyRate);
                makePayments(prePeriod, payments[calcPeriodIdx], periodTokenReceived, prePeriod.endBalance.add(periodTokenReceived), calcPeriodIdx);

                if (periodUtil.getPeriodCycle(periodUtil.getPeriodStartTimestamp(calcPeriodIdx + 1)) > lastPeriodCycleExecIdx) {
                    processEndOfYear(calcPeriodIdx);
                }
            }
        }

        assert(payments[currPeriodIdx - 1].paid);
        lastPeriodExecIdx = currPeriodIdx - 1;
    }

    /**
     * @dev Internal function to process end of year Clearance
     * @param yearEndPeriodCycle The Last Period Idx (Week Idx) of the year
     */
    function processEndOfYear(uint256 yearEndPeriodCycle) internal {
        PaymentHistory storage lastYearPeriod = payments[yearEndPeriodCycle];
        uint256 availableTokens = currentBalance();
        uint256 tokensToClear = min256(availableTokens,lastYearPeriod.endBalance);

        assert(ERC20(tokenAddress).transfer(feesWallet, tokensToClear));
        lastPeriodCycleExecIdx = lastPeriodCycleExecIdx + 1;
        lastYearPeriod.endBalance = 0;

        emit YearEndClearance(lastPeriodCycleExecIdx, tokensToClear);
    }

    /**
     * @dev Called when Payments are call within a week of last payment
     * @param currPeriodIdx Current Period Idx (Week)
     */
    function paymentOnTime(uint256 currPeriodIdx) internal {
    
        uint256 availableTokens = currentBalance();
        PaymentHistory memory prePeriod = payments[currPeriodIdx - 2];

        uint256 tokensRecvInPeriod = availableTokens.sub(prePeriod.endBalance);

        if (tokensRecvInPeriod <= 0) {
            tokensRecvInPeriod = 0;
        }
        else if ((now - periodUtil.getPeriodStartTimestamp(currPeriodIdx)) > grasePeriod) {
            tokensRecvInPeriod = periodUtil.getRatePerTimeUnits(tokensRecvInPeriod, currPeriodIdx - 1).mul(periodUtil.getUnitsPerPeriod());
            if (tokensRecvInPeriod <= 0) {
                tokensRecvInPeriod = 0;
            }
            assert(availableTokens >= tokensRecvInPeriod);
        }   

        makePayments(prePeriod, payments[currPeriodIdx - 1], tokensRecvInPeriod, prePeriod.endBalance + tokensRecvInPeriod, currPeriodIdx - 1);
    }

    /**
    * @dev Process a payment period
    * @param prevPayment Previous periods payment records
    * @param currPayment Current periods payment records to be updated
    * @param tokensRaised Tokens received for the period
    * @param availableTokens Contract available balance including the tokens received for the period
    */
    function makePayments(PaymentHistory memory prevPayment, PaymentHistory storage currPayment, uint256 tokensRaised, uint256 availableTokens, uint256 weekIdx) internal {

        assert(prevPayment.paid);
        assert(!currPayment.paid);
        assert(availableTokens >= tokensRaised);

        uint256 feesPay = tokensRaised == 0 ? 0 : tokensRaised.mul(FEES_PER).div(100);
        if (feesPay >= FEES_MAX_AMOUNT) {
            feesPay = FEES_MAX_AMOUNT;
        }
        else {
            // Calculates the Min percentage of previous month to pay
            uint256 prevFees95 = prevPayment.fees.mul(FEES_TOKEN_MIN_PERPREV).div(100);
            // Minimum amount of fees that is required
            uint256 minFeesPay = max256(FEES_TOKEN_MIN_AMOUNT, prevFees95);
            feesPay = max256(feesPay, minFeesPay);
        }

        if (feesPay > availableTokens) {
            feesPay = availableTokens;
        }

        uint256 rewardPay = 0;
        if (feesPay < tokensRaised) {
            // There is money left for reward pool
            rewardPay = tokensRaised.mul(REWARD_PER).div(100);
            // Rewards only comes for the tokens raised in the period
            rewardPay = min256(rewardPay, tokensRaised.sub(feesPay));
        }

        currPayment.fees = feesPay;
        currPayment.reward = rewardPay;

        assert(ERC20(tokenAddress).transfer(rewardWallet, rewardPay));
        assert(ERC20(tokenAddress).transfer(feesWallet, feesPay));

        currPayment.endBalance = availableTokens - feesPay - rewardPay;
        currPayment.paid = true;

        emit Payment(weekIdx, rewardPay, feesPay);
    }

    /**
    * @dev Event when payment was made
    * @param weekIdx Week Idx since EPOCH for payment
    * @param rewardPay Amount of tokens paid to the reward pool
    * @param feesPay Amount of tokens paid in fees
    */
    event Payment(uint256 weekIdx, uint256 rewardPay, uint256 feesPay);

    /**
    * @dev Event when year end clearance happens
    * @param yearIdx Year the clearance happend for
    * @param feesPay Amount of tokens paid in fees
    */
    event YearEndClearance(uint256 yearIdx, uint256 feesPay);


    /**
    * @dev Returns the token balance of the Fees contract
    */
    function currentBalance() internal view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    /**
    * @dev Returns the amount of weeks since EPOCH
    * @return Week count since EPOCH
    */
    function getWeekIdx() public view returns (uint256) {
        return periodUtil.getPeriodIdx(now);
    }

    /**
    * @dev Returns the Year
    */
    function getYearIdx() public view returns (uint256) {
        return periodUtil.getPeriodCycle(now);
    }

    /**
    * @dev Returns true if the week has been processed and paid out
    * @param weekIdx Weeks since EPOCH
    * @return true if week has been paid out
    */
    function weekProcessed(uint256 weekIdx) public view returns (bool) {
        return payments[weekIdx].paid;
    }

    /**
    * @dev Returns the amounts paid out for the given week
    * @param weekIdx Weeks since EPOCH
    */
    function paymentForWeek(uint256 weekIdx) public view returns (uint256 fees, uint256 reward) {
        PaymentHistory storage history = payments[weekIdx];
        fees = history.fees;
        reward = history.reward;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}