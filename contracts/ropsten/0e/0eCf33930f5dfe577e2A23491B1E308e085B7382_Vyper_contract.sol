# @version 0.2.8
governance: public(address)

struct Reward:
    dog: int128
    cat: int128

crud: public(Reward)

@external
def __init__():
    self.governance = msg.sender
    self.crud = Reward({
      cat: 333,
      dog: 111
    })

@external
def setGovernance(governance: address):
    self.governance = governance