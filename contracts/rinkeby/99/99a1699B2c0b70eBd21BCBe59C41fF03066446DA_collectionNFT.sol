// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract collectionNFT is ERC1155, Ownable {
    using Strings for uint256;

    address payable public feeReceipient;

    uint256 public marketFee;
    uint256 public collectionItems;
    uint256 public auctionStep = 0.01 ether;
    uint256 public salesOpenTime;
    uint256 public salesCloseTime;

    struct tokenData {
        uint256 maxSupply;
        uint256 currentSupply;
        uint256 price;
        bool isAuction;
    }

    struct Offer {
        address offerer;
        uint256 price;
        bool isAccepted;
    }
    
     // Store all active sell offers  and maps them to their respective token ids
    mapping(uint256 => Offer) public activeOffers;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => tokenData) public tokenIdtoData;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenId_edition_bid;
    mapping(uint256 => mapping(uint256 => address))
        public tokenId_edition_bidder;
    // mapping(uint256 => sellOffers) private _sellToken;
  
    event Purchased(
        uint256 amount,
        uint256 indexed tokenId,
        uint256 pricePaid,
        address indexed buyer,
        uint256 time
    );
    event bidReceived(
        uint256 indexed tokenId,
        uint256 indexed tokenEdition,
        uint256 amount,
        address indexed bidder,
        uint256 time
    );
    event NFTclaimed(uint256 tokenId, address indexed buyer);
    event withdrawFunds(uint256 amount, uint256 timestamp);
    event NewOffer(uint256 indexed tokenId, address indexed offerer, uint256 price);
    event OfferAccepted(uint256 indexed tokenID);
    event OfferReceived(uint256 indexed tokenID, address indexed buyer, uint256 price);

    constructor(
        string[] memory _uris,
        uint256[] memory _prices,
        uint256[] memory _amounts,
        bool[] memory _auction,
        uint256 _marketFee,
        address payable _feeRecipient,
        address payable _creator,
        uint256 _start,
        uint256 _end
    ) ERC1155("") {
        require(_uris.length == _prices.length, "length doesn't match");
        require(_uris.length == _amounts.length, "length doesn't match");
        require(_uris.length == _auction.length, "length doesn't match");

        marketFee = _marketFee;
        feeReceipient = _feeRecipient;
        salesOpenTime = _start;
        salesCloseTime = _end;

        for (uint256 i = 0; i < _uris.length; i++) {
            _setTokenURI(i, _uris[i]);

            tokenIdtoData[i] = tokenData({
                maxSupply: _amounts[i],
                currentSupply: 0,
                price: _prices[i],
                isAuction: _auction[i]
            });

            collectionItems++;
        }
        _transferOwnership(_creator);
    }

    modifier onlySaleClose() {
        require(
            block.timestamp > salesCloseTime,
            "sale needs to be closed first"
        );
        _;
    }

    modifier onlySaleOpen() {
        require(
            salesOpenTime < block.timestamp && block.timestamp < salesCloseTime,
            "sales are not open or already closed"
        );
        _;
    }

    function mint(uint256 _amount, uint256 _tokenId)
        public
        payable
        onlySaleOpen
    {
        tokenData storage token = tokenIdtoData[_tokenId];
        require(token.maxSupply > 0, "token id not valid");
        require(!token.isAuction, "token is not available for direct sale");
        require(
            token.currentSupply + _amount <= token.maxSupply,
            "exceeds max supply"
        );
        require(token.price * _amount <= msg.value, "not enough ETH to buy");
        token.currentSupply = token.currentSupply + _amount;
        _mint(msg.sender, _tokenId, _amount, "");
        emit Purchased(_amount, _tokenId, msg.value, msg.sender, block.timestamp);
    }


    function bid(uint256 _tokenId, uint256 _tokenEdition)
        public
        payable
        onlySaleOpen
    {
        tokenData storage token = tokenIdtoData[_tokenId];
        require(token.maxSupply > 0, "token id not valid");
        require(token.isAuction, "token is not on auction");
        require(
            msg.value >= token.price,
            "bid needs to be bigger than base price"
        );
        require(_tokenEdition <= token.maxSupply, "edition not valid");

        uint256 currentBid = tokenId_edition_bid[_tokenId][_tokenEdition];

        if (currentBid > 0) {
            require(
                msg.value >= currentBid + auctionStep,
                "needs to bid more than current bid + step"
            );
        }

        address previousBidder = tokenId_edition_bidder[_tokenId][
            _tokenEdition
        ];

        tokenId_edition_bid[_tokenId][_tokenEdition] = msg.value;
        tokenId_edition_bidder[_tokenId][_tokenEdition] = msg.sender;

        payable(previousBidder).transfer(currentBid);
        emit bidReceived(_tokenId, _tokenEdition, msg.value, msg.sender, block.timestamp);
    }

    function claimNFT(uint256 _tokenId, uint256 _tokenEdition)
        public
        onlySaleClose
    {
        require(
            tokenId_edition_bidder[_tokenId][_tokenEdition] == msg.sender,
            "you're not the winner of this bid"
        );
        tokenData storage token = tokenIdtoData[_tokenId];

        token.currentSupply = token.currentSupply + 1;

        _mint(msg.sender, _tokenId, 1, "");
        emit NFTclaimed(_tokenId, msg.sender);
    }

    function withdraw() public onlyOwner onlySaleClose {
        uint256 Fee = (address(this).balance * marketFee) / 10000;
        feeReceipient.transfer(Fee);

        emit withdrawFunds(address(this).balance, block.timestamp);
        payable(msg.sender).transfer(address(this).balance);
    }

    function _setTokenURI(uint256 tokenId, string memory tokenUri) internal {
        _tokenURIs[tokenId] = tokenUri;
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");
        return _tokenURIs[tokenId];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < collectionItems;
    }

    function createOffer(uint256 tokenId, uint256 price) public 
    {
        tokenData memory token = tokenIdtoData[tokenId];
        require(!token.isAuction, "token is not available for direct sale");
        require(token.price < price, "not enough ETH to buy");
        // Create sell offer
        activeOffers[tokenId] = Offer({offerer : msg.sender,
                                               price : price, isAccepted: false});
        // Broadcast sell offer
        emit NewOffer(tokenId, msg.sender, price);
    }

    function acceptOffer(uint256 tokenID) public onlyOwner {
        activeOffers[tokenID].isAccepted = true;
        emit OfferAccepted(tokenID);
    }

    function offerRecieve(uint256 tokenID) public payable {
        require(msg.sender == activeOffers[tokenID].offerer,"You are not offerer");
        require(msg.value >= activeOffers[tokenID].price,"Not enough ETH to buy");
        _mint(msg.sender, tokenID, 1, "");
        emit OfferReceived(tokenID, msg.sender, msg.value);
    } 
}