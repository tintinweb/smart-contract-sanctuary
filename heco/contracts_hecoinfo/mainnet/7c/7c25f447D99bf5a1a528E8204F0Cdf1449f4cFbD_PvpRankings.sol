pragma solidity ^0.6.0;
// TODO: Clean unused imports after splitting contract
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./PvpCore.sol";

contract PvpRankings is Initializable, AccessControlUpgradeable {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    IERC20 public skillToken;
    PvpCore public pvpcore;

    /// @dev how much of a duel's bounty is sent to the rankings pool
    uint8 private _rankingsPoolTaxPercent;
    /// @dev amount of points earned by winning a duel
    uint8 public winningPoints;
    /// @dev amount of points subtracted by losing duel
    uint8 public losingPoints;
    /// @dev max amount of top characters by tier
    uint8 private _maxTopCharactersPerTier;
    /// @dev current ranked season
    uint256 public currentRankedSeason;
    /// @dev timestamp of when the current season started
    uint256 public seasonStartedAt;
    /// @dev interval of ranked season restarts
    uint256 public seasonDuration;
    /// @dev amount of skill due for game coffers from tax
    uint256 public gameCofferTaxDue;
    /// @dev percentages of ranked prize distribution by fighter rank (represented as index)
    uint256[] public prizePercentages;

    /// @dev season number associated to character
    mapping(uint256 => uint256) public seasonByCharacter;
    /// @dev ranking points by character
    mapping(uint256 => uint256) public rankingPointsByCharacter;
    /// @dev accumulated skill pool per tier
    mapping(uint8 => uint256) public rankingsPoolByTier;
    /// @dev funds available for withdrawal by address
    mapping(address => uint256) private _rankingRewardsByPlayer;
    /// @dev top ranking characters by tier
    mapping(uint8 => uint256[]) private _topRankingCharactersByTier;

    event SeasonRestarted(
        uint256 indexed newSeason,
        uint256 timestamp
    );

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender));
    }

    function initialize(
        address gameContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        skillToken = IERC20(game.skillToken());

        _rankingsPoolTaxPercent = 15;
        winningPoints = 5;
        losingPoints = 3;
        _maxTopCharactersPerTier = 4;
        currentRankedSeason = 1;
        seasonStartedAt = block.timestamp;
        seasonDuration = 7 days;
        prizePercentages.push(60);
        prizePercentages.push(30);
        prizePercentages.push(10);
    }

    function withdrawRankedRewards() external {
        uint256 amountToTransfer = _rankingRewardsByPlayer[msg.sender];

        if (amountToTransfer > 0) {
            _rankingRewardsByPlayer[msg.sender] = 0;

            skillToken.safeTransfer(msg.sender, amountToTransfer);
        }
    }

    function restartRankedSeason() external restricted {
        uint256[] memory duelQueue = pvpcore.getDuelQueue();

        if (duelQueue.length > 0) {
            pvpcore.performDuels(duelQueue);
        }

        // Loops over 20 tiers. Should not be reachable anytime in the foreseeable future
        for (uint8 i = 0; i <= 20; i++) {
            if (_topRankingCharactersByTier[i].length == 0) {
                continue;
            }

            uint256 difference = 0;

            if (
                _topRankingCharactersByTier[i].length <= prizePercentages.length
            ) {
                difference =
                    prizePercentages.length -
                    _topRankingCharactersByTier[i].length;
            }

            // If there are less players than top positions, excess is transferred to top 1
            if (
                _topRankingCharactersByTier[i].length < prizePercentages.length
            ) {
                uint256 excessPercentage;
                
                address topOnePlayer = characters.ownerOf(_topRankingCharactersByTier[i][0]);

                // We accumulate excess percentage
                for (
                    uint256 j = prizePercentages.length - difference;
                    j < prizePercentages.length;
                    j++
                ) {
                    excessPercentage = excessPercentage.add(
                        prizePercentages[j]
                    );
                }

                // We assign excessive rewards to top 1 player
                _rankingRewardsByPlayer[topOnePlayer] = _rankingRewardsByPlayer[
                    topOnePlayer
                ].add((rankingsPoolByTier[i].mul(excessPercentage)).div(100));
            }

            // We assign rewards normally to all possible players
            for (uint8 h = 0; h < prizePercentages.length - difference; h++) {
                _assignRewards(
                    _topRankingCharactersByTier[i][h],
                    h,
                    rankingsPoolByTier[i]
                );
            }

            // We reset ranking prize pools
            rankingsPoolByTier[i] = 0;
 
            // We reset top players' scores
            for (uint256 k = 0; k < _topRankingCharactersByTier[i].length; k++) {
                rankingPointsByCharacter[_topRankingCharactersByTier[i][k]] = 0;
            }
        }

        currentRankedSeason = currentRankedSeason.add(1);
        seasonStartedAt = block.timestamp;

        emit SeasonRestarted(
                currentRankedSeason,
                seasonStartedAt
            );
    }

    // Requires 3 top characters, less than that will produce unintended consequences
    // Short-term solution function, delete once used.
    function forceRestartRankedSeason() external restricted {
        uint256[] memory duelQueue = pvpcore.getDuelQueue();

        if (duelQueue.length > 0) {
            pvpcore.performDuels(duelQueue);
        }

        // NOTE: TIERS HARDCODED FOR SPECIFIC ERROR
        for (uint8 i = 3; i <= 19; i++) {
            if (_topRankingCharactersByTier[i].length == 0) {
                continue;
            }

            // We assign rewards normally to all possible players
            for (uint8 h = 0; h < prizePercentages.length; h++) {
                _assignRewards(
                    _topRankingCharactersByTier[i][h],
                    h,
                    rankingsPoolByTier[i]
                );
            }

            // We reset ranking prize pools
            rankingsPoolByTier[i] = 0;
 
            // We reset top players' scores
            for (uint256 k = 0; k < _topRankingCharactersByTier[i].length; k++) {
                rankingPointsByCharacter[_topRankingCharactersByTier[i][k]] = 0;
            }
        }

        currentRankedSeason = currentRankedSeason.add(1);
        seasonStartedAt = block.timestamp;

        emit SeasonRestarted(
                currentRankedSeason,
                seasonStartedAt
            );
    }

    function forceAssignRewards(
        uint256 characterID,
        uint8 position,
        uint256 pool
    ) external restricted {
        uint256 percentage = prizePercentages[position];
        uint256 amountToTransfer = (pool.mul(percentage)).div(100);
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingRewardsByPlayer[playerToTransfer] = _rankingRewardsByPlayer[
            playerToTransfer
        ].add(amountToTransfer);
    }

    function changeRankingRewards(
        uint256 characterID,
        uint256 amount
    ) external restricted {
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingRewardsByPlayer[playerToTransfer] = amount;
    }

    function getRankingRewards(
        uint256 characterID
    ) external restricted view returns (uint256) {
        address player = characters.ownerOf(characterID);

        return _rankingRewardsByPlayer[player];
    }

    function clearTierTopCharacters(uint8 tier) external restricted {
        for (uint256 k = 0; k < _topRankingCharactersByTier[tier].length; k++) {
            rankingPointsByCharacter[_topRankingCharactersByTier[tier][k]] = 0;
        }
        delete _topRankingCharactersByTier[tier];
        rankingsPoolByTier[tier] = 0;
    }

    function _processWinner(uint256 winnerID, uint8 tier) private {
        uint256 rankingPoints = rankingPointsByCharacter[winnerID];
        uint256[] storage topRankingCharacters = _topRankingCharactersByTier[
            tier
        ];
        uint256 winnerPosition;
        bool winnerInRanking;

        // check if winner is withing the top 4
        for (uint8 i = 0; i < topRankingCharacters.length; i++) {
            if (winnerID == topRankingCharacters[i]) {
                winnerPosition = i;
                winnerInRanking = true;
                break;
            }
        }
        
        // if the winner is not in the top characters we then compare it to the last character of the top rank, swapping positions if the condition is met
        if (
            !winnerInRanking &&
            rankingPoints >=
            rankingPointsByCharacter[
                topRankingCharacters[topRankingCharacters.length - 1]
            ]
        ) {
            topRankingCharacters[topRankingCharacters.length - 1] = winnerID;
            winnerPosition = topRankingCharacters.length - 1;
        }

        for (winnerPosition; winnerPosition > 0; winnerPosition--) {
            if (
                rankingPointsByCharacter[
                    topRankingCharacters[winnerPosition]
                ] >=
                rankingPointsByCharacter[
                    topRankingCharacters[winnerPosition - 1]
                ]
            ) {
                uint256 oldCharacter = topRankingCharacters[winnerPosition - 1];
                topRankingCharacters[winnerPosition - 1] = winnerID;
                topRankingCharacters[winnerPosition] = oldCharacter;
            } else {
                break;
            }
        }
    }

    function _processLoser(uint256 loserID, uint8 tier) private {
        uint256 rankingPoints = rankingPointsByCharacter[loserID];
        uint256[] storage ranking = _topRankingCharactersByTier[tier];
        uint256 loserPosition;
        bool loserFound;

        // check if the loser is in the top 4
        for (uint8 i = 0; i < ranking.length; i++) {
            if (loserID == ranking[i]) {
                loserPosition = i;
                loserFound = true;
                break;
            }
        }
        // if the character is within the top 4, compare it to the character that precedes it and swap positions if the condition is met
        if (loserFound) {
            for (
                loserPosition;
                loserPosition < ranking.length - 1;
                loserPosition++
            ) {
                if (
                    rankingPoints <
                    rankingPointsByCharacter[ranking[loserPosition + 1]]
                ) {
                    uint256 oldCharacter = ranking[loserPosition + 1];
                    ranking[loserPosition + 1] = loserID;
                    ranking[loserPosition] = oldCharacter;
                } else {
                    break;
                }
            }
        }
    }

    function getTierTopCharacters(uint8 tier)
        external
        view
        returns (uint256[] memory)
    {
        uint256 arrayLength;
        // we return only the top 3 players, returning the array without the pivot ranker if it exists
        if (
            _topRankingCharactersByTier[tier].length == _maxTopCharactersPerTier
        ) {
            arrayLength = _topRankingCharactersByTier[tier].length - 1;
        } else {
            arrayLength = _topRankingCharactersByTier[tier].length;
        }
        uint256[] memory topRankers = new uint256[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            topRankers[i] = _topRankingCharactersByTier[tier][i];
        }

        return topRankers;
    }

    function getPlayerPrizePoolRewards() external view returns (uint256) {
        return _rankingRewardsByPlayer[msg.sender];
    }

    function _assignRewards(
        uint256 characterID,
        uint8 position,
        uint256 pool
    ) private {
        uint256 percentage = prizePercentages[position];
        uint256 amountToTransfer = (pool.mul(percentage)).div(100);
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingRewardsByPlayer[playerToTransfer] = _rankingRewardsByPlayer[
            playerToTransfer
        ].add(amountToTransfer);
    }

    function getDuelBountyDistribution(uint256 duelCost)
        external
        view
        returns (uint256, uint256)
    {
        uint256 bounty = duelCost.mul(2);
        uint256 poolTax = _rankingsPoolTaxPercent.mul(bounty).div(100);

        uint256 reward = bounty.sub(poolTax).sub(duelCost);

        return (reward, poolTax);
    }

    function fillGameCoffers() external restricted {
        skillToken.safeTransfer(address(game), gameCofferTaxDue);
        game.trackIncome(gameCofferTaxDue);
        gameCofferTaxDue = 0;
    }

    function increaseRankingsPool(uint8 tier, uint256 amount) external restricted {
        rankingsPoolByTier[tier] = rankingsPoolByTier[tier].add(amount);
    }

    function changeRankingPoints(uint256 characterID, uint256 points) external restricted {
        rankingPointsByCharacter[characterID] = points;
    }

    function handleEnterArena(uint256 characterID, uint8 tier) external restricted {
        bool isCharacterInTopRanks;
    
        for (uint i = 0; i < _topRankingCharactersByTier[tier].length; i++) {
            if (characterID == _topRankingCharactersByTier[tier][i]) {
                isCharacterInTopRanks = true;
            }
        }

        if (
            _topRankingCharactersByTier[tier].length <
            _maxTopCharactersPerTier && !isCharacterInTopRanks
        ) {
            _topRankingCharactersByTier[tier].push(characterID);
        }

        if (seasonByCharacter[characterID] != currentRankedSeason) {
            rankingPointsByCharacter[characterID] = 0;
            seasonByCharacter[characterID] = currentRankedSeason;
        }
    }

    function handlePrepareDuel(uint256 characterID) external restricted {
        if (seasonByCharacter[characterID] != currentRankedSeason) {
            rankingPointsByCharacter[characterID] = 0;
            seasonByCharacter[characterID] = currentRankedSeason;
        }
    }

    function handlePerformDuel(uint256 winnerID, uint256 loserID, uint256 bonusRank, uint8 tier, uint256 poolTax) external restricted {
        rankingPointsByCharacter[winnerID] = rankingPointsByCharacter[
                winnerID
        ].add(winningPoints.add(bonusRank));

        // Mute the ranking loss from users in pvpRankings
        // if (rankingPointsByCharacter[loserID] <= losingPoints) {
        //     rankingPointsByCharacter[loserID] = 0;
        // } else {
        //     rankingPointsByCharacter[loserID] = rankingPointsByCharacter[
        //         loserID
        //     ].sub(losingPoints);
        // }

        _processWinner(winnerID, tier);
        _processLoser(loserID, tier);

        rankingsPoolByTier[tier] = rankingsPoolByTier[
            tier
        ].add(poolTax / 2);

        gameCofferTaxDue += poolTax / 2;
    }

    // SETTERS

    function setPrizePercentage(uint256 index, uint256 value)
        external
        restricted
    {
        prizePercentages[index] = value;
    }

    function setRankingsPoolTaxPercent(uint8 percent) external restricted {
        _rankingsPoolTaxPercent = percent;
    }

    function setWinningPoints(uint8 pts) external restricted {
        winningPoints = pts;
    }

    function setLosingPoints(uint8 pts) external restricted {
        losingPoints = pts;
    }

    function setMaxTopCharactersPerTier(uint8 max) external restricted {
        _maxTopCharactersPerTier = max;
    }

    function setSeasonDuration(uint256 duration) external restricted {
        seasonDuration = duration;
    }

    function setPvpCoreAddress(address pvpCoreContract) external restricted {
        pvpcore = PvpCore(pvpCoreContract);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

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
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
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

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
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
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
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

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
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
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
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
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
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
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
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

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
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

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
library SafeMathUpgradeable {
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./Promos.sol";
import "./util.sol";

contract Weapons is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades weapon", "CBW");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_e55d8c5() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        burnPointMultiplier = 2;
        lowStarBurnPowerPerPoint = 15;
        fourStarBurnPowerPerPoint = 30;
        fiveStarBurnPowerPerPoint = 60;
    }

    function migrateTo_aa9da90() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        oneFrac = ABDKMath64x64.fromUInt(1);
        powerMultPerPointBasic =  ABDKMath64x64.divu(1, 400);// 0.25%
        powerMultPerPointPWR = powerMultPerPointBasic.mul(ABDKMath64x64.divu(103, 100)); // 0.2575% (+3%)
        powerMultPerPointMatching = powerMultPerPointBasic.mul(ABDKMath64x64.divu(107, 100)); // 0.2675% (+7%)
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
    }

    function migrateTo_surprise(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-128
        stars: 1-5 (1,2,3: primary only, 4: one secondary, 5: two secondaries)
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
        stats: STR(fire), DEX(earth), CHA(lightning), INT(water), PWR(traitless)
        base stat rolls: 1*(1-50), 2*(45-75), 3*(70-100), 4*(50-100), 5*(66-100, main is 68-100)
        burns: add level & main stat, and 50% chance to increase secondaries
        power: each point contributes .25% to fight power
        cosmetics: 0-255 but only 24 is used, may want to cap so future expansions dont change existing weps
    */

    struct Weapon {
        uint16 properties; // right to left: 3b stars, 2b trait, 7b stat pattern, 4b EMPTY
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
        uint8 level; // separate from stat1 because stat1 will have a pre-roll
    }

    struct WeaponBurnPoints {
        uint8 lowStarBurnPoints;
        uint8 fourStarBurnPoints;
        uint8 fiveStarBurnPoints;
    }

    struct WeaponCosmetics {
        uint8 version;
        uint256 seed;
    }

    Weapon[] private tokens;
    WeaponCosmetics[] private cosmetics;
    mapping(uint256 => WeaponBurnPoints) burnPoints;

    uint public burnPointMultiplier; // 2
    uint public lowStarBurnPowerPerPoint; // 15
    uint public fourStarBurnPowerPerPoint; // 30
    uint public fiveStarBurnPowerPerPoint; // 60

    int128 internal oneFrac; // 1.0
    int128 internal powerMultPerPointBasic; // 0.25%
    int128 internal powerMultPerPointPWR; // 0.2575% (+3%)
    int128 internal powerMultPerPointMatching; // 0.2675% (+7%)

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) durabilityTimestamp;

    uint256 public constant maxDurability = 20;
    uint256 public constant secondsPerDurability = 3000; //50 * 60

    mapping(address => uint256) burnDust; // user address : burned item dust counts

    Promos public promos;

    mapping(uint256 => uint256) public numberParameters;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars;//KEYS: NFTID, VARID
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..
    uint256 public constant NFTVAR_WEAPON_TYPE = 2; // x = 0: normal, x > 0: special for partner id x

    event Burned(address indexed owner, uint256 indexed burned);
    event NewWeapon(uint256 indexed weapon, address indexed minter, uint24 weaponType);
    event Reforged(address indexed owner, uint256 indexed reforged, uint256 indexed burned, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);
    event ReforgedWithDust(address indexed owner, uint256 indexed reforged, uint8 lowDust, uint8 fourDust, uint8 fiveDust, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NR");
    }

    modifier minterOnly() {
        _minterOnly();
        _;
    }

    function _minterOnly() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(MINTER_ROLE, msg.sender), "NR");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "NFL");
    }

    function getStats(uint256 id) internal view
        returns (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level) {

        Weapon memory w = tokens[id];
        return (w.properties, w.stat1, w.stat2, w.stat3, w.level);
    }

    function getCosmetics(uint256 id) internal view
        returns (uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel) {

        WeaponCosmetics memory wc = cosmetics[id];
        _blade = getRandomCosmetic(wc.seed, 1, 24);
        _crossguard = getRandomCosmetic(wc.seed, 2, 24);
        _grip = getRandomCosmetic(wc.seed, 3, 24);
        _pommel = getRandomCosmetic(wc.seed, 4, 24);
    }

    function getCosmeticsSeed(uint256 id) public view noFreshLookup(id)
        returns (uint256) {

        WeaponCosmetics memory wc = cosmetics[id];
        return wc.seed;
    }

    function get(uint256 id) public view noFreshLookup(id)
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,
            uint32 _cosmetics,
            uint24 _burnPoints, // burn points.. got stack limits so i put them together
            uint24 _bonusPower, // bonus power
            uint24 _weaponType // weapon type for special weapons
    ) {
        return _get(id);
    }

    function _get(uint256 id) internal view
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,
            uint32 _cosmetics, // cosmetics put together to avoid stack too deep errors
            uint24 _burnPoints, // burn points.. got stack limits so i put them together
            uint24 _bonusPower, // bonus power
            uint24 _weaponType // weapon type for special weapons
    ) {
        (_properties, _stat1, _stat2, _stat3, _level) = getStats(id);

        // scope to avoid stack too deep errors
        {
        (uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel) = getCosmetics(id);
        _cosmetics = uint32(_blade) | (uint32(_crossguard) << 8) | (uint32(_grip) << 16) | (uint32(_pommel) << 24);
        }

        WeaponBurnPoints memory wbp = burnPoints[id];
        _burnPoints =
            uint24(wbp.lowStarBurnPoints) |
            (uint24(wbp.fourStarBurnPoints) << 8) |
            (uint24(wbp.fiveStarBurnPoints) << 16);

        _bonusPower = getBonusPower(id);
        _weaponType = getWeaponType(id);
    }

    function setBaseURI(string memory baseUri) public restricted {
        _setBaseURI(baseUri);
    }

    function mintN(address minter, uint32 amount, uint256 seed, uint8 chosenElement) public restricted {
        for(uint i = 0; i < amount; i++)
            mint(minter, RandomUtil.combineSeeds(seed,i), chosenElement);
    }

    function mint(address minter, uint256 seed, uint8 chosenElement) public minterOnly returns(uint256) {
        uint256 stars;
        uint256 roll = seed % 100;
        // will need revision, possibly manual configuration if we support more than 5 stars
        if(roll < 1) {
            stars = 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            stars = 3;
        }
        else if(roll < 21) { // 3* at 15%
            stars = 2;
        }
        else if(roll < 56) { // 2* at 35%
            stars = 1;
        }
        else {
            stars = 0; // 1* at 44%
        }

        return mintWeaponWithStars(minter, stars, seed, chosenElement);
    }

    function mintSpecialWeapon(address minter, uint256 eventId, uint256 stars, uint256 seed, uint8 element) external minterOnly returns(uint256) {
        require(stars < 8);
        (uint16 stat1, uint16 stat2, uint16 stat3) = getStatRolls(stars, seed);

        return performMintWeapon(minter,
            eventId,
            getRandomProperties(stars, seed, element),
            stat1,
            stat2,
            stat3,
            RandomUtil.combineSeeds(seed,3)
        );
    }

    function mintGiveawayWeapon(address to, uint256 stars, uint8 chosenElement) external minterOnly returns(uint256) {
        // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
        return mintWeaponWithStars(to, stars, uint256(keccak256(abi.encodePacked(now, tokens.length))), chosenElement);
    }

    function mintWeaponWithStars(address minter, uint256 stars, uint256 seed, uint8 chosenElement) public minterOnly returns(uint256) {
        require(stars < 8);
        require(chosenElement == 100 || (chosenElement>= 0 && chosenElement<= 3));
        (uint16 stat1, uint16 stat2, uint16 stat3) = getStatRolls(stars, seed);

        return performMintWeapon(minter,
            0,
            getRandomProperties(stars, seed, chosenElement),
            stat1,
            stat2,
            stat3,
            RandomUtil.combineSeeds(seed,3)
        );
    }    

    function performMintWeapon(address minter,
        uint256 weaponType,
        uint16 properties,
        uint16 stat1, uint16 stat2, uint16 stat3,
        uint256 cosmeticSeed
    ) public minterOnly returns(uint256 tokenID) {

        tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        tokens.push(Weapon(properties, stat1, stat2, stat3, 0));
        cosmetics.push(WeaponCosmetics(0, cosmeticSeed));
        _mint(minter, tokenID);
        durabilityTimestamp[tokenID] = uint64(now.sub(getDurabilityMaxWait()));
        nftVars[tokenID][NFTVAR_WEAPON_TYPE] = weaponType;

        emit NewWeapon(tokenID, minter, uint24(weaponType));
    }

    function performMintWeaponDetailed(address minter,
        uint256 metaData,
        uint256 cosmeticSeed, uint256 tokenID
    ) public minterOnly returns(uint256) {

        uint8 fiveStarBurnPoints = uint8(metaData & 0xFF);
        uint8 fourStarBurnPoints = uint8((metaData >> 8) & 0xFF);
        uint8 lowStarBurnPoints = uint8((metaData >> 16) & 0xFF);
        uint8 level = uint8((metaData >> 24) & 0xFF);
        uint16 stat3 = uint16((metaData >> 32) & 0xFFFF);
        uint16 stat2 = uint16((metaData >> 48) & 0xFFFF);
        uint16 stat1 = uint16((metaData >> 64) & 0xFFFF);
        uint16 properties = uint16((metaData >> 80) & 0xFFFF);
        uint24 weaponType = uint24((metaData >> 128) & 0xFFFFFF);

        require(lowStarBurnPoints <= 100 && fourStarBurnPoints <= 25 &&  fiveStarBurnPoints <= 10);

        if(tokenID == 0){
            tokenID = performMintWeapon(minter, weaponType, properties, stat1, stat2, stat3, 0);
        }
        else {
            Weapon storage wp = tokens[tokenID];
            wp.properties = properties;
            wp.stat1 = stat1;
            wp.stat2 = stat2;
            wp.stat3 = stat3;
            wp.level = level;
        }
        WeaponCosmetics storage wc = cosmetics[tokenID];
        wc.seed = cosmeticSeed;

        tokens[tokenID].level = level;
        durabilityTimestamp[tokenID] = uint64(now); // avoid chain jumping abuse
        WeaponBurnPoints storage wbp = burnPoints[tokenID];

        wbp.lowStarBurnPoints = lowStarBurnPoints;
        wbp.fourStarBurnPoints = fourStarBurnPoints;
        wbp.fiveStarBurnPoints = fiveStarBurnPoints;

        return tokenID;
    }

    function getRandomProperties(uint256 stars, uint256 seed, uint8 chosenElement) internal pure returns (uint16) {
        uint256 trait;
        if (chosenElement == 100) {
            trait = ((RandomUtil.randomSeededMinMax(0,3,RandomUtil.combineSeeds(seed,1)) & 0x3) << 3);
        } else {
            trait = ((chosenElement & 0x3) << 3);
        }
        return uint16((stars & 0x7) // stars aren't randomized here!
            | trait // trait
            | ((RandomUtil.randomSeededMinMax(0,124,RandomUtil.combineSeeds(seed,2)) & 0x7F) << 5)); // statPattern
    }

    function getStatRolls(uint256 stars, uint256 seed) private pure returns (uint16, uint16, uint16) {
        // each point refers to .25%
        // so 1 * 4 is 1%
        uint16 minRoll = getStatMinRoll(stars);
        uint16 maxRoll = getStatMaxRoll(stars);
        uint8 statCount = getStatCount(stars);

        uint16 stat1 = getRandomStat(minRoll, maxRoll, seed, 5);
        uint16 stat2 = 0;
        uint16 stat3 = 0;
        if(statCount > 1) {
            stat2 = getRandomStat(minRoll, maxRoll, seed, 3);
        }
        if(statCount > 2) {
            stat3 = getRandomStat(minRoll, maxRoll, seed, 4);
        }
        return (stat1, stat2, stat3);
    }

    function getRandomStat(uint16 minRoll, uint16 maxRoll, uint256 seed, uint256 seed2) internal pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(minRoll, maxRoll,RandomUtil.combineSeeds(seed, seed2)));
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint8 limit) internal pure returns (uint8) {
        return uint8(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getStatMinRoll(uint256 stars) internal pure returns (uint16) {
        // 1 star
        if (stars == 0) return 4;
        // 2 star
        if (stars == 1) return 180;
        // 3 star
        if (stars == 2) return 280;
        // 4 star
        if (stars == 3) return 200;
        // 5+ star
        return 268;
    }

    function getStatMaxRoll(uint256 stars) internal pure returns (uint16) {
        // 3+ star
        if (stars > 1) return 400;
        // 2 star
        if (stars > 0) return 300;
        // 1 star
        return 200;
    }

    function getStatCount(uint256 stars) internal pure returns (uint8) {
        // 1-2 star
        if (stars < 3) return 1;
        // 3+ star
        return uint8(stars)-1;
    }

    function getProperties(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].properties;
    }

    function getStars(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStarsFromProperties(getProperties(id));
    }

    function getStarsFromProperties(uint16 properties) internal pure returns (uint8) {
        return uint8(properties & 0x7); // first two bits for stars
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getTraitFromProperties(getProperties(id));
    }

    function getTraitFromProperties(uint16 properties) internal pure returns (uint8) {
        return uint8((properties >> 3) & 0x3); // two bits after star bits (3)
    }

    function getStatPattern(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStatPatternFromProperties(getProperties(id));
    }

    function getStatPatternFromProperties(uint16 properties) internal pure returns (uint8) {
        return uint8((properties >> 5) & 0x7F); // 7 bits after star(3) and trait(2) bits
    }

    function getStat1Trait(uint8 statPattern) internal pure returns (uint8) {
        return uint8(uint256(statPattern) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat2Trait(uint8 statPattern) internal pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 5) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat3Trait(uint8 statPattern) internal pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 25) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level;
    }

    function getStat1(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat1;
    }

    function getStat2(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat2;
    }

    function getStat3(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat3;
    }

    function getPowerMultiplier(uint256 id) public view noFreshLookup(id) returns (int128) {
        // returns a 64.64 fixed point number for power multiplier
        // this function does not account for traits
        // it is used to calculate base enemy powers for targeting
        Weapon memory wep = tokens[id];
        int128 powerPerPoint = ABDKMath64x64.divu(1, 400); // 0.25% or x0.0025
        int128 stat1 = wep.stat1.fromUInt().mul(powerPerPoint);
        int128 stat2 = wep.stat2.fromUInt().mul(powerPerPoint);
        int128 stat3 = wep.stat3.fromUInt().mul(powerPerPoint);
        return ABDKMath64x64.fromUInt(1).add(stat1).add(stat2).add(stat3);
    }

    function getPowerMultiplierForTrait(
        uint16 properties,
        uint16 stat1,
        uint16 stat2,
        uint16 stat3,
        uint8 trait
    ) public view returns(int128) {
        // Does not include character trait to weapon trait match
        // Only counts arbitrary trait to weapon stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        uint8 statPattern = getStatPatternFromProperties(properties);
        int128 result = oneFrac;

        if(getStat1Trait(statPattern) == trait)
            result = result.add(stat1.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat1Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat1.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat1.fromUInt().mul(powerMultPerPointBasic));

        if(getStat2Trait(statPattern) == trait)
            result = result.add(stat2.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat2Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat2.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat2.fromUInt().mul(powerMultPerPointBasic));

        if(getStat3Trait(statPattern) == trait)
            result = result.add(stat3.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat3Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat3.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat3.fromUInt().mul(powerMultPerPointBasic));

        return result;
    }

    function getDustSupplies(address playerAddress) public view returns (uint32[] memory) {
        uint256 burnDustValue = burnDust[playerAddress];
        uint32[] memory supplies = new uint32[](3);
        supplies[0] = uint32(burnDustValue);
        supplies[1] = uint32(burnDustValue >> 32);
        supplies[2] = uint32(burnDustValue >> 64);
        return supplies;
    }

    function _setDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint256 burnDustValue = (uint256(amount5B) << 64) + (uint256(amount4B) << 32) + amountLB;
        burnDust[playerAddress] = burnDustValue;
    }

    function decrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) public restricted {
        _decrementDustSupplies(playerAddress, amountLB, amount4B, amount5B);
    }

    function _decrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        require(supplies[0] >= amountLB && supplies[1] >= amount4B && supplies[2] >= amount5B);
        supplies[0] -= amountLB;
        supplies[1] -= amount4B;
        supplies[2] -= amount5B;
        _setDustSupplies(playerAddress, supplies[0], supplies[1], supplies[2]);
    }

    function incrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) public restricted {
        _incrementDustSupplies(playerAddress, amountLB, amount4B, amount5B);
    }

    function _incrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        require(uint256(supplies[0]) + amountLB <= 0xFFFFFFFF
            && uint256(supplies[1]) + amount4B <= 0xFFFFFFFF
            && uint256(supplies[2]) + amount5B <= 0xFFFFFFFF);
        supplies[0] += amountLB;
        supplies[1] += amount4B;
        supplies[2] += amount5B;
        _setDustSupplies(playerAddress, supplies[0], supplies[1], supplies[2]);
    }

    function _calculateBurnValues(uint256 burnID) public view returns(uint8[] memory) {
        uint8[] memory values = new uint8[](3);

        // Carried burn points.
        WeaponBurnPoints storage burningbp = burnPoints[burnID];
        values[0] = (burningbp.lowStarBurnPoints + 1) / 2;
        values[1] = (burningbp.fourStarBurnPoints + 1) / 2;
        values[2] = (burningbp.fiveStarBurnPoints + 1) / 2;

        // Stars-based burn points.
        Weapon storage burning = tokens[burnID];
        uint8 stars = getStarsFromProperties(burning.properties);
        if(stars < 3) { // 1-3 star
            values[0] += uint8(burnPointMultiplier * (stars + 1));
        }
        else if(stars == 3) { // 4 star
            values[1] += uint8(burnPointMultiplier);
        }
        else if(stars == 4) { // 5 star
            values[2] += uint8(burnPointMultiplier);
        }

        return values;
    }

    function burn(uint256 burnID) public restricted {
        uint8[] memory values = _calculateBurnValues(burnID);

        address burnOwner = ownerOf(burnID);

        _burn(burnID);
        if(promos.getBit(burnOwner, 4) == false)
            _incrementDustSupplies(burnOwner, values[0], values[1], values[2]);

        emit Burned(
            burnOwner,
            burnID
        );
    }

    function burnWithoutDust(uint256[] memory burnIDs) public restricted {
        for(uint256 i = 0; i < burnIDs.length; i++) {
            _burnWithoutDust(burnIDs[i]);
        }
    }

    function _burnWithoutDust(uint256 burnID) internal {
        address burnOwner = ownerOf(burnID);
        _burn(burnID);
        emit Burned(burnOwner, burnID);
    }

    function reforge(uint256 reforgeID, uint256 burnID) public restricted {
        uint8[] memory values = _calculateBurnValues(burnID);

        // Note: preexisting issue of applying burn points even if _burn fails.
        if(promos.getBit(ownerOf(reforgeID), 4) == false)
            _applyBurnPoints(reforgeID, values[0], values[1], values[2]);
        _burn(burnID);

        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        emit Reforged(
            ownerOf(reforgeID),
            reforgeID,
            burnID,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    function reforgeWithDust(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) public restricted {

        if(promos.getBit(ownerOf(reforgeID), 4) == false)
            _applyBurnPoints(reforgeID, amountLB, amount4B, amount5B);
        _decrementDustSupplies(ownerOf(reforgeID), amountLB, amount4B, amount5B);

        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        emit ReforgedWithDust(
            ownerOf(reforgeID),
            reforgeID,
            amountLB,
            amount4B,
            amount5B,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    function _applyBurnPoints(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) private {
        WeaponBurnPoints storage wbp = burnPoints[reforgeID];

        if(amountLB > 0) {
            require(wbp.lowStarBurnPoints < 100);
        }
        if(amount4B > 0) {
            require(wbp.fourStarBurnPoints < 25);
        }
        if(amount5B > 0) {
            require(wbp.fiveStarBurnPoints < 10);
        }

        wbp.lowStarBurnPoints += amountLB;
        wbp.fourStarBurnPoints += amount4B;
        wbp.fiveStarBurnPoints += amount5B;

        if(wbp.lowStarBurnPoints > 100)
            wbp.lowStarBurnPoints = 100;
        if(wbp.fourStarBurnPoints > 25)
            wbp.fourStarBurnPoints = 25;
        if(wbp.fiveStarBurnPoints > 10)
            wbp.fiveStarBurnPoints = 10;
    }

    function getWeaponType(uint256 id) public view noFreshLookup(id) returns(uint24) {
        return uint24(nftVars[id][NFTVAR_WEAPON_TYPE]);
    }

    function getBonusPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return getBonusPowerForFight(id, tokens[id].level);
    }

    function getBonusPowerForFight(uint256 id, uint8 level) public view returns (uint24) {
        WeaponBurnPoints storage wbp = burnPoints[id];
        return uint24(lowStarBurnPowerPerPoint.mul(wbp.lowStarBurnPoints)
            .add(fourStarBurnPowerPerPoint.mul(wbp.fourStarBurnPoints))
            .add(fiveStarBurnPowerPerPoint.mul(wbp.fiveStarBurnPoints))
            .add(uint256(15).mul(level))
        );
    }

    function getFightData(uint256 id, uint8 charTrait) public view noFreshLookup(id) returns (int128, int128, uint24, uint8) {
        Weapon storage wep = tokens[id];
        return (
            oneFrac.add(powerMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        wep.stat1 + wep.stat2 + wep.stat3
                    )
            )),//targetMult
            getPowerMultiplierForTrait(wep.properties, wep.stat1, wep.stat2, wep.stat3, charTrait),
            getBonusPowerForFight(id, wep.level),
            getTraitFromProperties(wep.properties)
        );
    }

    function getFightDataAndDrainDurability(address fighter,
        uint256 id, uint8 charTrait, uint8 drainAmount, bool allowNegativeDurability, uint256 busyFlag) public
        restricted
    returns (int128, int128, uint24, uint8) {
        require(fighter == ownerOf(id) && nftVars[id][NFTVAR_BUSY] == 0);
        nftVars[id][NFTVAR_BUSY] |= busyFlag;
        drainDurability(id, drainAmount, allowNegativeDurability);
        Weapon storage wep = tokens[id];
        return (
            oneFrac.add(powerMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        wep.stat1 + wep.stat2 + wep.stat3
                    )
            )),//targetMult
            getPowerMultiplierForTrait(wep.properties, wep.stat1, wep.stat2, wep.stat3, charTrait),
            getBonusPowerForFight(id, wep.level),
            getTraitFromProperties(wep.properties)
        );
    }

    function drainDurability(uint256 id, uint8 amount, bool allowNegativeDurability) internal {
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require((durabilityPoints >= amount
        || (allowNegativeDurability && durabilityPoints > 0)) // we allow going into negative, but not starting negative
        );

        uint64 drainTime = uint64(amount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }
    }

    function setBurnPointMultiplier(uint256 multiplier) public restricted {
        burnPointMultiplier = multiplier;
    }
    function setLowStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        lowStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFourStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        fourStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFiveStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        fiveStarBurnPowerPerPoint = powerPerBurnPoint;
    }

    function getDurabilityTimestamp(uint256 id) public view returns (uint64) {
        return durabilityTimestamp[id];
    }

    function setDurabilityTimestamp(uint256 id, uint64 timestamp) public restricted {
        durabilityTimestamp[id] = timestamp;
    }

    function getDurabilityPoints(uint256 id) public view returns (uint8) {
        return getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
    }

    function getDurabilityPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerDurability;
        if(points > maxDurability) {
            points = maxDurability;
        }
        return uint8(points);
    }

    function isDurabilityFull(uint256 id) public view returns (bool) {
        return getDurabilityPoints(id) >= maxDurability;
    }

    function getDurabilityMaxWait() internal pure returns (uint64) {
        return uint64(maxDurability * secondsPerDurability);
    }

    function getNftVar(uint256 weaponID, uint256 nftVar) public view returns(uint256) {
        return nftVars[weaponID][nftVar];
    }
    function setNftVar(uint256 weaponID, uint256 nftVar, uint256 value) public restricted {
        nftVars[weaponID][nftVar] = value;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        // if we could afford to set exploiter weapons busy, the promos check becomes redundant, saving ~4.2k gas
        if(from != address(0))
            require(nftVars[tokenId][NFTVAR_BUSY] == 0 && (to == address(0) || promos.getBit(from, 4) == false));
    }

}

