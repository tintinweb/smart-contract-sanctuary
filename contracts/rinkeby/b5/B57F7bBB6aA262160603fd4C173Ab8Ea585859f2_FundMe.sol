/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;


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

contract FundMe {

    mapping (address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    constructor()  {
      owner = msg.sender; 
    }
    
    
    function fund() public payable {
        
        uint256 minimumUsd = 50 * 10 ** 18;
        //require will revert the transaction if it resolves to false
        //Enforcing a minimum deposit of 50USD using chainlink conversion
        require(getConversionRate(msg.value) >= minimumUsd, "Does not meet minimum requred value");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    } 

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * (10*10**10));
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10*10**18);
        return ethAmountInUsd;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }
    function withdrawl() payable onlyOwner public {
      // require that the sender is the owner
      payable(msg.sender).transfer(payable(address(this)).balance);
      //reset funders array balances
      for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex ++){
        address funder = funders[funderIndex];
        addressToAmountFunded[funder] = 0;
      }
      funders = new address[](0);
    }
}