# @version ^0.2.0

POLS: constant(address) = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735

# Contributor storage
struct Contributor:
    totalETH: uint256
    totalPOLS: uint256

admin: public(address)
contributors: public(HashMap[address, Contributor])
contributorList: public(address[5])
factory: public(address)
totalContributors: public(uint256)
totalPOLS: public(uint256)
totalETH: public(uint256)

interface TransferPOLS:
    def transferFrom(src: address, dst: address, wad: uint256) -> bool: nonpayable

@external
def __init__():
    self.factory = msg.sender

@external
def createPool(creator: address):
    assert msg.sender == self.factory, "Not allowed"
    self.admin = creator
    self.contributorList[self.totalContributors] = creator
    self.totalContributors += 1

@external
def addContributor(newContributor: address):
    assert msg.sender == self.admin, "Not pool admin"
    self.contributorList[self.totalContributors] = newContributor
    self.totalContributors += 1

@external
@payable
def contributeETH(amount: uint256):
    assert msg.sender in self.contributorList, "Not a registered contributor"
    assert msg.value == amount, "Insufficient input amount"
    self.contributors[msg.sender].totalETH += msg.value
    self.totalETH += msg.value

@external
def contributePOLS(amount: uint256):
    assert msg.sender in self.contributorList, "Not a registered contributor"
    TransferPOLS(POLS).transferFrom(msg.sender, self, amount)
    self.contributors[msg.sender].totalPOLS += amount
    self.totalPOLS += amount

@external
def WithdrawPOLS(amount: uint256):
    assert msg.sender in self.contributorList, "Not a registered contributor"
    assert self.contributors[msg.sender].totalPOLS <= amount, "Insufficient Output Amount"
    TransferPOLS(POLS).transferFrom(self, msg.sender, amount)
    self.contributors[msg.sender].totalPOLS -= amount
    self.totalPOLS -= amount

@external
def WithdrawETH(amount: uint256):
    assert msg.sender in self.contributorList, "Not a registered contributor"
    assert self.contributors[msg.sender].totalETH <= amount, "Insufficient Output Amount"
    send(msg.sender, amount)
    self.contributors[msg.sender].totalETH -= amount
    self.totalETH -= amount