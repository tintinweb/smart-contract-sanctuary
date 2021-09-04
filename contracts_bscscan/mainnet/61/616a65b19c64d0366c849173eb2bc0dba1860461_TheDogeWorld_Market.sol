// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ITheDogeWorld_Market.sol";
import "./ITheDogeWorldNFT.sol";

contract TheDogeWorld_Market is ITheDogeWorld_Market,Ownable {

    // EA: error authentication 
    // ES: error status (not active or active)
    // EC: error currrency
    // ET: error time
    // EY: error auction type
    // EV: error value

    uint256 public constant AUCTION_TIME = 86400;
    uint256 public constant LAST_BIDDER_RESET_TIME = 0;

    uint256 public FEE;
    uint256 public TOKEN_FEE;
    uint256 public NEXT_BID_PERCENTAGE;
    
    address public TDW_TOKEN_ADDRESS;
    address public DOGECOIN_ADDRESS;
    address public ERC721_TOKEN_ADDRESS;

    mapping(uint256 => Auction) private auctionList;

    constructor() {
        FEE = 5;
        TOKEN_FEE = 5;
        NEXT_BID_PERCENTAGE = 5;
    }

    function listOnAuction(uint256 tokenId, uint256 price, CURRENCY currency, uint256 duration, AUCTION_TYPE auctionType ) public override returns (Auction memory) {
        require(ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).ownerOf(tokenId) == msg.sender, "EA");
         require(!auctionList[tokenId].active, "ES" );

        ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), tokenId);

        Auction memory newAuction = Auction(true, msg.sender, address(0), price, duration + block.timestamp, currency, auctionType );
        auctionList[tokenId] = newAuction;

        emit ListOnAuction(msg.sender, tokenId, price, duration + block.timestamp, currency, auctionType);

        return newAuction;
    }

    function bid(uint256 _tokenId, uint256 _price) public payable override returns(Auction memory){
        Auction memory auctionItem = auctionList[_tokenId];
        require(auctionItem.active, "ES");
        require(auctionItem.auctionType == AUCTION_TYPE.AUCTION, "EY");

        if(block.timestamp > auctionItem.endTime){
            if(auctionItem.owner != address(0)){
                revert("ET");
            }
            auctionItem.endTime = AUCTION_TIME + block.timestamp;
        }

        uint256 bidValueMust = auctionItem.value + (auctionItem.value * NEXT_BID_PERCENTAGE / 100);
        if(auctionItem.currency == CURRENCY.BNB){
            require( bidValueMust <= msg.value, "EV" );
            if(auctionItem.owner != address(0)) {
                payable(auctionItem.owner).transfer(auctionItem.value);
            }
                auctionItem.value = msg.value;
        }else{
            require(bidValueMust <= _price, "EV" );
            address erc20ContractAddress;
            if(auctionItem.currency == CURRENCY.TOKEN){
                erc20ContractAddress = TDW_TOKEN_ADDRESS;
            }else if(auctionItem.currency == CURRENCY.DOGE){
                erc20ContractAddress = DOGECOIN_ADDRESS;
            }
            IERC20(erc20ContractAddress).transferFrom(msg.sender, address(this), _price);
            if(auctionItem.owner != address(0)) {
                IERC20(erc20ContractAddress).transfer(auctionItem.owner,auctionItem.value);
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
        require(auctionItem.auctionType == AUCTION_TYPE.AUCTION, "EY");
        require(auctionItem.seller == msg.sender || auctionItem.owner == msg.sender, "EA");

        if (auctionItem.owner == address(0)) {
            auctionItem.owner = auctionItem.seller;
            ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).transferFrom(address(this), auctionItem.owner, _tokenId);
        } else {
            ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).transferFrom(address(this), auctionItem.owner, _tokenId);

            ITheDogeWorldNFT.Artwork memory artwork = ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).getArtwork(_tokenId);
            uint256 royalityValue = (auctionItem.value * artwork.royalty) / 100;
            
            if(auctionItem.currency == CURRENCY.BNB){
                uint256 serviceFee = (auctionItem.value * FEE) / 100;
                uint256 value = auctionItem.value - (serviceFee + royalityValue);
                payable(auctionItem.seller).transfer(value);
                if(royalityValue > 0){
                    payable(artwork.creator).transfer(royalityValue);
                }
                payable(owner()).transfer(serviceFee);

            }else{
                address erc20ContractAddress;
                if(auctionItem.currency == CURRENCY.TOKEN){
                    erc20ContractAddress = TDW_TOKEN_ADDRESS;
                }else if(auctionItem.currency == CURRENCY.DOGE){
                    erc20ContractAddress = DOGECOIN_ADDRESS;
                }

                uint256 serviceFee = (auctionItem.value * TOKEN_FEE) / 100;
                uint256 value = auctionItem.value - (serviceFee + royalityValue);
                IERC20(erc20ContractAddress).transfer(auctionItem.seller,value);
                if(royalityValue > 0){
                    IERC20(erc20ContractAddress).transfer(artwork.creator,royalityValue);
                }
                IERC20(erc20ContractAddress).transfer(owner(),serviceFee);

            }
        }

        delete auctionList[_tokenId];
        emit ClaimNft(auctionItem.owner, _tokenId, auctionItem.value);
        return _tokenId;
       
    }

    
       function buySale(uint256 _tokenId) public payable override returns(uint256) {
        Auction memory auctionItem = auctionList[_tokenId];
        require(auctionItem.active, "ES");
        require(auctionItem.auctionType == AUCTION_TYPE.FIXED, "EY");

        if (auctionItem.seller == msg.sender) {
            ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).transferFrom(address(this), msg.sender, _tokenId);
        } else {
            ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).transferFrom(address(this), msg.sender, _tokenId);
            ITheDogeWorldNFT.Artwork memory artwork = ITheDogeWorldNFT(ERC721_TOKEN_ADDRESS).getArtwork(_tokenId);
            uint256 royalityValue = (auctionItem.value * artwork.royalty) / 100;

            if(auctionItem.currency == CURRENCY.BNB){
                uint256 serviceFee = (auctionItem.value * FEE) / 100;
                uint256 value = auctionItem.value - (serviceFee + royalityValue);
                payable(auctionItem.seller).transfer(value);
                payable(artwork.creator).transfer(royalityValue);
                payable(owner()).transfer(serviceFee);
            }else{

                address erc20ContractAddress;
                if(auctionItem.currency == CURRENCY.TOKEN){
                    erc20ContractAddress = TDW_TOKEN_ADDRESS;
                }else if(auctionItem.currency == CURRENCY.DOGE){
                    erc20ContractAddress = DOGECOIN_ADDRESS;
                }

                uint256 serviceFee = (auctionItem.value * TOKEN_FEE) / 100;
                uint256 value = auctionItem.value - (serviceFee + royalityValue);
                IERC20(erc20ContractAddress).transferFrom(msg.sender, auctionItem.seller, value);
                if(royalityValue > 0){
                    IERC20(erc20ContractAddress).transferFrom(msg.sender, artwork.creator, royalityValue);
                }
                IERC20(erc20ContractAddress).transferFrom(msg.sender, owner(), serviceFee);

                }
            }

        delete auctionList[_tokenId];
        emit ClaimNft(msg.sender, _tokenId, auctionItem.value);
        return _tokenId;
    }


    function getAuction(uint256 _tokenId) public view override returns (Auction memory) {
        return auctionList[_tokenId];
    }


    function setTokenAddress(address _nftAddress, address _tdwAddress, address _dogeAddress ) public override onlyOwner {
        ERC721_TOKEN_ADDRESS = _nftAddress;
        TDW_TOKEN_ADDRESS = _tdwAddress;
        DOGECOIN_ADDRESS = _dogeAddress;

    }


    function setFee(uint256 fee, uint256 tokenFee) public override onlyOwner {
        FEE = fee;
        TOKEN_FEE = tokenFee;
    }

    function setNextBidPercentage(uint256 nextBidPercent) public override onlyOwner {
        NEXT_BID_PERCENTAGE = nextBidPercent;
    }


    function withdraw(address _address, uint256 _value, CURRENCY currency) public override onlyOwner {
        if(currency == CURRENCY.BNB){
            payable(_address).transfer(_value);
        }else{
            address erc20ContractAddress;
            if(currency == CURRENCY.TOKEN){
                erc20ContractAddress = TDW_TOKEN_ADDRESS;
            }else if(currency == CURRENCY.DOGE){
                erc20ContractAddress = DOGECOIN_ADDRESS;
            }

           IERC20(erc20ContractAddress).transfer(_address,_value);
        }
    }

  }