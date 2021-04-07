# @version ^0.2.11
# 
#
#
#
#
#
# Events

event Dep:
    user: indexed(address)
    value: uint256

event Wit:
    user: indexed(address)
    value: uint256
    reward: uint256

event EmWit:
    user: indexed(address)
    value: uint256

event increased:
    value: uint256
    newEnd: uint256

event ownerChange:
    old: indexed(address)
    new: indexed(address)


# Variables
owner: public(address)
lastBlock: public(uint256)
endBlock: public(uint256)
totalStaked: public(uint256)
paidPerToken: public(uint256)

# Holdings
holdings: HashMap[address, uint256]
compactor: HashMap[address, int128]
userRewardsPaid: public(HashMap[address, uint256])

# # Set up the owner.
@external
def __init__():
    self.owner = msg.sender


# Let the owner set the  to another account
@external
def transferOwner(_owner: address):
    assert self.owner == msg.sender

    log ownerChange(self.owner, _owner)
    self.owner = _owner


# Internal funtcion to calculate the reward that has been paid according to a linear payout
@view
@internal
def _totalToPaid() -> uint256:
    # Formula
    # a = ((self.balance - self.totalStaked))/(self.endBlock - self.lastBlock)
    # b = -((self.balance - self.totalStaked)*self.lastBlock)/(self.endBlock - self.lastBlock)
    # ((self.balance - self.totalStaked) * (block.number+self.lastBlock))/(self.endBlock - self.lastBlock)

    # Then subtract the last calcultion
    # Which gives:
    if self.endBlock == 0:
        return 0
    elif self.endBlock > self.lastBlock:
        return ((self.balance - self.totalStaked) * (min(block.number, self.endBlock) - self.lastBlock))/(self.endBlock - self.lastBlock) * 10**6
    else:
        return (self.balance - self.totalStaked)


# Update the internal bookkeeping. We cannot allow changes to the contract without it first having appeared here.
@internal
def updateRewards():
    if block.number > self.lastBlock:
        totalToPaid: uint256 = self._totalToPaid()  # Remember that this value is * 10**6
        
        self.lastBlock = min(block.number, self.endBlock)
        self.paidPerToken += (totalToPaid) / max(self.totalStaked, 1000000) 


# User mangement
@payable
@external
def deposit():
    self.updateRewards()
    self.totalStaked += msg.value
    self.holdings[msg.sender] += msg.value
    self.compactor[msg.sender] += convert(msg.value * self.paidPerToken, int128)/10**6

    log Dep(msg.sender, msg.value)


# Withdraw including rewards pending
@payable
@external
def withdraw(_amount: uint256):
    self.updateRewards()
    
    rewards: uint256 = convert(
        convert(
            self.paidPerToken * self.holdings[msg.sender]/10**6 - self.userRewardsPaid[msg.sender], int128)
             - self.compactor[msg.sender], uint256
             )  # Rewards are always positive.

    self.userRewardsPaid[msg.sender] += rewards

    amount: uint256 = min(self.holdings[msg.sender], _amount)
    
    self.holdings[msg.sender] -= amount
    self.totalStaked -= amount

    self.compactor[msg.sender] -= convert(amount * self.paidPerToken, int128)/10**6

    send(msg.sender, amount)
    send(msg.sender, rewards)

    log Wit(msg.sender, msg.value, rewards)


# Allows increases to the balance
@payable
@external
def incIncentives():
    self.updateRewards()

    log increased(msg.value, self.endBlock)


# Set the endblock and allows increases to to the balance
@payable
@external
def incentivesBlock(end: uint256):
    assert msg.sender == self.owner
    assert end > self.endBlock  # The owner should not be able to accelerate the rewards paid out
    self.lastBlock = block.number
    if block.number < self.endBlock:
        self.updateRewards()
    self.endBlock = end

    log increased(msg.value, end)



#Check the balance of the address and rewards
@view
@external
def bal(user: address) -> (uint256, uint256):
    rewards: uint256 = 0
    if block.number > self.lastBlock:
        rewards = convert(
        convert(
            (self.paidPerToken + self._totalToPaid() / max(self.totalStaked, 1000000)) * self.holdings[user]/10**6 - self.userRewardsPaid[user], int128)
             - self.compactor[user], uint256
             )  # Rewards are always positive. If less than 1000000 units have been deposited, then the rewards are paid out more slowly.
    else:
        rewards = convert(
        convert(
            (self.paidPerToken) * self.holdings[user]/10**6 - self.userRewardsPaid[user], int128)
             - self.compactor[user], uint256
             )  # Rewards are always positive. If less than 1000000 units have been deposited, then the rewards are paid out more slowly.

    return (
        self.holdings[user], rewards
        )




# This functions returns the user's deposit without any consideration for the fee logic. It also resets the user's storage.
@payable
@external
def emergencyWithdraw():
    send(msg.sender, self.holdings[msg.sender])

    log EmWit(msg.sender, self.holdings[msg.sender])

    self.compactor[msg.sender] = 0
    self.userRewardsPaid[msg.sender] = 0
    self.totalStaked -= self.holdings[msg.sender]
    self.holdings[msg.sender] = 0