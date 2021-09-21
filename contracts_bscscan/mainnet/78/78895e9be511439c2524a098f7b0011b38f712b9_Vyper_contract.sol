#@version ^0.2.0

"""
@title Crypto Flex Club : The Most Exclusive Crypto Club
@license MIT
@author cryptoflexclub team
"""
#only 100 Members in the crypto flex club
MAXMEMBERS: constant (int128) = 100

#emitted when a participant withdraw pending refunds
event Withdraw:
    addr: indexed(address)
    amount: uint256

#emitted when a participant becomes the profile holder: winner of vieForProfile()
event Win:
    addr: indexed(address)
    amount: uint256

#emitted when a participant joins the crypto flex club. All requirements must be met
event JoinClub:
    memberIndex: int128
    addr: address

#emitted when the current profile holder steps down
event StepDown:
    addr: indexed(address)
    amount: uint256

#the data structure to hold current profile holder details
struct ProfileHolder:
    addr: address
    timeWon: uint256
    amount: uint256
    status: String[300]

#Info about a participant
struct AccountInfo:
    membership: bool
    pendingRefund: uint256
    membershipPeriod: uint256
    timeRemaining: uint256

#Info about the crypto flex club - club stats
struct ClubInfo:
    numMembers: int128
    currentStake: uint256
    theRequiredMembershipPeriod: uint256
    thePlatformFee: uint256

#Only one profile holder at a time. The previous profile holder is overwritten
#Info about previous holders can be retrieved using the Win event
profile: (ProfileHolder)

#to track refunds when a profile holder is removed by a higher stake
#only the depositor can withdraw these funds
pendingRefunds: (HashMap[address, uint256])

#to track the club members. member - True
#If not in the HashMap, will return False
members: (HashMap[address, bool])

#to track the number of members in the crypto flex club
currentMemberIndex: (int128)

#the minimum stake required to be a profile holder
minimumStake: (uint256)

#the minimum active profile period required
#to be able to join the club
#It can be updated by the dev team
#It increments by timeToAdd when a participant joins the club
requiredMembershipPeriod: (uint256)

#the period to add when a participant joins the club
#It can be updated by the dev team
timeToAdd: (uint256)

#to track the cumulative active profile period
#if a participant is the profile holder for 30 secs today
#and another time for 2 minutes, then the active profile
#period is 150 seconds
#It is only updated when the profile holder is dethrone
#Also when the current profile holder steps down
membershipPeriodTracker: (HashMap[address, uint256])

#the dev account to receive collected fees
#can perform update actions
#can be replaced : transfer ownership
treasuryAccount: address

#the fee charged when becoming the profile holder /
#when updating status
#since it is uint256, divided by 1000 instaed of 100 to get %
#set to 1 for 0.1% fee or 10 for 1%
platformFee: (uint256)

#keep track of collected fees and direct value transfers to the
#contract address
#dev team can only access the collectedFees and not deposited funds
collectedFees: (uint256)

#the status to be displayed when there is no profile holder
#i.e when the current profile holder steps down
defaultStatus: String[300]

#Initialize the minimumStake, requiredMembershipPeriod, timeToAdd
#platformFee and defaultStatus
@external
def __init__(_minimumStake: uint256, _requiredMembershipPeriod: uint256, _timeToAdd: uint256, _platformFee: uint256, _defaultStatus: String[300]):
    self.minimumStake = _minimumStake
    self.requiredMembershipPeriod = _requiredMembershipPeriod
    self.timeToAdd = _timeToAdd
    self.platformFee = _platformFee
    self.treasuryAccount = msg.sender
    self.defaultStatus = _defaultStatus
    #initialize the profile
    self.profile = ProfileHolder({
        addr: ZERO_ADDRESS,
        timeWon: block.timestamp,
        amount: self.minimumStake,
        status: self.defaultStatus
    })

#Allows a participant to become the current profile holder
#The value sent must be greater than the current stake + platform fees
#The current profile holder is refunded and profile active period tracked
#The profile is updated to match the details of the new holder
#Tracks the collectedFees
@external
@payable
def vieForProfile(_status: String[300]) -> bool:

    #sent value minus platform fees
    _platformFee: uint256 = (self.platformFee * msg.value) / convert(1000, uint256)
    sentValue: uint256 = msg.value - _platformFee
    #check if sentValue > minimumStake
    assert sentValue >= self.minimumStake, "Value < Minimum Stake"

    #check if there is a profile already
    if self.profile.addr != ZERO_ADDRESS:
        #check if value > than current highest
        assert sentValue > self.profile.amount, "Stake Lower than Current"

        #refund the current holder
        self.pendingRefunds[self.profile.addr] += self.profile.amount

        #track the membership period for current holder
        self.membershipPeriodTracker[self.profile.addr] += block.timestamp - self.profile.timeWon

    #track the platform fees
    self.collectedFees += _platformFee

    #set new profile
    self.profile = ProfileHolder({
        addr: msg.sender,
        timeWon: block.timestamp,
        amount: sentValue,
        status: _status
    })
    #emit Win event - will come in handy when retrieving previous profile holders
    #the profile is overwritten thats why
    log Win(msg.sender, sentValue)

    return True

