/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity 0.6.10;

interface Oracle{
    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
}

contract NovaPricer {
    uint256  private price;
    mapping(uint80=>HP) historicalPrice;
    Oracle private oracle;
    
    constructor(address _oracle) public{
        oracle = Oracle(_oracle);
    }
    
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
    
    function setPrice(uint80 _roundId,address _asset,uint256 _time,uint256 _price) public{
         price = _price;
         HP memory hp = HP(_time,_price);
         historicalPrice[_roundId] = hp;
         oracle.setExpiryPrice(_asset,_time,_price);
    }
}