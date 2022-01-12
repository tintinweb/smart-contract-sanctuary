# @version 0.2.16
"""
@title Voting Escrow Delegation Proxy
@author Angle Protocol
@license MIT
"""

# Full fork from:
# Curve Finance's veBoostProxy

from vyper.interfaces import ERC20

interface VeDelegation:
    def adjusted_balance_of(_account: address) -> uint256: view


event CommitAdmin:
    admin: address

event ApplyAdmin:
    admin: address

event DelegationSet:
    delegation: address


voting_escrow: public(address)


delegation: public(address)

admin: public(address)
future_admin: public(address)


@external
def __init__(_voting_escrow: address, _delegation: address, _admin: address):

    assert _voting_escrow != ZERO_ADDRESS
    assert _admin != ZERO_ADDRESS

    self.voting_escrow = _voting_escrow

    self.delegation = _delegation

    self.admin = _admin

    log DelegationSet(_delegation)


@view
@external
def adjusted_balance_of(_account: address) -> uint256:
    """
    @notice Get the adjusted veCRV balance from the active boost delegation contract
    @param _account The account to query the adjusted veCRV balance of
    @return veCRV balance
    """
    _delegation: address = self.delegation
    if _delegation == ZERO_ADDRESS:
        return ERC20(self.voting_escrow).balanceOf(_account)
    return VeDelegation(_delegation).adjusted_balance_of(_account)


@external
def kill_delegation():
    """
    @notice Set delegation contract to 0x00, disabling boost delegation
    @dev Callable by the emergency admin in case of an issue with the delegation logic
    """
    assert msg.sender == self.admin

    self.delegation = ZERO_ADDRESS
    log DelegationSet(ZERO_ADDRESS)


@external
def set_delegation(_delegation: address):
    """
    @notice Set the delegation contract
    @dev Only callable by the ownership admin
    @param _delegation `VotingEscrowDelegation` deployment address
    """
    assert msg.sender == self.admin

    # call `adjusted_balance_of` to make sure it works
    VeDelegation(_delegation).adjusted_balance_of(msg.sender)

    self.delegation = _delegation
    log DelegationSet(_delegation)


@external
def commit_admin(_admin: address):
    """
    @notice Set admin to `_admin`
    @param _admin Ownership admin
    """
    assert msg.sender == self.admin, "Access denied"

    self.future_admin = _admin

    log CommitAdmin(_admin)


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    """
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin

    log ApplyAdmin(_admin)