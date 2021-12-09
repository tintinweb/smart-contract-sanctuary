// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract Sale {
    IERC721 private _token;

    event PurchaseTicket(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId
    );
    event CreateTicketSale(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event CancelTicketSale(address indexed seller, uint256 indexed tokenId);
    event UpdateTicketSale(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    // Map from token ID to their corresponding auction.
    mapping(uint256 => uint256) tokenIdToSale;

    constructor(IERC721 token) {
        _token = token;
    }

    modifier onlyTicketOwner(uint256 _tokenId) {
        require(_token.ownerOf(_tokenId) == msg.sender);
        _;
    }

    function _addSale(uint256 _tokenId, uint256 _price) internal {
        tokenIdToSale[_tokenId] = _price;
    }

    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    function fetchSaleData(uint256 _tokenId)
        external
        view
        returns (uint256 sellingPrice)
    {
        return tokenIdToSale[_tokenId];
    }

    function createSale(uint256 _tokenId, uint256 _price)
        external
        onlyTicketOwner(_tokenId)
    {
        _addSale(_tokenId, _price);
        emit CreateTicketSale(msg.sender, _tokenId, _price);
    }

    function cancelSale(uint256 _tokenId) external onlyTicketOwner(_tokenId) {
        _removeSale(_tokenId);
        emit CancelTicketSale(msg.sender, _tokenId);
    }

    function setTokenPrice(uint256 _tokenId, uint256 _price)
        external
        onlyTicketOwner(_tokenId)
    {
        _addSale(_tokenId, _price);
        emit UpdateTicketSale(msg.sender, _tokenId, _price);
    }

    function purchaseToken(uint256 _tokenId) external payable {
        // Get a reference to the sale struct
        uint256 sellingPrice = tokenIdToSale[_tokenId];

        address payable _sellerWallet = payable(_token.ownerOf(_tokenId));
        address payable _buyerWallet = payable(msg.sender);

        //check for price
        require(msg.value >= sellingPrice);

        //transfer token
        /**
         safeTransferFrom will safely transfer a NFT from sender to the receiver
         if receiver address is smart contract or wallet then it should be compatible with ERC 721 standard otherwise transaction will be reverted
         */
        _token.safeTransferFrom(_sellerWallet, msg.sender, _tokenId);

        emit PurchaseTicket(_sellerWallet, msg.sender, _tokenId);

        //amt to seller
        uint256 amtToSeller = sellingPrice;

        require(amtToSeller >= 0);

        if (amtToSeller > 0) {
            _sellerWallet.transfer(amtToSeller);
        }

        //check if excess is present then transfer back
        uint256 excess = msg.value - sellingPrice;
        if (excess > 0) {
            _buyerWallet.transfer(excess);
        }

        //remove from sale
        _removeSale(_tokenId);
    }
}