pragma solidity ^0.6.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library RandomUtil {

    using SafeMath for uint256;

    function randomSeededMinMax(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max.sub(min).add(1);
        uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        randomVar = randomVar.add(min);
        return randomVar;
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }

    function plusMinus30PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        // avoid decimal loss
        uint256 thirtyPercent = num.mul(30).div(100);
        return num.sub(thirtyPercent).add(randomSeededMinMax(0, thirtyPercent.mul(2), seed));
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function minimumStakeAmount() external view returns (uint256);

    function minimumStakeTime() external view returns (uint256);

    function getStakeRewardDistributionTimeLeft() external view returns (uint256);

    function getStakeUnlockTimeLeft() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardsDuration() external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    // Events
    event RewardAdded(uint256 reward);

    event Staked(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward);

    event RewardsDurationUpdated(uint256 newDuration);

    event MinimumStakeTimeUpdated(uint256 newMinimumStakeTime);
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../cryptoblades.sol";

// Inheritance
import "./interfaces/IStakingRewards.sol";
import "./RewardsDistributionRecipientUpgradeable.sol";
import "./FailsafeUpgradeable.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewardsUpgradeable is
    IStakingRewards,
    Initializable,
    RewardsDistributionRecipientUpgradeable,
    ReentrancyGuardUpgradeable,
    FailsafeUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public override rewardRate;
    uint256 public override rewardsDuration;
    uint256 public override minimumStakeTime;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _stakeTimestamp;

    // used only by the SKILL-for-SKILL staking contract
    CryptoBlades internal __game;

    uint256 public override minimumStakeAmount;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _minimumStakeTime
    ) public virtual initializer {
        __Context_init();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __Failsafe_init_unchained();
        __ReentrancyGuard_init_unchained();
        __RewardsDistributionRecipient_init_unchained();

        // for consistency with the old contract
        transferOwnership(_owner);

        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        minimumStakeTime = _minimumStakeTime;

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 180 days;
    }

    function migrateTo_8cb6e70(uint256 _minimumStakeAmount) external onlyOwner {
        minimumStakeAmount = _minimumStakeAmount;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view override returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getStakeRewardDistributionTimeLeft()
        external
        override
        view
        returns (uint256)
    {
        (bool success, uint256 diff) = periodFinish.trySub(block.timestamp);
        return success ? diff : 0;
    }

    function getStakeUnlockTimeLeft() external override view returns (uint256) {
        if(periodFinish <= block.timestamp) return 0;
        (bool success, uint256 diff) =
            _stakeTimestamp[msg.sender].add(minimumStakeTime).trySub(
                block.timestamp
            );
        return success ? diff : 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
        external
        virtual
        override
        normalMode
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _stake(msg.sender, amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount)
        public
        virtual
        override
        normalMode
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime ||
                periodFinish <= block.timestamp,
            "Cannot withdraw until minimum staking time has passed"
        );
        _unstake(msg.sender, amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }

    function getReward()
        public
        virtual
        override
        normalMode
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            minimumStakeTime == 0 ||
                block.timestamp.sub(_stakeTimestamp[msg.sender]) >=
                minimumStakeTime ||
                periodFinish <= block.timestamp,
            "Cannot get reward until minimum staking time has passed"
        );
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external virtual override normalMode {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function recoverOwnStake() external virtual failsafeMode {
        uint256 amount = _balances[msg.sender];
        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            stakingToken.safeTransfer(msg.sender, amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        override
        normalMode
        onlyRewardsDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // End rewards emission earlier
    function updatePeriodFinish(uint256 timestamp)
        external
        normalMode
        onlyOwner
        updateReward(address(0))
    {
        require(
            timestamp > lastUpdateTime,
            "Timestamp must be after lastUpdateTime"
        );
        periodFinish = timestamp;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw the staking token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration)
        external
        normalMode
        onlyOwner
    {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setMinimumStakeTime(uint256 _minimumStakeTime)
        external
        normalMode
        onlyOwner
    {
        minimumStakeTime = _minimumStakeTime;
        emit MinimumStakeTimeUpdated(_minimumStakeTime);
    }

    function setMinimumStakeAmount(uint256 _minimumStakeAmount)
        external
        normalMode
        onlyOwner
    {
        minimumStakeAmount = _minimumStakeAmount;
        emit MinimumStakeAmountUpdated(_minimumStakeAmount);
    }

    function enableFailsafeMode() public override normalMode onlyOwner {
        minimumStakeAmount = 0;
        minimumStakeTime = 0;
        periodFinish = 0;
        rewardRate = 0;
        rewardPerTokenStored = 0;

        super.enableFailsafeMode();
    }

    function recoverExtraStakingTokensToOwner() external onlyOwner {
        // stake() and withdraw() should guarantee that
        // _totalSupply <= stakingToken.balanceOf(this)
        uint256 stakingTokenAmountBelongingToOwner =
            stakingToken.balanceOf(address(this)).sub(_totalSupply);

        if (stakingTokenAmountBelongingToOwner > 0) {
            stakingToken.safeTransfer(
                owner(),
                stakingTokenAmountBelongingToOwner
            );
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _stake(address staker, uint256 amount) internal
    {
        require(amount >= minimumStakeAmount, "Minimum stake amount required");
        _totalSupply = _totalSupply.add(amount);
        _balances[staker] = _balances[staker].add(amount);
        _stakeTimestamp[staker] = block.timestamp; // reset timer on adding to stake

        emit Staked(staker, amount);
    }

    function _unstake(address staker, uint256 amount) internal
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[staker] = _balances[staker].sub(amount);
        if (_balances[staker] == 0) {
            _stakeTimestamp[staker] = 0;
        } else {
            _stakeTimestamp[staker] = block.timestamp;
        }
        emit Withdrawn(staker, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        if (!failsafeModeActive) {
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = lastTimeRewardApplicable();
            if (account != address(0)) {
                rewards[account] = earned(account);
                userRewardPerTokenPaid[account] = rewardPerTokenStored;
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event MinimumStakeTimeUpdated(uint256 newMinimumStakeTime);
    event MinimumStakeAmountUpdated(uint256 newMinimumStakeAmount);
    event Recovered(address token, uint256 amount);
}

pragma solidity ^0.6.2;

// Inheritance
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipientUpgradeable is Initializable, OwnableUpgradeable {
    address public rewardsDistribution;

    function __RewardsDistributionRecipient_init() internal initializer {
        __Ownable_init();
        __RewardsDistributionRecipient_init_unchained();
    }

    function __RewardsDistributionRecipient_init_unchained() internal initializer {
    }

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FailsafeUpgradeable is Initializable, OwnableUpgradeable {
    bool public failsafeModeActive;

    function __Failsafe_init() internal initializer {
        __Ownable_init();
        __Failsafe_init_unchained();
    }

    function __Failsafe_init_unchained() internal initializer {
        failsafeModeActive = false;
    }

    function enableFailsafeMode() public virtual onlyOwner {
        failsafeModeActive = true;
        emit FailsafeModeEnabled();
    }

    event FailsafeModeEnabled();

    modifier normalMode {
        require(
            !failsafeModeActive,
            "This action cannot be performed while the contract is in Failsafe Mode"
        );
        _;
    }

    modifier failsafeMode {
        require(
            failsafeModeActive,
            "This action can only be performed while the contract is in Failsafe Mode"
        );
        _;
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./Promos.sol";
import "./util.sol";

contract Shields is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades shield", "CBS");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        shieldBaseMultiplier = ABDKMath64x64.fromUInt(1);
        defenseMultPerPointBasic =  ABDKMath64x64.divu(1, 400); // 0.25%
        defenseMultPerPointDEF = defenseMultPerPointBasic.mul(ABDKMath64x64.divu(103, 100)); // 0.2575% (+3%)
        defenseMultPerPointMatching = defenseMultPerPointBasic.mul(ABDKMath64x64.divu(107, 100)); // 0.2675% (+7%)
    }

    function migrateTo_surprise(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        promos = _promos;
    }

    /*
        visual numbers start at 0, increment values by 1
        stars: 1-5 (1,2,3: primary only, 4: one secondary, 5: two secondaries)
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
        stats: STR(fire), DEX(earth), CHA(lightning), INT(water), BLK(traitless)
        base stat rolls: 1*(1-50), 2*(45-75), 3*(70-100), 4*(50-100), 5*(66-100, main is 68-100)
        defense: each point contributes .25% to fight defense
        cosmetics: 0-255, to be used for future display purposes
    */

    struct Shield {
        uint16 properties; // right to left: 3b stars, 2b trait, 7b stat pattern, 4b EMPTY
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
    }

    struct ShieldCosmetics {
        uint8 version;
        uint256 seed;
    }

    Shield[] private tokens;
    ShieldCosmetics[] private cosmetics;

    int128 public shieldBaseMultiplier; // 1.0
    int128 public defenseMultPerPointBasic; // 0.25%
    int128 public defenseMultPerPointDEF; // 0.2575% (+3%)
    int128 public defenseMultPerPointMatching; // 0.2675% (+7%)

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) durabilityTimestamp;

    uint256 public constant maxDurability = 20;
    uint256 public constant secondsPerDurability = 3000; //50 * 60

    Promos public promos;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars;//KEYS: NFTID, VARID
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..
    uint256 public constant NFTVAR_SHIELD_TYPE = 2; // 0 = normal, 1 = founders, 2 = legendary defender

    event NewShield(uint256 indexed shield, address indexed minter);
    event Burned(uint256 indexed shield, address indexed burner);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function getStats(uint256 id) internal view
        returns (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3) {

        Shield memory s = tokens[id];
        return (s.properties, s.stat1, s.stat2, s.stat3);
    }

    function get(uint256 id) public view noFreshLookup(id)
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3
    ) {
        return _get(id);
    }

    function _get(uint256 id) internal view
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3
    ) {
        return getStats(id);
    }

    function getOwned() public view returns(uint256[] memory) {
        return getOwnedBy(msg.sender);
    }

    function getOwnedBy(address owner) public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(owner));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    function getCosmeticsSeed(uint256 id) public view noFreshLookup(id)
        returns (uint256) {

        ShieldCosmetics memory sc = cosmetics[id];
        return sc.seed;
    }

    function mint(address minter, uint256 shieldType, uint256 seed) public restricted returns(uint256) {
        uint256 stars;
        uint256 roll = seed % 100;
        // will need revision, possibly manual configuration if we support more than 5 stars
        if(roll < 1) {
            stars = 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            stars = 3;
        }
        else if(roll < 21) { // 3* at 15%
            stars = 2;
        }
        else if(roll < 56) { // 2* at 35%
            stars = 1;
        }
        else {
            stars = 0; // 1* at 44%
        }

        return mintShieldWithStars(minter, stars, shieldType, seed);
    }

    function burn(uint256 tokenID) public restricted {
        address burner = ownerOf(tokenID);
        _burn(tokenID);
        emit Burned(tokenID, burner);
    }

    function burn(uint256[] memory tokenIDs) public restricted {
        for(uint i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    function mintShieldWithStars(address minter, uint256 stars, uint256 shieldType, uint256 seed) public restricted returns(uint256) {
        require(stars < 8, "Stars parameter too high! (max 7)");
        (uint16 stat1, uint16 stat2, uint16 stat3) = getStatRolls(stars, seed);

        return performMintShield(minter,
            shieldType,
            getRandomProperties(stars, seed),
            stat1,
            stat2,
            stat3,
            RandomUtil.combineSeeds(seed,3)
        );
    }

    function mintShieldsWithStars(address minter, uint256 stars, uint256 shieldType, uint32 amount, uint256 seed) public restricted returns(uint256[] memory tokenIDs) {
        require(stars < 8, "Stars parameter too high! (max 7)");
        tokenIDs = new uint256[](amount);
        for(uint i = 0; i < amount; i++) {
            tokenIDs[i] = mintShieldWithStars(minter, stars, shieldType, seed);
            seed = RandomUtil.combineSeeds(seed,i);
        }
    }

    function performMintShield(address minter,
        uint256 shieldType,
        uint16 properties,
        uint16 stat1, uint16 stat2, uint16 stat3,
        uint256 cosmeticSeed
    ) public restricted returns(uint256 tokenID) {

        tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        tokens.push(Shield(properties, stat1, stat2, stat3));
        cosmetics.push(ShieldCosmetics(0, cosmeticSeed));
        _mint(minter, tokenID);
        durabilityTimestamp[tokenID] = uint64(now.sub(getDurabilityMaxWait()));
        nftVars[tokenID][NFTVAR_SHIELD_TYPE] = shieldType;

        emit NewShield(tokenID, minter);
    }

    function performMintShieldDetailed(address minter,
        uint256 metaData,
        uint256 cosmeticSeed, uint256 tokenID
    ) public restricted returns(uint256) {

        // uint256(uint256(0)) | uint256(stat3) << 16| (uint256(stat2) << 32) | (uint256(stat1) << 48) | (uint256(properties) << 64) | (uint256(appliedCosmetic) << 80);

        uint16 stat3 = uint16((metaData >> 16) & 0xFFFF);
        uint16 stat2 = uint16((metaData >> 32) & 0xFFFF);
        uint16 stat1 = uint16((metaData >> 48) & 0xFFFF);
        uint16 properties = uint16((metaData >> 64) & 0xFFFF);
        //cosmetics >> 80
        uint8 shieldType = uint8(metaData & 0xFF);

        if(tokenID == 0){
            tokenID = performMintShield(minter, shieldType, properties, stat1, stat2, stat3, 0);
        }
        else {
            Shield storage sh = tokens[tokenID];
            sh.properties = properties;
            sh.stat1 = stat1;
            sh.stat2 = stat2;
            sh.stat3 = stat3;
        }
        ShieldCosmetics storage sc = cosmetics[tokenID];
        sc.seed = cosmeticSeed;

        durabilityTimestamp[tokenID] = uint64(now); // avoid chain jumping abuse

        return tokenID;
    }

    function mintGiveawayShield(address to, uint256 stars, uint256 shieldType) external restricted returns(uint256) {
        require(shieldType != 1, "Can't mint founders shield");
        // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
        return mintShieldWithStars(to, stars, shieldType, uint256(keccak256(abi.encodePacked(now, tokens.length))));
    }

    function getRandomProperties(uint256 stars, uint256 seed) public pure returns (uint16) {
        return uint16((stars & 0x7) // stars aren't randomized here!
            | ((RandomUtil.randomSeededMinMax(0,3,RandomUtil.combineSeeds(seed,1)) & 0x3) << 3) // trait
            | ((RandomUtil.randomSeededMinMax(0,124,RandomUtil.combineSeeds(seed,2)) & 0x7F) << 5)); // statPattern
    }

    function getStatRolls(uint256 stars, uint256 seed) private pure returns (uint16, uint16, uint16) {
        uint16 minRoll = getStatMinRoll(stars);
        uint16 maxRoll = getStatMaxRoll(stars);
        uint8 statCount = getStatCount(stars);

        uint16 stat1 = getRandomStat(minRoll, maxRoll, seed, 5);
        uint16 stat2 = 0;
        uint16 stat3 = 0;
        if(statCount > 1) {
            stat2 = getRandomStat(minRoll, maxRoll, seed, 3);
        }
        if(statCount > 2) {
            stat3 = getRandomStat(minRoll, maxRoll, seed, 4);
        }
        return (stat1, stat2, stat3);
    }

    function getRandomStat(uint16 minRoll, uint16 maxRoll, uint256 seed, uint256 seed2) public pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(minRoll, maxRoll,RandomUtil.combineSeeds(seed, seed2)));
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint8 limit) public pure returns (uint8) {
        return uint8(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getStatMinRoll(uint256 stars) public pure returns (uint16) {
        // 1 star
        if (stars == 0) return 4;
        // 2 star
        if (stars == 1) return 180;
        // 3 star
        if (stars == 2) return 280;
        // 4 star
        if (stars == 3) return 200;
        // 5+ star
        return 268;
    }

    function getStatMaxRoll(uint256 stars) public pure returns (uint16) {
        // 3+ star
        if (stars > 1) return 400;
        // 2 star
        if (stars > 0) return 300;
        // 1 star
        return 200;
    }

    function getStatCount(uint256 stars) public pure returns (uint8) {
        // 1-2 star
        if (stars < 3) return 1;
        // 3+ star
        return uint8(stars)-1;
    }

    function getProperties(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].properties;
    }

    function getStars(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStarsFromProperties(getProperties(id));
    }

    function getStars(uint256[] memory ids) public view returns (uint8[] memory) {
        uint8[] memory stars = new uint8[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
            stars[i] = getStars(ids[i]);
        }
        return stars;
    }

    function getStarsFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8(properties & 0x7); // first two bits for stars
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getTraitFromProperties(getProperties(id));
    }

    function getTraitFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 3) & 0x3); // two bits after star bits (3)
    }

    function getStatPattern(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStatPatternFromProperties(getProperties(id));
    }

    function getStatPatternFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 5) & 0x7F); // 7 bits after star(3) and trait(2) bits
    }

    function getStat1Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(uint256(statPattern) % 5); // 0-3 regular traits, 4 = traitless (DEF)
    }

    function getStat2Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 5) % 5); // 0-3 regular traits, 4 = traitless (DEF)
    }

    function getStat3Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 25) % 5); // 0-3 regular traits, 4 = traitless (DEF)
    }

    function getStat1(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat1;
    }

    function getStat2(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat2;
    }

    function getStat3(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat3;
    }

    function getDefenseMultiplier(uint256 id) public view noFreshLookup(id) returns (int128) {
        // returns a 64.64 fixed point number for defense multiplier
        // this function does not account for traits
        // it is used to calculate base enemy defenses for targeting
        Shield memory shd = tokens[id];
        int128 defensePerPoint = defenseMultPerPointBasic;
        int128 stat1 = shd.stat1.fromUInt().mul(defensePerPoint);
        int128 stat2 = shd.stat2.fromUInt().mul(defensePerPoint);
        int128 stat3 = shd.stat3.fromUInt().mul(defensePerPoint);
        return shieldBaseMultiplier.add(stat1).add(stat2).add(stat3);
    }

    function getDefenseMultiplierForTrait(
        uint16 properties,
        uint16 stat1,
        uint16 stat2,
        uint16 stat3,
        uint8 trait
    ) public view returns(int128) {
        // Does not include character trait to shield trait match
        // Only counts arbitrary trait to shield stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        uint8 statPattern = getStatPatternFromProperties(properties);
        int128 result = shieldBaseMultiplier;

        if(getStat1Trait(statPattern) == trait)
            result = result.add(stat1.fromUInt().mul(defenseMultPerPointMatching));
        else if(getStat1Trait(statPattern) == 4) // DEF, traitless
            result = result.add(stat1.fromUInt().mul(defenseMultPerPointDEF));
        else
            result = result.add(stat1.fromUInt().mul(defenseMultPerPointBasic));

        if(getStat2Trait(statPattern) == trait)
            result = result.add(stat2.fromUInt().mul(defenseMultPerPointMatching));
        else if(getStat2Trait(statPattern) == 4) // DEF, traitless
            result = result.add(stat2.fromUInt().mul(defenseMultPerPointDEF));
        else
            result = result.add(stat2.fromUInt().mul(defenseMultPerPointBasic));

        if(getStat3Trait(statPattern) == trait)
            result = result.add(stat3.fromUInt().mul(defenseMultPerPointMatching));
        else if(getStat3Trait(statPattern) == 4) // DEF, traitless
            result = result.add(stat3.fromUInt().mul(defenseMultPerPointDEF));
        else
            result = result.add(stat3.fromUInt().mul(defenseMultPerPointBasic));

        return result;
    }

    function getDefenseMultiplierForTrait(uint256 id, uint8 trait) public view returns(int128) {
        Shield storage shd = tokens[id];
        return getDefenseMultiplierForTrait(shd.properties, shd.stat1, shd.stat2, shd.stat3, trait);
    }

    function getFightData(uint256 id, uint8 charTrait) public view noFreshLookup(id) returns (int128, int128, uint24, uint8) {
        Shield storage shd = tokens[id];
        return (
            shieldBaseMultiplier.add(defenseMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        shd.stat1 + shd.stat2 + shd.stat3
                    )
            )),//targetMult
            getDefenseMultiplierForTrait(shd.properties, shd.stat1, shd.stat2, shd.stat3, charTrait),
            // Bonus defense support intended in future.
            0,
            getTraitFromProperties(shd.properties)
        );
    }

    function getFightDataAndDrainDurability(uint256 id, uint8 charTrait, uint8 drainAmount) public
        restricted noFreshLookup(id)
    returns (int128, int128, uint24, uint8) {

        require(nftVars[id][NFTVAR_BUSY] == 0, "Shield is busy");
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require(durabilityPoints >= drainAmount, "Not enough durability!");

        uint64 drainTime = uint64(drainAmount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }

        Shield storage shd = tokens[id];
        return (
            shieldBaseMultiplier.add(defenseMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        shd.stat1 + shd.stat2 + shd.stat3
                    )
            )),//targetMult
            getDefenseMultiplierForTrait(shd.properties, shd.stat1, shd.stat2, shd.stat3, charTrait),
            // Bonus defense support intended in future.
            0,
            getTraitFromProperties(shd.properties)
        );
    }

    function drainDurability(uint256 id, uint8 amount) public restricted {
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require(durabilityPoints >= amount, "Not enough durability!");

        uint64 drainTime = uint64(amount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }
    }

    function getDurabilityTimestamp(uint256 id) public view returns (uint64) {
        return durabilityTimestamp[id];
    }

    function setDurabilityTimestamp(uint256 id, uint64 timestamp) public restricted {
        durabilityTimestamp[id] = timestamp;
    }

    function getDurabilityPoints(uint256 id) public view returns (uint8) {
        return getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
    }

    function getDurabilityPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerDurability;
        if(points > maxDurability) {
            points = maxDurability;
        }
        return uint8(points);
    }

    function isDurabilityFull(uint256 id) public view returns (bool) {
        return getDurabilityPoints(id) >= maxDurability;
    }

    function getDurabilityMaxWait() public pure returns (uint64) {
        return uint64(maxDurability * secondsPerDurability);
    }

    function getNftVar(uint256 shieldID, uint256 nftVar) public view returns(uint256) {
        return nftVars[shieldID][nftVar];
    }
    function setNftVar(uint256 shieldID, uint256 nftVar, uint256 value) public restricted {
        nftVars[shieldID][nftVar] = value;
    }
    function setNftVars(uint256[] calldata ids, uint256 nftVar, uint256 value) external restricted {
        for(uint i = 0; i < ids.length; i++)
            nftVars[ids[i]][nftVar] = value;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(promos.getBit(from, 4) == false && promos.getBit(to, 4) == false
            && nftVars[tokenId][NFTVAR_BUSY] == 0);
    }

    function setBaseURI(string memory baseUri) public restricted {
        _setBaseURI(baseUri);
    }
}

