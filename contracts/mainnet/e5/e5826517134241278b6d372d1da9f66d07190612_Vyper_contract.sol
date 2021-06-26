# Copyright (C) 2021 VolumeFi Software, Inc.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License. 
#  This program is distributed WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  @author VolumeFi, Software inc.
#  @notice This Vyper contract adds liquidity to any Sushiswap pool using ETH or any ERC20 Token.
#  SPDX-License-Identifier: Apache-2.0

# @version ^0.2.0

interface ERC20:
    def approve(spender: address, amount: uint256): nonpayable
    def transfer(recipient: address, amount: uint256): nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256): nonpayable

interface SushiswapFactory:
    def getPair(tokenA: address, tokenB: address) -> address: view
    def createPair(tokenA: address, tokenB: address) -> address: nonpayable

interface SushiswapPair:
    def token0() -> address: view
    def token1() -> address: view
    def getReserves() -> (uint256, uint256, uint256): view
    def mint(to: address) -> uint256: nonpayable

interface SushiswapRouter:
    def addLiquidity(tokenA: address, tokenB: address, amountADesired: uint256, amountBDesired: uint256, amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable

interface WrappedEth:
    def deposit(): payable

event LPTokenMint:
    minter: address
    liquidity: uint256

DEADLINE: constant(uint256) = MAX_UINT256
SUSHISWAPROUTER: constant(address) = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
SUSHISWAPFACTORY: constant(address) = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

admin: public(address)
feeAmount: public(uint256)
feeAddress: public(address)
paused: public(bool)

@external
def __init__():
    self.paused = False
    self.admin = msg.sender
    self.feeAddress = 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.feeAmount = 5 * 10 ** 15

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
@pure
def _getPairTokens(pair: address) -> (address, address):
    token0: address = SushiswapPair(pair).token0()
    token1: address = SushiswapPair(pair).token1()
    return (token0, token1)

@internal
@view
def _calculateSwapInAmount(reserveIn: uint256, userIn: uint256) -> uint256:
    return ((self.uintSqrt(reserveIn * (userIn * 3988000 + reserveIn * 3988009))) - reserveIn * 1997) / 1994

@internal
@view
def _getLiquidityInPool(token: address, pair: address) -> uint256:
    res0: uint256 = 0
    res1: uint256 = 0
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    blockTimestampLast: uint256 = 0
    (res0, res1, blockTimestampLast) = SushiswapPair(pair).getReserves()
    (token0, token1) = self._getPairTokens(pair)
    assert token0 == token or token1 == token, "Token ERROR!"
    if token0 == token:
        return res0
    else:
        return res1

@internal
@view
def _getMidToken(midToken: address, token0: address, token1: address) -> address:
    pair0: address = SushiswapFactory(SUSHISWAPFACTORY).getPair(midToken, token0)
    pair1: address = SushiswapFactory(SUSHISWAPFACTORY).getPair(midToken, token1)
    midAmount0: uint256 = self._getLiquidityInPool(midToken, pair0)
    midAmount1: uint256 = self._getLiquidityInPool(midToken, pair1)
    if midAmount0 > midAmount1:
        return token0
    else:
        return token1

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    ERC20(fromToken).approve(SUSHISWAPROUTER, 0)
    ERC20(fromToken).approve(SUSHISWAPROUTER, tokens2Trade)
    
    addrBytes: Bytes[288] = concat(convert(tokens2Trade, bytes32), convert(0, bytes32), convert(160, bytes32), convert(self, bytes32), convert(deadline, bytes32), convert(2, bytes32), convert(fromToken, bytes32), convert(toToken, bytes32))
    funcsig: Bytes[4] = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")
    full_data: Bytes[292] = concat(funcsig, addrBytes)
    
    _response: Bytes[128] = raw_call(
        SUSHISWAPROUTER,
        full_data,
        max_outsize=128
    )
    tokenBought: uint256 = convert(slice(_response, 96, 32), uint256)
    assert tokenBought > 0, "Error Swapping Token 2"
    return tokenBought

@internal
def _swap(fromToken: address, pair: address, toSushipoolToken0: address, toSushipoolToken1: address, amount: uint256, deadline: uint256) -> (uint256, uint256):
    res0: uint256 = 0
    res1: uint256 = 0
    blockTimestampLast: uint256 = 0
    (res0, res1, blockTimestampLast) = SushiswapPair(pair).getReserves()
    token1Bought: uint256 = 0
    token0Bought: uint256 = 0
    if (fromToken == toSushipoolToken0):
        amountToSwap: uint256 = self._calculateSwapInAmount(res0, amount)
        if amountToSwap == 0:
            amountToSwap = amount / 2
        token1Bought = self._token2Token(fromToken, toSushipoolToken1, amountToSwap, deadline)
        token0Bought = amount - amountToSwap
    else:
        amountToSwap: uint256 = self._calculateSwapInAmount(res1, amount)
        if amountToSwap == 0:
            amountToSwap = amount / 2
        token0Bought = self._token2Token(fromToken, toSushipoolToken0, amountToSwap, deadline)
        token1Bought = amount - amountToSwap
    return (token0Bought, token1Bought)

@internal
def _sushiDeposit(token0: address, token1: address, amount0: uint256, amount1: uint256, sender: address, deadline: uint256) -> uint256:
    ERC20(token0).approve(SUSHISWAPROUTER, 0)
    ERC20(token1).approve(SUSHISWAPROUTER, 0)
    ERC20(token0).approve(SUSHISWAPROUTER, amount0)
    ERC20(token1).approve(SUSHISWAPROUTER, amount1)
    amountA: uint256 = 0
    amountB: uint256 = 0
    LP: uint256 = 0
    (amountA, amountB, LP) = SushiswapRouter(SUSHISWAPROUTER).addLiquidity(token0, token1, amount0, amount1, 1, 1, sender, deadline)
    if amount0 - amountA > 0:
        ERC20(token0).transfer(sender, amount0 - amountA)
    if amount1 - amountB > 0:
        ERC20(token1).transfer(sender, amount1 - amountB)
    return LP

@internal
def _performInvest(fromToken:address, pair:address, amount:uint256, sender: address, deadline: uint256) -> uint256:
    toSushiswapToken0: address = ZERO_ADDRESS
    toSushiswapToken1: address = ZERO_ADDRESS
    (toSushiswapToken0, toSushiswapToken1) = self._getPairTokens(pair)
    if fromToken != toSushiswapToken0 and fromToken != toSushiswapToken1:
        raise "Token Error"
    token0Bought: uint256 = 0
    token1Bought: uint256 = 0
    (token0Bought, token1Bought) = self._swap(fromToken, pair, toSushiswapToken0, toSushiswapToken1, amount, deadline)
    return self._sushiDeposit(toSushiswapToken0, toSushiswapToken1, token0Bought, token1Bought, sender, deadline)

@internal
def _add_liquidity(tokenA: address, tokenB: address, amountADesired: uint256, amountBDesired: uint256, amountAMin: uint256, amountBMin: uint256) -> (uint256, uint256, address):
    pair: address = SushiswapFactory(SUSHISWAPFACTORY).getPair(tokenA, tokenB)
    if pair == ZERO_ADDRESS:
        pair = SushiswapFactory(SUSHISWAPFACTORY).createPair(tokenA, tokenB)
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    amount0Min: uint256 = 0
    amount1Min: uint256 = 0
    amount0Desired: uint256 = 0
    amount1Desired: uint256 = 0
    amount0: uint256 = 0
    amount1: uint256 = 0
    ab_swapped: bool = False
    if convert(tokenA, uint256) < convert(tokenB, uint256):
        amount0Min = amountAMin
        amount1Min = amountBMin
        amount0Desired = amountADesired
        amount1Desired = amountBDesired
    else:
        amount0Min = amountBMin
        amount1Min = amountAMin
        amount0Desired = amountBDesired
        amount1Desired = amountADesired
        ab_swapped = True
    reserve0: uint256 = 0
    reserve1: uint256 = 0
    blockTimestampLast: uint256 = 0
    (reserve0, reserve1, blockTimestampLast) = SushiswapPair(pair).getReserves()
    if reserve0 == 0 and reserve1 == 0:
        return (amountADesired, amountBDesired, pair)
    amount1Optimal: uint256 = amount0Desired * reserve1 / reserve0
    if amount1Optimal <= amount1Desired:
        if ab_swapped:
            assert amount1Optimal >= amount1Min, "INSUFFICIENT_A_AMOUNT"
            return (amount1Optimal, amount0Desired, pair)
        else:
            assert amount1Optimal >= amount1Min, "INSUFFICIENT_B_AMOUNT"
            return (amount0Desired, amount1Optimal, pair)
        
    else:
        amount0Optimal: uint256 = amount1Desired * reserve0 / reserve1
        assert amount0Optimal <= amount0Desired, "DESIRED AMOUNT ERROR"
        if ab_swapped:
            assert amount0Optimal >= amount0Min, "INSUFFICIENT_B_AMOUNT"
            return (amount1Desired, amount0Optimal, pair)
        else:
            assert amount0Optimal >= amount0Min, "INSUFFICIENT_A_AMOUNT"
            return (amount0Optimal, amount1Desired, pair)

@external
@payable
@nonreentrant('lock')
def investTokenForSushiPair(token: address, pair: address, amount: uint256, minPoolTokens: uint256, deadline: uint256=DEADLINE) -> uint256:
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
    LPBought: uint256 = 0
    midToken: address = WETH
    toInvest: uint256 = 0
    # invest ETH
    if token == VETH or token == ZERO_ADDRESS:
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
    if token0 == WETH or token1 == WETH or token == token0 or token == token1:
        LPBought = self._performInvest(midToken, pair, toInvest, msg.sender, deadline)
    else:
        midToken = self._getMidToken(WETH, token0, token1)
        toInvest = self._token2Token(WETH, midToken, toInvest, deadline)
        LPBought = self._performInvest(midToken, pair, toInvest, msg.sender, deadline)
    assert LPBought >= minPoolTokens, "High Slippage"
    return LPBought

@external
@nonreentrant('lock')
def addLiquidity(tokenA: address, tokenB: address, amountADesired: uint256, amountBDesired: uint256, amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256=DEADLINE) -> (uint256, uint256, uint256):
    assert deadline >= block.timestamp, "EXPIRED"
    amountA: uint256 = 0
    amountB: uint256 = 0
    liquidity: uint256 = 0
    pair: address = ZERO_ADDRESS
    (amountA, amountB, pair) = self._add_liquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin)
    ERC20(tokenA).transferFrom(msg.sender, pair, amountA)
    ERC20(tokenB).transferFrom(msg.sender, pair, amountB)
    liquidity = SushiswapPair(pair).mint(to)
    log LPTokenMint(msg.sender, liquidity)
    return (amountA, amountB, liquidity)

@external
@payable
@nonreentrant('lock')
def addLiquidityETH(token: address, amountTokenDesired: uint256, amountTokenMin: uint256, amountETHMin: uint256, to: address, deadline: uint256=DEADLINE) -> (uint256, uint256, uint256):
    assert deadline >= block.timestamp, "EXPIRED"
    amountToken: uint256 = 0
    amountETH: uint256 = 0
    liquidity: uint256 = 0
    pair: address = ZERO_ADDRESS
    (amountToken, amountETH, pair) = self._add_liquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin)
    ERC20(token).transferFrom(msg.sender, pair, amountToken)
    WrappedEth(WETH).deposit(value=amountETH)
    if msg.value > amountETH:
        send(msg.sender, msg.value - amountETH)
    ERC20(WETH).transfer(pair, amountETH)
    liquidity = SushiswapPair(pair).mint(to)
    log LPTokenMint(msg.sender, liquidity)
    return (amountToken, amountETH, liquidity)

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
@payable
def __default__(): pass