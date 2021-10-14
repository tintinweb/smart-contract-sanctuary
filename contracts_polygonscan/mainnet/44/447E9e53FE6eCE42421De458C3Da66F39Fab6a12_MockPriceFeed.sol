/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

pragma solidity ^0.5.16;

contract MockPriceFeed {

    uint price = 361793562602;
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
}