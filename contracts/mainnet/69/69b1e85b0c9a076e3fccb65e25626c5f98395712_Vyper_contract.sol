# @version ^0.2.12

"""
@title Paladin Loan Killer
@notice Tries to kill a Borrow (a PalLoan) that is over the health factor
        Receives ERC20 as reward, can withdraw them to the admin address
"""

from vyper.interfaces import ERC20

interface PalPool:
    def killBorrow(loanPool: address): nonpayable
    def isKillable(_loan: address) -> bool: view
    def _updateInterest() -> bool: nonpayable


event Kill:
    pool: indexed(address)
    loan: indexed(address)


admin: address
killer: address


@external
def __init__(_killer: address):
    self.admin = msg.sender
    self.killer = _killer



@external
def kill(_pool: address, _loan: address) -> bool:
    """
    @notice Try to kill a Borrow in a PalPool
    @param _pool : address of the PalPool
    @param _loan : address of the PalLoan
    @return Success
    """
    assert msg.sender == self.killer, "Killer only can call"

    PalPool(_pool)._updateInterest()

    assert PalPool(_pool).isKillable(_loan), "Loan not killable"

    PalPool(_pool).killBorrow(_loan)

    log Kill(_pool, _loan)

    return True


@external
@view
def balanceERC20(_token: address) -> uint256:
    """
    @notice Balance of the contract for a given ERC20
    @param _token : address of the ERC20
    @return balance amount
    """
    return ERC20(_token).balanceOf(self)


@external
def withdrawERC20(_token: address, _amount: uint256) -> bool:
    """
    @notice Withdraw the given amount in the given ERC20
    @param _token : address of the ERC20
    @param _amount : amount ot withdraw
    @return Success
    """
    assert msg.sender == self.admin, "Admin function"

    assert ERC20(_token).balanceOf(self) > 0, "No balance to withdraw"

    success: bool = ERC20(_token).transfer(self.admin, _amount)

    assert success, "Transfer failed"

    return success


@external
def changeAdmin(_new_admin: address):
    """
    @notice Change Admin of the contract
    @param _new_admin : address of the new admin
    """
    assert msg.sender == self.admin, "Admin function"

    self.admin = _new_admin