# We only have 1 event

event TXout:
    receiver: indexed(address)
    value: uint256


event Dep:
    depositor: indexed(address)
    value: uint256


# We only need to track the owner
owner: public(address)

# Set up the owner.
@external
def __init__(_owner: address):
    self.owner = _owner


#Check the balance of the address
@view
@external
def bal() -> uint256:
    return self.balance

@view
@external
def world() -> String[11]:
    return "Hello World"



# Defeault value

@payable
@external
def send_me_money():
    # Send me ETH
    log Dep(msg.sender, msg.value)


# Withdraw from the contract
@external
def withdraw(amount: uint256):
    assert self.owner == msg.sender
    assert self.balance >= amount

    # Log the withdrawal
    log TXout(msg.sender, amount)