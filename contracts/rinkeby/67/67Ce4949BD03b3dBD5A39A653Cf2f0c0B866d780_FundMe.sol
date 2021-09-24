/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: AggregatorV3Interface

// import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

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

    
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] funders;
    
    constructor() {
        owner = msg.sender;
    }
    
    function fund() public payable{
        uint256 minUsd = 50 * 10**18;
        require(getConversionRate(msg.value) >= minUsd, "You need to spend more ETH!!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //address of ETH/USD data feed on rinkeby testnet
        return priceFeed.version();
    }
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int256 answer,,,) = priceFeed.latestRoundData();
    return uint256(answer * 10000000000);
    }
    
     function getConversionRate(uint256 ethAmount) public view returns(uint256){
         uint256 ethPrice = getPrice();
         uint256 ethAmountInUsd = (ethPrice*ethAmount)/(10**18);
         return ethAmountInUsd;
     }
     
     modifier onlyOwner {
         require(msg.sender == owner, "You are not the owner");
         _;
     }
     
     function withdraw() public payable onlyOwner{
        address payable senderAddress = payable(msg.sender);
        senderAddress.transfer(address(this).balance);
        for(uint256 funderIndex; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
            funders = new address[](0);
        }
     }
}