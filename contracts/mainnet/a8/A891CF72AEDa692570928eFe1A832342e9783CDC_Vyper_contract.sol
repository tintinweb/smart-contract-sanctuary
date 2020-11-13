# Created by interfinex.io
# - The Greeks

from vyper.interfaces import ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event ClaimDividends:
    to: indexed(address)
    value: uint256
    totalDividends: uint256

event DistributeDividends:
    sender: indexed(address)
    value: uint256
    totalDividends: uint256

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalDividends: public(uint256)
totalClaimedTokenDividends: public(uint256)
totalTokenDividends: public(uint256)
dividend_token: public(address)
withdraw_address: public(address)

balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: public(uint256)
minter: public(address)
mintable: public(bool)

POINT_MULTIPLIER: constant(uint256) = 10 ** 24

lastDividends: public(HashMap[address, uint256])

@external
def initializeERC20(
    _name: String[64], 
    _symbol: String[32], 
    _decimals: uint256, 
    _supply: uint256, 
    _dividend_token: address,
    _mintable: bool
):
    assert self.minter == ZERO_ADDRESS, "Cannot initialize contract more than once"
    init_supply: uint256 = _supply * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.minter = msg.sender
    self.mintable = _mintable
    self.dividend_token = _dividend_token
    ERC20(self.dividend_token).approve(self, MAX_UINT256)
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@view
@external
def totalSupply() -> uint256:
    """
    @dev Total number of tokens in existence.
    """
    return self.total_supply

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @dev Function to check the amount of tokens that an owner allowed to a spender.
    @param _owner The address which owns the funds.
    @param _spender The address which will spend the funds.
    @return An uint256 specifying the amount of tokens still available for the spender.
    """
    return self.allowances[_owner][_spender]

@view
@internal
def _dividendsOf(_owner: address) -> uint256:
    return (self.totalDividends - self.lastDividends[_owner]) * self.balanceOf[_owner] / POINT_MULTIPLIER

@internal
def _distributeDividends(_from: address, _value: uint256):
    if _value == 0:
        return
    ERC20(self.dividend_token).transferFrom(_from, self, _value)
    # Ignore whatever the contract balance is because the contract can't claim dividends
    self.totalDividends += _value * POINT_MULTIPLIER / (self.total_supply - self.balanceOf[self])
    self.totalTokenDividends += _value
    log DistributeDividends(_from, _value, self.totalDividends)

@external
def distributeDividends(_value: uint256):
    self._distributeDividends(msg.sender, _value)

@internal
def _distributeExcessBalance():
    """
    @dev    Withdraw excess tokens in the contract. It's possible that excess tokens, 
            via dividends or some other means, will accrue in the contract. This provides
            an escape hatch for those funds.
    """
    excess_balance: uint256 = ERC20(self.dividend_token).balanceOf(self) - (self.totalTokenDividends - self.totalClaimedTokenDividends)
    self._distributeDividends(self, excess_balance)

@external
def distributeExcessBalance():
    self._distributeExcessBalance()

@view
@external
def getExcessBalance() -> uint256:
    return ERC20(self.dividend_token).balanceOf(self) - (self.totalTokenDividends - self.totalClaimedTokenDividends)
    
@view
@external
def dividendsOf(_owner: address) -> uint256:
    return self._dividendsOf(_owner)

@internal
def _claimDividends(_to: address):
    if _to == self:
        return
    dividends: uint256 = self._dividendsOf(_to)
    self.lastDividends[_to] = self.totalDividends   
    if dividends != 0:
        ERC20(self.dividend_token).transfer(_to, dividends)
        self.totalClaimedTokenDividends += dividends
        log ClaimDividends(_to, dividends, self.totalDividends)

@external
def claimDividends():
    self._claimDividends(msg.sender)

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self._claimDividends(msg.sender)
    self._claimDividends(_to)
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    self._claimDividends(_from)
    self._claimDividends(_to)
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert self.mintable == True
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self._claimDividends(_to)
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != ZERO_ADDRESS
    self._claimDividends(_to)
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._claimDividends(msg.sender)
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self._claimDividends(msg.sender)
    self.allowances[_to][msg.sender] -= _value
    self._burn(_to, _value)