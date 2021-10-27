/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


// 
interface IAddressesProviderMock {
    function setPriceOracle(address priceOracle) external;
}

interface IAgregatorMock {
    function latestAnswer() external view returns(uint128);
}

contract PriceOracleMock {
    IAgregatorMock agregator;
    uint256 price;
    constructor()
    {
        price = 1;
    }
    receive() external payable {
    }
    function kill(address payable beneficiary_)
    external
    {
        selfdestruct(beneficiary_);
    }
    function setPrice(uint256 price_)
    external
    {
        price = price_;
    }
    function getAssetPrice(address _asset)
    external
    view
    returns(uint256)
    {
        return price;
    }
}