# @version 0.2.8

"""
SPDX-License-Identifier: MIT

@title TokenHook v3 (THKv3).
@author Currently ANONYMOUS.
@dev For new token deployment:
1- Install MetaMask (Chrome/Firefox extension).
2- Connect to Rinkeby (or other private/public chains).
3- Run RemixIDE and set environment as "Injected Web3".
4- Copy and past this code in RemixIDE.
5- Deploy the token contract (ERC20).
@dev The code is compatible with version 0.2.8 of Vyper complier.
"""

# @dev Imports built-in ERC20 interfaces in Vyper
from vyper.interfaces import ERC20
implements: ERC20

# Events
event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokens: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _tokens: uint256

event Buy:
    _buyer: indexed(address)
    _wei: uint256
    _owner: indexed(address)
    _tokens: uint256

event Sell:
    _seller: indexed(address)
    _tokens: uint256
    _contract: indexed(address)
    _wei: uint256
    _owner: indexed(address)

event Received:
    _sender: indexed(address)
    _wei: uint256

event Withdrawal:
    _by: indexed(address)
    _contract: indexed(address)
    _wei: uint256

event Change:
    _current: uint256
    _new: uint256

event ChangeOwner:
    _current: indexed(address)
    _new: indexed(address)

event Pause:
    _owner: indexed(address)
    _state: bool

event Mint:
    _owner: indexed(address)
    _tokens: uint256

event Burn:
    _owner: indexed(address)
    _tokens: uint256

# State Variables
name: public(String[16])
symbol: public(String[8])
decimals: public(uint256)
owner: address
exchangeRate: public(uint256)
initialSupply: constant(uint256) = 200 * 10 ** 6
paused: bool
allowance: public(HashMap[address, HashMap[address, uint256]])
transferred: HashMap[address, HashMap[address, uint256]]
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)

@external
def __init__(_supply : uint256):
    """
    @notice Token constructor that runs only once upon contract creation.
    @param Initial supply of the token, zero values use default 200 million tokens
    @dev When verify the code in EtherScan and if you used the default initialSupply,
    set this value as "Constructor Arguments":
    0000000000000000000000000000000000000000000000000000000000000000
    @dev The token will be created with 18 decimal places,
    so it takes a balance of 10 ** 18 token units to equal one token.
    In other word, if we want to have x initial tokens, we need to pass in,
    x * 10 ** 18 to the constructor.
    """
    self.owner = msg.sender
    self.name = "TokenHookv3"
    self.symbol = "THKv3"
    self.decimals = 18
    self.totalSupply = _supply
    if (_supply == 0):
        self.totalSupply = initialSupply * 10 ** self.decimals
    self.balanceOf[self.owner] = self.totalSupply
    self.exchangeRate = 100
    log Transfer(ZERO_ADDRESS, self.owner, self.totalSupply)

@external
@payable
def __default__():
    """
    @notice Default function to accept ETH.
    @dev It is compatible with 2300 gas for receiving funds via send or transfer methods.
    """
    log Received(msg.sender, msg.value)

@external
@nonreentrant("lock")
def transfer(_to : address, _tokens : uint256) -> bool:
    """
    @notice Transfers `tokens` amount of tokens to address `to`, and fires Transfer event.
    @dev Based of ERC20 specifications, transferring zero tokens is also allowed.
    """
    assert not self.paused, "Fail-Safe mode"
    assert _to != msg.sender, "Receiver is sender"
    assert _to != ZERO_ADDRESS, "Zero address"
    assert self.balanceOf[msg.sender] >= _tokens, "Not enough balance"
    self.balanceOf[msg.sender] -= _tokens
    self.balanceOf[_to] += _tokens
    log Transfer(msg.sender, _to, _tokens)
    return True

@external
@nonreentrant("lock")
def transferFrom(_from : address, _to : address, _tokens : uint256) -> bool:
    """
    @notice Special type of Transfer that makes it possible to give permission to another address for spending tokens on your behalf.
    @dev It sends `tokens` from address `from` to address `to`. The `transferFrom` method is used for a withdraw work-flow, allowing
    contracts to send tokens on your behalf, for example to deposit to a contract address and/or to charge fees in sub-currencies.
    The function call fails unless the `from` account has deliberately authorized the sender of the message via `approve` function.
    """
    assert not self.paused, "Fail-Safe mode"
    assert _from != msg.sender, "Receiver is sender"
    assert _to != ZERO_ADDRESS, "Zero address"
    assert self.balanceOf[_from] >= _tokens, "Not enough tokens"
    
    #Prevent token transfer more than allowed (Multiple Withdrawal Attack)
    _transferred : uint256 = 0
    if (self.allowance[_from][msg.sender] > self.transferred[_from][msg.sender]):
        _transferred = self.allowance[_from][msg.sender] - self.transferred[_from][msg.sender]
    assert _tokens <= _transferred, "Transfer more than allowed" 
    
    self.balanceOf[_from] -= _tokens
    self.balanceOf[_to] += _tokens
    self.transferred[_from][msg.sender] += _tokens
    log Transfer(_from, _to, _tokens)
    return True

