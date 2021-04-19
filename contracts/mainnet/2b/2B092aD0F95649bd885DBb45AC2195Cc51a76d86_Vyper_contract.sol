# @version 0.2.11

"""
@title Unagii GuardErc20
@author stakewith.us
@license AGPL-3.0-or-later
"""

from vyper.interfaces import ERC20 

interface Erc20Vault:
    def token() -> address: view
    def deposit(_amount: uint256): nonpayable
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
    self.token = Erc20Vault(_vault).token()

    # deposit
    ERC20(self.token).approve(self.vault, MAX_UINT256)
    # withdraw
    ERC20(self.vault).approve(self.vault, MAX_UINT256)

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

@internal
def _safeTransfer(_token: address, _to: address, _amount: uint256):
    """
    @dev "safeTransfer" which works for ERC20s which return bool or not
    """
    assert _to != ZERO_ADDRESS, "to = 0 address"

    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(_response) > 0:
        assert convert(_response, bool), "transfer failed"  

@internal
def _safeTransferFrom(_token: address, _from: address, _to: address, _amount: uint256):
    """
    @dev "safeTransferFrom" which works for ERC20s which return bool or not
    """
    assert _to != ZERO_ADDRESS, "to = 0 address"

    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(_response) > 0:
        assert convert(_response, bool), "transfer from failed"  

@nonreentrant("lock")
@external
def deposit(_amount: uint256, _min: uint256):
    """
    @notice Deposit `token` into `vault`
    @param _amount Amount of `token` to deposit
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
    
    self._safeTransferFrom(self.token, msg.sender, self, _amount)

    # cache, saves about 2000 gas
    _vault: address = self.vault

    sharesBefore: uint256 = ERC20(_vault).balanceOf(self)
    # if token has fee on transfer, this function will fail
    Erc20Vault(_vault).deposit(_amount)
    sharesAfter: uint256 = ERC20(_vault).balanceOf(self)

    sharesDiff: uint256 = sharesAfter - sharesBefore

    assert sharesDiff >= _min, "shares < min"

    # Vault returns bool, so no need to use _safeTransfer
    ERC20(_vault).transfer(msg.sender, sharesDiff)

    log Deposit(msg.sender, _amount)

@nonreentrant("lock")
@external
def withdraw(_shares: uint256, _min: uint256):
    """
    @notice Withdraw `token` from `vault`
    @param _shares Amount of Unagii vault shares to burn
    @param _min Minimum token expected to return from Unagii vault
    @dev Transfers `token` back to caller
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
    _token: address = self.token

    # Vault returns bool, so no need to use _safeTransferFrom
    ERC20(_vault).transferFrom(msg.sender, self, _shares)

    balBefore: uint256 = ERC20(_token).balanceOf(self)
    Erc20Vault(_vault).withdraw(_shares, _min)
    balAfter: uint256 = ERC20(_token).balanceOf(self)

    diff: uint256 = balAfter - balBefore

    self._safeTransfer(_token, msg.sender, diff)

    log Withdraw(msg.sender, diff)

@external
def sweep(_token: address):
    """
    @notice Allow admin to claim dust and tokens that were accidentally sent
    """
    assert msg.sender == self.admin, "!admin"
    bal: uint256 = ERC20(_token).balanceOf(self)
    ERC20(_token).transfer(self.admin, bal)