# @version 0.2.11

"""
@title Unagii GuardEth
@author stakewith.us
@license AGPL-3.0-or-later
"""

from vyper.interfaces import ERC20 

interface EthVault:
    def token() -> address: view
    def deposit(): payable
    def withdraw(_shares: uint256, _min: uint256): nonpayable

event SetPause:
    paused: bool

event SetWhitelist:
    addr: indexed(address)
    approved: bool

event Deposit:
    sender: indexed(address)
    amount: uint256

event Withdraw:
    sender: indexed(address)
    amount: uint256

ETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

admin: public(address)
nextAdmin: public(address)
paused: public(bool)
vault: public(address)
token: public(address)
whitelist: public(HashMap[address, bool])

lastBlock: public(HashMap[address, uint256])

@external
def __init__(_vault: address):
    """
    @notice Contract constructor
    @param _vault Address of ERC20 vault
    """
    self.admin = msg.sender

    self.vault = _vault
    self.token = EthVault(_vault).token()
    assert self.token == ETH, "token != ETH"

    # withdraw
    ERC20(self.vault).approve(self.vault, MAX_UINT256)

@external
@payable
def __default__():
    # Prevent accidental ETH sent from user
    assert msg.sender == self.vault, "!vault"

@external
def setNextAdmin(_nextAdmin: address):
    """
    @notice Set next admin
    @param _nextAdmin Address of next admin
    """
    assert msg.sender == self.admin, "!admin"
    # allow next admin = zero address
    self.nextAdmin = _nextAdmin

@external
def claimAdmin():
    """
    @notice Claim admin
    @dev Only `nextAdmin` can claim admin 
    """
    assert msg.sender == self.nextAdmin, "!next admin"
    self.admin = msg.sender
    self.nextAdmin = ZERO_ADDRESS

@external
def setPause(_paused: bool):
    """
    @notice Pause / unpause contract
    @param _paused Boolean flag
    """
    assert msg.sender == self.admin, "!admin"
    self.paused = _paused
    log SetPause(_paused)

@external
def setWhitelist(_addr: address, _approved: bool):
    """
    @notice Approve or revoke an address to call deposit and withdraw
    @param _approved Boolean flag
    """
    assert msg.sender == self.admin, "!admin"
    self.whitelist[_addr] = _approved
    log SetWhitelist(_addr, _approved)

@nonreentrant("lock")
@external
@payable
def deposit(_min: uint256):
    """
    @notice Deposit ETH into `vault`
    @param _min Minimum shares expected to return from Unagii vault
    @dev Transfers Unagii vault shares back to caller
    @dev Protects against flash loan attacks by preventing EOA to
         deposit and withdraw in the same block
    """
    assert not self.paused, "paused"
    assert self.whitelist[msg.sender], "!whitelist"

    assert block.number > self.lastBlock[tx.origin], "no flash"
    # track EOA
    # tracking EOA prevents the following flash loan
    # 1. contract A calls deposit
    # 2. contract A transfers shares to contract B
    # 3. contract B calls withdraw
    self.lastBlock[tx.origin] = block.number
    
    # cache, saves about 2000 gas
    _vault: address = self.vault

    sharesBefore: uint256 = ERC20(_vault).balanceOf(self)
    EthVault(_vault).deposit(value=msg.value)
    sharesAfter: uint256 = ERC20(_vault).balanceOf(self)

    sharesDiff: uint256 = sharesAfter - sharesBefore

    assert sharesDiff >= _min, "shares < min"

    # Vault returns bool, so no need to use safeTransfer
    ERC20(_vault).transfer(msg.sender, sharesDiff)

    log Deposit(msg.sender, msg.value)

@nonreentrant("lock")
@external
def withdraw(_shares: uint256, _min: uint256):
    """
    @notice Withdraw ETH from `vault`
    @param _shares Amount of Unagii vault shares to burn
    @param _min Minimum ETH expected to return from Unagii vault
    @dev Transfers ETH back to caller
    @dev Protects against flash loan attacks by preventing EOA to
         deposit and withdraw in the same block
    """
    # allow withdraw even if paused = true
    assert self.whitelist[msg.sender], "!whitelist"

    assert block.number > self.lastBlock[tx.origin], "no flash"
    # track EOA
    self.lastBlock[tx.origin] = block.number

    # cache, saves about 1000 gas
    _vault: address = self.vault

    # Vault returns bool, so no need to use safeTransferFrom
    ERC20(_vault).transferFrom(msg.sender, self, _shares)

    balBefore: uint256 = self.balance
    EthVault(_vault).withdraw(_shares, _min)
    balAfter: uint256 = self.balance

    diff: uint256 = balAfter - balBefore

    raw_call(msg.sender, b"", value=diff)

    log Withdraw(msg.sender, diff)

@external
def sweep(_token: address):
    """
    @notice Allow admin to claim ETH dust and tokens that were accidentally sent
    """
    assert msg.sender == self.admin, "!admin"
    if _token == ETH:
        raw_call(msg.sender, b"", value=self.balance)
    else:
        bal: uint256 = ERC20(_token).balanceOf(self)
        ERC20(_token).transfer(self.admin, bal)