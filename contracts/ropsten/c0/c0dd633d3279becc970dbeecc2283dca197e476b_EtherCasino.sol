/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract EtherCasino {
    address admin;
    uint256 session;
    uint256 gameId = 0;
    uint256 lastGameId = 0;

    mapping(uint256 => Game) games;

    struct Game {
        uint256 id;
        string user;
        uint256 rangeFrom;
        uint256 rangeTo;
        uint256 amount;
        address payable player;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You're not an admin.");
        _;
    }

    modifier isGameTime() {
        require(
            block.timestamp * 1000 < session - 300000,
            "Wait for next the next Game."
        );
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setSession(uint256 _session) public payable {
        session = _session;
    }

    function getSession() public view returns (uint256) {
        return session;
    }

    function betGame(
        string memory _user,
        uint256 _rangeFrom,
        uint256 _rangeTo
    ) public payable isGameTime returns (uint256) {
        games[gameId] = Game(
            gameId,
            _user,
            _rangeFrom,
            _rangeTo,
            msg.value,
            payable(msg.sender)
        );
        gameId += 1;

        return session;
    }

    function playGame() public payable {
        uint256 value1 = 0;
        uint256 value2 = 0;
        uint256 rand = 0;
        for (uint256 i = lastGameId; i < gameId; i++) {
            if (games[i].rangeTo == 3) {
                value1 = games[i].amount;
            } else if (games[i].rangeTo == 6) {
                value2 = games[i].amount;
            }
        }
        if (value1 < value2) {
            rand = generate(block.timestamp, 0, 3);
        } else if (value2 < value1) {
            rand = generate(block.timestamp, 4, 6);
        } else {
            rand = generate(block.timestamp, 0, 6);
        }
        sendReward(rand);
    }

    function sendReward(uint256 rand) public payable {
        for (uint256 i = lastGameId; i < gameId; i++) {
            uint256 reward = 0;
            if (rand >= games[i].rangeFrom && rand <= games[i].rangeTo) {
                reward = games[i].amount * 2;
                games[i].player.transfer(reward);
            }
        }
        lastGameId = gameId;
    }

    function generate(
        uint256 time,
        uint256 seed1,
        uint256 seed2
    ) private returns (uint256) {
        uint256 rand = (time % seed2) + 1;
        if (rand < seed1) {
            return generate(time + rand, seed1, seed2);
        }
        return rand;
    }
}