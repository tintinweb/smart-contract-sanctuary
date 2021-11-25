/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface AggregatorV3Interface {
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

interface HomeContractClient {
    function getStudentsList() external view returns (string[] memory students); 
}

interface ERC20Client {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract BuyTestCoin {

    AggregatorV3Interface internal priceFeed;
    HomeContractClient internal homeContractClient;
    ERC20Client internal testTokenClient;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    constructor() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        homeContractClient = HomeContractClient(0x0E822C71e628b20a35F8bCAbe8c11F274246e64D);
        testTokenClient = ERC20Client(0x938032d88C839DceC68D9C3E6b6eb400F85532bD);
    }

    function _getLatestPrice() private view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        
        return price;
    }

    function _getStudentsCount() private view returns (int) {
        string[] memory students = homeContractClient.getStudentsList();

        return int(students.length);
    }

    function getTokenPrice() public view returns (uint256) {
        return uint256(_getLatestPrice() / _getStudentsCount());
    }

    function buyTokens() public payable returns (uint256) {
        require(msg.value > 0, "Send ETH to buy some tokens");

        uint256 amountToBuy = msg.value * getTokenPrice();

        uint256 vendorBalance = testTokenClient.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Sorry, there is not enough tokens to buy");

        (bool sent) = testTokenClient.transfer(msg.sender, amountToBuy);
        require(sent, "Transfer is failed");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);

        return amountToBuy;
    }
}