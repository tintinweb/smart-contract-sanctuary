# Copyright (C) 2021 VolumeFi Software, Inc.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License. 
#  This program is distributed WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  @author VolumeFi, Software inc.
#  @notice This Vyper contract is for Dancing Bananas.
#  SPDX-License-Identifier: Apache-2.0

# @version ^0.2.12

struct MintParams:
    token0: address
    token1: address
    fee: uint256
    tickLower: int128
    tickUpper: int128
    amount0Desired: uint256
    amount1Desired: uint256
    amount0Min: uint256
    amount1Min: uint256
    recipient: address
    deadline: uint256

struct SingleMintParams:
    token0: address
    token1: address
    fee: uint256
    tickLower: int128
    tickUpper: int128
    sqrtPriceAX96: uint256
    sqrtPriceBX96: uint256
    liquidityMin: uint256
    recipient: address
    deadline: uint256

struct RemoveParams:
    liquidity: uint256
    recipient: address
    deadline: uint256

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

interface NonfungiblePositionManager:
    def burn(tokenId: uint256): payable

interface ERC20:
    def approve(account: address, amount: uint256): nonpayable
    def transfer(account: address, amount: uint256): nonpayable
    def transferFrom(_from: address, _to: address, amount: uint256): nonpayable

interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB: address) -> address: view

interface UniswapV2Pair:
    def token0() -> address: view
    def getReserves() -> (uint256, uint256, uint256): view

event AddedLiquidity:
    tokenId: indexed(uint256)
    token0: indexed(address)
    token1: indexed(address)
    liquidity: uint256
    amount0: uint256
    amount1: uint256

event RemovedLiquidity:
    tokenId: indexed(uint256)
    token0: indexed(address)
    token1: indexed(address)
    liquidity: uint256
    amount0: uint256
    amount1: uint256

event Paused:
    paused: bool

event FeeChanged:
    newFee: uint256

NONFUNGIBLEPOSITIONMANAGER: constant(address) = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
UNISWAPV3FACTORY: constant(address) = 0x1F98431c8aD98523631AE4a59f267346ea31F984
UNISWAPV2FACTORY: constant(address) = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
UNISWAPV2ROUTER02: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

CAIPIN_MID: constant(Bytes[4]) = method_id("createAndInitializePoolIfNecessary(address,address,uint24,uint160)")
GETPOOL_MID: constant(Bytes[4]) = method_id("getPool(address,address,uint24)")
SLOT0_MID: constant(Bytes[4]) = method_id("slot0()")
MINT_MID: constant(Bytes[4]) = method_id("mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256))")
INCREASELIQUIDITY_MID: constant(Bytes[4]) = method_id("increaseLiquidity((uint256,uint256,uint256,uint256,uint256,uint256))")
DECREASELIQUIDITY_MID: constant(Bytes[4]) = method_id("decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))")
POSITIONS_MID: constant(Bytes[4]) = method_id("positions(uint256)")
COLLECT_MID: constant(Bytes[4]) = method_id("collect((uint256,address,uint128,uint128))")
SWAPETFT_MID: constant(Bytes[4]) = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")

