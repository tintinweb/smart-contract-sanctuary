// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*interface AggregatorV3Interface {
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
}*/

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping (address => uint256) public addressToAmountFunded;
    address owner;
    uint256 minimumUSD = 50*10**18;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
    function fund() public payable {
        require(getConversionRate(msg.value) >= minimumUSD, "You need to pay more");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e); //Kovan testnet
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C); //BSC Testnet
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10**10);
    }

    function getConversionRate(uint256 coinAmount) public view returns(uint256) {
        return (coinAmount * getPrice()) / 10**18;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function withdraw() public onlyOwner payable {
        //require(msg.sender == owner, "Only the owner can withdraw!");
        //addressToAmountFunded[owner] -= address(this).balance;
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 fundersIndex=0; fundersIndex < funders.length; fundersIndex++) {
          addressToAmountFunded[funders[fundersIndex]] = 0;
        }
        //blank address
        funders = new address[](0);
    }

    function getEntranceFee() public view returns (uint256) {
      uint256 price = getPrice();
      uint256 precision = 1 * 10**18;
      // to use safemath to return the ceiling of (minimumUSD * precision) / price;
      return (minimumUSD * precision) / price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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