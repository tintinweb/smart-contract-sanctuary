# @version 0.2.11
# (c) CoinFLEX
# Hub for Upgrading ERC-20 Tokens
'''
@title TokenSwap
@author CoinFLEX
@license Copyright (c) CoinFLEX, 2021 - all rights reserved
@notice Hub for Upgrading FLEXCoin ERC-20 Tokens
@dev Holds a set amount of new ERC-20 token to give out in exchange for older version
'''
from vyper.interfaces import ERC20

### Member Variables ###
old_addr: public(address) # Address of the old ERC-20 token contract
new_addr: public(address) # Address of the new ERC-20 token contract
treasury: public(address) # Address to move old ERC-20 tokens to after handing out new ERC-20 tokens
owner:    public(address) # Address where this contract belongs to

### Events ###
event FundsRescued:
  _token_addr: indexed(address)
  _target:     indexed(address)
  _amount:     uint256

event OwnershipTransferred:
  _prev_owner: indexed(address)
  _new_owner:  indexed(address)

event TokensSwapped:
  _addr:       indexed(address)
  _amount:     uint256

event TreasuryChanged:
  _prev_treasury: indexed(address)
  _new_treasury:  indexed(address)

### Constructor ###
@external
def __init__(_old_addr: address, _new_addr: address, _treasury: address):
  '''
  @notice Contract constructor
  @param _old_addr  address of the old ERC-20 token contract
  @param _new_addr  address of the old ERC-20 token contract
  @param _treasury  address to move old ERC-20 tokens to after handing out new ERC-20 tokens
  '''
  assert _old_addr != ZERO_ADDRESS, 'Old ERC-20 token address cannot be zero.' # dev: old ERC-20 token address cannot be zero
  self.old_addr = _old_addr
  assert _new_addr != ZERO_ADDRESS, 'New ERC-20 token address cannot be zero.' # dev: new ERC-20 token address cannot be zero
  self.new_addr = _new_addr
  assert _treasury != ZERO_ADDRESS, 'Treasury address cannot be zero.' # dev: treasury address cannot be zero
  self.treasury = _treasury
  self.owner = msg.sender

### Methods ###
@external
def change_treasury(_addr: address) -> bool:
  '''
  @notice Change the treasury address where old ERC-20 tokens get transferred to after swap.
  @dev only contract owner has access to this action
  @param _addr  the address of the new ERC-20 token treasury
  '''
  assert msg.sender == self.owner, 'Only contract owner is permitted to this action.' # dev: only owner
  assert _addr != ZERO_ADDRESS, 'Treasury address cannot be zero.' # dev: treasury address cannot be zero
  _prev_treasury: address = self.treasury # dev: save previous treasury address for logging
  self.treasury           = _addr         # dev: set new treasury address
  log TreasuryChanged(_prev_treasury, _addr)
  return True

@external
@nonreentrant('lock')
def rescue_funds(_addr: address, _amount: uint256) -> bool:
  '''
  @notice Rescue air-dropped fund from this contract
  @dev only contract owner has access to this action
  @param _addr  the token address to have its funds rescued
  @param _amount  the amount of tokens to have its funds rescued
  '''
  assert msg.sender == self.owner, 'Only contract owner is permitted to this action.' # dev: only owner
  assert _addr != ZERO_ADDRESS, 'Token address to rescue funds from cannot be zero.' # dev: token address to rescue funds from cannot be zero
  assert _amount > 0, 'Amount to rescue must be greater than zero.' # dev: amount to rescue must be greater than zero
  assert ERC20(_addr).transfer(msg.sender, _amount), 'Transfer failed.' # dev: transfer failed
  log FundsRescued(_addr, msg.sender, _amount)
  return True

@external
@nonreentrant('lock')
def swap(_amount: uint256) -> bool:
  '''
  @notice Swap old ERC-20 tokens with the new ERC-20 tokens
  @dev old ERC-20 tokens are transfered to the treasury address and the new ERC-20 tokens are handed out from this contract
  @param _amount  the amount to perform the swap
  '''
  assert _amount > 0, 'Amount to swap must be greater than zero.' # dev: amount to swap must be greater than zero
  assert ERC20(self.old_addr).transferFrom(msg.sender, self.treasury, _amount), 'Old token transfer failed.' # dev: transfer failed
  assert ERC20(self.new_addr).transfer(msg.sender, _amount), 'New token transfer failed.' # dev: transfer failed
  log TokensSwapped(msg.sender, _amount)
  return True

@external
def transfer_ownership(_addr: address) -> bool:
  '''
  @notice Transfer ownership for this contract; Only one owner address allowed
  @dev only contract owner has access to this action
  @param _addr  the address to transfer this contract's ownership to
  '''
  assert msg.sender == self.owner, 'Only contract owner is permitted to this action.' # dev: only owner
  assert _addr != ZERO_ADDRESS, 'Cannot transfer contract ownership to zero address.' # dev: cannot transfer ownership to zero address
  self.owner = _addr # dev: set new owner
  log OwnershipTransferred(msg.sender, _addr)
  return True