ADDLIQETH_MID: constant(Bytes[4]) = method_id("addLiquidityEthForUniV3(uint256,(address,address,uint256,int128,int128,uint256,uint256,uint256,uint256,address,uint256))")
_ADDLIQETH_MID: constant(Bytes[4]) = method_id("_addLiquidityEthForUniV3(uint256,(address,address,uint256,int128,int128,uint256,uint256,uint256,uint256,address,uint256),address,uint256)")
ADDLIQ_MID: constant(Bytes[4]) = method_id("addLiquidityForUniV3(uint256,(address,address,uint256,int128,int128,uint256,uint256,uint256,uint256,address,uint256))")
_ADDLIQ_MID: constant(Bytes[4]) = method_id("_addLiquidityForUniV3(uint256,(address,address,uint256,int128,int128,uint256,uint256,uint256,uint256,address,uint256),address)")
INVEST_MID: constant(Bytes[4]) = method_id("investTokenForUniPair(uint256,address,uint256,(address,address,uint256,int128,int128,uint256,uint256,uint256,address,uint256))")
_INVEST_MID: constant(Bytes[4]) = method_id("_investTokenForUniPair(uint256,address,uint256,(address,address,uint256,int128,int128,uint256,uint256,uint256,address,uint256),address,uint256)")
REMOVELIQ_MID: constant(Bytes[4]) = method_id("removeLiquidityFromUniV3NFLP(uint256,(uint256,address,uint256))")
_REMOVELIQ_MID: constant(Bytes[4]) = method_id("_removeLiquidityFromUniV3NFLP(uint256,(uint256,address,uint256))")
REMOVELIQETH_MID: constant(Bytes[4]) = method_id("removeLiquidityEthFromUniV3NFLP(uint256,(uint256,address,uint256))")
_REMOVELIQETH_MID: constant(Bytes[4]) = method_id("_removeLiquidityEthFromUniV3NFLP(uint256,(uint256,address,uint256))")
DIVEST_MID: constant(Bytes[4]) = method_id("divestUniV3NFLPToToken(uint256,address,(uint256,address,uint256),uint256)")
_DIVEST_MID: constant(Bytes[4]) = method_id("_divestUniV3NFLPToToken(uint256,address,(uint256,address,uint256),uint256)")

paused: public(bool)
admin: public(address)
feeAddress: public(address)
feeAmount: public(uint256)

@external
def __init__():
    self.paused = False
    self.admin = msg.sender
    self.feeAddress = 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.feeAmount = 5 * 10 ** 15

@internal
@pure
def getCurrentSqrtPriceX96(token0: address, token1: address, feeLevel: uint256) -> uint256:
    _response32: Bytes[32] = raw_call(
        UNISWAPV3FACTORY,
        concat(
            GETPOOL_MID,
            convert(token0, bytes32),
            convert(token1, bytes32),
            convert(feeLevel, bytes32)
        ),
        max_outsize=32,
        is_static_call=True
    )
    pool: address = convert(convert(_response32, bytes32), address)
    assert pool != ZERO_ADDRESS
    _response224: Bytes[224] = raw_call(
        pool,
        SLOT0_MID,
        max_outsize=224,
        is_static_call=True
    )
    sqrtPriceX96: uint256 = convert(slice(_response224, 0, 32), uint256)
    assert sqrtPriceX96 != 0
    return sqrtPriceX96

@internal
def addLiquidity(_tokenId: uint256, sender: address, uniV3Params: MintParams, _sqrtPriceX96: uint256 = 0) -> (uint256, uint256, uint256):
    ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, uniV3Params.amount0Desired)
    ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, uniV3Params.amount1Desired)
    if _tokenId == 0:
        sqrtPriceX96: uint256 = _sqrtPriceX96
        if sqrtPriceX96 == 0:
            sqrtPriceX96 = self.getCurrentSqrtPriceX96(uniV3Params.token0, uniV3Params.token1, uniV3Params.fee)
        _response32: Bytes[32] = raw_call(
            NONFUNGIBLEPOSITIONMANAGER,
            concat(
                CAIPIN_MID,
                convert(uniV3Params.token0, bytes32),
                convert(uniV3Params.token1, bytes32),
                convert(uniV3Params.fee, bytes32),
                convert(sqrtPriceX96, bytes32)
            ),
            max_outsize=32
        )
        assert convert(convert(_response32, bytes32), address) != ZERO_ADDRESS
        _response128: Bytes[128] = raw_call(
            NONFUNGIBLEPOSITIONMANAGER,
            concat(
                MINT_MID,
                convert(uniV3Params.token0, bytes32),
                convert(uniV3Params.token1, bytes32),
                convert(uniV3Params.fee, bytes32),
                convert(uniV3Params.tickLower, bytes32),
                convert(uniV3Params.tickUpper, bytes32),
                convert(uniV3Params.amount0Desired, bytes32),
                convert(uniV3Params.amount1Desired, bytes32),
                convert(uniV3Params.amount0Min, bytes32),
                convert(uniV3Params.amount1Min, bytes32),
                convert(uniV3Params.recipient, bytes32),
                convert(uniV3Params.deadline, bytes32)
            ),
            max_outsize=128
        )
        tokenId: uint256 = convert(slice(_response128, 0, 32), uint256)
        liquidity: uint256 = convert(slice(_response128, 32, 32), uint256)
        amount0: uint256 = convert(slice(_response128, 64, 32), uint256)
        amount1: uint256 = convert(slice(_response128, 96, 32), uint256)
        log AddedLiquidity(tokenId, uniV3Params.token0, uniV3Params.token1, liquidity, amount0, amount1)
        return (amount0, amount1, liquidity)
    else:
        liquidity: uint256 = 0
        amount0: uint256 = 0
        amount1: uint256 = 0
        _response96: Bytes[96] = raw_call(
            NONFUNGIBLEPOSITIONMANAGER,
            concat(
                INCREASELIQUIDITY_MID,
                convert(_tokenId, bytes32),
                convert(uniV3Params.amount0Desired, bytes32),
                convert(uniV3Params.amount1Desired, bytes32),
                convert(uniV3Params.amount0Min, bytes32),
                convert(uniV3Params.amount1Min, bytes32),
                convert(uniV3Params.deadline, bytes32)
            ),
            max_outsize=96
        )
        liquidity = convert(slice(_response96, 0, 32), uint256)
        amount0 = convert(slice(_response96, 32, 32), uint256)
        amount1 = convert(slice(_response96, 64, 32), uint256)
        log AddedLiquidity(_tokenId, uniV3Params.token0, uniV3Params.token1, liquidity, amount0, amount1)
        return (amount0, amount1, liquidity)

