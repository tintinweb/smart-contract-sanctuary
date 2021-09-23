/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract ourps {
    uint256 public constant VOTING_PERIOD = 10 minutes;

    uint256 public constant ROCK = 0;
    uint256 public constant PAPER = 1;
    uint256 public constant SCISSORS = 2;
    uint256 public constant FAILED_TO_PICK = 3;

    uint256 public constant MAINTENANCE_FEE = 1e9 wei;

    uint256 public constant RED = 0;
    uint256 public constant BLUE = 1;
    uint256 public constant DRAW = 2;

    uint256 private roundEndTimestamp;

    uint256[3][2] private votes;
    uint256[3] private results;

    bool private lock;

    event RoundEnded(uint256 result);

    constructor() {
        roundEndTimestamp = block.timestamp + VOTING_PERIOD;
        lock = false;
    }

    function vote(uint256 team, uint256 action) external payable {
        require(!lock, "Round is being processed");
        require(!roundEnded(), "Cannot vote until round is processed");
        require(team < 3, "Invalid team");
        require(action < 3, "Invalid action");
        require(msg.value > MAINTENANCE_FEE, "Insufficient funds");
        votes[team][action] += 1;
    }

    function getVotes(uint256 team)
        external
        view
        returns (
            uint256 _rock,
            uint256 _paper,
            uint256 _scissors
        )
    {
        require(team < 3, "Invalid team");
        _rock = votes[team][ROCK];
        _paper = votes[team][PAPER];
        _scissors = votes[team][SCISSORS];
    }

    function getResults()
        external
        view
        returns (
            uint256 _red,
            uint256 _blue,
            uint256 _draw
        )
    {
        _red = results[RED];
        _blue = results[BLUE];
        _draw = results[DRAW];
    }

    function getRoundEndTimestamp() public view returns (uint256) {
        return roundEndTimestamp;
    }

    function roundEnded() public view returns (bool) {
        return block.timestamp > roundEndTimestamp;
    }

    function getMove(uint256 team) public view returns (uint256) {
        require(team < 3, "Invalid team");
        if (
            votes[team][ROCK] > votes[team][PAPER] &&
            votes[team][ROCK] > votes[team][SCISSORS]
        ) {
            return ROCK;
        } else if (
            votes[team][PAPER] > votes[team][ROCK] &&
            votes[team][PAPER] > votes[team][SCISSORS]
        ) {
            return PAPER;
        } else if (
            votes[team][SCISSORS] > votes[team][ROCK] &&
            votes[team][SCISSORS] > votes[team][PAPER]
        ) {
            return SCISSORS;
        } else {
            return FAILED_TO_PICK;
        }
    }

    function getWinner(uint256 blueMove, uint256 redMove)
        public
        pure
        returns (uint256)
    {
        if (blueMove == ROCK) {
            if (redMove == PAPER) {
                return RED;
            } else if (redMove == SCISSORS || redMove == FAILED_TO_PICK) {
                return BLUE;
            } else {
                return DRAW;
            }
        } else if (blueMove == PAPER) {
            if (redMove == SCISSORS) {
                return RED;
            } else if (redMove == ROCK || redMove == FAILED_TO_PICK) {
                return BLUE;
            } else {
                return DRAW;
            }
        } else if (blueMove == SCISSORS) {
            if (redMove == ROCK) {
                return RED;
            } else if (redMove == PAPER || redMove == FAILED_TO_PICK) {
                return BLUE;
            } else {
                return DRAW;
            }
        } else {
            // blueMove = FAILED_TO_PICK
            if (redMove == FAILED_TO_PICK) {
                return DRAW;
            } else {
                return RED;
            }
        }
    }

    function endRound() external {
        require(roundEnded(), "Round not ended yet");
        require(!lock, "Round is being processed");
        lock = true;
        uint256 blueMove = getMove(BLUE);
        uint256 redMove = getMove(RED);
        uint256 winner = getWinner(blueMove, redMove);

        roundEndTimestamp = block.timestamp + VOTING_PERIOD;
        votes[BLUE][ROCK] = 0;
        votes[BLUE][PAPER] = 0;
        votes[BLUE][SCISSORS] = 0;
        votes[RED][ROCK] = 0;
        votes[RED][PAPER] = 0;
        votes[RED][SCISSORS] = 0;

        results[winner] += 1;
        emit RoundEnded(winner);
        lock = false;
        payable(msg.sender).transfer(address(this).balance);
    }
}