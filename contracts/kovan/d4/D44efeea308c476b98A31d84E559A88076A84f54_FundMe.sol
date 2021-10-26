// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

// contract to accept some form of payment
contract FundMe {
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function fund() payable public {
        // $1 dollar
        uint256 minUSD = 3 * 10 ** 18; // dealing in gwei
        
        require(getConversionRate(msg.value) >= minUSD, "you need to spend more eth");
        
        addressToAmountFunded[msg.sender] += msg.value; // sender, value keywords in a transaction
        // ETH -> USD conversion rate
        funders.push(msg.sender);
        
    }
    
    //getLatestPrice e.g. 415214540024 , 12 digit number
    // 4152.14540024 x 10^8
    
    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        
        return uint256(answer * 10000000000);
    }
    
    // 1000000000 = 1 gwei
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // 4152145400240.000000000000000000
        return ethAmountInUsd;
        // 0.000004152145400240

    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 fundersidx=0; fundersidx < funders.length; fundersidx++){
            address funder = funders[fundersidx];
            addressToAmountFunded[funder] = 0;
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