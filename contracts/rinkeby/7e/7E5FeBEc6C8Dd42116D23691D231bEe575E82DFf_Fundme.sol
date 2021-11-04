// SPDX-License-Identifier: MIT

import "AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

contract Fundme{
    
    mapping(address => uint) public addressToAmountFunded;
    address public owner;
    address[] public funders;
    AggregatorV3Interface public pricefeed;
    
    constructor(address _priceFeed) {
        owner = msg.sender;
        pricefeed = AggregatorV3Interface(_priceFeed);
    }
    
    function fund() public payable{
        uint minimumUsd = 50 * (10 ** 8);
        require(getConversionRate(msg.value) >= minimumUsd, "You need to spend more Eth");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns(uint){
        return pricefeed.version();
    }
    
    function getPrice() public view returns(uint){
        (,int256 answer,,,) = pricefeed.latestRoundData();
        return uint(answer);
    }
    

    function getConversionRate(uint ethAmount) public view returns(uint){
        uint ethPrice = getPrice();
        uint ethAmountInUsd = (ethPrice * ethAmount) / 10**8;
        return ethAmountInUsd;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable public onlyOwner{
        // require msg.sender = owner
        payable(msg.sender).transfer(address(this).balance);
        for (uint funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
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