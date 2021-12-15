/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Casin0x {
    struct GameInfo {
        uint256 resultTimeSeconds;
        uint256 betDeadlineTimeSeconds;
        uint256 strikePrice;
        uint256 totalBetOnHitOrHigher;
        uint256 totalBetOnLower;
        bool finalized;
        bool resultHitOrHigher;
    }

    struct Bet {
        address player;
        uint256 betSize;
        bool hitOrHigher;
    }

	GameInfo internal gameInfo;
    Bet[] internal bets;
    mapping(address => uint256) internal totalBetOnHitOrHigherByAddress;
    mapping(address => uint256) internal totalBetOnLowerByAddress;

	event NewBet(Bet _bet);

    constructor(
        uint256 _betDeadlineTimeSeconds,
        uint256 _resultTimeSeconds,
        uint256 _strikePrice
    ) {
        gameInfo.betDeadlineTimeSeconds = _betDeadlineTimeSeconds;
        gameInfo.resultTimeSeconds = _resultTimeSeconds;
        gameInfo.strikePrice = _strikePrice;
    }

    function placeBet(bool hitOrHigher) public payable {
        require(block.timestamp < gameInfo.betDeadlineTimeSeconds, "Betting already closed.");

        Bet memory bet;
        bet.betSize = msg.value;
        bet.hitOrHigher = hitOrHigher;
        bet.player = msg.sender;
        bets.push(bet);

        if (hitOrHigher) {
            gameInfo.totalBetOnHitOrHigher += msg.value;
            totalBetOnHitOrHigherByAddress[msg.sender] += msg.value;
        } else {
            gameInfo.totalBetOnLower += msg.value;
            totalBetOnLowerByAddress[msg.sender] += msg.value;
        }

        emit NewBet(bet);
    }

    function collectReward() public {
        require(gameInfo.finalized, "Someone needs to call finalize() first.");

        uint256 total = gameInfo.totalBetOnHitOrHigher + gameInfo.totalBetOnLower;
        uint256 reward;
        if (gameInfo.resultHitOrHigher) {
            // totalBetOnHitOrHigherByAddress[msg.sender] return 0 if key is not in the map
            reward = total * totalBetOnHitOrHigherByAddress[msg.sender] / gameInfo.totalBetOnHitOrHigher;
            totalBetOnHitOrHigherByAddress[msg.sender] = 0;
        } else {
            reward = total * totalBetOnLowerByAddress[msg.sender] / gameInfo.totalBetOnLower;
            totalBetOnLowerByAddress[msg.sender] = 0;
        }

        payable(msg.sender).transfer(reward);
    }

    function getResultPrice() private pure returns (uint256) {
        return 6001;
    }

    function finalize() public {
        require(block.timestamp >= gameInfo.resultTimeSeconds, "Result not available yet.");

        uint256 resultPrice = getResultPrice();
        if (resultPrice >= gameInfo.strikePrice) {
            gameInfo.resultHitOrHigher = true;
        } else {
            gameInfo.resultHitOrHigher = false;
        }

        gameInfo.finalized = true;
    }


    function getBet(uint256 index) public view returns (Bet memory) {
        return bets[index];
    }

    function getBetCount() public view returns (uint256) {
        return bets.length;
    }

    function getGameInfo() public view returns (GameInfo memory) {
	return gameInfo;
    }
}