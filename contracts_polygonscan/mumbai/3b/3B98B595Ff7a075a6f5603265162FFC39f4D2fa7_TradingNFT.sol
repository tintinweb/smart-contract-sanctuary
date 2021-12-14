// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

import "./test-trc20.sol";
import "./test-nft-721.sol";

contract TradingNFT {
    address private _owner;
    ERC721 private nft;
    Token3 private token;

    mapping(uint256 => Seller) _marketNFTCoin;
    mapping(uint256 => Seller) _marketNFTToken;
    struct Seller {
        address sellerAddress;
        uint256 price;
        address buyerAddress;
    }
    enum PaymentMethod {
        Token,
        Coin
    }

    constructor() public {
        _owner = msg.sender;
        nft = ERC721(0xA5b8feEF7ee7D820A05FB1DAe9cd4b948aD766b3);
        token = Token3(0x04b14Da344CF4D66dD2E4716c94D0a2B5A6e56D6);
    }

    modifier checkPermissionSell(uint256 tokenId) {
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "You do not have the right to sell this NFT."
        );
        _;
    }

    modifier checkOwnerNFT(uint256 tokenId, PaymentMethod paymentMethod) {
        require(
            _checkOwnerNFT(tokenId, paymentMethod),
            "This NFT was not owned by this person"
        );
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier checkOnSale(uint256 tokenId, PaymentMethod paymentMethod) {
        require(
            _checkOnSale(tokenId, paymentMethod),
            "NFT already has a buyer"
        );
        _;
    }

    function _checkOnSale(uint256 tokenId, PaymentMethod paymentMethod)
        private
        view
        returns (bool)
    {
        Seller memory seller;
        if (paymentMethod == PaymentMethod.Coin) {
            seller = _marketNFTCoin[tokenId];
        } else {
            seller = _marketNFTToken[tokenId];
        }
        bool cond = _marketNFTToken[tokenId].buyerAddress == address(0);
        return cond;
    }

    function _checkOwnerNFT(uint256 tokenId, PaymentMethod paymentMethod)
        private
        view
        returns (bool)
    {
        bool condition = false;
        if (paymentMethod == PaymentMethod.Coin) {
            Seller memory seller = _marketNFTCoin[tokenId];
            condition = (seller.sellerAddress == nft.ownerOf(tokenId));
        } else {
            Seller memory seller = _marketNFTToken[tokenId];
            condition = (seller.sellerAddress == nft.ownerOf(tokenId));
        }
        return condition;
    }

    function postNFTByCoin(uint256 tokenId, uint256 price)
        public
        checkPermissionSell(tokenId)
        returns (bool)
    {
        _marketNFTCoin[tokenId] = Seller(msg.sender, price, address(0));
        nft.transferFrom(msg.sender, address(this), tokenId);
        return true;
    }

    function buyNFTByCoin(uint256 tokenId)
        public
        checkOnSale(tokenId, PaymentMethod.Coin)
        returns (bool)
    {
        Seller memory seller = _marketNFTToken[tokenId];
        require(seller.sellerAddress != msg.sender, "Can not buy yourself!");
        nft.transferFrom(address(this), msg.sender, tokenId);
        payable(msg.sender).transfer(seller.price);

        // _marketNFTToken[tokenId].buyerAddress = msg.sender;
        delete _marketNFTToken[tokenId];
        return true;
    }

    function postNFTByToken(uint256 tokenId, uint256 price)
        public
        checkPermissionSell(tokenId)
        returns (bool)
    {
        _marketNFTToken[tokenId] = Seller(msg.sender, price, address(0));
        nft.transferFrom(msg.sender, address(this), tokenId);
        return true;
    }

    function buyNFTByToken(uint256 tokenId)
        public
        checkOwnerNFT(tokenId, PaymentMethod.Token)
        checkOnSale(tokenId, PaymentMethod.Token)
        returns (bool)
    {
        Seller memory seller = _marketNFTToken[tokenId];

        token.approve(_owner, seller.price);
        _marketNFTToken[tokenId].buyerAddress = msg.sender;

        delete _marketNFTCoin[tokenId];
        return true;
    }

    function confirmExchangePurchase(
        uint256 tokenId,
        PaymentMethod paymentMethod
    )
        public
        payable
        onlyOwner
        checkOwnerNFT(tokenId, paymentMethod)
        returns (bool)
    {
        require(
            !_checkOnSale(tokenId, paymentMethod),
            "NFT has not been purchased by anyone."
        );
        if (paymentMethod == PaymentMethod.Token) {
            Seller memory seller = _marketNFTToken[tokenId];
            nft.transferFrom(
                seller.sellerAddress,
                seller.buyerAddress,
                tokenId
            );
            token.transferFrom(
                seller.buyerAddress,
                seller.sellerAddress,
                seller.price
            );
        } else {
            Seller memory seller = _marketNFTToken[tokenId];
            nft.transferFrom(
                seller.sellerAddress,
                seller.buyerAddress,
                tokenId
            );
        }

        delete _marketNFTCoin[tokenId];
        delete _marketNFTCoin[tokenId];
        return true;
    }

    function priceNFTCoin(uint256 tokenId) public view returns (Seller memory) {
        if (_checkOwnerNFT(tokenId, PaymentMethod.Coin))
            return _marketNFTCoin[tokenId];
        Seller memory empty;
        return empty;
    }

    function priceNFTToken(uint256 tokenId)
        public
        view
        returns (Seller memory)
    {
        if (_checkOwnerNFT(tokenId, PaymentMethod.Coin))
            return _marketNFTToken[tokenId];
        Seller memory empty;
        return empty;
    }
}