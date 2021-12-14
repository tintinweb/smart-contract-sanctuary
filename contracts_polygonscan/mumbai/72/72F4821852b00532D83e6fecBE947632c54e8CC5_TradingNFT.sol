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
            nft.ownerOf(tokenId) == msg.sender ||
                nft.ownerOf(tokenId) == address(this),
            "You do not have the right to sell this NFT."
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

    function postNFTByCoin(uint256 tokenId, uint256 price)
        public
        checkPermissionSell(tokenId)
        returns (bool)
    {
        _marketNFTCoin[tokenId] = Seller(msg.sender, price, address(0));
        nft.approve(_owner, tokenId);
        return true;
    }

    function buyNFTByCoin(uint256 tokenId)
        public
        checkOnSale(tokenId, PaymentMethod.Coin)
        returns (bool)
    {
        Seller memory seller = _marketNFTToken[tokenId];
        require(seller.sellerAddress != msg.sender, "Can not buy yourself!");
        payable(msg.sender).transfer(seller.price);
        nft.transferFrom(seller.sellerAddress, msg.sender, tokenId);

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
        checkOnSale(tokenId, PaymentMethod.Token)
        returns (bool)
    {
        Seller memory seller = _marketNFTToken[tokenId];
        require(seller.sellerAddress != msg.sender, "Can not buy yourself!");

        require(
            token.transferFrom(msg.sender, seller.sellerAddress, seller.price),
            "Transfer fail"
        );
        nft.transferFrom(address(this), msg.sender, tokenId);

        delete _marketNFTToken[tokenId];
        delete _marketNFTCoin[tokenId];
        return true;
    }

    function priceNFTCoin(uint256 tokenId) public view returns (Seller memory) {
        return _marketNFTCoin[tokenId];
    }

    function priceNFTToken(uint256 tokenId)
        public
        view
        returns (Seller memory)
    {
        return _marketNFTToken[tokenId];
    }

    function cancelNFTCoin(uint256 tokenId) public returns (bool) {
        require(
            nft.ownerOf(tokenId) == address(this),
            "this nft is not for sale"
        );
        Seller memory sellerCoin = _marketNFTCoin[tokenId];
        Seller memory sellerToken = _marketNFTToken[tokenId];

        if (sellerToken.sellerAddress == address(0)) {
            nft.transferFrom(address(this), sellerCoin.sellerAddress, tokenId);
        }

        delete _marketNFTCoin[tokenId];
        return true;
    }

    function cancelNFTToken(uint256 tokenId) public returns (bool) {
        require(
            nft.ownerOf(tokenId) == address(this),
            "this nft is not for sale"
        );
        Seller memory sellerCoin = _marketNFTCoin[tokenId];
        Seller memory sellerToken = _marketNFTToken[tokenId];

        if (sellerCoin.sellerAddress == address(0)) {
            nft.transferFrom(address(this), sellerToken.sellerAddress, tokenId);
        }

        delete _marketNFTToken[tokenId];
        return true;
    }
}