#------------------------------------------------------------------------------
#
#   Copyright 2019 Fetch.AI Limited
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#------------------------------------------------------------------------------
from vyper.interfaces import ERC20


# maximum possible number of stakers a new auction can specify
MAX_SLOTS: constant(uint256) = 200
# number of blocks during which the auction remains open at reserve price
RESERVE_PRICE_DURATION: constant(uint256) = 25  # number of blocks
# number of seconds before deletion of the contract becomes possible after last lockupEnd() call
DELETE_PERIOD: constant(uint256) = 60 * (3600 * 24)
# defining the decimals supported in pool rewards per token
REWARD_PER_TOK_DENOMINATOR: constant(uint256) = 100000

@internal
def as_unitless_number (x: uint256) -> uint256: 
    return x

# Structs
struct Auction:
    finalPrice: uint256
    lockupEnd: uint256
    slotsSold: uint256
    start: uint256
    end: uint256
    startStake: uint256
    reserveStake: uint256
    declinePerBlock: uint256
    slotsOnSale: uint256
    rewardPerSlot: uint256
    uniqueStakers: uint256

struct VirtTokenHolder:
    isHolder: bool
    limit: uint256
    rewards: uint256

# Events
event Bid:
    AID: uint256
    _from: indexed(address)
    currentPrice: uint256
    amount: uint256
event BidTest: 
    totaltok: uint256

event NewAuction: 
    AID: uint256
    start: uint256
    end: uint256
    lockupEnd: uint256
    startStake: uint256
    reserveStake: uint256
    declinePerBlock: uint256
    slotsOnSale: uint256
    rewardPerSlot: uint256
    
event AuctionFinalised: 
    AID: uint256
    finalPrice: uint256
    slotsSold: uint256
event LockupEnded: 
    AID: uint256
event AuctionAborted: 
    AID: uint256
    rewardsPaid: bool
event SelfStakeWithdrawal: 
    _from: indexed(address)
    amount: uint256
event PledgeWithdrawal: 
    _from: indexed(address)
    amount: uint256

# Contract state
token: ERC20
owner: public(address)
earliestDelete: public(uint256)

# address -> uint256 Slots a staker has won in the current auction (cleared at endLockup())
stakerSlots: HashMap[address, uint256]

# auction winners
stakers: address[MAX_SLOTS]

# pledged stake + committed pool reward, excl. selfStakerDeposit; pool -> deposits
poolDeposits: public(HashMap[address, uint256])

# staker (directly) -> amount
selfStakerDeposits: public(HashMap[address, uint256])

# staker (directly) -> price at which the bid was made
priceAtBid: public(HashMap[address, uint256])

# Auction details
currentAID: public(uint256)
auction: public(Auction)
totalAuctionRewards: public(uint256)

# Virtual token management
virtTokenHolders: public(HashMap[address, VirtTokenHolder])

################################################################################
# Constant functions
################################################################################
# @notice True from auction initialisation until either we hit the lower bound on being clear or
#   the auction finalised through finaliseAuction()
@internal
@view
def _isBiddingPhase() -> bool:
    return ((self.auction.lockupEnd > 0)
            and (block.number < self.auction.end)
            and (self.auction.slotsSold < self.auction.slotsOnSale)
            and (self.auction.finalPrice == 0))

# @notice Returns true if either the auction has been finalised or the lockup has ended
# @dev self.auction will be cleared in endLockup() call
# @dev reserveStake > 0 condition in initialiseAuction() guarantees that finalPrice = 0 can never be
#   a valid final price
@internal
@view
def _isFinalised() -> bool:
    return (self.auction.finalPrice > 0) or (self.auction.lockupEnd == 0)

# @notice Calculate the scheduled, linearly declining price of the dutch auction
@internal
@view
def _getScheduledPrice() -> uint256:
    startStake_: uint256 = self.auction.startStake
    start: uint256 = self.auction.start
    if (block.number <= start):
        return startStake_
    else:
        # do not calculate max(startStake - decline, reserveStake) as that could throw on negative startStake - decline
        decline: uint256 = min(self.auction.declinePerBlock * (block.number - start),
                                    startStake_ - self.auction.reserveStake)
        return startStake_ - decline

