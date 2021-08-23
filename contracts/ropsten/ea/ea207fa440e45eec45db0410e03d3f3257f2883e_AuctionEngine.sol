/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.4.2;

interface IERC20 {
    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // interface
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract ERC20Basic is IERC20 {

    string public constant name = "TEST";
    string public constant symbol = "TEST";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library AddressUtils {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC721Receiver {
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


contract ERC721Interface {
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // interface
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract ERC721 is ERC721Interface {
    using SafeMath for uint256;
    using AddressUtils for address;

    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    mapping(uint256 => address) internal tokenOwner;

    mapping (address => uint256) internal ownedTokensCount;

    mapping (uint256 => address) internal tokenApprovals;

    mapping (address => mapping (address => bool)) internal operatorApprovals;


    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public {
        if (_to.isContract()) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, data);
            require(retval == ERC721_RECEIVED);
        }
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _approved != address(0)) {
            tokenApprovals[_tokenId] = _approved;
            emit Approval(owner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function onERC721Received(address, uint256, bytes) public returns (bytes4) {
        return ERC721_RECEIVED;
    }
}


contract AuctionEngine {
    using SafeMath for uint256;
    using AddressUtils for address;
    
    // event AuctionCreated(uint256 _index, address _creator, address _asset, address _token);
    event AuctionCreated(uint256 _index, address _creator, address _asset);
    event MarketplaceCreated(uint256 _index, address _creator, address _asset);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
    event MarketplaceBuy(uint256 _index, address _buyer, uint256 amount);
    event MarketplaceBuyYoa(uint256 _index, address _buyer, uint256 amount);
    event Claim(uint256 auctionIndex, address claimer);

    enum Status { pending, active, finished }
    struct Auction {
        address assetAddress;
        uint256 assetId;

        address creator;
        address paymentWallet;
        
        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
    }
    struct Marketplace {
        address assetAddress;
        uint256 assetId;
        
        address creator;
        address paymentWallet;
        
        address buyer;
        uint256 price;
    }
    Auction[] private auctions;
    Auction[] private auctionsYoa;
    Marketplace[] private marketplaces;
    Marketplace[] private marketplacesYoa;
    
    address yoaAddress = 0x735957ad139b8222d0571aa89683000915ad0af5;

    function createAuction(address _assetAddress,
                           uint256 _assetId,
                           address _paymentWallet,
                           uint256 _startPrice, 
                           uint256 _startTime, 
                           uint256 _duration) public returns (uint256) {
        
        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));
        
        if (_startTime == 0) { _startTime = now; }
        
        Auction memory auction = Auction({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            paymentWallet: _paymentWallet,
            startTime: _startTime,
            duration: _duration,
            currentBidAmount: _startPrice,
            currentBidOwner: address(0),
            bidCount: 0
        });
        uint256 index = auctions.push(auction) - 1;

        emit AuctionCreated(index, auction.creator, auction.assetAddress);
        
        return index;
    }
    
    function createMarketplace(address _assetAddress,
                               uint256 _assetId,
                               address _paymentWallet,
                               uint256 _price) public returns (uint256) {
        
        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));
        
        Marketplace memory marketplace = Marketplace({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            paymentWallet: _paymentWallet,
            price: _price,
            buyer: address(0)
        });
        uint256 index = marketplaces.push(marketplace) - 1;
        
        emit MarketplaceCreated(index, marketplace.creator, marketplace.assetAddress);
        
        return index;
    }
    
    function createMarketplaceYoa(address _assetAddress,
                                  uint256 _assetId,
                                  address _paymentWallet,
                                  uint256 _price) public returns (uint256) {
        
        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));
        
        Marketplace memory marketplace = Marketplace({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            paymentWallet: _paymentWallet,
            price: _price,
            buyer: address(0)
        });
        uint256 index = marketplaces.push(marketplace) - 1;
        
        emit MarketplaceCreated(index, marketplace.creator, marketplace.assetAddress);
        
