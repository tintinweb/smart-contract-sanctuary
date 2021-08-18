/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;


contract IndexedRebalanceLens {
  using DynamicArrays for address[];

  enum IndexVersion { NONE, CORE, SIGMA }
  enum RebalanceType { REWEIGH, REINDEX }
  enum Troolean { UNKNOWN, TRUE, FALSE }

  struct IndexInfo {
    IPool pool;
    IndexVersion version;
    RebalanceType next;
  }

  struct RebalanceRequirements {
    bool delayOK;
    bool twapOK;
    bool sortOK;
    Troolean tokenCountOK;
    Troolean strategyOK;
  }

  uint256 internal constant MAX_SORT_DELAY = 1 days;
  uint256 internal constant POOL_REWEIGH_DELAY = 1 weeks;

  uint32 internal constant SHORT_MIN = 20 minutes;
  uint32 internal constant SHORT_MAX = 2 days;

  uint32 internal constant LONG_MIN = 1 days;
  uint32 internal constant LONG_MAX = 1.5 weeks;

  ICoreController public constant CORE_CONTROLLER = ICoreController(0xF00A38376C8668fC1f3Cd3dAeef42E0E44A7Fcdb);
  ISigmaController public constant SIGMA_CONTROLLER = ISigmaController(0x5B470A8C134D397466A1a603678DadDa678CBC29);
  IOracle public constant ORACLE = IOracle(0xFa5a44D3Ba93D666Bf29C8804a36e725ecAc659A);

  function init(IndexInfo memory info) internal view {
    address controller = info.pool.getController();
    info.version =
      controller == address(CORE_CONTROLLER)
        ? IndexVersion.CORE
        : controller == address(SIGMA_CONTROLLER)
          ? IndexVersion.SIGMA
          : IndexVersion.NONE;
  }

  function timeSince(uint256 ts) internal view returns (uint256) {
    return block.timestamp - ts;
  }

  function checkUpdateNeeded(address token, uint256 min, uint256 max) public view returns (bool needsUpdate) {
    try ORACLE.computeAverageEthPrice(token, min, max) returns (IOracle.uq112x112 memory) {
      return false;
    } catch {
      return true;
    }
  }

  function checkUpdateNeeded(
    address[] memory tokens,
    uint256 min,
    uint256 max
  ) public view returns (address[] memory needUpdate) {
    uint256 len = tokens.length;
    needUpdate = DynamicArrays.dynamicAddressArray(len + 1);
    for (uint256 i; i < len; i++) {
      address token = tokens[i];
      if (checkUpdateNeeded(token, min, max)) {
        needUpdate.dynamicPush(token);
      }
    }
  }

  function checkCurrentTokens(
    IPool pool,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) internal view returns (address[] memory tokensNeedingUpdate) {
    tokensNeedingUpdate = checkUpdateNeeded(
      pool.getCurrentTokens(),
      minTimeElapsed,
      maxTimeElapsed
    );
  }

  function getPoolStatus(address pool) external view returns (
    IndexInfo memory info,
    RebalanceRequirements memory reqs,
    address[] memory tokensNeedingUpdate
  ) {
    info.pool = IPool(pool);
    init(info);
    require(info.version != IndexVersion.NONE, "Invalid pool");
    if (info.version == IndexVersion.CORE) {
      (reqs, tokensNeedingUpdate) = checkCorePool(info);
    } else {
      (reqs, tokensNeedingUpdate) = checkSigmaPool(info);
    }
  }

  function troolify(bool b) internal pure returns (Troolean) {
    return b ? Troolean.TRUE : Troolean.FALSE;
  }

  function checkCorePool(IndexInfo memory info)
    internal
    view
    returns (RebalanceRequirements memory reqs, address[] memory tokensNeedingUpdate)
  {
    ICoreController.IndexPoolMeta memory meta = CORE_CONTROLLER.getPoolMeta(address(info.pool));
    info.next = meta.reweighIndex % 4 == 3 ? RebalanceType.REINDEX : RebalanceType.REWEIGH;
    reqs.delayOK = timeSince(meta.lastReweigh) >= POOL_REWEIGH_DELAY;
    reqs.strategyOK = Troolean.TRUE;
    if (info.next == RebalanceType.REWEIGH) {
      tokensNeedingUpdate = checkCurrentTokens(info.pool, LONG_MIN, LONG_MAX);
      reqs.tokenCountOK = Troolean.TRUE;
    } else {
      address[] memory categoryTokens = CORE_CONTROLLER.getCategoryTokens(meta.categoryID);
      tokensNeedingUpdate = checkUpdateNeeded(
        categoryTokens,
        LONG_MIN,
        LONG_MAX
      );
      reqs.sortOK = timeSince(CORE_CONTROLLER.getLastCategoryUpdate(meta.categoryID)) <= MAX_SORT_DELAY;
      reqs.tokenCountOK = troolify(categoryTokens.length >= meta.indexSize);
      (address eToken,) = info.pool.extrapolatePoolValueFromToken();
      if (!tokensNeedingUpdate.includes(eToken)) {
        if (checkUpdateNeeded(eToken, SHORT_MIN, SHORT_MAX)) {
          tokensNeedingUpdate.dynamicPush(eToken);
        }
      }
    }
    reqs.twapOK = tokensNeedingUpdate.length == 0;
  }

  function tryGetScores(
    address strategy,
    address[] memory tokens
  ) internal view returns (uint256[] memory scores) {
    try IScoringStrategy(strategy).getTokenScores(tokens) returns (uint256[] memory _scores) {
      scores = _scores;
    } catch {}
  }

  // Used to reduce stack overhead
  struct SigmaMeta {
    uint16 listID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
    address strategy;
    uint256 minScore;
    uint256 maxScore;
  }

  function getSigmaMeta(address pool) internal view returns (SigmaMeta memory meta) {
    ISigmaController.IndexPoolMeta memory _meta = SIGMA_CONTROLLER.indexPoolMetadata(pool);
    meta.listID = _meta.listID;
    meta.indexSize = _meta.indexSize;
    meta.reweighIndex = _meta.reweighIndex;
    meta.lastReweigh = _meta.lastReweigh;
    (meta.strategy, meta.minScore, meta.maxScore) = SIGMA_CONTROLLER.getTokenListConfig(_meta.listID);
  }

  function checkSigmaScores(SigmaMeta memory meta) internal view returns (Troolean strategyOK, Troolean tokenCountOK) {
    address[] memory categoryTokens = SIGMA_CONTROLLER.getTokenList(meta.listID);
    uint256[] memory scores = tryGetScores(meta.strategy, categoryTokens);
    strategyOK = troolify(scores.length > 0);
    if (strategyOK == Troolean.FALSE) {
      tokenCountOK = Troolean.UNKNOWN;
    } else {
      uint256 numValid;
      for (uint256 i; i < scores.length; i++) {
        uint256 score = scores[i];
        if (score >= meta.minScore && score <= meta.maxScore) {
          numValid++;
        }
      }
      tokenCountOK = troolify(numValid >= meta.indexSize);
    }
  }

  function checkSigmaPool(IndexInfo memory info)
    internal
    view
    returns (RebalanceRequirements memory reqs, address[] memory tokensNeedingUpdate)
  {
    reqs.sortOK = true;
    SigmaMeta memory meta = getSigmaMeta(address(info.pool));
    info.next = meta.reweighIndex % 4 == 3 ? RebalanceType.REINDEX : RebalanceType.REWEIGH;
    reqs.delayOK = timeSince(meta.lastReweigh) >= POOL_REWEIGH_DELAY;
    if (info.next == RebalanceType.REWEIGH) {
      reqs.tokenCountOK = Troolean.TRUE;
      address[] memory poolTokens = info.pool.getCurrentTokens();
      tokensNeedingUpdate = checkUpdateNeeded(poolTokens, SHORT_MIN, SHORT_MAX);
      if (tokensNeedingUpdate.length == 0) {
        uint256[] memory scores = tryGetScores(meta.strategy, poolTokens);
        reqs.strategyOK = troolify(scores.length > 0);
      } else {
        reqs.strategyOK = Troolean.UNKNOWN;
      }
    } else {
      address[] memory categoryTokens = SIGMA_CONTROLLER.getTokenList(meta.listID);
      tokensNeedingUpdate = checkUpdateNeeded(
        categoryTokens,
        LONG_MIN,
        LONG_MAX
      );
      (address eToken,) = info.pool.extrapolatePoolValueFromToken();
      if (!tokensNeedingUpdate.includes(eToken)) {
        if (checkUpdateNeeded(eToken, SHORT_MIN, SHORT_MAX)) {
          tokensNeedingUpdate.dynamicPush(eToken);
        }
      }
      // If prices are ready, check if scores can be queried.
      // If scores can be queried, tokenCountOK = # of scores between min/max scores >= meta.indexSize.
      // If scores can not be queried, strategyOK = false
      // If prices are not ready, strategyOK and tokenCountOK both UNKNOWN
      if (tokensNeedingUpdate.length == 0) {
        (reqs.strategyOK, reqs.tokenCountOK) = checkSigmaScores(meta);
      } else {
        reqs.strategyOK = Troolean.UNKNOWN;
        reqs.tokenCountOK = Troolean.UNKNOWN;
      }
    }
    reqs.twapOK = tokensNeedingUpdate.length == 0;
  }
}


