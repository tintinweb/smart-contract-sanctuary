/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity 0.6.10;

contract NovaPricer {
    uint256  private price;
    mapping(uint80=>HP) historicalPrice;
    
    struct HP{
        uint256 time;
        uint256 price;
    }
    
    function getPrice() external  view returns (uint256) {
        return price;
    }

    function getHistoricalPrice(uint80 _roundId) external  view returns (uint256, uint256) {
        HP memory hp = historicalPrice[_roundId];
        return  (hp.price, hp.time);
    }
    
    function setPrice(uint80 _roundId,uint256 _price) public{
         price = _price;
         HP memory hp = HP(now,_price);
         historicalPrice[_roundId] = hp;
    }
   
}