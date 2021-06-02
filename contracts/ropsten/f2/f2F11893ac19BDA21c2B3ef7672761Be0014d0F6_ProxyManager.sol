// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableInternal.sol';

import '../pair/Pair.sol';
import '../pair/PairProxy.sol';
import './IProxyManager.sol';
import './ProxyManagerStorage.sol';

/**
 * @title Options pair management contract
 * @dev deployed standalone and connected to Median as diamond facet
 */
contract ProxyManager is IProxyManager, OwnableInternal {
  using ProxyManagerStorage for ProxyManagerStorage.Layout;

  event PairDeployment (address pair);

  /**
   * @notice get address of Pair implementation contract for forwarding via PairProxy
   * @return implementation address
   */
  function getPairImplementation () override external view returns (address) {
    return ProxyManagerStorage.layout().pairImplementation;
  }

  /**
   * @notice get address of Pool implementation contract for forwarding via PoolProxy
   * @return implementation address
   */
  function getPoolImplementation () override external view returns (address) {
    return ProxyManagerStorage.layout().poolImplementation;
  }

  /**
   * @notice get address of Pair contract for given assets
   * @param asset0 asset in pair
   * @param asset1 asset in pair
   * @return pair address (zero address if pair does not exist)
   */
  function getPair (
    address asset0,
    address asset1
  ) external view returns (address) {
    return ProxyManagerStorage.layout().getPair(asset0, asset1);
  }

  function getOwner () external view returns (address) {
    return  OwnableStorage.layout().owner;
  }

  /**
   * @notice deploy PairProxy contract
   * @param asset0 asset in pair
   * @param asset1 asset in pair
   * @param oracle0 Chainlink price aggregator for asset0
   * @param oracle1 Chainlink price aggregator for asset1
   * TODO: unrestrict
   * @return deployment address
   */
  function deployPair (
    address asset0,
    address asset1,
    address oracle0,
    address oracle1
  ) external onlyOwner returns (address) {
    PairProxy pair = new PairProxy(
      asset0,
      asset1,
      oracle0,
      oracle1
    );

    ProxyManagerStorage.layout().setPair(asset0, asset1, address(pair));
    emit PairDeployment(address(pair));
    return address(pair);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './OwnableStorage.sol';

abstract contract OwnableInternal {
  using OwnableStorage for OwnableStorage.Layout;

  modifier onlyOwner {
    require(
      msg.sender == OwnableStorage.layout().owner,
      'Ownable: sender must be owner'
    );
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@solidstate/contracts/access/OwnableInternal.sol';

import './IPair.sol';
import './PairStorage.sol';

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';
import { OptionMath } from '../libraries/OptionMath.sol';

/**
 * @title Median options pair
 * @dev deployed standalone and referenced by PairProxy
 */
contract Pair is IPair, OwnableInternal {
  using ABDKMath64x64 for int128;
  using PairStorage for PairStorage.Layout;

  /**
   * @notice get addresses of PoolProxy contracts
   * @return pool addresses
   */
  function getPools () external view returns (address, address) {
    return PairStorage.layout().getPools();
  }

  /**
   * TODO: define base and underlying
   * @inheritdoc IPair
   */
  function updateAndGetLatestData () override external returns (int128 price64x64, int128 variance64x64) {
    _update();
    PairStorage.Layout storage l = PairStorage.layout();
    price64x64 = l.getPriceUpdate(block.timestamp);
    variance64x64 = l.emaVarianceAnnualized64x64;
  }

  /**
   * TODO: define base and underlying
   * @inheritdoc IPair
   */
  function updateAndGetHistoricalPrice (
    uint256 timestamp
  ) override external returns (int128 price64x64) {
    _update();
    price64x64 = PairStorage.layout().getPriceUpdateAfter(timestamp);
  }

  /**
   * @notice fetch latest price from given oracle
   * @param oracle Chainlink price aggregator address
   * @return price latest price
   */
  function _fetchLatestPrice (
    address oracle
  ) internal view returns (int256 price) {
    (, price, , ,) = AggregatorV3Interface(oracle).latestRoundData();
  }

  /**
   * @notice TODO
   */
  function _update () internal {
    PairStorage.Layout storage l = PairStorage.layout();

    uint256 updatedAt = l.updatedAt;

    int128 oldPrice64x64 = l.getPriceUpdate(updatedAt);
    int128 newPrice64x64 = ABDKMath64x64.divi(
      _fetchLatestPrice(l.oracle0),
      _fetchLatestPrice(l.oracle1)
    );

    if (l.getPriceUpdate(block.timestamp) == 0) {
      l.setPriceUpdate(block.timestamp, newPrice64x64);
    }

    int128 logReturns64x64 = newPrice64x64.div(oldPrice64x64).ln();
    int128 oldEmaLogReturns64x64 = l.emaLogReturns64x64;

    l.emaLogReturns64x64 = OptionMath.unevenRollingEma(
      oldEmaLogReturns64x64,
      logReturns64x64,
      updatedAt,
      block.timestamp
    );

    l.emaVarianceAnnualized64x64 = OptionMath.unevenRollingEmaVariance(
      oldEmaLogReturns64x64,
      l.emaVarianceAnnualized64x64 / 365,
      logReturns64x64,
      updatedAt,
      block.timestamp
    ) * 365;

    l.updatedAt = block.timestamp;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableStorage.sol';
import '@solidstate/contracts/proxy/managed/ManagedProxyOwnable.sol';

import '../core/IProxyManager.sol';
import '../pool/PoolProxy.sol';
import './PairStorage.sol';

/**
 * @title Upgradeable proxy with centrally controlled Pair implementation
 */
contract PairProxy is ManagedProxyOwnable {
  using PairStorage for PairStorage.Layout;

  constructor (
    address asset0,
    address asset1,
    address oracle0,
    address oracle1
  ) ManagedProxy(IProxyManager.getPairImplementation.selector) {
    OwnableStorage.layout().owner = msg.sender;

    PoolProxy pool0 = new PoolProxy(msg.sender, asset0, asset1);
    PoolProxy pool1 = new PoolProxy(msg.sender, asset1, asset0);

    PairStorage.Layout storage l = PairStorage.layout();
    l.asset0 = asset0;
    l.asset1 = asset1;
    l.setOracles(oracle0, oracle1);
    l.setPools(address(pool0), address(pool1));
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IProxyManager {
  function getPairImplementation () external view returns (address);
  function getPoolImplementation () external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library ProxyManagerStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'median.contracts.storage.ProxyManager'
  );

  struct Layout {
    address pairImplementation;
    address poolImplementation;
    mapping (address => mapping (address => address)) pairs;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function getPair (
    Layout storage l,
    address asset0,
    address asset1
  ) internal view returns (address) {
    if (asset0 > asset1) {
      (asset0, asset1) = (asset1, asset0);
    }

    return l.pairs[asset0][asset1];
  }

  function setPair (
    Layout storage l,
    address asset0,
    address asset1,
    address pair
  ) internal {
    if (asset0 > asset1) {
      (asset0, asset1) = (asset1, asset0);
    }

    l.pairs[asset0][asset1] = pair;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.Ownable'
  );

  struct Layout {
    address owner;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function setOwner (
    Layout storage l,
    address owner
  ) internal {
    l.owner = owner;
  }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPair {
  /**
   * @notice update cache and get most recent price and variance
   * @return price64x64 64x64 fixed point representation of price
   * @return variance64x64 64x64 fixed point representation of EMA of annualized variance
   */
  function updateAndGetLatestData () external returns (int128 price64x64, int128 variance64x64);

  /**
   * @notice update cache and get price for given timestamp
   * @param timestamp timestamp of price to query
   * @return price64x64 64x64 fixed point representation of price
   */
  function updateAndGetHistoricalPrice (
    uint256 timestamp
  ) external returns (int128 price64x64);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PairStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'median.contracts.storage.Pair'
  );

  struct Layout {
    // TODO: ordering of assets (and oracles and pools)
    address asset0;
    address asset1;
    address oracle0;
    address oracle1;
    address pool0;
    address pool1;

    uint256 updatedAt;

    int128 emaLogReturns64x64;
    int128 emaVarianceAnnualized64x64;

    // TODO: enforced interval size for maturity (maturity % interval == 0)
    // updatable by owner

    // minimum resolution price bucket => price
    mapping (uint256 => int128) bucketPrices64x64;
    // sequence id (minimum resolution price bucket / 256) => price update sequence
    mapping (uint256 => uint256) priceUpdateSequences;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function getPools (
    Layout storage l
  ) internal view returns (address, address) {
    return (l.pool0, l.pool1);
  }

  function setOracles(
    Layout storage l,
    address oracle0,
    address oracle1
  ) internal {
    require(
      AggregatorV3Interface(oracle0).decimals() == AggregatorV3Interface(oracle1).decimals(),
      'Pair: oracle decimals must match'
    );

    l.oracle0 = oracle0;
    l.oracle1 = oracle1;
  }

  function setPools (
    Layout storage l,
    address pool0,
    address pool1
  ) internal {
    l.pool0 = pool0;
    l.pool1 = pool1;
  }

  function setPriceUpdate (
    Layout storage l,
    uint timestamp,
    int128 price64x64
  ) internal {
    // TODO: check for off-by-one errors
    uint bucket = timestamp / (1 hours);
    l.bucketPrices64x64[bucket] = price64x64;
    l.priceUpdateSequences[bucket >> 8] += 1 << 256 - (bucket & 255);
  }

  function getPriceUpdate (
    Layout storage l,
    uint timestamp
  ) internal view returns (int128) {
    return l.bucketPrices64x64[timestamp / (1 hours)];
  }

  function getPriceUpdateAfter (
    Layout storage l,
    uint timestamp
  ) internal view returns (int128) {
    // TODO: check for off-by-one errors
    uint bucket = timestamp / (1 hours);
    uint sequenceId = bucket >> 8;
    // shift to skip buckets from earlier in sequence
    uint offset = bucket & 255;
    uint sequence = l.priceUpdateSequences[sequenceId] << offset >> offset;

    uint currentPriceUpdateSequenceId = block.timestamp / (256 hours);

    while (sequence == 0 && sequenceId <= currentPriceUpdateSequenceId) {
      sequence = l.priceUpdateSequences[++sequenceId];
    }

    if (sequence == 0) {
      // TODO: no price update found; continuing function will return 0 anyway
      return 0;
    }

    uint256 msb; // most significant bit

    for (uint256 i = 128; i > 0; i >> 1) {
      if (sequence >> i > 0) {
        msb += i;
        sequence >>= i;
      }
    }

    return l.bucketPrices64x64[(sequenceId + 1 << 8) - msb];
  }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

library OptionMath {
  using ABDKMath64x64 for int128;

  // 64x64 fixed point integer constants
  int128 internal constant ONE_64x64 = 0x10000000000000000;
  int128 internal constant THREE_64x64 = 0x30000000000000000;

  // 64x64 fixed point representation of 2e
  int128 internal constant INITIAL_C_LEVEL_64x64 = 0x56fc2a2c515da32ea;

  // 64x64 fixed point constants used in Choudhury’s approximation of the Black-Scholes CDF
  int128 private constant CDF_CONST_0 = 0x09109f285df452394; // 2260 / 3989
  int128 private constant CDF_CONST_1 = 0x19abac0ea1da65036; // 6400 / 3989
  int128 private constant CDF_CONST_2 = 0x0d3c84b78b749bd6b; // 3300 / 3989

  /**
   * @notice calculate the exponential decay coefficient for a given interval
   * @param oldTimestamp timestamp of previous update
   * @param newTimestamp current timestamp
   * @return 64x64 fixed point representation of exponential decay coefficient
   */
  function decay (
    uint256 oldTimestamp,
    uint256 newTimestamp
  ) internal pure returns (int128) {
    return ONE_64x64.sub(
      (-ABDKMath64x64.divu(newTimestamp - oldTimestamp, 7 days)).exp()
    );
  }

  /**
   * @notice calculate the rolling EMA of an uneven time series
   * @param oldEmaLogReturns64x64 64x64 fixed point representation of previous EMA
   * @param logReturns64x64 64x64 fixed point representation of natural log of rate of return for current period
   * @param oldTimestamp timestamp of previous update
   * @param newTimestamp current timestamp
   * @return 64x64 fixed point representation of EMA
   */
  function unevenRollingEma (
    int128 oldEmaLogReturns64x64,
    int128 logReturns64x64,
    uint256 oldTimestamp,
    uint256 newTimestamp
  ) internal pure returns (int128) {
    int128 decay64x64 = decay(oldTimestamp, newTimestamp);

    return logReturns64x64.mul(decay64x64).add(
      ONE_64x64.sub(decay64x64).mul(oldEmaLogReturns64x64)
    );
  }

  /**
   * @notice calculate the rolling EMA variance of an uneven time series
   * @param oldEmaLogReturns64x64 64x64 fixed point representation of previous EMA
   * @param oldEmaVariance64x64 64x64 fixed point representation of previous variance
   * @param logReturns64x64 64x64 fixed point representation of natural log of rate of return for current period
   * @param oldTimestamp timestamp of previous update
   * @param newTimestamp current timestamp
   * @return 64x64 fixed point representation of EMA of variance
   */
  function unevenRollingEmaVariance (
    int128 oldEmaLogReturns64x64,
    int128 oldEmaVariance64x64,
    int128 logReturns64x64,
    uint256 oldTimestamp,
    uint256 newTimestamp
  ) internal pure returns (int128) {
    int128 decay64x64 = decay(oldTimestamp, newTimestamp);
    int128 difference64x64 = logReturns64x64.sub(oldEmaLogReturns64x64);

    return ONE_64x64.sub(decay64x64).mul(
      // squaring via mul is cheaper than via pow
      decay64x64.mul(difference64x64).mul(difference64x64).add(oldEmaVariance64x64)
    );
  }

  /**
   * @notice calculate Choudhury’s approximation of the Black-Scholes CDF
   * @param input64x64 64x64 fixed point representation of random variable
   * @return 64x64 fixed point representation of the approximated CDF of x
   */
  function N (
    int128 input64x64
  ) internal pure returns (int128) {
    // squaring via mul is cheaper than via pow
    int128 inputSquared64x64 = input64x64.mul(input64x64);

    int128 value64x64 = (-inputSquared64x64 >> 1).exp().div(
      CDF_CONST_0.add(
        CDF_CONST_1.mul(input64x64.abs())
      ).add(
        CDF_CONST_2.mul(inputSquared64x64.add(THREE_64x64).sqrt())
      )
    );

    return input64x64 > 0 ? ONE_64x64.sub(value64x64) : value64x64;
  }

  /**
   * @notice calculate the price of an option using the Black-Scholes model
   * @param emaVarianceAnnualized64x64 64x64 fixed point representation of annualized EMA of variance
   * @param strike64x64 64x64 fixed point representation of strike price
   * @param spot64x64 64x64 fixed point representation of spot price
   * @param timeToMaturity64x64 64x64 fixed point representation of duration of option contract (in years)
   * @param isCall whether to price "call" or "put" option
   * @return 64x64 fixed point representation of Black-Scholes option price
   */
  function bsPrice (
    int128 emaVarianceAnnualized64x64,
    int128 strike64x64,
    int128 spot64x64,
    int128 timeToMaturity64x64,
    bool isCall
  ) internal pure returns (int128) {
    int128 cumulativeVariance64x64 = timeToMaturity64x64.mul(emaVarianceAnnualized64x64);
    int128 cumulativeVarianceSqrt64x64 = cumulativeVariance64x64.sqrt();

    int128 d1_64x64 = spot64x64.div(strike64x64).ln().add(cumulativeVariance64x64 >> 1).div(cumulativeVarianceSqrt64x64);
    int128 d2_64x64 = d1_64x64.sub(cumulativeVarianceSqrt64x64);

    if (isCall) {
      return spot64x64.mul(N(d1_64x64)).sub(strike64x64.mul(N(d2_64x64)));
    } else {
      return -spot64x64.mul(N(-d1_64x64)).sub(strike64x64.mul(N(-d2_64x64)));
    }
  }

  /**
   * @notice recalculate C-Level based on change in liquidity
   * @param initialCLevel64x64 64x64 fixed point representation of C-Level of Pool before update
   * @param oldPoolState64x64 64x64 fixed point representation of liquidity in pool before update
   * @param newPoolState64x64 64x64 fixed point representation of liquidity in pool after update
   * @param steepness64x64 64x64 fixed point representation of steepness coefficient
   * @return 64x64 fixed point representation of new C-Level
   */
  function calculateCLevel (
    int128 initialCLevel64x64,
    int128 oldPoolState64x64,
    int128 newPoolState64x64,
    int128 steepness64x64
  ) internal pure returns (int128) {
    return newPoolState64x64.sub(oldPoolState64x64).div(
      oldPoolState64x64 > newPoolState64x64 ? oldPoolState64x64 : newPoolState64x64
    ).mul(steepness64x64).neg().exp().mul(initialCLevel64x64);
  }

  /**
   * @notice calculate the price of an option using the Median Finance model
   * @param emaVarianceAnnualized64x64 64x64 fixed point representation of annualized EMA of variance
   * @param strike64x64 64x64 fixed point representation of strike price
   * @param spot64x64 64x64 fixed point representation of spot price
   * @param timeToMaturity64x64 64x64 fixed point representation of duration of option contract (in years)
   * @param oldCLevel64x64 64x64 fixed point representation of C-Level of Pool before purchase
   * @param oldPoolState 64x64 fixed point representation of current state of the pool
   * @param newPoolState 64x64 fixed point representation of state of the pool after trade
   * @param steepness64x64 64x64 fixed point representation of Pool state delta multiplier
   * @param isCall whether to price "call" or "put" option
   * @return medianPrice64x64 64x64 fixed point representation of Median option price
   * @return cLevel64x64 64x64 fixed point representation of C-Level of Pool after purchase
   */
  function quotePrice (
    int128 emaVarianceAnnualized64x64,
    int128 strike64x64,
    int128 spot64x64,
    int128 timeToMaturity64x64,
    int128 oldCLevel64x64,
    int128 oldPoolState,
    int128 newPoolState,
    int128 steepness64x64,
    bool isCall
  ) internal pure returns (int128 medianPrice64x64, int128 cLevel64x64) {
    int128 deltaPoolState64x64 = newPoolState.sub(oldPoolState).div(oldPoolState).mul(steepness64x64);
    int128 tradingDelta64x64 = deltaPoolState64x64.neg().exp();

    int128 bsPrice64x64 = bsPrice(emaVarianceAnnualized64x64, strike64x64, spot64x64, timeToMaturity64x64, isCall);
    cLevel64x64 = tradingDelta64x64.mul(oldCLevel64x64);

    medianPrice64x64 = bsPrice64x64.mul(cLevel64x64).mul(
      // slippage coefficient
      ONE_64x64.sub(tradingDelta64x64).div(deltaPoolState64x64)
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../access/OwnableStorage.sol';
import './ManagedProxy.sol';

/**
 * @title Proxy with implementation controlled by ERC171 owner
 */
 abstract contract ManagedProxyOwnable is ManagedProxy {
   /**
    * @inheritdoc ManagedProxy
    */
   function _getManager () override internal view returns (address) {
     return OwnableStorage.layout().owner;
   }
 }

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableStorage.sol';
import '@solidstate/contracts/introspection/ERC165Storage.sol';
import '@solidstate/contracts/proxy/managed/ManagedProxyOwnable.sol';
import '@solidstate/contracts/token/ERC20/ERC20MetadataStorage.sol';
import '@solidstate/contracts/token/ERC20/IERC20Metadata.sol';
import '@solidstate/contracts/token/ERC1155/IERC1155.sol';

import '../core/IProxyManager.sol';
import './PoolStorage.sol';

import { OptionMath } from '../libraries/OptionMath.sol';

/**
 * @title Upgradeable proxy with centrally controlled Pool implementation
 */
contract PoolProxy is ManagedProxyOwnable {
  using ERC165Storage for ERC165Storage.Layout;

  constructor (
    address owner,
    address base,
    address underlying
  ) ManagedProxy(IProxyManager.getPoolImplementation.selector) {
    OwnableStorage.layout().owner = owner;

    {
      PoolStorage.Layout storage l = PoolStorage.layout();
      l.treasury = owner;
      l.pair = msg.sender;
      l.underlying = underlying;
      l.underlyingDecimals = IERC20Metadata(underlying).decimals();
      l.cLevel64x64 = OptionMath.INITIAL_C_LEVEL_64x64;
    }

    {
      ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();

      string memory symbolBase = IERC20Metadata(base).symbol();
      string memory symbolUnderlying = IERC20Metadata(underlying).symbol();

      l.name = string(abi.encodePacked(
        'Median Liquidity: ',
        symbolUnderlying,
        '/',
        symbolBase
      ));

      l.symbol = string(abi.encodePacked(
        'MED-',
        symbolUnderlying,
        symbolBase
      ));

      l.decimals = 18;
    }

    {
      ERC165Storage.Layout storage l = ERC165Storage.layout();
      l.setSupportedInterface(type(IERC165).interfaceId, true);
      l.setSupportedInterface(type(IERC1155).interfaceId, true);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../Proxy.sol';

/**
 * @title Proxy with externally controlled implementation
 * @dev implementation fetched using immutable function selector
 */
 abstract contract ManagedProxy is Proxy {
   bytes4 internal immutable _managerSelector;

   /**
    * @param managerSelector function selector used to fetch implementation from manager
    */
   constructor (
     bytes4 managerSelector
   ) {
     _managerSelector = managerSelector;
   }

   /**
    * @inheritdoc Proxy
    */
   function _getImplementation () override internal view returns (address) {
     (bool success, bytes memory data) = _getManager().staticcall(abi.encodePacked(_managerSelector));
     require(success, 'ManagedProxy: failed to fetch implementation');
     return abi.decode(data, (address));
   }

   /**
    * @notice get manager of proxy implementation
    * @return manager address
    */
   function _getManager () virtual internal view returns (address);
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Base proxy contract
 */
abstract contract Proxy {
  /**
   * @notice delegate all calls to implementation contract
   * @dev memory location in use by assembly may be unsafe in other contexts
   */
  fallback () external payable {
    address implementation = _getImplementation();

    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 { revert(0, returndatasize()) }
      default { return (0, returndatasize()) }
    }
  }

  /**
   * @notice get logic implementation address
   * @return implementation address
   */
  function _getImplementation () virtual internal returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC165'
  );

  struct Layout {
    // TODO: use EnumerableSet to allow post-diamond-cut auditing
    mapping (bytes4 => bool) supportedInterfaces;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function isSupportedInterface (
    Layout storage l,
    bytes4 interfaceId
  ) internal view returns (bool) {
    return l.supportedInterfaces[interfaceId];
  }

  function setSupportedInterface (
    Layout storage l,
    bytes4 interfaceId,
    bool status
  ) internal {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    l.supportedInterfaces[interfaceId] = status;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20MetadataStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Metadata'
  );

  struct Layout {
    string name;
    string symbol;
    uint8 decimals;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function setName (
    Layout storage l,
    string memory name
  ) internal {
    l.name = name;
  }

  function setSymbol (
    Layout storage l,
    string memory symbol
  ) internal {
    l.symbol = symbol;
  }

  function setDecimals (
    Layout storage l,
    uint8 decimals
  ) internal {
    l.decimals = decimals;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Metadata {
  function name () external view returns (string memory);

  function symbol () external view returns (string memory);

  function decimals () external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../introspection/IERC165.sol';

interface IERC1155 is IERC165 {
  event TransferSingle (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  event TransferBatch (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll (
    address indexed account,
    address indexed operator,
    bool approved
  );

  event URI (
    string value,
    uint256 indexed id
  );

  function balanceOf (
    address account,
    uint256 id
  ) external view returns (uint256);

  function balanceOfBatch (
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);

  function setApprovalForAll (
    address operator,
    bool approved
  ) external;

  function isApprovedForAll (
    address account,
    address operator
  ) external view returns (bool);

  function safeTransferFrom (
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom (
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/token/ERC20/ERC20BaseStorage.sol';

import { ABDKMath64x64Token } from '../libraries/ABDKMath64x64Token.sol';
import { OptionMath } from '../libraries/OptionMath.sol';

library PoolStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'median.contracts.storage.Pool'
  );

  struct Layout {
    address treasury;
    address pair;
    address underlying;
    uint8 underlyingDecimals;
    int128 cLevel64x64;
    int128 fee64x64;

    mapping (address => uint256) depositedAt;

    // doubly linked list of free liquidity intervals
    mapping (address => address) liquidityQueueAscending;
    mapping (address => address) liquidityQueueDescending;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function totalSupply64x64 (
    Layout storage l
  ) internal view returns (int128) {
    return ABDKMath64x64Token.fromDecimals(
      ERC20BaseStorage.layout().totalSupply, l.underlyingDecimals
    );
  }

  function addUnderwriter (
    Layout storage l,
    address account
  ) internal {
    l.liquidityQueueAscending[l.liquidityQueueDescending[address(0)]] = account;
  }

  function removeUnderwriter (
    Layout storage l,
    address account
  ) internal {
    address prev = l.liquidityQueueDescending[account];
    address next = l.liquidityQueueAscending[account];
    l.liquidityQueueAscending[prev] = next;
    l.liquidityQueueDescending[next] = prev;
    delete l.liquidityQueueAscending[account];
    delete l.liquidityQueueDescending[account];
  }

  function setCLevel (
    Layout storage l,
    int128 oldLiquidity64x64,
    int128 newLiquidity64x64
  ) internal {
    l.cLevel64x64 = OptionMath.calculateCLevel(
      l.cLevel64x64,
      oldLiquidity64x64,
      newLiquidity64x64,
      OptionMath.ONE_64x64
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
  function supportsInterface (
    bytes4 interfaceId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20BaseStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Base'
  );

  struct Layout {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalSupply;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

library ABDKMath64x64Token {
  using ABDKMath64x64 for int128;

  /**
   * @notice convert 64x64 fixed point representation of token amount to decimal
   * @param value64x64 64x64 fixed point representation of token amount
   * @param decimals token display decimals
   * @return value decimal representation of token amount
   */
  function toDecimals (
    int128 value64x64,
    uint8 decimals
  ) internal pure returns (uint256 value) {
    value = value64x64.mulu(10 ** decimals);
  }

  /**
   * @notice convert decimal representation of token amount to 64x64 fixed point
   * @param value decimal representation of token amount
   * @param decimals token display decimals
   * @return value64x64 64x64 fixed point representation of token amount
   */
  function fromDecimals (
    uint256 value,
    uint8 decimals
  ) internal pure returns (int128 value64x64) {
    value64x64 = ABDKMath64x64.divu(value, 10 ** decimals);
  }

  /**
   * @notice convert 64x64 fixed point representation of token amount to wei (18 decimals)
   * @param value64x64 64x64 fixed point representation of token amount
   * @return value wei representation of token amount
   */
  function toWei (
    int128 value64x64
  ) internal pure returns (uint256 value) {
    value = toDecimals(value64x64, 18);
  }

  /**
   * @notice convert wei representation (18 decimals) of token amount to 64x64 fixed point
   * @param value wei representation of token amount
   * @return value64x64 64x64 fixed point representation of token amount
   */
  function fromWei (
    uint256 value
  ) internal pure returns (int128 value64x64) {
    value64x64 = fromDecimals(value, 18);
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}