# @notice Returns the scheduled price of the auction until the auction is finalised. Then returns
#   the final price.
# @dev Auction price declines linearly from auction.start over _duration, then
# stays at _reserveStake for RESERVE_PRICE_DURATION
# @dev Returns zero If no auction is in bidding or lock-up phase
@internal
@view
def _getCurrentPrice() -> (uint256):
    if self._isFinalised():
        return self.auction.finalPrice
    else:
        scheduledPrice: uint256 = self._getScheduledPrice()
        return scheduledPrice

# @notice Returns the lockup needed by an address that stakes directly
# @dev Will throw if _address is a bidder in current auction & auciton not yet finalised, as the
#   slot number & price are not final yet
# @dev Calling endLockup() will clear all stakerSlots flags and thereby set the required
#   lockups to 0 for all participants
@internal
@view
def _calculateSelfStakeNeeded(_address: address) -> uint256:
    selfStakeNeeded: uint256 = 0
    # these slots can be outdated if auction is not yet finalised / lockup hasn't ended yet
    slotsWon: uint256 = self.stakerSlots[_address]

    if slotsWon > 0:
        assert self._isFinalised(), "Is bidder and auction not finalised yet"
        poolDeposit: uint256 = self.poolDeposits[_address]
        currentPrice: uint256 = self._getCurrentPrice()

        if (slotsWon * currentPrice) > poolDeposit:
            selfStakeNeeded += (slotsWon * currentPrice) - poolDeposit
    return selfStakeNeeded

################################################################################
# Main functions
################################################################################
@external
def __init__(_ERC20Address: address):
    self.owner = msg.sender
    self.token = ERC20(_ERC20Address)

