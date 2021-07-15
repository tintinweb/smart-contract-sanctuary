# @version ^0.2.12
"""
@title Polymer's Vesting and distribution contract
@author Polymer
@license MIT
@notice
    Enables vesting of a token distribution.
    The token to distribution is stored until vesting has initiated.

    Vesting is by a linear schedule set globally. 
    The schedule can be changed by the owner as long as the
    cliff has not been passed yet. This is a mathematical concern.

    Cliff
    The contract contains a start timestamp, referred to as the cliff. 
    Once the cliff is passed, the vesting schedule and vesting amounts
    are /fixed/. No new amounts can be entered into vesting, but the punisher
    can lower vested amounts. The punisher can be disabled by setting him 
    to ZERO_ADDRESS, as he decides who inherits the role.

    Whitelists
    On contract creation, whitelisting is enabled by default.The administrator
    can enable or disable a whitelist of allowed users. Alternatively, the
    whitelist can be disabled. If the whitelist is disabled, a token contribution
    is recommended. Even if entering is free, a token contribution (for example)
    be used to ensure people only register a certain amount.

    One-time payout
    The contract contains a flag that enables a one-time payout of a fixed
    percentage of the vesting. If the flag is never raised, this withholds the
    percentage contribution.
"""

# Load the ERC20 interface to add an ERC20 token to the contract
from vyper.interfaces import ERC20

event Collect:
    to: indexed(address)
    token: address
    amount: uint256

event VestedClaims:
    to: indexed(address)
    amount: uint256

event Enter:
    who: indexed(address)
    amount: uint256
    contribution: uint256

event ContributionPrice:
    new: uint256

event Flag:
    status: bool

event Slope:
    cliff: uint256
    end: uint256

event Punish:
    _who: indexed(address)
    _from: uint256
    _to: uint256

event Whitelist:
    who: indexed(address)
    status: uint256



event OwnerTransfer:
    old: indexed(address)
    new: indexed(address)

event ClaimTransfer:
    old: indexed(address)
    new: indexed(address)

event PunisherTransfer:
    old: indexed(address)
    new: indexed(address)



# scale to increase precision.
RESOLUTION: constant(uint256) = 10**18

# Contract variables
owner: public(address)
punisher: public(address)

# Vesting Variables
cliffTimestamp: public(uint256)
endTimestamp: public(uint256)
flag: public(bool)
IMMEDIATEALLOCATION: constant(uint256) = 0 # out of RESOLUTION

useWhitelist: public(bool)
whitelisted: public(HashMap[address, uint256])


# Token contribution
contributionToken: public(address)
contributionPrice: public(uint256) # · resolution


# Token management variables
totalTokens: public(uint256)
# Alternatively a struct.
userVesting: public(HashMap[address, uint256])
userClaimed: public(HashMap[address, uint256])
vestingToken: public(address)


# Preclaim token storage.
#  Tokens owned by claimAddress is distributable by this contract.
#  Requires allowance.
claimAddress: public(address)


@external
def __init__(_claimAddress : address, _vestingToken : address):
    self.claimAddress = _claimAddress
    self.useWhitelist = True
    self.owner = msg.sender
    self.punisher = msg.sender
    self.vestingToken = _vestingToken


@external
def transferOwner(_owner : address):
    """
    @notice Transfer ownership to another address
    @dev Reverts if msg.sender is not owner
    @param _owner address Address of new owner
    """
    assert msg.sender == self.owner, "unauthorized"

    log OwnerTransfer(self.owner, _owner)

    self.owner = _owner


@external
def transferPunisher(_punisher : address):
    """
    @notice Transfer punisher to another address
    @dev Reverts if msg.sender is not punisher
    @param _punisher address Address of new punisher
    """
    assert msg.sender == self.punisher, "unauthorized"

    log PunisherTransfer(self.punisher, _punisher)

    self.punisher = _punisher


