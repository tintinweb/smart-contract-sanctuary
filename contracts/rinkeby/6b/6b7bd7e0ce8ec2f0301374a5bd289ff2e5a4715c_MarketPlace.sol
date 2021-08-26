/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity 0.5.12;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused, "Contract Paused!");
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

interface IERC165 {
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId,  bytes calldata data) external;

    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    bytes4 constant internal ERC721_RECEIVED_VALUE = 0xf0b9e5ba;
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external
    returns(bytes4)
    {
       return ERC721_RECEIVED_VALUE;
    }
}

contract MarketBase is ERC721Holder {
    
    struct Sale{
        address payable seller;
        uint256 startingPrice;
        uint256 endingPrice;
        uint64 duration;
        uint64 timestamp;
    }
    
    struct Auction {
        address payable seller;
        uint256 currentPrice;
        address payable currentBidder;
        uint64 duration;
        uint64 timestamp;
    }

    IERC721 public semiFungibleContract;

    uint256 public ownerCut;
    
    mapping (uint256 => Sale) tokenIdToSale;
    mapping (uint256 => Auction) tokenIdToAuction;

    event SaleCreated(uint256 indexed tokenId, uint256 indexed startingPrice, uint256 endingPrice, uint256 indexed duration);
    event SaleSuccessful(uint256 indexed tokenId, uint256 indexed finalPrice, address indexed buyer);
    event SaleCancelled(uint256 indexed tokenId);
    event AuctionCreated(uint256 indexed tokenId, uint256 indexed currentPrice, uint256 indexed duration);
    event BidSuccessful(uint256 indexed tokenId, uint256 indexed currentPrice, address indexed currentBidder);
    event AuctionSuccessful(uint256 indexed tokenId, uint256 indexed totalPrice, address indexed winner);
    event AuctionCancelled(uint256 indexed tokenId);

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (semiFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        semiFungibleContract.safeTransferFrom(_owner, address(this), _tokenId, "");
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        semiFungibleContract.safeTransferFrom(address(this), _receiver, _tokenId, "");
    }
    
    function _addSale(uint256 _tokenId, Sale memory _sale) internal {
        require(_sale.duration >= 1 minutes, "Durantion needs to more than 1 minutes!");

        tokenIdToSale[_tokenId] = _sale;

        emit SaleCreated(
            uint256(_tokenId),
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration)
        );
    }
    
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_seller, _tokenId);
        emit SaleCancelled(_tokenId);
    }
    
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.currentPrice),
            uint256(_auction.duration)
        );
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        require(tokenIdToAuction[_tokenId].currentBidder == address(0));
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bidSale(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        Sale storage sale = tokenIdToSale[_tokenId];

        require(_isOnSale(sale), "Token is not onsale!");
        uint256 price = _currentPrice(sale);
        require(_bidAmount >= price, "Insufficient Amount!");

        address payable seller = sale.seller;

        _removeSale(_tokenId);

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);
        }

        emit SaleSuccessful(_tokenId, price, msg.sender);

        return price;
    }
    
    function _bidAuction(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));
        uint256 price = auction.currentPrice;
        require(_bidAmount >= price*11/10);

        if (auction.currentBidder != address(0)) {
            auction.currentBidder.transfer(price);
        }
        auction.currentPrice = _bidAmount;
        auction.currentBidder = msg.sender;

        emit BidSuccessful(_tokenId, _bidAmount, msg.sender);

        return _bidAmount;
    }
    
    function _auctionClose(uint256 _tokenId)
        internal
        returns (bool)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(!_isOnAuction(auction), 'Auction not close');
        require(auction.currentBidder != address(0));
        require(msg.sender == auction.seller || msg.sender == auction.currentBidder);
        uint256 price = auction.currentPrice;
        address payable seller = auction.seller;
        
        _removeAuction(_tokenId);
        
         if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);
        }
        emit AuctionSuccessful(_tokenId, price, auction.currentBidder);

        return true;
    }
    
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }
    
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.timestamp > 0);
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return ((_auction.timestamp+_auction.duration) > now);
    }
    
    function _currentPrice(Sale storage _sale)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;
        if (now > _sale.timestamp) {
            secondsPassed = now - _sale.timestamp;
        }

        return _computeCurrentPrice(
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
            secondsPassed
        );
    }
    
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }
    
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

}

contract MarketPlace is Pausable, MarketBase {
    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
        
    function isMarket() external pure returns (bool) {
        return true;
    }

    constructor (address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        IERC721 candidateContract = IERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        semiFungibleContract = candidateContract;
    }
    
    function withdrawBalance() external {
        address payable nftAddress =  address(uint160(address(semiFungibleContract)));

        require(
            msg.sender == _owner ||
            msg.sender == nftAddress
        );
        bool res = nftAddress.send(address(this).balance);
    }

    function createSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address payable _seller
    )
        external
        whenNotPaused
    {
        require(_duration == uint256(uint64(_duration)));
        require(msg.sender == address(semiFungibleContract));
        require(_owns(_seller, _tokenId), "You are not owner or You do not have enough!");
        _escrow(_seller, _tokenId);
        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            _endingPrice,
            uint64(_duration),
            uint64(now)
        );
        _addSale(_tokenId, sale);
    }
    
    function createAuction(
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _duration,
        address payable _seller
    )
        external
        whenNotPaused
    {
        require(_duration == uint256(uint64(_duration)));
        require(msg.sender == address(semiFungibleContract));
        require(_owns(_seller, _tokenId));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            _initialPrice,
            address(0),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }
    
    function bidSale(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _bidSale(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }
    
    function bidAuction(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _bidAuction(_tokenId, msg.value);
    }
    
    function closeAuction(uint256 _tokenId)
        external
        whenNotPaused
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        address payable bidder = auction.currentBidder;
        _auctionClose(_tokenId);
        _transfer(bidder, _tokenId);
    }

    function cancelSale(uint256 _tokenId)
        external
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }
    
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.timestamp > 0);
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        _cancelAuction(_tokenId, auction.seller);
    }

    function getSale(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 timestamp
    ) {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.startingPrice,
            sale.endingPrice,
            sale.duration,
            sale.timestamp
        );
    }
    
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 currentPrice,
        address currentBidder,
        uint256 duration,
        uint256 timestamp
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.currentPrice,
            auction.currentBidder,
            auction.duration,
            auction.timestamp
        );
    }

    function getSalePrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return _currentPrice(sale);
    }
    
    function getCurrentBid(uint256 _tokenId)
        external
        view
        returns
    (
        address bidder,
        uint256 price
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.currentBidder,
            auction.currentPrice
        );
    }

}