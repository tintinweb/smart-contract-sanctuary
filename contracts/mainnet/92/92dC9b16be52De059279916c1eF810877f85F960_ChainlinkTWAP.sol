/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

pragma solidity 0.6.7;

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

interface AggregatorInterface {
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    // post-Historic

    function decimals() external view returns (uint8);
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

abstract contract IncreasingRewardRelayerLike {
    function reimburseCaller(address) virtual external;
}

contract ChainlinkTWAP is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ChainlinkTWAP/account-not-authorized");
        _;
    }

    // --- Variables ---
    AggregatorInterface         public chainlinkAggregator;
    IncreasingRewardRelayerLike public rewardRelayer;

    // Delay between updates after which the reward starts to increase
    uint256 public periodSize;
    // Timestamp of the Chainlink aggregator
    uint256 public linkAggregatorTimestamp;
    // Last timestamp when the median was updated
    uint256 public lastUpdateTime;                  // [unix timestamp]
    // Cumulative result
    uint256 public converterResultCumulative;
    // Latest result
    uint256 private medianResult;                   // [wad]
    /**
      The ideal amount of time over which the moving average should be computed, e.g. 24 hours.
      In practice it can and most probably will be different than the actual window over which the contract medianizes.
    **/
    uint256 public windowSize;
    // Maximum window size used to determine if the median is 'valid' (close to the real one) or not
    uint256 public maxWindowSize;
    // Total number of updates
    uint256 public updates;
    // Multiplier for the Chainlink result
    uint256 public multiplier = 1;
    // Number of updates in the window
    uint8   public granularity;

    // You want to change these every deployment
    uint256 public staleThreshold = 3;
    bytes32 public symbol         = "RAI-USD-TWAP";

    ChainlinkObservation[] public chainlinkObservations;

    // --- Structs ---
    struct ChainlinkObservation {
        uint timestamp;
        uint timeAdjustedResult;
    }

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
    event UpdateResult(uint256 result);

    constructor(
      address aggregator,
      uint256 windowSize_,
      uint256 maxWindowSize_,
      uint256 multiplier_,
      uint8   granularity_
    ) public {
        require(aggregator != address(0), "ChainlinkTWAP/null-aggregator");
        require(multiplier_ >= 1, "ChainlinkTWAP/null-multiplier");
        require(granularity_ > 1, 'ChainlinkTWAP/null-granularity');
        require(windowSize_ > 0, 'ChainlinkTWAP/null-window-size');
        require(
          (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
          'ChainlinkTWAP/window-not-evenly-divisible'
        );

        authorizedAccounts[msg.sender] = 1;

        lastUpdateTime                 = now;
        windowSize                     = windowSize_;
        maxWindowSize                  = maxWindowSize_;
        granularity                    = granularity_;
        multiplier                     = multiplier_;

        chainlinkAggregator            = AggregatorInterface(aggregator);

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("maxWindowSize", maxWindowSize);
        emit ModifyParameters("aggregator", aggregator);
    }

    // --- Boolean Utils ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- General Utils ---
    /**
    * @notice Returns the oldest observations (relative to the current index in the Uniswap/Converter lists)
    **/
    function getFirstObservationInWindow()
      private view returns (ChainlinkObservation storage firstChainlinkObservation) {
        uint256 earliestObservationIndex = earliestObservationIndex();
        firstChainlinkObservation        = chainlinkObservations[earliestObservationIndex];
    }
    /**
      @notice It returns the time passed since the first observation in the window
    **/
    function timeElapsedSinceFirstObservation() public view returns (uint256) {
        if (updates > 1) {
          ChainlinkObservation memory firstChainlinkObservation = getFirstObservationInWindow();
          return subtract(now, firstChainlinkObservation.timestamp);
        }
        return 0;
    }
    /**
    * @notice Returns the index of the earliest observation in the window
    **/
    function earliestObservationIndex() public view returns (uint256) {
        if (updates <= granularity) {
          return 0;
        }
        return subtract(updates, uint(granularity));
    }
    /**
    * @notice Get the observation list length
    **/
    function getObservationListLength() public view returns (uint256) {
        return chainlinkObservations.length;
    }

    // --- Administration ---
    /*
    * @notify Modify an uin256 parameter
    * @param parameter The name of the parameter to change
    * @param data The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "maxWindowSize") {
          require(data > windowSize, 'ChainlinkTWAP/invalid-max-window-size');
          maxWindowSize = data;
        }
        else if (parameter == "staleThreshold") {
          require(data > 1, "ChainlinkTWAP/invalid-stale-threshold");
          staleThreshold = data;
        }
        else revert("ChainlinkTWAP/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to change
    * @param addr The new parameter address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        if (parameter == "aggregator") chainlinkAggregator = AggregatorInterface(addr);
        else if (parameter == "rewardRelayer") {
          rewardRelayer = IncreasingRewardRelayerLike(addr);
        }
        else revert("ChainlinkTWAP/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Main Getters ---
    /**
    * @notice Fetch the latest medianResult or revert if is is null
    **/
    function read() external view returns (uint256) {
        require(
          both(both(medianResult > 0, updates > granularity), timeElapsedSinceFirstObservation() <= maxWindowSize),
          "ChainlinkTWAP/invalid-price-feed"
        );
        return multiply(medianResult, multiplier);
    }
    /**
    * @notice Fetch the latest medianResult and whether it is null or not
    **/
    function getResultWithValidity() external view returns (uint256, bool) {
        return (
          multiply(medianResult, multiplier),
          both(both(medianResult > 0, updates > granularity), timeElapsedSinceFirstObservation() <= maxWindowSize)
        );
    }

    // --- Median Updates ---
    /*
    * @notify Update the moving average
    * @param feeReceiver The address that will receive a SF payout for calling this function
    */
    function updateResult(address feeReceiver) external {
        require(address(rewardRelayer) != address(0), "ChainlinkTWAP/null-reward-relayer");

        uint256 elapsedTime = (chainlinkObservations.length == 0) ?
          subtract(now, lastUpdateTime) : subtract(now, chainlinkObservations[chainlinkObservations.length - 1].timestamp);

        // Check delay between calls
        require(elapsedTime >= periodSize, "ChainlinkTWAP/wait-more");

        int256 aggregatorResult     = chainlinkAggregator.latestAnswer();
        uint256 aggregatorTimestamp = chainlinkAggregator.latestTimestamp();

        require(aggregatorResult > 0, "ChainlinkTWAP/invalid-feed-result");
        require(both(aggregatorTimestamp > 0, aggregatorTimestamp > linkAggregatorTimestamp), "ChainlinkTWAP/invalid-timestamp");

        // Get current first observation timestamp
        uint256 timeSinceFirst;
        if (updates > 0) {
          ChainlinkObservation memory firstUniswapObservation = getFirstObservationInWindow();
          timeSinceFirst = subtract(now, firstUniswapObservation.timestamp);
        } else {
          timeSinceFirst = elapsedTime;
        }

        // Update the observations array
        updateObservations(elapsedTime, uint256(aggregatorResult));

        // Update var state
        medianResult            = converterResultCumulative / timeSinceFirst;
        updates                 = addition(updates, 1);
        linkAggregatorTimestamp = aggregatorTimestamp;
        lastUpdateTime          = now;

        emit UpdateResult(medianResult);

        // Get final fee receiver
        address finalFeeReceiver = (feeReceiver == address(0)) ? msg.sender : feeReceiver;

        // Send the reward
        rewardRelayer.reimburseCaller(finalFeeReceiver);
    }
    /**
    * @notice Push new observation data in the observation array
    * @param timeElapsedSinceLatest Time elapsed between now and the earliest observation in the window
    * @param newResult Latest result coming from Chainlink
    **/
    function updateObservations(
      uint256 timeElapsedSinceLatest,
      uint256 newResult
    ) internal {
        // Compute the new time adjusted result
        uint256 newTimeAdjustedResult = multiply(newResult, timeElapsedSinceLatest);
        // Add Chainlink observation
        chainlinkObservations.push(ChainlinkObservation(now, newTimeAdjustedResult));
        // Add the new update
        converterResultCumulative = addition(converterResultCumulative, newTimeAdjustedResult);

        // Subtract the earliest update
        if (updates >= granularity) {
          ChainlinkObservation memory chainlinkObservation = getFirstObservationInWindow();
          converterResultCumulative = subtract(converterResultCumulative, chainlinkObservation.timeAdjustedResult);
        }
    }
}