@external
def setClaim(_contract : address):
    """
    @notice Sets the source of tokens
    @dev Reverts if msg.sender is not owner
    @param _contract address Address of the new source of tokens to vest
    """
    assert msg.sender == self.owner, "unauthorized"

    log ClaimTransfer(self.claimAddress, _contract)

    self.claimAddress = _contract


@external
def setSlope(_cliffTimestamp : uint256, _endTimestamp : uint256):
    """
    @notice Sets the slope settings
    @dev 
        Reverts if msg.sender != owner
        Reverts if cliff has already passed
        Reverts if _cliffTimestamp has passed.
    @param _cliffTimestamp uint256 New cliff
    """
    assert msg.sender == self.owner, "unauthorized"
    assert (block.timestamp <= self.cliffTimestamp) or (self.cliffTimestamp == 0), "Cliff passed"
    assert block.timestamp <= _cliffTimestamp, "Cliff invalid"
    assert _cliffTimestamp < _endTimestamp

    log Slope(_cliffTimestamp, _endTimestamp)

    self.cliffTimestamp = _cliffTimestamp
    self.endTimestamp = _endTimestamp


@external
def raiseFlag():
    """
    @notice Allows the initial tokens to be released
    @dev 
        Reverts if msg.sender != owner
    """
    assert msg.sender == self.owner

    self.flag = True

    log Flag(True)


@external
def setWhitelist(_bool : bool):
    """
    @notice Enable or disable whitelist.
    @dev 
        Reverts if msg.sender != owner
    @param _bool bool
    """
    assert msg.sender == self.owner, "unauthorized"

    log Whitelist(ZERO_ADDRESS, convert(_bool, uint256))

    self.useWhitelist = _bool


@external
def whitelist(_who : address, _amount : uint256):
    """
    @notice Sets whitelist for a user
    @dev 
        Reverts if msg.sender != owner
    @param _who address User to set whitelist for
    @param _amount uint256 The amount to whitelist the user for
        True for whitelisted
        False for not whitelisted
    """
    assert msg.sender == self.owner, "unauthorized"

    log Whitelist(_who, _amount)

    self.whitelisted[_who] = _amount


@external
def setContribution(_price : uint256, _contributionToken : address):
    """
    @notice Sets a new contributionPrice and contributionToken for vesting
    @dev 
        Reverts if msg.sender != owner
    @param _price uint256 New contributionPrice
    """
    assert msg.sender == self.owner, "unauthorized"

    log ContributionPrice(_price)

    self.contributionPrice = _price
    self.contributionToken = _contributionToken


@external
def punish(_who : address, _newAmount : uint256):
    """
    @notice Set a vesting user's amount.
    @dev 
        Reverts if msg.sender != punisher
        Reverts if _newAmount results in an increase.
    @param _who address The address to punish
    @param _newAmount uint256 The new amount.
    """
    assert msg.sender == self.punisher, "unauthorized"

    _userClaimed: uint256 = self.userClaimed[_who]

    assert self.userVesting[_who] - _userClaimed >= _newAmount, "Increases vesting"

    log Punish(_who, self.userVesting[_who], _newAmount + _userClaimed)

    self.userVesting[_who] = _newAmount + _userClaimed


@external
def collect(_to : address, _token : address, _amount : uint256):
    """
    @notice Collect token contributions and forward them to _to.
    @dev 
        Reverts if msg.sender != owner
    @param _to address The address to send token contributions to
    @param _token address The token to send contributions to. (Required in case contributionToken changed)
    @param _amount uint256 Amount of _token to send to _to.
    """
    assert msg.sender == self.owner, "unauthorized"

    log Collect(_to, _token, _amount)

    assert ERC20(_token).transfer(_to, _amount), "Transfer failed"


