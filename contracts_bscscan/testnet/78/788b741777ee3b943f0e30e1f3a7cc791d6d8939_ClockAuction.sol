/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// CryptoKitties Source code

pragma solidity ^0.8.0;

abstract contract ERC721 {
    // Required methods
    function totalSupply() public view virtual returns (uint256 total);
    function balanceOf(address _owner) public view  virtual returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view virtual returns (address owner);
    function approve(address _to, uint256 _tokenId) virtual external;
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual external;

    function supportsInterface(bytes4 _interfaceID) external view virtual returns (bool);

}

abstract contract ERC20 {
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address who) public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



abstract contract SubBase {
    ERC721 public nonFungibleContract;
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);


    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, address(this), _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(address(this), _receiver, _tokenId);
    }
    function _createRandom() internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
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

    ERC20 public erc20Contract;

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

    constructor(address _nftAddress) {
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    function setDeveloperAddress(address _developer) public onlyOwner {
        developer=_developer;
    }

    function setERC20ContractAddress(address _erc20) public onlyOwner {
        erc20Contract = ERC20(_erc20);
    }



    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256  _tokenId, Auction memory _auction) internal {
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
        return (_auction.startedAt > 0)&&(block.timestamp<(_auction.startedAt+_auction.duration));
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
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp),
            address(0),
            uint128(0)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId, uint256 _bidAmount)
    external
    payable
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        //        uint256 _bidAmount = msg.value;
        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));
        require(_bidAmount>=auction.startingPrice);
        require(_bidAmount>auction.bidPrice);
        require(erc20Contract.transferFrom(msg.sender, address(this), _bidAmount));

        emit AuctionBid(_tokenId, _bidAmount, msg.sender);

        if (auction.bidPrice>0) {
            erc20Contract.transfer(auction.bidder, auction.bidPrice);
        }

        if (_bidAmount >= auction.endingPrice) {
            emit AuctionSuccessful(_tokenId, _bidAmount, msg.sender);
            uint256 reward = _computeCut(_bidAmount);
            developerBalance +=reward;
            ownerBalance += reward*4;
            erc20Contract.transfer(auction.seller, _bidAmount-5*reward);
            _removeAuction(_tokenId);
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

        if (block.timestamp <(auction.duration+auction.startedAt)) {
            require(msg.sender == auction.seller, "only seller");
        }
        emit AuctionSuccessful(_tokenId, auction.bidPrice, auction.bidder);

        uint256 reward = _computeCut(auction.bidPrice);
        developerBalance +=reward;
        ownerBalance += 4*reward;
        erc20Contract.transfer(auction.seller, auction.bidPrice-5*reward);
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
            erc20Contract.transfer(auction.bidder, auction.bidPrice);
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
        require(developer != address(0), "invalid developer address");
        erc20Contract.transfer(developer, developerBalance);
        developerBalance=0;
    }

    function withdrawOwnerReward() public onlyOwner{
        require(ownerBalance>0, "no reward");
        erc20Contract.transfer(owner(), ownerBalance);
        ownerBalance=0;
    }
}