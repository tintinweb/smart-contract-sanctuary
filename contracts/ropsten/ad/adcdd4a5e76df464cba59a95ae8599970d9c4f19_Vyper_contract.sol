struct Bid:
  blindedBid: bytes32
  deposit: uint256

MAX_BIDS: constant(int128) = 128

# Event for logging that auction has ended
event AuctionEnded:
  highestBidder: address
  highestBid: uint256

# Auction parameters
beneficiary: public(address)
biddingEnd: public(uint256)
revealEnd: public(uint256)

# Set to true at the end of auction, disallowing any new bids
ended: public(bool)

# Final auction state
highestBid: public(uint256)
highestBidder: public(address)

# State of the bids
bids: HashMap[address, Bid[128]]
bidCounts: HashMap[address, int128]

# Allowed withdrawals of previous bids
pendingReturns: HashMap[address, uint256]


@external
def __init__(_beneficiary: address, _biddingTime: uint256, _revealTime: uint256):
  self.beneficiary = _beneficiary
  self.biddingEnd = block.timestamp + _biddingTime
  self.revealEnd = self.biddingEnd + _revealTime