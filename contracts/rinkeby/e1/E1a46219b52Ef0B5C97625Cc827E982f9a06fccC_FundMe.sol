// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping(address => uint256) public address_to_amount_funded;
    address[] public funders;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function fund() payable public {
        uint256 min_value = 50 * 10**18;
        require(get_conversion_rate(msg.value) >= min_value, 'You need to spend MORE!!!');
        address_to_amount_funded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function get_version() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function num_decimals() public view returns(uint8){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.decimals();
    }

    function get_price() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        uint256 factor = 18 - uint256(num_decimals());
        return uint256(answer)*10**factor;
    }

    function get_conversion_rate(uint256 eth_amount) public view returns(uint256){
        uint256 eth_price = get_price();
        uint256 eth_amount_usd = (eth_amount * eth_price) / 10**18;
        return eth_amount_usd;
    }

    modifier only_owner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable only_owner public {
        owner.transfer(address(this).balance);
        for (uint256 i=0; i < funders.length; i++) {
            address_to_amount_funded[funders[i]] = 0;
        }
        funders = new address[](0);
    }

}

//3309183289080000000000

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