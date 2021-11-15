# @version 0.2.11
"""
@title ProxyAdmin
@notice Thin proxy allowing shared ownership of contracts
@author Ben Hauser
@license MIT
"""


event TransactionExecuted:
    admin: indexed(address)
    target: indexed(address)
    calldata: Bytes[100000]
    value: uint256

event RequestAdminChange:
    current_admin: address
    future_admin: address

event RevokeAdminChange:
    current_admin: address
    future_admin: address
    calling_admin: address

event ApproveAdminChange:
    current_admin: address
    future_admin: address
    calling_admin: address

event AcceptAdminChange:
    previous_admin: address
    current_admin: address


admins: public(address[2])

pending_current_admin: uint256
pending_new_admin: address
change_approved: bool


@external
def __init__(_authorized: address[2]):
    """
    @notice Contract constructor
    @param _authorized Admin accounts for this contract
    """
    self.admins = _authorized


@payable
@external
def execute(_target: address, _calldata: Bytes[100000]):
    """
    @notice Execute a contract call
    @dev Ether sent when calling this function is forwarded onward
    @param _target Address of the contract to call
    @param _calldata Calldata to use in the call
    """
    assert msg.sender in self.admins  # dev: only admin

    raw_call(_target, _calldata, value=msg.value)
    log TransactionExecuted(msg.sender, _target, _calldata, msg.value)


@view
@external
def get_admin_change_status() -> (address, address, bool):
    """
    @notice Get information about a pending admin change
    @return Admin address to be replaced,
            admin address to be added,
            has change been approved?
    """
    idx: uint256 = self.pending_current_admin
    if idx == 0:
        return ZERO_ADDRESS, ZERO_ADDRESS, False
    else:
        return self.admins[idx - 1], self.pending_new_admin, self.change_approved


@external
def request_admin_change(_new_admin: address):
    """
    @notice Initiate changing an admin address
    @param _new_admin New admin address (replaces msg.sender)
    """
    assert self.pending_current_admin == 0  # dev: already an active request

    admin_list: address[2] = self.admins
    assert _new_admin not in admin_list  # dev: new admin is already admin

    for i in range(2):
        if admin_list[i] == msg.sender:
            self.pending_current_admin = i + 1
            self.pending_new_admin = _new_admin
            log RequestAdminChange(msg.sender, _new_admin)
            return

    raise  # dev: only admin


@external
def approve_admin_change():
    """
    @notice Approve changing an admin address
    @dev Only callable by the 2nd admin address (the one that will not change)
    """
    idx: uint256 = self.pending_current_admin

    assert idx > 0  # dev: no active request
    assert msg.sender == self.admins[idx % 2]  # dev: caller is not 2nd admin

    self.change_approved = True
    log ApproveAdminChange(self.admins[idx - 1], self.pending_new_admin, msg.sender)


@external
def revoke_admin_change():
    """
    @notice Revoke changing an admin address
    @dev May be called by either admin at any time to reset the process,
         even if approval has previous been given
    """
    assert msg.sender in self.admins  # dev: only admin

    idx: uint256 = self.pending_current_admin
    pending_admin: address = ZERO_ADDRESS
    if idx > 0:
        pending_admin = self.admins[idx - 1]

    log RevokeAdminChange(pending_admin, self.pending_new_admin, msg.sender)

    self.pending_current_admin = 0
    self.pending_new_admin = ZERO_ADDRESS
    self.change_approved = False



@external
def accept_admin_change():
    """
    @notice Accept a changed admin address
    @dev Only callable by the new admin address, after approval has been given
    """
    assert self.change_approved == True  # dev: change not approved
    assert msg.sender == self.pending_new_admin  # dev: only new admin

    idx: uint256 = self.pending_current_admin - 1
    log AcceptAdminChange(self.admins[idx], msg.sender)
    self.admins[idx] = msg.sender

    self.pending_current_admin = 0
    self.pending_new_admin = ZERO_ADDRESS
    self.change_approved = False