@internal
def removeLiquidity(_tokenId: uint256, _removeParams: RemoveParams, _recipient: address=ZERO_ADDRESS) -> (address, address, uint256, uint256):
    _response384: Bytes[384] = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            POSITIONS_MID,
            convert(_tokenId, bytes32)
        ),
        max_outsize=384,
        is_static_call=True
    )
    token0: address = convert(convert(slice(_response384, 64, 32), uint256), address)
    token1: address = convert(convert(slice(_response384, 96, 32), uint256), address)
    liquidity: uint256 = convert(slice(_response384, 224, 32), uint256)
    isBurn: bool = False
    if liquidity <= _removeParams.liquidity:
        isBurn = True
    else:
        liquidity = _removeParams.liquidity
    _response64: Bytes[64] = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            DECREASELIQUIDITY_MID,
            convert(_tokenId, bytes32),
            convert(liquidity, bytes32),
            convert(0, bytes32),
            convert(0, bytes32),
            convert(_removeParams.deadline, bytes32)
        ),
        max_outsize=64
    )
    recipient: address = _recipient
    if _recipient == ZERO_ADDRESS:
        recipient = _removeParams.recipient

    _response64 = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            COLLECT_MID,
            convert(_tokenId, bytes32),
            convert(recipient, bytes32),
            convert(2 ** 128 - 1, bytes32),
            convert(2 ** 128 - 1, bytes32)
        ),
        max_outsize=64
    )
    amount0: uint256 = convert(slice(_response64, 0, 32), uint256)
    amount1: uint256 = convert(slice(_response64, 32, 32), uint256)
    if isBurn:
        NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).burn(_tokenId)

    log RemovedLiquidity(_tokenId, token0, token1, liquidity, amount0, amount1)

    return (token0, token1, amount0, amount1)

