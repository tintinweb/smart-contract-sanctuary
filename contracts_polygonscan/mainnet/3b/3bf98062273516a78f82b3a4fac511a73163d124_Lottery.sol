// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public attousdEntryFee;
    AggregatorV3Interface internal coinUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    // OPEN: 0
    // CLOSED: 1
    // CALCULATING_WINNER: 2

    LOTTERY_STATE public lotteryState;
    uint256 public fee; // fee in LINK
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash,
        uint256 _minUsd
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        attousdEntryFee = _minUsd * (10**18);
        coinUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        require(lotteryState == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough coins!");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = coinUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (attousdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lotteryState == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer((address(this).balance * 97) / 100);
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

    function changeAttousdEntryFee(uint256 _attousd) public onlyOwner {
        attousdEntryFee = _attousd;
    }
}