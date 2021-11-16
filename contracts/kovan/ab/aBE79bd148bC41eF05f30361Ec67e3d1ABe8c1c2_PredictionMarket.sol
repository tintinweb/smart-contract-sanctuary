/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: PredictionMarket.sol

contract PredictionMarket {
    address public s_owner;
    address payable[] public s_players;
    uint256 public s_usdEntryFee;

    AggregatorV3Interface internal ethUsdPriceFeed;

    enum Side {
        Marcos,
        Pacquiao
    }
    struct Result {
        Side winner;
        Side loser;
    }
    Result public s_result;

    enum MARKET_STATE {
        CLOSED,
        OPEN,
        CALCULATING_WINNER,
        CLOSED_FOREVER
    }
    MARKET_STATE public market_state;

    // maps each side to the total amount of eth bet on each candidate
    mapping(Side => uint256) public bets;

    // maps the gambler's address to the side he/she has bet on
    // which maps to amount betted by the gambler
    mapping(address => mapping(Side => uint256)) public betsPerGambler;

    constructor(address owner, address priceFeedAddress) public {
        s_owner = owner;
        s_usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(priceFeedAddress);
        market_state = MARKET_STATE.CLOSED;
    }

    function placeBet(Side side) external payable {
        require(market_state == MARKET_STATE.OPEN, "Market not open!");
        require(msg.sender != s_owner, "Owner cannot place bet!");
        // $50 minimum
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        bets[side] += msg.value;
        betsPerGambler[msg.sender][side] += msg.value;
        s_players.push(msg.sender);
    }

    function startMarket() public {
        require(msg.sender == s_owner, "Only owner can call this function!");
        require(market_state == MARKET_STATE.CLOSED, "Market already open!");
        market_state = MARKET_STATE.OPEN;
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //18 Decimals
        uint256 costToEnter = (s_usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function sendWinnings() internal {
        require(
            market_state == MARKET_STATE.CALCULATING_WINNER,
            "Market is still open!"
        );
        for (
            uint256 playerIndex = 0;
            playerIndex < s_players.length;
            playerIndex++
        ) {
            uint256 gamblerBet = betsPerGambler[s_players[playerIndex]][
                s_result.winner
            ];
            if (gamblerBet > 0) {
                uint256 totalWin = gamblerBet +
                    (bets[s_result.loser] * gamblerBet) /
                    bets[s_result.winner];

                betsPerGambler[msg.sender][Side.Marcos] = 0;
                betsPerGambler[msg.sender][Side.Pacquiao] = 0;
                s_players[playerIndex].transfer(totalWin);

                market_state = MARKET_STATE.CLOSED_FOREVER;
            }
        }
    }

    function reportResult(Side winner, Side loser) external {
        require(msg.sender == s_owner, "Only owner can call this function!");
        require(market_state == MARKET_STATE.OPEN, "Market is closed forever!");
        market_state = MARKET_STATE.CALCULATING_WINNER;
        s_result.winner = winner;
        s_result.loser = loser;
        sendWinnings();
    }
}