@external
def _addLiquidityEthForUniV3(_tokenId: uint256, uniV3Params: MintParams, msg_sender: address, msg_value: uint256):
    assert msg.sender == self
    assert not self.paused
    assert convert(uniV3Params.token0, uint256) < convert(uniV3Params.token1, uint256)
    if uniV3Params.token0 == WETH:
        if msg_value > uniV3Params.amount0Desired:
            send(msg_sender, msg_value - uniV3Params.amount0Desired)
        else:
            assert msg_value == uniV3Params.amount0Desired
        WrappedEth(WETH).deposit(value=uniV3Params.amount0Desired)
        ERC20(uniV3Params.token1).transferFrom(msg_sender, self, uniV3Params.amount1Desired)
        amount0: uint256 = 0
        amount1: uint256 = 0
        liquidity: uint256 = 0
        (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg_sender, uniV3Params)
        amount0 = uniV3Params.amount0Desired - amount0
        amount1 = uniV3Params.amount1Desired - amount1
        if amount0 > 0:
            WrappedEth(WETH).withdraw(amount0)
            send(msg_sender, amount0)
            ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
        if amount1 > 0:
            ERC20(uniV3Params.token1).transfer(msg_sender, amount1)
            ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
    else:
        assert uniV3Params.token1 == WETH
        if msg_value > uniV3Params.amount1Desired:
            send(msg_sender, msg_value - uniV3Params.amount1Desired)
        else:
            assert msg_value == uniV3Params.amount1Desired
        WrappedEth(WETH).deposit(value=uniV3Params.amount1Desired)
        ERC20(uniV3Params.token0).transferFrom(msg_sender, self, uniV3Params.amount0Desired)
        amount0: uint256 = 0
        amount1: uint256 = 0
        liquidity: uint256 = 0
        (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg_sender, uniV3Params)
        amount0 = uniV3Params.amount0Desired - amount0
        amount1 = uniV3Params.amount1Desired - amount1
        if amount0 > 0:
            ERC20(uniV3Params.token0).transfer(msg_sender, amount0)
            ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
        if amount1 > 0:
            WrappedEth(WETH).withdraw(amount1)
            send(msg_sender, amount1)
            ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)

@external
def _addLiquidityForUniV3(_tokenId: uint256, uniV3Params: MintParams, msg_sender: address):
    assert msg.sender == self
    assert not self.paused
    assert convert(uniV3Params.token0, uint256) < convert(uniV3Params.token1, uint256)
    ERC20(uniV3Params.token0).transferFrom(msg_sender, self, uniV3Params.amount0Desired)
    ERC20(uniV3Params.token1).transferFrom(msg_sender, self, uniV3Params.amount1Desired)
    amount0: uint256 = 0
    amount1: uint256 = 0
    liquidity: uint256 = 0
    (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg_sender, uniV3Params)
    amount0 = uniV3Params.amount0Desired - amount0
    amount1 = uniV3Params.amount1Desired - amount1
    if amount0 > 0:
        ERC20(uniV3Params.token0).transfer(msg_sender, amount0)
        ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
    if amount1 > 0:
        ERC20(uniV3Params.token1).transfer(msg_sender, amount1)
        ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)

@external
def _removeLiquidityFromUniV3NFLP(_tokenId: uint256, _removeParams: RemoveParams):
    assert msg.sender == self
    assert _tokenId != 0
    self.removeLiquidity(_tokenId, _removeParams)

@external
def _removeLiquidityEthFromUniV3NFLP(_tokenId: uint256, _removeParams: RemoveParams):
    assert msg.sender == self
    assert _tokenId != 0
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    amount0: uint256 = 0
    amount1: uint256 = 0
    (token0, token1, amount0, amount1) = self.removeLiquidity(_tokenId, _removeParams, self)
    if token0 == WETH and token1 != WETH:
        WrappedEth(token0).withdraw(amount0)
        send(_removeParams.recipient, amount0)
        ERC20(token1).transfer(_removeParams.recipient, amount1)
    elif token1 == WETH and token0 != WETH:
        WrappedEth(token1).withdraw(amount1)
        send(_removeParams.recipient, amount1)
        ERC20(token0).transfer(_removeParams.recipient, amount0)
    else:
        raise "Not Eth Pair"

@internal
def token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    ERC20(fromToken).approve(UNISWAPV2ROUTER02, tokens2Trade)
    _response: Bytes[128] = raw_call(
        UNISWAPV2ROUTER02,
        concat(
            SWAPETFT_MID,
            convert(tokens2Trade, bytes32),
            convert(0, bytes32),
            convert(160, bytes32),
            convert(self, bytes32),
            convert(deadline, bytes32),
            convert(2, bytes32),
            convert(fromToken, bytes32),
            convert(toToken, bytes32)
        ),
        max_outsize=128
    )
    tokenBought: uint256 = convert(slice(_response, 96, 32), uint256)
    ERC20(fromToken).approve(UNISWAPV2ROUTER02, 0)
    assert tokenBought > 0
    return tokenBought