@nonreentrant("lock")
@external
def enter(_amount : uint256) -> bool:
    """
    @notice Enter a vesting for _amount of vestingToken.
    @dev 
        Reverts if cliff has been passed.
        Reverts if useWhitelist == True and msg.sender is not whitelisted. 
        Reverts if user cannot pay _amount · contributionPrice.
    @param _amount uint256 Amount of _token to allocate to msg.sender
    @return bool True
    """
    assert block.timestamp <= self.cliffTimestamp, "Cliff passed"
    if self.useWhitelist:
        self.whitelisted[msg.sender] -= _amount  # dev: Not enough whitelisted

    if self.contributionPrice > 0:
        assert ERC20(self.contributionToken).transferFrom(msg.sender, self, (_amount*self.contributionPrice)/RESOLUTION), "Contribution"
    assert ERC20(self.vestingToken).transferFrom(self.claimAddress, self, _amount), "Vest allocation"

    log Enter(msg.sender, _amount, (_amount * self.contributionPrice)/RESOLUTION)

    self.userVesting[msg.sender] += _amount

    return True


# No reentrancy lock because external call is after storage mod
@external
def claimVested() -> uint256:
    """
    @notice Claims vested tokens
    @dev
        !Reverts if block.timestamp < cliffTimestamp. 
    @return uint256 Vested tokens.
    """
    
    userVest: uint256 = self.userVesting[msg.sender]

    # Logic for initial allocation
    initial: uint256 = 0
    if self.flag:
        initial = (userVest*IMMEDIATEALLOCATION)/RESOLUTION

    # Create vesting function.
    #
    # Y |         /-----
    #   |       /
    #   |     /     
    # --+---/-----------
    #   |   A     B     
    # A: cliffTimestamp
    # B: endTimestamp
    # Y: userVesting
    # y = a * x + b
    # Y = ?a * B + ?b and 0 = ?a * A + ?b 
    # <=> a = -Y/(B-A), b = YB/(B-A)
    # y = Y/(B-A) * x - YA/(B-A) = (Y·(x-A))/(B-A)

    A: uint256 = self.cliffTimestamp
    numRewardTokens: uint256 = initial
    if block.timestamp > self.cliffTimestamp:
        B: uint256 = self.endTimestamp
        Y: uint256 = (userVest*(RESOLUTION-IMMEDIATEALLOCATION))/RESOLUTION


        # Piecewise right.
        x: uint256 = min(block.timestamp, B)
        # Sainty check: x >= B <=> x = B <=> (Y·(x-A))/(B-A) = (Y·(B-A))/(B-A) = Y · (B-A)/(B-A) = Y
        

        # Piecewise left.
        numRewardTokens += ((Y*(x-A))/(B-A)) # Dev: Call later; x < A => x-A < 0. uint256 < 0 => reverts.

    numRewardTokens -= self.userClaimed[msg.sender]
    
    self.userClaimed[msg.sender] += numRewardTokens

    assert ERC20(self.vestingToken).transfer(msg.sender, numRewardTokens)

    log VestedClaims(msg.sender, numRewardTokens)

    return numRewardTokens


@view
@external
def viewVested(_user : address) -> uint256:
    """
    @notice Claims vested tokens
    @dev
        !Reverts if block.timestamp < cliffTimestamp. 
    @return uint256 Vested tokens.
    """
    
    userVest: uint256 = self.userVesting[_user]

    initial: uint256 = 0
    if self.flag:
        initial = (userVest*IMMEDIATEALLOCATION)/RESOLUTION


    A: uint256 = self.cliffTimestamp
    numRewardTokens: uint256 = initial
    if block.timestamp > self.cliffTimestamp:
        B: uint256 = self.endTimestamp
        Y: uint256 = (userVest*(RESOLUTION-IMMEDIATEALLOCATION))/RESOLUTION

        x: uint256 = min(block.timestamp, B)
        numRewardTokens += ((Y*(x-A))/(B-A)) 

    return numRewardTokens - self.userClaimed[_user]