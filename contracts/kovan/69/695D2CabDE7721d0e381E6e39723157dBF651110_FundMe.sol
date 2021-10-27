// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";


contract FundMe {
    
    mapping(address => uint256) public addressFunded; 
    
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    
    function fund(uint256) payable public {
        //be sure we receive $50
        uint256 minimumUSD = 50 * 10**18; 
        require(getConversionRate(msg.value) >= minimumUSD, "You need to Deposit more ETH.");
        addressFunded[msg.sender] += msg.value;
    }
    
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int256 answer,,,) =  priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }
     
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethPriceDollar = (ethPrice * ethAmount) / 1000000000000000000;
        return ethPriceDollar;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
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