/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

pragma solidity ^0.5.16;

contract MockPriceFeed {

    uint price = 4800000000000000000000;
    uint8 decimal = 8;

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