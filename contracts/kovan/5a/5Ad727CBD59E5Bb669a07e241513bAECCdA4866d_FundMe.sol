/**
 *Submitted for verification at Etherscan.io on 2021-10-02
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

contract FundMe{
    
    mapping(address => uint256) public addressToAmountFunding;
    address[] public funders;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function Fund() public payable {
        uint256 minimumUSD = 50 * 10 * 18; //transform 50 dollars into wei
        //require(getConversionRate(msg.value) >= minimumUSD, "50$ is the minimum"); //require will revert the transaction
        addressToAmountFunding[msg.sender] += msg.value; //msg.sender and msg.value are keywords in every transaction
        funders.push(msg.sender);
       }
       
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);//the address is taken from chain.lnik in prices eth to usd
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,
        int256 answer,
        ,
        ,
        ) = priceFeed.latestRoundData();
        
        return uint256(answer); //since the return calue should be uint256
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice()/100000000;
        uint256 ethAmountinUSD = (ethPrice * ethAmount);
       return ethAmountinUSD;
        
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _; // this means run the rest of the code
    }
    
    function withdraw() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance); //this refers to the currrent contract, when used with address it refers to the address of this contract
        for (uint256 i = 0; i < funders.length; i++){
            address funder = funders[i];
            addressToAmountFunding[funder] = 0;
        }
        funders = new address[](0); // clear funders array
    }
}