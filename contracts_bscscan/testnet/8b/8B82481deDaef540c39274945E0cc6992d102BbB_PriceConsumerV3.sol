// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;
    mapping(address=>int256) contracts;
    mapping(address=>int256) entryPrice;
    mapping(address=>uint256) entryBlock;
    /**
     * Returns the latest price
     */
     constructor() {
        priceFeed = AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C);
    }
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }

  /*  function getADAPrice() public view returns (int){
       return getLatestPrice(0x5e66a1775BbC249b5D51C13d29245522582E671C);
    }*/

/*   function getETHPrice() public view returns (int){
       return getLatestPrice(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);
    }
    
    function getCAKEPrice() public view returns (int){
       return getLatestPrice(0x81faeDDfeBc2F8Ac524327d70Cf913001732224C);
    }
    
    function getMATICPrice() public view returns (int){
       return getLatestPrice(0x957Eb0316f02ba4a9De3D308742eefd44a3c1719);
    }
                
function getBNBPrice() public view returns (int){
       return getLatestPrice(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }*/
    
    function buyBTCContract(int256 amount) public {
        int currentPrice=getLatestPrice();
        entryBlock[msg.sender]=block.number;
        entryPrice[msg.sender]=currentPrice;
        contracts[msg.sender]=amount;
        //1 contract 10 usd
    }
    
    function checkProfit(uint256)public view returns (uint256){
        return ((uint256((10*contracts[msg.sender])*1000000000000000000))/uint256((entryPrice[msg.sender]*1000000000000000000)))*uint256(getLatestPrice());
    }
    
}