        return index;
    }
    
    function bid(uint256 auctionIndex) public payable returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator != address(0));
        require(isActive(auctionIndex));
        
        if (msg.value > auction.currentBidAmount) {
            // refund last highest bidder
            if (auction.currentBidOwner != address(0)) {
                auction.currentBidOwner.transfer(auction.currentBidAmount);
            }
            
            auction.currentBidAmount = msg.value;
            auction.currentBidOwner = msg.sender;
            auction.bidCount = auction.bidCount.add(1);
            
            emit AuctionBid(auctionIndex, msg.sender, msg.value);
            return true;
        } else if (msg.value <= auction.currentBidAmount) {
            msg.sender.transfer(msg.value);
            return true;
        }
        return false;
    }
    
    function buy(uint256 marketplaceIndex) public payable returns (bool) {
        Marketplace storage marketplace = marketplaces[marketplaceIndex];
        require(marketplace.creator != address(0));
        require(isActiveMarketplace(marketplaceIndex));
        
        if (msg.value >= marketplace.price) {
            marketplace.buyer = msg.sender;
            marketplace.paymentWallet.transfer(msg.value);
            ERC721 asset = ERC721(marketplace.assetAddress);
            asset.transferFrom(marketplace.creator, msg.sender, marketplace.assetId);
            
            emit MarketplaceBuy(marketplaceIndex, msg.sender, msg.value);
        } else if (msg.value < marketplace.price) {
            msg.sender.transfer(msg.value);
            return true;
        }
        return false;
    }
    function buyYoa(uint256 marketplaceIndex, uint256 amount) public returns (bool) {
        IERC20 token = IERC20(yoaAddress);
        Marketplace storage marketplace = marketplacesYoa[marketplaceIndex];
        require(marketplace.creator != address(0));
        require(isActiveMarketplaceYoa(marketplaceIndex));
        
        require(token.balanceOf(msg.sender) >= amount);
        token.transferFrom(msg.sender, address(this), amount);
        
        if (amount >= marketplace.price) {
            marketplace.buyer = msg.sender;
            marketplace.paymentWallet.transfer(amount);
            ERC721 asset = ERC721(marketplace.assetAddress);
            asset.transferFrom(marketplace.creator, msg.sender, marketplace.assetId);
            
            emit MarketplaceBuyYoa(marketplaceIndex, msg.sender, amount);
        } else if (amount < marketplace.price) {
            token.transfer(msg.sender, amount);
            return true;
        }
        return false;
    }

    function getTotalAuctions() public view returns (uint256) { return auctions.length; }

    function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }
    function isActiveMarketplace(uint256 index) public view returns (bool) { return getStatusMarketplace(index) == Status.active; }
    function isActiveMarketplaceYoa(uint256 index) public view returns (bool) { return getStatusMarketplaceYoa(index) == Status.active; }
    
    function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }
    function isFinishedYoa(uint256 index) public view returns (bool) { return getStatusYoa(index) == Status.finished; }
    
    function getAuctionInformation(uint256 index) public view returns (address) {
        Auction storage auction = auctions[index];
        return auction.assetAddress;
    }
    function getMarketplaceInformation(uint256 index) public view returns (address) {
        Marketplace storage marketplace = marketplaces[index];
        return marketplace.assetAddress;
    }
    
    function getStatus(uint256 index) public view returns (Status) {
        Auction storage auction = auctions[index];
        if (now < auction.startTime) {
            return Status.pending;
        } else if (now < auction.startTime.add(auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }
    function getStatusYoa(uint256 index) public view returns (Status) {
        Auction storage auction = auctionsYoa[index];
        if (now < auction.startTime) {
            return Status.pending;
        } else if (now < auction.startTime.add(auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }
    function getStatusMarketplace(uint256 index) public view returns (Status) {
        Marketplace storage marketplace = marketplaces[index];
        if (marketplace.buyer != address(0)) {
            return Status.finished;
        } else {
            return Status.active;
        }
    }
    function getStatusMarketplaceYoa(uint index) public view returns (Status) {
        Marketplace storage marketplace = marketplacesYoa[index];
        if (marketplace.buyer != address(0)) {
            return Status.finished;
        } else {
            return Status.active;
        }
    }

    function getCurrentBidOwner(uint256 auctionIndex) public view returns (address) { return auctions[auctionIndex].currentBidOwner; }
    
    function getPaymentWallet(uint256 auctionIndex) public view returns (address) { return auctions[auctionIndex].paymentWallet; }
    
    function getCurrentBidAmount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].currentBidAmount; }

    function getBidCount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].bidCount; }

    function getWinner(uint256 auctionIndex) public view returns (address) {
        require(isFinished(auctionIndex));
        return auctions[auctionIndex].currentBidOwner;
    }    

    function claimTokens(uint256 auctionIndex) public { 
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];
        
        require(auction.creator == msg.sender);
        auction.paymentWallet.transfer(auction.currentBidAmount);

        emit Claim(auctionIndex, auction.creator);
    }

    function claimAsset(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];
        
        address winner = getWinner(auctionIndex);
        require(winner == msg.sender);
        
        ERC721 asset = ERC721(auction.assetAddress);
        asset.transferFrom(auction.creator, winner, auction.assetId);

        emit Claim(auctionIndex, winner);
    }
}