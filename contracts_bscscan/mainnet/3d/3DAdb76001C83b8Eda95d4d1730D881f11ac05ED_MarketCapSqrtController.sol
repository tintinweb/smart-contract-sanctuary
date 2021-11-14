// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MarketCapSortedTokenCategories.sol";
import "../interfaces/IIndexPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IPoolInitializer.sol";
import "../interfaces/IBisharesUniswapV2Oracle.sol";
import "../interfaces/IDelegateCallProxyManager.sol";
import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";
import "../lib/MCapSqrtLibrary.sol";
import "../proxies/SaltyLib.sol";


contract MarketCapSqrtController is MarketCapSortedTokenCategories {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;
  using SafeMath for uint256;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;
  
  /**
   * @dev Data structure with metadata about an index pool.
   *
   * Includes the number of times a pool has been either reweighed
   * or re-indexed, as well as the timestamp of the last such action.
   *
   * To reweigh or re-index, the last update must have occurred at
   * least `POOL_REWEIGH_DELAY` seconds ago.
   *
   * If `++index % REWEIGHS_BEFORE_REINDEX + 1` is 0, the pool will
   * re-index, otherwise it will reweigh.
   *
   * The struct fields are assigned their respective integer sizes so
   * that solc can pack the entire struct into a single storage slot.
   * `reweighIndex` is intended to overflow, `categoryID` will never
   * reach 2**16, `indexSize` is capped at 10 and it is unlikely that
   * this project will be in use in the year 292277026596 (unix time
   * for 2**64 - 1).
   *
   * @param initialized Whether the pool has been initialized with the
   * starting balances.
   * @param categoryID Category identifier for the pool.
   * @param indexSize Number of tokens the pool should hold.
   * @param reweighIndex Number of times the pool has either re-weighed
   * or re-indexed.
   * @param lastReweigh Timestamp of last pool re-weigh or re-index.
   */
  struct IndexPoolMeta {
    bool initialized;
    uint16 categoryID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
  }

  uint256 internal constant MIN_INDEX_SIZE = 2;
  uint256 internal constant MAX_INDEX_SIZE = 25;
  uint256 internal constant MIN_BALANCE = 1e6;
  bytes32 internal constant INITIALIZER_IMPLEMENTATION_ID = keccak256("PoolInitializer.sol");
  bytes32 internal constant POOL_IMPLEMENTATION_ID = keccak256("IndexPool.sol");
  uint256 internal constant WEIGHT_MULTIPLIER = 25e18;
  uint256 internal constant POOL_REWEIGH_DELAY = 1 weeks;
  uint256 internal constant REWEIGHS_BEFORE_REINDEX = 3;

  IPoolFactory internal immutable _factory;
  IDelegateCallProxyManager internal immutable _proxyManager;
  address public immutable defaultExitFeeRecipient;
  address public immutable defaultExitFeeRecipientAdditional;
  mapping(address => IndexPoolMeta) internal _poolMeta;

  function computeInitializerAddress(
    address poolAddress
  ) public view returns (address) {
    return SaltyLib.computeProxyAddressManyToOne(
      address(_proxyManager),
      address(this),
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  function computePoolAddress(
    uint256 categoryID,
    uint256 indexSize
  ) external view returns (address) {
    return SaltyLib.computeProxyAddressManyToOne(
      address(_proxyManager),
      address(_factory),
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(
        address(this),
        keccak256(abi.encodePacked(categoryID, indexSize))
      ))
    );
  }

  function getInitialTokensAndBalances(
    uint256 categoryID,
    uint256 indexSize,
    uint144 wethValue
  ) public view returns (address[] memory tokens, uint256[] memory balances) {
    tokens = getTopCategoryTokens(categoryID, indexSize);
    PriceLibrary.TwoWayAveragePrice[] memory prices = _categoryOracles[categoryID].computeTwoWayAveragePrices(
      tokens,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    FixedPoint.uq112x112[] memory weights = getTopCategoryTokensInitialWeights(categoryID, indexSize);
    weights = MCapSqrtLibrary.computeTokenWeights(weights);
    balances = new uint256[](indexSize);
    for (uint256 i = 0; i < indexSize; i++) {
      uint256 targetBalance = MCapSqrtLibrary.computeWeightedBalance(
        wethValue,
        weights[i],
        prices[i]
      );
      require(targetBalance >= MIN_BALANCE, "BiShares: Min balance overflow");
      balances[i] = targetBalance;
    }
  }

  event PoolInitialized(address pool, uint256 categoryID, uint256 indexSize);
  event NewPoolInitializer(address pool, address initializer);

  constructor(
    IPoolFactory factory,
    IDelegateCallProxyManager proxyManager,
    address defaultExitFeeRecipient_,
    address defaultExitFeeRecipientAdditional_
  ) MarketCapSortedTokenCategories() {
    address zero = address(0);
    require(address(factory) != zero, "BiShares: Factory is zero address");
    require(address(proxyManager) != zero, "BiShares: Proxy manager is zero address");
    require(
      defaultExitFeeRecipient_ != zero
      && defaultExitFeeRecipientAdditional_ != zero,
      "Bishares: Fee recipient is zero address"
    );
    _factory = factory;
    _proxyManager = proxyManager;
    defaultExitFeeRecipient = defaultExitFeeRecipient_;
    defaultExitFeeRecipientAdditional = defaultExitFeeRecipientAdditional_;
  }

  function initialize() public override returns (bool) {
    return super.initialize();
  }

  function prepareIndexPool(
    uint256 categoryID,
    uint256 indexSize,
    uint256 initialWethValue,
    string memory name,
    string memory symbol
  ) external onlyOwner returns (address poolAddress, address initializerAddress) {
    require(indexSize >= MIN_INDEX_SIZE, "BiShares: Min index size overflow");
    require(indexSize <= MAX_INDEX_SIZE, "BiShares: Max index size overflow");
    require(initialWethValue < uint144(-1), "BiShares: Initial weth value uint144 overflow");
    address router = _categoryRouters[categoryID];
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID];
    poolAddress = _factory.deployPool(
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(categoryID, indexSize))
    );
    IIndexPool(poolAddress).configure(
      address(this),
      name,
      symbol,
      address(oracle),
      router,
      defaultExitFeeRecipient,
      defaultExitFeeRecipientAdditional
    );
    _poolMeta[poolAddress] = IndexPoolMeta({
      initialized: false,
      categoryID: uint16(categoryID),
      indexSize: uint8(indexSize),
      lastReweigh: 0,
      reweighIndex: 0
    });
    initializerAddress = _proxyManager.deployProxyManyToOne(
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
    IPoolInitializer initializer = IPoolInitializer(initializerAddress);
    (
      address[] memory tokens,
      uint256[] memory balances
    ) = getInitialTokensAndBalances(categoryID, indexSize, uint144(initialWethValue));
    initializer.initialize(poolAddress, tokens, balances, oracle);
    emit NewPoolInitializer(
      poolAddress,
      initializerAddress
    );
  }

  function finishPreparedIndexPool(
    address poolAddress,
    address[] memory tokens,
    uint256[] memory balances
  ) external returns (bool) {
    address caller = msg.sender;
    uint256 valueSum = 0;
    require(caller == computeInitializerAddress(poolAddress), "BiShares: Prepare index pool first");
    uint256 len = tokens.length;
    require(balances.length == len, "BiShares: Invalid arrays length");
    address oracleAddress = IIndexPool(poolAddress).oracle();
    IndexPoolMeta memory meta = _poolMeta[poolAddress];
    require(!meta.initialized, "BiShares: Already initialized");
    uint96[] memory denormalizedWeights = new uint96[](len);
    uint144[] memory ethValues = IBisharesUniswapV2Oracle(oracleAddress).computeAverageEthForTokens(
      tokens,
      balances,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    for (uint256 i = 0; i < len; i++) {
      valueSum = valueSum.add(ethValues[i]);
    }
    for (uint256 j = 0; j < len; j++) {
      denormalizedWeights[j] = _denormalizeFractionalWeight(
        FixedPoint.fraction(uint112(ethValues[j]), uint112(valueSum))
      );
    }
    bool result = IIndexPool(poolAddress).initialize(
      tokens,
      balances,
      denormalizedWeights,
      caller
    );
    meta.lastReweigh = uint64(block.timestamp);
    meta.initialized = result;
    _poolMeta[poolAddress] = meta;
    emit PoolInitialized(
      poolAddress,
      meta.categoryID,
      meta.indexSize
    );
    return result;
  }

  function setMaxPoolTokens(
    address poolAddress,
    uint256 maxPoolTokens
  ) external onlyOwner _havePool(poolAddress) returns (bool) {
    return IIndexPool(poolAddress).setMaxPoolTokens(maxPoolTokens);
  }

  function setExitFeeReciver(
    address poolAddress,
    address exitFeeRecipient,
    bool additional
  ) external onlyOwner _havePool(poolAddress) returns (bool) {
    return IIndexPool(poolAddress).setExitFeeRecipient(exitFeeRecipient, additional);
  }

  function updateMinimumBalance(
    IIndexPool pool,
    address tokenAddress
  ) external _havePool(address(pool)) returns (bool) {
    IIndexPool.Record memory record = pool.getTokenRecord(tokenAddress);
    require(!record.ready, "BiShares: Token not ready");
    uint256 poolValue = _estimatePoolValue(pool);
    address oracleAddress = IIndexPool(pool).oracle();
    PriceLibrary.TwoWayAveragePrice memory price = IBisharesUniswapV2Oracle(oracleAddress).computeTwoWayAveragePrice(
      tokenAddress,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint256 minimumBalance = price.computeAverageTokensForEth(poolValue) / 100;
    return pool.setMinimumBalance(tokenAddress, minimumBalance);
  }

  function delegateCompLikeTokenFromPool(
    address pool,
    address token,
    address delegatee
  ) external onlyOwner _havePool(pool) returns (bool) {
    return IIndexPool(pool).delegateCompLikeToken(token, delegatee);
  }

  function reindexPool(address poolAddress) external returns (bool) {
    uint256 time = block.timestamp;
    IndexPoolMeta memory meta = _poolMeta[poolAddress];
    require(meta.initialized, "BiShares: Pool not found");
    require(time - meta.lastReweigh >= POOL_REWEIGH_DELAY, "BiShares: Pool reweigh delay overflow");
    require((++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) == 0, "BiShares: Pool reweigh index overflow");
    uint256 size = meta.indexSize;
    uint256 categoryID = meta.categoryID;
    address[] memory tokens = getTopCategoryTokens(categoryID, size);
    address oracleAddress = IIndexPool(poolAddress).oracle();
    PriceLibrary.TwoWayAveragePrice[] memory prices = IBisharesUniswapV2Oracle(
      oracleAddress).computeTwoWayAveragePrices(
        tokens,
        SHORT_TWAP_MIN_TIME_ELAPSED,
        SHORT_TWAP_MAX_TIME_ELAPSED
      );
    FixedPoint.uq112x112[] memory weights = getTopCategoryTokensInitialWeights(categoryID, size);
    weights = MCapSqrtLibrary.computeTokenWeights(weights);
    uint256[] memory minimumBalances = new uint256[](size);
    uint96[] memory denormalizedWeights = new uint96[](size);
    uint144 totalValue = _estimatePoolValue(IIndexPool(poolAddress));
    for (uint256 i = 0; i < size; i++) {
      minimumBalances[i] = prices[i].computeAverageTokensForEth(totalValue) / 100;
      denormalizedWeights[i] = _denormalizeFractionalWeight(weights[i]);
    }
    meta.lastReweigh = uint64(time);
    _poolMeta[poolAddress] = meta;
    return IIndexPool(poolAddress).reindexTokens(
      tokens,
      denormalizedWeights,
      minimumBalances
    );
  }

  function reweighPool(address poolAddress) external returns (bool) {
    uint256 time = block.timestamp;
    IndexPoolMeta memory meta = _poolMeta[poolAddress];
    require(meta.initialized, "BiShares: Pool not found");
    require(time - meta.lastReweigh >= POOL_REWEIGH_DELAY, "BiShares: Pool reweigh delay overflow");
    require((++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) != 0, "BiShares: Pool reweigh index overflow");
    address[] memory tokens = IIndexPool(poolAddress).getCurrentDesiredTokens();
    FixedPoint.uq112x112[] memory weights = getTopCategoryTokensInitialWeights(meta.categoryID, meta.indexSize);
    weights = MCapSqrtLibrary.computeTokenWeights(weights);
    uint96[] memory denormalizedWeights = new uint96[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      denormalizedWeights[i] = _denormalizeFractionalWeight(weights[i]);
    }
    meta.lastReweigh = uint64(time);
    _poolMeta[poolAddress] = meta;
    return IIndexPool(poolAddress).reweighTokens(tokens, denormalizedWeights);
  }

  function _estimatePoolValue(IIndexPool pool) internal view returns (uint144) {
    (address token, uint256 value) = pool.extrapolatePoolValueFromToken();
    address oracleAddress = pool.oracle();
    return IBisharesUniswapV2Oracle(oracleAddress).computeAverageEthForTokens(
      token,
      value,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
  }

  function _denormalizeFractionalWeight(FixedPoint.uq112x112 memory fraction) internal pure returns (uint96) {
    return uint96(fraction.mul(WEIGHT_MULTIPLIER).decode144());
  }

  modifier _havePool(address pool) {
    require(_poolMeta[pool].initialized, "BiShares: Pool not found");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./CodeHashes.sol";


library SaltyLib {

  function deriveManyToOneSalt(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) internal pure returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        originator,
        implementationID,
        suppliedSalt
      )
    );
  }

  function deriveOneToOneSalt(
    address originator,
    bytes32 suppliedSalt
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(originator, suppliedSalt));
  }

  function computeProxyAddressOneToOne(
    address deployer,
    address originator,
    bytes32 suppliedSalt
  ) internal pure returns (address) {
    bytes32 salt = deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH, deployer);
  }

  function computeProxyAddressManyToOne(
    address deployer,
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) internal pure returns (address) {
    bytes32 salt = deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH, deployer);
  }

  function computeHolderAddressManyToOne(
    address deployer,
    bytes32 implementationID
  ) internal pure returns (address) {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH,
      deployer
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract ManyToOneImplementationHolder {
  address internal immutable _manager;
  address internal _implementation;

  constructor() {
    _manager = msg.sender;
  }

  fallback() external payable {
    if (msg.sender != _manager) {
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    }
    assembly { sstore(0, calldataload(0)) }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Proxy.sol";


contract DelegateCallProxyOneToOne is Proxy {
  address internal immutable _manager;

  constructor() {
    _manager = msg.sender ;
  }

  function _implementation() internal override view returns (address) {
    address implementation;
    assembly {
      implementation := sload(
        // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
        0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a
      )
    }
    return implementation;
  }

  function _beforeFallback() internal override {
    if (msg.sender != _manager) {
      super._beforeFallback();
    } else {
      assembly {
        sstore(
          // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
          0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a,
          calldataload(0)
        )
        return(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Proxy.sol";


interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}


contract DelegateCallProxyManyToOne is Proxy {
  address internal immutable _implementationHolder;

  constructor() {
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

  function _implementation() internal override view returns (address) {
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./ManyToOneImplementationHolder.sol";
import "./DelegateCallProxyManyToOne.sol";
import "./DelegateCallProxyOneToOne.sol";


library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = keccak256(
    type(DelegateCallProxyOneToOne).creationCode
  );
  bytes32 internal constant MANY_TO_ONE_CODEHASH = keccak256(
    type(DelegateCallProxyManyToOne).creationCode
  );
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = keccak256(
    type(ManyToOneImplementationHolder).creationCode
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IUniswapV2Pair.sol";
import "./FixedPoint.sol";


library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  function currentCumulativePrices(
    address pair
  ) internal view returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrices: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
      // counterfactual
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  function currentCumulativePrice0(
    address pair
  ) internal view returns (uint256 price0Cumulative, uint32 blockTimestamp) {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice0: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
    }
  }

  function currentCumulativePrice1(
    address pair
  ) internal view returns (uint256 price1Cumulative, uint32 blockTimestamp) {
    blockTimestamp = currentBlockTimestamp();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice1: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  function computeAveragePrice(
    uint224 priceCumulativeStart,
    uint224 priceCumulativeEnd,
    uint32 timeElapsed
  ) internal pure returns (FixedPoint.uq112x112 memory priceAverage) {
    priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";

interface IUniswapFactory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

library UniswapV2Library {
  using SafeMath for uint256;
  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal view returns (address pair) {
    IUniswapFactory _factory = IUniswapFactory(factory);
    pair = _factory.getPair(token0, token1);
  }

  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";


library PriceLibrary {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  struct TwoWayAveragePrice {
    uint224 priceAverage;
    uint224 ethPriceAverage;
  }

  function pairInitialized(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (bool) {
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token, weth);
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
    return reserve0 != 0 && reserve1 != 0;
  }

  function observePrice(
    address uniswapFactory,
    address tokenIn,
    address quoteToken
  ) internal view returns (uint32, uint224) {
    (address token0, address token1) = UniswapV2Library.sortTokens(tokenIn, quoteToken);
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
    if (token0 == tokenIn) {
      (uint256 price0Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
      return (blockTimestamp, uint224(price0Cumulative));
    } else {
      (uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
      return (blockTimestamp, uint224(price1Cumulative));
    }
  }

  function observeTwoWayPrice(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (PriceObservation memory) {
    (address token0, address token1) = UniswapV2Library.sortTokens(token, weth);
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    if (token0 == token) {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price0Cumulative),
        ethPriceCumulativeLast: uint224(price1Cumulative)
      });
    } else {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price1Cumulative),
        ethPriceCumulativeLast: uint224(price0Cumulative)
      });
    }
  }

  function computeTwoWayAveragePrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (TwoWayAveragePrice memory) {
    uint32 timeElapsed = uint32(observation2.timestamp - observation1.timestamp);
    FixedPoint.uq112x112 memory priceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      timeElapsed
    );
    FixedPoint.uq112x112 memory ethPriceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      timeElapsed
    );
    return TwoWayAveragePrice({
      priceAverage: priceAverage._x,
      ethPriceAverage: ethPriceAverage._x
    });
  }

  function computeAveragePrice(
    uint32 timestampStart,
    uint224 priceCumulativeStart,
    uint32 timestampEnd,
    uint224 priceCumulativeEnd
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      priceCumulativeStart,
      priceCumulativeEnd,
      uint32(timestampEnd - timestampStart)
    );
  }

  function computeAverageTokenPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  function computeAverageEthPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  function computeAverageEthForTokens(
    TwoWayAveragePrice memory prices,
    uint256 tokenAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.priceAverage).mul(tokenAmount).decode144();
  }

  function computeAverageTokensForEth(
    TwoWayAveragePrice memory prices,
    uint256 wethAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.ethPriceAverage).mul(wethAmount).decode144();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceLibrary.sol";
import "./FixedPoint.sol";
import "./Babylonian.sol";


library MCapSqrtLibrary {
  using Babylonian for uint256;
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;

  function computeAverageMarketCap(
    address token,
    PriceLibrary.TwoWayAveragePrice memory averagePrice
  ) internal view returns (uint144) {
    uint256 totalSupply = IERC20(token).totalSupply();
    return averagePrice.computeAverageEthForTokens(totalSupply);
  }

  function computeMarketCapSqrts(
    address[] memory tokens,
    PriceLibrary.TwoWayAveragePrice[] memory averagePrices
  ) internal view returns (uint112[] memory sqrts) {
    uint256 len = tokens.length;
    sqrts = new uint112[](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 marketCap = computeAverageMarketCap(tokens[i], averagePrices[i]);
      sqrts[i] = uint112(marketCap.sqrt());
    }
  }

  function computeTokenWeights(
    address[] memory tokens,
    PriceLibrary.TwoWayAveragePrice[] memory averagePrices
  ) internal view returns (FixedPoint.uq112x112[] memory weights) {
    uint112[] memory sqrts = computeMarketCapSqrts(tokens, averagePrices);
    uint112 rootSum;
    uint256 len = sqrts.length;
    for (uint256 i = 0; i < len; i++) rootSum += sqrts[i];
    weights = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      weights[i] = FixedPoint.fraction(sqrts[i], rootSum);
    }
  }

  function computeTokenWeights(
    FixedPoint.uq112x112[] memory weights
  ) internal pure returns (FixedPoint.uq112x112[] memory) {
    uint256 len = weights.length;
    uint112 weightsSum;
    for (uint256 i = 0; i < len; i++) weightsSum += uint112(weights[i]._x);
    for (uint256 i = 0; i < len; i++) weights[i] = FixedPoint.fraction(uint112(weights[i]._x), weightsSum);
    return weights;
  }

  function computeWeightedBalance(
    uint144 totalValue,
    FixedPoint.uq112x112 memory weight,
    PriceLibrary.TwoWayAveragePrice memory averagePrice
  ) internal pure returns (uint144 weightedBalance) {
    uint144 desiredWethValue = weight.mul(totalValue).decode144();
    return averagePrice.computeAverageTokensForEth(desiredWethValue);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = uint256(1) << RESOLUTION;
  uint256 private constant Q224 = Q112 << RESOLUTION;

  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112(self._x / uint224(x));
  }

  function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
    uint256 z;
    require(
      y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
      "FixedPoint: MULTIPLICATION_OVERFLOW"
    );
    return uq144x112(z);
  }

  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
  }

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uq112x112(uint224(Q224 / self._x));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library Babylonian {
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = (y + 1) / 2;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUniswapV2Pair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IBisharesUniswapV2Oracle.sol";


interface IPoolInitializer {
  function initialize(
    address poolAddress,
    address[] memory tokens,
    uint256[] memory amounts,
    IBisharesUniswapV2Oracle oracle
  ) external returns (bool);
  function finish() external returns (bool);
  function claimTokens() external returns (bool);
  function claimTokens(address account) external returns (bool);
  function claimTokens(address[] memory accounts) external returns (bool);
  function contributeTokens(
    address token,
    uint256 amountIn,
    uint256 minimumCredit
  ) external returns (uint256);
  function contributeTokens(
    address[] memory tokens,
    uint256[] memory amountsIn,
    uint256 minimumCredit
  ) external returns (uint256);
  function updatePrices() external returns (bool);

  function isFinished() external view returns (bool);
  function getTotalCredit() external view returns (uint256);
  function getCreditOf(address account) external view returns (uint256);
  function getDesiredTokens() external view returns (address[] memory);
  function getDesiredAmount(address token) external view returns (uint256);
  function getDesiredAmounts(address[] memory tokens) external view returns (uint256[] memory);
  function getCreditForTokens(address token, uint256 amountIn) external view returns (uint144);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IDelegateCallProxyManager.sol";


interface IPoolFactory {
  function approvePoolController(address controller) external returns (bool);
  function disapprovePoolController(address controller) external returns (bool);
  function deployPool(bytes32 implementationID, bytes32 controllerSalt) external returns (address);

  function proxyManager() external view returns (IDelegateCallProxyManager);
  function isApprovedController(address) external view returns (bool);
  function getPoolImplementationID(address) external view returns (bytes32);
  function isRecognizedPool(address pool) external view returns (bool);
  function computePoolAddress(
    bytes32 implementationID,
    address controller,
    bytes32 controllerSalt
  ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string memory name,
    string memory symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeReciver,
    address exitFeeReciverAdditional
  ) external returns (bool);
  function initialize(
    address[] memory tokens,
    uint256[] memory balances,
    uint96[] memory denorms,
    address tokenProvider
  ) external returns (bool);
  function setMaxPoolTokens(uint256 maxPoolTokens) external returns (bool);
  function delegateCompLikeToken(address token, address delegatee) external returns (bool);
  function setExitFeeRecipient(address exitFeeRecipient_, bool additional) external returns (bool);
  function reweighTokens(address[] memory tokens, uint96[] memory desiredDenorms) external returns (bool);
  function reindexTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms,
    uint256[] memory minimumBalances
  ) external returns (bool);
  function setMinimumBalance(address token, uint256 minimumBalance) external returns (bool);
  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external returns (bool);
  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external returns (bool);

  function oracle() external view returns (address);
  function router() external view returns (address);
  function isPublicSwap() external view returns (bool);
  function getController() external view returns (address);
  function getMaxPoolTokens() external view returns (uint256);
  function isBound(address t) external view returns (bool);
  function getNumTokens() external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory tokens);
  function getCurrentDesiredTokens() external view returns (address[] memory tokens);
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getTokenRecord(address token) external view returns (Record memory record);
  function extrapolatePoolValueFromToken() external view returns (address token, uint256 extrapolatedValue);
  function getTotalDenormalizedWeight() external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getMinimumBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
  function getExitFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IDelegateCallProxyManager {
  function isImplementationLocked(bytes32 implementationID) external view returns (bool);
  function isImplementationLocked(address proxyAddress) external view returns (bool);
  function isApprovedDeployer(address deployer) external view returns (bool);
  function getImplementationHolder() external view returns (address);
  function getImplementationHolder(bytes32 implementationID) external view returns (address);
  function computeProxyAddressOneToOne(address originator, bytes32 suppliedSalt) external view returns (address);
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);
  function computeHolderAddressManyToOne(bytes32 implementationID) external view returns (address);

  function approveDeployer(address deployer) external returns (bool);
  function revokeDeployerApproval(address deployer) external returns (bool);
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external returns (bool);
  function lockImplementationManyToOne(bytes32 implementationID) external returns (bool);
  function lockImplementationOneToOne(address proxyAddress) external returns (bool);
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external returns (bool);
  function setImplementationAddressOneToOne(address proxyAddress, address implementation) external returns (bool);
  function deployProxyOneToOne(bytes32 suppliedSalt, address implementation) external returns(address proxyAddress);
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";


interface IBisharesUniswapV2Oracle {
  function hasPriceObservationInWindow(address token, uint256 priceKey) external view returns (bool);
  function getPriceObservationInWindow(
    address token, uint256 priceKey
  ) external view returns (PriceLibrary.PriceObservation memory);
  function getPriceObservationsInRange(
    address token, uint256 timeFrom, uint256 timeTo
  ) external view returns (PriceLibrary.PriceObservation[] memory prices);
  function canUpdatePrice(address token) external view returns (bool);
  function canUpdatePrices(address[] memory tokens) external view returns (bool[] memory);
  function computeTwoWayAveragePrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice memory);
  function computeAverageTokenPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);
  function computeAverageEthPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);
  function computeTwoWayAveragePrices(
    address[] memory tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice[] memory);
  function computeAverageTokenPrices(
    address[] memory tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);
  function computeAverageEthPrices(
    address[] memory tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);
  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);
  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);
  function computeAverageEthForTokens(
    address[] memory tokens,
    uint256[] memory tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);
  function computeAverageTokensForEth(
    address[] memory tokens,
    uint256[] memory wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);

  function updatePrice(address token) external returns (bool);
  function updatePrices(address[] memory tokens) external returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/GSN/Context.sol";

contract OwnableProxy is Context {
  address private _owner;

  function owner() public view returns (address) {
    return _owner;
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // For implementation owner
  constructor() {
    _transferOwnership(_msgSender());
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "BiShares: New owner is zero address");
    _transferOwnership(newOwner);
  }

  // For proxy owner
  function _initializeOwnership() internal {
    require(_owner == address(0), "BiShares: Owner has already been initialized");
    _transferOwnership(_msgSender());
  }

  function _transferOwnership(address newOwner) private {
    address previousOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "BiShares: Caller is not the owner");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OwnableProxy.sol";
import "../interfaces/IBisharesUniswapV2Oracle.sol";
import "../lib/FixedPoint.sol";


contract MarketCapSortedTokenCategories is OwnableProxy {
  uint32 internal constant LONG_TWAP_MIN_TIME_ELAPSED = 1 days;
  uint32 internal constant LONG_TWAP_MAX_TIME_ELAPSED = 1.5 weeks;
  uint32 internal constant SHORT_TWAP_MIN_TIME_ELAPSED = 20 minutes;
  uint32 internal constant SHORT_TWAP_MAX_TIME_ELAPSED = 2 days;
  uint256 internal constant MAX_SORT_DELAY = 1 days;
  uint256 internal constant MAX_CATEGORY_TOKENS = 25;

  uint256 public categoryIndex;
  mapping(uint256 => IBisharesUniswapV2Oracle) internal _categoryOracles;
  mapping(uint256 => address) internal _categoryRouters;
  mapping(uint256 => address[]) internal _categoryTokens;
  mapping(uint256 => mapping(address => FixedPoint.uq112x112)) internal _categoryTokensInitialWeights;
  mapping(uint256 => mapping(address => bool)) internal _isCategoryToken;
  mapping(uint256 => uint256) internal _lastCategoryUpdate;

  function computeAverageMarketCap(
    address token,
    IBisharesUniswapV2Oracle oracle
  ) external view returns (uint144) {
    uint256 totalSupply = IERC20(token).totalSupply();
    return oracle.computeAverageEthForTokens(
      token,
      totalSupply,
      LONG_TWAP_MIN_TIME_ELAPSED,
      LONG_TWAP_MAX_TIME_ELAPSED
    ); 
  }

  function computeAverageMarketCaps(
    address[] memory tokens,
    IBisharesUniswapV2Oracle oracle
  ) public view returns (uint144[] memory marketCaps) {
    uint256 len = tokens.length;
    uint256[] memory totalSupplies = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      totalSupplies[i] = IERC20(tokens[i]).totalSupply();
    }
    marketCaps = oracle.computeAverageEthForTokens(
      tokens,
      totalSupplies,
      LONG_TWAP_MIN_TIME_ELAPSED,
      LONG_TWAP_MAX_TIME_ELAPSED
    );
  }

  function hasCategory(uint256 categoryID) external view returns (bool) {
    return categoryID <= categoryIndex && categoryID > 0;
  }

  function getLastCategoryUpdate(uint256 categoryID) external view validCategory(categoryID) returns (uint256) {
    return _lastCategoryUpdate[categoryID];
  }

  function isTokenInCategory(
    uint256 categoryID,
    address token
  ) external view validCategory(categoryID) returns (bool) {
    return _isCategoryToken[categoryID][token];
  }

  function getCategoryTokens(uint256 categoryID) external view validCategory(categoryID) returns (address[] memory) {
    return _categoryTokens[categoryID];
  }

  function getCategoryTokensInitialWeights(
    uint256 categoryID
  ) external view validCategory(categoryID) returns (FixedPoint.uq112x112[] memory weights) {
    address[] storage _tokens = _categoryTokens[categoryID];
    weights = new FixedPoint.uq112x112[](_tokens.length);
    for (uint256 i = 0; i < weights.length; i++) {
      weights[i] = _categoryTokensInitialWeights[categoryID][_tokens[i]];
    }
  }

  function getCategoryMarketCaps(
    uint256 categoryID
  ) external view validCategory(categoryID) returns (uint144[] memory) {
    return computeAverageMarketCaps(_categoryTokens[categoryID], _categoryOracles[categoryID]);
  }

  function getTopCategoryTokens(
    uint256 categoryID,
    uint256 num
  ) public view validCategory(categoryID) returns (address[] memory tokens)
  {
    address[] storage categoryTokens = _categoryTokens[categoryID];
    require(num <= categoryTokens.length, "BiShares: Category size overflow");
    require(block.timestamp - _lastCategoryUpdate[categoryID] <= MAX_SORT_DELAY, "BiShares: Category not ready");
    tokens = new address[](num);
    for (uint256 i = 0; i < num; i++) tokens[i] = categoryTokens[i];
  }

  function getTopCategoryTokensInitialWeights(
    uint256 categoryID,
    uint256 num
  ) public view validCategory(categoryID) returns (FixedPoint.uq112x112[] memory weights) {
    address[] storage categoryTokens = _categoryTokens[categoryID];
    require(num <= categoryTokens.length, "BiShares: Category size overflow");
    require(block.timestamp - _lastCategoryUpdate[categoryID] <= MAX_SORT_DELAY, "BiShares: Category not ready");
    weights = new FixedPoint.uq112x112[](num);
    for (uint256 i = 0; i < num; i++) weights[i] = _categoryTokensInitialWeights[categoryID][categoryTokens[i]];
  }

  event CategoryAdded(uint256 categoryID, bytes32 metadataHash);
  event CategorySorted(uint256 categoryID);
  event TokenAdded(address token, uint256 categoryID);
  event TokenRemoved(address token, uint256 categoryID);

  constructor() OwnableProxy() {}

  function initialize() public virtual returns (bool) {
    _initializeOwnership();
    return true;
  }

  function updateCategoryPrices(
    uint256 categoryID
  ) external validCategory(categoryID) returns (bool[] memory pricesUpdated) {
    address[] memory tokens = _categoryTokens[categoryID];
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID];
    pricesUpdated = oracle.updatePrices(tokens);
  }

  function createCategory(
    bytes32 metadataHash,
    IBisharesUniswapV2Oracle oracle,
    address router
  ) external onlyOwner returns (bool) {
    address zero = address(0);
    require(address(oracle) != zero, "BiShares: Oracle is zero address");
    require(router != zero, "BiShares: Router is zero address");
    uint256 categoryID = ++categoryIndex;
    _categoryOracles[categoryID] = oracle;
    _categoryRouters[categoryID] = router;
    emit CategoryAdded(categoryID, metadataHash);
    return true;
  }

  function addToken(
    uint256 categoryID,
    address token,
    FixedPoint.uq112x112 memory weight
  ) external onlyOwner validCategory(categoryID) returns (bool) {
    require(_categoryTokens[categoryID].length < MAX_CATEGORY_TOKENS, "BiShares: Max category tokens overflow");
    _addToken(categoryID, token, weight);
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID]; 
    oracle.updatePrice(token);
    _lastCategoryUpdate[categoryID] -= MAX_SORT_DELAY;
    return true;
  }

  function addTokens(
    uint256 categoryID,
    address[] memory tokens,
    FixedPoint.uq112x112[] memory weights
  ) external onlyOwner validCategory(categoryID) returns (bool) {
    uint256 len = tokens.length;
    require(
      _categoryTokens[categoryID].length + len <= MAX_CATEGORY_TOKENS,
      "BiShares: Max category tokens overflow"
    );
    require(weights.length == len, "BiShares: Invalid arrays length");
    for (uint256 i = 0; i < len; i++) {
      _addToken(categoryID, tokens[i], weights[i]);
    }
    _categoryOracles[categoryID].updatePrices(tokens);
    _lastCategoryUpdate[categoryID] -= MAX_SORT_DELAY;
    return true;
  }

  function removeToken(
    uint256 categoryID,
    address token
  ) external onlyOwner validCategory(categoryID) returns (bool) {
    uint256 i = 0;
    uint256 len = _categoryTokens[categoryID].length;
    require(len > 0, "BiShares: Category is empty");
    require(_isCategoryToken[categoryID][token], "BiShares: Token not bound");
    _isCategoryToken[categoryID][token] = false;
    for (; i < len; i++) {
      if (_categoryTokens[categoryID][i] == token) {
        uint256 last = len - 1;
        if (i != last) {
          address lastToken = _categoryTokens[categoryID][last];
          _categoryTokens[categoryID][i] = lastToken;
        }
        _lastCategoryUpdate[categoryID] -= MAX_SORT_DELAY;
        _categoryTokens[categoryID].pop();
        _categoryTokensInitialWeights[categoryID][token] = FixedPoint.uq112x112(0);
        emit TokenRemoved(token, categoryID);
        break;
      }
    }
    return true;
  }

  function orderCategoryTokensByMarketCap(uint256 categoryID) external validCategory(categoryID) returns (bool) {
    address[] memory categoryTokens = _categoryTokens[categoryID];
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID];
    uint256 len = categoryTokens.length;
    uint144[] memory marketCaps = computeAverageMarketCaps(categoryTokens, oracle);
    for (uint256 i = 1; i < len; i++) {
      uint144 cap = marketCaps[i];
      address token = categoryTokens[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && marketCaps[j] < cap) {
        marketCaps[j + 1] = marketCaps[j];
        categoryTokens[j + 1] = categoryTokens[j];
        j--;
      }
      marketCaps[j + 1] = cap;
      categoryTokens[j + 1] = token;
    }
    _categoryTokens[categoryID] = categoryTokens;
    _lastCategoryUpdate[categoryID] = block.timestamp;
    emit CategorySorted(categoryID);
    return true;
  }

  function _addToken(uint256 categoryID, address token, FixedPoint.uq112x112 memory weight) internal {
    require(!_isCategoryToken[categoryID][token], "BiShares: Token not bound");
    require(weight._x != 0, "BiShares: Weight is zero");
    _isCategoryToken[categoryID][token] = true;
    _categoryTokens[categoryID].push(token);
    _categoryTokensInitialWeights[categoryID][token] = weight;
    emit TokenAdded(token, categoryID);
  }

  modifier validCategory(uint256 categoryID) {
    require(categoryID <= categoryIndex && categoryID > 0, "BiShares: Invalid category id");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";