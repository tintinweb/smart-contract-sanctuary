/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/LiquidationAuction.sol
pragma solidity ^0.8.2;

interface LedgerLike {
  function transferDebt(
    address,
    address,
    uint256
  ) external;

  function transferCollateral(
    bytes32,
    address,
    address,
    uint256
  ) external;

  function collateralTypes(bytes32)
    external
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function createUnbackedDebt(
    address,
    address,
    uint256
  ) external;
}

interface OracleLike {
  function getPrice() external returns (bytes32, bool);
}

interface OracleRelayerLike {
  function redemptionPrice() external returns (uint256);

  function collateralTypes(bytes32) external returns (OracleLike, uint256);
}

interface LiquidationEngineLike {
  function liquidatonPenalty(bytes32) external returns (uint256);

  function removeDebtFromLiquidation(bytes32, uint256) external;
}

interface LiquidationAuctionCallee {
  function liquidationCallback(
    address,
    uint256,
    uint256,
    bytes calldata
  ) external;
}

interface DiscountCalculatorLike {
  function discountPrice(uint256, uint256) external view returns (uint256);
}

contract LiquidationAuction is Initializable {
  uint256 constant BLN = 10**9;
  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;

  struct Auction {
    uint256 index; // Index in active array
    uint256 debtToRaise; // Dai to raise       [rad]
    uint256 collateralToSell; // collateral to sell [wad]
    address position; // Liquidated CDP
    uint96 startTime; // Auction start time
    uint256 startingPrice; // Starting price     [ray]
  }

  mapping(address => uint256) public authorizedAccounts;
  bytes32 public collateralType; // Collateral type of this LiquidationAuction
  LedgerLike public ledger; // Core CDP Engine

  LiquidationEngineLike public liquidationEngine; // Liquidation module
  address public accountingEngine; // Recipient of dai raised in auctions
  OracleRelayerLike public oracleRelayer; // Collateral price module
  DiscountCalculatorLike public discountCalculator; // Current price discount calculator

  uint256 public startingPriceFactor; // Multiplicative factor to increase starting price                  [ray]
  uint256 public maxAuctionDuration; // Time elapsed before auction reset                                 [seconds]
  uint256 public maxPriceDiscount; // Percentage drop before auction reset                              [ray]
  uint64 public keeperRewardFactor; // Percentage of debtWithPenalty to createUnbackedDebt from accountingEngine to incentivize keepers         [wad]
  uint192 public keeperIncentive; // Flat fee to createUnbackedDebt from accountingEngine to incentivize keepers                  [rad]
  uint256 public minDebtForReward; // Cache the collateralType dust times the collateralType liquidatonPenalty to prevent excessive SLOADs [rad]

  uint256 public auctionCount; // Total auctions
  uint256[] public activeAuctions; // Array of active auction ids

  mapping(uint256 => Auction) public auction;

  uint256 internal locked;

  // Levels for circuit breaker
  // 0: no breaker
  // 1: no new startAuction()
  // 2: no new startAuction() or redo()
  // 3: no new startAuction(), redo(), or take()
  uint256 public stopped;

  // --- Events ---
  event GrantAuthorization(address indexed user);
  event RevokeAuthorization(address indexed user);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
  event UpdateParameter(bytes32 indexed parameter, address data);

  event StartAuction(
    uint256 indexed auctionId,
    address indexed position,
    address indexed keeper,
    uint256 startingPrice,
    uint256 debtToRaise,
    uint256 collateralToSell,
    uint256 reward
  );
  event BidOnAuction(
    uint256 indexed auctionId,
    address indexed position,
    uint256 maxPrice,
    uint256 price,
    uint256 debtDelta,
    uint256 debtToRaise,
    uint256 collateralToSell
  );
  event RestartAuction(
    uint256 indexed auctionId,
    address indexed position,
    address indexed keeper,
    uint256 startingPrice,
    uint256 debtToRaise,
    uint256 collateralToSell,
    uint256 reward
  );

  event CancelAuction(uint256 indexed auctionId);
  event UpdateMinDebtForReward(uint256 minDebtForReward, uint256 timestamp);

  // --- Init ---
  function initialize(
    address ledger_,
    address oracleRelayer_,
    address liquidationEngine_,
    bytes32 collateralType_
  ) public initializer {
    ledger = LedgerLike(ledger_);
    oracleRelayer = OracleRelayerLike(oracleRelayer_);
    liquidationEngine = LiquidationEngineLike(liquidationEngine_);
    collateralType = collateralType_;
    startingPriceFactor = RAY;
    authorizedAccounts[msg.sender] = 1;
    emit GrantAuthorization(msg.sender);
  }

  // --- Auth ---
  function grantAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 1;
    emit GrantAuthorization(user);
  }

  function revokeAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 0;
    emit RevokeAuthorization(user);
  }

  modifier isAuthorized() {
    require(authorizedAccounts[msg.sender] == 1, "Core/not-authorized");
    _;
  }

  // --- Synchronization ---
  modifier reentrancyGuard() {
    require(locked == 0, "LiquidationAuction/system-locked");
    locked = 1;
    _;
    locked = 0;
  }

  modifier isStopped(uint256 level) {
    require(stopped < level, "LiquidationAuction/stopped-incorrect");
    _;
  }

  // --- Administration ---
  function updateStartingPriceFactor(uint256 data)
    external
    isAuthorized
    reentrancyGuard
  {
    startingPriceFactor = data;
    emit UpdateParameter("startingPriceFactor", data);
  }

  function updateMaxAuctionDuration(uint256 data)
    external
    isAuthorized
    reentrancyGuard
  {
    maxAuctionDuration = data; // Time elapsed before auction reset
    emit UpdateParameter("maxAuctionDuration", data);
  }

  function updateMaxPriceDiscount(uint256 data)
    external
    isAuthorized
    reentrancyGuard
  {
    maxPriceDiscount = data; // Percentage drop before auction reset
    emit UpdateParameter("maxPriceDiscount", data);
  }

  function updateKeeperRewardFactor(uint64 data)
    external
    isAuthorized
    reentrancyGuard
  {
    keeperRewardFactor = data; // Percentage of debtToRaise to incentivize (max: 2^64 - 1 => 18.xxx WAD = 18xx%)
    emit UpdateParameter("keeperRewardFactor", data);
  }

  function updateKeeperIncentive(uint192 data)
    external
    isAuthorized
    reentrancyGuard
  {
    keeperIncentive = data; // Flat fee to incentivize keepers (max: 2^192 - 1 => 6.277T RAD)
    emit UpdateParameter("keeperIncentive", data);
  }

  function updateStopped(uint256 data) external isAuthorized reentrancyGuard {
    stopped = data; // Set breaker (0, 1, 2, or 3)
    emit UpdateParameter("stopped", data);
  }

  function updateOracleRelayer(address data)
    external
    isAuthorized
    reentrancyGuard
  {
    oracleRelayer = OracleRelayerLike(data);
    emit UpdateParameter("oracleRelayer", data);
  }

  function updateLiquidationEngine(address data)
    external
    isAuthorized
    reentrancyGuard
  {
    liquidationEngine = LiquidationEngineLike(data);
    emit UpdateParameter("liquidationEngine", data);
  }

  function updateAccountingEngine(address data)
    external
    isAuthorized
    reentrancyGuard
  {
    accountingEngine = data;
    emit UpdateParameter("accountingEngine", data);
  }

  function updateDiscountCalculator(address data)
    external
    isAuthorized
    reentrancyGuard
  {
    discountCalculator = DiscountCalculatorLike(data);
    emit UpdateParameter("discountCalculator", data);
  }

  // --- Math ---
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x <= y ? x : y;
  }

  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * y) / WAD;
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * y) / RAY;
  }

  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * RAY) / y;
  }

  // --- Auction ---

  // get the price directly from the OSM
  // Could get this from rmul(Vat.collateralTypes(collateralType).spot, Spotter.mat()) instead, but
  // if mat has changed since the last poke, the resulting value will be
  // incorrect.
  function getFeedPrice() internal returns (uint256 feedPrice) {
    (OracleLike oracle, ) = oracleRelayer.collateralTypes(collateralType);
    (bytes32 price, bool isValid) = oracle.getPrice();
    require(isValid, "LiquidationAuction/invalid-price");
    feedPrice = rdiv(uint256(price) * BLN, oracleRelayer.redemptionPrice());
  }

  // start an auction
  // note: trusts the caller to transfer collateral to the contract
  // The starting price `startingPrice` is obtained as follows:
  //
  //     startingPrice = val * startingPriceFactor / redemptionPrice
  //
  // Where `val` is the collateral's unitary value in USD, `startingPriceFactor` is a
  // multiplicative factor to increase the starting price, and `redemptionPrice` is a
  // reference per DAI.
  function startAuction(
    uint256 debtToRaise, // Debt                   [rad]
    uint256 collateralToSell, // Collateral             [wad]
    address position, // Address that will receive any leftover collateral
    address keeper // Address that will receive incentives
  )
    external
    isAuthorized
    reentrancyGuard
    isStopped(1)
    returns (uint256 auctionId)
  {
    // Input validation
    require(debtToRaise > 0, "LiquidationAuction/zero-debtToRaise");
    require(collateralToSell > 0, "LiquidationAuction/zero-collateralToSell");
    require(position != address(0), "LiquidationAuction/zero-position");
    auctionId = ++auctionCount;

    activeAuctions.push(auctionId);

    auction[auctionId].index = activeAuctions.length - 1;
    auction[auctionId].debtToRaise = debtToRaise;
    auction[auctionId].collateralToSell = collateralToSell;
    auction[auctionId].position = position;
    auction[auctionId].startTime = uint96(block.timestamp);

    uint256 startingPrice;
    startingPrice = rmul(getFeedPrice(), startingPriceFactor);
    require(startingPrice > 0, "LiquidationAuction/zero-startingPrice-price");
    auction[auctionId].startingPrice = startingPrice;

    // incentive to startAuction auction
    uint256 reward;
    if (keeperIncentive > 0 || keeperRewardFactor > 0) {
      reward = keeperIncentive + wmul(debtToRaise, keeperRewardFactor);
      ledger.createUnbackedDebt(accountingEngine, keeper, reward);
    }

    emit StartAuction(
      auctionId,
      position,
      keeper,
      startingPrice,
      debtToRaise,
      collateralToSell,
      reward
    );
  }

  // Reset an auction
  // See `startAuction` above for an explanation of the computation of `top`.
  function restartAuction(
    uint256 auctionId, // id of the auction to reset
    address keeper // Address that will receive incentives
  ) external reentrancyGuard isStopped(2) {
    // Read auction data
    address position = auction[auctionId].position;
    uint96 startTime = auction[auctionId].startTime;
    uint256 startingPrice = auction[auctionId].startingPrice;

    require(position != address(0), "LiquidationAuction/not-running-auction");

    // Check that auction needs reset
    // and compute current price [ray]
    (bool shouldRestart, ) = auctionStatus(startTime, startingPrice);
    require(shouldRestart, "LiquidationAuction/cannot-restart");

    uint256 debtToRaise = auction[auctionId].debtToRaise;
    uint256 collateralToSell = auction[auctionId].collateralToSell;
    auction[auctionId].startTime = uint96(block.timestamp);

    uint256 feedPrice = getFeedPrice();
    startingPrice = rmul(feedPrice, startingPriceFactor);
    require(startingPrice > 0, "LiquidationAuction/zero-startingPrice-price");
    auction[auctionId].startingPrice = startingPrice;

    // incentive to redo auction
    uint256 reward;
    if (keeperIncentive > 0 || keeperRewardFactor > 0) {
      if (
        debtToRaise >= minDebtForReward &&
        (collateralToSell * feedPrice) >= minDebtForReward
      ) {
        reward = keeperIncentive + wmul(debtToRaise, keeperRewardFactor);
        ledger.createUnbackedDebt(accountingEngine, keeper, reward);
      }
    }

    emit RestartAuction(
      auctionId,
      position,
      keeper,
      startingPrice,
      debtToRaise,
      collateralToSell,
      reward
    );
  }

  // Buy up to `maxCollateralToBuy` of collateral from the auction indexed by `id`.
  //
  // Auctions will not collect more DAI than their assigned DAI target,`debtToRaise`;
  // thus, if `maxCollateralToBuy` would cost more DAI than `debtToRaise` at the current price, the
  // amount of collateral purchased will instead be just enough to collect `debtToRaise` DAI.
  //
  // To avoid partial purchases resulting in very small leftover auctions that will
  // never be cleared, any partial purchase must leave at least `LiquidationAuction.minDebtForReward`
  // remaining DAI target. `minDebtForReward` is an asynchronously updated value equal to
  // (Vat.dust * Dog.liquidatonPenalty(collateralType) / WAD) where the values are understood to be determined
  // by whatever they were when LiquidationAuction.updateMinDebtForReward() was last called. Purchase amounts
  // will be minimally decreased when necessary to respect this limit; i.e., if the
  // specified `maxCollateralToBuy` would leave `debtToRaise < minDebtForReward` but `debtToRaise > 0`, the amount actually
  // purchased will be such that `debtToRaise == minDebtForReward`.
  //
  // If `debtToRaise <= minDebtForReward`, partial purchases are no longer possible; that is, the remaining
  // collateral can only be purchased entirely, or not at all.
  function bidOnAuction(
    uint256 auctionId, // Auction id
    uint256 maxCollateralToBuy, // Upper limit on amount of collateral to buy  [wad]
    uint256 maxPrice, // Maximum acceptable price (DAI / collateral) [ray]
    address liquidatorAddress, // Receiver of collateral and external call address
    bytes calldata data // Data to pass in external call; if length 0, no call is done
  ) external reentrancyGuard isStopped(3) {
    address position = auction[auctionId].position;
    uint96 startTime = auction[auctionId].startTime;

    require(position != address(0), "LiquidationAuction/not-running-auction");

    uint256 price;
    {
      bool shouldRestart;
      (shouldRestart, price) = auctionStatus(
        startTime,
        auction[auctionId].startingPrice
      );

      // Check that auction doesn't need reset
      require(!shouldRestart, "LiquidationAuction/needs-reset");
    }

    // Ensure price is acceptable to buyer
    require(maxPrice >= price, "LiquidationAuction/too-expensive");

    uint256 collateralToSell = auction[auctionId].collateralToSell;
    uint256 debtToRaise = auction[auctionId].debtToRaise;
    uint256 debtDelta;

    {
      // Purchase as much as possible, up to maxCollateralToBuy
      uint256 collateralDelta = min(collateralToSell, maxCollateralToBuy); // collateralDelta <= collateralToSell

      // DAI needed to buy a collateralDelta of this sale
      debtDelta = collateralDelta * price;

      // Don't collect more than debtToRaise of DAI
      if (debtDelta > debtToRaise) {
        // Total debt will be paid
        debtDelta = debtToRaise; // debtDelta' <= debtDelta
        // Adjust collateralDelta
        collateralDelta = debtDelta / price; // collateralDelta' = debtDelta' / price <= debtDelta / price == collateralDelta <= collateralToSell
      } else if (
        debtDelta < debtToRaise && collateralDelta < collateralToSell
      ) {
        // If collateralDelta == collateralToSell => auction completed => dust doesn't matter
        if (debtToRaise - debtDelta < minDebtForReward) {
          // safe as debtDelta < debtToRaise
          // If debtToRaise <= minDebtForReward, buyers have to take the entire collateralToSell.
          require(
            debtToRaise > minDebtForReward,
            "LiquidationAuction/no-partial-purchase"
          );
          // Adjust amount to pay
          debtDelta = debtToRaise - minDebtForReward; // debtDelta' <= debtDelta
          // Adjust collateralDelta
          collateralDelta = debtDelta / price; // collateralDelta' = debtDelta' / price < debtDelta / price == collateralDelta < collateralToSell
        }
      }

      // Calculate remaining debtToRaise after operation
      debtToRaise = debtToRaise - debtDelta; // safe since debtDelta <= debtToRaise
      // Calculate remaining collateralToSell after operation
      collateralToSell = collateralToSell - collateralDelta;

      // Send collateral to liquidatorAddress
      ledger.transferCollateral(
        collateralType,
        address(this),
        liquidatorAddress,
        collateralDelta
      );

      // Do external call (if data is defined) but to be
      // extremely careful we don't allow to do it to the two
      // contracts which the LiquidationAuction needs to be authorized
      if (
        data.length > 0 &&
        liquidatorAddress != address(ledger) &&
        liquidatorAddress != address(liquidationEngine)
      ) {
        LiquidationAuctionCallee(liquidatorAddress).liquidationCallback(
          msg.sender,
          debtDelta,
          collateralDelta,
          data
        );
      }

      // Get DAI from caller
      ledger.transferDebt(msg.sender, accountingEngine, debtDelta);

      // Removes Dai out for liquidation from accumulator
      liquidationEngine.removeDebtFromLiquidation(
        collateralType,
        collateralToSell == 0 ? debtToRaise + debtDelta : debtDelta
      );
    }

    if (collateralToSell == 0) {
      // When there is no more collateral to sell, close the auction
      removeAuction(auctionId);
    } else if (debtToRaise == 0) {
      // When no more debt needs to be raised, refunds remaining collateral & close the auction
      ledger.transferCollateral(
        collateralType,
        address(this),
        position,
        collateralToSell
      );
      removeAuction(auctionId);
    } else {
      // If there are both debtToRaise & collateralToSell, update the auction with the remainder debt and collateral
      auction[auctionId].debtToRaise = debtToRaise;
      auction[auctionId].collateralToSell = collateralToSell;
    }

    emit BidOnAuction(
      auctionId,
      position,
      maxPrice,
      price,
      debtDelta,
      debtToRaise,
      collateralToSell
    );
  }

  function removeAuction(uint256 auctionId) internal {
    uint256 lastAuctionIdInList = activeAuctions[activeAuctions.length - 1];
    if (auctionId != lastAuctionIdInList) {
      // Swap auction to remove to last on the list
      uint256 _index = auction[auctionId].index;
      activeAuctions[_index] = lastAuctionIdInList;
      auction[lastAuctionIdInList].index = _index;
    }
    activeAuctions.pop();
    delete auction[auctionId];
  }

  // The number of active auctions
  function countActiveAuctions() external view returns (uint256) {
    return activeAuctions.length;
  }

  // Return the entire array of active auctions
  function listActiveAuctions() external view returns (uint256[] memory) {
    return activeAuctions;
  }

  // Externally returns boolean for if an auction needs a redo and also the current price
  function getAuctionStatus(uint256 id)
    external
    view
    returns (
      bool needsRedo,
      uint256 price,
      uint256 collateralToSell,
      uint256 debtToRaise
    )
  {
    // Read auction data
    address usr = auction[id].position;
    uint96 startTime = auction[id].startTime;

    bool done;
    (done, price) = auctionStatus(startTime, auction[id].startingPrice);

    needsRedo = usr != address(0) && done;
    collateralToSell = auction[id].collateralToSell;
    debtToRaise = auction[id].debtToRaise;
  }

  // Internally returns boolean for if an auction needs a redo
  function auctionStatus(uint96 startTime, uint256 startingPrice)
    internal
    view
    returns (bool shouldRestart, uint256 discountedPrice)
  {
    discountedPrice = discountCalculator.discountPrice(
      startingPrice,
      block.timestamp - startTime
    );
    shouldRestart = (block.timestamp - startTime > maxAuctionDuration ||
      rdiv(discountedPrice, startingPrice) < maxPriceDiscount);
  }

  // Public function to update the cached dust*liquidatonPenalty value.
  function updateMinDebtForReward() external {
    (, , , , uint256 debtFloor) = LedgerLike(ledger).collateralTypes(
      collateralType
    );
    minDebtForReward = wmul(
      debtFloor,
      liquidationEngine.liquidatonPenalty(collateralType)
    );
    emit UpdateMinDebtForReward(minDebtForReward, block.timestamp);
  }

  // Cancel an auction during ES or via governance action.
  function cancelAuction(uint256 id) external isAuthorized reentrancyGuard {
    require(
      auction[id].position != address(0),
      "LiquidationAuction/not-running-auction"
    );
    liquidationEngine.removeDebtFromLiquidation(
      collateralType,
      auction[id].debtToRaise
    );
    ledger.transferCollateral(
      collateralType,
      address(this),
      msg.sender,
      auction[id].collateralToSell
    );
    removeAuction(id);
    emit CancelAuction(id);
  }
}