@external
@nonreentrant("lock")
def approve(_spender : address, _tokens : uint256) -> bool:
    """
    @notice It approves another address to spend tokens on your behalf.
    @dev It allows `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    If this function is called again, it overwrites the current allowance with `tokens`.
    """
    assert not self.paused, "Fail-Safe mode"
    assert _spender != msg.sender, "Approver is spender"
    assert _spender != ZERO_ADDRESS, "Zero address"
    assert self.balanceOf[msg.sender] >= _tokens, "Not enough balance"
    self.allowance[msg.sender][_spender] = _tokens
    log Approval(msg.sender, _spender, _tokens)
    return True
    
@external
@nonreentrant("lock")
def sell(_tokens: uint256) -> bool:
    """
    @notice Supports selling tokens to the contract.
    @dev It uses send method to be compatible with EIP-1884.
    """
    assert not self.paused, "Fail-Safe mode"
    assert _tokens > 0, "No token to sell"
    assert self.exchangeRate > 0, "Invalid exchange rate"
    assert self.balanceOf[msg.sender] >= _tokens, "Not enough token"
    _wei: uint256 = _tokens / self.exchangeRate
    assert self.balance >= _wei, "Not enough wei"
    
    # Using Checks-Effects-Interactions (CEI) pattern to mitigate same-function re-entrancy
    self.balanceOf[msg.sender] -= _tokens
    self.balanceOf[self.owner] += _tokens
    send(msg.sender, _wei)
    log Sell(msg.sender, _tokens, self, _wei, self.owner)
    return True

@external
@payable
def buy() -> bool:
    """
    @notice Supports buying token by transferring Ether
    @dev Calculations are in Wei
    """
    assert not self.paused, "Fail-Safe mode"
    assert msg.sender != self.owner, "Called by the Owner"
    assert msg.value > 0, "Not enough fund"
    assert self.exchangeRate > 0, "Invalid exchange rate"
    _tokens: uint256 = msg.value * self.exchangeRate
    assert self.balanceOf[self.owner] >= _tokens, "Not enough tokens"

    self.balanceOf[msg.sender] += _tokens
    self.balanceOf[self.owner] -= _tokens
    log Buy(msg.sender, msg.value, self.owner, _tokens)
    return True

@external
def withdraw(_amount: uint256) -> bool:
    """
    @notice Withdraw Ether from the contract and send it to the address that is specified by the owner.
    @dev It can be called only by the owner.
    """
    assert msg.sender == self.owner, "Not the owner"
    assert self.balance >= _amount, "Not enough fund"
    send(msg.sender, _amount)
    log Withdrawal(msg.sender, self, _amount)
    return True

@external
def mint(_tokens: uint256):
    """
    @notice Creates new tokens and assigns them to the owner.
    @dev Increases the total supply as well.
    """
    assert msg.sender == self.owner, "Not the owner"
    self.totalSupply += _tokens
    self.balanceOf[self.owner] += _tokens
    log Mint(msg.sender, _tokens)

@external
def burn(_tokens: uint256):
    """
    @notice Burns tokens from the owner.
    @dev Decreases the total supply as well.
    """
    assert msg.sender == self.owner, "Not the owner"
    assert self.balanceOf[self.owner] >= _tokens, "Not enough tokens"
    self.totalSupply -= _tokens
    self.balanceOf[self.owner] -= _tokens
    log Burn(msg.sender, _tokens)
    
@external
def setExchangeRate(_rate: uint256) -> bool:
    """
    @notice Sets new exchange rate.
    @dev It can be called only by the owner.
    """
    assert msg.sender == self.owner, "Not the owner"
    currentRate: uint256 = self.exchangeRate
    self.exchangeRate = _rate
    log Change(currentRate, self.exchangeRate)
    return True

@external
def changeOwner(_owner: address):
    """
    @notice Changes owner of the contract
    """
    assert msg.sender == self.owner, "Not the owner"
    currentOwner: address = self.owner
    self.owner = _owner
    log ChangeOwner(currentOwner, self.owner)
    
@external
def pause():
    """
    @notice Pause the contract.
    @dev It can be as result of self-checks (off-chain computations).
    """
    assert msg.sender == self.owner, "Not the owner"
    self.paused = True   
    log Pause(msg.sender, self.paused)

@external
def unpause():
    """
    @notice Unpause the contract.
    @dev It can be used after self-checks.
    """
    assert msg.sender == self.owner, "Not the owner"
    self.paused = False
    log Pause(msg.sender, self.paused)

@view
@external
def transfers(_tokenHolder: address, _spender: address) -> uint256:
    """
    @notice Returns the amount of transferred tokens by spender's account.
    @dev It is used to prevent Multiple Withdrawal Attack
    """
    assert not self.paused, "Fail-Safe mode"
    return self.transferred[_tokenHolder][_spender]