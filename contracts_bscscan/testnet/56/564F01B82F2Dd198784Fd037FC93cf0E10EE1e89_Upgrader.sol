// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) public pure returns (uint256) {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./5-types.sol";

interface IUpgrader {
  function upgrade(Types.Simba[] memory simbas) external returns(
    uint256[] memory toBurnIds,
    Types.Simba[] memory newSimbas,
    Types.UpgradeResult
  );
  
  function getPosibilityWithCurrentSetting(Types.Simba[] memory simbas) external view returns(uint256[4] memory toBurnIds);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface Types {
  struct Simba {
    uint256 id;
    uint256 level;
    uint256 hp;
    uint256 mp;
    uint256 st;
    uint256 ag;
    uint256 it;
  }

  enum UpgradeResult {
    FAIL,
    INCREASE_1_LEVEL,
    INCREASE_2_LEVELS,
    INCREASE_3_LEVELS
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./0-safe-math.sol";
import "./5-types.sol";
import "./5-iupgrader.sol";

contract Upgrader is IUpgrader {
  using SafeMath for uint256;
  
  uint256 public upgradeCount = 0;
  
  constructor() {
    initMilestones();
  }

  function upgrade(Types.Simba[] memory allSimbas) external override returns(
    uint256[] memory toBurnIds,
    Types.Simba[] memory newSimbas,
    Types.UpgradeResult upgradeResult
  ) {
    uint256 randomValue = getRandom(block.timestamp, tx.origin, upgradeCount++, allSimbas[0].id);
    upgradeResult = getUpgradeResult(allSimbas, randomValue);

    uint256 NOT_EXISTS_ID = 0;
    Types.Simba memory biggestSimba = getBiggestSimba(allSimbas, NOT_EXISTS_ID);
    newSimbas = getNewSimbas(upgradeResult, biggestSimba, randomValue);
    toBurnIds = getToBurnIds(allSimbas, biggestSimba, upgradeResult);
    return (toBurnIds, newSimbas, upgradeResult);
  }

  function getToBurnIds(
    Types.Simba[] memory allSimbas,
    Types.Simba memory biggestSimba,
    Types.UpgradeResult upgradeResult
  ) public pure returns(uint256[] memory result) {
    if (upgradeResult == Types.UpgradeResult.FAIL) {
      result = new uint256[](1);
      result[0] = biggestSimba.id;
      return result;
    }
    
    result = new uint256[](allSimbas.length);
    for (uint256 index = 0; index < allSimbas.length; index++) {
      result[index] = allSimbas[index].id;
    }
    return result;
  }

  function getNewSimbas(
    Types.UpgradeResult upgradeResult,
    Types.Simba memory biggestSimba,
    uint256 randomValue
  ) public pure returns(Types.Simba[] memory result) {
    uint256 newLevel = uint256(int256(biggestSimba.level) + getAddedLevel(upgradeResult));
    if (newLevel == 0) {
      result = new Types.Simba[](0);
      return result;
    }

    uint256 MAX_LEVEL = 19;
    if (newLevel <= MAX_LEVEL) {
      result = new Types.Simba[](1);
      result[0] = getNewSimbaByLevelAndRandom(newLevel, randomValue);
      return result;
    }

    uint256 numberOfNewSimbas = newLevel - MAX_LEVEL + 1;
    result = new Types.Simba[](numberOfNewSimbas);
    for (uint256 count = 1; count <= numberOfNewSimbas; count++) {
      result[count - 1] = getNewSimbaByLevelAndRandom(MAX_LEVEL, randomValue);
    }
    return result;
  }

  function getNewSimbaByLevelAndRandom(uint256 level, uint256 randomValue) public pure returns(Types.Simba memory) {
    return Types.Simba({
      id: 0,
      level: level,
      hp: randomValue / 10 % 11,
      mp: randomValue / 100 % 11,
      st: randomValue / 1000 % 11,
      ag: randomValue / 10000 % 11,
      it: randomValue / 100000 % 11
    });
  }

  function getRandom(uint256 timestamp, address sender, uint256 _upgradeCount, uint256 firstTokenId) public pure returns(uint256) {
    return uint256(keccak256(abi.encodePacked(timestamp, sender, _upgradeCount, firstTokenId)));
  }

  function getAddedLevel(Types.UpgradeResult upgradeResult) public pure returns(int256) {
    if (upgradeResult == Types.UpgradeResult.INCREASE_1_LEVEL) return 1;
    if (upgradeResult == Types.UpgradeResult.INCREASE_2_LEVELS) return 2;
    if (upgradeResult == Types.UpgradeResult.INCREASE_3_LEVELS) return 3;
    return -1;
  }

  enum CompareResult {
    FIRST_BIGGER_THAN_SECOND,
    FIRST_SMALLER_THAN_SECOND,
    FIRST_EQUAL_SECOND
  }

  function getBonusPoint(Types.Simba memory biggest, Types.Simba memory secondBiggest) public pure returns(uint256) {
    if (biggest.level != secondBiggest.level) return getTotalSimbaIndex(biggest);
    return getTotalSimbaIndex(biggest) + getTotalSimbaIndex(secondBiggest);
  }

  function getTotalSimbaIndex(Types.Simba memory simba) public pure returns(uint256) {
    return simba.hp + simba.mp + simba.st + simba.ag + simba.it;
  }

  function compare(Types.Simba memory first, Types.Simba memory second) public pure returns(CompareResult) {
    if (first.level > second.level) return CompareResult.FIRST_BIGGER_THAN_SECOND;
    if (first.level < second.level) return CompareResult.FIRST_SMALLER_THAN_SECOND;
    uint256 firstTotal = getTotalSimbaIndex(first);
    uint256 secondTotal = getTotalSimbaIndex(second);

    if (firstTotal > secondTotal) return CompareResult.FIRST_BIGGER_THAN_SECOND;
    if (firstTotal < secondTotal) return CompareResult.FIRST_SMALLER_THAN_SECOND;
    return CompareResult.FIRST_EQUAL_SECOND;
  }

  function getBiggestSimba(Types.Simba[] memory allSimbas, uint256 skipId) public pure returns(Types.Simba memory result) {
    uint256 length = allSimbas.length;
    for (uint256 index = 0; index < length; index++) {
      if (allSimbas[index].id == skipId) continue;
      if (compare(result, allSimbas[index]) != CompareResult.FIRST_SMALLER_THAN_SECOND) continue;
      result = allSimbas[index];
    }
    return result;
  }

  uint256[] public SIMBA_PRICES_FOR_SELLER = [
    0,
    1 ether,
    2.1 ether,
    4.2 ether,
    8.8 ether,
    18.2 ether,
    37.7 ether,
    78.2 ether,
    162.7 ether,
    339.2 ether,
    708.5 ether,
    1482.9 ether,
    3110.7 ether,
    6540.5 ether,
    13785.8 ether,
    29131.4 ether,
    61723.5 ether,
    131146.2 ether,
    279468.9 ether,
    597370.7 ether
  ];

  function getTotalValue(Types.Simba[] memory allSimbas, uint256[] memory _SIMBA_PRICES_FOR_SELLER) public pure returns(uint256) {
    uint256 total = 0;
    for (uint256 index = 0; index < allSimbas.length; index++) {
      Types.Simba memory simba = allSimbas[index];
      total += _SIMBA_PRICES_FOR_SELLER[simba.level ];
    }
    return total;
  }

  uint256[4][] baseRates = [
    [uint256(0), uint256(0), uint256(0), uint256(0)],
    [uint256(1500), uint256(7200), uint256(1000), uint256(300)],
    [uint256(1493), uint256(7198), uint256(1007), uint256(302)],
    [uint256(1485), uint256(7197), uint256(1014), uint256(304)],
    [uint256(1478), uint256(7195), uint256(1021), uint256(306)],
    [uint256(1470), uint256(7193), uint256(1028), uint256(308)],
    [uint256(1463), uint256(7191), uint256(1035), uint256(311)],
    [uint256(1456), uint256(7189), uint256(1043), uint256(313)],
    [uint256(1448), uint256(7187), uint256(1050), uint256(315)],
    [uint256(1441), uint256(7184), uint256(1057), uint256(317)],
    [uint256(1434), uint256(7182), uint256(1065), uint256(319)],
    [uint256(1427), uint256(7179), uint256(1072), uint256(322)],
    [uint256(1420), uint256(7177), uint256(1080), uint256(324)],
    [uint256(1412), uint256(7174), uint256(1087), uint256(326)],
    [uint256(1405), uint256(7171), uint256(1095), uint256(328)],
    [uint256(1398), uint256(7168), uint256(1103), uint256(331)],
    [uint256(1391), uint256(7165), uint256(1110), uint256(333)],
    [uint256(1384), uint256(7059), uint256(1221), uint256(335)],
    [uint256(0), uint256(8197), uint256(1466), uint256(338)]
  ];

  function getUpgradeResult(Types.Simba[] memory allSimbas, uint256 randomValue) public view returns(Types.UpgradeResult) {
    uint256[4] memory posibility = getPosibility(
      allSimbas,
      baseRates,
      SIMBA_PRICES_FOR_SELLER,
      milestones
    );
    return getUpgradeResultByRandomValueAndPosibility(posibility, randomValue);
  }

  function getPosibility(
    Types.Simba[] memory allSimbas,
    uint256[4][] memory _baseRates,
    uint256[] memory _SIMBA_PRICES_FOR_SELLER,
    Milestone[] memory _milestones
  ) public pure returns(uint256[4] memory result) {
    uint256 NOT_EXISTS_ID = 0;
    Types.Simba memory biggestSimba = getBiggestSimba(allSimbas, NOT_EXISTS_ID);
    Types.Simba memory secondBiggestSimba = getBiggestSimba(allSimbas, biggestSimba.id);
    uint256[4] memory posibilityWithoutBonusPoints = getPossibilityWithoutBonusPoints(
      _baseRates[biggestSimba.level],
      getTotalValue(allSimbas, _SIMBA_PRICES_FOR_SELLER),
      _SIMBA_PRICES_FOR_SELLER[biggestSimba.level + 1],
      _milestones
    );
    return getPossibilityWithBonusPoints(
      posibilityWithoutBonusPoints,
      getBonusPoint(biggestSimba, secondBiggestSimba)
    );
  }

  function getPosibilityWithCurrentSetting(Types.Simba[] memory allSimbas) public view override returns(uint256[4] memory) {
    return getPosibility(allSimbas, baseRates, SIMBA_PRICES_FOR_SELLER, milestones);
  }

  function getUpgradeResultByRandomValueAndPosibility(uint256[4] memory posibility, uint256 randomValue) public pure returns(Types.UpgradeResult) {
    uint256 modded = randomValue % 10000;
    if (modded < posibility[0]) return Types.UpgradeResult.FAIL;
    if (modded < posibility[0] + posibility[1]) return Types.UpgradeResult.INCREASE_1_LEVEL;
    if (modded < posibility[0] + posibility[1] + posibility[2]) return Types.UpgradeResult.INCREASE_2_LEVELS;
    return Types.UpgradeResult.INCREASE_3_LEVELS;
  }

  struct Milestone {
    uint256 percentage;
    int down1;
    int up1;
    int up2;
    int up3;
  }
  
  Milestone[] milestones;

  function initMilestones() internal {
    milestones.push(Milestone({ percentage: 70, down1: 0, up1: -20, up2: -75, up3: -75 }));
    milestones.push(Milestone({ percentage: 80, down1: 0, up1: -20, up2: -50, up3: -50 }));
    milestones.push(Milestone({ percentage: 90, down1: 0, up1: 0, up2: 0, up3: 0 }));
    milestones.push(Milestone({ percentage: 130, down1: -33, up1: 0, up2: 200, up3: 300 }));
  }

  function getPercentage(uint256 allSimbasValue, uint256 nextLevelPrice) public pure returns(uint256) {
    uint256 percentage = allSimbasValue * 100 / nextLevelPrice;
    uint256 MIN_PERCENTAGE = 70;
    require(percentage >= MIN_PERCENTAGE, 'NOT_ENOUGH_SIMBAS');

    uint256 MAX_PERCENTAGE = 130;
    return percentage < MAX_PERCENTAGE ? percentage : MAX_PERCENTAGE;
  }

  function getPossibilityWithoutBonusPoints(
    uint256[4] memory levelBaseRates,
    uint256 allSimbasValue,
    uint256 nextLevelPrice,
    Milestone[] memory _milestones
  ) public pure returns (uint256[4] memory result) {
    uint256 percentage = getPercentage(allSimbasValue, nextLevelPrice);
    Milestone memory milestone = calculateMilestone(
      percentage,
      findLowerMilestone(percentage, _milestones),
      findUpperMilestone(percentage, _milestones)
    );
    return applyMilestone(levelBaseRates, milestone);
  }

  function getPossibilityWithBonusPoints(uint256[4] memory withoutBonusPointsRates, uint256 bonusPoint) public pure returns (uint256[4] memory result) {
    if (bonusPoint < 50) return withoutBonusPointsRates;
    Milestone memory milestone = calculateMilestone(
      bonusPoint,
      Milestone({ percentage: 40, down1: 0, up1: 0, up2: 0, up3: 0 }),
      Milestone({ percentage: 100, down1: -50, up1: 0, up2: 100, up3: 100 })
    );
    return applyMilestone(withoutBonusPointsRates, milestone);
  }

  function getY2(uint256 x0, int256 y0, uint256 x1, int256 y1, uint256 x2) public pure returns(int256) {
    bool isJustOnePoint = x0 == x1 && x1 == x2 && y0 == y1;
    if (isJustOnePoint) return y0;
    
    bool isInvalidCase = x0 == x1 && y0 != y1;
    require(!isInvalidCase, 'INVALID_POINTS');
    return int256(x2 - x0) * (y1 - y0) / int256(x1 - x0) + y0;
  }

  function calculateMilestone(uint256 percentage, Milestone memory lower, Milestone memory upper) public pure returns(Milestone memory result) {
    result.down1 = getY2(lower.percentage, lower.down1, upper.percentage, upper.down1, percentage);
    result.up1 = getY2(lower.percentage, lower.up1, upper.percentage, upper.up1, percentage);
    result.up2 = getY2(lower.percentage, lower.up2, upper.percentage, upper.up2, percentage);
    result.up3 = getY2(lower.percentage, lower.up3, upper.percentage, upper.up3, percentage);
    result.percentage = percentage;
    return result;
  }

  function findLowerMilestone(uint256 percentage, Milestone[] memory _milestones) public pure returns(Milestone memory) {
    for (int256 index = int256(_milestones.length - 1); index >= 0; index--) {
      if (percentage < _milestones[uint256(index)].percentage) continue;
      return _milestones[uint256(index)];
    }
    revert('INVALID_PERCENTAGE');
  }
  
  function findUpperMilestone(uint256 percentage, Milestone[] memory _milestones) public pure returns(Milestone memory) {
    uint256 length = _milestones.length;
    for (uint256 index = 0; index < length; index++) {
      if (percentage > _milestones[uint256(index)].percentage) continue;
      return _milestones[uint256(index)];
    }
    revert('INVALID_PERCENTAGE');
  }

  function getNewRate(uint256 rate, int256 change) public pure returns(uint256) {
    return uint256(int256(rate) + int256(rate) * change / 100);
  }

  function applyMilestone(uint256[4] memory rates, Milestone memory milestone) public pure returns (uint256[4] memory result) {
    result = [rates[0], rates[1], rates[2], rates[3]];
    result[0] = getNewRate(rates[0], milestone.down1);
    result[1] = getNewRate(rates[1], milestone.up1);
    result[2] = getNewRate(rates[2], milestone.up2);
    result[3] = getNewRate(rates[3], milestone.up3);
    if (milestone.down1 == 0) {
      result[0] = 10000 - (result[1] + result[2] + result[3]);
      return result;
    }
    if (milestone.up1 == 0) {
      result[1] = 10000 - (result[0] + result[2] + result[3]);
      return result;
    }
    return result;
  }
}