@internal
@view
def getVirtualPriceX96(sqrtPriceAX96: uint256, sqrtPriceX96: uint256, sqrtPriceBX96: uint256) -> uint256:
    ret: uint256 = (sqrtPriceBX96 - sqrtPriceX96) * 2 ** 96 / sqrtPriceBX96 * 2 ** 96 / sqrtPriceX96 * 2 ** 96 / (sqrtPriceX96 - sqrtPriceAX96)
    if ret > 2 ** 160:
        return 2 ** 160
    else:
        return ret

@internal
@pure
def uintSqrt(x: uint256) -> uint256:
    if x > 3:
        z: uint256 = (x + 1) / 2
        y: uint256 = x
        for i in range(256):
            if y == z:
                return y
            y = z
            z = (x / z + z) / 2
        raise "Did not coverage"
    elif x == 0:
        return 0
    else:
        return 1

@internal
@view
def getUserInForSqrtPriceX96(reserveIn: uint256, reserveOut: uint256, priceX96: uint256, toInvest: uint256) -> uint256:
    b: uint256 = reserveIn + (reserveOut * 997 / 1000 * 2 ** 96 / priceX96) - toInvest * 997 / 1000
    return (self.uintSqrt(b * b + 4 * reserveIn * toInvest * 997 / 1000) - b) * 1000 / 1994

@internal
@pure
def _getLiquidityInPool(midToken: address, pair: address) -> uint256:
    res0: uint256 = 0
    res1: uint256 = 0
    blockTimestampLast: uint256 = 0
    (res0, res1, blockTimestampLast) = UniswapV2Pair(pair).getReserves()
    token0: address = UniswapV2Pair(pair).token0()
    if token0 == midToken:
        return res0
    else:
        return res1

@internal
@view
def getMidToken(midToken: address, token0: address, token1: address) -> address:
    if midToken == token0 or midToken == token1:
        return midToken
    pair0: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, token0)
    pair1: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, token1)
    eth0: uint256 = self._getLiquidityInPool(midToken, pair0)
    eth1: uint256 = self._getLiquidityInPool(midToken, pair1)
    if eth0 > eth1:
        return token0
    else:
        return token1

