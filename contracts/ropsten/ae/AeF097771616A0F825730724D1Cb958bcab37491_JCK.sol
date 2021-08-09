/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.8.6;

contract JCK {
    uint256 public _price;
    
    constructor()
    {
        _price = 1000;
    }
    
    event SetTokenPrice(uint256 price);
    
    function setTokenPrice(uint256 price) public
    {
        _price = price;
        emit SetTokenPrice(price);
    }
    
    function price() public view returns(uint256)
    {
        return _price;
    }
}