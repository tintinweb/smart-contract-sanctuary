/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Binance Smart Chain
     * Aggregator: BNB/USD
     * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
     */ 
    constructor()  {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    
    function updatePlan() external view returns(uint256){
        uint256 _price = uint256(getLatestPrice());
        _price = 30000000000/_price;
        return _price;
    }
    
    function updatePlan2() external   returns(bool){
        uint256 _price = uint256(getLatestPrice());
        _price = 30000000000/_price;
        payable(address(this)).transfer(_price/10**8);
        return true;
    }
    
    function send() public payable{

        payable(address(this)).transfer(msg.value);

    }
    
    
    function send2(uint256 x) public payable{
        
        payable(address(this)).transfer(x);

    }
    
    
    function xxx(uint i) external payable returns(string memory){
        
        if(i == 1){
            uint256 _price = uint256(getLatestPrice());
            _price = (5000000000*10**8/_price);
            payable(address(this)).transfer(_price);
            return "1";
        }else if(i==2){
             uint256 _price = uint256(getLatestPrice());
            _price = (30000000000*10**8/_price);
            payable(address(this)).transfer(_price);
            return "1";
            return "2";
        }else{
            return "none";
        }
    }
    
    function yyy(uint i) external view returns(uint){
        
        if(i == 1){
            uint256 _price = uint256(getLatestPrice());
            _price = (5000000000*10**8/_price);
            // payable(address(this)).transfer(_price);
            return _price;
        }else if(i==2){
             uint256 _price = uint256(getLatestPrice());
            _price = (30000000000*10**8/_price);
           
            // payable(address(this)).transfer(_price);
            
            return _price;
        }else{
            return 0;
        }
        
        
    }
}