pragma solidity ^0.6.5;

interface IStakeFromGame {
    function stakeFromGame(address player, uint256 amount) external;

    function unstakeToGame(address player, uint256 amount) external;
}

pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
    function getRandomSeedUsingHash(address user, bytes32 hash) external view returns (uint256 seed);
}

pragma solidity ^0.6.5;

interface IPriceOracle {
    // Views
    function currentPrice() external view returns (uint256 price);

    // Mutative
    function setCurrentPrice(uint256 price) external;

    // Events
    event CurrentPriceUpdated(uint256 price);
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IStakeFromGame.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./util.sol";
import "./common.sol";
import "./Blacksmith.sol";
import "./SpecialWeaponsManager.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    int128 public constant PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT =
        14757395258967641292; // 0.8 in fixed-point 64x64 format

    // Mapped variables (vars[]) keys, one value per key
    // Using small numbers for now to save on contract size (3% for 13 vars vs using uint256(keccak256("name"))!)
    // Can be migrated later via setVars if needed
    uint256 public constant VAR_HOURLY_INCOME = 1;
    uint256 public constant VAR_HOURLY_FIGHTS = 2;
    uint256 public constant VAR_HOURLY_POWER_SUM = 3;
    uint256 public constant VAR_HOURLY_POWER_AVERAGE = 4;
    uint256 public constant VAR_HOURLY_PAY_PER_FIGHT = 5;
    uint256 public constant VAR_HOURLY_TIMESTAMP = 6;
    uint256 public constant VAR_DAILY_MAX_CLAIM = 7;
    uint256 public constant VAR_CLAIM_DEPOSIT_AMOUNT = 8;
    uint256 public constant VAR_PARAM_PAYOUT_INCOME_PERCENT = 9;
    uint256 public constant VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT = 10;
    uint256 public constant VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT = 11;
    uint256 public constant VAR_PARAM_MAX_FIGHT_PAYOUT = 12;
    uint256 public constant VAR_HOURLY_DISTRIBUTION = 13;
    uint256 public constant VAR_UNCLAIMED_SKILL = 14;
    uint256 public constant VAR_HOURLY_MAX_POWER_AVERAGE = 15;
    uint256 public constant VAR_PARAM_HOURLY_MAX_POWER_PERCENT = 16;
    uint256 public constant VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS = 17;
    uint256 public constant VAR_PARAM_HOURLY_PAY_ALLOWANCE = 18;
    uint256 public constant VAR_MINT_WEAPON_FEE_DECREASE_SPEED = 19;
    uint256 public constant VAR_MINT_CHARACTER_FEE_DECREASE_SPEED = 20;
    uint256 public constant VAR_WEAPON_FEE_INCREASE = 21;
    uint256 public constant VAR_CHARACTER_FEE_INCREASE = 22;
    uint256 public constant VAR_MIN_WEAPON_FEE = 23;
    uint256 public constant VAR_MIN_CHARACTER_FEE = 24;
    uint256 public constant VAR_WEAPON_MINT_TIMESTAMP = 25;
    uint256 public constant VAR_CHARACTER_MINT_TIMESTAMP = 26;
    uint256 public constant VAR_FIGHT_FLAT_IGO_BONUS = 27; // TEMP, do not reuse 27 later though


    // Mapped user variable(userVars[]) keys, one value per wallet
    uint256 public constant USERVAR_DAILY_CLAIMED_AMOUNT = 10001;
    uint256 public constant USERVAR_CLAIM_TIMESTAMP = 10002;

    Characters public characters;
    Weapons public weapons;
    IERC20 public skillToken;//0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;
    IPriceOracle public priceOracleSkillPerUsd;
    IRandoms public randoms;

    function initialize(IERC20 _skillToken, Characters _characters, Weapons _weapons, IPriceOracle _priceOracleSkillPerUsd, IRandoms _randoms) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        skillToken = _skillToken;
        characters = _characters;
        weapons = _weapons;
        priceOracleSkillPerUsd = _priceOracleSkillPerUsd;
        randoms = _randoms;

        staminaCostFight = 40;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;

        // migrateTo_1ee400a
        fightXpGain = 32;

        // migrateTo_aa9da90
        oneFrac = ABDKMath64x64.fromUInt(1);
        fightTraitBonus = ABDKMath64x64.divu(75, 1000);

        // migrateTo_7dd2a56
        // numbers given for the curves were $4.3-aligned so they need to be multiplied
        // additional accuracy may be in order for the setter functions for these
        fightRewardGasOffset = ABDKMath64x64.divu(23177, 100000); // 0.0539 x 4.3
        fightRewardBaseline = ABDKMath64x64.divu(344, 1000); // 0.08 x 4.3

