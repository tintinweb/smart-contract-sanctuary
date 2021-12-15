// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ICoinDeed.sol";
import "../interface/ICoinDeedFactory.sol";

library CoinDeedUtils {
    uint256 public constant BASE_DENOMINATOR = 10_000;
    address public constant FEED_REGISTRY_ADDRESS = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;

    function tokenRatio(
        address tokenA,
        uint256 tokenAAmount,
        address tokenB
    ) internal view returns (uint256 tokenBAmount){
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(FEED_REGISTRY_ADDRESS);
        uint256 answerA = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        uint256 answerB = uint256(feedRegistry.latestAnswer(tokenB, Denominations.USD));
        uint8 decimalsA = feedRegistry.decimals(tokenA, Denominations.USD);
        uint8 decimalsB = feedRegistry.decimals(tokenB, Denominations.USD);
        require(answerA > 0 && answerB > 0, "Invalid oracle answer");
        return tokenAAmount * (answerA / (10 ** decimalsA)) * ((10 ** decimalsB) / answerB);
    }

    function readyCheck(
        address tokenA,
        uint256 totalStake,
        uint256 stakingMultiplier,
        uint256 deedSize
    ) external view returns (bool){
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(FEED_REGISTRY_ADDRESS);
        uint256 answer = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        uint8 decimals = feedRegistry.decimals(tokenA, Denominations.USD);
        require(answer > 0, "Invalid oracle answer");
        if (
            totalStake >=
            deedSize *
            answer /
            (10 ** decimals) * // Oracle Price in USD
            stakingMultiplier /
            BASE_DENOMINATOR // Staking multiplier
        )
        {
            return true;
        }
        return false;
    }

    function cancelCheck(
        ICoinDeed.DeedState state,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.DeedParameters memory deedParameters,
        uint256 totalSupply
    ) external view returns (bool) {
        if (
            state == ICoinDeed.DeedState.SETUP &&
            block.timestamp > executionTime.recruitingEndTimestamp
        )
        {
            return true;
        }
        else if (
            totalSupply < deedParameters.deedSize * deedParameters.minimumBuy / BASE_DENOMINATOR &&
            block.timestamp > executionTime.buyTimestamp
        )
        {
            return true;
        }
        else {
            return false;
        }
    }

    function withdrawStakeCheck(
        ICoinDeed.DeedState state,
        ICoinDeed.ExecutionTime memory executionTime,
        uint256 stake,
        bool isManager
    ) external view returns (bool) {
        require(
            state != ICoinDeed.DeedState.READY &&
            state != ICoinDeed.DeedState.OPEN,
            "Deed is not in correct state"
        );
        require(stake > 0, "No stake");
        require(
            state == ICoinDeed.DeedState.CLOSED ||
            !isManager,
            "Can not withdraw your stake."
        );
        require(
            state != ICoinDeed.DeedState.SETUP ||
            executionTime.recruitingEndTimestamp < block.timestamp,
            "Recruiting did not end."
        );
        return true;
    }

    // Token B is the collateral token
    // Token A is the debt token
    function checkRiskMitigationAndGetSellAmount(
        ICoinDeed.Pair memory pair,
        ICoinDeed.RiskMitigation memory riskMitigation,
        uint256 totalDeposit,
        uint256 totalBorrow
    ) external view returns (uint256 sellAmount) {
        // Debt value expressed in collateral token units
        uint256 totalBorrowInDepositToken = tokenRatio(
            pair.tokenA, totalBorrow, pair.tokenB);
        /** With leverage L, the ratio of total value of assets / debt is L/L-1.
          * To track an X% price drop, we set the mitigation threshold to (1-X) * L/L-1.
          * For example, if the initial leverage is 3 and we track a price drop of 5%,
          * risk mitigation can be triggered when the ratio of assets to debt falls
          * below 0.95 * 3/2 = 0.1485.
         **/

        uint256 mitigationThreshold =
            (BASE_DENOMINATOR - riskMitigation.trigger) *
            riskMitigation.leverage /
            (riskMitigation.leverage - 1);
        uint256 priceRatio =
            totalDeposit *
            BASE_DENOMINATOR /
            totalBorrowInDepositToken;
        require(priceRatio < mitigationThreshold, "Risk Mitigation isnt required.");

        /** To figure out how much to sell, we use the following formula:
          * a = collateral tokens
          * d = debt token value expressed in collateral token units
          * (e.g. for ETH collateral and BTC debt, how much ETH the BTC debt is worth)
          * s = amount of collateral tokens to sell
          * l_1 = current leverage = a/(a - d)
          * l_2 = risk mitigation target leverage = (a - s)/(a - d)
          * e = equity value expressed in collateral token units = a - d
          * From here we derive s = [a/e - l_2] * e
         **/
        uint256 equityInDepositToken = totalDeposit - totalBorrowInDepositToken;
        sellAmount = ((BASE_DENOMINATOR * totalDeposit / equityInDepositToken) -
                            (BASE_DENOMINATOR * riskMitigation.leverage)) *
                            equityInDepositToken / BASE_DENOMINATOR;
    }

    function getClaimAmount(
        ICoinDeed.DeedState state,
        address tokenA,
        uint256 totalSupply,
        uint256 buyIn
    ) external view returns (uint256 claimAmount)
    {
        require(buyIn > 0, "No share.");
        uint256 balance;
        // Get balance. Assuming delegate call as a library function
        if (tokenA == address(0x00)) {
            balance = address(this).balance;
        }
        else {
            balance = IERC20(tokenA).balanceOf(address(this));
        }

        // Assign claim amount
        if (state == ICoinDeed.DeedState.CLOSED) {
            // buyer can claim tokenA in the same proportion as their buyins
            claimAmount = balance * buyIn / (totalSupply);

            // just a sanity check in case division rounds up
            if (claimAmount > balance) {
                claimAmount = balance;
            }
        } else {
            // buyer can claim tokenA back
            claimAmount = buyIn;
        }
        return claimAmount;
    }

    function validateTokens(ICoinDeed.Pair memory pair) internal view {
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(FEED_REGISTRY_ADDRESS);
        require(
            feedRegistry.latestAnswer(pair.tokenA, Denominations.USD) > 0 &&
            feedRegistry.latestAnswer(pair.tokenB, Denominations.USD) > 0,
            "Invalid oracle feed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoinDeed {


    struct DeedParameters {
        uint256 deedSize;
        uint8 leverage;
        uint256 managementFee;
        uint256 minimumBuy;
    }

    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    struct Pair {address tokenA; address tokenB;}

    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    struct RiskMitigation {
        uint256 trigger;
        uint8 leverage;
    }

    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }

    /**
    *  Reserve a wholesale to swap on execution time
    */
    function reserveWholesale(uint256 wholesaleId) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    */
    function stake(uint256 amount) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    // function stakeEth() external payable;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    // function stakeDifferentToken(address token, uint256 amount) external;

    /**
    *  Brokers can withdraw their stake
    */
    function withdrawStake() external;

    /**
    *  Edit Broker Config
    */
    function editBrokerConfig(BrokerConfig memory brokerConfig) external;

    /**
    *  Edit RiskMitigation
    */
    function editRiskMitigation(RiskMitigation memory riskMitigation) external;

    /**
    *  Edit ExecutionTime
    */
    function editExecutionTime(ExecutionTime memory executionTime) external;

    /**
    *  Edit DeedInfo
    */
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee, uint256 minimumBuy) external;

    /**
    *  Edit
    */
    function edit(DeedParameters memory deedParameters,
        ExecutionTime memory executionTime,
        RiskMitigation memory riskMitigation,
        BrokerConfig memory brokerConfig) external;

    /**
     * Initial swap to buy the tokens
     */
    function buy() external;

    /**
     * Final swap to buy the tokens
     */
    function sell() external;

    /**
    *  Cancels deed if it is not started yet.
    */
    function cancel() external;

    /**
    *  Buyers buys in from the deed
    */
    function buyIn(uint256 amount) external;

    /**
    *  Buyers buys in from the deed with native coin
    */
    function buyInEth() external payable;

    /**
    *  Buyers pays of their loan
    */
    // function payOff(uint256 amount) external;

    /**
    *  Buyers pays of their loan with native coin
    */
    // function payOffEth() external payable;

    /**
     *  Buyers pays of their loan with with another ERC20
     */
    // function payOffDifferentToken(address tokenAddress, uint256 amount) external;

    /**
    *  Buyers claims their balance if the deed is completed.
    */
    function claimBalance() external;

    /**
    *  Brokers and DeedManager claims their rewards.
    */
    // function claimManagementFee() external;

    /**
    *  System changes leverage to be sure that the loan can be paid.
    */
    function executeRiskMitigation() external;

    /**
    *  Buyers can leave deed before escrow closes.
    */
    function exitDeed() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeed.sol";

interface ICoinDeedFactory {


    event DeedCreated(
        uint256 indexed id,
        address indexed deedAddress,
        address indexed manager
    );

    event StakeAdded(
        address indexed coinDeed,
        address indexed broker,
        uint256 indexed amount
    );

    event StateChanged(
        address indexed coinDeed,
        ICoinDeed.DeedState state
    );

    event DeedCanceled(
        address indexed coinDeed,
        address indexed deedAddress
    );

    event SwapExecuted(
        address indexed coinDeed,
        uint256 indexed tokenBought
    );

    event BuyIn(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event ExitDeed(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event PayOff(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event LeverageChanged(
        address indexed coinDeed,
        address indexed salePercentage
    );

    event BrokersEnabled(
        address indexed coinDeed
    );

    /**
    * DeedManager calls to create deed contract
    */
    function createDeed(ICoinDeed.Pair calldata pair,
        uint256 stakingAmount,
        uint256 wholesaleId,
        ICoinDeed.DeedParameters calldata deedParameters,
        ICoinDeed.ExecutionTime calldata executionTime,
        ICoinDeed.RiskMitigation calldata riskMitigation,
        ICoinDeed.BrokerConfig calldata brokerConfig) external;

    /**
    * Returns number of Open deeds to able to browse them
    */
    function openDeedCount() external view returns (uint256);

    /**
    * Returns number of completed deeds to able to browse them
    */
    function completedDeedCount() external view returns (uint256);

    /**
    * Returns number of pending deeds to able to browse them
    */
    function pendingDeedCount() external view returns (uint256);

    function setMaxLeverage(uint8 _maxLeverage) external;

    function setStakingMultiplier(uint256 _stakingMultiplier) external;

    function permitToken(address token) external;

    function unpermitToken(address token) external;

    function wholesaleFactoryAddress() external view returns (address);

    function lendingPoolAddress() external view returns (address);

    function coinDeedDeployerAddress() external view returns (address);

    // The maximum leverage that any deed can have
    function maxLeverage() external view returns (uint8);

    // The fee the platform takes from all buyins before the swap
    function platformFee() external view returns (uint256);

    // The chainlink oracle feed registry address
    function feedRegistryAddress() external view returns (address);

    // The treasury address
    function treasuryAddress() external view returns (address);

    // The amount of stake needed per dollar value of the buyins
    function stakingMultiplier() external view returns (uint256);

    // The maximum proportion relative price can drop before a position becomes insolvent is 1/leverage.
    // The maximum price drop a deed can list risk mitigation with is maxPriceDrop/leverage
    function maxPriceDrop() external view returns (uint256);

    function setPlatformFee(uint256 _platformFee) external;

    function setFeedRegistry(address _feedRegistryAddress) external;

    function setTreasuryAddress(address _treasuryAddress) external;

    function setMaxPriceDrop(uint256 _maxPriceDrop) external;

    function managerDeedCount(address manager) external view returns (uint256);

    function emitStakeAdded(
        address broker,
        uint256 amount
    ) external;

    function emitStateChanged(
        ICoinDeed.DeedState state
    ) external;

    function emitDeedCanceled(
        address deedAddress
    ) external;

    function emitSwapExecuted(
        uint256 tokenBought
    ) external;

    function emitBuyIn(
        address buyer,
        uint256 amount
    ) external;

    function emitExitDeed(
        address buyer,
        uint256 amount
    ) external;

    function emitPayOff(
        address buyer,
        uint256 amount
    ) external;

    function emitLeverageChanged(
        address salePercentage
    ) external;

    function emitBrokersEnabled() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}