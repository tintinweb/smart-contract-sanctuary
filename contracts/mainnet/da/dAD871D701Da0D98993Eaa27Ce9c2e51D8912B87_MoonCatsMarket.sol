/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: IMoonCats

// import "../../../../interfaces/markets/tokens/IERC721.sol";

interface IMoonCats {

    struct AdoptionOffer {
        bool exists;
        bytes5 catId;
        address seller;
        uint price;
        address onlyOfferTo;
    }

    /* accepts an adoption offer  */
    function acceptAdoptionOffer(bytes5 catId) payable external;

    /* transfer a cat directly without payment */
    function giveCat(bytes5 catId, address to) external;

    function adoptionOffers(bytes5 catId) external view returns(AdoptionOffer memory offer);
}

// File: MoonCatsMarket.sol

library MoonCatsMarket {

    address public constant MOONCATSRESCUE = 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;
    //address public MOONCATSWRAPPED = 0x7C40c393DC0f283F318791d746d894DdD3693572;

    function buyAssetsForEth(bytes memory data, address recipient) public {
        bytes5[] memory tokenIds;
        (tokenIds) = abi.decode(
            data,
            (bytes5[])
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _buyAssetForEth(tokenIds[i], estimateAssetPriceInEth(tokenIds[i]), recipient);
        }
    }

    function estimateAssetPriceInEth(bytes5 tokenId) public view returns(uint256) {
        return IMoonCats(MOONCATSRESCUE).adoptionOffers(tokenId).price;
    }

    function estimateBatchAssetPriceInEth(bytes memory data) public view returns(uint256 totalCost) {
        bytes5[] memory tokenIds;
        (tokenIds) = abi.decode(
            data,
            (bytes5[])
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalCost += IMoonCats(MOONCATSRESCUE).adoptionOffers(tokenIds[0]).price;
        }
    }

    function _buyAssetForEth(bytes5 _tokenId, uint256 _price, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(IMoonCats(MOONCATSRESCUE).acceptAdoptionOffer.selector, _tokenId);

        (bool success, ) = MOONCATSRESCUE.call{value:_price}(_data);
        require(success, "_buyAssetForEth: moonCats buy failed.");

        IMoonCats(MOONCATSRESCUE).giveCat(_tokenId, _recipient);
    }
}