#Allow a participant to withdraw refunded funds
#Refund must be > 0
#This is the only function allowing participants to get funds from the smart contract
#Only participants with pendingRefunds are elligible
#Dev team can not withdraw user funds on their behalf
@external
def withdraw() -> bool:

    #get the pending refund of participant
    pendingRefund: uint256 = self.pendingRefunds[msg.sender]

    #check if > 0
    assert pendingRefund > convert(0, uint256), "No Pending Refund"

    #set pending refund to 0 (converted to uint256) : literals are int128 by default
    self.pendingRefunds[msg.sender] = convert(0, uint256)

    #transfer the pending refund to the participant
    send(msg.sender, pendingRefund)

    #emit a Withdraw event
    log Withdraw(msg.sender, pendingRefund)
    return True

#A current profile holder can step down
#The profile is reset with defaultStatus and minimumStake
#The current profile holder is refunded - funds can only be accessed through withdraw()
#The active profile period is tracked
@external
def stepDown() -> bool:

    #check if msg.sender is current holder
    assert self.profile.addr == msg.sender, "Not Current Holder"

    #get the current stake
    amount: uint256 = self.profile.amount

    #get the time when the status was updated or profile won
    _profilePeriod: uint256 = self.profile.timeWon

    #rest the current Holder
    self.profile = ProfileHolder({
        addr: ZERO_ADDRESS,
        timeWon: block.timestamp,
        amount: self.minimumStake,
        status: self.defaultStatus
    })
    #update pending Refund
    self.pendingRefunds[msg.sender] += amount

    #update membership period
    self.membershipPeriodTracker[msg.sender] += block.timestamp - _profilePeriod

    #emit stepdown event
    log StepDown(msg.sender, amount)

    return True

#Allow members to join the crypto flex club
#Can only be 100 members max
#Must have met the active profile period required (requiredMembershipPeriod)
#Can only join once
#Increments the currentMemberIndex by 1. Keeps track of no. of club members
#Increments the requiredMembershipPeriod by timeToAdd
@external
def joinClub() -> bool:

    #check if membership period attained
    membershipPeriod: uint256 = self.membershipPeriodTracker[msg.sender]
    assert membershipPeriod >= self.requiredMembershipPeriod, "Membership Period Not Attained"

    #check if already a member
    assert self.members[msg.sender] == False, "Already A Member!"

    #check if max members reached
    assert self.currentMemberIndex < MAXMEMBERS, "Members Club Is Full!"

    #increment no. of members
    self.currentMemberIndex += 1

    #increment active profile period required by timeToAdd
    self.requiredMembershipPeriod += self.timeToAdd

    #add new member
    self.members[msg.sender] = True

    #emit JoinClub event
    log JoinClub(self.currentMemberIndex - 1 , msg.sender)
    return True

#returns the time in seconds before a member can join the club
#requiredMembershipPeriod - active profile period 
#returns 0 if time is required is exceeded or is already a member
@view
@internal
def _checkPeriodRemaining(_addr: address) -> uint256:

    #check if period is exceeded or is already a member
    if self.requiredMembershipPeriod <= self.membershipPeriodTracker[_addr] or self.members[_addr]:
        return convert(0, uint256)
    else:
        return self.requiredMembershipPeriod - self.membershipPeriodTracker[_addr]

#returns the cumulative active profile period for a participant
@view
@internal
def _checkMembershipPeriod(_addr: address) -> uint256:
    return  self.membershipPeriodTracker[_addr]

#returns true is a participant is a club member
#returns false when not a club member
@view
@internal
def _checkMembership(_addr: address) -> bool:
    return self.members[_addr]


#returns the details of the current profile holder
#in solidity 0.8.7 can return  a struct
#but we are hardcore python devs, so Vyper it is!
@view
@internal
def _checkCurrentHolder() -> (address, uint256, uint256, String[300]):
    return (self.profile.addr, self.profile.timeWon, self.profile.amount, self.profile.status)

#returns the current stake 
#returns the minimumStake if there is no profile holder
@view
@internal
def _checkCurrentStake() -> uint256:
    if self.profile.addr != ZERO_ADDRESS:
        return self.profile.amount
    else:
        return self.minimumStake

