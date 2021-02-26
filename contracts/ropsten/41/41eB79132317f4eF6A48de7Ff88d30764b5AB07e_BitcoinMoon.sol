// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./AggregatorV3Interface.sol";

contract BitcoinMoon {

    int priceTarget = 1000000;
    address public minter;
    event withdrawal(address indexed _wallet, int _amount);
    AggregatorV3Interface internal priceFeed;

    // Get BTC/USD price
    constructor() public {
        minter = msg.sender;
        priceFeed = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function requestFunds() public {
        require( msg.sender == minter );

        // if BTC price aboce threshold, release funds
        int btcPrice = getLatestPrice();
        require( btcPrice >= priceTarget );

        // Invoke on msg.sender because that is an "address payable" type
        uint256 amount = address(this).balance;
        msg.sender.transfer(amount);
        emit withdrawal(msg.sender, int256(amount));

        // I read about this being safer to transfer funds but I don't fully understand it yet so not sure
        // (bool success, ) = minter.call.value(balance)("");
        // require(success, "Transfer failed.");
    }
}