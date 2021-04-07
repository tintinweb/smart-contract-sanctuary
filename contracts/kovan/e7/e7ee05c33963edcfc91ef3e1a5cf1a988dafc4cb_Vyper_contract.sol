# We only have 1 event

event TXout:
    receiver: indexed(address)
    value: uint256


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


# We only need to track the owner
owner: public(address)
incentives: public(uint256)
lastBlock: uint256
totalStaked: uint256
paidPerToken: public(uint256)

# Holdings
holdings: HashMap[address, uint256]
compactor: HashMap[address, uint256]
userRewards: public(HashMap[address, uint256])

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
    totalToPaid: uint256 = (self.incentives - self.incentives * 98 ** (block.number - self.lastBlock))/(100**(block.number - self.lastBlock))
    self.incentives -= totalToPaid
    self.lastBlock = block.number

    self.paidPerToken += self.totalStaked * totalToPaid/self.totalStaked



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
    rewards: uint256 = self.paidPerToken * self.holdings[msg.sender] - self.userRewards[msg.sender]

    self.userRewards[msg.sender] += rewards


    send(msg.sender, amount + rewards)

    log Wit(msg.sender, msg.value, rewards)


# incentives
@payable
@external
def increase_incentives():
    self.incentives += msg.value

    log increased(msg.value)



#Check the balance of the address
@view
@external
def bal(user: address) -> (uint256, uint256):
    totalToPaid: uint256 = (self.incentives - self.incentives * 98 ** (block.number - self.lastBlock))/(100**(block.number - self.lastBlock))


    return (
        self.holdings[user],
        (self.paidPerToken + self.totalStaked * totalToPaid/self.totalStaked) * self.holdings[msg.sender] - self.userRewards[msg.sender]
        )




# INCASE OF PROBLEMS
@payable
@external
def emergency_withdraw():
    self.compactor[msg.sender] = 0
    self.userRewards[msg.sender] = 0
    self.totalStaked -= self.holdings[msg.sender]

    send(msg.sender, self.holdings[msg.sender])

    log EmWit(msg.sender, self.holdings[msg.sender])

    self.holdings[msg.sender] = 0