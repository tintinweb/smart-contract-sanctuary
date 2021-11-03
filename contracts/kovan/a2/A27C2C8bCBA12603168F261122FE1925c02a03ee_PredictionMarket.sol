/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: PredictionMarket.sol

contract PredictionMarket {
    address public s_market;
    bool public s_electionFinished;
    enum Side {
        Marcos,
        Pacquiao
    }
    struct Result {
        Side winner;
        Side loser;
    }
    Result public s_result;

    // maps each side to the total amount of eth bet on each candidate
    mapping(Side => uint256) public bets;

    // maps the gambler's address to the side he/she has bet on
    // which maps to amount betted by the gambler
    mapping(address => mapping(Side => uint256)) public betsPerGambler;

    constructor(address market) public {
        s_market = market;
    }

    function placeBet(Side side) external payable {
        require(s_electionFinished == false, "Election is finished!");
        bets[side] += msg.value;
        betsPerGambler[msg.sender][side] += msg.value;
    }

    function withdraw() external payable {
        uint256 gamblerBet = betsPerGambler[msg.sender][s_result.winner];
        require(gamblerBet > 0, "You do not have any winnings!");
        require(s_electionFinished == true, "Election not finished!");
        uint256 totalWin = gamblerBet +
            (bets[s_result.loser] * gamblerBet) /
            bets[s_result.winner];
        betsPerGambler[msg.sender][Side.Marcos] = 0;
        betsPerGambler[msg.sender][Side.Pacquiao] = 0;
        msg.sender.transfer(totalWin);
    }

    function reportResult(Side winner, Side loser) external {
        require(msg.sender == s_market, "Only market can call this function!");
        require(s_electionFinished == false, "Election is finished");
        s_result.winner = winner;
        s_result.loser = loser;
        s_electionFinished = true;
    }
}