pragma solidity ^0.8.0;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Yamato
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
 *
 * This Factory is a fork of Murray Software's deliverables.
 * And this entire project is including the fork of Hegic Protocol.
 * Hence the license is alinging to the GPL-3.0
*/

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract ChainlinkMock {
    uint80 private lastRoundId;
    uint80 private lastPriceUpdateRoundId;
    uint8 public chaosCounter;
    int256 public lastPrice;
    
    uint public _deviation;
    int256 public _change;

    constructor() public {
        lastRoundId = 30000000000000000001;
        lastPriceUpdateRoundId = 30000000000000000001;
        chaosCounter = 0;
        lastPrice = 300000000000;
    }

    function latestRoundData() external returns (
      uint80 roundId, // The round ID.
      int256 answer, // The price.
      uint256 startedAt, // Timestamp of when the round started.
      uint256 updatedAt, // Timestamp of when the round was updated.
      uint80 answeredInRound // The round ID of the round in which the answer was computed.
    ) {
      (
        uint deviation,
        bool sign
      ) = randomize();
      
      uint80 currentRoundId = lastRoundId + 1;
    
      if (deviation == 0) {
        // no deviation, hence answeredInRound == lastPriceUpdateRoundId
        answer = lastPrice;
        answeredInRound = lastPriceUpdateRoundId;

        _change = 0;
      } else {
        if (deviation == 10) {
          if (chaos()) {
            deviation = 51;
          }
        }

        int change = lastPrice / 10000;
        change = change * int(deviation);
        answer = sign ? answer + change : answer - change;

        if (answer == 0) {
          // Price shouldn't be zero, reset if so
          answer = 300000000000;
        } else if (answer < 0) {
          // Price shouldn't be negative, flip the sign if so
          answer = answer * -1;
        }

        lastPrice = answer;
        answeredInRound = currentRoundId;
        lastPriceUpdateRoundId = currentRoundId;

        _change = change;
      }
      _deviation = deviation;
      return (currentRoundId, answer, block.timestamp, block.timestamp, answeredInRound);
    }

    function randomize() private view returns (uint, bool) {
      uint randomNumber = uint(keccak256(abi.encodePacked(msg.sender,  block.timestamp,  blockhash(block.number - 1))));
      uint deviation = randomNumber % 11;
      bool sign = randomNumber % 2 == 1 ? true : false;
      return (deviation, sign);
    }

    // If chaos counter == 10, reset it to 0 and trigger chaos = 51% deviation
    // Otherwise, increment the chaos counter and return false
    function chaos() private returns (bool) {
      if (chaosCounter == 10) {
        chaosCounter == 0;
        return true;
      }
      chaosCounter += 1;
      return false;
    }
}

