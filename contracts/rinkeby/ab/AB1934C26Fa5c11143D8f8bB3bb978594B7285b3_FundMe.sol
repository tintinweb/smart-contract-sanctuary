// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    
    mapping(address => uint256) public fundings;
    address[] public funders;
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
         return priceFeed.version();
    }
    
    function fund() public payable {
        uint256 minUSDFund = 10 * 10 ** 18;
        require(getConversionRate(msg.value) >= minUSDFund, "need to send more Eth!");
        fundings[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
       
       return uint256(answer * 10000000000);
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
      uint256 ethPrice = getPrice();
      uint ethAmountinUSD = (ethPrice * ethAmount) / 1000000000000000000;
      return ethAmountinUSD;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable onlyOwner public {
       // require(msg.sender == owner);
        payable(msg.sender).transfer( address(this).balance);
        
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            fundings[funders[funderIndex]] = 0;
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