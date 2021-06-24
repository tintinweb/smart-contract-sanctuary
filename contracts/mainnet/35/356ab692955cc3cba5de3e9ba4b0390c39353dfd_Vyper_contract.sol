# Copyright (C) 2021 VolumeFi Software, Inc.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License. 
#  This program is distributed WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  @author VolumeFi, Software Inc.
#  @notice This Vyper contract REMOVES liquidity to any Uniswap V3 pool using ETH or any ERC20 Token.
#  SPDX-License-Identifier: Apache-2.0

# @version >=0.2.12

struct RemoveParams:
    liquidity: uint256
    recipient: address
    deadline: uint256

interface ERC20:
    def allowance(owner: address, spender: address) -> uint256: view

interface NonfungiblePositionManager:
    def burn(tokenId: uint256): payable

interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB: address) -> address: view

interface UniswapV2Pair:
    def token0() -> address: view
    def token1() -> address: view
    def getReserves() -> (uint256, uint256, uint256): view

interface WrappedEth:
    def withdraw(amount: uint256): nonpayable

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
UNISWAPV2ROUTER02: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
UNISWAPV2FACTORY: constant(address) = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEADLINE: constant(uint256) = MAX_UINT256

APPROVE_MID: constant(Bytes[4]) = method_id("approve(address,uint256)")
SWAPETFT_MID: constant(Bytes[4]) = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")
TRANSFER_MID: constant(Bytes[4]) = method_id("transfer(address,uint256)")
POSITIONS_MID: constant(Bytes[4]) = method_id("positions(uint256)")
DECREASELIQUIDITY_MID: constant(Bytes[4]) = method_id("decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))")
COLLECT_MID: constant(Bytes[4]) = method_id("collect((uint256,address,uint128,uint128))")


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
def safeTransfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFER_MID,
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transfer
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed"  # dev: failed transfer

@internal
@pure
def _getPairTokens(pair: address) -> (address, address):
    token0: address = UniswapV2Pair(pair).token0()
    token1: address = UniswapV2Pair(pair).token1()
    return (token0, token1)

@internal
@view
def _getLiquidityInPool(midToken: address, pair: address) -> uint256:
    res0: uint256 = 0
    res1: uint256 = 0
    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    blockTimestampLast: uint256 = 0
    (res0, res1, blockTimestampLast) = UniswapV2Pair(pair).getReserves()
    (token0, token1) = self._getPairTokens(pair)
    if token0 == midToken:
        return res0
    else:
        return res1

@internal
@view
def _getMidToken(midToken: address, token0: address, token1: address) -> address:
    if token0 == midToken or token1 == midToken:
        return midToken
    pair0: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, token0)
    pair1: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, token1)
    eth0: uint256 = self._getLiquidityInPool(midToken, pair0)
    eth1: uint256 = self._getLiquidityInPool(midToken, pair1)
    if eth0 > eth1:
        return token0
    else:
        return token1

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    _response32: Bytes[32] = empty(Bytes[32])
    if ERC20(fromToken).allowance(self, UNISWAPV2ROUTER02) == 0:
        _response32 = raw_call(
            fromToken,
            concat(
                APPROVE_MID,
                convert(UNISWAPV2ROUTER02, bytes32),
                convert(MAX_UINT256, bytes32)
            ),
            max_outsize=32
        )  # dev: failed approve
        if len(_response32) > 0:
            assert convert(_response32, bool), "Approve failed"  # dev: failed approve
    
    addrBytes: Bytes[288] = concat(convert(tokens2Trade, bytes32), convert(0, bytes32), convert(160, bytes32), convert(self, bytes32), convert(deadline, bytes32), convert(2, bytes32), convert(fromToken, bytes32), convert(toToken, bytes32))
    funcsig: Bytes[4] = SWAPETFT_MID
    full_data: Bytes[292] = concat(funcsig, addrBytes)
    
    _response128: Bytes[128] = raw_call(
        UNISWAPV2ROUTER02,
        full_data,
        max_outsize=128
    )
    tokenBought: uint256 = convert(slice(_response128, 96, 32), uint256)
    assert tokenBought > 0, "Error Swapping Token 2"
    return tokenBought

@internal
def removeLiquidity(_tokenId: uint256, _removeParams: RemoveParams, _isBurn: bool=True, _recipient: address=ZERO_ADDRESS) -> (address, address, uint256, uint256):
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
    isBurn: bool = _isBurn
    if isBurn and liquidity > _removeParams.liquidity:
        liquidity = _removeParams.liquidity
        isBurn = False

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
@payable
@nonreentrant('lock')
def removeLiquidityFromUniV3NFLP(_tokenId: uint256, _removeParams: RemoveParams, isBurn: bool=True):
    assert _tokenId != 0, "Wrong Token ID"

    fee: uint256 = self.feeAmount
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    else:
        assert msg.value == fee, "Insufficient fee"
    if fee > 0:
        send(self.feeAddress, fee)

    self.removeLiquidity(_tokenId, _removeParams, isBurn)

