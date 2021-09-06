/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.7;



// Part: IAlphaBuyWall

interface IAlphaBuyWall {
  struct BidInfo {
    address bidder; // bidder address
    uint96 amount; // remaining desired amount to buy
    uint112 price; // bid price
  }

  function bid(
    uint112,
    uint112,
    uint96
  ) external;

  function unbid(uint112, uint112) external;

  function sell(uint, uint112) external;

  function bidLinkedList() external view returns (address);

  function bidInfos(uint) external view returns (BidInfo memory);

  function nft() external view returns (address);

  function setOracle(address) external;
}

// Part: OpenZeppelin/[email protected]/Initializable

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

// Part: Governable

contract Governable is Initializable {
  event SetGovernor(address governor);
  event SetPendingGovernor(address pendingGovernor);

  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  bytes32[64] _gap; // reserve space for upgrade

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
    emit SetGovernor(msg.sender);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
    emit SetPendingGovernor(_pendingGovernor);
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
    emit SetGovernor(msg.sender);
  }
}

// File: NFTFloorPriceOracle.sol

// Inspiration from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/Oracle.sol
contract NFTFloorPriceOracle is Governable {
  struct Observation {
    uint32 timestamp;
    uint192 priceCumulative;
    bool initialized;
  }

  struct LastInfo {
    uint112 index;
    uint112 price;
  }

  uint public constant OBS_SIZE = 300;
  mapping(address => address) public underlyings; // Mapping from ABW contract to underlying NFT address.
  mapping(address => Observation[OBS_SIZE]) public observations; // Mapping from ABW contract to observations.
  mapping(address => LastInfo) public lastInfos; // Mapping from ABW contract to last updated info (index, price)
  mapping(address => address) public abws; // Mapping from underlying NFT to ABW contract address (for reverse lookup). Mapping maintained by governor.

  /// @dev Initializes the contract.
  function initialize() external initializer {
    __Governable__init();
  }

  /// @dev Initializes the observation for the msg.sender (ABW).
  /// @param _nft The underlying NFT token.
  function init(address _nft) external {
    underlyings[msg.sender] = _nft;
    observations[msg.sender][0] = Observation({
      timestamp: uint32(block.timestamp),
      priceCumulative: 0,
      initialized: true
    });
  }

  /// @dev Sets reverse lookup mapping.
  /// @param _underlying The underlying NFT token to map from.
  /// @param _abw The ABW contract address to map to.
  function _setAbw(address _underlying, address _abw) internal {
    require(IAlphaBuyWall(_abw).nft() == _underlying, '!underlying');
    abws[_underlying] = _abw;
  }

  /// @dev Sets reverse lookup mapping for multiple pairs.
  /// @param _underlyings The list of underlying NFT token to map from.
  /// @param _abws The list of ABW contract address to map to.
  function setAbws(address[] calldata _underlyings, address[] calldata _abws) external onlyGov {
    require(_underlyings.length == _abws.length, '!length');
    for (uint i = 0; i < _underlyings.length; i++) {
      _setAbw(_underlyings[i], _abws[i]);
    }
  }

  /// @dev Updates the price cumulative for the msg.sender (ABW)
  /// @param _price Input price to update.
  function write(uint112 _price) external {
    uint112 lastIndex = lastInfos[msg.sender].index;
    uint112 lastPrice = lastInfos[msg.sender].price;
    Observation memory last = observations[msg.sender][lastIndex];

    if (last.timestamp == block.timestamp) return;

    // compute new price cumulative
    uint112 curIndex = uint112((lastIndex + 1) % OBS_SIZE);
    uint32 delta;
    uint192 updatedPriceCumulative;
    unchecked {
      delta = uint32(block.timestamp) - last.timestamp; // underflow desired
      updatedPriceCumulative = last.priceCumulative + uint192(lastPrice) * delta; // overflow desired
    }

    // update storage
    observations[msg.sender][curIndex] = Observation({
      timestamp: uint32(block.timestamp),
      priceCumulative: updatedPriceCumulative,
      initialized: true
    });
    lastInfos[msg.sender] = LastInfo({index: curIndex, price: _price});
  }

  /// @dev Checks if input times are in chrono-order.
  /// @param _time Current block timestamp
  /// @param _a First input timestamp.
  /// @param _b Second input timestamp.
  /// @return Whether _a is chronologically before _b.
  function lte(
    uint32 _time,
    uint32 _a,
    uint32 _b
  ) public pure returns (bool) {
    // if there hasn't been overflow, no need to adjust
    if (_a <= _time && _b <= _time) return _a <= _b;

    uint aAdjusted = _a > _time ? _a : _a + 2**32;
    uint bAdjusted = _b > _time ? _b : _b + 2**32;

    return aAdjusted <= bAdjusted;
  }

  /// @dev Transforms last observation up to current timestamp.
  /// @param _last The last observation.
  /// @param _timestamp The current block timestamp.
  /// @param _price The latest updated price.
  /// @return The updated observation.
  function transform(
    Observation memory _last,
    uint32 _timestamp,
    uint112 _price
  ) public pure returns (Observation memory) {
    uint32 delta;
    unchecked {
      delta = _timestamp - _last.timestamp;
      return
        Observation({
          timestamp: _timestamp,
          priceCumulative: _last.priceCumulative + uint192(_price) * delta,
          initialized: true
        });
    }
  }

  /// @dev Searches the surrounding observations using binary search. Solution must exist,
  /// i.e. target time in [beforeOrAt, atOrAfter].
  /// @param _abw ABW contract address.
  /// @param _time The current block timestamp.
  /// @param _target The target timestamp to search.
  /// @param _index The current last index.
  /// @return beforeOrAt The before observation.
  /// @return atOrAfter The after observation.
  function binarySearch(
    address _abw,
    uint32 _time,
    uint32 _target,
    uint32 _index
  ) public view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    uint l = (_index + 1) % OBS_SIZE;
    uint r = l + OBS_SIZE - 1;
    uint i;
    while (true) {
      i = (l + r) / 2;

      beforeOrAt = observations[_abw][i % OBS_SIZE];

      if (!beforeOrAt.initialized) {
        l = i + 1;
        continue;
      }

      atOrAfter = observations[_abw][(i + 1) % OBS_SIZE];
      bool targetAtOrAfter = lte(_time, beforeOrAt.timestamp, _target);

      // check if we've found the answer!
      if (targetAtOrAfter && lte(_time, _target, atOrAfter.timestamp)) break;

      if (!targetAtOrAfter) r = i - 1;
      else l = i + 1;
    }
  }

  /// @dev Gets surrounding observations given the target.
  /// @param _abw The ABW contract address.
  /// @param _time The current block timestamp.
  /// @param _target The target timestamp.
  /// @param _lastIndex The current last index.
  /// @param _price The latest updated price.
  /// @return beforeOrAt The before observation.
  /// @return atOrAfter The after observation.
  function getSurroundingObservations(
    address _abw,
    uint32 _time,
    uint32 _target,
    uint32 _lastIndex,
    uint112 _price
  ) public view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    // check newest first
    beforeOrAt = observations[_abw][_lastIndex];

    if (lte(_time, beforeOrAt.timestamp, _target)) {
      if (beforeOrAt.timestamp == _target) {
        // ignore atOrAfter
        return (beforeOrAt, atOrAfter);
      } else {
        // calculate up to current
        return (beforeOrAt, transform(beforeOrAt, _target, _price));
      }
    }

    // check the oldest available observation
    beforeOrAt = observations[_abw][(_lastIndex + 1) % OBS_SIZE];
    if (!beforeOrAt.initialized) beforeOrAt = observations[_abw][0];

    require(lte(_time, beforeOrAt.timestamp, _target), 'too old');

    return binarySearch(_abw, _time, _target, _lastIndex);
  }

  /// @dev Gets a single observation given time to look back.
  /// @param _abw The ABW contract address.
  /// @param _time The current block timestamp.
  /// @param _secondsAgo The amount of time to look back.
  /// @param _price The latest updated price.
  /// @return priceCumulative The price cumulative given the time.
  function observeSingle(
    address _abw,
    uint32 _time,
    uint32 _secondsAgo,
    uint112 _price
  ) public view returns (uint192 priceCumulative) {
    uint32 target;
    unchecked {
      target = uint32(block.timestamp) - _secondsAgo; // underflow desired
    }
    (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(
      _abw,
      _time,
      target,
      uint32(lastInfos[_abw].index),
      _price
    );

    if (target == beforeOrAt.timestamp) {
      // left
      return beforeOrAt.priceCumulative;
    } else if (target == atOrAfter.timestamp) {
      // right
      return atOrAfter.priceCumulative;
    } else {
      // middle
      unchecked {
        uint32 observationTimeDelta = atOrAfter.timestamp - beforeOrAt.timestamp;
        uint32 targetDelta = target - beforeOrAt.timestamp;
        return
          beforeOrAt.priceCumulative +
          ((atOrAfter.priceCumulative - beforeOrAt.priceCumulative) / observationTimeDelta) *
          targetDelta;
      }
    }
  }

  /// @dev Gets multiple observation given list of times to look back.
  /// @param _abw The ABW contract address.
  /// @param _time The current block timestamp.
  /// @param _secondsAgo The list of amount of time to look back.
  /// @return priceCumulatives List of price cumulatives given list of times.
  function observe(
    address _abw,
    uint32 _time,
    uint32[] memory _secondsAgo
  ) public view returns (uint192[] memory priceCumulatives) {
    uint112 lastPrice = lastInfos[_abw].price;
    priceCumulatives = new uint192[](_secondsAgo.length);
    for (uint i = 0; i < _secondsAgo.length; i++) {
      priceCumulatives[i] = observeSingle(_abw, _time, _secondsAgo[i], lastPrice);
    }
  }

  /// @dev Gets TWAP given the period.
  /// @param _abw The ABW contract address.
  /// @param _period The period of time to look back
  /// @return twap The twap of the given period.
  function consult(address _abw, uint32 _period) public view returns (uint112 twap) {
    uint32[] memory secondsAgo = new uint32[](2);
    secondsAgo[0] = _period;
    secondsAgo[1] = 0;

    uint192[] memory priceCumulatives = observe(_abw, uint32(block.timestamp), secondsAgo);
    unchecked {
      uint192 priceCumulativeDelta = priceCumulatives[1] - priceCumulatives[0];
      return uint112(priceCumulativeDelta / _period);
    }
  }

  /// @dev Gets TWAP given the period for an nft (using reverse mapping lookup).
  /// @param _nft The NFT address.
  /// @param _period The period of time to look back.
  /// @return twap The twap of the given period.
  function consultNFT(address _nft, uint32 _period) public view returns (uint112 twap) {
    address abw = abws[_nft];
    require(abw != address(0), 'abw not exist');
    return consult(abw, _period);
  }

  /// @dev Gets 1-hour TWAP for an nft
  /// @param _nft The NFT address.
  /// @return twap The 1-hour TWAP.
  function getHourTWAP(address _nft) external view returns (uint112 twap) {
    return consultNFT(_nft, 3600);
  }
}