// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IClockAuction.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./INFTCore.sol";

/// @title Auction Core
contract ClockAuctionBase {
    using SafeMath for uint256;
     
    address public nftToken = 0x7A1afa8397429d44c21d37d39026427C599c8c18;
    uint256 public feeBid = 0.01 ether;
    uint256 public minAuctionPrice = 1 ether;
    address public feeWallet = 0x8E8FCc1680a6A642521a5F9BE37eC2f26940E38A;
    uint256 stepBid = 10;

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price at beginning of auction
        uint256 startingPrice;
        // Price at end of auction
        uint256 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        uint256 startAt;
        // Current Bidder
        address currentBidder;
        // claim NFT
        bool claimNFT;
        // claim Token
        bool claimToken;
    }

    struct Bidder {
        address userAddress;
        uint256 amount;
        uint256 timeBid;
    }

    struct History {
        uint256 tokenId;
        Bidder[] bidders;
    }

    // Reference to contract tracking NFT ownership
    address public nonFungibleContract;

    uint256 public ownerCut;
    mapping (uint256 => Auction) public tokenIdToAuction;
    mapping (uint256 => History) public histories;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 duration, address currentBidder, uint256 startAt);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address bidder);
    event AuctionClaimedNFT(uint256 tokenId, address winner);
    event AuctionClaimedToken(uint256 tokenId, address winner, uint256 amount);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (IERC721(nonFungibleContract).ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        IERC721(nonFungibleContract).transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        IERC721(nonFungibleContract).transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.duration),
            address(0),
            block.timestamp
        );
    }

    /// @dev Computes the price and transfers winnings.
    function _bid(uint256 _tokenId, uint256 _bidAmount, address _bidder)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        // Check that the bid is greater than or equal to the current price
        uint256 price = auction.endingPrice;
        uint256 minimumBid = price.mul(stepBid).div(100);
        require(_bidAmount >= price.add(minimumBid), "amount must be greater than the current price");

        //Return token old bidder
        if(auction.currentBidder != address(0)) {
            uint256 biddDiff = _bidAmount - price;
            uint256 returnLastPrice = uint256(auction.endingPrice).add(uint256(biddDiff).mul(stepBid).div(100));
            require(IERC20(nftToken).transfer(auction.currentBidder, returnLastPrice));
        }
        auction.currentBidder = _bidder;
        auction.endingPrice = _bidAmount;
        History storage history = histories[_tokenId];
        if(history.tokenId == 0) {
            history.tokenId = _tokenId;
        }
        history.bidders.push(Bidder(_bidder, _bidAmount, block.timestamp));
        emit AuctionSuccessful(_tokenId, _bidAmount, _bidder);

        return _bidAmount;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Removes an history auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeHistoryAuction(uint256 _tokenId) internal {
        delete histories[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction memory _auction) internal view returns (bool) {
        return (_auction.startingPrice > 0);
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}

/// @title Clock auction for non-fungible tokens.
contract ClockAuction is Pausable, ClockAuctionBase, IClockAuction {

    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;
        nonFungibleContract = _nftAddress;
    }

    function withdrawBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        IERC20(nftToken).transfer(owner(), getBalance());
    }
    
    function changeCut(uint256 _cut) external onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
    }
    
    function getBalance() view public returns(uint256) {
        return IERC20(nftToken).balanceOf(address(this));
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration,
        address _seller
    )
        virtual override external
        whenNotPaused
    {
        require(_startingPrice == uint256(_startingPrice));
        require(_duration == uint256(_duration));

        require(_owns(msg.sender, _tokenId), "Not tokenId owner");
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _startingPrice,
            0,
            uint64(_duration),
            block.timestamp,
            address(0),
            false,
            false
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough KAI is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId, uint256 _amount, address _bidder)
        virtual external payable
        whenNotPaused
    {
        // require(IERC20(nftToken).transfer(address(this), _amount));
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, _amount, _bidder);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        Auction memory auction
    ) {
        auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "TokenID is a must on auction");
        return auction;
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "TokenID is a must on auction");
        return auction.endingPrice;
    }

}


/// @title Clock auction modified for sale of MinoWar
contract NFTClockAuction is ClockAuction, ReentrancyGuard {
    using SafeMath for uint256; 

    bool public isSaleClockAuction = true;   

    constructor(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration,
        address _seller
    )
        override external nonReentrant
    {
        require(_startingPrice >= minAuctionPrice, "minimum price not enough");
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _startingPrice,
            0,
            uint64(_duration),
            block.timestamp,
            address(0),
            false,
            false
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId, uint256 _amount, address _bidder)
        override external payable nonReentrant
    {
        require(IERC20(nftToken).transferFrom(_bidder, address(this), _amount));
        require(feeBid == msg.value, "fee bid not enough");
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(block.timestamp <= auction.startAt.add(auction.duration), "auction already ended");
        require(auction.seller != address(0) , "auction not exist");
        // _bid verifies token ID size
        _bid(_tokenId, _amount, _bidder);
        payable(feeWallet).transfer(msg.value);
    }

    function claimNFT(uint256 _tokenId) external nonReentrant {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.seller != address(0) , "auction not exist");
        require(block.timestamp > auction.startAt.add(auction.duration), "waiting auction ended");
        if(auction.currentBidder != address(0)){
            require(_msgSender() == auction.currentBidder, "not the winner");
        } 
        if(auction.currentBidder == address(0)){
            require(_msgSender() == auction.seller, "not the owner");
        }       
        auction.claimNFT = true;
        _transfer(_msgSender(), _tokenId);
        if(auction.claimToken && auction.claimNFT) {
            _removeAuction(_tokenId);
            _removeHistoryAuction(_tokenId);
        }
        if(auction.currentBidder == address(0)){
            _removeAuction(_tokenId);
            _removeHistoryAuction(_tokenId);
        }    
        emit AuctionClaimedNFT(_tokenId, _msgSender());
    }

    function claimAmount(uint256 _tokenId) external nonReentrant {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.seller != address(0) , "auction not exist");
        require(block.timestamp > auction.startAt.add(auction.duration), "waiting auction ended");
        uint256 cutAmount;
        if(auction.currentBidder != address(0)){
            require(_msgSender() == auction.currentBidder, "not the winner");
            auction.claimToken = true;          
            cutAmount = uint256(auction.endingPrice).sub(_computeCut(auction.endingPrice));
            require(IERC20(nftToken).transfer(auction.seller, cutAmount));
        } 
        if(auction.claimToken && auction.claimNFT) {
            _removeAuction(_tokenId);
            _removeHistoryAuction(_tokenId);
        }
        
        emit AuctionClaimedToken(_tokenId, _msgSender(), cutAmount);
    }

    function cancelAuctionOwner(uint256 _tokenId, address userAddress) external onlyOwner {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(block.timestamp > auction.startAt.add(auction.duration), "waiting auction ended");
       
        _transfer(userAddress, _tokenId);
        _removeAuction(_tokenId);
        _removeHistoryAuction(_tokenId);
    }


    function getHistories(uint256 _tokenId) public view returns (History memory history) {
        history = histories[_tokenId]; 
    }

    function setStepBid(uint256 _percent) external onlyOwner {
        stepBid = _percent;
    }

    function setMinAuctionPrice(uint256 _price) external onlyOwner {
        minAuctionPrice = _price;
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }
}