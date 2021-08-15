//SourceUnit: AuctionTRX.sol

pragma solidity >=0.8.0 <0.9.0;

interface TRC721TokenReceiver {
    function onTRC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface TRC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

abstract contract TRC20 {
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address who) public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract TRC721 {
    function balanceOf(address _owner) public view virtual returns (uint256);
    function ownerOf(uint256 _tokenId) public view virtual returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) virtual public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) virtual public;
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual public;
    function approve(address _approved, uint256 _tokenId) virtual public;
    function setApprovalForAll(address _operator, bool _approved) virtual public;
    function getApproved(uint256 _tokenId) public view virtual returns (address);
    function isApprovedForAll(address _owner, address _operator) public view virtual returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract AuctionEngineV6 is TRC721TokenReceiver, TRC165 {
    modifier trxAuction(uint256 auctionIndex) {
        require(isTRXAuction(auctionIndex), "auction only use trx");
        _;
    }

    modifier trc20Auction(uint256 auctionIndex) {
        require(!isTRXAuction(auctionIndex), "auction only use trc20");
        _;
    }

    using SafeMath for uint256;
    event AuctionCreated(uint256 _index, address _creator, address _asset, uint256 _assetID);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
    event ClaimTokens(uint256 auctionIndex, address claimer, uint256 amount);
    event ClaimAsset(uint256 auctionIndex, address claimer);
    enum Status {pending, active, finished}
    struct Auction {
        address assetAddress;
        uint256 assetId;
        uint256 startTime;
        uint256 minPrice;
        uint256 endTime;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
        uint256 instantBuyPrice;
        bool finished;
        bool isWonBidSent;
        address trc20tokenAddress; //If we prefer to accept trc20 token (like USDT) instead of trx;
        address creator;
        mapping(address => uint) pendingReturns;
    }

    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

    uint numAuctions;
    mapping (uint256 => Auction) auctions;

    function createAuction(
        address _assetAddress,
        uint256 _assetId,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _duration,
        uint256 _instantBuyPrice,
        address _trc20tokenAddress
    ) public returns (uint256) {
        require(TRC165(_assetAddress).supportsInterface(_INTERFACE_ID_TRC721), "Not valid TRC721 asset");
        TRC721 asset = TRC721(_assetAddress);
        asset.safeTransferFrom(msg.sender, address(this), _assetId, "");
        if (_startTime == 0) {
            _startTime = block.timestamp;
        }
        require(_startTime >= block.timestamp, "Start time should be in future");
        require(_duration > 0, "Duration should be positive");

	numAuctions++;
	Auction storage a = auctions[numAuctions];
        a.assetAddress = _assetAddress;
        a.assetId = _assetId;
        a.startTime = _startTime;
        a.endTime = _startTime.add(_duration);
        a.minPrice = _startPrice;
        a.currentBidAmount = 0;
        a.currentBidOwner = msg.sender; //If no one binds, creator will be able to claim back the asset.
        a.bidCount = 0;
        a.instantBuyPrice = _instantBuyPrice;
        a.finished = false;
        a.creator = msg.sender;
        a.isWonBidSent = false;
        a.trc20tokenAddress= _trc20tokenAddress;
        uint256 index = numAuctions;
        emit AuctionCreated(index, msg.sender, _assetAddress, _assetId);
        return index;
    }

    function isTRXAuction(uint256 auctionIndex) public view returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        return auction.trc20tokenAddress == address(0);
    }

    function bidTRX(uint256 auctionIndex) public payable trxAuction(auctionIndex) {
        _bid(auctionIndex, msg.value);
    }

    function bidTRC20(uint256 auctionIndex, uint256 amount) public trc20Auction(auctionIndex) {
        _bid(auctionIndex, amount);
        Auction storage auction = auctions[auctionIndex];
        TRC20 token = TRC20(auction.trc20tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount));
    }

    function _bid(uint256 auctionIndex, uint256 amount) internal {
        Auction storage auction = auctions[auctionIndex];
        require(amount >= auction.minPrice, "Value should be not smaller than start price");
        require(amount > auction.currentBidAmount, "Value should be bigger the current bid");

        if (auction.currentBidAmount != 0) {
            auction.pendingReturns[auction.currentBidOwner] += auction.currentBidAmount;
        }
        auction.currentBidAmount = amount;
        auction.currentBidOwner = msg.sender;
        auction.bidCount = auction.bidCount.add(1);
        emit AuctionBid(auctionIndex, msg.sender, amount);
    }

    function getTotalAuctions() public view returns (uint256) {
        return numAuctions;
    }

    function isActive(uint256 index) public view returns (bool) {
        return getStatus(index) == Status.active;
    }

    function isFinished(uint256 index) public view returns (bool) {
        return getStatus(index) == Status.finished;
    }


    function getStatus(uint256 index) public view returns (Status) {
        Auction storage auction = auctions[index];
        if (auction.finished) {
            return Status.finished;
        }

        if (block.timestamp < auction.startTime) {
            return Status.pending;
        }
	if (block.timestamp < auction.endTime) {
            return Status.active;
        }
	return Status.finished;
    }

    function getCurrentBidOwner(uint256 auctionIndex) public view returns (address) {
        return auctions[auctionIndex].currentBidOwner;
    }

    function getCurrentBidAmount(uint256 auctionIndex) public view returns (uint256) {
        return auctions[auctionIndex].currentBidAmount;
    }

    function getBidCount(uint256 auctionIndex) public view returns (uint256) {
        return auctions[auctionIndex].bidCount;
    }

    function getWinner(uint256 auctionIndex) public view returns (address) {
        require(isFinished(auctionIndex));
        return auctions[auctionIndex].currentBidOwner;
    }

    function claimTokens(uint256 auctionIndex) public {
        Auction storage auction = auctions[auctionIndex];
        uint amount = auction.pendingReturns[msg.sender];

        require(amount > 0, "Nothing to claim");

        auction.pendingReturns[msg.sender] = 0;
        _sendTo(auctionIndex, amount);
        emit ClaimTokens(auctionIndex, msg.sender, amount);
    }

    function _sendTo(uint256 auctionIndex, uint256 amount) internal {
        Auction storage auction = auctions[auctionIndex];
        if (isTRXAuction(auctionIndex)) {
            payable(msg.sender).transfer(amount);
        } else {
            TRC20 token = TRC20(auction.trc20tokenAddress);
            require(token.transfer(msg.sender, amount));
        }
    }

    function claimAsset(uint256 auctionIndex) public {
        address winner = getWinner(auctionIndex);
        require(isFinished(auctionIndex), "auction is not finished yet");
        require(winner == msg.sender, "you are not winner");

        Auction storage auction = auctions[auctionIndex];
        TRC721 asset = TRC721(auction.assetAddress);
        asset.transferFrom(address(this), winner, auction.assetId);
        emit ClaimAsset(auctionIndex, winner);
    }

    function claimWonBid(uint256 auctionIndex) public {
        require(isFinished(auctionIndex), "auction is not finished yet");
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator == msg.sender, "not creator of auction");
        require(!auction.isWonBidSent, "you already collected a won bid");
        auction.isWonBidSent = true;
        _sendTo(auctionIndex, auction.currentBidAmount);
    }


    function instantBuyAssetWithTRX(uint256 auctionIndex) public payable trxAuction(auctionIndex) {
        _instantBuy(auctionIndex, msg.value);
    }

    function instantBuyAssetWithTRC20(uint256 auctionIndex, uint256 amount) public trc20Auction(auctionIndex) {
        _instantBuy(auctionIndex, amount);
        Auction storage auction = auctions[auctionIndex];
        TRC20 token = TRC20(auction.trc20tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount));
    }
    function _instantBuy(uint256 auctionIndex, uint256 amount) internal {
        Auction storage auction = auctions[auctionIndex];

        require(isActive(auctionIndex), "Auction is not active");
        require(auction.instantBuyPrice > 0, "Instant price was not set. This can not be bought instantly");

        require(amount >= auction.instantBuyPrice);

        if (auction.currentBidAmount != 0) {
            auction.pendingReturns[auction.currentBidOwner] += auction.currentBidAmount;
        }

        auction.currentBidAmount = amount;
        auction.currentBidOwner = msg.sender;
        auction.finished = true;
    }

    function onTRC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
	return type(TRC721TokenReceiver).interfaceId;
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(TRC165).interfaceId || interfaceID == type(TRC721TokenReceiver).interfaceId;
    }
}