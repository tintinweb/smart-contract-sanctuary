/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

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

contract FundMe {
    // uint256 decimal = 10**18;
    //with mapping, we can't loop through it.
    mapping(address => uint256) addressToAmountFunded;
    //so use another structure to store all address, and then use that to loop
    // all address in mapping.
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        // uint256 minimumUSD = 50*decimal;
        uint256 minimumUSD = 50 * 1000000000000000000;

        require(
            getConvertRate(msg.value) >= minimumUSD,
            "THUAN contract require more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        //you need the rate to covert from ETH-> USD by convert Rate!!!
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    //return eth price with 18 decimals behind-> actual return wei value dollar!
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //answer actual return value of ETH with 8decimal behind! -> so i have to multi with 10 decimal too.
        return uint256(answer * 10000000000); //*1000000000 or 10000000000 (right seem better!) 10 zero numbers
        //should return around: 374431181187 -> convert 8 decimals-> 3,744.31181187 $
    }

    //wei = smallest value of eth number.
    //1 gwei = 1000000000 wei
    //convert value they send to us dollar
    //@param: ethAmount- wei value!
    //@return: also wei value!
    function getConvertRate(uint256 ehtAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 real_value = (ethPrice * ehtAmount) / 1000000000000000000;
        return real_value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //time to withdraw all money
        payable(msg.sender).transfer(address(this).balance);
        //set all other funders turn  to 0
        for (uint256 i; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        //re-construct all funders.
        funders = new address[](0);
    }
}