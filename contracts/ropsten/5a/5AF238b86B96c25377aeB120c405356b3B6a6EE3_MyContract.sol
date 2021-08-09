/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.8.5;

contract MyContract {
    address owner;
    uint256 tokenPrice;
    constructor () {
        owner = msg.sender;
    }
    function setTokenprice(uint256 price) public {
        tokenPrice = price;
    }
    function getTokenprice() public view returns (uint256) {
        return tokenPrice;
    }
}