/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract ETHPrice {
    address private owner;
    uint256 usdPerOneEth;
    
    modifier ownerOnly() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor(uint256 originUsdPrice) {
        owner = msg.sender;
        usdPerOneEth = originUsdPrice;
    }
    
    function setETHPrice(uint256 usdPrice) public ownerOnly {
        usdPerOneEth = usdPrice;
    }
    
    function getETHPrice() public view returns (uint256 usdPrice) {
        usdPrice = usdPerOneEth;
    }
}