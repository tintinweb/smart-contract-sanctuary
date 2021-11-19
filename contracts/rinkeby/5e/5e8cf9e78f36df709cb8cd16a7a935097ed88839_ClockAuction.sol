/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// CryptoKitties Source code
// Copied from: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code

pragma solidity ^0.4.22;

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

}


contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Pledge {
    function getPledgeInfo(address _own) public view returns(uint256 balance, uint256 createdAt);
}

contract SubBase {
    ERC721 public nonFungibleContract;
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);
    Pledge public pledgeContract;

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(this, _receiver, _tokenId);
    }
    function _createRandom() internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.difficulty, now)));
    }

    function _meetPledged(address _own) internal view returns(bool) {
        uint256 value;
        uint256 created;
        (value, created) = pledgeContract.getPledgeInfo(_own);
        return (value>=(10*(10**18))&&((now-created)>=60*24*3600));
    }
}


contract ClockAuction is Ownable, SubBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;

        address bidder;
        uint128 bidPrice;
    }


    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut=100;
    address public developer;
    uint256 public developerBalance;
    uint256 public ownerBalance;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    event AuctionBid(uint256 tokenId, uint256 price, address player);

    constructor(address _nftAddress) public{
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
        owner = msg.sender;
    }

    function setDeveloperAddress(address _developer) public onlyOwner {
        developer=_developer;
    }

    function setPledgeAddress(address _address) external onlyOwner {
        pledgeContract = Pledge(_address);
    }


    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0)&&(now<(_auction.startedAt+_auction.duration));
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        require(_meetPledged(msg.sender), "not meet pledge");
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            address(0),
            uint128(0)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
    external
    payable
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        uint256 _bidAmount = msg.value;
        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));
        require(_bidAmount>=auction.startingPrice);
        require(_bidAmount>auction.bidPrice);
        require(_meetPledged(msg.sender), "not meet pledge");

        emit AuctionBid(_tokenId, _bidAmount, msg.sender);

        if (auction.bidPrice>0) {
            auction.bidder.transfer(auction.bidPrice);
        }

        if (_bidAmount >= auction.endingPrice) {
            emit AuctionSuccessful(_tokenId, _bidAmount, msg.sender);
            address seller = auction.seller;
            _removeAuction(_tokenId);
            uint256 reward = _computeCut(_bidAmount);
            developerBalance +=reward;
            ownerBalance += reward*4;
            seller.transfer(_bidAmount-5*reward);
            _transfer(msg.sender, _tokenId);
        } else {
            auction.bidPrice=uint128(_bidAmount);
            auction.bidder=msg.sender;
        }
    }

    function bidEnd(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(auction.bidPrice>=auction.startingPrice);

        if (now <(auction.duration+auction.startedAt)) {
            require(msg.sender == auction.seller, "only seller");
        }
        emit AuctionSuccessful(_tokenId, auction.bidPrice, auction.bidder);

        address seller = auction.seller;
        uint256 reward = _computeCut(auction.bidPrice);
        developerBalance +=reward;
        ownerBalance += 4*reward;
        seller.transfer(auction.bidPrice-5*reward);
        _transfer(auction.bidder, _tokenId);
        _removeAuction(_tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        //        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller || msg.sender == auction.bidder, "only seller and bidder cancel auction");
        if (auction.bidPrice>=auction.startingPrice) {
            auction.bidder.transfer(auction.bidPrice);
        }
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 currentPrice,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        auction.bidPrice,
        auction.startedAt
        );
    }

    function withdrawDeveloperReward() public{
        require(developerBalance>0, "no reward");
        developer.transfer(developerBalance);
        developerBalance=0;
    }

    function withdrawOwnerReward() public onlyOwner{
        require(ownerBalance>0, "no reward");
        owner.transfer(ownerBalance);
        ownerBalance=0;
    }
}