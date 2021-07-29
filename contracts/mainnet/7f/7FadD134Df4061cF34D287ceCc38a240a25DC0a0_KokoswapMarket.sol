// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./IMarket.sol";
import "./KokoswapNFT.sol";
import "./IERC20.sol";


contract KokoswapMarket is IMarket,Ownable {

    uint256 public constant AUCTION_TIME = 86400; //3 days
    uint256 public constant LAST_BIDDER_RESET_TIME = 900;

    uint256 public FEE = 15;
    uint256 public TOKEN_FEE = 15;
    uint256 public NEXT_BID_PERCENTAGE = 5;
    
    address public ERC20_TOKEN_ADDRESS;
    address public ERC721_TOKEN_ADDRESS;

    mapping(uint256 => Auction) private auctionList;

    constructor() {}

    function listOnAuction(uint256 tokenId, uint256 price, CURRENCY currency, uint256 _days ) public override returns (Auction memory) {
        require(KokoswapNFT(ERC721_TOKEN_ADDRESS).ownerOf(tokenId) == msg.sender, "EA");
         require(!auctionList[tokenId].active, "ES" );

        Auction memory newAuction = Auction(true, msg.sender, address(0), price, _days + block.timestamp, currency );
        auctionList[tokenId] = newAuction;

        KokoswapNFT(ERC721_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), tokenId);

        emit ListOnAuction(msg.sender, tokenId, price, _days + block.timestamp, currency);

        return newAuction;
    }

    function bid(uint256 _tokenId, uint256 _price) public payable override returns(Auction memory){
        Auction memory auctionItem = auctionList[_tokenId];
        require(auctionItem.active, "ES");

        if(block.timestamp > auctionItem.endTime){
            if(auctionItem.owner != address(0)){
                revert("ET");
            }
            auctionItem.endTime = AUCTION_TIME + block.timestamp;
        }

        uint256 bidValueMust = auctionItem.value + (auctionItem.value * NEXT_BID_PERCENTAGE / 100);
        if(auctionItem.currency == CURRENCY.ETH){
            require( bidValueMust <= msg.value, "EV" );
            if(auctionItem.owner != address(0)) {
                payable(auctionItem.owner).transfer(auctionItem.value);
            }
                auctionItem.value = msg.value;
        }else{
            require( bidValueMust <= _price, "EV" );
            require(IERC20(ERC20_TOKEN_ADDRESS).allowance(msg.sender, address(this)) >= _price, "EA");
            IERC20(ERC20_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _price);
            if(auctionItem.owner != address(0)) {
                IERC20(ERC20_TOKEN_ADDRESS).transfer(auctionItem.owner,auctionItem.value);
            }
            auctionItem.value = _price;
        }
        
        auctionItem.owner = msg.sender;

        if (auctionItem.endTime - block.timestamp < LAST_BIDDER_RESET_TIME) {
            auctionItem.endTime = LAST_BIDDER_RESET_TIME + block.timestamp;
        }

        auctionList[_tokenId] = auctionItem;
        emit Bid(msg.sender, _tokenId, auctionItem.value,  auctionItem.currency);
        return auctionList[_tokenId];
    }


    function claimNft(uint256 _tokenId) public override returns(uint256) {
        Auction memory auctionItem = auctionList[_tokenId];
        require(auctionItem.active, "ES");
        require(block.timestamp > auctionItem.endTime, "ET");
        require(auctionItem.seller == msg.sender || auctionItem.owner == msg.sender, "EA");

        if (auctionItem.owner == address(0)) {
            KokoswapNFT(ERC721_TOKEN_ADDRESS).transferFrom(address(this), auctionItem.seller, _tokenId);
        } else {
            KokoswapNFT(ERC721_TOKEN_ADDRESS).transferFrom(address(this), auctionItem.owner, _tokenId);

            KokoswapNFT.Artwork memory artwork = KokoswapNFT(ERC721_TOKEN_ADDRESS).getArtwork(_tokenId);
            uint256 royalityValue = (auctionItem.value * artwork.royalty) / 100;
            
            if(auctionItem.currency == CURRENCY.ETH){
                uint256 serviceFee = (auctionItem.value * FEE) / 100;
                uint256 value = auctionItem.value - (serviceFee + royalityValue);
                payable(auctionItem.seller).transfer(value);
                if(royalityValue > 0){
                    payable(artwork.creator).transfer(royalityValue);
                }
                
            }else{
                uint256 serviceFee = (auctionItem.value * TOKEN_FEE) / 100;
                uint256 value = auctionItem.value - (serviceFee + royalityValue);
                IERC20(ERC20_TOKEN_ADDRESS).transfer(auctionItem.seller,value);
                if(royalityValue > 0){
                    IERC20(ERC20_TOKEN_ADDRESS).transfer(artwork.creator,royalityValue);
                }
            }
        }

        delete auctionList[_tokenId];
        emit ClaimNft(auctionItem.owner, _tokenId, auctionItem.value);
        return _tokenId;
       
    }

    

    function getAuction(uint256 _tokenId) public view override returns (Auction memory) {
        return auctionList[_tokenId];
    }


    function setTokenAddress(address erc721contract, address erc20contract ) public override onlyOwner {
        ERC721_TOKEN_ADDRESS = erc721contract;
        ERC20_TOKEN_ADDRESS = erc20contract;

    }


    function setFee(uint256 fee, uint256 tokenFee) public override onlyOwner {
        FEE = fee;
        TOKEN_FEE = tokenFee;
    }

    function setNextBidPercentage(uint256 nextBidPercent) public override onlyOwner {
        NEXT_BID_PERCENTAGE = nextBidPercent;
    }


    function withdraw(address _address, uint256 _value, CURRENCY currency) public override onlyOwner {
        if(currency == CURRENCY.ETH){
            payable(_address).transfer(_value);
        }else{
           IERC20(ERC20_TOKEN_ADDRESS).transfer(_address,_value);
        }
    }

     function transferAnyERC20Token(address _address, uint tokens) public onlyOwner returns (bool success) {
        return IERC20(_address).transfer(owner(), tokens);
    }

  }