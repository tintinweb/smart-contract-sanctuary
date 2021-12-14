//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe{


    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor (address _priceFeed) public{
        priceFeed = AggregatorV3Interface(_priceFeed);
        //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e Rinkeby address
        owner = msg.sender;
    }
    
    function fund() public payable{
        uint256 minUSD = 50 * 10**18;
        require(getConversionRate(msg.value) >= minUSD, "Send more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        //eth to usd conversion rate?
    }

    function getVersion() public view returns(uint256){
        //AggregatorV3Interface priceFeed = 
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        (,int256 answer,,,)= priceFeed.latestRoundData();
        return uint256(answer * 10000000000); //multiply to have 18 decimal places
    }


    function getConversionRate(uint256 _ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethInUsd = (ethPrice * _ethAmount) / 1000000000000000000;
        return ethInUsd;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex<funders.length; funderIndex++){
            addressToAmountFunded[funders[funderIndex]] = 0;
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