// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IMSSpaceToken.sol";
import "./IMSNft.sol";
import "./IMSExchangeData.sol";

contract MSExchange  {
    IMSSpaceToken private msSpaceToken;
    IMSNft private msBlindBoxNft;
    IMSNft private msGemoNft;
    IMSExchangeData private msExchangeData;

    constructor( 
        address _IMSSpaceToken,
        address _IMSBlindBoxNft,
        address _IMSGemoNft,
        address _IExchangeData
        ) {
        msSpaceToken    = IMSSpaceToken(_IMSSpaceToken);
        msBlindBoxNft   = IMSNft(_IMSBlindBoxNft);
        msGemoNft       = IMSNft(_IMSGemoNft);
        msExchangeData  = IMSExchangeData(_IExchangeData);
    }

    event ev_nftForSell(
        uint8 nftType,
        uint256 indexed nftID,
        uint256 indexed sellPrice,
        address indexed owner
    );

    event ev_NftForSoldOut(
        uint8 indexed nftType,
        uint256 indexed nftID,
        address indexed owner
    );

    event ev_buyNft(
        uint8  nftType,
        uint256 indexed nftID,
        uint256  sellPrice,
        address indexed seller,
        address indexed buyer,
        uint256 sellerbalance,
        uint256 buyerbalance,
        uint256 sellerbalanceofnft,
        uint256 buyerbalanceofnft
    );
    
    event ev_openPreSellBlindBox(
        uint256 indexed itemId,
        address indexed Address
    );

    function NftForSell(uint8 nftType,uint256 nftID, uint256 sellPrice) external{
        IMSNft msNft = nftType == 1? msGemoNft : msBlindBoxNft;
        uint256 minPrice = nftType == 1? msExchangeData.GetMinGemoSellPrice() : msExchangeData.GetMinBlindBoxSellPrice();
        uint256 maxPrice = nftType == 1? msExchangeData.GetMaxGemoSellPrice() : msExchangeData.GetMaxBlindBoxSellPrice();

        require(msNft.msGetOwner(nftID) == msg.sender, "You don't own this .");
        require(msExchangeData.hasGoods(nftType, nftID) == false, "this goods already for sell");        
        require(msNft.msIsApprovedForAll(msg.sender, address(this)), "Approve this goods first.");
        require(sellPrice >= minPrice, "Price reaches the lower limit.");
        require(sellPrice <= maxPrice, "Price reaches the upper limit.");

        msExchangeData.NftForSell(nftType, nftID,  sellPrice, msg.sender);
        emit ev_nftForSell( nftType,
                         nftID, 
                         sellPrice, 
                         msg.sender);
    }

    function NftForSoldOut(uint8 nftType,uint256 nftID) external{
        IMSNft msNft = nftType == 1? msGemoNft : msBlindBoxNft;

        require(msNft.msGetOwner(nftID) == msg.sender, "You don't own this goods.");

        msExchangeData.NftForSoldOut(nftType, nftID);
        emit ev_NftForSoldOut(nftType, nftID,
                            msg.sender);
    }

    function buyNft(uint8 nftType,uint256 nftID) payable external {
        IMSNft msNft = nftType == 1? msGemoNft : msBlindBoxNft;
        (uint256 sellPrice,  uint8 _nftType, bool isVaild, address seller) = msExchangeData.GetNftGoodsContent(nftType, nftID);

        require(isVaild, "This goods not actually for sale.");
        require(msg.sender != msNft.msGetOwner(nftID), "You can't buy yours goods.");
        require(seller == msNft.msGetOwner(nftID), "Seller no longer owner of this item.");

        //Don't take a cut for now,take cut In the future 
        uint256 retNftID = nftID;
        if(seller == msNft.msGetOwner(nftID))
        {
            payable(seller).transfer(sellPrice);
            msNft.msTransferFrom(seller, msg.sender, nftID);            
        }
        else
            retNftID = 0;

        msExchangeData.buyNftFinish(_nftType, nftID);
        emit ev_buyNft(_nftType, retNftID, sellPrice, seller, msg.sender,
                msSpaceToken.msGetBalanceOf(seller),
                msSpaceToken.msGetBalanceOf(msg.sender),
                msNft.msGetBalanceOf(seller),
                msNft.msGetBalanceOf(msg.sender));
    }

    function openPreSellBlindBox() payable external {
        require(msg.sender.balance > msExchangeData.getpreSellBlindBoxPrice(), "Your balance is not enough");
        
        address recipient = msExchangeData.getVaultAddress();
        payable(recipient).transfer(msExchangeData.getpreSellBlindBoxPrice());
        uint256 nftID = msGemoNft.msMint(msg.sender);
        
        emit ev_openPreSellBlindBox(nftID, msg.sender);
    }
}