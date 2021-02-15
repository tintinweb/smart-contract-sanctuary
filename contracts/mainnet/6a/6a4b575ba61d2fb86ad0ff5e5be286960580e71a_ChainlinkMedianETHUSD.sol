/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity 0.6.7;

interface AggregatorInterface {
  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  function latestAnswer() external returns (int256);
  function latestTimestamp() external returns (uint256);
  function latestRound() external returns (uint256);
  function getAnswer(uint256 roundId) external returns (int256);
  function getTimestamp(uint256 roundId) external returns (uint256);

  // post-Historic

  function decimals() external returns (uint8);
  function getRoundData(uint256 _roundId)
    external
    returns (
      uint256 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
  function latestRoundData()
    external
    returns (
      uint256 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
}

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
}

contract IncreasingTreasuryReimbursement is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "IncreasingTreasuryReimbursement/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Starting reward for the fee receiver/keeper
    uint256 public baseUpdateCallerReward;          // [wad]
    // Max possible reward for the fee receiver/keeper
    uint256 public maxUpdateCallerReward;           // [wad]
    // Max delay taken into consideration when calculating the adjusted reward
    uint256 public maxRewardIncreaseDelay;          // [seconds]
    // Rate applied to baseUpdateCallerReward every extra second passed beyond a certain point (e.g next time when a specific function needs to be called)
    uint256 public perSecondCallerRewardIncrease;   // [ray]

    // SF treasury
    StabilityFeeTreasuryLike  public treasury;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event FailRewardCaller(bytes revertReason, address feeReceiver, uint256 amount);

    constructor(
      address treasury_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_
    ) public {
        if (address(treasury_) != address(0)) {
          require(StabilityFeeTreasuryLike(treasury_).systemCoin() != address(0), "IncreasingTreasuryReimbursement/treasury-coin-not-set");
        }
        require(maxUpdateCallerReward_ >= baseUpdateCallerReward_, "IncreasingTreasuryReimbursement/invalid-max-caller-reward");
        require(perSecondCallerRewardIncrease_ >= RAY, "IncreasingTreasuryReimbursement/invalid-per-second-reward-increase");
        authorizedAccounts[msg.sender] = 1;

        treasury                        = StabilityFeeTreasuryLike(treasury_);
        baseUpdateCallerReward          = baseUpdateCallerReward_;
        maxUpdateCallerReward           = maxUpdateCallerReward_;
        perSecondCallerRewardIncrease   = perSecondCallerRewardIncrease_;
        maxRewardIncreaseDelay          = uint(-1);

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("treasury", treasury_);
        emit ModifyParameters("baseUpdateCallerReward", baseUpdateCallerReward);
        emit ModifyParameters("maxUpdateCallerReward", maxUpdateCallerReward);
        emit ModifyParameters("perSecondCallerRewardIncrease", perSecondCallerRewardIncrease);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Treasury ---
    /**
    * @notice This returns the stability fee treasury allowance for this contract by taking the minimum between the per block and the total allowances
    **/
    function treasuryAllowance() public view returns (uint256) {
        (uint total, uint perBlock) = treasury.getAllowance(address(this));
        return minimum(total, perBlock);
    }
    /*
    * @notice Get the SF reward that can be sent to a function caller right now
    */
    function getCallerReward(uint256 timeOfLastUpdate, uint256 defaultDelayBetweenCalls) public view returns (uint256) {
        bool nullRewards = (baseUpdateCallerReward == 0 && maxUpdateCallerReward == 0);
        if (either(timeOfLastUpdate >= now, nullRewards)) return 0;
        uint256 timeElapsed = (timeOfLastUpdate == 0) ? defaultDelayBetweenCalls : subtract(now, timeOfLastUpdate);
        if (either(timeElapsed < defaultDelayBetweenCalls, baseUpdateCallerReward == 0)) {
            return 0;
        }
        uint256 adjustedTime      = subtract(timeElapsed, defaultDelayBetweenCalls);
        uint256 maxPossibleReward = minimum(maxUpdateCallerReward, treasuryAllowance() / RAY);
        if (adjustedTime > maxRewardIncreaseDelay) {
            return maxPossibleReward;
        }
        uint256 calculatedReward = baseUpdateCallerReward;
        if (adjustedTime > 0) {
            calculatedReward = rmultiply(rpower(perSecondCallerRewardIncrease, adjustedTime, RAY), calculatedReward);
        }
        if (calculatedReward > maxPossibleReward) {
            calculatedReward = maxPossibleReward;
        }
        return calculatedReward;
    }
    /**
    * @notice Send a stability fee reward to an address
    * @param proposedFeeReceiver The SF receiver
    * @param reward The system coin amount to send
    **/
    function rewardCaller(address proposedFeeReceiver, uint256 reward) internal {
        if (address(treasury) == proposedFeeReceiver) return;
        if (either(address(treasury) == address(0), reward == 0)) return;
        address finalFeeReceiver = (proposedFeeReceiver == address(0)) ? msg.sender : proposedFeeReceiver;
        try treasury.pullFunds(finalFeeReceiver, treasury.systemCoin(), reward) {}
        catch(bytes memory revertReason) {
            emit FailRewardCaller(revertReason, finalFeeReceiver, reward);
        }
    }
}

contract ChainlinkPriceFeedMedianizer is IncreasingTreasuryReimbursement {
    // --- Variables ---
    AggregatorInterface public chainlinkAggregator;

    // Delay between updates after which the reward starts to increase
    uint256 public periodSize;
    // Latest median price
    uint256 private medianPrice;                    // [wad]
    // Timestamp of the Chainlink aggregator
    uint256 public linkAggregatorTimestamp;
    // Last timestamp when the median was updated
    uint256 public  lastUpdateTime;                 // [unix timestamp]
    // Multiplier for the Chainlink price feed in order to scaled it to 18 decimals. Default to 10 for USD price feeds
    uint8   public  multiplier = 10;

    // You want to change these every deployment
    uint256 public staleThreshold = 3;
    bytes32 public symbol         = "ethusd";

    // --- Events ---
    event UpdateResult(uint256 medianPrice, uint256 lastUpdateTime);

    constructor(
      address aggregator,
      address treasury_,
      uint256 periodSize_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(aggregator != address(0), "ChainlinkPriceFeedMedianizer/null-aggregator");
        require(multiplier >= 1, "ChainlinkPriceFeedMedianizer/null-multiplier");
        require(periodSize_ > 0, "ChainlinkPriceFeedMedianizer/null-period-size");

        lastUpdateTime      = now;
        periodSize          = periodSize_;
        chainlinkAggregator = AggregatorInterface(aggregator);

        emit ModifyParameters(bytes32("periodSize"), periodSize);
        emit ModifyParameters(bytes32("aggregator"), aggregator);
    }

    // --- General Utils ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") baseUpdateCallerReward = data;
        else if (parameter == "maxUpdateCallerReward") {
          require(data > baseUpdateCallerReward, "ChainlinkPriceFeedMedianizer/invalid-max-reward");
          maxUpdateCallerReward = data;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(data >= RAY, "ChainlinkPriceFeedMedianizer/invalid-reward-increase");
          perSecondCallerRewardIncrease = data;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(data > 0, "ChainlinkPriceFeedMedianizer/invalid-max-increase-delay");
          maxRewardIncreaseDelay = data;
        }
        else if (parameter == "periodSize") {
          require(data > 0, "ChainlinkPriceFeedMedianizer/null-period-size");
          periodSize = data;
        }
        else if (parameter == "staleThreshold") {
          require(data > 1, "ChainlinkPriceFeedMedianizer/invalid-stale-threshold");
          staleThreshold = data;
        }
        else revert("ChainlinkPriceFeedMedianizer/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        if (parameter == "aggregator") chainlinkAggregator = AggregatorInterface(addr);
        else if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike(addr).systemCoin() != address(0), "ChainlinkPriceFeedMedianizer/treasury-coin-not-set");
      	  treasury = StabilityFeeTreasuryLike(addr);
        }
        else revert("ChainlinkPriceFeedMedianizer/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    function read() external view returns (uint256) {
        require(both(medianPrice > 0, subtract(now, linkAggregatorTimestamp) <= multiply(periodSize, staleThreshold)), "ChainlinkPriceFeedMedianizer/invalid-price-feed");
        return medianPrice;
    }

