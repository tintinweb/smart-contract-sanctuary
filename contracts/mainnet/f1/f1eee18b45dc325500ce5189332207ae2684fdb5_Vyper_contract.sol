#  @version ^0.2.12
from vyper.interfaces import ERC20

PRICE: constant(uint256) = 200 # 1 ETH is worth X


event CharityChange:
    charity: indexed(address)
    status: bool


event AdminChange:
    admin: indexed(address)


event Purchase:
    buyer: indexed(address)
    liquidity: uint256
    value: uint256


interface IUniswapRouter:
    def addLiquidityETH(
        token: address,
        amountTokenDesired: uint256,
        amountTokenMin: uint256,
        amountETHMin: uint256,
        to: address,
        deadline: uint256,
    ) -> (uint256, uint256, uint256):
        payable


uniswap: public(IUniswapRouter)
saleToken: public(ERC20)

admin: public(address)
charity: public(HashMap[address, bool])

expires: public(uint256)
raised: public(uint256)


@external
def __init__(_uniswap: address, _saleToken: address, _admin: address, _expires: uint256):
    self.uniswap = IUniswapRouter(_uniswap)
    self.saleToken = ERC20(_saleToken)
    self.saleToken.approve(_uniswap, MAX_UINT256)
    self.admin = _admin
    self.expires = _expires


@internal
@view
def _estimate(_value: uint256) -> (uint256, uint256, uint256, uint256):
    token: uint256 = _value * PRICE # (in token)
    liquidity: uint256 = token / 5 # 20% of tokens (in token)
    charity: uint256 = _value / 3 # (in ETH)
    founder: uint256 = _value - (charity + _value / 2) # (in ETH)
    return (token, liquidity, charity, founder)


@external
def updateCharity(_charity: address, status: bool):
    """
    @notice
        Update charity status
    @param _charity
        Charity to update
    @param status
        True if charity can be donated
    """
    assert msg.sender == self.admin
    self.charity[_charity] = status
    log CharityChange(_charity, status)


@external
def updateAdmin(_to: address):
    """
    @notice
        Change admin
    @param _to
        Address of new admin
    """
    assert msg.sender == self.admin
    self.admin = _to
    log AdminChange(_to)


@external
def recover(token: address):
    assert msg.sender == self.admin
    assert block.timestamp > self.expires + 86400 * 180
    assert token != self.saleToken.address, "Sale: Cannot recover sale tokens"
    ERC20(token).transfer(msg.sender, ERC20(token).balanceOf(self))


@external
@payable
def purchase(_min: uint256, _charity: address) -> uint256:
    """
    @notice
        Purchase tokens through sale
    @param _min
        Minimum output for saleToken
    @param _charity
        Address of charity to donate
    @return
        Amount sent in saleToken
    """
    assert self.charity[_charity], "Sale: Unknown charity"
    assert self.expires > block.timestamp, "Sale: Sale expired"
    self.raised += msg.value
    token: uint256 = 0
    liquidity: uint256 = 0
    charity: uint256 = 0
    founder: uint256 = 0
    (token, liquidity, charity, founder) = self._estimate(msg.value)
    if liquidity > 0:
        # Remaining from liquidity and value
        # will be refunded to the contract and
        # admin will receive these tokens.
        self.uniswap.addLiquidityETH(
            self.saleToken.address,
            liquidity,
            0,
            0,
            self,
            block.timestamp,
            value=msg.value/2,
        )
    token = min(token, self.saleToken.balanceOf(self))
    assert token >= _min, "Sale: Token amount below user set minimum"
    self.saleToken.transfer(msg.sender, token)
    send(_charity, min(charity, self.balance))
    send(self.admin, self.balance)
    log Purchase(msg.sender, liquidity, token)
    return token


@external
def burn():
    """
    @notice
        Burn tokens
    @dev
        Only after sale is expired
    """
    assert block.timestamp > self.expires
    self.saleToken.transfer(ZERO_ADDRESS, self.saleToken.balanceOf(self))


@external
@view
def estimate(_value: uint256) -> (uint256, uint256, uint256, uint256):
    """
    @notice
        Estimate tokens to receive for specific value
    @param _value
        Amount in ETH to purchase tokens
    @return
        Amount in sale token to receive
        Amount in ETH for liquidity
        Amount in ETH for charity
        Amount in ETH for founders
    """
    return self._estimate(_value)