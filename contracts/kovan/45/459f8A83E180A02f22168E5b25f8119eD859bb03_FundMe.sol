// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;
    address[] funders;

    function fund() public payable {

        uint256 minUsd = 50 * 10 ** 8;
        uint256 usdAmount = getConversionRate(msg.value);

        require(usdAmount >= minUsd, "Invalid tx: ETH value below $50");

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256) {

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();

        uint256 usdAmountValue = ethAmount * ethPrice;

        return usdAmountValue;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function withdraw() payable public onlyOwner {

        payable(msg.sender).transfer(address(this).balance);

        for(uint256 funderIndex; funderIndex < funders.length; funderIndex++){
            addressToAmountFunded[funders[funderIndex]] = 0;
        }
        funders = new address[](0);
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