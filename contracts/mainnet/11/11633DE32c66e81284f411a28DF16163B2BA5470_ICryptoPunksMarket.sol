// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

interface ICryptoPunksMarket {
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(
        address indexed from,
        address indexed to,
        uint256 punkIndex
    );
    event PunkOffered(
        uint256 indexed punkIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event PunkBidEntered(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBidWithdrawn(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBought(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    function setInitialOwner(address to, uint256 punkIndex) external;

    function setInitialOwners(
        address[] calldata addresses,
        uint256[] calldata indices
    ) external;

    function allInitialOwnersAssigned() external;

    function getPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;

    function punkNoLongerForSale(uint256 punkIndex) external;

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei)
        external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external;

    function withdraw() external;

    function enterBidForPunk(uint256 punkIndex) external;

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

    function withdrawBidForPunk(uint256 punkIndex) external;

    function punkIndexToAddress(uint256 punkIndex) external returns (address);
    function punksOfferedForSale(uint256 punkIndex)
        external
        returns (
            bool isForSale,
            uint256 _punkIndex,
            address seller,
            uint256 minValue,
            address onlySellTo
        );

    function balanceOf(address user) external returns (uint256);
}
