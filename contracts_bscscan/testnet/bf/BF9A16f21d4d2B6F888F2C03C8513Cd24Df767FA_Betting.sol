//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Betting {
    // @dev If betting odd is 1.25, admin should submit 125
    uint constant oddsMultiplier = 100;
    enum BettingType{HomeWin, Draw, AwayWin}

    event BetPlaced(address indexed player, uint256 amount, BettingType bettingType, uint indexed matchId);
    event BetWon(address indexed player, uint256 amount, BettingType bettingType, uint indexed matchId);
    event OddsSet(uint indexed matchId, uint256 homeWin, uint draw, uint awayWin);

    address public admin;
    uint public bettingDeadline;

    struct Bet {
        address player;
        BettingType bettingType;
        uint amount;
    }

    struct Odds {
        uint homeWin;
        uint draw;
        uint awayWin;
    }

    // @dev Mapping for matchId => Bet
    mapping(uint => Bet[]) public bets;
    // @dev Mapping for matchId => Odds
    mapping(uint => Odds) public betOdds;
    
    constructor(uint _bettingDeadline) payable {
        admin = msg.sender;
        bettingDeadline = _bettingDeadline;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Admin only");
        _;
    }

    modifier beforeDeadline {
        require(block.timestamp <= bettingDeadline, "Deadline has passed");
        _;
    }

    modifier afterDeadline {
        require(block.timestamp > bettingDeadline, "Betting is not finished");
        _;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function setOdds(uint matchId, uint homeWin, uint draw, uint awayWin) public beforeDeadline onlyAdmin {
        betOdds[matchId] = Odds(homeWin, draw, awayWin);
        emit OddsSet(matchId, homeWin, draw, awayWin);
    }

    function placeBet(uint matchId, BettingType bettingType) external beforeDeadline payable {
        require(msg.value > 0, "Bet amount must be greater than 0");

        Bet memory newBet = Bet({
            player: msg.sender,
            amount: msg.value,
            bettingType: bettingType
        });

        bets[matchId].push(newBet);

        emit BetPlaced(msg.sender, msg.value, bettingType, matchId);
    }

    function payWinningBets(uint matchId, BettingType winningType) public onlyAdmin afterDeadline {
        Bet[] memory allBets = bets[matchId];

        for (uint i = 0; i < allBets.length; i++) {
            Bet memory bet = allBets[i];
            if (bet.bettingType == winningType) {
                uint payoutAmount = calculateWinning(matchId, winningType, bet.amount);
                payable(bet.player).call{value: payoutAmount}("");
                // ignore result because we don't care if it worked or not
                // we should use a withdrawal pattern instead of this, a bad address can deliberately revert to sabotage others
                emit BetWon(bet.player, payoutAmount, winningType, matchId);
            }
        }

        delete bets[matchId];
    }

    function calculateWinning(uint matchId, BettingType winningType, uint betSize) internal view returns(uint) {
        Odds memory odds = betOdds[matchId];

        uint multiplier;

        if (winningType == BettingType.HomeWin) {
            multiplier = odds.homeWin;
        } else if (winningType == BettingType.Draw) {
            multiplier = odds.draw;
        } else if (winningType == BettingType.AwayWin) {
            multiplier = odds.awayWin;
        }

        uint winningAmount = betSize * multiplier / oddsMultiplier;
        uint fee = winningAmount / 100 * 5;
        
        // deduct fee, and leave it in our contract
        return winningAmount - fee;
    }
}