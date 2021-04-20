# @version ^0.2.0
# Polkastarter POLS Pool for IDOs
# Use at your own risk

POLS_POOL: constant(address) = 0x36438D5bec77CE8Efe13709bAaBDf61922045A11

owner: public(address)

interface PolsPool:
    def initialize() -> bool: nonpayable

@external
def __init__():
    self.owner = msg.sender

@external
def createPool() -> address:
    contract: address = create_forwarder_to(POLS_POOL)
    PolsPool(POLS_POOL).initialize()
    return contract