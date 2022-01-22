//SPDX-License-Identifier:MIT
pragma solidity >=0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public add_to_amount;
    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 min_val = 50 * 10**18;
        require(
            get_cvt_value(msg.value) >= min_val,
            " You need to send more ETH"
        );
        add_to_amount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function get_version() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return pricefeed.version();
    }

    function get_price() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //(uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound) = pricefeed.latestRoundData();
        (, int256 answer, , , ) = pricefeed.latestRoundData();
        return uint256(answer * (10**10)); //converted to gwei which is 10X18 in eth
        //3316748747380000000000
        //3,316.74874738
    }

    function get_cvt_value(uint256 ethAmount) public view returns (uint256) {
        uint256 ethprice = get_price();
        uint256 ethAmountinUSD = (ethAmount * ethprice) / (10**18);
        return (ethAmountinUSD);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, " No Dice !");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            add_to_amount[funder] = 0;
        }
        funders = new address[](0);
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