#returns the number of members in the crypto flex club
@view
@internal
def _checkNumMembers() -> int128:
    return self.currentMemberIndex


#external function to call _checkPeriodRemaining(_addr)
#not using msg.sender to give function flexibility
#non participants can check on behalf of participants and club members
@view
@external
def checkPeriodRemaining(_addr: address) -> uint256:
    return self._checkPeriodRemaining(_addr)

#external function to call _checkMembershipPeriod(_addr)
@view
@external
def checkMembershipPeriod(_addr: address) -> uint256:
    return  self._checkMembershipPeriod(_addr)

#external function to call _checkMembership(_addr)
@view
@external
def checkMembership(_addr: address) -> bool:
    return self._checkMembership(_addr)

#external function to call _checkCurrentHolder()
@view
@external
def checkCurrentHolder() -> (address, uint256, uint256, String[300]):
    return self._checkCurrentHolder()

#external function to call _checkCurrentStake()
@view
@external
def checkCurrentStake() -> uint256:
    return self._checkCurrentStake()

#external function to call _checkNumMembers()
@view
@external
def checkNumMembers() -> int128:
    return self._checkNumMembers()

#Returns the information pertaining a participant
#Whether is a member, pendingRefund, total profile 
#active period  and timeRemaining before can join club
#Sol 0.8.7 can return struct, but once again;
#Hardcore python devs
@view
@external
def checkAccountInfo(_addr: address) -> (bool, uint256, uint256, uint256):
    accountInfo: AccountInfo = AccountInfo({
    membership: self._checkMembership(_addr),
    pendingRefund: self.pendingRefunds[_addr],
    membershipPeriod: self._checkMembershipPeriod(_addr),
    timeRemaining: self._checkPeriodRemaining(_addr)
    })
    return (accountInfo.membership, accountInfo.pendingRefund, accountInfo.membershipPeriod, accountInfo.timeRemaining)

#Returns information about the crypto flex club
#No. of members, currentStake, requiredMembershipPeriod
#Before a participant can become a member of the
#most exclusive crypto club
#Lastly the platform fee
@view
@external
def getClubData() -> (int128, uint256, uint256, uint256):
    clubInfo: ClubInfo = ClubInfo({
    numMembers: self._checkNumMembers(),
    currentStake: self._checkCurrentStake(),
    theRequiredMembershipPeriod: self.requiredMembershipPeriod,
    thePlatformFee: self.platformFee
    })
    return (clubInfo.numMembers, clubInfo.currentStake, clubInfo.theRequiredMembershipPeriod, clubInfo.thePlatformFee)

#the default function, similar to fallback fxn in solidity
#called when value is sent directly to the smart contract
#value sent is included in the collected fees
#the devs can return the funds if the sender reaches out
@external
@payable
def __default__():
    self.collectedFees += msg.value

#only the dev account can call this function
#allows the minimumStake, platformFee, requiredMembershipPeriod 
#timeToAdd to be updated
#for fairness, this will performed after the community / club members vote
#will be delegated to the community when governance is implemented and intergrated
@external
def update(_minimumStake: uint256 ,_platformFee: uint256, _requiredMembershipPeriod: uint256, _timeToAdd: uint256) -> bool:
    #only admin
    assert msg.sender == self.treasuryAccount, "Not Authorised"
    self.minimumStake = _minimumStake
    self.platformFee = _platformFee
    self.requiredMembershipPeriod = _requiredMembershipPeriod
    self.timeToAdd = _timeToAdd

    return True

#only the dev account can call this function
#Sets the status when there is no profile holder
@external
def updateDefaultStatus(_status: String[300]) -> bool:
    #only admin
    assert msg.sender == self.treasuryAccount
    self.defaultStatus = _status
    return True

#only the dev team can call this function
#transfers ownership
#sets the treasuryAccount
@external
def updateTreasuryAccount(_addr: address) -> bool:
    #only admin
    assert msg.sender == self.treasuryAccount
    self.treasuryAccount = _addr
    return True

#only the dev team can call this function
#allows the collected fees to be sent to the
#treasury account.
#includes funds sent directly to the smart contract
#amount withdrawn is either less than or equal to collected fees
#amount withdrawn is deducted from collected fees
@external
def collectFees(_amount: uint256) -> bool:
    #only admin
    assert msg.sender == self.treasuryAccount
    amount : uint256 = 0

    #check if amount is less than or equal to the collected fees
    if _amount <= self.collectedFees:
        amount = _amount
    else:
        amount = self.collectedFees
    
    #deduct amount withdrawn
    self.collectedFees -= amount

    #transfer amount to treasury account
    send(msg.sender, amount)

    #emit withdraw event
    log Withdraw(msg.sender, amount)

    return True