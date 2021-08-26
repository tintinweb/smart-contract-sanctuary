# Contract multisend
# This contract is meant to send ethereum
# and ethereum tokens to several addresses
# in at most two ethereum transactions


# Variables
owner: public(address)
sendEthFee: public(wei_value)  # wei


# Functions

# Set owner of the contract
@public
@payable
def __init__():
    self.owner = msg.sender


# MultisendEther
# accepts lists of addresses and corresponding amounts to be sent to them
# calculates the total amount and add fee
# distribute ether if sent ether is suficient
# return change back to the owner
@public
@payable
def multiSendEther(addresses: address[100], amount: wei_value, num: uint256) -> bool:
    sender: address = msg.sender
    value_sent: wei_value = msg.value

    # required amount is amount plus fee
    requiredAmount: wei_value = amount * num + (self.sendEthFee)

    # Check if sufficient eth amount was sent
    assert value_sent >= requiredAmount

    # Distribute ethereum
    for i in range(100):
        if (addresses[i] != ZERO_ADDRESS):
            send(addresses[i], as_wei_value(amount, "wei"))

    # Send back excess amount
    if value_sent > requiredAmount:
        change: wei_value = value_sent - requiredAmount
        send(sender, as_wei_value(change, "wei"))

    return True


@public
@payable
def deposit() -> bool:
    return True


@public
def withdrawEther(_to: address, _value: uint256) -> bool:
    assert msg.sender == self.owner
    send(_to, as_wei_value(_value, "wei"))
    return True


@public
def destroy(_to: address):
    assert msg.sender == self.owner
    selfdestruct(_to)