/**
 *Submitted for verification at polygonscan.com on 2021-10-22
*/

pragma solidity ^0.5.16;

contract MockPriceFeed {

    uint price = 1500000000000000000;
    uint8 decimal = 18;

    function decimals() external view returns (uint8){
        return(decimal);
    }

    function latestAnswer() external view returns (uint){
        return(price);
    }

    function setPrice(uint _price) external{
        price = _price;
    }

    function setDecimals(uint8 _decimal) external{
        decimal = _decimal;
    }
}