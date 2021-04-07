# @version ^0.2.0
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


event toPay:
    value: uint256


event increased:
    value: uint256
    newEnd: uint256


# Variables
owner: public(address)
incentives: public(uint256)
lastBlock: public(uint256)
endBlock: public(uint256)
totalStaked: public(uint256)
paidPerToken: public(uint256)

# Holdings
holdings: HashMap[address, uint256]
compactor: HashMap[address, uint256]
userRewardsPaid: public(HashMap[address, uint256])

# # Set up the owner.
# @external
# def __init__(_owner: address):
#     self.owner = _owner

@payable
@external
def take_owner():
    assert self.owner == 0x0000000000000000000000000000000000000000
    
    self.owner = msg.sender
    self.lastBlock = block.number 

    self.totalStaked += msg.value
    self.holdings[msg.sender] += msg.value
    self.compactor[msg.sender] += msg.value * self.paidPerToken

    log Dep(msg.sender, msg.value)



@internal
def updateRewards():
    
    # Formula
    # a = (self.incentives)/(self.endBlock - self.lastBlock)
    # b = -(self.incentives*self.lastBlock)/(self.endBlock - self.lastBlock)
    # (self.incentives * (block.number+self.lastBlock))/(self.endBlock - self.lastBlock)

    # Then subtract the last calcultion
    # Which gives:
    totalToPaid: uint256 = (self.incentives * (min(block.number, self.endBlock) - self.lastBlock))/(self.endBlock - self.lastBlock)
    
    log toPay(totalToPaid)

    self.incentives -= totalToPaid
    self.lastBlock = min(block.number, self.endBlock)

    self.paidPerToken += totalToPaid / max(self.totalStaked, 1)


@view
@external
def viewRewards() -> uint256:
    return (self.incentives * (min(block.number, self.endBlock) - self.lastBlock))/(self.endBlock - self.lastBlock)


# User mangement
@payable
@external
def deposit():
    self.updateRewards()
    self.totalStaked += msg.value
    self.holdings[msg.sender] += msg.value
    self.compactor[msg.sender] += msg.value * self.paidPerToken

    log Dep(msg.sender, msg.value)


# Withdraw including rewards pending
@payable
@external
def withdraw(amount: uint256):
    self.updateRewards()
    assert self.holdings[msg.sender] >= amount
    self.holdings[msg.sender] -= amount
    self.totalStaked -= amount

    self.compactor[msg.sender] -= amount * self.paidPerToken
    rewards: uint256 = self.paidPerToken * self.holdings[msg.sender] - self.compactor[msg.sender] - self.userRewardsPaid[msg.sender]

    self.userRewardsPaid[msg.sender] += rewards


    send(msg.sender, amount + rewards)

    log Wit(msg.sender, msg.value, rewards)


# incentives
@payable
@external
def inc_incentives():
    self.updateRewards()
    self.incentives += msg.value

    log increased(msg.value, self.endBlock)


@payable
@external
def incentives_block(end: uint256):
    assert msg.sender == self.owner
    if block.number < self.endBlock:
        self.updateRewards()
    self.incentives += msg.value
    self.endBlock = end

    log increased(msg.value, end)



#Check the balance of the address
@view
@external
def bal(user: address) -> (uint256, uint256):
    totalToPaid: uint256 = (self.incentives * (block.number - self.lastBlock))/(self.endBlock - self.lastBlock)


    return (
        self.holdings[user],
        (self.paidPerToken + totalToPaid / self.totalStaked) * self.holdings[msg.sender] - self.compactor[msg.sender] - self.userRewardsPaid[msg.sender]
        )




# INCASE OF PROBLEMS
@payable
@external
def emergency_withdraw():
    self.compactor[msg.sender] = 0
    self.userRewardsPaid[msg.sender] = 0
    self.totalStaked -= self.holdings[msg.sender]

    send(msg.sender, self.holdings[msg.sender])

    log EmWit(msg.sender, self.holdings[msg.sender])

    self.holdings[msg.sender] = 0