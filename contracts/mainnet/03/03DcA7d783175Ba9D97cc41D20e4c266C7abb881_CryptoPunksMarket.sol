/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: ICryptoPunks

interface ICryptoPunks {

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    function buyPunk(uint punkIndex) external payable;

    function punksOfferedForSale(uint punkIndex) external view returns(Offer memory offer);

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) external;
}

// File: CryptoPunksMarket.sol

library CryptoPunksMarket {


    address public constant CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    function buyAssetsForEth(bytes memory data, address recipient) public {
        uint256[] memory punkIndexes;
        (punkIndexes) = abi.decode(
            data,
            (uint256[])
        );
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            _buyAssetForEth(punkIndexes[i], estimateAssetPriceInEth(punkIndexes[i]), recipient);
        }
    }

    function estimateAssetPriceInEth(uint256 punkIndex) public view returns(uint256) {
        return ICryptoPunks(CRYPTOPUNKS).punksOfferedForSale(punkIndex).minValue;
    }

    function estimateBatchAssetPriceInEth(bytes memory data) public view returns(uint256 totalCost) {
        uint256[] memory punkIndexes;
        (punkIndexes) = abi.decode(
            data,
            (uint256[])
        );
        ICryptoPunks.Offer memory offer;
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            offer = ICryptoPunks(CRYPTOPUNKS).punksOfferedForSale(punkIndexes[i]);
            if(offer.isForSale) {
                totalCost += offer.minValue;
            }
        }
    }

    function _buyAssetForEth(uint256 _index, uint256 _price, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(ICryptoPunks(CRYPTOPUNKS).buyPunk.selector, _index);

        (bool success, ) = CRYPTOPUNKS.call{value:_price}(_data);
        require(success, "_buyAssetForEth: cryptopunk buy failed.");

        ICryptoPunks(CRYPTOPUNKS).transferPunk(_recipient, _index);
    }
}