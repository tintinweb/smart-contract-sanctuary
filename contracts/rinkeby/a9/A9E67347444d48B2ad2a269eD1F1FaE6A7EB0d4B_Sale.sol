// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface HomeInterface {
    function getStudentsList() external view returns (string[] memory students);
}

interface ERC20Token {
    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address recipient, uint256 value)
        external
        returns (bool success);
}

contract Sale {
    AggregatorV3Interface internal priceFeed;
    address public home_contract;
    address token;

    constructor(
        address _home_contract,
        address _token,
        address _chainLinkETHUSDRinkeby
    ) {
        home_contract = _home_contract;
        token = _token;
        priceFeed = AggregatorV3Interface(_chainLinkETHUSDRinkeby);
    }

    receive() external payable {
        buyTokens();
    }

    fallback() external {
        buyTokens();
    }

    function buyTokens() public payable {
        uint256 registeredStudentsLength = getRegisteredStudentsLength();
        require(registeredStudentsLength > 0, "Students lenght can't be 0");

        require(msg.value > 0, "Amount of tokens can't be 0");

        uint256 amount = (msg.value * getPrice()) / registeredStudentsLength;

        if (ERC20Token(token).balanceOf(address(this)) >= amount) {
            ERC20Token(token).transfer(msg.sender, amount);
        } else {
            (bool success, ) = msg.sender.call{
                gas: 300000000000000,
                value: msg.value
            }("Sorry, there is not enough tokens to buy");
            require(success, "External call failed");
        }
    }

    function getPrice() public view returns (uint256) {
        (, int256 priceETHUSDRinkeby, , , ) = priceFeed.latestRoundData();
        return uint256(priceETHUSDRinkeby) / (10**priceFeed.decimals());
    }

    function getRegisteredStudentsLength() public view returns (uint256) {
        string[] memory students = HomeInterface(home_contract)
            .getStudentsList();

        return students.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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