@external
@payable
@nonreentrant('lock')
def removeLiquidityEthFromUniV3NFLP(_tokenId: uint256, _removeParams: RemoveParams, isBurn: bool=True):
    assert _tokenId != 0, "Wrong Token ID"

    fee: uint256 = self.feeAmount
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    else:
        assert msg.value == fee, "Insufficient fee"
    if fee > 0:
        send(self.feeAddress, fee)

    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    amount0: uint256 = 0
    amount1: uint256 = 0
    (token0, token1, amount0, amount1) = self.removeLiquidity(_tokenId, _removeParams, isBurn, self)
    if token0 == WETH and token1 != WETH:
        WrappedEth(token0).withdraw(amount0)
        send(_removeParams.recipient, amount0)
        self.safeTransfer(token1, _removeParams.recipient, amount1)
    elif token1 == WETH and token0 != WETH:
        WrappedEth(token1).withdraw(amount1)
        send(_removeParams.recipient, amount1)
        self.safeTransfer(token0, _removeParams.recipient, amount0)
    else:
        raise "Not Eth Pair"

@external
@payable
@nonreentrant('lock')
def divestUniV3NFLPToToken(_tokenId: uint256, _token: address, _removeParams: RemoveParams, minTokenAmount: uint256, isBurn: bool=True, deadline: uint256=MAX_UINT256) -> uint256:
    assert not self.paused, "Paused"
    fee: uint256 = self.feeAmount
    msg_value: uint256 = msg.value

    assert msg.value >= fee, "Insufficient fee"
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    send(self.feeAddress, fee)

    token: address = _token
    if token == VETH or token == ZERO_ADDRESS:
        token = WETH

    token0: address = ZERO_ADDRESS
    token1: address = ZERO_ADDRESS
    amount0: uint256 = 0
    amount1: uint256 = 0
    (token0, token1, amount0, amount1) = self.removeLiquidity(_tokenId, _removeParams, isBurn, self)

    amount: uint256 = 0
    if token0 == token:
        amount = self._token2Token(token1, token0, amount1, deadline)
    elif token1 == token:
        amount = self._token2Token(token0, token1, amount0, deadline)
    else:
        midToken: address = self._getMidToken(WETH, token0, token1)
        if midToken == token0:
            amount = self._token2Token(token1, token0, amount1, deadline)
            amount = self._token2Token(token0, WETH, amount + amount0, deadline)
            amount = self._token2Token(WETH, token, amount, deadline)
        else:
            amount = self._token2Token(token0, token1, amount0, deadline)
            amount = self._token2Token(token1, WETH, amount + amount1, deadline)
            amount = self._token2Token(WETH, token, amount, deadline)

    assert amount >= minTokenAmount, "High Slippage"

    if token != _token:
        WrappedEth(WETH).withdraw(amount)
        send(msg.sender, amount)
    else:
        self.safeTransfer(token, msg.sender, amount)
    return amount

# Admin functions
@external
def pause(_paused: bool):
    assert msg.sender == self.admin, "Not admin"
    self.paused = _paused
    log Paused(_paused)

@external
def newAdmin(_admin: address):
    assert msg.sender == self.admin, "Not admin"
    self.admin = _admin

@external
def newFeeAmount(_feeAmount: uint256):
    assert msg.sender == self.admin, "Not admin"
    self.feeAmount = _feeAmount
    log FeeChanged(_feeAmount)

@external
def newFeeAddress(_feeAddress: address):
    assert msg.sender == self.admin, "Not admin"
    self.feeAddress = _feeAddress

@external
@nonreentrant('lock')
def batchWithdraw(token: address[8], amount: uint256[8], to: address[8]):
    assert msg.sender == self.admin, "Not admin"
    for i in range(8):
        if token[i] == VETH:
            send(to[i], amount[i])
        elif token[i] != ZERO_ADDRESS:
            self.safeTransfer(token[i], to[i], amount[i])

@external
@nonreentrant('lock')
def withdraw(token: address, amount: uint256, to: address):
    assert msg.sender == self.admin, "Not admin"
    if token == VETH:
        send(to, amount)
    elif token != ZERO_ADDRESS:
        self.safeTransfer(token, to, amount)

@external
@payable
def __default__():
    assert msg.sender == WETH, "can't receive Eth"