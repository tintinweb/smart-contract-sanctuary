/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.4.2;


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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract AuctionEngine {
    using SafeMath for uint256;

    // event AuctionCreated(uint256 _index, address _creator, address _asset, address _token);
    event AuctionCreated(uint256 _index, address _creator, address _asset);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
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
    Auction[] private auctions;

    function createAuction(address _assetAddress,
                           uint256 _assetId,
                           address _paymentWallet,
                           uint256 _startPrice, 
                           uint256 _startTime, 
                           uint256 _duration) public returns (uint256) {
        

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

        // emit AuctionCreated(index, auction.creator, auction.assetAddress, auction.tokenAddress);
        emit AuctionCreated(index, auction.creator, auction.assetAddress);
        
        return index;
    }

    function bid(uint256 auctionIndex) public payable returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator != address(0));
        require(isActive(auctionIndex));
        
        if (msg.value > auction.currentBidAmount) {
            // we got a better bid. Return tokens to the previous best bidder
            // and register the sender as `currentBidOwner`
            // ERC20 token = ERC20(auction.tokenAddress);
            // require(token.transferFrom(msg.sender, address(this), amount));
            
            if (auction.currentBidAmount != 0) {
                // return funds to the previuos bidder
                auction.currentBidOwner.transfer(auction.currentBidAmount);
                // token.transfer(
                //     auction.currentBidOwner, 
                //     auction.currentBidAmount
                // );
            }
            // register new bidder
            auction.currentBidAmount = msg.value;
            auction.currentBidOwner = msg.sender;
            auction.bidCount = auction.bidCount.add(1);
            
            emit AuctionBid(auctionIndex, msg.sender, msg.value);
            return true;
        }
        return false;
    }

    function getTotalAuctions() public view returns (uint256) { return auctions.length; }

    function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }
    
    function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }
    
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
        address auctionSeller = auction.paymentWallet;
        
        require(auction.creator == msg.sender);
        // ERC20 token = ERC20(auction.tokenAddress);
        require(auction.paymentWallet.send(auction.currentBidAmount));
        // require(token.transfer(auction.creator, auction.currentBidAmount));
        
        emit Claim(auctionIndex, auction.creator);
    }
}