@external
def _investTokenForUniPair(_tokenId: uint256, _token: address, amount: uint256, _uniV3Params: SingleMintParams, msg_sender: address, msg_value: uint256):
    assert msg.sender == self
    assert not self.paused
    assert amount > 0
    uniV3Params: MintParams = MintParams({
        token0: _uniV3Params.token0,
        token1: _uniV3Params.token1,
        fee: _uniV3Params.fee,
        tickLower: _uniV3Params.tickLower,
        tickUpper: _uniV3Params.tickUpper,
        amount0Desired: 0,
        amount1Desired: 0,
        amount0Min: 0,
        amount1Min: 0,
        recipient: _uniV3Params.recipient,
        deadline: _uniV3Params.deadline
    })
    assert convert(uniV3Params.token0, uint256) < convert(uniV3Params.token1, uint256)
    token: address = _token
    toInvest: uint256 = 0
    midToken: address = WETH
    if token == VETH or token == ZERO_ADDRESS:
        if msg_value > amount:
            send(msg_sender, msg_value - amount)
        else:
            assert msg_value == amount
        WrappedEth(WETH).deposit(value=amount)
        token = WETH
        toInvest = amount
    else:
        ERC20(token).transferFrom(msg_sender, self, amount)
        if msg_value > 0:
            send(msg_sender, msg_value)
        if token == WETH:
            toInvest = amount
        elif token != uniV3Params.token0 and token != uniV3Params.token1:
            toInvest = self.token2Token(token, WETH, amount, uniV3Params.deadline)
        else:
            midToken = token
            toInvest = amount

    if uniV3Params.token0 != WETH and uniV3Params.token1 != WETH and token != uniV3Params.token0 and token != uniV3Params.token1:
        midToken = self.getMidToken(WETH, uniV3Params.token0, uniV3Params.token1)
        toInvest = self.token2Token(WETH, midToken, toInvest, uniV3Params.deadline)

    res0: uint256 = 0
    res1: uint256 = 0
    blockTimestampLast: uint256 = 0
    pair: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(uniV3Params.token0, uniV3Params.token1)
    endToken: address = ZERO_ADDRESS
    if midToken == uniV3Params.token0:
        (res0, res1, blockTimestampLast) = UniswapV2Pair(pair).getReserves()
        endToken = uniV3Params.token1
    else:
        (res1, res0, blockTimestampLast) = UniswapV2Pair(pair).getReserves()
        endToken = uniV3Params.token0

    sqrtPriceX96: uint256 = 0

    sqrtPriceX96 = self.getCurrentSqrtPriceX96(uniV3Params.token0, uniV3Params.token1, uniV3Params.fee)

    retAmount: uint256 = 0
    swapAmount: uint256 = 0
    if sqrtPriceX96 <= _uniV3Params.sqrtPriceAX96:
        if convert(midToken, uint256) > convert(endToken, uint256):
            swapAmount = toInvest
    elif sqrtPriceX96 >= _uniV3Params.sqrtPriceBX96:
        if convert(midToken, uint256) < convert(endToken, uint256):
            swapAmount = toInvest
    else:
        virtualPriceX96: uint256 = self.getVirtualPriceX96(_uniV3Params.sqrtPriceAX96, sqrtPriceX96, _uniV3Params.sqrtPriceBX96)
        if convert(midToken, uint256) > convert(endToken, uint256):
            swapAmount = self.getUserInForSqrtPriceX96(res0, res1, virtualPriceX96, toInvest)
        else:
            swapAmount = self.getUserInForSqrtPriceX96(res0, res1, 2 ** 192 / virtualPriceX96, toInvest)

    if swapAmount > toInvest:
        swapAmount = toInvest

    if swapAmount > 0:
        retAmount = self.token2Token(midToken, endToken, swapAmount, uniV3Params.deadline)

    if uniV3Params.token0 == midToken:
        uniV3Params.amount0Desired = toInvest - swapAmount
        uniV3Params.amount1Desired = retAmount
    else:
        uniV3Params.amount1Desired = toInvest - swapAmount
        uniV3Params.amount0Desired = retAmount

    amount0: uint256 = 0
    amount1: uint256 = 0
    liquidity: uint256 = 0
    (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg_sender, uniV3Params, sqrtPriceX96)
    assert liquidity >= _uniV3Params.liquidityMin
    amount0 = uniV3Params.amount0Desired - amount0
    amount1 = uniV3Params.amount1Desired - amount1
    if amount0 > 0:
        ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
    if amount1 > 0:
        ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)

@external
def _divestUniV3NFLPToToken(_tokenId: uint256, _token: address, _removeParams: RemoveParams, minTokenAmount: uint256):
    assert msg.sender == self
    deadline: uint256 = MAX_UINT256
    assert not self.paused

    token: address = _token
    if token == VETH or token == ZERO_ADDRESS:
        token = WETH

    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    amount0: uint256 = 0
    amount1: uint256 = 0
    (token0, token1, amount0, amount1) = self.removeLiquidity(_tokenId, _removeParams, self)

    amount: uint256 = 0
    if token0 == token:
        amount = self.token2Token(token1, token0, amount1, MAX_UINT256) + amount0
    elif token1 == token:
        amount = self.token2Token(token0, token1, amount0, MAX_UINT256) + amount1
    else:
        midToken: address = self.getMidToken(WETH, token0, token1)
        if midToken == token0:
            amount = self.token2Token(token1, token0, amount1, MAX_UINT256)
            amount = self.token2Token(token0, WETH, amount + amount0, MAX_UINT256)
            amount = self.token2Token(WETH, token, amount, MAX_UINT256)
        else:
            amount = self.token2Token(token0, token1, amount0, MAX_UINT256)
            amount = self.token2Token(token1, WETH, amount + amount1, MAX_UINT256)
            amount = self.token2Token(WETH, token, amount, MAX_UINT256)

    assert amount >= minTokenAmount

    if token != _token:
        WrappedEth(WETH).withdraw(amount)
        send(_removeParams.recipient, amount)
    else:
        ERC20(token).transfer(_removeParams.recipient, amount)

