/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOracle {
    function getPrice(string memory token) external returns(uint256,uint256 );
}

interface IBandOracle {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }
    function decimals() external view returns (uint8);

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string calldata _base, string calldata _quote)
    external
    view
    returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] calldata _bases, string[] calldata _quotes)
    external
    view
    returns (ReferenceData[] memory);
}



contract BandOracle is IOracle {
    IBandOracle public bandOracle;

    //0xDA7a001b254CD22e46d3eAB04d937489c93174C3
    constructor(address _bandOracle)  {
        bandOracle = IBandOracle (_bandOracle);
    }

    function getPrice(string memory token) public view override  returns(uint256  price,uint256 lastUpdate ){
        IBandOracle.ReferenceData memory  ref= bandOracle.getReferenceData(token,"USDT");
        price = ref.rate;
        lastUpdate =ref.lastUpdatedBase;
    }

}