        // migrateTo_5e833b0
        durabilityCostFight = 1;
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    function migrateTo_23b3a8b(IStakeFromGame _stakeFromGame) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        stakeFromGameImpl = _stakeFromGame;
    }

    function migrateTo_801f279() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        burnWeaponFee = ABDKMath64x64.divu(2, 10);//0.2 usd;
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(3, 10);//0.3 usd;

        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee;//0.5 usd;
    }

    function migrateTo_60872c8(Blacksmith _blacksmith) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        blacksmith = _blacksmith;
    }

    function migrateTo_6a97bd1() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        rewardsClaimTaxMax = 2767011611056432742; // = ~0.15 = ~15%
        rewardsClaimTaxDuration = 15 days;
    }

    function migrateTo_e1fe97c(SpecialWeaponsManager _swm) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        specialWeaponsManager = _swm;
    }

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    uint characterLimit;
    // config vars
    uint8 staminaCostFight;

    // prices & payouts are in USD, with 4 decimals of accuracy in 64.64 fixed point format
    int128 public mintCharacterFee;
    //int128 public rerollTraitFee;
    //int128 public rerollCosmeticsFee;
    int128 public refillStaminaFee;
    // lvl 1 player power could be anywhere between ~909 to 1666
    // cents per fight multiplied by monster power divided by 1000 (lv1 power)
    int128 public fightRewardBaseline;
    int128 public fightRewardGasOffset;

    int128 public mintWeaponFee;
    int128 public reforgeWeaponFee;

    uint256 nonce;

    mapping(address => uint256) lastBlockNumberCalled;

    uint256 public fightXpGain; // multiplied based on power differences

    mapping(address => uint256) tokenRewards; // user adress : skill wei
    mapping(uint256 => uint256) xpRewards; // character id : xp

    int128 public oneFrac; // 1.0
    int128 public fightTraitBonus; // 7.5%

    mapping(address => uint256) public inGameOnlyFunds;
    uint256 public totalInGameOnlyFunds;

    Promos public promos;

    mapping(address => uint256) private _rewardsClaimTaxTimerStart;

    IStakeFromGame public stakeFromGameImpl;

    uint8 durabilityCostFight;

    int128 public burnWeaponFee;
    int128 public reforgeWeaponWithDustFee;

    Blacksmith public blacksmith;

    struct MintPayment {
        bytes32 blockHash;
        uint256 blockNumber;
        address nftAddress;
        uint count;
    }

    mapping(address => MintPayment) mintPayments;

    struct MintPaymentSkillDeposited {
        uint256 skillDepositedFromWallet;
        uint256 skillDepositedFromRewards;
        uint256 skillDepositedFromIgo;

        uint256 skillRefundableFromWallet;
        uint256 skillRefundableFromRewards;
        uint256 skillRefundableFromIgo;

        uint256 refundClaimableTimestamp;
    }

    uint256 public totalMintPaymentSkillRefundable;
    mapping(address => MintPaymentSkillDeposited) mintPaymentSkillDepositeds;

    int128 private rewardsClaimTaxMax;
    uint256 private rewardsClaimTaxDuration;

    mapping(uint256 => uint256) public vars;
    mapping(address => mapping(uint256 => uint256)) public userVars;

    SpecialWeaponsManager public specialWeaponsManager;

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);
    event InGameOnlyFundsGiven(address indexed to, uint256 skillAmount);

    function recoverSkill(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        skillToken.safeTransfer(msg.sender, amount);
    }

    function REWARDS_CLAIM_TAX_MAX() public view returns (int128) {
        return rewardsClaimTaxMax;
    }

    function REWARDS_CLAIM_TAX_DURATION() public view returns (uint256) {
        return rewardsClaimTaxDuration;
    }

    function getSkillToSubtractSingle(uint256 _needed, uint256 _available)
        public
        pure
        returns (uint256 _used, uint256 _remainder) {

        if(_needed <= _available) {
            return (_needed, 0);
        }

        _needed -= _available;

        return (_available, _needed);
    }

    function getSkillToSubtract(uint256 _inGameOnlyFunds, uint256 _tokenRewards, uint256 _skillNeeded)
        public
        pure
        returns (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) {

        if(_skillNeeded <= _inGameOnlyFunds) {
            return (_skillNeeded, 0, 0);
        }

        _skillNeeded -= _inGameOnlyFunds;

        if(_skillNeeded <= _tokenRewards) {
            return (_inGameOnlyFunds, _skillNeeded, 0);
        }

        _skillNeeded -= _tokenRewards;

        return (_inGameOnlyFunds, _tokenRewards, _skillNeeded);
    }

    function getSkillNeededFromUserWallet(address playerAddress, uint256 skillNeeded, bool allowInGameOnlyFunds)
        public
        view
        returns (uint256 skillNeededFromUserWallet) {

        uint256 inGameOnlyFundsToUse = 0;
        if (allowInGameOnlyFunds) {
            inGameOnlyFundsToUse = inGameOnlyFunds[playerAddress];
        }
        (,, skillNeededFromUserWallet) = getSkillToSubtract(
            inGameOnlyFundsToUse,
            tokenRewards[playerAddress],
            skillNeeded
        );
    }

    function unpackFightData(uint96 playerData)
        public pure returns (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) {

        charTrait = uint8(playerData & 0xFF);
        basePowerLevel = uint24((playerData >> 8) & 0xFFFFFF);
        timestamp = uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF);
    }

    function fight(uint256 char, uint256 wep, uint32 target, uint8 fightMultiplier) external
        /*restricted*/ returns (uint256, uint256) {
        require(fightMultiplier >= 1 && fightMultiplier <= 5);

        (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) =
            unpackFightData(characters.getFightDataAndDrainStamina(tx.origin,
                char, staminaCostFight * fightMultiplier, false, 0));

        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightDataAndDrainDurability(tx.origin, wep, charTrait,
                durabilityCostFight * fightMultiplier, false, 0);

        // dirty variable reuse to avoid stack limits
        target = grabTarget(
            Common.getPlayerPower(basePowerLevel, weaponMultTarget, weaponBonusPower),
            timestamp,
            target,
            now / 1 hours
        );
        return performFight(
            char,
            wep,
            Common.getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            uint24(charTrait | (uint24(weaponTrait) << 8) | (target & 0xFF000000) >> 8),
            uint24(target & 0xFFFFFF),
            fightMultiplier
        );
    }

    function performFight(
        uint256 char,
        uint256 wep,
        uint24 playerFightPower,
        uint24 traitsCWE, // could fit into uint8 since each trait is only stored on 2 bits (TODO)
        uint24 targetPower,
        uint8 fightMultiplier
    ) private returns (uint256 tokens, uint256 expectedTokens) {
        uint256 seed = uint256(keccak256(abi.encodePacked(now, tx.origin)));
        uint24 playerRoll = getPlayerPowerRoll(playerFightPower,traitsCWE,seed);
        uint24 monsterRoll = getMonsterPowerRoll(targetPower, RandomUtil.combineSeeds(seed,1));

        updateHourlyPayouts(); // maybe only check in trackIncome? (or do via bot)

        uint16 xp = getXpGainForFight(playerFightPower, targetPower) * fightMultiplier;
        tokens = getTokenGainForFight(targetPower, true) * fightMultiplier;
        expectedTokens = tokens;

        if(tokenRewards[tx.origin] == 0 && tokens > 0) {
            _rewardsClaimTaxTimerStart[tx.origin] = block.timestamp;
        }

        if (playerRoll < monsterRoll) {
            tokens = 0;
            xp = 0;
        }
        //TEMP FOR EVENT
        else {
            _giveInGameOnlyFundsFromContractBalance(tx.origin, vars[VAR_FIGHT_FLAT_IGO_BONUS] * fightMultiplier);
        }
        //^ TEMP

        // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
        tokenRewards[tx.origin] += tokens;
        vars[VAR_UNCLAIMED_SKILL] += tokens;
        vars[VAR_HOURLY_DISTRIBUTION] -= tokens;
        xpRewards[char] += xp;
        

        vars[VAR_HOURLY_FIGHTS] += fightMultiplier;
        vars[VAR_HOURLY_POWER_SUM] += playerFightPower * fightMultiplier;

        emit FightOutcome(tx.origin, char, wep, (targetPower | ((uint32(traitsCWE) << 8) & 0xFF000000)), playerRoll, monsterRoll, xp, (tokens + vars[VAR_FIGHT_FLAT_IGO_BONUS] * fightMultiplier));
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint24 monsterPower, bool applyLimit) public view returns (uint256) {
        // monsterPower / avgPower * payPerFight * powerMultiplier
        uint256 amount = ABDKMath64x64.divu(monsterPower, vars[VAR_HOURLY_POWER_AVERAGE])
            .mulu(vars[VAR_HOURLY_PAY_PER_FIGHT]);

        if(amount > vars[VAR_PARAM_MAX_FIGHT_PAYOUT])
            amount = vars[VAR_PARAM_MAX_FIGHT_PAYOUT];
        if(vars[VAR_HOURLY_DISTRIBUTION] < amount * 5 && applyLimit) // the * 5 is a temp measure until we can sync frontend on main
            amount = 0;
        return amount;
    }

    function getXpGainForFight(uint24 playerPower, uint24 monsterPower) internal view returns (uint16) {
        return uint16(ABDKMath64x64.divu(monsterPower, playerPower).mulu(fightXpGain));
    }

    function getPlayerPowerRoll(
        uint24 playerFightPower,
        uint24 traitsCWE,
        uint256 seed
    ) internal view returns(uint24) {

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(playerFightPower,seed);
        return uint24(getPlayerTraitBonusAgainst(traitsCWE).mulu(playerPower));
    }

    function getMonsterPowerRoll(uint24 monsterPower, uint256 seed) internal pure returns(uint24) {
        // roll for fights
        return uint24(RandomUtil.plusMinus10PercentSeeded(monsterPower, seed));
    }

    function getPlayerTraitBonusAgainst(uint24 traitsCWE) public view returns (int128) {
        int128 traitBonus = oneFrac;
        uint8 characterTrait = uint8(traitsCWE & 0xFF);
        if(characterTrait == (traitsCWE >> 8) & 0xFF/*wepTrait*/) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        if(Common.isTraitEffectiveAgainst(characterTrait, uint8(traitsCWE >> 16)/*enemy*/)) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        else if(Common.isTraitEffectiveAgainst(uint8(traitsCWE >> 16)/*enemy*/, characterTrait)) {
            traitBonus = traitBonus.sub(fightTraitBonus);
        }
        return traitBonus;
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        // this is a frontend function
        (int128 weaponMultTarget,,
            uint24 weaponBonusPower,
            ) = weapons.getFightData(wep, characters.getTrait(char));

        return getTargetsInternal(
            Common.getPlayerPower(uint24(characters.getTotalPower(char)), weaponMultTarget, weaponBonusPower),
            characters.getStaminaTimestamp(char),
            now / 1 hours
        );
    }

    function getTargetsInternal(uint24 playerPower,
        uint64 staminaTimestamp,
        uint256 currentHour
    ) private pure returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour

        uint32[4] memory targets;
        for(uint32 i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            // this is a read only function so it's fine to pack all 4 params each iteration
            // for the sake of target picking it needs to be the same as in grabTarget(i)
            // even the exact type of "i" is important here
            uint256 indexSeed = uint256(keccak256(abi.encodePacked(
                staminaTimestamp, currentHour, playerPower, i
            )));
            targets[i] = uint32(
                RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed) // power
                | (uint32(indexSeed % 4) << 24) // trait
            );
        }

        return targets;
    }

    function grabTarget(
        uint24 playerPower,
        uint64 staminaTimestamp,
        uint32 enemyIndex,
        uint256 currentHour
    ) private pure returns (uint32) {
        require(enemyIndex < 4);

        uint256 enemySeed = uint256(keccak256(abi.encodePacked(
            staminaTimestamp, currentHour, playerPower, enemyIndex
        )));
        return uint32(
            RandomUtil.plusMinus10PercentSeeded(playerPower, enemySeed) // power
            | (uint32(enemySeed % 4) << 24) // trait
        );
    }

    function mintCharacter() public onlyNonContract oncePerBlock(msg.sender) {

        uint256 skillAmount = usdToSkill(mintCharacterFee);
        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[msg.sender],
                skillAmount
            );
        require(skillToken.balanceOf(msg.sender) >= fromUserWallet && promos.getBit(msg.sender, 4) == false);

        uint256 convertedAmount = usdToSkill(getMintCharacterFee());
        _payContractTokenOnly(msg.sender, convertedAmount);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        characters.mint(msg.sender, seed);

        // first weapon free with a character mint, max 1 star
        if(weapons.balanceOf(msg.sender) == 0) {
            weapons.mintWeaponWithStars(msg.sender, 0, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), 100);
        }

        _updateCharacterMintFee();
    }

    function mintWeaponN(uint32 num, uint8 chosenElement, uint256 eventId)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(getMintWeaponFee() * num * chosenElementFee));
        _mintWeaponNLogic(num, chosenElement, eventId);
    }

    function mintWeapon(uint8 chosenElement, uint256 eventId) external onlyNonContract oncePerBlock(msg.sender) {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(getMintWeaponFee() * chosenElementFee));
        _mintWeaponLogic(chosenElement, eventId);
    }

    function mintWeaponNUsingStakedSkill(uint32 num, uint8 chosenElement, uint256 eventId)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        int128 discountedMintWeaponFee =
            getMintWeaponFee()
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(num))
                .mul(ABDKMath64x64.fromUInt(chosenElementFee));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponNLogic(num, chosenElement, eventId);
    }

    function mintWeaponUsingStakedSkill(uint8 chosenElement, uint256 eventId) external onlyNonContract oncePerBlock(msg.sender) {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        int128 discountedMintWeaponFee =
            getMintWeaponFee()
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(chosenElementFee));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponLogic(chosenElement, eventId);
    }

    function _mintWeaponNLogic(uint32 num, uint8 chosenElement, uint256 eventId) internal {
        require(num > 0 && num <= 10);
        if(eventId > 0) {
            specialWeaponsManager.addShards(msg.sender, eventId, num);
        }
        _updateWeaponMintFee(num);
        weapons.mintN(msg.sender, num, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), chosenElement);
    }

    function _mintWeaponLogic(uint8 chosenElement, uint256 eventId) internal {
        //uint256 seed = randoms.getRandomSeed(msg.sender);
        if(eventId > 0) {
            specialWeaponsManager.addShards(msg.sender, eventId, 1);
        }
        _updateWeaponMintFee(1);
        weapons.mint(msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), chosenElement);
    }

    function _updateWeaponMintFee(uint256 num) internal {
        mintWeaponFee = getMintWeaponFee() + ABDKMath64x64.divu(vars[VAR_WEAPON_FEE_INCREASE].mul(num), 1e18);
        vars[VAR_WEAPON_MINT_TIMESTAMP] = block.timestamp;
    }

    function _updateCharacterMintFee() internal {
        mintCharacterFee = getMintCharacterFee() + ABDKMath64x64.divu(vars[VAR_CHARACTER_FEE_INCREASE], 1e18);
        vars[VAR_CHARACTER_MINT_TIMESTAMP] = block.timestamp;
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        randoms = _newRandoms;
    }

    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == msg.sender, "ONC");
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "OCB");
        lastBlockNumberCalled[user] = block.number;
    }

    modifier isWeaponOwner(uint256 weapon) {
        _isWeaponOwner(weapon);
        _;
    }

    function _isWeaponOwner(uint256 weapon) internal view {
        require(weapons.ownerOf(weapon) == msg.sender);
    }

    modifier isWeaponsOwner(uint256[] memory weaponArray) {
        _isWeaponsOwner(weaponArray);
        _;
    }

    function _isWeaponsOwner(uint256[] memory weaponArray) internal view {
        for(uint i = 0; i < weaponArray.length; i++) {
            require(weapons.ownerOf(weaponArray[i]) == msg.sender);
        }
    }

    modifier isCharacterOwner(uint256 character) {
        _isCharacterOwner(character);
        _;
    }

    function _isCharacterOwner(uint256 character) internal view {
        require(characters.ownerOf(character) == msg.sender);
    }

    function payPlayerConverted(address playerAddress, uint256 convertedAmount) public restricted {
        _payPlayerConverted(playerAddress, convertedAmount);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount, true);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount, bool track) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount, track);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount) internal {
        _payContractTokenOnly(playerAddress, convertedAmount, true);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount, bool track) internal {
        (, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[playerAddress],
                convertedAmount
            );

        _deductPlayerSkillStandard(playerAddress, 0, fromTokenRewards, fromUserWallet, track);
    }

    function _payContract(address playerAddress, int128 usdAmount) internal
        returns (uint256 _fromInGameOnlyFunds, uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        return _payContractConverted(playerAddress, usdToSkill(usdAmount));
    }

    function _payContractConverted(address playerAddress, uint256 convertedAmount) internal
        returns (uint256 _fromInGameOnlyFunds, uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        require(skillToken.balanceOf(playerAddress) >= fromUserWallet,
            string(abi.encodePacked("Not enough SKILL! Need ",RandomUtil.uint2str(convertedAmount))));

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);
    }

    function payContractConvertedSupportingStaked(address playerAddress, uint256 convertedAmount) external restricted 
        returns (
            uint256 _fromInGameOnlyFunds,
            uint256 _fromTokenRewards,
            uint256 _fromUserWallet,
            uint256 _fromStaked
        ) {
        return _payContractConvertedSupportingStaked(playerAddress, convertedAmount);
    }

    function _payContractConvertedSupportingStaked(address playerAddress, uint256 convertedAmount) internal
        returns (
            uint256 _fromInGameOnlyFunds,
            uint256 _fromTokenRewards,
            uint256 _fromUserWallet,
            uint256 _fromStaked
        ) {

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 _remainder) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        (uint256 fromUserWallet, uint256 fromStaked) =
            getSkillToSubtractSingle(
                _remainder,
                skillToken.balanceOf(playerAddress)
            );

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        if(fromStaked > 0) {
            stakeFromGameImpl.unstakeToGame(playerAddress, fromStaked);
            _trackIncome(fromStaked);
        }

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet, fromStaked);
    }

    function _payContractStakedOnly(address playerAddress, uint256 convertedAmount) internal {
        stakeFromGameImpl.unstakeToGame(playerAddress, convertedAmount);
        _trackIncome(convertedAmount);
    }

    function payContractStakedOnly(address playerAddress, uint256 convertedAmount) external restricted {
        _payContractStakedOnly(playerAddress, convertedAmount);
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet
    ) internal {
        _deductPlayerSkillStandard(
            playerAddress,
            fromInGameOnlyFunds,
            fromTokenRewards,
            fromUserWallet,
            true
        );
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet,
        bool trackInflow
    ) internal {
        if(fromInGameOnlyFunds > 0) {
            totalInGameOnlyFunds = totalInGameOnlyFunds.sub(fromInGameOnlyFunds);
            inGameOnlyFunds[playerAddress] = inGameOnlyFunds[playerAddress].sub(fromInGameOnlyFunds);
        }

        if(fromTokenRewards > 0) {
            tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        }

        if(fromUserWallet > 0) {
            skillToken.transferFrom(playerAddress, address(this), fromUserWallet);
            if(trackInflow)
                _trackIncome(fromUserWallet);
        }
    }

    function deductAfterPartnerClaim(uint256 amount, address player) external restricted {
        tokenRewards[player] = tokenRewards[player].sub(amount);
        vars[VAR_UNCLAIMED_SKILL] -= amount;
        _trackIncome(amount);
    }

    function trackIncome(uint256 income) public restricted {
        _trackIncome(income);
    }

    function _trackIncome(uint256 income) internal {
        vars[VAR_HOURLY_INCOME] += ABDKMath64x64.divu(vars[VAR_PARAM_PAYOUT_INCOME_PERCENT],100)
                .mulu(income);
        updateHourlyPayouts();
    }

    function updateHourlyPayouts() internal {
        // Could be done by a bot instead?
        if(now - vars[VAR_HOURLY_TIMESTAMP] >= 1 hours) {
            vars[VAR_HOURLY_TIMESTAMP] = now;

            uint256 undistributed = vars[VAR_HOURLY_INCOME] + vars[VAR_HOURLY_DISTRIBUTION];

            vars[VAR_HOURLY_DISTRIBUTION] = undistributed > vars[VAR_PARAM_HOURLY_PAY_ALLOWANCE]
                ? vars[VAR_PARAM_HOURLY_PAY_ALLOWANCE] : undistributed;
            vars[VAR_HOURLY_INCOME] = undistributed.sub(vars[VAR_HOURLY_DISTRIBUTION]);

            uint256 fights = vars[VAR_HOURLY_FIGHTS];
            if(fights >= vars[VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS]) {
                uint256 averagePower = vars[VAR_HOURLY_POWER_SUM] / fights;

                if(averagePower > vars[VAR_HOURLY_MAX_POWER_AVERAGE])
                    vars[VAR_HOURLY_MAX_POWER_AVERAGE] = averagePower;
            }
            vars[VAR_HOURLY_POWER_AVERAGE] = ABDKMath64x64.divu(vars[VAR_PARAM_HOURLY_MAX_POWER_PERCENT],100)
                .mulu(vars[VAR_HOURLY_MAX_POWER_AVERAGE]);

            vars[VAR_DAILY_MAX_CLAIM] = vars[VAR_HOURLY_PAY_PER_FIGHT] * vars[VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT];
            vars[VAR_HOURLY_FIGHTS] = 0;
            vars[VAR_HOURLY_POWER_SUM] = 0;
        }
    }

    function _payPlayer(address playerAddress, int128 baseAmount) internal {
        _payPlayerConverted(playerAddress, usdToSkill(baseAmount));
    }

    function _payPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        skillToken.transfer(playerAddress, convertedAmount);
    }

    function setCharacterMintValue(uint256 cents) public restricted {
        mintCharacterFee = ABDKMath64x64.divu(cents, 100);
    }

    function setWeaponMintValue(uint256 cents) public restricted {
        mintWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setStaminaCostFight(uint8 points) public restricted {
        staminaCostFight = points;
    }

    function setDurabilityCostFight(uint8 points) public restricted {
        durabilityCostFight = points;
    }

    function setFightXpGain(uint256 average) public restricted {
        fightXpGain = average;
    }

    function setRewardsClaimTaxMaxAsPercent(uint256 _percent) public restricted {
        rewardsClaimTaxMax = ABDKMath64x64.divu(_percent, 100);
    }

    function setRewardsClaimTaxDuration(uint256 _rewardsClaimTaxDuration) public restricted {
        rewardsClaimTaxDuration = _rewardsClaimTaxDuration;
    }

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function giveInGameOnlyFunds(address to, uint256 skillAmount) external restricted {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        skillToken.safeTransferFrom(msg.sender, address(this), skillAmount);

        emit InGameOnlyFundsGiven(to, skillAmount);
    }

    function _giveInGameOnlyFundsFromContractBalance(address to, uint256 skillAmount) internal {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        emit InGameOnlyFundsGiven(to, skillAmount);
    }

    function giveInGameOnlyFundsFromContractBalance(address to, uint256 skillAmount) external restricted {
        _giveInGameOnlyFundsFromContractBalance(to, skillAmount);
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    function claimTokenRewards() public {
        claimTokenRewards(getRemainingTokenClaimAmountPreTax());
    }

    function claimTokenRewards(uint256 _claimingAmount) public {

        trackDailyClaim(_claimingAmount);

        uint256 _tokenRewardsToPayOut = _claimingAmount.sub(
            _getRewardsClaimTax(msg.sender).mulu(_claimingAmount)
        );

        // Tax goes to game contract itself, which would mean
        // transferring from the game contract to ...itself.
        // So we don't need to do anything with the tax part of the rewards.
        if(promos.getBit(msg.sender, 4) == false) {
            _payPlayerConverted(msg.sender, _tokenRewardsToPayOut);
            if(_tokenRewardsToPayOut <= vars[VAR_UNCLAIMED_SKILL])
                vars[VAR_UNCLAIMED_SKILL] -= _tokenRewardsToPayOut;
        }
    }

    function trackDailyClaim(uint256 _claimingAmount) internal {

        if(isDailyTokenClaimAmountExpired()) {
            userVars[msg.sender][USERVAR_CLAIM_TIMESTAMP] = now;
            userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT] = 0;
        }
        require(_claimingAmount <= getRemainingTokenClaimAmountPreTax() && _claimingAmount > 0);
        // safemath throws error on negative
        tokenRewards[msg.sender] = tokenRewards[msg.sender].sub(_claimingAmount);
        userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT] += _claimingAmount;
    }

    function isDailyTokenClaimAmountExpired() public view returns (bool) {
        return userVars[msg.sender][USERVAR_CLAIM_TIMESTAMP] <= now - 1 days;
    }

    function getClaimedTokensToday() public view returns (uint256) {
        // if claim timestamp is older than a day, it's reset to 0
        return isDailyTokenClaimAmountExpired() ? 0 : userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT];
    }

    function getRemainingTokenClaimAmountPreTax() public view returns (uint256) {
        // used to get how much can be withdrawn until the daily withdraw timer expires
        uint256 max = getMaxTokenClaimAmountPreTax();
        uint256 claimed = getClaimedTokensToday();
        if(claimed >= max)
            return 0; // all tapped out for today
        uint256 remainingOfMax = max-claimed;
        return tokenRewards[msg.sender] >= remainingOfMax ? remainingOfMax : tokenRewards[msg.sender];
    }

    function getMaxTokenClaimAmountPreTax() public view returns(uint256) {
        // if tokenRewards is above VAR_CLAIM_DEPOSIT_AMOUNT, we let them withdraw more
        // this function does not account for amount already withdrawn today
        if(tokenRewards[msg.sender] >= vars[VAR_CLAIM_DEPOSIT_AMOUNT]) { // deposit bonus active
            // max is either 10% of amount above deposit, or 2x the regular limit, whichever is higher
            uint256 aboveDepositAdjusted = ABDKMath64x64.divu(vars[VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT],100)
                .mulu(tokenRewards[msg.sender]-vars[VAR_CLAIM_DEPOSIT_AMOUNT]); // 10% above deposit
            if(aboveDepositAdjusted > vars[VAR_DAILY_MAX_CLAIM] * 2) {
                return aboveDepositAdjusted;
            }
            return vars[VAR_DAILY_MAX_CLAIM] * 2;
        }
        return vars[VAR_DAILY_MAX_CLAIM];
    }

    function stakeUnclaimedRewards() public {
        stakeUnclaimedRewards(getRemainingTokenClaimAmountPreTax());
    }

    function stakeUnclaimedRewards(uint256 amount) public {

        trackDailyClaim(amount);

        if(promos.getBit(msg.sender, 4) == false) {
            skillToken.approve(address(stakeFromGameImpl), amount);
            stakeFromGameImpl.stakeFromGame(msg.sender, amount);
        }
    }

    function claimXpRewards() public {
        // our characters go to the tavern to rest
        // they meditate on what they've learned

        uint256[] memory chars = characters.getReadyCharacters(msg.sender);
        require(chars.length > 0);
        uint256[] memory xps = new uint256[](chars.length);
        for(uint256 i = 0; i < chars.length; i++) {
            xps[i] = xpRewards[chars[i]];
            xpRewards[chars[i]] = 0;
        }
        characters.gainXpAll(chars, xps);
    }

    function resetXp(uint256[] memory chars) public restricted {
        for(uint256 i = 0; i < chars.length; i++) {
            xpRewards[chars[i]] = 0;
        }
    }

    function getTokenRewards() public view returns (uint256) {
        return tokenRewards[msg.sender];
    }

    function getXpRewards(uint256[] memory chars) public view returns (uint256[] memory) {
        uint charsAmount = chars.length;
        uint256[] memory xps = new uint256[](charsAmount);
        for(uint i = 0; i < chars.length; i++) {
            xps[i] = xpRewards[chars[i]];
        }
        return xps;
    }

    function getTokenRewardsFor(address wallet) public view returns (uint256) {
        return tokenRewards[wallet];
    }

    function getTotalSkillOwnedBy(address wallet) public view returns (uint256) {
        return inGameOnlyFunds[wallet] + getTokenRewardsFor(wallet) + skillToken.balanceOf(wallet);
    }

    function _getRewardsClaimTax(address playerAddress) internal view returns (int128) {
        assert(_rewardsClaimTaxTimerStart[playerAddress] <= block.timestamp);

        uint256 rewardsClaimTaxTimerEnd = _rewardsClaimTaxTimerStart[playerAddress].add(rewardsClaimTaxDuration);

        (, uint256 durationUntilNoTax) = rewardsClaimTaxTimerEnd.trySub(block.timestamp);

        assert(0 <= durationUntilNoTax && durationUntilNoTax <= rewardsClaimTaxDuration);

        int128 frac = ABDKMath64x64.divu(durationUntilNoTax, rewardsClaimTaxDuration);

        return rewardsClaimTaxMax.mul(frac);
    }

    function getOwnRewardsClaimTax() public view returns (int128) {
        return _getRewardsClaimTax(msg.sender);
    }

    function getMintWeaponFee() public view returns (int128) {
        int128 decrease = ABDKMath64x64.divu(block.timestamp.sub(vars[VAR_WEAPON_MINT_TIMESTAMP]).mul(vars[VAR_MINT_WEAPON_FEE_DECREASE_SPEED]), 1e18);
        int128 weaponFeeMin = ABDKMath64x64.divu(vars[VAR_MIN_WEAPON_FEE], 100);
        if(decrease > mintWeaponFee) {
            return weaponFeeMin;
        }
        if(mintWeaponFee - decrease < weaponFeeMin) {
            return weaponFeeMin;
        }
        return mintWeaponFee.sub(decrease);
    }

    function getMintCharacterFee() public view returns (int128) {
        int128 decrease = ABDKMath64x64.divu(block.timestamp.sub(vars[VAR_CHARACTER_MINT_TIMESTAMP]).mul(vars[VAR_MINT_CHARACTER_FEE_DECREASE_SPEED]), 1e18);
        int128 characterFeeMin = ABDKMath64x64.divu(vars[VAR_MIN_CHARACTER_FEE], 100);
        if(decrease > mintCharacterFee) {
            return characterFeeMin;
        }
        if(mintCharacterFee - decrease < characterFeeMin) {
            return characterFeeMin;
        }
        return mintCharacterFee.sub(decrease);
    }

}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Common {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint8;

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) internal pure returns (bool) {
        return (((attacker + 1) % 4) == defender); // Thanks to Tourist
    }

    function getPlayerPower(
        uint24 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) internal pure returns(uint24) {
        return uint24(weaponMultiplier.mulu(basePower).add(bonusPower));
    }

    function getBonusRankingPoints(uint256 weakerPower, uint256 strongerPower) internal pure returns (uint256) {
        // @TODO once tested transform to save gas: 
        // X < Y: (1 - ( (1.3*(x-y)/0.6*y) + (0.7*(y-x)/0.6*x) )) * 0.5
        // Note: Formula hard-copied in PvPArenaMatchMaking.vue due to contract size limitations in PvPArena.sol
        uint256 bonusRanking;

        uint256 strongerMinRoll = strongerPower.mul(90).div(100);
        uint256 strongerMaxRoll = strongerPower.mul(110).div(100);
 
        uint256 weakerMinRoll = weakerPower.mul(90).div(100);
        uint256 weakerMaxRoll = weakerPower.mul(110).div(100);

        uint256 strongerRollSpread = strongerMaxRoll.sub(strongerMinRoll);
        uint256 weakerRollSpread = weakerMaxRoll.sub(weakerMinRoll);

        uint256 rollOverlap = weakerMaxRoll.sub(strongerMinRoll);
       
        uint256 strongerRollChanceToOverlap = rollOverlap.mul(100).div(strongerRollSpread);

        uint256 weakerRollChanceToOverlap = rollOverlap.mul(100).div(weakerRollSpread);
        // A * B * 100 / 10000 * 2
        uint256 winChance = strongerRollChanceToOverlap.mul(weakerRollChanceToOverlap).mul(100).div(20000);

        if (winChance < 50) {
            bonusRanking = getBonusRankingPointFormula(uint256(50).sub(winChance));
            return bonusRanking;
        }
    }

    function getBonusRankingPointFormula(uint256 processedWinChance) internal pure returns (uint256) {
        // Note: Formula hard-copied in PvPArenaMatchMaking.vue due to contract size limitations in PvPArena.sol
        if (processedWinChance <= 40) {
            // Equivalent to (1.06**processedWinChance)
            return (53**processedWinChance).div(50**processedWinChance);
        } else {
            // Equivalent to (1.5**(1.3*processedWinChance - 48)) + 7
            return ((3**(processedWinChance.mul(13).div(10).sub(48))).div(2**(processedWinChance.mul(13).div(10).sub(48)))).add(7);
        }
    }

    function getPlayerPowerBase100(
        uint256 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) internal pure returns (uint24) {
        // we divide total power by 100 and add the base of 1000
       return uint24 (weaponMultiplier.mulu(basePower).add(bonusPower).div(100).add(1000));  
    }
    function getPowerAtLevel(uint8 level) internal pure returns (uint24) {
        // does not use fixed points since the numbers are simple
        // the breakpoints every 10 levels are floored as expected
        // level starts at 0 (visually 1)
        // 1000 at lvl 1
        // 9000 at lvl 51 (~3months)
        // 22440 at lvl 105 (~3 years)
        // 92300 at lvl 255 (heat death of the universe)
        return uint24(
            uint256(1000)
                .add(level.mul(10))
                .mul(level.div(10).add(1))
        );
    }

    function adjustDecimals(uint256 amount, uint256 decimals) internal pure returns (uint256 adjustedAmount){
        if(decimals > 18) {
            adjustedAmount = amount.mul(10**uint(decimals - 18));
        } else {
            adjustedAmount = amount.div(10**uint(18 - decimals));
        }
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./util.sol";
import "./Garrison.sol";
import "./common.sol";

contract Characters is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using SafeMath for uint16;
    using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Copied from promos.sol, to avoid paying 5k gas to query a constant.
    uint256 private constant BIT_FIRST_CHARACTER = 1;

    function initialize () public initializer {
        __ERC721_init("CryptoBlades character", "CBC");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_1ee400a(uint256[255] memory _experienceTable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        experienceTable = _experienceTable;
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    function migrateTo_b627f23() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        characterLimit = 4;
    }

    function migrateTo_1a19cbb(Garrison _garrison) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        garrison = _garrison;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-256
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
    */

    struct Character {
        uint16 xp; // xp to next level
        uint8 level; // up to 256 cap
        uint8 trait; // 2b trait, TBD
        uint64 staminaTimestamp; // standard timestamp in seconds-resolution marking regen start from 0
    }
    struct CharacterCosmetics {
        uint8 version;
        uint256 seed;
    }

    Character[] private tokens;
    CharacterCosmetics[] private cosmetics;

    uint256 public constant maxStamina = 200;
    uint256 public constant secondsPerStamina = 300; //5 * 60

    uint256[256] private experienceTable; // fastest lookup in the west

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    Promos public promos;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    uint256 public characterLimit;

    mapping(uint256 => uint256) public raidsDone;
    mapping(uint256 => uint256) public raidsWon;

    uint256 public constant NFTVAR_SIMPLEQUEST_PROGRESS = 101;
    uint256 public constant NFTVAR_SIMPLEQUEST_TYPE = 102;
    uint256 public constant NFTVAR_REPUTATION = 103;

    uint256 public constant SIMPLEQUEST_TYPE_RAID = 8;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars; // nftID, fieldID, value
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..

    Garrison public garrison;

    uint256 public constant NFTVAR_BONUS_POWER = 2;

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(address indexed owner, uint256 indexed character, uint16 level);
    event Burned(address indexed owner, uint256 indexed id);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NA");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    modifier minterOnly() {
        _minterOnly();
        _;
    }

    function _minterOnly() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(MINTER_ROLE, msg.sender), 'no access');
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function get(uint256 id) public view noFreshLookup(id) returns (uint16, uint8, uint8, uint64, uint16, uint16, uint16, uint16, uint16, uint16) {
        Character memory c = tokens[id];
        CharacterCosmetics memory cc = cosmetics[id];
        return (c.xp, c.level, c.trait, c.staminaTimestamp,
            getRandomCosmetic(cc.seed, 1, 13), // head
            getRandomCosmetic(cc.seed, 2, 45), // arms
            getRandomCosmetic(cc.seed, 3, 61), // torso
            getRandomCosmetic(cc.seed, 4, 41), // legs
            getRandomCosmetic(cc.seed, 5, 22), // boots
            getRandomCosmetic(cc.seed, 6, 2) // race
        );
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint16 limit) private pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getCosmeticsSeed(uint256 id) public view noFreshLookup(id) returns (uint256) {
        CharacterCosmetics memory cc = cosmetics[id];
        return cc.seed;
    }

    function getSoulForBurns(uint256[] calldata burnIds) external view returns (uint256) {
        uint256 soulAmount = 0;
        for(uint i = 0; i < burnIds.length; i++) {
            soulAmount += getTotalPower(burnIds[i]).div(10);
        }
        return soulAmount;
    }

    function mint(address minter, uint256 seed) public restricted {
        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        uint64 staminaTimestamp = uint64(now.sub(getStaminaMaxWait()));

        tokens.push(Character(xp, level, trait, staminaTimestamp));
        cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
        address receiver = minter;
        if(minter != address(0) && minter != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, minter) && balanceOf(minter) >= characterLimit) {
            receiver = address(garrison);
            garrison.redirectToGarrison(minter, tokenID);
            _mint(address(garrison), tokenID);
        }
        else {
            _mint(minter, tokenID);
        }
        emit NewCharacter(tokenID, receiver);
    }

    function customMint(address minter, uint16 xp, uint8 level, uint8 trait, uint256 seed, uint256 tokenID, uint24 bonusPower, uint16 reputation) minterOnly public returns (uint256) {
        uint64 staminaTimestamp = uint64(now); // 0 on purpose to avoid chain jumping abuse

        if(tokenID == 0){
            tokenID = tokens.length;

            if(block.number != lastMintedBlock)
                firstMintedOfLastBlock = tokenID;
            lastMintedBlock = block.number;

            tokens.push(Character(xp, level, trait, staminaTimestamp));
            cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
            address receiver = minter;
            if(minter != address(0) && minter != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, minter) && balanceOf(minter) >= characterLimit) {
                receiver = address(garrison);
                garrison.redirectToGarrison(minter, tokenID);
                _mint(address(garrison), tokenID);
            }
            else {
                _mint(minter, tokenID);
            }
            emit NewCharacter(tokenID, receiver);
        }
        else {
            Character storage ch = tokens[tokenID];
            ch.xp = xp;
            ch.level = level;
            ch.trait = trait;
            ch.staminaTimestamp = staminaTimestamp;

            CharacterCosmetics storage cc = cosmetics[tokenID];
            cc.seed = seed;
        }

        nftVars[tokenID][NFTVAR_BONUS_POWER] = bonusPower;
        nftVars[tokenID][NFTVAR_REPUTATION] = reputation;

        return tokenID;
    }

    function burnIntoCharacter(uint256[] calldata burnIds, uint256 targetCharId, uint256 burnPowerMultiplier) external restricted {
        uint256 burnPower = 0;
        for(uint i = 0; i < burnIds.length; i++) {
            burnPower += nftVars[burnIds[i]][NFTVAR_BONUS_POWER].add(getPowerAtLevel(tokens[burnIds[i]].level));
            address burnOwner = ownerOf(burnIds[i]);
            if(burnOwner == address(garrison)) {
                burnOwner = garrison.characterOwner(burnIds[i]);
                garrison.updateOnBurn(burnOwner, burnIds[i]);
            }
            _burn(burnIds[i]);

            emit Burned(
                burnOwner,
                burnIds[i]
            );
        }
        require(uint(4).mul(getPowerAtLevel(tokens[targetCharId].level)) >= getTotalPower(targetCharId).add(burnPower), "Power limit");
        nftVars[targetCharId][NFTVAR_BONUS_POWER] = burnPower.mul(burnPowerMultiplier).div(1e18).add(nftVars[targetCharId][NFTVAR_BONUS_POWER]);
    }

    function burnIntoSoul(uint256[] calldata burnIds) external restricted {
        for(uint i = 0; i < burnIds.length; i++) {
            address burnOwner = ownerOf(burnIds[i]);
            if(burnOwner == address(garrison)) {
                burnOwner = garrison.characterOwner(burnIds[i]);
                garrison.updateOnBurn(burnOwner, burnIds[i]);
            }
            _burn(burnIds[i]);

            emit Burned(
                burnOwner,
                burnIds[i]
            );
        }
    }

    function upgradeWithSoul(uint256 targetCharId, uint256 soulAmount) external restricted {
        uint256 burnPower = soulAmount.mul(10);
        require(uint(4).mul(getPowerAtLevel(tokens[targetCharId].level)) >= getTotalPower(targetCharId).add(burnPower), "Power limit");
        nftVars[targetCharId][NFTVAR_BONUS_POWER] = burnPower.add(nftVars[targetCharId][NFTVAR_BONUS_POWER]);
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level; // this is used by dataminers and it benefits us
    }

    function getRequiredXpForNextLevel(uint8 currentLevel) public view returns (uint16) {
        return uint16(experienceTable[currentLevel]); // this is helpful to users as the array is private
    }

    function getPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return getPowerAtLevel(tokens[id].level);
    }

    function getTotalPower(uint256 id) public view noFreshLookup(id) returns (uint256) {
        return nftVars[id][NFTVAR_BONUS_POWER].add(getPowerAtLevel(tokens[id].level));
    }

    function getPowerAtLevel(uint8 level) public pure returns (uint24) {
        return Common.getPowerAtLevel(level);
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].trait;
    }

    function setTrait(uint256 id, uint8 trait) public restricted {
        tokens[id].trait = trait;
    }

    function getXp(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return tokens[id].xp;
    }

    function gainXp(uint256 id, uint16 xp) public restricted {
        _gainXp(id, xp);
    }

    function _gainXp(uint256 id, uint256 xp) internal {
        Character storage char = tokens[id];
        if (char.level < 255) {
            uint newXp = char.xp.add(xp);
            uint requiredToLevel = experienceTable[char.level]; // technically next level
            while (newXp >= requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level += 1;
                emit LevelUp(ownerOf(id), id, char.level);
                if (char.level < 255)
                    requiredToLevel = experienceTable[char.level];
                else newXp = 0;
            }
            char.xp = uint16(newXp);
        }
    }

    function gainXpAll(uint256[] calldata chars, uint256[] calldata xps) external restricted {
        for(uint i = 0; i < chars.length; i++)
            _gainXp(chars[i], xps[i]);
    }

    function getStaminaTimestamp(uint256 id) public view noFreshLookup(id) returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function getStaminaPoints(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStaminaPointsFromTimestamp(tokens[id].staminaTimestamp);
    }

    function getStaminaPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerStamina;
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view noFreshLookup(id) returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }

    function getFightDataAndDrainStamina(address fighter,
        uint256 id, uint8 amount, bool allowNegativeStamina, uint256 busyFlag) public restricted returns(uint96) {
        require(fighter == ownerOf(id) && nftVars[id][NFTVAR_BUSY] == 0);
        nftVars[id][NFTVAR_BUSY] |= busyFlag;

        Character storage char = tokens[id];
        uint8 staminaPoints = getStaminaPointsFromTimestamp(char.staminaTimestamp);
        require((staminaPoints > 0 && allowNegativeStamina) // we allow going into negative, but not starting negative
            || staminaPoints >= amount, "Not enough stamina!");

        uint64 drainTime = uint64(amount * secondsPerStamina);
        uint64 preTimestamp = char.staminaTimestamp;
        if(staminaPoints >= maxStamina) { // if stamina full, we reset timestamp and drain from that
            char.staminaTimestamp = uint64(now - getStaminaMaxWait() + drainTime);
        }
        else {
            char.staminaTimestamp = uint64(char.staminaTimestamp + drainTime);
        }
        // bitwise magic to avoid stacking limitations later on
        return uint96(char.trait | (getTotalPower(id) << 8) | (preTimestamp << 32));
    }

    function processRaidParticipation(uint256 id, bool won, uint16 xp) public restricted {
        raidsDone[id] = raidsDone[id] + 1;
        raidsWon[id] = won ? (raidsWon[id] + 1) : (raidsWon[id]);
        require(nftVars[id][NFTVAR_BUSY] == 0); // raids do not apply busy flag for now
        //nftVars[id][NFTVAR_BUSY] = 0;
        _gainXp(id, xp);
        if (getNftVar(id, NFTVAR_SIMPLEQUEST_TYPE) == SIMPLEQUEST_TYPE_RAID) {
            uint currentProgress = getNftVar(id, NFTVAR_SIMPLEQUEST_PROGRESS);
            setNftVar(id, NFTVAR_SIMPLEQUEST_PROGRESS, ++currentProgress);
        }
    }

    function getCharactersOwnedBy(address wallet) public view returns(uint256[] memory chars) {
        uint256 count = balanceOf(wallet);
        chars = new uint256[](count);
        for(uint256 i = 0; i < count; i++)
            chars[i] = tokenOfOwnerByIndex(wallet, i);
    }

    function getReadyCharacters(address wallet) public view returns(uint256[] memory chars) {
        uint256[] memory owned = getCharactersOwnedBy(wallet);
        uint256 ready = 0;
        for(uint i = 0; i < owned.length; i++)
            if(nftVars[owned[i]][NFTVAR_BUSY] == 0)
                ready++;
        chars = new uint[](ready);
        for(uint i = 0; i < owned.length; i++)
            if(nftVars[owned[i]][NFTVAR_BUSY] == 0)
                chars[--ready] = owned[i];
    }

    function setNFTVars(uint256 id, uint256[] memory fields, uint256[] memory values) public restricted {
        for(uint i = 0; i < fields.length; i++)
            nftVars[id][fields[i]] = values[i];
    }

    function getNFTVars(uint256 id, uint256[] memory fields) public view returns(uint256[] memory values) {
        values = new uint256[](fields.length);
        for(uint i = 0; i < fields.length; i++)
            values[i] = nftVars[id][fields[i]];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(nftVars[tokenId][NFTVAR_BUSY] == 0);
        address[] memory users = new address[](2);
        users[0] = from;
        users[1] = to;
        promos.setBits(users, BIT_FIRST_CHARACTER);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) override public {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to) && balanceOf(to) >= characterLimit) {
            garrison.redirectToGarrison(to, tokenId);
            super.safeTransferFrom(from, address(garrison), tokenId);
        }
        else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function getNftVar(uint256 characterID, uint256 nftVar) public view returns(uint256) {
        return nftVars[characterID][nftVar];
    }
    function setNftVar(uint256 characterID, uint256 nftVar, uint256 value) public restricted {
        nftVars[characterID][nftVar] = value;
    }

    function setBaseURI(string memory baseUri) public restricted {
        _setBaseURI(baseUri);
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./SafeRandoms.sol";
import "./util.sol";
import "./staking/StakingRewardsUpgradeable.sol";
import "./interfaces/IPriceOracle.sol";

contract SpecialWeaponsManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SPECIAL_WEAPON_SEED = keccak256("SPECIAL_WEAPON_SEED");

    // STATE
    Promos public promos;
    Weapons public weapons;
    SafeRandoms public safeRandoms;
    CryptoBlades public game;
    IPriceOracle public priceOracleSkillPerUsd;

    struct EventInfo {
        string name;
        uint8 weaponElement;
        uint256 endTime;
        uint256 supply;
        uint256 orderedCount;
    }

    mapping(address => mapping(uint256 => uint256)) public userEventShardSupply;
    mapping(uint256 => uint256) public vars;
    uint256 public constant VAR_SHARD_COST_LOW = 1;
    uint256 public constant VAR_SHARD_COST_MEDIUM = 2;
    uint256 public constant VAR_SHARD_COST_HIGH = 3;
    uint256 public constant VAR_SKILL_USD_COST_LOW = 4;
    uint256 public constant VAR_SKILL_USD_COST_MEDIUM = 5;
    uint256 public constant VAR_SKILL_USD_COST_HIGH = 6;
    uint256 public constant VAR_CONVERT_RATIO_DENOMINATOR = 10;
    uint256 public constant VAR_DAILY_SHARDS_PER_SKILL_STAKED = 11;
    uint256 public eventCount;

    mapping(uint256 => EventInfo) public eventInfo;
    mapping(address => mapping(uint256 => bool)) public userForgedAtEvent;
    mapping(address => mapping(uint256 => uint256)) public userOrderOptionForEvent;
    mapping(address => uint256) userStakedSkill;
    mapping(address => uint256) userStakedSkillUpdatedTimestamp;
    mapping(address => uint256) userSkillStakingShardsRewards;
    mapping(uint256 => string) public specialWeaponArt;
    mapping(uint256 => string) public specialWeaponDetails;
    mapping(uint256 => string) public specialWeaponWebsite;
    mapping(uint256 => string) public specialWeaponNote;


    function initialize(Promos _promos, Weapons _weapons, SafeRandoms _safeRandoms, CryptoBlades _game, IPriceOracle _priceOracleSkillPerUsd)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        promos = _promos;
        weapons = _weapons;
        safeRandoms = _safeRandoms;
        game = _game;
        priceOracleSkillPerUsd = _priceOracleSkillPerUsd;
        eventCount = 0;
    }

    // MODIFIERS

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    modifier hasMinterRole() {
        _hasMinterRole();
        _;
    }

    function _hasMinterRole() internal view {
        require(hasRole(MINTER_ROLE, msg.sender), "Not minter");
    }

    modifier isValidOption(uint256 orderOption) {
        _isValidOption(orderOption);
        _;
    }

    function _isValidOption(uint256 orderOption) internal pure {
        require(orderOption >= 1 && orderOption <= 3, "Invalid option");
    }

    modifier isEventActive(uint256 eventId) {
        _isEventActive(eventId);
        _;
    }

    function _isEventActive(uint256 eventId) internal view {
        require(getIsEventActive(eventId), "Event inactive");
    }

    modifier canBeOrdered(uint256 eventId) {
        _canBeOrdered(eventId);
        _;
    }

    function _canBeOrdered(uint256 eventId) internal view {
        require(userOrderOptionForEvent[msg.sender][eventId] == 0, "Limit 1");
        require(hasRemainingSupply(eventId), "Sold out");
    }

    // VARS

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    // VIEWS

    function getSeed(uint256 eventId) internal pure returns(uint256 seed) {
        seed = uint(keccak256(abi.encodePacked(SPECIAL_WEAPON_SEED, uint(1), eventId)));
    }

    function getActiveEventsIds() public view returns(uint256[] memory) {
        uint256[] memory activeEventIds = new uint256[](getActiveEventsCount());
        uint256 arrayIterator = 0;
        for(uint i = 1; i <= eventCount; i++) {
            if(eventInfo[i].endTime > block.timestamp) {
                activeEventIds[arrayIterator++] = i;
            }
        }

        return activeEventIds;
    }

    function getActiveEventsCount() public view returns(uint256 activeEventsCount) {
        for(uint i = 0; i <= eventCount; i++) {
            if(getIsEventActive(i)) {
                activeEventsCount++;
            }
        }
    }

    function getIsEventActive(uint256 eventId) public view returns(bool) {
        return eventInfo[eventId].endTime > block.timestamp;
    }

    function hasRemainingSupply(uint256 eventId) public view returns(bool) {
        return eventInfo[eventId].supply == 0 || eventInfo[eventId].orderedCount < eventInfo[eventId].supply;
    }

    function getTotalOrderedCount(uint256 eventId) public view returns(uint256) {
        return eventInfo[eventId].orderedCount;
    }

    function getEventInfo(uint256 eventId) public view returns(string memory, uint8, uint256, uint256, uint256) {
        EventInfo memory info = eventInfo[eventId];
        return (info.name, info.weaponElement, info.endTime, info.supply, info.orderedCount);
    }

    function getUserSpecialShardsSupply(address user, uint256 eventId) public view returns(uint256) {
        return userEventShardSupply[user][eventId];
    }

    function getUserShardsRewards(address user) public view returns(uint256) {
        return userSkillStakingShardsRewards[user]
            .add(userStakedSkill[user]
                .mul(vars[VAR_DAILY_SHARDS_PER_SKILL_STAKED])
                .mul(block.timestamp - userStakedSkillUpdatedTimestamp[user])
                .div(60 * 60 * 24)
                .div(1e18)
            );
    }

    function getSkillForgeCost(uint256 orderOption) public view returns(uint256) {
        return usdToSkill(ABDKMath64x64.divu(vars[orderOption + 3], 1));
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    function getSpecialWeaponData(uint256 eventId) public view returns (string memory, string memory, string memory, string memory) {
        return (specialWeaponArt[eventId], specialWeaponDetails[eventId], specialWeaponWebsite[eventId], specialWeaponNote[eventId]);
    }

    // FUNCTIONS

    // supply 0 = unlimited
    function startNewEvent(string calldata name, uint8 element, uint256 period, uint256 supply, string calldata art, string calldata details, string calldata website, string calldata note) external restricted {
        uint eventId = ++eventCount;
        eventInfo[eventId] = EventInfo(
            name,
            element,
            block.timestamp + period,
            supply,
            0
        );
        specialWeaponArt[eventId] = art;
        specialWeaponDetails[eventId] = details;
        specialWeaponWebsite[eventId] = website;
        specialWeaponNote[eventId] = note;
    }

    function incrementEventCount() external restricted {
        eventCount++;
    }

    function updateStakingReward(address user, uint256 stakingAmount) external restricted {
        userSkillStakingShardsRewards[user] = getUserShardsRewards(user);
        userStakedSkill[user] = stakingAmount;
        userStakedSkillUpdatedTimestamp[user] = block.timestamp;
    }

    function claimShardRewards(uint256 eventId, uint256 amount) external {
        require(amount.mul(1e18) <= getUserShardsRewards(msg.sender), "Not enough rewards");
        userSkillStakingShardsRewards[msg.sender] = getUserShardsRewards(msg.sender).sub(amount.mul(1e18));
        userStakedSkillUpdatedTimestamp[msg.sender] = block.timestamp;
        userEventShardSupply[msg.sender][eventId] += amount;
    }

    function orderSpecialWeaponWithShards(uint256 eventId, uint256 orderOption) public canBeOrdered(eventId) isEventActive(eventId) isValidOption(orderOption) {
        require(userEventShardSupply[msg.sender][eventId] >= vars[orderOption], "Not enough shards");
        userEventShardSupply[msg.sender][eventId] -= vars[orderOption];
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        eventInfo[eventId].orderedCount++;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function orderSpecialWeaponWithSkill(uint256 eventId, uint256 orderOption) public canBeOrdered(eventId) isEventActive(eventId) isValidOption(orderOption) {
        game.payContractTokenOnly(msg.sender, getSkillForgeCost(orderOption));
        userOrderOptionForEvent[msg.sender][eventId] = orderOption;
        eventInfo[eventId].orderedCount++;
        safeRandoms.requestSingleSeed(msg.sender, getSeed(eventId));
    }

    function forgeSpecialWeapon(uint256 eventId) public {
        require(userOrderOptionForEvent[msg.sender][eventId] > 0, 'Nothing to forge');
        require(!userForgedAtEvent[msg.sender][eventId], 'Already forged');
        userForgedAtEvent[msg.sender][eventId] = true;
        mintSpecial(
            msg.sender,
            eventId,
            safeRandoms.popSingleSeed(msg.sender, getSeed(eventId), true, false),
            userOrderOptionForEvent[msg.sender][eventId],
            eventInfo[eventId].weaponElement
        );
    }

    function addShards(address user, uint256 eventId, uint256 shardsAmount) external restricted isEventActive(eventId){
        userEventShardSupply[user][eventId] += shardsAmount;
    }

    function mintSpecial(address minter, uint256 eventId, uint256 seed, uint256 orderOption, uint8 element) private returns(uint256) {
        uint256 stars;
        uint256 roll = seed % 100;
        if(orderOption == 3) {
            stars = 4;
        }
        else if(orderOption == 2) {
            if(roll < 16) {
                stars = 4;
            }
            else {
                stars = 3;
            }
        }
        else {
            if(roll < 5) {
                stars = 4;
            }
            else if (roll < 28) {
                stars = 3;
            }
            else {
                stars = 2;
            }
        }

        return mintSpecialWeaponWithStars(minter, eventId, stars, seed, element);
    }

    function mintSpecialWeaponWithStars(address minter, uint256 eventId, uint256 stars, uint256 seed, uint8 element) private returns(uint256) {
        return weapons.mintSpecialWeapon(minter, eventId, stars, seed, element);
    }

    function convertShards(uint256 eventIdFrom, uint256 eventIdTo, uint256 amount) external isEventActive(eventIdTo) {
        require(userEventShardSupply[msg.sender][eventIdFrom] >= amount, 'Not enough shards');
        userEventShardSupply[msg.sender][eventIdFrom] -= amount;
        uint256 convertedAmount = amount.div(vars[VAR_CONVERT_RATIO_DENOMINATOR]);
        convertedAmount += userEventShardSupply[msg.sender][eventIdFrom] == 0 && amount % vars[VAR_CONVERT_RATIO_DENOMINATOR] > 0 ? 1 : 0;
        userEventShardSupply[msg.sender][eventIdTo] += convertedAmount;
    }

    function updateEventEndTime(uint256 eventId, uint256 endTime) external restricted {
        eventInfo[eventId].endTime = endTime;
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function privatePartnerOrder(address[] calldata receivers, uint256 eventId, uint256 orderOption) external hasMinterRole isValidOption(orderOption) isEventActive(eventId) {
        require(eventInfo[eventId].supply == 0 || receivers.length + eventInfo[eventId].orderedCount <= eventInfo[eventId].supply, "Not enough supply");
        for(uint i = 0; i < receivers.length; i++) {
            if(userOrderOptionForEvent[receivers[i]][eventId] != 0) continue;
            userOrderOptionForEvent[receivers[i]][eventId] = orderOption;
            eventInfo[eventId].orderedCount++;
            safeRandoms.requestSingleSeed(receivers[i], getSeed(eventId));
        }
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function privatePartnerMint(address[] calldata receivers, uint256 eventId, uint256 orderOption) external hasMinterRole isValidOption(orderOption) isEventActive(eventId) {
        require(eventInfo[eventId].supply == 0 || receivers.length + eventInfo[eventId].orderedCount <= eventInfo[eventId].supply, "Not enough supply");
        for(uint i = 0; i < receivers.length; i++) {
            if(userOrderOptionForEvent[receivers[i]][eventId] != 0 || userForgedAtEvent[receivers[i]][eventId]) continue;
            userOrderOptionForEvent[receivers[i]][eventId] = orderOption;
            eventInfo[eventId].orderedCount++;
            userForgedAtEvent[receivers[i]][eventId] = true;
            mintSpecial(
                receivers[i],
                eventId,
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), receivers[i]))),
                userOrderOptionForEvent[receivers[i]][eventId],
                eventInfo[eventId].weaponElement
            );
        }
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function reserveForGiveaways(address reservingAddress, uint256 eventId, uint256 orderOption, uint256 amount) external hasMinterRole isValidOption(orderOption) isEventActive(eventId) {
        require(eventInfo[eventId].supply == 0 || amount + eventInfo[eventId].orderedCount <= eventInfo[eventId].supply, "Not enough supply");
        for(uint i = 0; i < amount; i++) {
            eventInfo[eventId].orderedCount++;
            mintSpecial(
                reservingAddress,
                eventId,
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), reservingAddress, i))),
                orderOption,
                eventInfo[eventId].weaponElement
            );
        }
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function createManualEvent(string calldata name, uint8 element) external restricted {
        eventInfo[++eventCount] = EventInfo(
            name,
            element,
            1, // end time 1 to differentiate from non existing events
            0,
            0
        );
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function mintOrderOptionForManualEvent(address[] calldata receivers, uint256 eventId, uint256 orderOption) external hasMinterRole isValidOption(orderOption) {
        require(eventInfo[eventId].endTime == 1, "Wrong event id");
        for(uint i = 0; i < receivers.length; i++) {
            eventInfo[eventId].orderedCount++;
            mintSpecial(
                receivers[i],
                eventId,
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), receivers[i]))),
                orderOption,
                eventInfo[eventId].weaponElement
            );
        }
    }

    // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
    function mintStarsForManualEvent(address[] calldata receivers, uint256 eventId, uint256 stars) external hasMinterRole {
        require(eventInfo[eventId].endTime == 1, "Wrong event id");
        require(stars >= 2 && stars <= 4, "Wrong stars");
        for(uint i = 0; i < receivers.length; i++) {
            eventInfo[eventId].orderedCount++;
            mintSpecialWeaponWithStars(
                receivers[i],
                eventId,
                stars,
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), receivers[i]))),
                eventInfo[eventId].weaponElement
            );
        }
    }

    // SETTERS

    function setSpecialWeaponArt(uint256 eventId, string calldata art) external restricted {
        specialWeaponArt[eventId] = art;
    }

    function setSpecialWeaponDetails(uint256 eventId, string calldata details) external restricted {
        specialWeaponDetails[eventId] = details;
    }

    function setSpecialWeaponWebsite(uint256 eventId, string calldata website) external restricted {
        specialWeaponWebsite[eventId] = website;
    }

    function setSpecialWeaponNote(uint256 eventId, string calldata note) external restricted {
        specialWeaponNote[eventId] = note;
    }

}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SafeRandoms is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    /* Security
    *   Seeds are more secure the faster they are resolved
    *   Resolution every block = 100% security
    *   Optionally, publicResolutionBlocks can be set to 0 to force admin resolution
    */

    /* Usage:
    *
    *   Transaction #1: Have the user pay costs (if applicable) and request the seed
    *   Transaction #2: Pop the seed (will revert if not ready, use check if necessary)
    *
    *   After popping, you can use one seed for multiple outcomes (ie 10 weapon seeds)
    *   Just make sure to re-encode with keccak256(abi.encodePacked(seed,value...))
    *   ONLY with values that won't change over time:
    *   ie. block.number: NO
    *   1,2,3 etc: YES, IF seeds aren't shared under the same action identifier
    *    (so 1x weapons produce different requestIDs than 10x weapons)
    *
    *   You can use the requestNext boolean for pop calls to request the next seed already,
    *   This allows you to have a new secure seed ready for every transaction (except the first)
    *
    *   Resolve booleans of functions contribute to seed resolution,
    *   (sending false can be used to save gas if necessary)
    *    Check costs ~2k gas, resolution costs 35k (+3.1k for event + 1.7k for event check)
    */

    /* Seed Types
    *
    *   Single (One-at-a-time) seeds:
    *    Only one request possible per user for this type at a time
    *    The seed must be used before another one can be requested
    *    Can be used for actions that don't have up-front cost (besides gas)
    *     But! Consider possibility that the user may transfer NFT to another wallet or bridge networks
    *    These seeds can be salted after without popping to produce expectable results if tolerable
    *     (this saves gas if the initial action needed security but the following ones don't)
    *     ! Salted seeds are stored separately, the original one-at-a-time seed will be available raw
    *
    *   Queued seeds:
    *    More than one seed request can be piled up (costs ~15-20k more gas than single seeds)
    *    Example use: Ordering multiple batches of weapons without requiring the first batch to complete
    *    MUST HAVE a full upfront cost to avoid abuse! (ie skill cost to mint an NFT)
    *
    *   !!! IMPORTANT !!!!
    *    Seed types are not to be mixed for the same action type!
    *    Requesting a queued seed and popping a one-timer won't work, and vice versa
    */

    /* RequestIDs
    *
    *   Request ID is a unique value to identify the exact action a random seed is requested for.
    *   A seed requested for 1x weapon mint must be different than for 10x weapon mints etc.
    *
    *   Produce clean looking request IDs for two properties:
    *    RandomUtil.combineSeeds(SEED_WEAPON_MINT, amount)
    *
    *   Or dirtier / for many properties: (you can slap arrays into encodePacked directly)
    *    uint(keccak256(abi.encodePacked(SEED_WEAPON_MINT, amount, special_weapon_series)))
    *
    *   !!! DO NOT USE SIMPLE CONSTANT VALUES FOR THE ACTION IDENTIFIER (1,2,3) !!!
    *   USE ENCODED STRING CONSTANTS FOR EXAMPLE:
    *   uint256 public constant SEED_WEAPON_MINT = uint(keccak256("SEED_WEAPON_MINT"));
    */

    uint256 public currentSeedIndex; // new requests pile up under this index
    uint256 public seedIndexBlockNumber; // the block number "currentSeedIndex" was reached on
    uint256 public firstRequestBlockNumber; // first request block for the latest seed index
    mapping(uint256 => bytes32) public seedHashes; // key: seedIndex

    // keys: user, requestID / value: seedIndex
    mapping(address => mapping(uint256 => uint256)) public singleSeedRequests; // one-at-a-time (saltable)
    mapping(address => mapping(uint256 => uint256)) public singleSeedSalts; // optional, ONLY for single seeds
    mapping(address => mapping(uint256 => uint256[])) public queuedSeedRequests; // arbitrary in/out LIFO

    bool public publicResolutionLimited;
    uint256 public publicResolutionBlocks; // max number of blocks to resolve if limited

    bool public emitResolutionEvent;
    bool public emitRequestEvent;
    bool public emitPopEvent;

    event SeedResolved(address indexed resolver, uint256 indexed seedIndex);
    event SeedRequested(address indexed requester, uint256 indexed requestId);
    event SeedPopped(address indexed popper, uint256 indexed requestId);

    function initialize () public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        currentSeedIndex = 1; // one-at-a-time seeds have a 0 check
        seedIndexBlockNumber = block.number;
        firstRequestBlockNumber = block.number-1; // save 15k gas for very first user
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not admin");
    }

    // SINGLE SEED REQUESTS

    function requestSingleSeed(address user, uint256 requestID) public restricted {
        _resolveSeedPublic(user);
        _requestSingleSeedAssert(user, requestID);
    }

    function requestSingleSeed(address user, uint256 requestID, bool force) public restricted {
        _resolveSeedPublic(user);
        if(force)
            _requestSingleSeed(user, requestID);
        else
            _requestSingleSeedAssert(user, requestID);
    }

    function _requestSingleSeedAssert(address user, uint256 requestID) internal {
        require(singleSeedRequests[user][requestID] == 0);
        _requestSingleSeed(user, requestID);
    }
    
    function _requestSingleSeed(address user, uint256 requestID) internal {
        singleSeedRequests[user][requestID] = currentSeedIndex;
        if(firstRequestBlockNumber < seedIndexBlockNumber)
            firstRequestBlockNumber = block.number;

        if(emitRequestEvent)
            emit SeedRequested(user, requestID);
    }

    // QUEUED SEED REQUESTS

    function requestQueuedSeed(address user, uint256 requestID) public restricted {
        _resolveSeedPublic(user);
        _requestQueuedSeed(user, requestID);
    }

    function _requestQueuedSeed(address user, uint256 requestID) internal {
        queuedSeedRequests[user][requestID].push(currentSeedIndex);
        if(firstRequestBlockNumber < seedIndexBlockNumber)
            firstRequestBlockNumber = block.number;

        if(emitRequestEvent)
            emit SeedRequested(user, requestID);
    }

    // SEED RESOLUTIONS

    function resolveSeedPublic() public {
       _resolveSeedPublic(msg.sender);
    }

    function _resolveSeedPublic(address resolver) internal {
        if(!publicResolutionLimited || block.number < firstRequestBlockNumber + publicResolutionBlocks)
            _resolveSeed(resolver);
    }

    function resolveSeedAdmin() public restricted {
        _resolveSeed(msg.sender);
    }

    function _resolveSeed(address resolver) internal {
        if(block.number > firstRequestBlockNumber && firstRequestBlockNumber >= seedIndexBlockNumber) {
            seedHashes[currentSeedIndex++] = blockhash(block.number - 1);
            seedIndexBlockNumber = block.number;
            if(emitResolutionEvent)
                emit SeedResolved(resolver, currentSeedIndex);
        }
    }

    // SINGLE SEED FULFILLMENT

    function popSingleSeed(address user, uint256 requestID, bool resolve, bool requestNext) public restricted returns (uint256 seed) {
        if(resolve)
            _resolveSeedPublic(user);

        seed = readSingleSeed(user, requestID, false); // reverts on zero
        delete singleSeedRequests[user][requestID];

        if(emitPopEvent)
            emit SeedPopped(user, requestID);

        if(requestNext)
            _requestSingleSeed(user, requestID);
    }

    function readSingleSeed(address user, uint256 requestID, bool allowZero) public view returns (uint256 seed) {
        if(seedHashes[singleSeedRequests[user][requestID]] == 0) {
            require(allowZero);
            // seed stays 0 by default if allowed
        }
        else {
            seed = uint256(keccak256(abi.encodePacked(
                seedHashes[singleSeedRequests[user][requestID]],
                user, requestID
            )));
        }
    }

    function saltSingleSeed(address user, uint256 requestID, bool resolve) public restricted returns (uint256 seed) {
        if(resolve)
            _resolveSeedPublic(user);

        require(seedHashes[singleSeedRequests[user][requestID]] != 0);
        seed = uint(keccak256(abi.encodePacked(
            seedHashes[singleSeedRequests[user][requestID]]
            ,singleSeedSalts[user][requestID]
        )));
        singleSeedSalts[user][requestID] = seed;
        return seed;
    }

    // QUEUED SEED FULFILLMENT

    function popQueuedSeed(address user, uint256 requestID, bool resolve, bool requestNext) public restricted returns (uint256 seed) {
        if(resolve)
            _resolveSeedPublic(user);

        // will revert on empty queue due to pop()
        seed = readQueuedSeed(user, requestID, false);
        queuedSeedRequests[user][requestID].pop();

        if(emitPopEvent)
            emit SeedPopped(user, requestID);

        if(requestNext)
            _requestQueuedSeed(user, requestID);

        return seed;
    }

    function readQueuedSeed(address user, uint256 requestID, bool allowZero) public view returns (uint256 seed) {
        uint256 lastIndex = queuedSeedRequests[user][requestID].length-1;
        seed = uint256(keccak256(abi.encodePacked(
            seedHashes[queuedSeedRequests[user][requestID][lastIndex]],
            user, requestID, lastIndex
        )));
        require(allowZero || seed != 0);
    }

    // HELPER VIEWS

    function hasSingleSeedRequest(address user, uint256 requestID) public view returns (bool) {
        return singleSeedRequests[user][requestID] != 0;
    }

    function getQueuedRequestCount(uint256 requestID) public view returns (uint256) {
        return queuedSeedRequests[msg.sender][requestID].length;
    }

    function encode(uint256[] calldata requestData) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(requestData)));
    }

    // ADMIN FUNCTIONS (excluding resolveSeedAdmin)

    function setPublicResolutionLimited(bool to) public restricted {
        publicResolutionLimited = to;
    }

    function setPublicResolutionBlocks(uint256 to) public restricted {
        publicResolutionBlocks = to;
    }

    function setEmitResolutionEvent(bool to) public restricted {
        emitResolutionEvent = to;
    }

    function setEmitRequestEvent(bool to) public restricted {
        emitRequestEvent = to;
    }

    function setEmitPopEvent(bool to) public restricted {
        emitPopEvent = to;
    }

}

pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IRandoms.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";
import "./common.sol";
import "./PvpRankings.sol";

contract PvpCore is Initializable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint8;
    using SafeMath for uint24;
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 shieldID;
        uint256 wager;
        bool useShield;
    }

    struct Match {
        uint256 attackerID;
        uint256 defenderID;
        uint256 createdAt;
    }

    struct Duelist {
        uint256 ID;
        uint8 level;
        uint8 trait;
        uint24 roll;
        uint256 power;
    }

    struct Duel {
        Duelist attacker;
        Duelist defender;
        uint8 tier;
        uint256 cost;
        bool attackerWon;
        uint256 bonusRank;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    IRandoms public randoms;
    PvpRankings public pvprankings;

    /// @dev the base amount wagered per duel in dollars
    int128 private _baseWagerUSD;
    /// @dev how much extra USD is wagered per level tier
    int128 private _tierWagerUSD;
    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint8 public wageringFactor;
    /// @dev percentage of duel cost charged when rerolling opponent
    uint256 public reRollFeePercent;
    /// @dev percentage of entry wager charged when withdrawing from arena with pending duel
    uint256 public withdrawFeePercent;
    /// @dev amount of time a match finder has to make a decision
    uint256 public decisionSeconds;
    /// @dev allows or blocks entering arena (we can extend later to disable other parts such as rerolls)
    uint256 public arenaAccess; // 0 = cannot join, 1 = can join
    /// @dev value sent by players to offset bot's duel costs
    uint256 public duelOffsetCost;
    /// @dev PvP bot address
    address payable public pvpBotAddress;
    /// @dev characters by id that are on queue to perform a duel
    EnumerableSet.UintSet private _duelQueue;

    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) public fighterByCharacter;
    /// @dev Active match by characterID of the finder
    mapping(uint256 => Match) public matchByFinder;
    /// @dev if character is currently in the arena
    mapping(uint256 => bool) public isCharacterInArena;
    /// @dev if weapon is currently in the arena
    mapping(uint256 => bool) public isWeaponInArena;
    /// @dev if shield is currently in the arena
    mapping(uint256 => bool) public isShieldInArena;
    /// @dev if defender is in a duel that has not finished processing
    mapping(uint256 => bool) public isDefending;
    /// @dev if a character is someone else's opponent
    mapping(uint256 => uint256) public finderByOpponent;
    /// @dev character's tier when it last entered arena. Used to reset rank if it changes
    mapping(uint256 => uint8) public previousTierByCharacter;
    /// @dev excess wager by character for when they re-enter the arena
    mapping(uint256 => uint256) public excessWagerByCharacter;
    /// @dev IDs of characters available for matchmaking by tier
    mapping(uint8 => EnumerableSet.UintSet) private _matchableCharactersByTier;
    /// @dev special weapon reroll timestamp
    mapping(uint256 => uint256) public specialWeaponRerollTimestamp;
    /// @dev owner's address by character ID
    mapping(uint256 => address) private _ownerByCharacter;
    
    event DuelFinished(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp,
        uint256 attackerRoll,
        uint256 defenderRoll,
        bool attackerWon,
        uint256 bonusRank
    );

    event CharacterKicked(
        uint256 indexed characterID,
        uint256 kickedBy,
        uint256 timestamp
    );

    modifier characterInArena(uint256 characterID) {
        _characterInArena(characterID);
        _;
    }

    function _characterInArena(uint256 characterID) internal view {
        require(isCharacterInArena[characterID], "N");
    }

    modifier characterWithinDecisionTime(uint256 characterID) {
        _characterWithinDecisionTime(characterID);
        _;
    }

    function _characterWithinDecisionTime(uint256 characterID) internal view {
        require(
            isCharacterWithinDecisionTime(characterID),
            "D"
        );
    }

    modifier characterNotUnderAttack(uint256 characterID) {
        _characterNotUnderAttack(characterID);
        _;
    }

    function _characterNotUnderAttack(uint256 characterID) internal view {
        require(!isCharacterUnderAttack(characterID), "U");
    }

    modifier characterNotInDuel(uint256 characterID) {
        _characterNotInDuel(characterID);
        _;
    }

    function _characterNotInDuel(uint256 characterID) internal view {
        require(!isCharacterInDuel(characterID), "Q");
    }

    modifier isOwnedCharacter(uint256 characterID) {
        require(_ownerByCharacter[characterID] == msg.sender);
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender));
    }

    function initialize(
        address gameContract,
        address shieldsContract,
        address randomsContract,
        address pvpRankingsContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        shields = Shields(shieldsContract);
        skillToken = IERC20(game.skillToken());
        randoms = IRandoms(randomsContract);
        pvprankings = PvpRankings(pvpRankingsContract);

        _baseWagerUSD = ABDKMath64x64.divu(500, 100); // $5
        _tierWagerUSD = ABDKMath64x64.divu(50, 100); // $0.5
        wageringFactor = 3;
        reRollFeePercent = 25;
        withdrawFeePercent = 25;
        decisionSeconds = 2 minutes;
        duelOffsetCost = 0.005 ether;
    }

    /// @dev enter the arena with a character, a weapon and optionally a shield
    function enterArena(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield,
        bool tierless
    ) external {
        require(
            characters.ownerOf(characterID) == msg.sender &&
                weapons.ownerOf(weaponID) == msg.sender
        );

        require(characters.getNftVar(characterID, 1) == 0 && weapons.getNftVar(weaponID, 1) == 0, "B");

        if (useShield) {
            require(shields.ownerOf(shieldID) == msg.sender);
            require(shields.getNftVar(shieldID, 1) == 0, "S");
        }

        require((arenaAccess & 1) == 1, "L");

        uint8 tier;
        if (tierless) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        uint256 wager = getEntryWagerByTier(tier);

        if (_ownerByCharacter[characterID] != msg.sender) {
            _ownerByCharacter[characterID] = msg.sender;
        }

        if (previousTierByCharacter[characterID] != tier) {
            pvprankings.changeRankingPoints(characterID, 0);
        }

        pvprankings.handleEnterArena(characterID, tier);

        isCharacterInArena[characterID] = true;
        characters.setNftVar(characterID, 1, 1);

        isWeaponInArena[weaponID] = true;
        weapons.setNftVar(weaponID, 1, 1);

        if (useShield) {
            isShieldInArena[shieldID] = true;
            shields.setNftVar(shieldID, 1, 1);
        }

        uint256 characterWager;

        if (excessWagerByCharacter[characterID] != 0) {
            characterWager = excessWagerByCharacter[characterID];
        } else {
            characterWager = fighterByCharacter[characterID].wager;
        }

        _matchableCharactersByTier[tier].add(characterID);
        fighterByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager.add(characterWager),
            useShield
        );
        previousTierByCharacter[characterID] = tier;
        excessWagerByCharacter[characterID] = 0;

        skillToken.transferFrom(msg.sender, address(this), wager);
    }

    /// @dev withdraws a character and its items from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawFromArena(uint256 characterID)
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        characterNotInDuel(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint256 wager = fighter.wager;

        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        uint256 entryWager = getEntryWager(characterID);

        if (matchByFinder[characterID].createdAt != 0) {
            if (wager < entryWager.mul(withdrawFeePercent).div(100)) {
                wager = 0;
            } else {
                wager = wager.sub(entryWager.mul(withdrawFeePercent).div(100));
            }
        }

        _removeCharacterFromArena(characterID, tier);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(msg.sender, wager);
    }

    /// @dev attempts to find an opponent for a character
    function findOpponent(uint256 characterID)
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        characterNotInDuel(characterID)
    {
        require(matchByFinder[characterID].createdAt == 0, "M");

        uint8 tier;

        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        _assignOpponent(characterID, tier);
    }

    /// @dev attempts to find a new opponent for a fee
    function reRollOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        isOwnedCharacter(characterID)
        characterNotInDuel(characterID)
    {
        uint256 opponentID = getOpponent(characterID);
        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        require(matchByFinder[characterID].createdAt != 0, "R");

        delete finderByOpponent[opponentID];
        if (isCharacterInArena[opponentID]) {
            _matchableCharactersByTier[tier].add(opponentID);
        }

        _assignOpponent(characterID, tier);

        uint256 weaponID = fighterByCharacter[characterID].weaponID;
        if(weapons.getWeaponType(weaponID) > 0 && specialWeaponRerollTimestamp[weaponID] < block.timestamp) {
            specialWeaponRerollTimestamp[weaponID] = block.timestamp + 24 hours;
        }
        else {
            skillToken.transferFrom(
                msg.sender,
                address(this),
                getDuelCostByTier(tier).mul(reRollFeePercent).div(100)
            );
        }
    }

    /// @dev adds a character to the duel queue
    function prepareDuel(uint256 attackerID)
        external
        payable
        isOwnedCharacter(attackerID)
        characterInArena(attackerID)
        characterWithinDecisionTime(attackerID)
        characterNotInDuel(attackerID)
    {
        require((arenaAccess & 1) == 1);
        require(msg.value == duelOffsetCost, "O");

        uint256 defenderID = getOpponent(attackerID);

        pvprankings.handlePrepareDuel(attackerID);

        pvprankings.handlePrepareDuel(defenderID);

        isDefending[defenderID] = true;

        _duelQueue.add(attackerID);

        pvpBotAddress.transfer(msg.value);
    }

    function createDuelist(uint256 id) internal view returns (Duelist memory duelist) {
        duelist.ID = id;

        (
            , // xp
            duelist.level,
            duelist.trait,
            , // staminaTimestamp
            , // head
            , // torso
            , // legs
            , // boots
            , // race
        ) = characters.get(id);
    }

    /// @dev performs a list of duels
    function performDuels(uint256[] calldata attackerIDs) external restricted {
        for (uint256 i = 0; i < attackerIDs.length; i++) {
            Duel memory duel;
            duel.attacker = createDuelist(attackerIDs[i]);

            if (!_duelQueue.contains(duel.attacker.ID)) continue;

            duel.defender = createDuelist(getOpponent(duel.attacker.ID));

            if (previousTierByCharacter[duel.attacker.ID] == 20) {
                duel.tier = 20;
            } else {
                duel.tier = getArenaTierForLevel(duel.attacker.level);
            }

            duel.cost = getDuelCostByTier(duel.tier);

            duel.attacker.power = getCharacterPower(duel.attacker.ID, duel.tier);
            duel.defender.power = getCharacterPower(duel.defender.ID, duel.tier);

            duel.attacker.roll = _getCharacterPowerRoll(duel.attacker, duel.defender.trait, duel.tier);
            duel.defender.roll = _getCharacterPowerRoll(duel.defender, duel.attacker.trait, duel.tier);

            // Reduce defender roll if attacker has a shield
            if (fighterByCharacter[duel.attacker.ID].useShield) {
                uint24 attackerShieldDefense = 3;

                uint8 attackerShieldTrait = shields.getTrait(
                    fighterByCharacter[duel.attacker.ID].shieldID
                );

                if (
                    Common.isTraitEffectiveAgainst(attackerShieldTrait, duel.defender.trait)
                ) {
                    attackerShieldDefense = 10;
                }

                duel.defender.roll = uint24(
                    (duel.defender.roll.mul(uint24(100).sub(attackerShieldDefense)))
                        .div(100)
                );
            }

            // Reduce attacker roll if defender has a shield
            if (fighterByCharacter[duel.defender.ID].useShield) {
                uint24 defenderShieldDefense = 3;

                uint8 defenderShieldTrait = shields.getTrait(
                    fighterByCharacter[duel.defender.ID].shieldID
                );

                if (
                    Common.isTraitEffectiveAgainst(defenderShieldTrait, duel.attacker.trait)
                ) {
                    defenderShieldDefense = 10;
                }

                duel.attacker.roll = uint24(
                    (duel.attacker.roll.mul(uint24(100).sub(defenderShieldDefense)))
                        .div(100)
                );
            }

            duel.attackerWon = (duel.attacker.roll >= duel.defender.roll);

            uint256 winnerID = duel.attackerWon
                ? duel.attacker.ID
                : duel.defender.ID;
            uint256 loserID = duel.attackerWon
                ? duel.defender.ID
                : duel.attacker.ID;

            if (winnerID == duel.attacker.ID && duel.attacker.power < duel.defender.power) {
                duel.bonusRank = Common.getBonusRankingPoints(duel.attacker.power, duel.defender.power);
            } else if (winnerID == duel.defender.ID && duel.attacker.power > duel.defender.power) {
                duel.bonusRank = Common.getBonusRankingPoints(duel.defender.power, duel.attacker.power);           
            }

            emit DuelFinished(
                duel.attacker.ID,
                duel.defender.ID,
                block.timestamp,
                duel.attacker.roll,
                duel.defender.roll,
                duel.attackerWon,
                duel.bonusRank
            );

            (
                uint256 reward,
                uint256 poolTax
            ) = pvprankings.getDuelBountyDistribution(duel.cost);

            fighterByCharacter[winnerID].wager = fighterByCharacter[winnerID]
                .wager
                .add(reward);

            uint256 loserWager;

            if (
                fighterByCharacter[loserID].wager <
                duel.cost
            ) {
                loserWager = 0;
            } else {
                loserWager = fighterByCharacter[loserID].wager.sub(
                    duel.cost
                );
            }

            fighterByCharacter[loserID].wager = loserWager;

            delete matchByFinder[duel.attacker.ID];
            delete finderByOpponent[duel.defender.ID];
            isDefending[duel.defender.ID] = false;

            if (
                fighterByCharacter[loserID].wager < duel.cost ||
                fighterByCharacter[loserID].wager <
                getEntryWagerByTier(duel.tier).mul(withdrawFeePercent).div(100)
            ) {
                _removeCharacterFromArena(loserID, duel.tier);
                emit CharacterKicked(
                    loserID,
                    winnerID,
                    block.timestamp
                );
            } else {
                _matchableCharactersByTier[duel.tier].add(loserID);
            }

            _matchableCharactersByTier[duel.tier].add(winnerID);

            pvprankings.handlePerformDuel(winnerID, loserID, duel.bonusRank, duel.tier, poolTax);

            skillToken.safeTransfer(address(pvprankings), poolTax);

            _duelQueue.remove(duel.attacker.ID);
        }
    }

    /// @dev wether or not the character is still in time to start a duel
    function isCharacterWithinDecisionTime(uint256 characterID)
        internal
        view
        returns (bool)
    {
        return
            matchByFinder[characterID].createdAt.add(decisionSeconds) >
            block.timestamp;
    }

    /// @dev checks wether or not the character is actively someone else's opponent
    function isCharacterUnderAttack(uint256 characterID)
        public
        view
        returns (bool)
    {
        if (finderByOpponent[characterID] == 0) {
            if (matchByFinder[0].defenderID == characterID) {
                return isCharacterWithinDecisionTime(0);
            }
            return false;
        }

        return isCharacterWithinDecisionTime(finderByOpponent[characterID]);
    }

    /// @dev checks wether or not the character is currently in the duel queue
    function isCharacterInDuel(uint256 characterID)
        internal
        view
        returns (bool)
    {
        return _duelQueue.contains(characterID) || isDefending[characterID];
    }

    /// @dev gets the amount of SKILL required to enter the arena
    function getEntryWager(uint256 characterID) public view returns (uint256) {
        return getDuelCost(characterID).mul(wageringFactor);
    }

    /// @dev gets the amount of SKILL required to enter the arena by tier
    function getEntryWagerByTier(uint8 tier) public view returns (uint256) {
        return getDuelCostByTier(tier).mul(wageringFactor);
    }

    /// @dev gets the amount of SKILL that is risked per duel
    function getDuelCost(uint256 characterID) public view returns (uint256) {
        if (previousTierByCharacter[characterID] == 20) {
            return  game.usdToSkill(_baseWagerUSD);
        }

        int128 tierExtra = ABDKMath64x64
            .divu(getArenaTier(characterID).mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
    }

    /// @dev gets the amount of SKILL that is risked per duel by tier
    function getDuelCostByTier(uint8 tier) internal view returns (uint256) {
        if (tier == 20) {
            return game.usdToSkill(_baseWagerUSD);
        }

        int128 tierExtra = ABDKMath64x64
            .divu(tier.mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
    }

    /// @dev gets the arena tier of a character (tiers are 1-10, 11-20, etc...)
    function getArenaTier(uint256 characterID) public view returns (uint8) {
        uint8 level = characters.getLevel(characterID);
        return getArenaTierForLevel(level);
    }

    function getArenaTierForLevel(uint8 level) internal pure returns (uint8) {
        return uint8(level.div(10));
    }

    /// @dev get an attacker's opponent
    function getOpponent(uint256 attackerID) public view returns (uint256) {
        return matchByFinder[attackerID].defenderID;
    }

    /// @dev returns the current duel queue
    function getDuelQueue() public view returns (uint256[] memory) {
        uint256 length = _duelQueue.length();
        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = _duelQueue.at(i);
        }

        return values;
    }

    /// @dev assigns an opponent to a character
    function _assignOpponent(uint256 characterID, uint8 tier) private {
        EnumerableSet.UintSet
            storage matchableCharacters = _matchableCharactersByTier[tier];

        require(matchableCharacters.length() != 0, "L");

        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint256 randomIndex = RandomUtil.randomSeededMinMax(
            0,
            matchableCharacters.length() - 1,
            seed
        );
        uint256 opponentID;
        uint256 matchableCharactersCount = matchableCharacters.length();
        bool foundOpponent = false;

        for (uint256 i = 0; i < matchableCharactersCount; i++) {
            uint256 index = (randomIndex + i) % matchableCharactersCount;
            uint256 candidateID = matchableCharacters.at(index);

            if (candidateID == characterID) {
                if (matchableCharactersCount == 1) {
                    break;
                }
                if (
                    matchableCharacters.at(matchableCharactersCount - 1) ==
                    candidateID
                ) {
                    candidateID = matchableCharacters.at(0);
                } else {
                    candidateID = matchableCharacters.at(index + 1);
                }
            }
            if (
                _ownerByCharacter[candidateID] == msg.sender
            ) {
                continue;
            }

            foundOpponent = true;
            opponentID = candidateID;
            break;
        }

        require(foundOpponent, "E");

        matchByFinder[characterID] = Match(
            characterID,
            opponentID,
            block.timestamp
        );
        finderByOpponent[opponentID] = characterID;
        _matchableCharactersByTier[tier].remove(characterID);
        _matchableCharactersByTier[tier].remove(opponentID);
    }

    /// @dev removes a character from arena and clears it's matches
    function _removeCharacterFromArena(uint256 characterID, uint8 tier)
        private
        characterInArena(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];

        uint256 weaponID = fighter.weaponID;
        uint256 shieldID = fighter.shieldID;

        excessWagerByCharacter[characterID] = fighter.wager;

        // Shield removed first before the fighter is deleted
        if (fighter.useShield) {
            isShieldInArena[shieldID] = false;
            shields.setNftVar(shieldID, 1, 0);
        }

        delete fighterByCharacter[characterID];
        delete matchByFinder[characterID];

        if (_matchableCharactersByTier[tier].contains(characterID)) {
            _matchableCharactersByTier[tier].remove(characterID);
        }

        isCharacterInArena[characterID] = false;
        isWeaponInArena[weaponID] = false;

        characters.setNftVar(characterID, 1, 0);
        weapons.setNftVar(weaponID, 1, 0);
    }

    function _getCharacterPowerRoll(Duelist memory character, uint8 opponentTrait, uint8 tier)
        private
        view
        returns (uint24)
    {
        uint24 playerFightPower = getCharacterPower(character.ID, tier);

        Fighter memory fighter = fighterByCharacter[character.ID];
        uint256 weaponID = fighter.weaponID;
        uint256 seed = randoms.getRandomSeedUsingHash(
            _ownerByCharacter[character.ID],
            blockhash(block.number - 1)
        );

        uint8 weaponTrait = weapons.getTrait(weaponID);

        int128 playerTraitBonus = _getPVPTraitBonusAgainst(
            character.trait,
            weaponTrait,
            opponentTrait
        );

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(
            playerFightPower,
            seed
        );

        return uint24(playerTraitBonus.mulu(playerPower));
    }

    function getCharacterPower(uint256 characterID, uint8 tier)
        public
        view
        returns (uint24) 
    {
        int128 bonusShieldStats;
        
        (
            ,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            
        ) = weapons.getFightData(fighterByCharacter[characterID].weaponID, characters.getTrait(characterID));

        if (fighterByCharacter[characterID].useShield) {
            // we set bonus shield stats as 0.2
            bonusShieldStats = _getShieldStats(characterID).sub(1).mul(20).div(100);
        }

        uint24 power;

        if (tier == 20) {
            power = Common.getPowerAtLevel(34);
        } else {
            power = Common.getPowerAtLevel(characters.getLevel(characterID));
        }

        return (   
            Common.getPlayerPowerBase100(
                power,
                (weaponMultFight.add(bonusShieldStats)),
                weaponBonusPower)
        );
    }

    /// @dev returns the amount of matcheable characters
    function getMatchablePlayerCount(uint256 characterID) external view returns(uint) {
        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }
        return _matchableCharactersByTier[tier].length();   
    }

    function _getPVPTraitBonusAgainst(
        uint8 characterTrait,
        uint8 weaponTrait,
        uint8 opponentTrait
    ) private view returns (int128) {
        int128 traitBonus = ABDKMath64x64.fromUInt(1);
        int128 fightTraitBonus = game.fightTraitBonus();
        int128 charTraitFactor = ABDKMath64x64.divu(50, 100);
        if (characterTrait == weaponTrait) {
            traitBonus = traitBonus.add(fightTraitBonus.mul(3));
        }

        // We apply 50% of char trait bonuses because they are applied twice (once per fighter)
        if (
            Common.isTraitEffectiveAgainst(characterTrait, opponentTrait)
        ) {
            traitBonus = traitBonus.add(fightTraitBonus.mul(charTraitFactor));
        } else if (
            Common.isTraitEffectiveAgainst(opponentTrait, characterTrait)
        ) {
            traitBonus = traitBonus.sub(fightTraitBonus.mul(charTraitFactor));
        }
        return traitBonus;
    }

    function _getShieldStats(uint256 characterID)
        private
        view
        returns (int128)
    {
        uint8 trait = characters.getTrait(characterID);
        uint256 shieldID = fighterByCharacter[characterID].shieldID;
        int128 shieldMultFight = shields.getDefenseMultiplierForTrait(shieldID, trait);
        return (shieldMultFight);
    }

    function setBaseWagerInCents(uint256 cents) external restricted {
        _baseWagerUSD = ABDKMath64x64.divu(cents, 100);
    }

    function setTierWagerInCents(uint256 cents) external restricted {
        _tierWagerUSD = ABDKMath64x64.divu(cents, 100);
    }

    function setWageringFactor(uint8 factor) external restricted {
        wageringFactor = factor;
    }

    function setReRollFeePercent(uint256 percent) external restricted {
        reRollFeePercent = percent;
    }

    function setWithdrawFeePercent(uint256 percent) external restricted {
        withdrawFeePercent = percent;
    }

    function setDecisionSeconds(uint256 secs) external restricted {
        decisionSeconds = secs;
    }

    function setArenaAccess(uint256 accessFlags) external restricted {
        arenaAccess = accessFlags;
    }

    function setDuelOffsetCost(uint256 cost) external restricted {
        duelOffsetCost = cost;
    }

    function setPvpBotAddress(address payable botAddress) external restricted {
        pvpBotAddress = botAddress;
    }

    // Note: The following are debugging functions, they can be muted to save contract size

    function forceRemoveCharacterFromArena(uint256 characterID)
        external 
        restricted
        characterNotUnderAttack(characterID)
        characterNotInDuel(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint8 tier;
        
        if (previousTierByCharacter[characterID] == 20) {
            tier = 20;
        } else {
            tier = getArenaTier(characterID);
        }

        uint256 wager = fighter.wager;
        uint256 entryWager = getEntryWager(characterID);

        if (matchByFinder[characterID].createdAt != 0) {
            if (wager < entryWager.mul(withdrawFeePercent).div(100)) {
                wager = 0;
            } else {
                wager = wager.sub(entryWager.mul(withdrawFeePercent).div(100));
            }
        }

        _removeCharacterFromArena(characterID, tier);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(characters.ownerOf(characterID), wager);
    }

    // function clearDuelQueue(uint256 length) external restricted {
    //     for (uint256 i = 0; i < length; i++) {
    //         if (matchByFinder[_duelQueue.at(i)].defenderID > 0) {
    //             isDefending[matchByFinder[_duelQueue.at(i)].defenderID] = false;
    //         }

    //         _duelQueue.remove(_duelQueue.at(i));
    //     }

    //     isDefending[0] = false;
    // }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract Promos is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_f73df27() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        firstCharacterPromoInGameOnlyFundsGivenInUsd = ABDKMath64x64.divu(
            17220,
            100
        );
    }

    mapping(address => uint256) public bits;
    uint256 public constant BIT_FIRST_CHARACTER = 1;
    uint256 public constant BIT_FOUNDER_SHIELD = 2;
    uint256 public constant BIT_BAD_ACTOR = 4;
    uint256 public constant BIT_LEGENDARY_DEFENDER = 8;

    int128 public firstCharacterPromoInGameOnlyFundsGivenInUsd;

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function setBit(address user, uint256 bit) external restricted {
        bits[user] |= bit;
    }

    function setBits(address[] memory user, uint256 bit) public restricted {
        for(uint i = 0; i < user.length; i++)
            bits[user[i]] |= bit;
    }

    function unsetBit(address user, uint256 bit) public restricted {
        bits[user] &= ~bit;
    }

    function unsetBits(address[] memory user, uint256 bit) public restricted {
        for(uint i = 0; i < user.length; i++)
            bits[user[i]] &= ~bit;
    }

    function getBit(address user, uint256 bit) external view returns (bool) {
        return (bits[user] & bit) == bit;
    }

    function firstCharacterPromoInGameOnlyFundsGivenInUsdAsCents() external view returns (uint256) {
        return firstCharacterPromoInGameOnlyFundsGivenInUsd.mulu(100);
    }

    function setFirstCharacterPromoInGameOnlyFundsGivenInUsdAsCents(
        uint256 _usdCents
    ) external restricted {
        firstCharacterPromoInGameOnlyFundsGivenInUsd = ABDKMath64x64.divu(
            _usdCents,
            100
        );
    }

    function setFirstCharacterPromoInGameOnlyFundsGivenInUsdAsRational(
        uint256 _numerator,
        uint256 _denominator
    ) external restricted {
        firstCharacterPromoInGameOnlyFundsGivenInUsd = ABDKMath64x64.divu(
            _numerator,
            _denominator
        );
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./characters.sol";
import "./cryptoblades.sol";

contract Garrison is Initializable, IERC721ReceiverUpgradeable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // STATE
    Characters characters;

    EnumerableSet.AddressSet private supportedTokenTypes;

    mapping(address => EnumerableSet.UintSet) userGarrison;
    mapping(uint256 => address) public characterOwner;
    EnumerableSet.UintSet private allCharactersInGarrison;

    CryptoBlades game;

    event CharacterReceived(uint256 indexed character, address indexed minter);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        characters = _characters;
    }

    function migrateTo_d514745(CryptoBlades _game) external restricted {
        game = _game;
    }

    // MODIFIERS
    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(GAME_ADMIN, msg.sender), "Not admin");
        _;
    }

    modifier isCharacterOwner(uint256 id) {
        require(characterOwner[id] == msg.sender);
        _;
    }

    modifier isInGarrison(uint256 id) {
        require(allCharactersInGarrison.contains(id));
        _;
    }

    modifier isCharactersOwner(uint256[] memory ids) {
        _isCharactersOwner(ids);
        _;
    }

    function _isCharactersOwner(uint256[] memory ids) internal view {
        for(uint i = 0; i < ids.length; i++) {
            require(characterOwner[ids[i]] == msg.sender, 'Not owner');
        }
    }

    // VIEWS
    function getUserCharacters() public view  returns (uint256[] memory tokens) {
        uint256 amount = balanceOf(msg.sender);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage storedTokens = userGarrison[msg.sender];

        for (uint256 i = 0; i < amount; i++) {
            uint256 id = storedTokens.at(i);
                tokens[i] = id;
        }
    }

    function balanceOf(address user) public view returns(uint256) {
        return userGarrison[user].length();
    }

    // MUTATIVE
    function sendToGarrison(uint256 id) public {
        characterOwner[id] = msg.sender;
        userGarrison[msg.sender].add(id);
        allCharactersInGarrison.add(id);
        characters.safeTransferFrom(msg.sender, address(this), id);

        emit CharacterReceived(id, msg.sender);
    }

    function redirectToGarrison(address user, uint256 id) restricted external {
        characterOwner[id] = user;
        userGarrison[user].add(id);
        allCharactersInGarrison.add(id);

        emit CharacterReceived(id, user);
    }

    function restoreFromGarrison(uint256 id)
        public
        isCharacterOwner(id)
        isInGarrison(id)
    {
        require(characters.balanceOf(msg.sender) < characters.characterLimit(), "Receiver has too many characters");
        delete characterOwner[id];
        userGarrison[msg.sender].remove(id);
        allCharactersInGarrison.remove(id);
        characters.safeTransferFrom(address(this), msg.sender, id);
    }

    function swapWithGarrison(uint256 plazaId, uint256 garrisonId) external {
      sendToGarrison(plazaId);
      restoreFromGarrison(garrisonId);
    }

    function transferFromGarrison(address receiver, uint256 id)
        public
        isCharacterOwner(id)
        isInGarrison(id)
    {
        delete characterOwner[id];
        userGarrison[msg.sender].remove(id);
        allCharactersInGarrison.remove(id);
        characters.safeTransferFrom(address(this), receiver, id);
    }

    function claimAllXp(uint256[] calldata chars) external isCharactersOwner(chars) {
        uint256[] memory xps = game.getXpRewards(chars);
        game.resetXp(chars);
        characters.gainXpAll(chars, xps);
    }

    function updateOnBurn(address playerAddress, uint256 burnedId) external restricted {
        delete characterOwner[burnedId];
        userGarrison[playerAddress].remove(burnedId);
        allCharactersInGarrison.remove(burnedId);
    }

    function allowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.remove(address(_tokenAddress));
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _id,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // NOTE: The contract address is always the message sender.
        address _tokenAddress = msg.sender;

        require(
            supportedTokenTypes.contains(_tokenAddress) &&
                allCharactersInGarrison.contains(_id),
            "Token ID not listed"
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Cosmetics is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event CosmeticGiven(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticUsed(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticRestored(address indexed owner, uint32 cosmetic, uint32 amount);
    
    event CosmeticGivenByAdmin(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticTakenByAdmin(address indexed owner, uint32 cosmetic, uint32 amount);

    mapping(address => mapping(uint32 => uint32)) public owned;

    mapping(uint32 => bool) internal _cosmeticAvailable;

    uint32 internal constant _noCosmetic = 0;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier cosmeticAvailable(uint32 cosmetic) {
         require(_cosmeticAvailable[cosmetic], "Not available");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier haveCosmetic(uint32 cosmetic, uint32 amount) {
        require(owned[msg.sender][cosmetic] >= amount, "No cosmetic");
        _;
    }

    function giveCosmetic(address buyer, uint32 cosmetic, uint32 amount) public restricted {
        owned[buyer][cosmetic] += amount;
        emit CosmeticGiven(buyer, cosmetic, amount);
    }

    function useCosmetic(uint32 cosmetic, uint32 amount) internal haveCosmetic(cosmetic, amount) cosmeticAvailable(cosmetic) {
        owned[msg.sender][cosmetic] -= amount;
        emit CosmeticUsed(msg.sender, cosmetic, amount);
    }

    function _restoreCosmetic(uint32 cosmetic, uint32 amount) internal {
        owned[msg.sender][cosmetic] += amount;
        emit CosmeticRestored(msg.sender, cosmetic, amount);
    }

    function getCosmeticCount(uint32 cosmetic) public view returns(uint32) {
        return owned[msg.sender][cosmetic];
    }

    function isCosmeticAvailable(uint32 cosmetic) public view returns (bool){
        return _cosmeticAvailable[cosmetic];
    }

    function toggleCosmeticAvailable(uint32 cosmetic, bool available) external isAdmin {
        _cosmeticAvailable[cosmetic] = available;
    }

    function giveCosmeticByAdmin(address receiver, uint32 cosmetic, uint32 amount) external isAdmin cosmeticAvailable(cosmetic) {
        owned[receiver][cosmetic] += amount;
        emit CosmeticGivenByAdmin(receiver, cosmetic, amount);
    }

    function takeCosmeticByAdmin(address target, uint32 cosmetic, uint32 amount) external isAdmin {
        require(owned[target][cosmetic] >= amount, 'Not enough cosmetic');
        owned[target][cosmetic] -= amount;
        emit CosmeticTakenByAdmin(target, cosmetic, amount);
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Consumables is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event ConsumableGiven(address indexed owner, uint32 amount);

    mapping(address => uint32) public owned;
    
    bool internal _enabled;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;
    }

    modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier itemNotDisabled() {
         require(_enabled, "Item disabled");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier haveItem(uint32 amount) {
        require(owned[msg.sender] >= amount, "No item");
        _;
    }

    function giveItem(address buyer, uint32 amount) public restricted {
        owned[buyer] += amount;
        emit ConsumableGiven(buyer, amount);
    }

    function consumeItem(uint32 amount) internal haveItem(amount) itemNotDisabled {
        owned[msg.sender] -= amount;
    }

    function getItemCount() public view returns (uint32) {
        return owned[msg.sender];
    }

    function toggleItemCanUse(bool canUse) external isAdmin {
        _enabled = canUse;
    }

    function giveItemByAdmin(address receiver, uint32 amount) external isAdmin {
        owned[receiver] += amount;
    }

    function takeItemByAdmin(address target, uint32 amount) external isAdmin {
        require(owned[target] >= amount, 'Not enough item');
        owned[target] -= amount;
    }

    function itemEnabled() public view returns (bool){
        return _enabled;
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./CBKLand.sol";

contract CBKLandSale is Initializable, AccessControlUpgradeable {

    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CBKLand public cbkLand;
     /* ========== EVENTS ========== */
    event T1Given(address indexed owner, uint256 stamp);
    event T2Given(address indexed owner, uint256 chunkId);
    event T3Given(address indexed owner, uint256 chunkId);
    event T1GivenFree(address indexed owner, uint256 stamp);
    event T2GivenFree(address indexed owner, uint256 chunkId);
    event T3GivenFree(address indexed owner, uint256 chunkId);
    event T1GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event T2GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event T3GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event LandTokenGiven(address indexed reseller, address indexed owner, uint256 tier);

    event ReservedLandClaimed(uint256 indexed reservation, address indexed reseller, address indexed owner, uint256 tier, uint256 chunkId);
    event MassMintReservedLand(address indexed player, address indexed reseller, uint256 chunkId, uint256 tier1, uint256 tier2, bool giveTier3);
    event MassMintReservedChunklessLand(address indexed player, address indexed reseller, uint256 tier1, uint256 tier2,  uint256 tier3);
    event ReservedLandClaimedForPlayer(uint256 indexed reservation, address indexed reseller, address indexed owner, uint256 tier, uint256 chunkId);
    
    /* ========== LAND SALE INFO ========== */
    uint256 private constant NO_LAND = 0;
    uint256 public constant TIER_ONE = 1;
    uint256 public constant TIER_TWO = 2;
    uint256 public constant TIER_THREE = 3;
    uint256 private constant MAX_CHUNK_ID = 9999; // 100 x 100

    struct purchaseInfo {
        address buyer;
        uint256 purchasedTier;
        uint256 stamp; // chunkId or roundrobin stamp
        bool free;
    }

    uint256 private totalSales;
    mapping(uint256 => purchaseInfo) public sales; // Put all sales in an mapping for easier tracking
    mapping(address => purchaseInfo) public purchaseAddressMapping;
    mapping(uint256 => uint256) public availableLand; // Land that is up for sale. 
    mapping(uint256 => uint256) public chunkZoneLandSales;

    /* ========== T1 LAND SALE INFO ========== */
    // T1 land is sold with no exact coordinates commitment and assigned based on round robin
    // once minting is done. For now the player gets a stamp which can reflect PROJECTED land coordinates
    // should it need be.
    uint256 private t1LandsSold;



    /* ========== T2 LAND SALE INFO ========== */
    uint256 private t2LandsSold;
    uint256 private chunksWithT2Land;

    uint256 private _allowedLandSalePerChunk;
    uint256 private _allowedLandOffset; // Max allowed deviation allowed from theoretical average

    // T2 sold per chunk
    mapping(uint256 => uint256) public chunkT2LandSales;


    /* ========== T3 LAND SALE INFO ========== */
    uint256 private t3LandsSold;
    mapping(uint256 => address) public chunkT3LandSoldTo;


    /* ========== RESERVED CHUNKS SALE INFO ========== */
    EnumerableSet.UintSet private reservedChunkIds;

    bool internal _enabled;
    bool internal _reservedEnabled;
    
    mapping(address => EnumerableSet.UintSet) private reservedChunks;
    mapping(address => uint256) private reservedChunksCounter;
    mapping(uint256 => address) private chunksReservedFor;

    // reseller address => land tier => budget
    mapping(address => mapping(uint256 => uint256)) private resellerLandBudget;

    // player reserved land
    uint256 private playerReservedLandAt;
    mapping(address => EnumerableSet.UintSet) private playerReservedLands;
    mapping(uint256 => uint256) private playerReservedLandTier;
    mapping(uint256 => address) private playerReservedLandReseller;
    mapping(uint256 => address) private playerReservedLandForPlayer;
    mapping(uint256 => bool) private playerReservedLandClaimed;
    
    EnumerableSet.UintSet private takenT3Chunks;

    function initialize(CBKLand _cbkLand)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = false;

        _allowedLandOffset = 2;
        _allowedLandSalePerChunk = 99; // At least 1 reserved for T3
        availableLand[TIER_ONE] = 1000; // Placeholder value
        availableLand[TIER_TWO] = 100; // Placeholder value
        availableLand[TIER_THREE] = 10; // Placeholder value

        cbkLand = _cbkLand;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier saleAllowed() {
        require(_enabled, "Sales disabled");
        _;
    }

    modifier reservedSaleAllowed() {
        require(_reservedEnabled, "Sales disabled");
        _;
    }

    modifier canPurchase(address buyer) {
        require(purchaseAddressMapping[buyer].purchasedTier == 0, "Already purchased");
        _;
    }

    modifier chunkAvailable(uint256 chunkId) {
        require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
        require(!reservedChunkIds.contains(chunkId), "Chunk reserved");
        require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
        require(_chunkAvailableForT2(chunkId), "Chunk overpopulated");
        _;
    }

    // modifier reservedChunkAvailable(uint256 chunkId) {
    //     require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
    //     require(reservedChunks[msg.sender].contains(chunkId), "Chunk not reserved");
    //     require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
    //     _;
    // }

    // Will not overcomplicate the math on this one. Keeping it simple on purpose for gas cost.
    // Limited to t2 because T3 not many and T1 round robins
    function _chunkAvailableForT2(uint256 chunkId) internal view returns (bool) {
        return chunksWithT2Land == 0 ||
            (chunkT2LandSales[chunkId] + 1 < _allowedLandOffset + t2LandsSold / chunksWithT2Land);
    }

    modifier t3Available(uint256 chunkId) {
        require(_chunkAvailableForT3(chunkId), "T3 not available");
        _;
    }

    function _chunkAvailableForT3(uint256 chunkId) internal view returns (bool) {
        return chunkT3LandSoldTo[chunkId] == address(0);
    }

    modifier tierAvailable(uint256 tier) {
        require(availableLand[tier] > 0, "Tier not available");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function giveT1Land(address buyer) public saleAllowed canPurchase(buyer) tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1Given(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2Land(address buyer, uint256 chunkId) public saleAllowed canPurchase(buyer) tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2Given(buyer, chunkId);
        cbkLand.mint(buyer, TIER_TWO, chunkId);
    }

    function giveT3Land(address buyer, uint256 chunkId) public saleAllowed canPurchase(buyer) tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        takenT3Chunks.add(chunkId);
        emit T3Given(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    function giveT1LandFree(address buyer) public tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1GivenFree(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2LandFree(address buyer, uint256 chunkId) public tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, chunkId, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_TWO, chunkId);
    }

    function giveT3LandFree(address buyer, uint256 chunkId) public tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
        takenT3Chunks.add(chunkId);
        emit T3GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    // function giveLandToken(address buyer, uint256 tier) public reservedSaleAllowed() {
    //     require(resellerLandBudget[msg.sender][tier] > 0); // will protect against invalid tiers
    //     resellerLandBudget[msg.sender][tier]--;
    //     cbkLand.mintLandToken(msg.sender, buyer, tier);
    //     emit LandTokenGiven(msg.sender, buyer, tier);
    // }

    // function getResellerBudget(address reseller) public view returns (uint256 t1, uint256 t2, uint256 t3) {
    //     t1 = resellerLandBudget[reseller][TIER_ONE];
    //     t2 = resellerLandBudget[reseller][TIER_TWO];
    //     t3 = resellerLandBudget[reseller][TIER_THREE];
    // }

    // function setResellerBudget(address reseller, uint256 t1, uint256 t2, uint256 t3) public restricted {
    //     resellerLandBudget[reseller][TIER_ONE] = t1;
    //     resellerLandBudget[reseller][TIER_TWO] = t2;
    //     resellerLandBudget[reseller][TIER_THREE] = t3;
    // }

    // Solidity hates polymorphism for this particular function
    function giveT1LandReservedBulk(address[] memory players, address reseller) public restricted {
        for (uint256 i = 0; i < players.length; i++) {
            giveT1LandReserved(players[i], reseller);
        }
    }

    function giveT1LandReserved(address player, address reseller) public restricted {
        uint256 rcLength = reservedChunks[reseller].length();
        require(rcLength > 0, "no reserved chunks");
        uint256 counter = reservedChunksCounter[reseller];
        for(uint256 i = counter; i < counter + rcLength; i++){
            uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
            // it's actually a T1, but we will play on the T2 because population is shared
            if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                if(chunkT2LandSales[cId] == 0){
                    chunksWithT2Land++;
                }
                chunkT2LandSales[cId]++;
                chunkZoneLandSales[chunkIdToZoneId(cId)]++;
                cbkLand.mint(player, TIER_ONE, cId, reseller);
                emit T1GivenReserved(reseller, player, cId);
                reservedChunksCounter[reseller] = uint256(i + 1);
                return;
            }
        }

        // Could not find a land
        revert();
    }

    // For mass mint
    function massMintReservedLand(address player, address reseller, uint256 chunkId, uint256 tier1, uint256 tier2, bool giveTier3) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        require(chunkT2LandSales[chunkId] + tier1 + tier2 <= _allowedLandSalePerChunk, "NA");
        require(!giveTier3 || _chunkAvailableForT3(chunkId), "NA2");
    
        if((tier1 + tier2) > 0 && chunkT2LandSales[chunkId] == 0) {
             chunksWithT2Land++;
        }
                
        if(tier1 > 0) {
            cbkLand.massMint(player, TIER_ONE, chunkId, reseller, tier1);
            chunkT2LandSales[chunkId] += tier1;
        }

        if(tier2 > 0) {
            cbkLand.massMint(player, TIER_TWO, chunkId, reseller, tier2);
            chunkT2LandSales[chunkId] += tier2;
        }

        if(giveTier3) {
            chunkT3LandSoldTo[chunkId] = player;
            takenT3Chunks.add(chunkId);
            cbkLand.mint(player, TIER_THREE, chunkId, reseller);
        }

        chunkZoneLandSales[chunkIdToZoneId(chunkId)] += tier1 + tier2 + (giveTier3 ? 1 : 0);
        emit MassMintReservedLand(player, reseller, chunkId, tier1, tier2, giveTier3);
    }

    // For mass mint 
    // Can change chunk id once
    // Call with caution
    function massMintReservedLand(address player, address reseller, uint256 tier1, uint256 tier2, uint256 tier3) public restricted {
        require(reservedChunks[reseller].length() > 0, "no reservation");
                
        if(tier1 > 0) {
            cbkLand.massMint(player, TIER_ONE, 0, reseller, tier1);
        }

        if(tier2 > 0) {
            cbkLand.massMint(player, TIER_TWO, 0, reseller, tier2);
        }

        if(tier3 > 0) {
            cbkLand.massMint(player, TIER_THREE, 0, reseller, tier3);
        }

        emit MassMintReservedChunklessLand(player, reseller, tier1, tier2, tier3);
    }

    // Can be called only from land with reseller address and chunkid 0
    // For T1; assignedChunkId is a dummy param
    function changeLandChunkId(uint256 landId, uint256 assignedChunkid) public {
        require(cbkLand.ownerOf(landId) == msg.sender, "NA1"); // Owns the land
        (uint256 tier, uint256 chunkId, , , address reseller) = cbkLand.get(landId);
        require(chunkId == 0 && reseller != address(0), "NA2"); // Is a reseller land with chunk id 0
        require(assignedChunkid == 0 || reservedChunks[reseller].contains(assignedChunkid), "NA3"); // FE didn't send chunkId or reseller owns the assigned chunkId
        require(tier != TIER_THREE || _chunkAvailableForT3(assignedChunkid), "NA4"); // Not tier 3 or tier 3 available
        require((tier == TIER_ONE && assignedChunkid == 0) || assignedChunkid > 0, "NA5"); // tier 1 or chunkid requested
        require(tier != TIER_TWO || chunkT2LandSales[assignedChunkid] < _allowedLandSalePerChunk, "NA6"); // Not T2 or population allows it

        // T1 => get random reseller chunkId
        if(tier == TIER_ONE) {
            uint256 rcLength = reservedChunks[reseller].length();
            require(rcLength > 0, "no reserved chunks");
            uint256 counter = reservedChunksCounter[reseller];
            for(uint256 i = counter; i < counter + rcLength; i++) {
                uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
                if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                    assignedChunkid = cId;
                    reservedChunksCounter[reseller] = uint256(i + 1);
                    break;
                }
            }
        }

        require(assignedChunkid != 0, "NA7"); // Would only happen if T1 && round robin failed; shouldn't

        // T1 and T2 share population
        if(tier != TIER_THREE) {
            if(chunkT2LandSales[assignedChunkid] == 0){
                chunksWithT2Land++;
            }

            chunkT2LandSales[assignedChunkid]++;
        }

        // T3 => tag the land
        if(tier == TIER_THREE) {
            chunkT3LandSoldTo[assignedChunkid] = msg.sender;
            takenT3Chunks.add(assignedChunkid);
        }

        chunkZoneLandSales[chunkIdToZoneId(assignedChunkid)]++;
        cbkLand.updateChunkId(landId, assignedChunkid);
    }

    function giveT1LandReservedBulk(address[] memory players, address reseller, uint256 chunkId) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        for (uint256 i = 0; i < players.length; i++) {
            giveT1LandReserved(players[i], reseller, chunkId);
        }
    }

    function giveT1LandReserved(address player, address reseller, uint256 chunkId) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        if(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk) {
            if(chunkT2LandSales[chunkId] == 0){
                chunksWithT2Land++;
            }
            chunkT2LandSales[chunkId]++;
            chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
            cbkLand.mint(player, TIER_ONE, chunkId, reseller);
            emit T1GivenReserved(reseller, player, chunkId);
             return;
        }
        // Could not find a land
        revert();
    }

    // function giveT2LandReserved(address buyer, uint256 chunkId) public reservedChunkAvailable(chunkId) reservedSaleAllowed() {
    //      if(chunkT2LandSales[chunkId] == 0){
    //         chunksWithT2Land++;
    //     }

    //     chunkT2LandSales[chunkId]++;
    //     chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

    //     emit T2GivenReserved(msg.sender, buyer, chunkId);
    //     cbkLand.mint(buyer, TIER_TWO, chunkId);
    // }

    // function giveT3LandReserved(address buyer, uint256 chunkId) public reservedChunkAvailable(chunkId) t3Available(chunkId) reservedSaleAllowed() {
    //     chunkT3LandSoldTo[chunkId] = buyer;
    //     chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

    //     emit T3GivenReserved(msg.sender, buyer, chunkId);
    //     cbkLand.mint(buyer, TIER_THREE, chunkId);
    // }

    // Will leave this commented
    // function setLandURI(uint256 landId, string memory uri) public {
    //     (, uint256 chunkId,,) = cbkLand.get(landId);
    //     require(reservedChunks[msg.sender].contains(chunkId), "no access");
    //     cbkLand.setURI(landId, uri);
    // }

    function chunkIdToZoneId(uint256 chunkId) internal pure returns (uint256){
        return 10 * (chunkId / 1000) + (chunkId % 100) / 10;
    }

    function salesAllowed() public view returns (bool){
        return _enabled;
    }

    function reservedSalesAllowed() public view returns (bool){
        return _reservedEnabled;
    }

    function getAllowedLandOffset()  public view returns (uint256){
        return _allowedLandOffset;
    }

    function checkIfChunkAvailable(uint256 tier, uint256 chunkId) public view returns (bool){
        if(reservedChunkIds.contains(chunkId)){
            return false;
        }

        if(chunkId > MAX_CHUNK_ID){
            return false;
        }

        if(tier == TIER_ONE){
            return availableLand[TIER_ONE] > 0;
        }

        if(tier == TIER_TWO){
            return availableLand[TIER_TWO] > 0
                    && chunkT2LandSales[TIER_TWO] < _allowedLandSalePerChunk
                    && _chunkAvailableForT2(chunkId);
        }

        if(tier == TIER_THREE){
            return availableLand[TIER_THREE] > 0
                    && _chunkAvailableForT3(chunkId);
        }

        return false;
    }

    function checkChunkReserved(uint256 chunkId) public view returns (bool){
        return reservedChunkIds.contains(chunkId);
    }

    function getAllZonesPopulation() public view returns (uint256[] memory) {
        uint256[] memory toReturn = new uint256[](100);

        for (uint256 i = 0; i < 100; i++) {
            toReturn[i] = chunkZoneLandSales[i];
        }

        return toReturn;
    }

    function getZonePopulation(uint256[] memory zoneIds) public view returns (uint256[] memory) {
        require(zoneIds.length > 0 && zoneIds.length <= 100, "invalid request");
        uint256[] memory toReturn = new uint256[](zoneIds.length);

        for (uint256 i = 0; i < zoneIds.length; i++) {
            toReturn[i] = chunkZoneLandSales[zoneIds[i]];
        }

        return toReturn;
    }

    function getZoneChunkPopulation(uint256 zoneId) public view returns (uint256[] memory) {
        require(zoneId < 100, "invalid request");
        uint256 zoneX = zoneId % 10;
        uint256 zoneY = zoneId / 10;

        uint256[] memory toReturn = new uint256[](100);
        uint256 counter = 0;

        for(uint256 j = zoneY * 1000; j < zoneY * 1000 + 1000; j += 100) {
            for(uint256 i = zoneX * 10; i < zoneX * 10 + 10; i++) {
                uint256 projectedId = i + j;
                toReturn[counter++] = chunkT2LandSales[projectedId] + (chunkT3LandSoldTo[projectedId] != address(0) ? 1 : 0);
            }
        }

        return toReturn;
    }

    function getChunkPopulation(uint256[] memory chunkIds) public view returns (uint256[] memory) {
        require(chunkIds.length > 0 && chunkIds.length <= 100, "invalid request");
        uint256[] memory toReturn = new uint256[](chunkIds.length);

        for (uint256 i = 0; i < chunkIds.length; i++) {
            toReturn[i] = chunkT2LandSales[chunkIds[i]] + (chunkT3LandSoldTo[chunkIds[i]] != address(0) ? 1 : 0);
        }

        return toReturn;
    }

    function getAvailableLand()  public view returns (uint256, uint256, uint256) {
        return (availableLand[TIER_ONE], availableLand[TIER_TWO], availableLand[TIER_THREE]);
    }

    function getAvailableLandPerChunk()  public view returns (uint256) {
        return _allowedLandSalePerChunk;
    }

    function getSoldLand()  public view returns (uint256, uint256, uint256) {
        return (t1LandsSold, t2LandsSold, t3LandsSold);
    }

    function getPopulatedT2Chunks()  public view returns (uint256) {
        return chunksWithT2Land;
    }

    function getPurchase()  public view returns (uint256, uint256) {
        return (purchaseAddressMapping[msg.sender].purchasedTier, purchaseAddressMapping[msg.sender].stamp);
    }

    function getPurchaseOf(address owner)  public view returns (uint256, uint256) {
        return (purchaseAddressMapping[owner].purchasedTier, purchaseAddressMapping[owner].stamp);
    }

    function getSalesCount() public view returns (uint256){
        return totalSales;
    }

    function getPurchaseBySale(uint256 sale)  public view returns (address, uint256, uint256) {
        return (sales[sale].buyer, sales[sale].purchasedTier, sales[sale].stamp);
    }

    function setSaleAllowed(bool allowed) external isAdmin {
        _enabled = allowed;
    }

    function setReservedSaleAllowed(bool allowed) external isAdmin {
        _reservedEnabled = allowed;
    }

    // do NOT use this for reserve false unless really needed. This doesn't update reseller data
    // the purpose of this function is to provide a cheap way to bulk reserve blocks that don't have resellers
    function setChunksReservation(uint256[] calldata chunkIds, bool reserved) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            
            if(reserved && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserved) {
                reservedChunkIds.remove(chunkIds[i]);
            }
        }
    }

    // be careful with forced, a chunkId may still remain attached to an existing reseller
    // forced should not be used unless something is really wrong
    function setChunksReservationInfo(uint256[] calldata chunkIds, address reserveFor, bool reserved, bool forced) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            require (chunkIds[i] != 0, "0 NA"); // chunk id 0 shouldn't be reserved
            require(!reserved || (forced || chunksReservedFor[chunkIds[i]] == address(0)), "AS"); // already reserved, request has to be forced to avoid issues
            
            if(reserved && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserved) {
                reservedChunkIds.remove(chunkIds[i]);
                chunksReservedFor[chunkIds[i]] = address(0);
                 reservedChunks[reserveFor].remove(chunkIds[i]);
            }

            if(reserved && !reservedChunks[reserveFor].contains(chunkIds[i])) {
                reservedChunks[reserveFor].add(chunkIds[i]);
                chunksReservedFor[chunkIds[i]] = reserveFor;
            }
        }
    }

    function givePlayersReservedLand(address[] calldata players, address reseller, uint256 tier) external isAdmin {
        for (uint256 i = 0; i < players.length; i++) {
            playerReservedLands[players[i]].add(++playerReservedLandAt);
            playerReservedLandTier[playerReservedLandAt] = tier;
            playerReservedLandReseller[playerReservedLandAt] = reseller;
            playerReservedLandForPlayer[playerReservedLandAt] = players[i];
        }
    }

    function getPlayerReservedLand(address player) public view returns(uint256[] memory t2Reservations, uint256[] memory t3Reservations) {
        uint256 amount = playerReservedLands[player].length();
        uint256 t2Count = 0;
        uint256 t3Count = 0;
         for (uint256 i = 0; i < amount; i++) {
            uint256 reservation = playerReservedLands[player].at(i);
            uint256 reservedTier = playerReservedLandTier[reservation];
           if(reservedTier == 2) {
               t2Count++;
           }
           else if(reservedTier == 3) {
               t3Count++;
           }
        }

        if(t2Count == 0 && t3Count == 0) {
            return (new uint256[](0), new uint256[](0));
        }

        t2Reservations = new uint256[](t2Count); 
        t3Reservations = new uint256[](t3Count); 
        t2Count = 0;
        t3Count = 0;

        for (uint256 i = 0; i < amount; i++) {
            uint256 reservation = playerReservedLands[player].at(i);
            uint256 reservedTier = playerReservedLandTier[reservation];
           if(reservedTier == 2) {
               t2Reservations[t2Count++] = reservation;
           }
           else if(reservedTier == 3) {
               t3Reservations[t3Count++] = reservation;
           }
        }
    }

    function getChunksOfReservations(uint256 reservationId) public view returns (uint256[] memory chunkIds) {
        address reseller = playerReservedLandReseller[reservationId];
        return getChunksOfReseller(reseller);
    }

    function getInfoOfReservation(uint256 reservationId) public view returns (address player, address reseller, uint256 tier, bool claimed) {
        return (playerReservedLandForPlayer[reservationId], playerReservedLandReseller[reservationId], playerReservedLandTier[reservationId], playerReservedLandClaimed[reservationId]);
    }

    function getChunksOfReseller(address reservedFor) public view  returns (uint256[] memory chunkIds) {
        uint256 amount = reservedChunks[reservedFor].length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = reservedChunks[reservedFor].at(i);
                chunkIds[index++] = id;
        }
    }

    function claimPlayerReservedLand(uint256 reservation, uint256 chunkId, uint256 tier) public reservedSaleAllowed {
        require(tier != 1, "NT1");
        require(playerReservedLandClaimed[reservation] == false, "AC"); // already claimed
        require(playerReservedLands[msg.sender].contains(reservation), "IR"); // invalid reservation
        require(playerReservedLandTier[reservation] == tier, "IT"); // invalid tier
        address reseller = playerReservedLandReseller[reservation];
        require(reservedChunks[reseller].contains(chunkId), "IR2"); // invalid reseller

        if(tier == 3) {
            require(_chunkAvailableForT3(chunkId), "T3 NA"); 
            chunkT3LandSoldTo[chunkId] = msg.sender;
            takenT3Chunks.add(chunkId);
        }

        if(tier == 2) {
            require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "T2 NA");
            if(chunkT2LandSales[chunkId] == 0){
                chunksWithT2Land++;
            }
            chunkT2LandSales[chunkId]++;
        }
        
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
        playerReservedLands[msg.sender].remove(reservation);
        playerReservedLandClaimed[reservation] = true;
        cbkLand.mint(msg.sender, tier, chunkId, reseller);
        emit ReservedLandClaimed(reservation, reseller, msg.sender, tier, chunkId);
    }


    
    function massClaimReservationsForPlayer(address player, uint256[] calldata reservations) external isAdmin {
        for (uint256 i = 0; i < reservations.length; i++) {
            uint256 reservation = reservations[i];
            require(playerReservedLandClaimed[reservation] == false, "AC"); // already claimed
            require(playerReservedLands[player].contains(reservation), "IR"); // invalid reservation
            address reseller = playerReservedLandReseller[reservation];
            uint256 rcLength = reservedChunks[reseller].length();
            require(rcLength > 0, "no reserved chunks");
            
            uint256 assignedChunkid = 0;
            uint256 reservedTier = playerReservedLandTier[reservation];
            
            require(reservedTier == TIER_TWO || reservedTier == TIER_THREE, "NA");

            uint256 counter = reservedChunksCounter[reseller];
            for(uint256 i = counter; i < counter + rcLength; i++) {
                uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
                if(reservedTier == TIER_TWO) { // T2, find a spot with enough population
                    if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                        assignedChunkid = cId;
                        reservedChunksCounter[reseller] = uint256(i + 1);
                        break;
                    }
                }
                else if(!takenT3Chunks.contains(cId)) { // This is a T3, find a chunk that isn't claimed as T3
                    assignedChunkid = cId;
                     reservedChunksCounter[reseller] = uint256(i + 1);
                    break;
                }
                
            }

            require(assignedChunkid != 0, "NA");

            if(reservedTier == TIER_TWO) {
                if(chunkT2LandSales[assignedChunkid] == 0){
                    chunksWithT2Land++;
                }
                chunkT2LandSales[assignedChunkid]++;
            }
            else {
                chunkT3LandSoldTo[assignedChunkid] = player;
                takenT3Chunks.add(assignedChunkid);
            }

            playerReservedLands[player].remove(reservation);
            playerReservedLandClaimed[reservation] = true;
            cbkLand.mint(player, reservedTier, assignedChunkid, reseller);
            chunkZoneLandSales[chunkIdToZoneId(assignedChunkid)]++;
            emit ReservedLandClaimedForPlayer(reservation, reseller, player, reservedTier, assignedChunkid);
        }
    }

    function getResellerOfChunk(uint256 chunkId) public view  returns (address reservedFor) {
        reservedFor = chunksReservedFor[chunkId];
    }

    function getReservedChunksIds() public view  returns (uint256[] memory chunkIds) {
        uint256 amount = reservedChunkIds.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = reservedChunkIds.at(i);
                chunkIds[index++] = id;
        }
    }

    function getTakenT3Chunks() public view  returns (uint256[] memory chunkIds) {
        uint256 amount = takenT3Chunks.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = takenT3Chunks.at(i);
                chunkIds[index++] = id;
        }
    }

    function setAllowedLandOffset(uint256 allowedOffset) external isAdmin {
        _allowedLandOffset = allowedOffset;
    }

    function setAllowedLandPerChunk(uint256 allowedLandSalePerChunk) external isAdmin {
        _allowedLandSalePerChunk = allowedLandSalePerChunk;
    }

    function setAvailableLand(uint256 tier, uint256 available) external isAdmin {
        require(tier >= TIER_ONE && tier <= TIER_THREE, "Invalid tier");
        availableLand[tier] = available;
    }

    function getReservationAt() public view returns (uint256) {
        return playerReservedLandAt;
    }

    // function updateResellerOfReservation(uint256[] calldata ids, address reseller) external isAdmin {
    //     for (uint256 i = 0; i < ids.length; i++) {
    //         playerReservedLandReseller[ids[i]] = reseller;
    //     }
    // }

    // Do not use forced unless really needed. If used, preferable don't update population
    // Do NOT use with T3
    // function updateLandChunkIdBulk(uint256[] calldata landIds, uint256 fromChunkId, uint256 toChunkId, bool updateToPopulation, bool forced) external isAdmin {
    //     require(forced || cbkLand.landsBelongToChunk(landIds, fromChunkId), "NA");

    //     if(updateToPopulation) {
    //         uint256 populationFrom = chunkT2LandSales[fromChunkId];
    //         uint256 populationTo = chunkT2LandSales[toChunkId];
    //         uint256 populationChange = landIds.length;

    //         if(populationFrom - populationChange < 0) {
    //             require(forced, "NA2"); // forced or don't allow. Something is wrong.
    //             populationChange = populationFrom; // can't have negative population
    //         }

    //         if(populationTo + populationChange > _allowedLandSalePerChunk) {
    //             require(forced, "NA3"); // forced or don't allow. Something is wrong. No reset on populationChange
    //         }

    //         chunkT2LandSales[fromChunkId] -= populationChange;
    //         chunkZoneLandSales[chunkIdToZoneId(fromChunkId)] -= populationChange;

    //         chunkT2LandSales[toChunkId] += populationChange;
    //         chunkZoneLandSales[chunkIdToZoneId(toChunkId)] += populationChange;
    //     }

    //     cbkLand.updateChunkId(landIds, toChunkId);
    // }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract CBKLand is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    // Land specific
    uint256 public constant LT = 0; // Land Tier
    uint256 public constant LC = 1; // Land Chunk Id
    uint256 public constant LX = 2; // Land Coordinate X
    uint256 public constant LY = 3; // Land Coordinate Y
    

    event LandMinted(address indexed minter, uint256 id, uint256 tier, uint256 chunkId);
    event LandTransfered(address indexed from, address indexed to, uint256 id);
    event LandTokenMinted(address indexed reseller, address indexed minter, uint256 id, uint256 tier);
    event LandMintedWithReseller(address indexed minter, uint256 id, uint256 tier, uint256 chunkId, address reseller);
    event LandChunkIdUpdated(uint256 indexed id, uint256 chunkId);

    // TotalLand
    uint256 landMinted;
    // Avoiding structs for stats
    mapping(uint256 => mapping(uint256 => uint256)) landData;

    mapping(uint256 => mapping(uint256 => string)) landStrData;

    uint256 public constant LBT = 0; // Land is a Token, it will have its chunkId updated later
    mapping(uint256 => mapping(uint256 => bool)) landBoolData;

    uint256 public constant LAR = 0; // Land Reseller, the one who minted the token
    mapping(uint256 => mapping(uint256 => address)) landAddressData;

    uint256 public constant TSU = 0; // URI of a tier. Will put this in land NFT because it kinda belongs here
    mapping(uint256 => mapping(uint256 => string)) tierStrData;

    function initialize () public initializer {
        __ERC721_init("CryptoBladesKingdoms Land", "CBKL");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

     // tier, chunkid, x, y, reseller address
    function get(uint256 id) public view returns (uint256, uint256, uint256, uint256, address) {
        return (landData[id][LT], landData[id][LC], landData[id][LX], landData[id][LY], landAddressData[id][LAR]);
    }

    function getOwned(address owner) public view returns (uint256[] memory ownedIds) {
        uint256 ownedLandCount = balanceOf(owner);
        ownedIds = new uint256[](ownedLandCount);
         for(uint256 i = 0; i < ownedLandCount; i++) {
             ownedIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function getLandReseller(uint256 land) public view returns (address) {
        return landAddressData[land][LAR];
    }

    // DO NOT call directly outside the logic of CBKLandSale to avoid breaking tier and chunk logic
    function mint(address minter, uint256 tier, uint256 chunkId) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        //landData[tokenID][LX] = x; // not yet
        //landData[tokenID][LY] = y; // not yet
        
        _mint(minter, tokenID);
        emit LandMinted(minter, tokenID, tier, chunkId);
    }

    function mint(address minter, uint256 tier, uint256 chunkId, address reseller) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        //landData[tokenID][LX] = x; // not yet
        //landData[tokenID][LY] = y; // not yet
        
        landAddressData[tokenID][LAR] = reseller;

        _mint(minter, tokenID);
        emit LandMintedWithReseller(minter, tokenID, tier, chunkId, reseller);
    }

    function massMint(address minter, uint256 tier, uint256 chunkId, address reseller, uint256 quantity) public restricted {
        for(uint256 i = 0; i < quantity; i++) {
            mint(minter, tier, chunkId, reseller);
        }
    }

    function updateChunkId(uint256 id, uint256 chunkId) public restricted {
        landData[id][LC] = chunkId;
        emit LandChunkIdUpdated(id, chunkId);
    }

    function updateChunkId(uint256[] memory ids, uint256 chunkId) public restricted {
        for(uint256 i = 0; i < ids.length; i++) {
            updateChunkId(ids[i], chunkId);
        }
    }

    // Helper function for bulk moving land without having to jump chains
    function landsBelongToChunk(uint256[] memory ids, uint256 chunkId) public view returns (bool) {
        for(uint256 i = 0; i < ids.length; i++) {
            if(landData[ids[i]][LC] != chunkId) {
                return false;
            }

            if(ids[i] > landMinted) {
                return false;
            }
        }

        return true;
    }

    function getLandTierURI(uint256 id) public view returns (string memory uri) {
       (uint256 tier,,,,) = get(id);
        return getTierURI(tier);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return getLandTierURI(id);
    }

    function getTierURI(uint256 tier) public view returns (string memory uri) {
        return tierStrData[tier][TSU];
    }

    function setTierStr(uint256 tier, uint256 index, string memory val) public restricted {
        tierStrData[tier][index] = val;
    }

    function getLandTier(uint256 id) public view returns (uint256) {
        return landData[id][LT];
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IRandoms.sol";
import "./shields.sol";
import "./Consumables.sol";
import "./Cosmetics.sol";
import "./weapons.sol";
import "./cryptoblades.sol";
import "./CBKLandSale.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    uint256 public constant ITEM_WEAPON_RENAME = 1;
    uint256 public constant ITEM_CHARACTER_RENAME = 2;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_FIRE = 3;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_EARTH = 4;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_WATER = 5;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_LIGHTNING = 6;
    uint256 public constant ITEM_COSMETIC_WEAPON = 7; // series
    uint256 public constant ITEM_COSMETIC_CHARACTER = 8; // series
    uint256 public constant ITEM_SHIELD = 9;

    uint256 public constant VAR_PURCHASE_SHIELD_TYPE = 1;
    uint256 public constant VAR_PURCHASE_SHIELD_SUPPLY = 2; // only for non-0 type shields

    uint256 public constant LINK_SKILL_ORACLE_2 = 1; // technically second skill oracle (it's separate)
    uint256 public constant LINK_KING_ORACLE = 2;

    uint256 public constant CURRENCY_SKILL = 0;
    //uint256 public constant CURRENCY_KING = 1; // not referenced atm

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

    Shields public shields;
    CryptoBlades public game;


    // keys: ITEM_ constant
    mapping(uint256 => address) public itemAddresses;
    mapping(uint256 => uint256) public itemFlatPrices;

    mapping(uint256 => uint256) public numberParameters; // AKA "vars"

    mapping(uint256 => mapping(uint256 => uint256)) public itemSeriesFlatPrices;
    CBKLandSale public cbkLandSale;
    // ERC20 => tier => price
    mapping(uint256 => mapping(uint256 => uint256)) public landPrices;
    mapping(uint256 => address) currencies;

    mapping(uint256 => address) public links;

    /* ========== INITIALIZERS AND MIGRATORS ========== */

    function initialize(Weapons _weapons, IRandoms _randoms)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        weapons = _weapons;
        randoms = _randoms;
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        randoms = _newRandoms;
    }

    function migrateTo_61c10da(Shields _shields, CryptoBlades _game) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        shields = _shields;
        game = _game;
    }

    function migrateTo_16884dd(
        address _characterRename,
        address _weaponRename,
        address _charFireTraitChange,
        address _charEarthTraitChange,
        address _charWaterTraitChange,
        address _charLightningTraitChange
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        itemAddresses[ITEM_WEAPON_RENAME] = _weaponRename;
        itemAddresses[ITEM_CHARACTER_RENAME] = _characterRename;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_FIRE] = _charFireTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_EARTH] = _charEarthTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_WATER] = _charWaterTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = _charLightningTraitChange;

        itemFlatPrices[ITEM_WEAPON_RENAME] = 0.1 ether;
        itemFlatPrices[ITEM_CHARACTER_RENAME] = 0.1 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = 0.2 ether;
    }

    function migrateTo_bcdf4c(CBKLandSale _cbkLandSale) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        cbkLandSale = _cbkLandSale;
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverToken(address tokenAddress, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function purchaseShield() public {
        require(itemFlatPrices[ITEM_SHIELD] > 0);

        uint256 shieldType = numberParameters[VAR_PURCHASE_SHIELD_TYPE];
        if(shieldType != 0) {
            require(numberParameters[VAR_PURCHASE_SHIELD_SUPPLY] > 0);
            numberParameters[VAR_PURCHASE_SHIELD_SUPPLY] -= 1;
        }
        payCurrency(msg.sender, itemFlatPrices[ITEM_SHIELD], CURRENCY_SKILL);
        shields.mint(msg.sender, shieldType,
            uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)))));
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(hasRole(GAME, msg.sender), "Only game");
        _;
    }

    modifier isAdmin() {
         _isAdmin();
        _;
    }
    
    function _isAdmin() internal view {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
    }

    /* ========== Generic Getters ========== */

    function getAddressOfItem(uint256 itemIndex) public view returns(address) {
        return itemAddresses[itemIndex];
    }

    function getFlatPriceOfItem(uint256 itemIndex) public view returns(uint256) {
        return itemFlatPrices[itemIndex];
    }

    function getFlatPriceOfSeriesItem(uint256 itemIndex, uint256 seriesIndex) public view returns(uint256) {
        return itemSeriesFlatPrices[itemIndex][seriesIndex];
    }

    function getCurrency(uint256 currency) public view returns (address) {
        return currencies[currency];
    }

    function getLink(uint256 linkId) public view returns (address) {
        return links[linkId];
    }

    function vars(uint256 varField) public view returns (uint256) {
        return numberParameters[varField];
    }

    /* ========== Generic Setters ========== */

    function setAddressOfItem(uint256 itemIndex, address to) external isAdmin {
        itemAddresses[itemIndex] = to;
    }

    function setFlatPriceOfItem(uint256 itemIndex, uint256 flatWeiPrice) external isAdmin {
        itemFlatPrices[itemIndex] = flatWeiPrice;
    }

    function setFlatPriceOfItemSeries(uint256 itemIndex,
        uint256[] calldata seriesIndices,
        uint256[] calldata seriesPrices
    ) external isAdmin {
        for(uint i = 0; i < seriesIndices.length; i++) {
            itemSeriesFlatPrices[itemIndex][seriesIndices[i]] = seriesPrices[i];
        }
    }

    function setCurrency(uint256 currency, address currencyAddress, bool forced) external isAdmin {
        require(currency > 0 && (forced || currencies[currency] == address(0)), 'used');
        currencies[currency] = currencyAddress;
    }

    function setLink(uint256 linkId, address linkAddress) external isAdmin {
        links[linkId] = linkAddress;
    }

    function setVar(uint256 varField, uint256 value) external isAdmin {
        numberParameters[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external isAdmin {
        for(uint i = 0; i < varFields.length; i++) {
            numberParameters[varFields[i]] = values[i];
        }
    }

    /* ========== Character Rename ========== */

    function setCharacterRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_CHARACTER_RENAME] = newPrice;
    }

    function characterRenamePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_CHARACTER_RENAME];
    }

    function purchaseCharacterRenameTag(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_RENAME], 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_CHARACTER_RENAME], CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_CHARACTER_RENAME]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterRenameTagDeal(uint256 paying) public { // 4 for the price of 3
        require(paying == itemFlatPrices[ITEM_CHARACTER_RENAME] * 3, 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_CHARACTER_RENAME] * 3, CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_CHARACTER_RENAME]).giveItem(msg.sender, 4);
    }

    /* ========== Weapon Rename ========== */

    function setWeaponRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_WEAPON_RENAME] = newPrice;
    }

    function weaponRenamePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_WEAPON_RENAME];
    }

    function purchaseWeaponRenameTag(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_WEAPON_RENAME], 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_WEAPON_RENAME], CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_WEAPON_RENAME]).giveItem(msg.sender, 1);
    }

    function purchaseWeaponRenameTagDeal(uint256 paying) public { // 4 for the price of 3
        require(paying == itemFlatPrices[ITEM_WEAPON_RENAME] * 3, 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_WEAPON_RENAME] * 3, CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_WEAPON_RENAME]).giveItem(msg.sender, 4);
    }

     /* ========== Character Trait Change ========== */

     function setCharacterTraitChangePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = newPrice;
    }

     function characterTraitChangePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE];
    }

    function purchaseCharacterFireTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE], 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE], CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_FIRE]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterEarthTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH], 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH], CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_EARTH]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterWaterTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER], 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER], CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_WATER]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterLightningTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING], 'Invalid price');
        payCurrency(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING], CURRENCY_SKILL);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING]).giveItem(msg.sender, 1);
    }


    /* ========== Weapon cosmetics ========== */
    function setWeaponCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic] = newPrice;
    }

     function getWeaponCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic];
    }

    function purchaseWeaponCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic], 'Invalid price');
        payCurrency(msg.sender, itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic], CURRENCY_SKILL);
        Cosmetics(itemAddresses[ITEM_COSMETIC_WEAPON]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== Character cosmetics ========== */
    function setCharacterCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic] = newPrice;
    }

     function getCharacterCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic];
    }

    function purchaseCharacterCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic], 'Invalid price');
        payCurrency(msg.sender, itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic], CURRENCY_SKILL);
        Cosmetics(itemAddresses[ITEM_COSMETIC_CHARACTER]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== CBK Land sale ========== */

    event CBKLandPurchased(address indexed owner, uint256 tier, uint256 price, uint256 currency);

    function purchaseT1CBKLand(uint256 paying, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_ONE(), currency);
        require(paying > 0 && price == paying, 'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT1Land(msg.sender);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_ONE(), price, currency);
    }

    function purchaseT2CBKLand(uint256 paying, uint256 chunkId, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_TWO(), currency);
        require(paying > 0 && price == paying,  'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT2Land(msg.sender, chunkId);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_TWO(), price, currency);
    }

    function purchaseT3CBKLand(uint256 paying, uint256 chunkId, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_THREE(), currency);
        require(paying > 0 && price == paying, 'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT3Land(msg.sender, chunkId);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_THREE(), price, currency);
    }

    function getCBKLandPrice(uint256 tier, uint256 currency) public view returns (uint256){
        return landPrices[currency][tier] * getOracledTokenPerUSD(currency);
    }

    function getOracledTokenPerUSD(uint256 currency) public view returns (uint256) {
        if(currency == CURRENCY_SKILL) {
            return IPriceOracle(links[LINK_SKILL_ORACLE_2]).currentPrice();
        }
        else {
            return IPriceOracle(links[LINK_KING_ORACLE]).currentPrice();
        }
    }

    function setCBKLandPrice(uint256 tier, uint256 newPrice, uint256 currency) external isAdmin {
        require(newPrice > 0, 'invalid price');
        require(tier >= cbkLandSale.TIER_ONE() && tier <= cbkLandSale.TIER_THREE(), "Invalid tier");
        landPrices[currency][tier] = newPrice;
    }

    function payCurrency(address payer, uint256 paying, uint256 currency) internal {
        if(currency == CURRENCY_SKILL){
             game.payContractConvertedSupportingStaked(payer, paying);
        }
        else {
            IERC20(currencies[currency]).transferFrom(payer, address(this), paying);
        }
    }
}