pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract RarebuFixedPriceSale is Ownable {
    using SafeMath for uint256;

    event NFTSold(address indexed buyer, uint256 price);
    event NFTRemovedFromSale(address indexed owner);
    event NFTSalePriceChanged(address indexed seller, uint256 oldPrice, uint256 newPrice);
    event NFTAddedForSale(address indexed seller, uint256 price);

    uint256 public fixedPriceCommissionBP;
    uint256 public maxPriceForSale;
    uint256 public minPriceForSale;

    struct SaleData {         
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        address owner; 
    }

    SaleData[] public saleInfo;
    mapping(address => mapping(uint256 => SaleData)) public saleMapping;

    // []SaleData public saleDataArray;
    constructor(
    ) {
    }

    function putNFTOnSale(address tokenAddress, uint256 tokenId, uint256 price) public returns(SaleData memory) {
        IERC721 token = IERC721(tokenAddress);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        require(isApproved == true, "Token is not approved.");
        address owner = token.ownerOf(tokenId);
        require(owner == msg.sender, "You are not the token owner.");
        require(minPriceForSale <= price, "Token sale price is lower than minimum.");
        require(maxPriceForSale >= price, "Token sale price is higher than maximum.");
        SaleData memory nftSale = SaleData({
            tokenAddress : tokenAddress,
            tokenId : tokenId,
            price : price,
            owner : msg.sender
        });
        //saleInfo.push(nftSale);
        saleMapping[tokenAddress][tokenId] = nftSale;
        emit NFTAddedForSale(msg.sender,price);
        return nftSale;
    }

    function changeNFTSalePrice(address tokenAddress, uint256 tokenId, uint256 newPrice) public returns(SaleData memory) {
        SaleData memory nftSaleData = saleMapping[tokenAddress][tokenId];
        require(nftSaleData.owner == msg.sender,"You are not the token owner");
        require(minPriceForSale <= newPrice, "Token sale price is lower than minimum.");
        require(maxPriceForSale >= newPrice, "Token sale price is higher than maximum.");
        uint256 oldPrice = nftSaleData.price;
        SaleData memory newSaleData = SaleData({
            tokenAddress : tokenAddress,
            tokenId : tokenId,
            price : newPrice,
            owner : msg.sender
        });
        saleMapping[tokenAddress][tokenId] = newSaleData;
        emit NFTSalePriceChanged(msg.sender,oldPrice,newPrice);
        return newSaleData;
    }

    function buyNFTFromSale(address tokenAddress, uint256 tokenId) public payable {
        uint256 amountPaid = msg.value;
        SaleData memory nftSaleData = saleMapping[tokenAddress][tokenId];
        require(nftSaleData.price == amountPaid ,"You paid wrong amount");
        IERC721 nftToken = IERC721(nftSaleData.tokenAddress);
        delete saleMapping[tokenAddress][tokenId];
        nftToken.safeTransferFrom(nftSaleData.owner, msg.sender, nftSaleData.tokenId);
        emit NFTSold(msg.sender, amountPaid);
    }

    function removeNFTFromSale(address tokenAddress, uint256 tokenId) public {
        SaleData memory nftSaleData = saleMapping[tokenAddress][tokenId];
        require(nftSaleData.owner == msg.sender,"You are not the owner");
        delete saleMapping[tokenAddress][tokenId];
        emit NFTRemovedFromSale(msg.sender);
    }

}