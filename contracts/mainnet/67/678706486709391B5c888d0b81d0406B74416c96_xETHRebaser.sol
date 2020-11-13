pragma solidity 0.6.6;


        
interface UniswapPairContract {
  
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  }
        

interface xETHTokenInterface {
   
    //Public functions
    function maxScalingFactor() external view returns (uint256);
    function xETHScalingFactor() external view returns (uint256);
    //rebase permissioned
    function setTxFee(uint16 fee) external ;
    function setSellFee(uint16 fee) external ;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
}

contract xETHRebaser {

    using SafeMath for uint256;

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

 
    /// @notice an event emitted when deviationThreshold is changed
    event NewDeviationThreshold(uint256 oldDeviationThreshold, uint256 newDeviationThreshold);

    /// @notice Governance address
    address public gov;

  
    /// @notice Spreads out getting to the target price
    uint256 public rebaseLag;

    /// @notice Peg target
    uint256 public targetRate;
  
    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    uint256 public deviationThreshold;

    /// @notice More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    /// @notice Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    /// @notice The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    /// @notice The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    /// @notice The number of rebase cycles since inception
    uint256 public epoch;

    // rebasing is not active initially. It can be activated at T+12 hours from
    // deployment time
    ///@notice boolean showing rebase activation status
    bool public rebasingActive;

    /// @notice delays rebasing activation to facilitate liquidity
    uint256 public constant rebaseDelay = 0;

    address public xETHAddress;
   
    address public uniswap_xeth_eth_pair;
    
    mapping(address => bool) public whitelistFrom;
    
   

    constructor(
        address xETHAddress_,
        address xEthEthPair_
    )
        public
    {
          minRebaseTimeIntervalSec = 1 days;
          rebaseWindowOffsetSec = 0; // 00:00 UTC rebases
       
          // 0.01 ETH
          targetRate = 10**18;

          // daily rebase, with targeting reaching peg in 5 days
          rebaseLag = 10;

          // 5%
          deviationThreshold = 5 * 10**15;

          // 3 hours
          rebaseWindowLengthSec = 24 hours;
          
          uniswap_xeth_eth_pair = xEthEthPair_;
          xETHAddress = xETHAddress_;

          gov = msg.sender;
    }

  
  
  
    
     function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyGov {
        whitelistFrom[_addr] = _whitelisted;
    }
    
    
     function _isWhitelisted(address _from) internal view returns (bool) {
        return whitelistFrom[_from];
    }
    
    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
     *      and targetRate is 1e18
     */
    function rebase()
        public
    {
        // EOA only
        require(msg.sender == tx.origin);
        require(_isWhitelisted(msg.sender));
        // ensure rebasing at correct time
        _inRebaseWindow();
        

        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now);

        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = now;

        epoch = epoch.add(1);

        // get price from uniswap v2;
        uint256 exchangeRate = getPrice();

        // calculates % change to supply
        (uint256 offPegPerc, bool positive) = computeOffPegPerc(exchangeRate);

        uint256 indexDelta = offPegPerc;

        // Apply the Dampening factor.
        indexDelta = indexDelta.div(rebaseLag);

        xETHTokenInterface xETH = xETHTokenInterface(xETHAddress);

        if (positive) {
            require(xETH.xETHScalingFactor().mul(uint256(10**18).add(indexDelta)).div(10**18) < xETH.maxScalingFactor(), "new scaling factor will be too big");
        }


        // rebase
        xETH.rebase(epoch, indexDelta, positive);
        assert(xETH.xETHScalingFactor() <= xETH.maxScalingFactor());

  }
  
    function getPrice()
        public
        view
        returns (uint256)
    {
        (uint xethReserve, uint ethReserve, ) = UniswapPairContract(uniswap_xeth_eth_pair).getReserves();
        
        uint xEthPrice = ethReserve.mul(10**18).div(xethReserve);
               
        return xEthPrice;
    }


  


    function setDeviationThreshold(uint256 deviationThreshold_)
        external
        onlyGov
    {
        require(deviationThreshold > 0);
        uint256 oldDeviationThreshold = deviationThreshold;
        deviationThreshold = deviationThreshold_;
        emit NewDeviationThreshold(oldDeviationThreshold, deviationThreshold_);
    }

    /**
     * @notice Sets the rebase lag parameter.
               It is used to dampen the applied supply adjustment by 1 / rebaseLag
               If the rebase lag R, equals 1, the smallest value for R, then the full supply
               correction is applied on each rebase cycle.
               If it is greater than 1, then a correction of 1/R of is applied on each rebase.
     * @param rebaseLag_ The new rebase lag parameter.
     */
    function setRebaseLag(uint256 rebaseLag_)
        external
        onlyGov
    {
        require(rebaseLag_ > 0);
        rebaseLag = rebaseLag_;
    }
    
    /**
     * @notice Sets the targetRate parameter.
     * @param targetRate_ The new target rate parameter.
     */
    function setTargetRate(uint256 targetRate_)
        external
        onlyGov
    {
        require(targetRate_ > 0);
        targetRate = targetRate_;
    }

    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         rebase operations.
     *         a) the minimum time period that must elapse between rebase cycles.
     *         b) the rebase window offset parameter.
     *         c) the rebase window length parameter.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     * @param rebaseWindowOffsetSec_ The number of seconds from the beginning of
              the rebase interval, where the rebase window begins.
     * @param rebaseWindowLengthSec_ The length of the rebase window in seconds.
     */
    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_,
        uint256 rebaseWindowLengthSec_)
        external
        onlyGov
    {
        require(minRebaseTimeIntervalSec_ > 0);
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_);

        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
        rebaseWindowLengthSec = rebaseWindowLengthSec_;
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {

        // rebasing is delayed until there is a liquid market
        _inRebaseWindow();
        return true;
    }

    function _inRebaseWindow() internal view {
        require(now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec, "too early");
        require(now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)), "too late");
    }

    /**
     * @return Computes in % how far off market is from peg
     */
    function computeOffPegPerc(uint256 rate)
        private
        view
        returns (uint256, bool)
    {
        if (withinDeviationThreshold(rate)) {
            return (0, false);
        }

        // indexDelta =  (rate - targetRate) / targetRate
        if (rate > targetRate) {
            return (rate.sub(targetRate).mul(10**18).div(targetRate), true);
        } else {
            return (targetRate.sub(rate).mul(10**18).div(targetRate), false);
        }
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate)
        private
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** 18);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
}

  library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

 
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

 
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
  
  function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}