@external
@payable
@nonreentrant('lock')
def batchRun(data: Bytes[3616]):
    fee: uint256 = self.feeAmount
    assert msg.value >= fee
    send(self.feeAddress, fee)
    cursor: uint256 = 0
    usedValue: uint256 = fee
    for i in range(8):
        if len(data) < cursor + 4:
            break
        mid: Bytes[4] = slice(data, cursor, 4)
        cursor += 4
        if mid == ADDLIQ_MID:
            raw_call(self,
                concat(
                    _ADDLIQ_MID,
                    slice(data, cursor, 384),
                    convert(msg.sender, bytes32)
                )
            )
            cursor += 384
        elif mid == ADDLIQETH_MID:
            if convert(convert(slice(data, cursor + 32, 32), uint256), address) == WETH:
                raw_call(self,
                    concat(
                        _ADDLIQETH_MID,
                        slice(data, cursor, 384),
                        convert(msg.sender, bytes32),
                        slice(data, cursor + 192, 32)
                    )
                )
                usedValue += convert(slice(data, cursor + 192, 32), uint256)
            else:
                assert convert(convert(slice(data, cursor + 64, 32), uint256), address) == WETH
                raw_call(self,
                    concat(
                        _ADDLIQETH_MID,
                        slice(data, cursor, 384),
                        convert(msg.sender, bytes32),
                        slice(data, cursor + 224, 32)
                    )
                )
                usedValue += convert(slice(data, cursor + 224, 32), uint256)
            cursor += 384
        elif mid == REMOVELIQ_MID:
            raw_call(self,
                concat(
                    _REMOVELIQ_MID,
                    slice(data, cursor, 128)
                )
            )
            cursor += 128
        elif mid == REMOVELIQETH_MID:
            raw_call(self,
                concat(
                    _REMOVELIQETH_MID,
                    slice(data, cursor, 128)
                )
            )
            cursor += 128
        elif mid == INVEST_MID:
            token: address = convert(convert(slice(data, cursor + 32, 32), uint256), address)
            if token == VETH or token == ZERO_ADDRESS:
                raw_call(self,
                    concat(
                        _INVEST_MID,
                        slice(data, cursor, 416),
                        convert(msg.sender, bytes32),
                        slice(data, cursor + 64, 32)
                    )
                )
                usedValue += convert(slice(data, cursor + 64, 32), uint256)
            else:
                raw_call(self,
                    concat(
                        _INVEST_MID,
                        slice(data, cursor, 416),
                        convert(msg.sender, bytes32),
                        convert(0, bytes32)
                    )
                )
            cursor += 416
        elif mid == DIVEST_MID:
            raw_call(self,
                concat(
                    _DIVEST_MID,
                    slice(data, cursor, 192)
                )
            )
            cursor += 192
        else:
            assert convert(mid, uint256) == 0
            break

    if msg.value - usedValue > 0:
        send(msg.sender, msg.value - usedValue)

# Admin functions
@external
def pause(_paused: bool):
    assert msg.sender == self.admin
    self.paused = _paused
    log Paused(_paused)

@external
def newAdmin(_admin: address):
    assert msg.sender == self.admin
    self.admin = _admin

@external
def newFeeAmount(_feeAmount: uint256):
    assert msg.sender == self.admin
    self.feeAmount = _feeAmount
    log FeeChanged(_feeAmount)

@external
def newFeeAddress(_feeAddress: address):
    assert msg.sender == self.admin
    self.feeAddress = _feeAddress

@external
@nonreentrant('lock')
def batchWithdraw(token: address[8], amount: uint256[8], to: address[8]):
    assert msg.sender == self.admin
    for i in range(8):
        if token[i] == VETH:
            send(to[i], amount[i])
        elif token[i] != ZERO_ADDRESS:
            ERC20(token[i]).transfer(to[i], amount[i])

@external
@nonreentrant('lock')
def withdraw(token: address, amount: uint256, to: address):
    assert msg.sender == self.admin
    if token == VETH:
        send(to, amount)
    elif token != ZERO_ADDRESS:
        ERC20(token).transfer(to, amount)

@external
@payable
def __default__():
    assert msg.sender == WETH