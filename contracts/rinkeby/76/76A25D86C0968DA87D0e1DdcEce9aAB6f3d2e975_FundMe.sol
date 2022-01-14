/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {

    mapping(address => uint256) public addressToAmoundFunded;
    address public owner;
    address[] funders;

    constructor() public {
        owner = msg.sender;
    }


    function fund() public payable {

        uint256 minUSD = 50 * 10 **18;
        require( getConversionRate(msg.value) >= minUSD, "Need to spend more eth");
        
        addressToAmoundFunded[msg.sender] += msg.value;

        funders.push(msg.sender);



    }

    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x2431452A0010a43878bF198e170F6319Af6d27F4);
        
        return priceFeed.version();

    }

    function getPrice() public view returns(uint256){

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x2431452A0010a43878bF198e170F6319Af6d27F4);

        (
            uint80 roundID,
            int256 answer,
            uint256 startAt,
            uint256 updateAt,
            uint80 answeredRound ) = priceFeed.latestRoundData();

            return startAt;

    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){

        uint256 ethPrice = getPrice();
        uint256 ethPriceInUSD = (ethPrice * ethAmount);

        return ethPriceInUSD;
    }


    modifier onlyOwner {
        require( msg.sender == owner);
        _;
    }
    function widthdraw() payable onlyOwner public {

        msg.sender.transfer(address(this).balance);
        for( uint256 i = 0; i < funders.length; i++)
        {
            address funder = funders[i];
            addressToAmoundFunded[funder] = 0;
        }
    
    }
}