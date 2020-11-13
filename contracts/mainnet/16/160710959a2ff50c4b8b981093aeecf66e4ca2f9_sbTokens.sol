// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './SafeCast.sol';
import './AggregatorV3Interface.sol';

contract sbTokens {
  event TokenAdded(address indexed token, address indexed oracle);
  event TokenPricesRecorded(uint256 indexed day);

  using SafeCast for int256;
  using SafeMath for uint256;

  bool internal initDone;

  uint16 internal constant PHASE_OFFSET = 64;

  address internal sbTimelock;

  address[] internal tokens;
  address[] internal oracles;
  mapping(address => uint16) internal oraclePhase;

  mapping(address => AggregatorV3Interface) internal priceFeeds;

  mapping(address => mapping(uint256 => uint256)) internal tokenDayPrice;
  mapping(address => uint64) internal tokenRoundLatest;
  mapping(address => uint256) internal tokenDayStart;
  uint256 internal dayLastRecordedPricesFor;

  function init(
    address sbTimelockAddress,
    address[] memory tokenAddresses,
    address[] memory oracleAddresses
  ) public {
    require(!initDone, 'init done');
    // NOTE: ETH will be address(0)
    require(tokenAddresses.length == oracleAddresses.length, 'mismatch array lengths');
    require(tokenAddresses.length > 0, 'zero');
    sbTimelock = sbTimelockAddress;
    dayLastRecordedPricesFor = _getCurrentDay().sub(1);
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      _addToken(tokenAddresses[i], oracleAddresses[i]);
    }
    initDone = true;
  }

  function upToDate() external view returns (bool) {
    return dayLastRecordedPricesFor == _getCurrentDay().sub(1);
  }

  function addToken(address token, address oracle) external {
    require(msg.sender == sbTimelock, 'not sbTimelock');
    require(token != address(0), 'token not zero address');
    require(oracle != address(0), 'oracle not zero address');
    require(oracle != token, 'token oracle not same');
    require(!_tokenExists(token), 'token exists');
    require(!_oracleExists(oracle), 'oracle exists');
    _addToken(token, oracle);
  }

  function getTokens() external view returns (address[] memory) {
    return tokens;
  }

  function getTokenPrices(uint256 day) external view returns (uint256[] memory) {
    require(day <= dayLastRecordedPricesFor, 'invalid day');
    uint256[] memory prices = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      prices[i] = tokenDayPrice[token][day];
    }
    return prices;
  }

  function tokenAccepted(address token) external view returns (bool) {
    return _tokenExists(token);
  }

  function getTokenPrice(address token, uint256 day) external view returns (uint256) {
    require(_tokenExists(token), 'invalid token');
    require(day >= tokenDayStart[token], '1: invalid day');
    require(day <= dayLastRecordedPricesFor, '2: invalid day');
    return tokenDayPrice[token][day];
  }

  function getOracles() public view returns (address[] memory) {
    return oracles;
  }

  function getDayLastRecordedPricesFor() public view returns (uint256) {
    return dayLastRecordedPricesFor;
  }

  function getSbTimelockAddressUsed() public view returns (address) {
    return sbTimelock;
  }

  function getTokenRoundLatest(address token) public view returns (uint80) {
    require(_tokenExists(token), 'invalid token');
    return _makeCombinedId(oraclePhase[token], tokenRoundLatest[token]);
  }

  function getTokenDayStart(address token) public view returns (uint256) {
    require(_tokenExists(token), 'invalid token');
    return tokenDayStart[token];
  }

  function getCurrentDay() public view returns (uint256) {
    return _getCurrentDay();
  }

  function recordTokenPrices() public {
    require(_getCurrentDay() > dayLastRecordedPricesFor.add(1), 'already recorded');
    dayLastRecordedPricesFor = dayLastRecordedPricesFor.add(1);
    for (uint256 i = 0; i < tokens.length; i++) {
      (uint80 roundId, , , , ) = priceFeeds[tokens[i]].latestRoundData();
      (uint16 phase, ) = _getPhaseIdRoundId(roundId);

      if (oraclePhase[tokens[i]] != phase) {
        oraclePhase[tokens[i]] = phase;
        _cacheToken(tokens[i], _dayToTimestamp(dayLastRecordedPricesFor));
      }

      tokenDayPrice[tokens[i]][dayLastRecordedPricesFor] = _getDayClosingPrice(tokens[i], dayLastRecordedPricesFor);
    }
    emit TokenPricesRecorded(dayLastRecordedPricesFor);
  }

  function _addToken(address token, address oracle) internal {
    tokens.push(token);
    oracles.push(oracle);
    priceFeeds[token] = AggregatorV3Interface(oracle);
    (uint80 roundId, , , , ) = priceFeeds[token].latestRoundData();
    (uint16 phaseId, ) = _getPhaseIdRoundId(roundId);
    oraclePhase[token] = phaseId;
    uint256 currentDay = _getCurrentDay();
    tokenDayStart[token] = currentDay;
    uint256 timestamp = _dayToTimestamp(currentDay.sub(1));
    _cacheToken(token, timestamp);
    emit TokenAdded(token, oracle);
  }

  function _cacheToken(address token, uint256 timestamp) internal {
    tokenRoundLatest[token] = 1;
    uint64 roundId = _getRoundBeforeTimestamp(token, timestamp);
    tokenRoundLatest[token] = roundId;
  }

  function _getRoundBeforeTimestamp(address token, uint256 timestamp) internal view returns (uint64) {
    uint64 left = tokenRoundLatest[token];
    (uint80 roundId, , , , ) = priceFeeds[token].latestRoundData();
    (, uint64 right) = _getPhaseIdRoundId(roundId);
    uint64 middle = (right + left) / 2;
    while (left <= right) {
      roundId = _makeCombinedId(oraclePhase[token], middle);
      (, , , uint256 roundTimestamp, ) = priceFeeds[token].getRoundData(roundId);
      if (roundTimestamp == timestamp) {
        return middle - 1;
      } else if (roundTimestamp < timestamp) {
        left = middle + 1;
      } else {
        right = middle - 1;
      }
      middle = (right + left) / 2;
    }
    return middle;
  }

  function _getDayClosingPrice(address token, uint256 day) internal returns (uint256) {
    uint256 timestamp = _dayToTimestamp(day);
    uint64 roundId = _getRoundBeforeTimestamp(token, timestamp);
    tokenRoundLatest[token] = roundId;
    uint80 combinedId = _makeCombinedId(oraclePhase[token], roundId);
    (, int256 price, , , ) = priceFeeds[token].getRoundData(combinedId);
    uint256 priceUint256 = price.toUint256();
    uint8 decimals = priceFeeds[token].decimals();
    for (uint8 i = decimals; i < 18; i++) {
      priceUint256 = priceUint256.mul(10);
    }
    return priceUint256;
  }

  function _getCurrentDay() internal view returns (uint256) {
    return block.timestamp.div(1 days).add(1);
  }

  function _dayToTimestamp(uint256 day) internal pure returns (uint256) {
    return day.mul(1 days);
  }

  function _tokenExists(address token) internal view returns (bool) {
    for (uint256 i = 0; i < tokens.length; i++) {
      if (token == tokens[i]) {
        return true;
      }
    }
    return false;
  }

  function _oracleExists(address oracle) internal view returns (bool) {
    for (uint256 i = 0; i < oracles.length; i++) {
      if (oracle == oracles[i]) {
        return true;
      }
    }
    return false;
  }

  function _getPhaseIdRoundId(uint256 combinedId) internal pure returns (uint16, uint64) {
    return (uint16(combinedId >> PHASE_OFFSET), uint64(combinedId));
  }

  function _makeCombinedId(uint80 phaseId, uint64 roundId) internal pure returns (uint80) {
    return (phaseId << PHASE_OFFSET) | roundId;
  }
}
