// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;
import "AggregatorV3Interface.sol";

contract Lottery {
    // List of players that have entered the lottery
    address payable[] players;
    uint256 usdEntranceFee;
    AggregatorV3Interface internal priceFeed;
    LOTTERY_STATE lotteryState;
    address lotteryOwner;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNNER
    }

    constructor(address _priceFeedAddr) public {
        usdEntranceFee = 50 * (10**18);
        priceFeed = AggregatorV3Interface(_priceFeedAddr);
        lotteryState = LOTTERY_STATE.CLOSED;
        lotteryOwner = msg.sender;
    }

    // Enter the lottery, but first check that the player
    // has sufficient funds
    function enter() public payable {
        require(
            lotteryState == LOTTERY_STATE.OPEN,
            "Cannot enter, the lottery is closed."
        );
        require(
            msg.value > getEntranceFee(),
            "At least 50 USD is required to enter the lottery"
        );

        // Add the player to the list of lottery members
        players.push(msg.sender);
    }

    // Return the entrance fee in terms of eth (represented in wei)
    function getEntranceFee() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 ethToUsd = uint256(answer) / (10**8);
        return usdEntranceFee / ethToUsd;
    }

    function startLottery() public {
        require(
            lotteryState == LOTTERY_STATE.CLOSED,
            "Lottery is already in progress"
        );

        lotteryState = LOTTERY_STATE.OPEN;
    }

    modifier onlyOwner() {
        require(msg.sender == lotteryOwner);

        _;
    }

    function endLottery() public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.OPEN // TODO: Turn into modifier
        );

        // Choose the winner
        lotteryState = LOTTERY_STATE.CALCULATING_WINNNER;
        address payable winner = players[0]; // TODO: Choose the winner randomly
        winner.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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