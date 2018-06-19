pragma solidity 0.4.24;

contract CopaDelCrypto
{
  address public owner;
  constructor() public
  {
    owner = msg.sender;
  }
  modifier onlyOwner
  {
    require(msg.sender == owner);
    _;
  }

  struct Forecast
  {
    bytes32 part1;
    bytes32 part2;
    bytes32 part3;
    bytes12 part4;
    bool hasPaidOrWon;
  }

  uint256 public prizeValue;
  uint256 public resultsPublishedTime;

  bytes32 public worldCupResultPart1;
  bytes32 public worldCupResultPart2;
  bytes32 public worldCupResultPart3;
  bytes12 public worldCupResultPart4;

  bool public forecastingClosed;
  bool public resultsPublished;

  uint32 public resultsValidationStep;
  uint32 public verifiedWinnersCount;
  uint32 public verifiedWinnersLastCount;

  uint16 public publishedWinningScoreThreshold;
  uint16 public expectedWinnersCount;

  address[] public players;

  mapping(address => Forecast) public forecasts;

  function PlaceNewForecast(bytes32 f1, bytes32 f2, bytes32 f3, bytes12 f4)
  public payable
  {
    require(!forecastingClosed && msg.value == 50000000000000000 && !forecasts[msg.sender].hasPaidOrWon);

    forecasts[msg.sender].part1 = f1;
    forecasts[msg.sender].part2 = f2;
    forecasts[msg.sender].part3 = f3;
    forecasts[msg.sender].part4 = f4;
    forecasts[msg.sender].hasPaidOrWon = true;

    players.push(msg.sender);
  }

  function UpdateForecast(bytes32 f1, bytes32 f2, bytes32 f3, bytes12 f4)
  public
  {
    require(!forecastingClosed && forecasts[msg.sender].hasPaidOrWon);

    forecasts[msg.sender].part1 = f1;
    forecasts[msg.sender].part2 = f2;
    forecasts[msg.sender].part3 = f3;
    forecasts[msg.sender].part4 = f4;
  }

  function CloseForecasting(uint16 exWinCount)
  public onlyOwner
  {
    require(!forecastingClosed);
    require((exWinCount == 0 && players.length > 10000)
             || (exWinCount > 0 && (uint32(exWinCount) * uint32(exWinCount) >= players.length
                 && uint32(exWinCount - 1) * uint32(exWinCount - 1) < players.length)));
    expectedWinnersCount = (players.length) > 10000 ? uint16(players.length / 100) : exWinCount;

    forecastingClosed = true;
  }

  function PublishWorldCupResults(bytes32 res1, bytes32 res2, bytes32 res3, bytes12 res4)
  public onlyOwner
  {
    require(forecastingClosed && !resultsPublished);

    worldCupResultPart1 = res1;
    worldCupResultPart2 = res2;
    worldCupResultPart3 = res3;
    worldCupResultPart4 = res4;

    resultsValidationStep = 0;
    verifiedWinnersCount = 0;
    verifiedWinnersLastCount = 0;
    resultsPublishedTime = block.timestamp;
  }

  function PublishWinnersScoreThres(uint16 scoreThres)
  public onlyOwner
  {
    require(forecastingClosed && !resultsPublished);

    publishedWinningScoreThreshold = scoreThres;
  }

  function VerifyPublishedResults(uint16 stepSize)
  public onlyOwner
  {
    require(forecastingClosed && !resultsPublished);
    require(stepSize > 0 && resultsValidationStep + stepSize <= players.length);

    uint32 wins;
    uint32 lasts;

    for (uint32 i = resultsValidationStep; i < resultsValidationStep + stepSize; i++) {

      Forecast memory fc = forecasts[players[i]];

      uint16 score = scoreGroups(fc.part1, fc.part2, worldCupResultPart1, worldCupResultPart2)
                     + scoreKnockouts(fc.part2, fc.part3, fc.part4);

      if (score >= publishedWinningScoreThreshold) {
        wins++;
        if (score == publishedWinningScoreThreshold) {
          lasts++;
        }
        forecasts[players[i]].hasPaidOrWon = true;
      } else {
        forecasts[players[i]].hasPaidOrWon = false;
      }
    }

    resultsValidationStep += stepSize;
    verifiedWinnersCount += wins;
    verifiedWinnersLastCount += lasts;

    if (resultsValidationStep == players.length) {
      verifiedWinnersCount = validateWinnersCount(verifiedWinnersCount, verifiedWinnersLastCount, expectedWinnersCount);
      verifiedWinnersLastCount = 0;
      expectedWinnersCount = 0;

      if (verifiedWinnersCount > 0) {
        prizeValue = address(this).balance / verifiedWinnersCount;
        resultsPublished = true;
      }
    }
  }

  function WithdrawPrize()
  public
  returns(bool)
  {
    require(prizeValue > 0);

    if (forecasts[msg.sender].hasPaidOrWon) {
      forecasts[msg.sender].hasPaidOrWon = false;
      if (!msg.sender.send(prizeValue)) {
        forecasts[msg.sender].hasPaidOrWon = true;
        return false;
      }
      return true;
    }
    return false;
  }

  function CancelGame()
  public onlyOwner
  {
    forecastingClosed = true;
    resultsPublished = true;
    resultsPublishedTime = block.timestamp;
    prizeValue = address(this).balance / players.length;
  }

  function CancelGameAfterResultsPublished()
  public onlyOwner
  {
    CancelGame();
    for (uint32 i = 0; i < players.length; i++) {
    	forecasts[players[i]].hasPaidOrWon = true;
    }
  }

  function WithdrawUnclaimed()
  public onlyOwner
  returns(bool)
  {
    require(resultsPublished && block.timestamp >= (resultsPublishedTime + 10 weeks));

    uint256 amount = address(this).balance;
    if (amount > 0) {
      if (!msg.sender.send(amount)) {
        return false;
      }
    }
    return true;
  }

  function getForecastData(bytes32 pred2, bytes32 pred3, bytes12 pred4, uint8 index)
  public pure
  returns(uint8)
  {
    assert(index >= 32 && index < 108);
    if (index < 64) {
      return uint8(pred2[index - 32]);
    } else if (index < 96) {
      return uint8(pred3[index - 64]);
    } else {
      return uint8(pred4[index - 96]);
    }
  }

  function getResultData(uint8 index)
  public view
  returns(uint8)
  {
    assert(index >= 32 && index < 108);
    if (index < 64) {
      return uint8(worldCupResultPart2[index - 32]);
    } else if (index < 96) {
      return uint8(worldCupResultPart3[index - 64]);
    } else {
      return uint8(worldCupResultPart4[index - 96]);
    }
  }

  function computeGroupPhasePoints(uint8 pred, uint8 result)
  public pure
  returns(uint8)
  {
    uint8 gamePoint = 0;

    int8 predLeft = int8(pred % 16);
    int8 predRight = int8(pred >> 4);
    int8 resultLeft = int8(result % 16);
    int8 resultRight = int8(result >> 4);

    int8 outcome = resultLeft - resultRight;
    int8 predOutcome = predLeft - predRight;

    if ((outcome > 0 && predOutcome > 0)
        || (outcome < 0 && predOutcome < 0)
        || (outcome == 0 && predOutcome == 0)) {
      gamePoint += 4;
    }

    if (predLeft == resultLeft) {
      gamePoint += 2;
    }

    if (predRight == resultRight) {
      gamePoint += 2;
    }
    return gamePoint;
  }

  function computeKnockoutPoints(uint8 pred, uint8 result, uint8 shootPred, uint8 shootResult,
                                 uint8 roundFactorLeft, uint8 roundFactorRight, bool isInverted)
  public pure
  returns (uint16)
  {
    uint16 gamePoint = 0;
    int8 predLeft = int8(pred % 16);
    int8 predRight = int8(pred >> 4);
    int8 resultLeft = int8(result % 16);
    int8 resultRight = int8(result >> 4);

    int8 predOutcome = predLeft - predRight;
    int8 outcome = resultLeft - resultRight;

    if (predOutcome == 0) {
       predOutcome = int8(shootPred % 16) - int8(shootPred >> 4);
    }
    if (outcome == 0) { 
       outcome = int8(shootResult % 16) - int8(shootResult >> 4);
    }

    if (isInverted) {
      resultLeft = resultLeft + resultRight;
      resultRight = resultLeft - resultRight;
      resultLeft = resultLeft - resultRight;
      outcome = -outcome;
    }

    if ((outcome > 0 && predOutcome > 0) || (outcome < 0 && predOutcome < 0)) {
      gamePoint += 4 * (roundFactorLeft + roundFactorRight);
    }

    gamePoint += 4 * ((predLeft == resultLeft ? roundFactorLeft : 0)
                      + (predRight == resultRight ? roundFactorRight: 0));

    return gamePoint;
  }

  function scoreGroups(bytes32 pred1, bytes32 pred2, bytes32 res1, bytes32 res2)
  public pure
  returns(uint16)
  {
    uint16 points = 0;
    for (uint8 f = 0; f < 48; f++) {
      if (f < 32) {
        points += computeGroupPhasePoints(uint8(pred1[f]), uint8(res1[f]));
      } else {
        points += computeGroupPhasePoints(uint8(pred2[f - 32]), uint8(res2[f - 32]));
      }
    }
    return points;
  }

  function scoreKnockouts(bytes32 pred2, bytes32 pred3, bytes12 pred4)
  public view
  returns(uint16)
  {
    uint8 f = 48;
    uint16 points = 0;

    int8[15] memory twinShift = [int8(16), 16, 16, 16, -16, -16, -16, -16, 8, 8, -8, -8, 4, -4, 0];
    uint8[15] memory roundFactor = [uint8(2), 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4, 8, 8, 16];

    for (uint8 i = 0; i < 15; i++) {

      bool teamLeftOK = getForecastData(pred2, pred3, pred4, f) == getResultData(f);
      bool teamRightOK = getForecastData(pred2, pred3, pred4, f + 1) == getResultData(f + 1);

      if (teamLeftOK || teamRightOK) {
        points += computeKnockoutPoints(getForecastData(pred2, pred3, pred4, f + 2), getResultData(f + 2),
                                        getForecastData(pred2, pred3, pred4, f + 3), getResultData(f + 3),
                                        teamLeftOK ? roundFactor[i] : 0, teamRightOK ? roundFactor[i] : 0,
                                        false);
        if (i < 8) {
          points += (teamLeftOK ? 4 : 0) + (teamRightOK ? 4 : 0);
        }
      }

      bool isInverted = (i < 8) || i == 14;
      teamLeftOK = getForecastData(pred2, pred3, pred4, f) ==
                   (getResultData(uint8(int8(f + (isInverted ? 1 : 0)) + twinShift[i])));
      teamRightOK = getForecastData(pred2, pred3, pred4, f + 1) ==
                   (getResultData(uint8(int8(f + (isInverted ? 0 : 1)) + twinShift[i])));

      if (teamLeftOK || teamRightOK) {
        points += computeKnockoutPoints(getForecastData(pred2, pred3, pred4, f + 2),
                                        getResultData(uint8(int8(f + 2) + twinShift[i])),
                                        getForecastData(pred2, pred3, pred4, f + 3),
                                        getResultData(uint8(int8(f + 3) + twinShift[i])),
                                        teamLeftOK ? roundFactor[i] : 0, teamRightOK ? roundFactor[i] : 0,
                                        isInverted);
        if (i < 8) {
          points += (teamLeftOK ? 2 : 0) + (teamRightOK ? 2 : 0);
        }
      }
      f = f + 4;
    }
    return points;
  }

  function validateWinnersCount(uint32 winners, uint32 last, uint32 expected)
  public pure
  returns(uint32)
  {
    if (winners < expected) {
      return 0;
    } else if ((winners == expected && last >= 1)
                || (last > 1 && (winners - last) < expected)) {
      return winners;
    } else {
      return 0;
    }
  }
}