    function getResultWithValidity() external view returns (uint256,bool) {
        return (medianPrice, both(medianPrice > 0, subtract(now, linkAggregatorTimestamp) <= multiply(periodSize, staleThreshold)));
    }

    // --- Median Updates ---
    function updateResult(address feeReceiver) external {
        int256 aggregatorPrice      = chainlinkAggregator.latestAnswer();
        uint256 aggregatorTimestamp = chainlinkAggregator.latestTimestamp();

        require(aggregatorPrice > 0, "ChainlinkPriceFeedMedianizer/invalid-price-feed");
        require(both(aggregatorTimestamp > 0, aggregatorTimestamp > linkAggregatorTimestamp), "ChainlinkPriceFeedMedianizer/invalid-timestamp");

        uint256 callerReward    = getCallerReward(lastUpdateTime, periodSize);
        medianPrice             = multiply(uint(aggregatorPrice), 10 ** uint(multiplier));
        linkAggregatorTimestamp = aggregatorTimestamp;
        lastUpdateTime          = now;

        emit UpdateResult(medianPrice, lastUpdateTime);
        rewardCaller(feeReceiver, callerReward);
    }
}

contract ChainlinkMedianETHUSD is ChainlinkPriceFeedMedianizer {
  constructor(
    address aggregator,
    uint256 periodSize,
    uint256 baseUpdateCallerReward,
    uint256 maxUpdateCallerReward,
    uint256 perSecondCallerRewardIncrease
  ) ChainlinkPriceFeedMedianizer(aggregator, address(0), periodSize, baseUpdateCallerReward, maxUpdateCallerReward, perSecondCallerRewardIncrease) public {
        symbol = "ETHUSD";
        multiplier = 10;
        staleThreshold = 6;
    }
}