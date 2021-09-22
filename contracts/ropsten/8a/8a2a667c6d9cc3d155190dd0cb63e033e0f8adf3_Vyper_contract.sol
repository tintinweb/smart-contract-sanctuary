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


@external
@payable
def bid(_blindedBid: bytes32):
  assert block.timestamp < self.biddingEnd

  numBids: int128 = self.bidCounts[msg.sender]
  assert numBids < MAX_BIDS

  self.bids[msg.sender][numBids] = Bid({
    blindedBid: _blindedBid,
    deposit: msg.value
  })

  self.bidCounts[msg.sender] += 1

@internal
def placeBid(bidder: address, _value: uint256) -> bool:
  # If bid is less than highest bid, bid fails
  if (_value <= self.highestBid):
    return False
  
  # Refund the previously highest_bidder
  if (self.highestBidder != ZERO_ADDRESS):
    self.pendingReturns[self.highestBidder] += self.highestBid
  
  # Place bid successfully and update auction state
  self.highestBid = _value
  self.highestBidder = bidder

  return True

# Reveal Blinded Bids. Get a refund for all correctly blinded
# Invalid bids and for all bids except for totally highest.
@external
def reveal(_numBids: int128, _values: uint256[128], _fakes: bool[128], _secrets: bytes32[128]):
  # Check that bidding period is over
  assert block.timestamp > self.biddingEnd

  # Check that reveal end has not passed
  assert block.timestamp < self.revealEnd

  # Check that number of bids being revealed matches for log for sender
  assert _numBids == self.bidCounts[msg.sender]

  # Calculate refund for sender
  refund: uint256 = 0
  for i in range(MAX_BIDS):
    if (i >= _numBids):
      break
    
    # Get bid to check
    bidToCheck: Bid = (self.bids[msg.sender])[i]

    # Check against encoded packet
    value: uint256 = _values[i]
    fake: bool = _fakes[i]
    secret: bytes32 = _secrets[i]
    blindedBid: bytes32 = keccak256(concat(
      convert(value, bytes32),
      convert(fake, bytes32),
      secret
    ))
    
    # Bid was not actually revealed
    # Do not refund deposit
    if (blindedBid != bidToCheck.blindedBid):
      assert 1 == 0
      continue
    
    # Add deposit to refund if bid was indeed revealed
    refund += bidToCheck.deposit
    if (not fake and bidToCheck.deposit >= value):
      if (self.placeBid(msg.sender, value)):
        refund -= value
    
    # Make it impossible for the sender to re-claim the same deposit
    zeroBytes32: bytes32 = EMPTY_BYTES32
    bidToCheck.blindedBid = zeroBytes32
  
  # Send refund if non-zero
  if (refund != 0):
    send(msg.sender, refund)

# Withdraw a bid that was overbid.
@external
def withdraw():
  # Check that there is an allowed pending return.
  pendingAmount: uint256 = self.pendingReturns[msg.sender]
  if (pendingAmount > 0):
    self.pendingReturns[msg.sender] = 0
    send(msg.sender, pendingAmount)

# End the auction and send the highest bid to the beneficiary
@external
def auctionEnd():
  # Check that reveal end has passed
  assert block.timestamp > self.revealEnd

  # Check that auction has not already been marked as ended
  assert not self.ended

  # Log auction ending and set flag
  log AuctionEnded(self.highestBidder, self.highestBid)
  self.ended = True

  # Transfer funds to beneficiary
  send(self.beneficiary, self.highestBid)