# @notice Owner can initialise new auctions
# @dev First auction starts with AID 1
# @dev Requires the transfer of _reward to the contract to be approved with the
#   underlying ERC20 token
# @param _start: start of the price decay
# @param _startStake: initial auction price
# @param _reserveStake: lowest possible auction price >= 1
# @param _duration: duration over which the auction price declines. Total bidding
#   duration is _duration + RESERVE_PRICE_DURATION
# @param _lockup_duration: number of blocks the lockup phase will last
# @param _slotsOnSale: size of the assembly in this cycle
# @param _reward: added to any remaining reward of past auctions
@external
def initialiseAuction(_start: uint256,
                      _startStake: uint256,
                      _reserveStake: uint256,
                      _duration: uint256,
                      _lockup_duration: uint256,
                      _slotsOnSale: uint256,
                      _reward: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert _startStake > _reserveStake, "Invalid startStake"
    assert (_slotsOnSale > 0) and (_slotsOnSale <= MAX_SLOTS), "Invald slot number"
    assert _start >= block.number, "Start before current block"
    # NOTE: _isFinalised() relies on this requirement
    assert _reserveStake > 0, "Reserve stake has to be at least 1"
    assert self.auction.lockupEnd == 0, "End current auction"
    self.currentAID += 1

    # Use integer-ceil() of the fraction with (+ _duration - 1)
    declinePerBlock: uint256 = (_startStake - _reserveStake + _duration - 1) / _duration
    end: uint256 = _start + _duration + RESERVE_PRICE_DURATION
    self.auction.start = _start
    self.auction.end = end
    self.auction.lockupEnd = end + _lockup_duration
    self.auction.startStake = _startStake
    self.auction.reserveStake = _reserveStake
    self.auction.declinePerBlock = declinePerBlock
    self.auction.slotsOnSale = _slotsOnSale
    # Also acts as the last checked price in _updatePrice()
    self.auction.finalPrice = 0

    # add auction rewards
    self.totalAuctionRewards += _reward
    self.auction.rewardPerSlot = self.totalAuctionRewards / self.auction.slotsOnSale
    success: bool = self.token.transferFrom(msg.sender, self, self.as_unitless_number(_reward))
    assert success, "Transfer failed"

    log NewAuction(self.currentAID, _start, end, end + _lockup_duration, _startStake,
                   _reserveStake, declinePerBlock, _slotsOnSale, self.auction.rewardPerSlot)

# @notice Move unclaimed auction rewards back to the contract owner
# @dev Requires that no auction is in bidding or lockup phase
@external
def retrieveUndistributedAuctionRewards():
    assert msg.sender == self.owner, "Owner only"
    assert self.auction.lockupEnd == 0, "Auction ongoing"
    undistributed: uint256 = self.totalAuctionRewards
    self.totalAuctionRewards = empty(uint256)

    success: bool = self.token.transfer(self.owner, self.as_unitless_number(undistributed))
    assert success, "Transfer failed"

# @notice Enter a bid into the auction. Requires the sender's deposits + _topup >= currentPrice or
#   specify _topup = 0 to automatically calculate and transfer the topup needed to make a bid at the
#   current price. Beforehand the sender must have approved the ERC20 contract to allow the transfer
#   of at least the topup to the auction contract via ERC20.approve(auctionContract.address, amount)
# @param _topup: Set to 0 to bid current price (automatically calculating and transfering required topup),
#   o/w it will be interpreted as a topup to the existing deposits
# @dev Only one bid per address and auction allowed, as time of bidding also specifies the priority
#   in slot allocation
# @dev No bids below current auction price allowed
@external
def bid(_topup: uint256):
    assert self._isBiddingPhase(), "Not in bidding phase"
    assert self.stakerSlots[msg.sender] == 0, "Sender already bid"

    _currentAID: uint256 = self.currentAID
    currentPrice: uint256 = self._getCurrentPrice()
    _isVirtTokenHolder: bool = self.virtTokenHolders[msg.sender].isHolder

    assert (_isVirtTokenHolder == False) or (_topup <= self.virtTokenHolders[msg.sender].limit), "Virtual tokens above limit"

    totDeposit: uint256 = self.selfStakerDeposits[msg.sender]

    # cannot modify input argument
    topup: uint256 = _topup
    if (currentPrice > totDeposit) and(_topup == 0):
        topup = currentPrice - totDeposit
    else:
        assert totDeposit + topup >= currentPrice, "Bid below current price"

    # Update deposits & stakers
    self.priceAtBid[msg.sender] = currentPrice
    self.selfStakerDeposits[msg.sender] += topup
    slots: uint256 = min((totDeposit + topup) / currentPrice, self.auction.slotsOnSale - self.auction.slotsSold)
    self.stakerSlots[msg.sender] = slots
    self.auction.slotsSold += slots
    self.stakers[self.auction.uniqueStakers] = msg.sender
    self.auction.uniqueStakers += 1

    # Transfer topup if necessary
    if (topup > 0) and (_isVirtTokenHolder == False):
        success: bool = self.token.transferFrom(msg.sender, self, self.as_unitless_number(topup))
        assert success, "Transfer failed"
    log Bid(_currentAID, msg.sender, currentPrice, totDeposit + topup)

# @Notice Anyone can supply the correct final price to finalise the auction and calculate the number of slots each
#   staker has won. Required before lock-up can be ended or withdrawals can be made
# @param finalPrice: proposed solution for the final price. Throws if not the correct solution
# @dev Allows to move the calculation of the price that clear the auction off-chain
@external
def finaliseAuction(finalPrice: uint256):
    currentPrice: uint256 = self._getCurrentPrice()
    assert finalPrice >= currentPrice, "Suggested solution below current price"
    assert self.auction.finalPrice == 0, "Auction already finalised"
    assert self.auction.lockupEnd >= 0, "Lockup has already ended"

    slotsOnSale: uint256 = self.auction.slotsOnSale
    slotsRemaining: uint256 = slotsOnSale
    slotsRemainingP1: uint256 = slotsOnSale
    finalPriceP1: uint256 = finalPrice + 1

    uniqueStakers_int128: int128 = convert(self.auction.uniqueStakers, int128)
    staker: address = ZERO_ADDRESS
    totDeposit: uint256 = 0
    slots: uint256 = 0
    currentSlots: uint256 = 0
    _priceAtBid: uint256= 0

    for i in range(MAX_SLOTS):
        if i >= uniqueStakers_int128:
            break

        staker = self.stakers[i]
        _priceAtBid = self.priceAtBid[staker]
        slots = 0

        if finalPrice <= _priceAtBid:
            totDeposit = self.selfStakerDeposits[staker] + self.poolDeposits[staker]

            if slotsRemaining > 0:
                # finalPrice will always be > 0 as reserveStake required to be > 0
                slots = min(totDeposit / finalPrice, slotsRemaining)
                currentSlots = self.stakerSlots[staker]
                if slots != currentSlots:
                    self.stakerSlots[staker] = slots
                slotsRemaining -= slots

            if finalPriceP1 <= _priceAtBid:
                slotsRemainingP1 -= min(totDeposit / finalPriceP1, slotsRemainingP1)

        # later bidders dropping out of slot-allocation as earlier bidders already claim all slots at the final price
        if slots == 0:
            self.stakerSlots[staker] = empty(uint256)
            self.stakers[i] = empty(address)

    if (finalPrice == self.auction.reserveStake) and (self._isBiddingPhase() == False):
        # a) reserveStake clears the auction and reserveStake + 1 does not
        doesClear: bool = (slotsRemaining == 0) and (slotsRemainingP1 > 0)
        # b) reserveStake does not clear the auction, accordingly neither will any other higher price
        assert (doesClear or (slotsRemaining > 0)), "reserveStake is not the best solution"
    else:
        assert slotsRemaining == 0, "finalPrice does not clear auction"
        assert slotsRemainingP1 > 0, "Not largest price clearing the auction"

    self.auction.finalPrice = finalPrice
    self.auction.slotsSold = slotsOnSale - slotsRemaining
    log AuctionFinalised(self.currentAID, finalPrice, slotsOnSale - slotsRemaining)

# @notice Anyone can end the lock-up of an auction, thereby allowing everyone to
#   withdraw their stakes and rewards. Auction must first be finalised through finaliseAuction().
@internal
def _endLockup(payoutRewards: bool):
    assert self.auction.lockupEnd > 0, "No lockup to end"

    slotsSold: uint256 = self.auction.slotsSold
    rewardPerSlot_: uint256 = 0
    self.earliestDelete = block.timestamp + DELETE_PERIOD

    if payoutRewards:
        assert self._isFinalised(), "Not finalised"
        rewardPerSlot_ = self.auction.rewardPerSlot
        self.totalAuctionRewards -= slotsSold * rewardPerSlot_

    # distribute rewards & cleanup
    staker: address = ZERO_ADDRESS

    for i in range(MAX_SLOTS):
        staker = self.stakers[i]
        if staker == ZERO_ADDRESS:
            break

        if payoutRewards:
            if self.virtTokenHolders[staker].isHolder:
                self.virtTokenHolders[staker].rewards += self.stakerSlots[staker] * rewardPerSlot_
            else:
                self.selfStakerDeposits[staker] += self.stakerSlots[staker] * rewardPerSlot_

        self.stakerSlots[staker] = empty(uint256)
        if self.virtTokenHolders[staker].isHolder:
            self.selfStakerDeposits[staker] = empty(uint256)

    self.stakers = empty(address[MAX_SLOTS])
    self.auction = empty(Auction)

@external
def endLockup():
    # Prevents repeated calls of this function as self.auction will get reset here
    assert self.auction.finalPrice > 0, "Auction not finalised yet or no auction to end"
    assert block.number >= self.auction.lockupEnd, "Lockup not over"
    self._endLockup(True)
    log LockupEnded(self.currentAID)

# @notice The owner can clear the auction and all recorded slots in the case of an emergency and
# thereby immediately lift any lockups and allow the immediate withdrawal of any made deposits.
# @param payoutRewards: whether rewards get distributed to bidders
@external
def abortAuction(payoutRewards: bool):
    assert msg.sender == self.owner, "Owner only"

    self._endLockup(payoutRewards)
    log AuctionAborted(self.currentAID, payoutRewards)

# @notice Withdraw any self-stake exceeding the required lockup. In case sender is a bidder in the
#   current auction, this requires the auction to be finalised through finaliseAuction(),
#   o/w _calculateSelfStakeNeeded() will throw
@external
def withdrawSelfStake() -> uint256:
    # not guaranteed to be initialised to 0 without setting it explicitly
    withdrawal: uint256 = 0

    if self.virtTokenHolders[msg.sender].isHolder:
        withdrawal = self.virtTokenHolders[msg.sender].rewards
        self.virtTokenHolders[msg.sender].rewards = empty(uint256)
    else:
        selfStake: uint256 = self.selfStakerDeposits[msg.sender]
        selfStakeNeeded: uint256 = self._calculateSelfStakeNeeded(msg.sender)

        if selfStake > selfStakeNeeded:
            withdrawal = selfStake - selfStakeNeeded
            self.selfStakerDeposits[msg.sender] -= withdrawal
        elif selfStake < selfStakeNeeded:
            assert False, "Critical failure"

    success: bool = self.token.transfer(msg.sender, self.as_unitless_number(withdrawal))
    assert success, "Transfer failed"

    log SelfStakeWithdrawal(msg.sender, withdrawal)

    return withdrawal

# @notice Allow the owner to remove the contract, given that no auction is
#   active and at least DELETE_PERIOD blocks have past since the last lock-up end.
@external
def deleteContract():
    assert msg.sender == self.owner, "Owner only"
    assert self.auction.lockupEnd == 0, "In lockup phase"
    assert block.timestamp >= self.earliestDelete, "earliestDelete not reached"

    contractBalance: uint256 = self.token.balanceOf(self)
    success: bool = self.token.transfer(self.owner, contractBalance)
    assert success, "Transfer failed"

    selfdestruct(self.owner)

# @notice Allow the owner to set virtTokenHolder status for addresses, allowing them to participate
#   with virtual tokens
# @dev Throws if the address has existing selfStakerDeposits, active slots, a registered pool for
#   this auction, unretrieved pool rewards or existing pledges
# @param _address: address for which to set the value
# @param _isVirtTokenHolder: new value indicating whether isVirtTokenHolder or not
# @param preserveRewards: if setting isVirtTokenHolder to false and that address still has remaining rewards:
#   whether to move those rewards into selfStakerDeposits or to add them back to the control of the owner
#   by adding them to totalAuctionRewards
@external
def setVirtTokenHolder(_address: address, _isVirtTokenHolder: bool, limit: uint256, preserveRewards: bool):
    assert msg.sender == self.owner, "Owner only"
    assert self.stakerSlots[_address] == 0, "Address has active slots"
    assert self.selfStakerDeposits[_address] == 0, "Address has positive selfStakerDeposits"
    # assert self.registeredPools[_address].remainingReward == 0, "Address has remainingReward"
    # assert self.pledges[_address].amount == 0, "Address has positive pledges"
    # assert (self.registeredPools[_address].AID < self.currentAID) or (self.auction.finalPrice == 0), "Address has a pool in ongoing auction"

    existingRewards: uint256 = self.virtTokenHolders[_address].rewards

    if (_isVirtTokenHolder == False) and (existingRewards > 0):
        if preserveRewards:
            self.selfStakerDeposits[_address] += existingRewards
        else:
            self.totalAuctionRewards += existingRewards
        self.virtTokenHolders[_address].rewards = empty(uint256)

    self.virtTokenHolders[_address].isHolder = _isVirtTokenHolder
    self.virtTokenHolders[_address].limit = limit

@external
def setVirtTokenLimit(_address: address, _virtTokenLimit: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert self.virtTokenHolders[_address].isHolder, "Not a virtTokenHolder"
    self.virtTokenHolders[_address].limit = _virtTokenLimit

################################################################################
# Getters
################################################################################
@external
@view
def getERC20Address() -> address:
    return self.token.address

@external
@view
def getDenominator() -> uint256:
    return REWARD_PER_TOK_DENOMINATOR

@external
@view
def getFinalStakerSlots(staker: address) -> uint256:
    assert self._isFinalised(), "Slots not yet final"
    return self.stakerSlots[staker]

# @dev Always returns an array of MAX_SLOTS with elements > unique bidders = zero
@external
@view
def getFinalStakers() -> address[MAX_SLOTS]:
    assert self._isFinalised(), "Stakers not yet final"
    return self.stakers

@external
@view
def getFinalSlotsSold() -> uint256:
    assert self._isFinalised(), "Slots not yet final"
    return self.auction.slotsSold

@external
@view
def getCurrentStakers() -> address[MAX_SLOTS]:
   return self.stakers

@external
@view
def isBiddingPhase() -> bool:
    return self._isBiddingPhase()

@external
@view
def isFinalised() -> bool:
    return self._isFinalised()

@external
@view
def getCurrentPrice() -> uint256:
    return self._getCurrentPrice()

@external
@view
def calculateSelfStakeNeeded(_address: address) -> uint256:
    return self._calculateSelfStakeNeeded(_address)