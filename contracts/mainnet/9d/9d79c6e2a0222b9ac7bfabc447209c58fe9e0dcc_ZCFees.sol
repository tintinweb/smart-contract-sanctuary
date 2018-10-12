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

// File: contracts/ERC20Burnable.sol

/**
 * @title BurnableToken
 * 
 * Interface for Basic ERC20 interactions and allowing burning  of tokens
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract ERC20Burnable is ERC20Basic {

    function burn(uint256 _value) public;
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

// File: contracts/ZCFees.sol

/**
 * @title ZCFees
 * 
 * Used to process transaction
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract ZCFees {

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

    uint256 public totalRewards;
    uint256 public totalFees;

    mapping (uint256 => PaymentHistory) payments;
    address public tokenAddress;
    PeriodUtil public periodUtil;
    // Last week that has been executed
    uint256 public lastPeriodExecIdx;
    // Last Year that has been processed
    uint256 public lastPeriodCycleExecIdx;
    // Amount of time in seconds grase processing time
    uint256 grasePeriod;

    // Wallet for Fees payments
    address public feesWallet;
    // Wallet for Reward payments
    address public rewardWallet;
    
    // Fees 1 : % tokens taken per week
    uint256 internal constant FEES1_PER = 10;
    // Fees 1 : Max token payout per week
    uint256 internal constant FEES1_MAX_AMOUNT = 400000 * (10**18);
    // Fees 2 : % tokens taken per week
    uint256 internal constant FEES2_PER = 10;
    // Fees 2 : Max token payout per week
    uint256 internal constant FEES2_MAX_AMOUNT = 800000 * (10**18);
    // Min Amount of Fees to pay out per week
    uint256 internal constant FEES_TOKEN_MIN_AMOUNT = 24000 * (10**18);
    // Min Percentage Prev Week to pay out per week
    uint256 internal constant FEES_TOKEN_MIN_PERPREV = 95;
    // Rewards Percentage of Period Received
    uint256 internal constant REWARD_PER = 70;
    // % Amount of remaining tokens to burn at end of year
    uint256 internal constant BURN_PER = 25;
    
    /**
     * @param _tokenAdr The Address of the Token
     * @param _periodUtilAdr The Address of the PeriodUtil
     * @param _grasePeriod The time in seconds you allowed to process payments before avg is calculated into next period(s)
     * @param _feesWallet Where the fees are sent in tokens
     * @param _rewardWallet Where the rewards are sent in tokens
     */
    constructor (address _tokenAdr, address _periodUtilAdr, uint256 _grasePeriod, address _feesWallet, address _rewardWallet) public {
        assert(_tokenAdr != address(0));
        assert(_feesWallet != address(0));
        assert(_rewardWallet != address(0));
        assert(_periodUtilAdr != address(0));
        tokenAddress = _tokenAdr;
        feesWallet = _feesWallet;
        rewardWallet = _rewardWallet;
        periodUtil = PeriodUtil(_periodUtilAdr);

        grasePeriod = _grasePeriod;
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
    function process() public {
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

        // Burn some of tokens
        uint256 tokensToBurn = tokensToClear.mul(BURN_PER).div(100);
        ERC20Burnable(tokenAddress).burn(tokensToBurn);

        uint256 tokensToFeesWallet = tokensToClear.sub(tokensToBurn);
        totalFees = totalFees.add(tokensToFeesWallet);
        assert(ERC20Burnable(tokenAddress).transfer(feesWallet, tokensToFeesWallet));
        lastPeriodCycleExecIdx = lastPeriodCycleExecIdx + 1;
        lastYearPeriod.endBalance = 0;

        emit YearEndClearance(lastPeriodCycleExecIdx, tokensToFeesWallet, tokensToBurn);
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

        // Fees 1 Payment
        uint256 fees1Pay = tokensRaised == 0 ? 0 : tokensRaised.mul(FEES1_PER).div(100);
        if (fees1Pay >= FEES1_MAX_AMOUNT) {
            fees1Pay = FEES1_MAX_AMOUNT;
        }
        // Fees 2 Payment
        uint256 fees2Pay = tokensRaised == 0 ? 0 : tokensRaised.mul(FEES2_PER).div(100);
        if (fees2Pay >= FEES2_MAX_AMOUNT) {
            fees2Pay = FEES2_MAX_AMOUNT;
        }

        uint256 feesPay = fees1Pay.add(fees2Pay);
        if (feesPay >= availableTokens) {
            feesPay = availableTokens;
        } else {
            // Calculates the Min percentage of previous month to pay
            uint256 prevFees95 = prevPayment.fees.mul(FEES_TOKEN_MIN_PERPREV).div(100);
            // Minimum amount of fees that is required
            uint256 minFeesPay = max256(FEES_TOKEN_MIN_AMOUNT, prevFees95);
            feesPay = max256(feesPay, minFeesPay);
            feesPay = min256(feesPay, availableTokens);
        }

        // Rewards Payout
        uint256 rewardPay = 0;
        if (feesPay < tokensRaised) {
            // There is money left for reward pool
            rewardPay = tokensRaised.mul(REWARD_PER).div(100);
            rewardPay = min256(rewardPay, availableTokens.sub(feesPay));
        }

        currPayment.fees = feesPay;
        currPayment.reward = rewardPay;

        totalFees = totalFees.add(feesPay);
        totalRewards = totalRewards.add(rewardPay);

        assert(ERC20Burnable(tokenAddress).transfer(rewardWallet, rewardPay));
        assert(ERC20Burnable(tokenAddress).transfer(feesWallet, feesPay));

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
    * @param burned Amount of tokens burned
    */
    event YearEndClearance(uint256 yearIdx, uint256 feesPay, uint256 burned);


    /**
    * @dev Returns the token balance of the Fees contract
    */
    function currentBalance() internal view returns (uint256) {
        return ERC20Burnable(tokenAddress).balanceOf(address(this));
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