// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe{
    
    mapping (address => uint256) public addressToAmmountFunded;
    AggregatorV3Interface internal priceFeed;
    address[] public funders;
    
    function fund() public payable returns (uint256){

        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value)>= minimumUSD, "You need to spend at least 5USD");
        addressToAmmountFunded[msg.sender]+= msg.value;
        funders.push(msg.sender);
        return addressToAmmountFunded[msg.sender];
    }
    
    receive() payable external {
        addressToAmmountFunded[msg.sender]+= msg.value;
    }
    
    fallback() payable external {
        addressToAmmountFunded[msg.sender]+= msg.value;
    }
    
    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    address public owner;
    constructor() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        owner = msg.sender;
    }
    
    function getVersion() public view returns (uint256){
        return priceFeed.version();
    }


    function getPriceOfEthInUSD() public view returns (uint256){
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 10000000000); 
    }
    
    function getConversionRate(uint256 gweiAmmount) public view returns (uint256){
        uint256 ethPriceInUSD = getPriceOfEthInUSD();
        //uint8 decimals = priceFeed.decimals();
        uint256 gweiAmmountInUSD = (ethPriceInUSD * gweiAmmount) / 1000000000000000000;
        return gweiAmmountInUSD;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner of this contract can withdraw the funds");
        _;
    }
    
    
    function withdraw() payable onlyOwner public{   
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 i=0;i < funders.length ; i++){
            addressToAmmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
    
    function getBalance() public view returns (uint256){
        return address(this).balance;
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