# @version 0.2.15
"""
@title Voting Escrow Delegation Proxy
@author Curve Finance
@license MIT
"""

from vyper.interfaces import ERC20


interface VeDelegation:
    def adjusted_balance_of(_account: address) -> uint256: view


event CommitAdmins:
    ownership_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    emergency_admin: address

event DelegationSet:
    delegation: address


VOTING_ESCROW: constant(address) = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2


delegation: public(address)

emergency_admin: public(address)
ownership_admin: public(address)
future_emergency_admin: public(address)
future_ownership_admin: public(address)


@external
def __init__(_delegation: address, _o_admin: address, _e_admin: address):
    self.delegation = _delegation

    self.ownership_admin = _o_admin
    self.emergency_admin = _e_admin

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
        return ERC20(VOTING_ESCROW).balanceOf(_account)
    return VeDelegation(_delegation).adjusted_balance_of(_account)


@external
def kill_delegation():
    """
    @notice Set delegation contract to 0x00, disabling boost delegation
    @dev Callable by the emergency admin in case of an issue with the delegation logic
    """
    assert msg.sender in [self.ownership_admin, self.emergency_admin]

    self.delegation = ZERO_ADDRESS
    log DelegationSet(ZERO_ADDRESS)


@external
def set_delegation(_delegation: address):
    """
    @notice Set the delegation contract
    @dev Only callable by the ownership admin
    @param _delegation `VotingEscrowDelegation` deployment address
    """
    assert msg.sender == self.ownership_admin

    # call `adjusted_balance_of` to make sure it works
    VeDelegation(_delegation).adjusted_balance_of(msg.sender)

    self.delegation = _delegation
    log DelegationSet(_delegation)


@external
def commit_set_admins(_o_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _e_admin)


@external
def apply_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    _o_admin: address = self.future_ownership_admin
    _e_admin: address = self.future_emergency_admin
    self.ownership_admin = _o_admin
    self.emergency_admin = _e_admin

    log ApplyAdmins(_o_admin, _e_admin)