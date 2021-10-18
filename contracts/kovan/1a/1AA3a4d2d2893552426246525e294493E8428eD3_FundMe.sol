//SPDX-License-Identifier:MIT

pragma solidity >=0.8;

import "AggregatorV3Interface.sol";


contract FundMe
{   
    mapping(address=>uint256) public transdic;
    uint256 public totalfund=0;
    address public owner;
    address[] public funders;
    
    
    constructor() 
    {
        owner=msg.sender;
    }
    
    
    
     function fund () public payable
    {uint256 minimumUSD = 50 * 10 ** 18;
        require(GWeiUsdValue(msg.value) >= minimumUSD, "You need to spend more ETH!");
        
        transdic[msg.sender]+=msg.value;
       funders.push(msg.sender);
        totalfund+=msg.value;
        
    }
    
    
    function getVersion() public view returns(uint256)
    {
        AggregatorV3Interface pricefeed=AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return pricefeed.version();
    }
    
    
    function getPrice() public view returns(uint256)
    {
        AggregatorV3Interface priceFeed=AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
 (
            , 
            int price,
            ,
            ,
           
        ) = priceFeed.latestRoundData();
        return uint256(price*10**10) ;
      
    }
    
        function des() public view returns(uint256)
    {
        AggregatorV3Interface priceFeed=AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
         return uint256(priceFeed.decimals()) ;
      
    }
    
    function GWeiUsdValue(uint256  _eth) public view returns(uint256)
    {
        uint256 ethprice=getPrice();
        uint256 ethvalue=(ethprice*_eth) / 1000000000;
        return ethvalue;
    }
    
    
      
    modifier onlyOwner
    {
        require(owner==msg.sender);
        _;

    }
    
    function withdraw()  public payable {
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 i =0;i<funders.length;i++)
        {
            transdic[funders[i]]=0;
            
        }
        funders=new address[](0);
        totalfund=0;
        
        
 
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