interface IScoringStrategy {
  function getTokenScores(address[] calldata tokens) external view returns (uint256[] memory scores);
}


interface IOracle {
  struct uq112x112 { uint224 _x; }

  function computeAverageEthPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (uq112x112 memory);
}


interface IPool {
  function getController() external view returns (address);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function extrapolatePoolValueFromToken() external view returns (address/* token */, uint256/* extrapolatedValue */);
}


interface ISigmaController {
  struct IndexPoolMeta {
    bool initialized;
    uint16 listID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
  }

  function indexPoolMetadata(address) external view returns (IndexPoolMeta memory);

  function getTokenList(uint256 listID) external view returns (address[] memory tokens);

  function getTokenListConfig(uint256 listID)
    external
    view
    returns (
      address scoringStrategy,
      uint128 minimumScore,
      uint128 maximumScore
    );
}

interface ICoreController {
  struct IndexPoolMeta {
    bool initialized;
    uint16 categoryID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
  }
  function getPoolMeta(address poolAddress) external view returns (IndexPoolMeta memory meta);

  function getLastCategoryUpdate(uint256 categoryID) external view returns (uint256);

  function getCategoryTokens(uint256 categoryID) external view returns (address[] memory tokens);
}


library DynamicArrays {
  /**
   * @dev Reserves space in memory for an array of length `size`, but sets the length to 0.
   * This can be safely used for a dynamic array so long as the maximum possible size is
   * known beforehand. If the array can exceed `size`, pushing to it will corrupt memory.
   */
  function dynamicAddressArray(uint256 size) internal pure returns (address[] memory arr) {
    arr = new address[](size);
    assembly { mstore(arr, 0) }
  }

  /**
   * @dev Reserves space in memory for an array of length `size`, but sets the length to 0.
   * This can be safely used for a dynamic array so long as the maximum possible size is
   * known beforehand. If the array can exceed length `size`, pushing to it will corrupt memory.
   */
  function dynamicUint256Array(uint256 size) internal pure returns (uint256[] memory arr) {
    arr = new uint256[](size);
    assembly { mstore(arr, 0) }
  }

  /**
   * @dev Pushes an address to an in-memory array by reassigning the array length and storing
   * the element in the position used by solidity for the current array index.
   * Note: This should ONLY be used on an array created with `dynamicAddressArray`. Using it
   * on a typical array created with `new address[]()` will almost certainly have unintended
   * and unpredictable side effects.
   */
  function dynamicPush(address[] memory arr, address element) internal pure {
    assembly {
      let size := mload(arr)
      let ptr := add(
        add(arr, 32),
        mul(size, 32)
      )
      mstore(ptr, element)
      mstore(arr, add(size, 1))
    }
  }

  /**
   * @dev Pushes a uint256 to an in-memory array by reassigning the array length and storing
   * the element in the position used by solidity for the current array index.
   * Note: This should ONLY be used on an array created with `dynamicUint256Array`. Using it
   * on a typical array created with `new uint256[]()` will almost certainly have unintended
   * and unpredictable side effects.
   */
  function dynamicPush(uint256[] memory arr, uint256 element) internal pure {
    assembly {
      let size := mload(arr)
      let ptr := add(
        add(arr, 32),
        mul(size, 32)
      )
      mstore(ptr, element)
      mstore(arr, add(size, 1))
    }
  }

  function includes(address[] memory arr, address find) internal pure returns (bool) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return true;
    return false;
  }
}