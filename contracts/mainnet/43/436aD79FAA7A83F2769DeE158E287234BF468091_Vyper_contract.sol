# @version 0.2.7
# (c) CoinFLEX
# Pipeline to change Pool LP Tokens to unified vLP Token for the Geyser

'''
@title Pipeline
@author CoinFLEX
@license Copyright (c) CoinFLEX, 2021 - all rights reserved
@notice Pipeline to change Pool LP Tokens to unified vLP Token for the Geyser
@dev Swaps between LP Tokens from admin-verfified Liquidity Pool Tokens to get vLP Token
'''
from vyper.interfaces import ERC20

### Interfaces ###
interface ERC20LP:
  def mint(_to: address, _value: uint256) -> bool: nonpayable
  def burnFrom(_to: address, _value: uint256) -> bool: nonpayable

interface TokenGeyser:
  def totalStakedFor(_addr: address) -> uint256:view
  def totalStaked() -> uint256:view
  def token() -> address:view
  def totalLocked() -> uint256:view
  def totalUnlocked() -> uint256:view
  def getStakingToken() -> address:view
  def getDistributionToken() -> address:view
  def stake(_amount: uint256, _data: Bytes[32]): nonpayable
  def stakeFor(_user: address, _amount: uint256, _data: Bytes[32]): nonpayable
  def unstake(_amount: uint256, _data: Bytes[32]): nonpayable
  def unstakeQuery(_amount: uint256) -> uint256: payable

interface Ownable: # OpenZeppelin Ownable
  def transferOwnership(_new_owner:address): nonpayable

### Events ###
event LiquidityPoolTokenAdded:
  _lp_addr: indexed(address)

event LiquidityPoolTokenRemoved:
  _lp_addr: indexed(address)

event TokenStakedAtGeyser:
  _lp_addr: indexed(address)
  _staked_for: indexed(address)
  _amount: indexed(uint256)

event TokenRedeemed:
  _lp_addr: indexed(address)
  _staked_for: indexed(address)
  _amount: indexed(uint256)

event TokenRecovery:
  _lp_addr: indexed(address)
  _amount: indexed(uint256)

### Member Variables ###
lp_tokens: public(HashMap[address, bool])
lp_balances: public(HashMap[address, HashMap[address, uint256]])
has_staked: public(HashMap[address, bool])
owner: public(address)
pipeline_token: public(address)
geyser: public(address)
recovery_timelock: public(uint256)

@external
def __init__(_plt_addr: address, _geyser_addr: address, _timelock: uint256):
  '''
  @notice Contract constructor
  @param _plt_addr  address to Pipeline Token
  @param _geyser_addr  address to Token Geyser where Pipeline Token will be staked/locked
  @param _timelock  set timelock until tokens stuck within pipeline can be recovered by admin starting from deployment blocktime
  '''
  self.pipeline_token = _plt_addr
  self.geyser = _geyser_addr
  self.owner = msg.sender
  assert _timelock > 0, 'Recovery Timelock cannot be below zero.' # dev: recovery timelock cannot be below zero
  self.recovery_timelock = block.timestamp + _timelock

@external
def add_lp_token(_lp_addr: address) -> bool:
  '''
  @notice this function is protected from re-entrancy  
  @param _lp_addr  address to liquidity pool token to be added to verified list  
  '''
  assert msg.sender == self.owner, 'You are not allowed here.' # dev: only owner
  self.lp_tokens[_lp_addr] = True
  return True

@external
def remove_lp_token(_lp_addr: address) -> bool:
  '''
  @notice this function is protected from re-entrancy  
  @param _lp_addr  address to liquidity pool token to be removed to verified list  
  '''
  assert msg.sender == self.owner, 'You are not allowed here.' # dev: only owner
  self.lp_tokens[_lp_addr] = False
  return False

@external
@nonreentrant('lock')
def stake(_lp_addr: address, _amount: uint256) -> bool:
  '''
  @notice Receives and hold verified Liquidity Pool Token from user, mints equivalent in Pipeline Token to stakeFor at geyser  
  @param _lp_addr  address to liquidity pool token previously verified to be held at pipeline and have equivalent stakedFor at geyser  
  @param _amount  the amount of tokens to be staked  
  '''
  assert self.lp_tokens[_lp_addr] == True, 'Token Not Verified by Admin' # dev: token not verified by admin
  assert ERC20(_lp_addr).transferFrom(msg.sender, self, _amount)         # dev: transfer failed
  assert TokenGeyser(self.geyser).getStakingToken() == self.pipeline_token    # dev: unmatched staking token failed
  assert ERC20LP(self.pipeline_token).mint(self, _amount)                     # dev: mint failed
  assert ERC20(self.pipeline_token).approve(self.geyser, _amount)             # dev: approve failed
  assert self.has_staked[msg.sender] == False, 'Do not stake twice from the same address' # dev: user address tries to stake twice
  TokenGeyser(self.geyser).stakeFor(msg.sender, _amount, 0x00)
  _lp_balance: uint256 = self.lp_balances[_lp_addr][msg.sender]
  assert _lp_balance + _amount != MAX_UINT256, 'Amount Overflow'         # dev: overflow
  self.lp_balances[_lp_addr][msg.sender] = _lp_balance + _amount
  self.has_staked[msg.sender] = True
  log TokenStakedAtGeyser(_lp_addr, msg.sender, _amount)
  return True

@external
@nonreentrant('lock')
def redeem(_lp_addr: address, _amount: uint256) -> bool:
  '''
  @notice Receives and burns Pipeline Token user sends back to receive their Liquidity Pool Token held  
  @param _lp_addr  address to liquidity pool token to be returned to user  
  @param _amount  the amount of tokens to be redeemed  
  '''
  assert ERC20(_lp_addr).transfer(msg.sender, _amount)                   # dev: lp token transfer failed
  assert ERC20(self.pipeline_token).transferFrom(msg.sender, self, _amount)   # dev: pipeline token transfer failed
  assert ERC20LP(self.pipeline_token).burnFrom(self, _amount)                 # dev: burn failed
  _lp_balance: uint256 = self.lp_balances[_lp_addr][msg.sender]
  assert _lp_balance != MAX_UINT256, 'Amount Overflow'                   # dev: overflow
  _lp_balance = _lp_balance - _amount
  assert _lp_balance >= 0, 'Token Amount Invalid'                        # dev: token amount cannot be below zero
  self.lp_balances[_lp_addr][msg.sender] = _lp_balance
  log TokenRedeemed(_lp_addr, msg.sender, _amount)
  return True

@external
@nonreentrant('lock')
def renounce_geyser_ownership() -> bool:
  '''
  @notice this function is protected from re-entrancy  
  '''
  assert msg.sender == self.owner, 'You are not the Admin.' # dev: you are not the admin
  Ownable(self.geyser).transferOwnership(self.owner)        # dev: ownership transfer failed
  return True

@external
@nonreentrant('lock')
def rescue_funds(_lp_addr: address) -> bool:
  assert msg.sender == self.owner, 'You are not the Admin.' # dev: you are not the admin
  assert block.timestamp > self.recovery_timelock, 'Tokens can only be recovered after time-locked period.' # dev: tokens can be recovered after timelock
  _amount: uint256 = ERC20(_lp_addr).balanceOf(self)
  assert _amount > 0, 'Token not held by contract.'    # dev: token not held by contract
  assert ERC20(_lp_addr).transfer(msg.sender, _amount) # dev: transfer failed
  log TokenRecovery(_lp_addr, _amount)
  return True