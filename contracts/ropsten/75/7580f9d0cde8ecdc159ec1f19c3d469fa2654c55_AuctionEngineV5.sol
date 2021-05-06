/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.5.10;

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 energy.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
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

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    // interface
    function balanceOf(address _owner) public view returns (uint256);

    function ownerOf(uint256 _tokenId) public view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    function approve(address _approved, uint256 _tokenId) public;

    function setApprovalForAll(address _operator, bool _approved) public;

    function getApproved(uint256 _tokenId) public view returns (address);

    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract AuctionEngineV5 is ERC721TokenReceiver, ERC165 {
    modifier trxAuction(uint256 auctionIndex) {
        require(isTRXAuction(auctionIndex), "auction only use trx");
        _;
    }

    modifier erc20Auction(uint256 auctionIndex) {
        require(!isTRXAuction(auctionIndex), "auction only use erc20");
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
        address erc20tokenAddress; //If we prefer to accept erc20 token (like USDT) instead of trx;
        address creator;
        mapping(address => uint) pendingReturns;
    }

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    Auction[] private auctions;

    function createAuction(
        address _assetAddress,
        uint256 _assetId,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _duration,
        uint256 _instantBuyPrice,
        address _erc20tokenAddress
    ) public returns (uint256) {
        require(ERC165(_assetAddress).supportsInterface(_INTERFACE_ID_ERC721), "Not valid ERC721 asset");
        ERC721 asset = ERC721(_assetAddress);
        asset.safeTransferFrom(msg.sender, address(this), _assetId, "");
        if (_startTime == 0) {
            _startTime = now;
        }
        require(_startTime >= now, "Start time should be in future");
        require(_duration > 0, "Duration should be positive");

        Auction memory auction = Auction({
        assetAddress : _assetAddress,
        assetId : _assetId,
        startTime : _startTime,
        endTime : _startTime.add(_duration),
        minPrice : _startPrice,
        currentBidAmount : 0,
        currentBidOwner : msg.sender, //If no one binds, creator will be able to claim back the asset.
        bidCount : 0,
        instantBuyPrice : _instantBuyPrice,
        finished : false,
        creator : msg.sender,
        isWonBidSent : false,
        erc20tokenAddress: _erc20tokenAddress
        });
        uint256 index = auctions.push(auction) - 1;
        emit AuctionCreated(index, msg.sender, _assetAddress, _assetId);
        return index;
    }

    function isTRXAuction(uint256 auctionIndex) public view returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        return auction.erc20tokenAddress == address(0);
    }

    function bidTRX(uint256 auctionIndex) public payable trxAuction(auctionIndex) {
        _bid(auctionIndex, msg.value);
    }

    function bidERC20(uint256 auctionIndex, uint256 amount) public erc20Auction(auctionIndex) {
        _bid(auctionIndex, amount);
        Auction storage auction = auctions[auctionIndex];
        ERC20 token = ERC20(auction.erc20tokenAddress);
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
        return auctions.length;
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

        if (now < auction.startTime) {
            return Status.pending;
        }
	if (now < auction.endTime) {
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
            require(msg.sender.send(amount));
        } else {
            ERC20 token = ERC20(auction.erc20tokenAddress);
            require(token.transfer(msg.sender, amount));
        }
    }

    function claimAsset(uint256 auctionIndex) public {
        address winner = getWinner(auctionIndex);
        require(isFinished(auctionIndex), "auction is not finished yet");
        require(winner == msg.sender, "you are not winner");

        Auction storage auction = auctions[auctionIndex];
        ERC721 asset = ERC721(auction.assetAddress);
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

    function instantBuyAssetWithERC20(uint256 auctionIndex, uint256 amount) public erc20Auction(auctionIndex) {
        _instantBuy(auctionIndex, amount);
        Auction storage auction = auctions[auctionIndex];
        ERC20 token = ERC20(auction.erc20tokenAddress);
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

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == 0x01ffc9a7 || // ERC165
        interfaceID == 0xf0b9e5ba;
        // ERC721TokenReceiver
    }
}