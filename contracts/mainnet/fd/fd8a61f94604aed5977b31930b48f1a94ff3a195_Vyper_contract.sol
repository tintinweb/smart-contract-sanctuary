# @version ^0.2.0

interface ERC20:
    def approve(spender: address, amount: uint256): nonpayable
    def transfer(recipient: address, amount: uint256): nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256): nonpayable

interface UniswapV2Pair:
    def token0() -> address: view
    def token1() -> address: view
    def getReserves() -> (uint256, uint256, uint256): view

interface UniswapV2Router02:
    def addLiquidity(tokenA: address, tokenB: address, amountADesired: uint256, amountBDesired: uint256, amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable

interface WrappedEth:
    def deposit(): payable

UNISWAPV2ROUTER02: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEADLINE: constant(uint256) = MAX_UINT256 # change

paused: public(bool)
admin: public(address)
feeAmount: public(uint256)
feeAddress: public(address)

event TestValue:
    value: uint256
    text: String[256]

event TestAddress:
    addr: address
    text: String[256]

event TestData:
    data: bytes32
    text: String[256]

@external
def __init__():
    self.paused = False
    self.admin = msg.sender
    self.feeAddress = 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.feeAmount = 5 * 10 ** 15

@internal
@pure
def _getPairTokens(pair: address) -> (address, address):
    token0: address = UniswapV2Pair(pair).token0()
    token1: address = UniswapV2Pair(pair).token1()
    return (token0, token1)

@internal
@pure
def uintSqrt(y: uint256) -> uint256:
    z: uint256 = 0
    x: uint256 = 0
    if y > 3:
        z = y
        x = y / 2 + 1
        for i in range(256):
            if x >= z:
                break
            z = x
            x = (y / x + x) / 2
    elif y != 0:
        z = 1
    else:
        z = 0
    return z

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    ERC20(fromToken).approve(UNISWAPV2ROUTER02, 0)
    ERC20(fromToken).approve(UNISWAPV2ROUTER02, tokens2Trade)
    
    addrBytes: Bytes[288] = concat(convert(tokens2Trade, bytes32), convert(0, bytes32), convert(160, bytes32), convert(self, bytes32), convert(deadline, bytes32), convert(2, bytes32), convert(fromToken, bytes32), convert(toToken, bytes32))
    funcsig: Bytes[4] = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")
    full_data: Bytes[292] = concat(funcsig, addrBytes)
    
    _response: Bytes[128] = raw_call(
        UNISWAPV2ROUTER02,
        full_data,
        max_outsize=128
    )
    tokenBought: uint256 = convert(slice(_response, 96, 32), uint256)
    assert tokenBought > 0, "Error Swapping Token 2"
    return tokenBought

@internal
@view
def _calculateSwapInAmount(reserveIn: uint256, userIn: uint256) -> uint256:
    return ((self.uintSqrt(reserveIn * (userIn * 3988000 + reserveIn * 3988009))) - reserveIn * 1997) / 1994

@internal
def _swap(fromToken: address, pair: address, toUnipoolToken0: address, toUnipoolToken1: address, amount: uint256, deadline: uint256) -> (uint256, uint256):
    res0: uint256 = 0
    res1: uint256 = 0
    blockTimestampLast: uint256 = 0
    (res0, res1, blockTimestampLast) = UniswapV2Pair(pair).getReserves()
    token1Bought: uint256 = 0
    token0Bought: uint256 = 0
    if (fromToken == toUnipoolToken0):
        amountToSwap: uint256 = self._calculateSwapInAmount(res0, amount)
        if amountToSwap == 0:
            amountToSwap = amount / 2
        token1Bought = self._token2Token(fromToken, toUnipoolToken1, amountToSwap, deadline)
        token0Bought = amount - amountToSwap
    else:
        amountToSwap: uint256 = self._calculateSwapInAmount(res1, amount)
        if amountToSwap == 0:
            amountToSwap = amount / 2
        token0Bought = self._token2Token(fromToken, toUnipoolToken0, amountToSwap, deadline)
        token1Bought = amount - amountToSwap
    return (token0Bought, token1Bought)

@internal
def _uniDeposit(token0: address, token1: address, amount0: uint256, amount1: uint256, sender: address, deadline: uint256) -> uint256:
    ERC20(token0).approve(UNISWAPV2ROUTER02, 0)
    ERC20(token1).approve(UNISWAPV2ROUTER02, 0)
    ERC20(token0).approve(UNISWAPV2ROUTER02, amount0)
    ERC20(token1).approve(UNISWAPV2ROUTER02, amount1)
    amountA: uint256 = 0
    amountB: uint256 = 0
    LP: uint256 = 0
    (amountA, amountB, LP) = UniswapV2Router02(UNISWAPV2ROUTER02).addLiquidity(token0, token1, amount0, amount1, 1, 1, sender, deadline)
    if amount0 - amountA > 0:
        ERC20(token0).transfer(sender, amount0 - amountA)
    if amount1 - amountB > 0:
        ERC20(token1).transfer(sender, amount1 - amountB)
    return LP

@internal
def _performInvest(fromToken:address, pair:address, amount:uint256, sender: address, deadline: uint256) -> uint256:
    toUniswapToken0: address = ZERO_ADDRESS
    toUniswapToken1: address = ZERO_ADDRESS
    (toUniswapToken0, toUniswapToken1) = self._getPairTokens(pair)
    if fromToken != toUniswapToken0 and fromToken != toUniswapToken1:
        raise "Token Error"
    token0Bought: uint256 = 0
    token1Bought: uint256 = 0
    (token0Bought, token1Bought) = self._swap(fromToken, pair, toUniswapToken0, toUniswapToken1, amount, deadline)
    return self._uniDeposit(toUniswapToken0, toUniswapToken1, token0Bought, token1Bought, sender, deadline)

@external
@payable
@nonreentrant('lock')
def investTokenForEthPair(token: address, pair: address, amount: uint256, minPoolTokens: uint256, deadline: uint256=MAX_UINT256) -> uint256:
    assert not self.paused, "Paused"
    fee: uint256 = self.feeAmount
    msg_value: uint256 = msg.value
    assert msg.value >= fee, "Insufficient fee"
    send(self.feeAddress, fee)
    msg_value -= fee
    assert amount > 0, "Invalid input amount"
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    (token0, token1) = self._getPairTokens(pair)
    if token0 != WETH and token1 != WETH:
        raise "Not ETH Pair"
    midToken: address = WETH
    toInvest: uint256 = 0
    LPBought: uint256 = 0
    # invest ETH
    if token == VETH:
        assert msg_value >= amount, "ETH not enough"
        # return remaining ETH
        if msg_value > amount:
            send(msg.sender, msg_value - amount)
        toInvest = amount
        WrappedEth(WETH).deposit(value=toInvest)
    # invest Token
    else:
        ERC20(token).transferFrom(msg.sender, self, amount)
        if msg_value > 0:
            send(msg.sender, msg_value)
        if token == WETH:
            toInvest = amount
        elif token != token0 and token != token1:
            toInvest = self._token2Token(token, WETH, amount, deadline)
        else:
            midToken = token
            toInvest = amount
    LPBought = self._performInvest(midToken, pair, toInvest, msg.sender, deadline)
    assert LPBought >= minPoolTokens, "High Slippage"
    return LPBought

# Admin functions
@external
def pause(_paused: bool):
    assert msg.sender == self.admin, "Not admin"
    self.paused = _paused

@external
def newAdmin(_admin: address):
    assert msg.sender == self.admin, "Not admin"
    self.admin = _admin

@external
def newFeeAmount(_feeAmount: uint256):
    assert msg.sender == self.admin, "Not admin"
    self.feeAmount = _feeAmount

@external
def newFeeAddress(_feeAddress: address):
    assert msg.sender == self.admin, "Not admin"
    self.feeAddress = _feeAddress

@external
def seizeMany(token: address[8], amount: uint256[8], to: address[8]):
    assert msg.sender == self.admin, "Not admin"
    for i in range(8):
        if token[i] == VETH:
            send(to[i], amount[i])
        elif token[i] != ZERO_ADDRESS:
            ERC20(token[i]).transfer(to[i], amount[i])

@external
def seize(token: address, amount: uint256, to: address):
    assert msg.sender == self.admin, "Not admin"
    if token == VETH:
        send(to, amount)
    elif token != ZERO_ADDRESS:
        ERC20(token).transfer(to, amount)

@external
@payable
def __default__(): pass