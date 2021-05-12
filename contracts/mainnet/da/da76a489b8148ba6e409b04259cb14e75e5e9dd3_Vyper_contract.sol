# Copyright (C) 2021 VolumeFi Software, Inc.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License. 
#  This program is distributed WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  @author VolumeFi, Software Inc.
#  @notice This Vyper contract adds liquidity to any Uniswap V2 pool using ETH or any ERC20 Token.
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
    liquidityMin: uint256
    recipient: address
    deadline: uint256

struct ModifyParams:
    fee: uint256
    tickLower: int128
    tickUpper: int128
    recipient: address
    deadline: uint256

interface ERC20:
    def allowance(_owner: address, _spender: address) -> uint256: view

interface ERC721:
    def transferFrom(_from: address, _to: address, _tokenId: uint256): payable

interface NonfungiblePositionManager:
    def burn(tokenId: uint256): payable

interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB: address) -> address: view

interface UniswapV2Pair:
    def token0() -> address: view
    def token1() -> address: view
    def getReserves() -> (uint256, uint256, uint256): view
    def mint(to: address) -> uint256: nonpayable

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

event AddedLiquidity:
    tokenId: indexed(uint256)
    token0: indexed(address)
    token1: indexed(address)
    liquidity: uint256
    amount0: uint256
    amount1: uint256

event NFLPModified:
    oldTokenId: indexed(uint256)
    newTokenId: indexed(uint256)

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

APPROVE_MID: constant(Bytes[4]) = method_id("approve(address,uint256)")
TRANSFER_MID: constant(Bytes[4]) = method_id("transfer(address,uint256)")
TRANSFERFROM_MID: constant(Bytes[4]) = method_id("transferFrom(address,address,uint256)")
CAIPIN_MID: constant(Bytes[4]) = method_id("createAndInitializePoolIfNecessary(address,address,uint24,uint160)")
GETPOOL_MID: constant(Bytes[4]) = method_id("getPool(address,address,uint24)")
SLOT0_MID: constant(Bytes[4]) = method_id("slot0()")
MINT_MID: constant(Bytes[4]) = method_id("mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256))")
POSITIONS_MID: constant(Bytes[4]) = method_id("positions(uint256)")
INCREASELIQUIDITY_MID: constant(Bytes[4]) = method_id("increaseLiquidity((uint256,uint256,uint256,uint256,uint256,uint256))")
DECREASELIQUIDITY_MID: constant(Bytes[4]) = method_id("decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))")
COLLECT_MID: constant(Bytes[4]) = method_id("collect((uint256,address,uint128,uint128))")
SWAPETFT_MID: constant(Bytes[4]) = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")

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
def safeApprove(_token: address, _spender: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            APPROVE_MID,
            convert(_spender, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool), "Approve failed"  # dev: failed approve

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
def safeTransferFrom(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFERFROM_MID,
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transferFrom
    if len(_response) > 0:
        assert convert(_response, bool), "TransferFrom failed"  # dev: failed transferFrom

@internal
def addLiquidity(_tokenId: uint256, sender: address, uniV3Params: MintParams, _sqrtPriceX96: uint256 = 0) -> (uint256, uint256, uint256):
    self.safeApprove(uniV3Params.token0, NONFUNGIBLEPOSITIONMANAGER, uniV3Params.amount0Desired)
    self.safeApprove(uniV3Params.token1, NONFUNGIBLEPOSITIONMANAGER, uniV3Params.amount1Desired)
    if _tokenId == 0:
        sqrtPriceX96: uint256 = _sqrtPriceX96
        _response32: Bytes[32] = empty(Bytes[32])
        if sqrtPriceX96 == 0:
            _response32 = raw_call(
                UNISWAPV3FACTORY,
                concat(
                    GETPOOL_MID,
                    convert(uniV3Params.token0, bytes32),
                    convert(uniV3Params.token1, bytes32),
                    convert(uniV3Params.fee, bytes32)
                ),
                max_outsize=32,
                is_static_call=True
            )
            pool: address = convert(convert(_response32, bytes32), address)
            assert pool != ZERO_ADDRESS, "Pool does not exist"
            _response224: Bytes[224] = raw_call(
                pool,
                SLOT0_MID,
                max_outsize=224,
                is_static_call=True
            )
            sqrtPriceX96 = convert(slice(_response224, 0, 32), uint256)
            assert sqrtPriceX96 != 0, "Pool does not initialized"

        _response32 = raw_call(
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
        assert convert(convert(_response32, bytes32), address) != ZERO_ADDRESS, "Create Or Init Pool failed"
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

@external
@payable
@nonreentrant('lock')
def addLiquidityEthForUniV3(_tokenId: uint256, uniV3Params: MintParams):
    assert not self.paused, "Paused"
    assert convert(uniV3Params.token0, uint256) < convert(uniV3Params.token1, uint256), "Unsorted tokens"
    if uniV3Params.token0 == WETH:
        if msg.value > uniV3Params.amount0Desired:
            send(msg.sender, msg.value - uniV3Params.amount0Desired)
        else:
            assert msg.value == uniV3Params.amount0Desired, "Eth not enough"
        WrappedEth(WETH).deposit(value=uniV3Params.amount0Desired)
        self.safeTransferFrom(uniV3Params.token1, msg.sender, self, uniV3Params.amount1Desired)
        amount0: uint256 = 0
        amount1: uint256 = 0
        liquidity: uint256 = 0
        (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg.sender, uniV3Params)
        amount0 = uniV3Params.amount0Desired - amount0
        amount1 = uniV3Params.amount1Desired - amount1
        if amount0 > 0:
            WrappedEth(WETH).withdraw(amount0)
            send(msg.sender, amount0)
            self.safeApprove(uniV3Params.token0, NONFUNGIBLEPOSITIONMANAGER, 0)
        if amount1 > 0:
            self.safeTransfer(uniV3Params.token1, msg.sender, amount1)
            self.safeApprove(uniV3Params.token1, NONFUNGIBLEPOSITIONMANAGER, 0)
    else:
        assert uniV3Params.token1 == WETH, "Not Eth Pair"
        if msg.value > uniV3Params.amount1Desired:
            send(msg.sender, msg.value - uniV3Params.amount1Desired)
        else:
            assert msg.value == uniV3Params.amount1Desired, "Eth not enough"
        WrappedEth(WETH).deposit(value=uniV3Params.amount1Desired)
        self.safeTransferFrom(uniV3Params.token0, msg.sender, self, uniV3Params.amount0Desired)
        amount0: uint256 = 0
        amount1: uint256 = 0
        liquidity: uint256 = 0
        (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg.sender, uniV3Params)
        amount0 = uniV3Params.amount0Desired - amount0
        amount1 = uniV3Params.amount1Desired - amount1
        if amount0 > 0:
            self.safeTransfer(uniV3Params.token0, msg.sender, amount0)
            self.safeApprove(uniV3Params.token0, NONFUNGIBLEPOSITIONMANAGER, 0)
        if amount1 > 0:
            WrappedEth(WETH).withdraw(amount1)
            send(msg.sender, amount1)
            self.safeApprove(uniV3Params.token1, NONFUNGIBLEPOSITIONMANAGER, 0)

@external
@nonreentrant('lock')
def addLiquidityForUniV3(_tokenId: uint256, uniV3Params: MintParams):
    assert not self.paused, "Paused"
    assert convert(uniV3Params.token0, uint256) < convert(uniV3Params.token1, uint256), "Unsorted tokens"

    self.safeTransferFrom(uniV3Params.token0, msg.sender, self, uniV3Params.amount0Desired)
    self.safeTransferFrom(uniV3Params.token1, msg.sender, self, uniV3Params.amount1Desired)

    amount0: uint256 = 0
    amount1: uint256 = 0
    liquidity: uint256 = 0
    (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg.sender, uniV3Params)
    amount0 = uniV3Params.amount0Desired - amount0
    amount1 = uniV3Params.amount1Desired - amount1
    if amount0 > 0:
        self.safeTransfer(uniV3Params.token0, msg.sender, amount0)
        self.safeApprove(uniV3Params.token0, NONFUNGIBLEPOSITIONMANAGER, 0)
    if amount1 > 0:
        self.safeTransfer(uniV3Params.token1, msg.sender, amount1)
        self.safeApprove(uniV3Params.token1, NONFUNGIBLEPOSITIONMANAGER, 0)

@external
@payable
@nonreentrant('lock')
def modifyPositionForUniV3NFLP(_tokenId: uint256, modifyParams: ModifyParams):
    assert _tokenId != 0, "Wrong Token ID"
    fee: uint256 = self.feeAmount
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    else:
        assert msg.value == fee, "Insufficient fee"
    send(self.feeAddress, fee)
    ERC721(NONFUNGIBLEPOSITIONMANAGER).transferFrom(msg.sender, self, _tokenId)
    
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
    
    _response64: Bytes[64] = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            DECREASELIQUIDITY_MID,
            convert(_tokenId, bytes32),
            convert(liquidity, bytes32),
            convert(0, bytes32),
            convert(0, bytes32),
            convert(modifyParams.deadline, bytes32)
        ),
        max_outsize=64
    )

    _response64 = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            COLLECT_MID,
            convert(_tokenId, bytes32),
            convert(self, bytes32),
            convert(2 ** 128 - 1, bytes32),
            convert(2 ** 128 - 1, bytes32)
        ),
        max_outsize=64
    )
    amount0: uint256 = convert(slice(_response64, 0, 32), uint256)
    amount1: uint256 = convert(slice(_response64, 32, 32), uint256)
    
    NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).burn(_tokenId)

    sqrtPriceX96: uint256 = 0
    _response32: Bytes[32] = raw_call(
        UNISWAPV3FACTORY,
        concat(
            GETPOOL_MID,
            convert(token0, bytes32),
            convert(token1, bytes32),
            convert(modifyParams.fee, bytes32)
        ),
        max_outsize=32,
        is_static_call=True
    )
    pool: address = convert(convert(_response32, bytes32), address)
    if pool == ZERO_ADDRESS:
        sqrtPriceX96 = 2 ** 96 * self.uintSqrt(amount0) / self.uintSqrt(amount1)
    else:
        _response224: Bytes[224] = raw_call(
            pool,
            SLOT0_MID,
            max_outsize=224,
            is_static_call=True
        )
        sqrtPriceX96 = convert(slice(_response224, 0, 32), uint256)
        if sqrtPriceX96 == 0:
            sqrtPriceX96 = 2 ** 96 * self.uintSqrt(amount1) / self.uintSqrt(amount1)

    _response32 = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            CAIPIN_MID,
            convert(token0, bytes32),
            convert(token1, bytes32),
            convert(modifyParams.fee, bytes32),
            convert(sqrtPriceX96, bytes32)
        ),
        max_outsize=32
    )

    assert convert(convert(_response32, bytes32), address) != ZERO_ADDRESS, "Create Or Init Pool failed"

    self.safeApprove(token0, NONFUNGIBLEPOSITIONMANAGER, amount0)
    self.safeApprove(token1, NONFUNGIBLEPOSITIONMANAGER, amount1)

    _response128: Bytes[128] = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        concat(
            MINT_MID,
            convert(token0, bytes32),
            convert(token1, bytes32),
            convert(modifyParams.fee, bytes32),
            convert(modifyParams.tickLower, bytes32),
            convert(modifyParams.tickUpper, bytes32),
            convert(amount0, bytes32),
            convert(amount1, bytes32),
            convert(0, bytes32),
            convert(0, bytes32),
            convert(msg.sender, bytes32),
            convert(modifyParams.deadline, bytes32)
        ),
        max_outsize=128
    )
    tokenId: uint256 = convert(slice(_response128, 0, 32), uint256)
    liquiditynew: uint256 = convert(slice(_response128, 32, 32), uint256)
    amount0new: uint256 = convert(slice(_response128, 64, 32), uint256)
    amount1new: uint256 = convert(slice(_response128, 96, 32), uint256)

    if amount0 > amount0new:
        self.safeTransfer(token0, msg.sender, amount0 - amount0new)
        self.safeApprove(token0, NONFUNGIBLEPOSITIONMANAGER, 0)
    if amount1 > amount1new:
        self.safeTransfer(token1, msg.sender, amount1 - amount1new)
        self.safeApprove(token1, NONFUNGIBLEPOSITIONMANAGER, 0)
    log NFLPModified(_tokenId, tokenId)

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    self.safeApprove(fromToken, UNISWAPV2ROUTER02, tokens2Trade)
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
    self.safeApprove(fromToken, UNISWAPV2ROUTER02, 0)
    assert tokenBought > 0, "Error Swapping Token"
    return tokenBought

# (X + fX') * (Y - Y') = X * Y
# Y' / (X_toinvest - X') = p^2 = P
# Quadratic equation solution for X'
@internal
@view
def _getUserInForSqrtPriceX96(reserveIn: uint256, reserveOut: uint256, sqrtPriceX96: uint256, toInvest: uint256) -> uint256:
    b: uint256 = reserveIn + (reserveOut * 997 / 1000 * 2 ** 96 / sqrtPriceX96 * 2 ** 96 / sqrtPriceX96) - toInvest * 997 / 1000
    return (self.uintSqrt(b * b + 4 * reserveIn * toInvest * 997 / 1000) - b) * 1000 / 1994

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
    pair0: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, token0)
    pair1: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, token1)
    eth0: uint256 = self._getLiquidityInPool(midToken, pair0)
    eth1: uint256 = self._getLiquidityInPool(midToken, pair1)
    if eth0 > eth1:
        return token0
    else:
        return token1

@external
@payable
@nonreentrant('lock')
def investTokenForUniPair(_token: address, amount: uint256, _tokenId: uint256, _uniV3Params: SingleMintParams):
    assert not self.paused, "Paused"
    assert amount > 0, "Invalid input amount"
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
    assert convert(uniV3Params.token0, uint256) < convert(uniV3Params.token1, uint256), "Unsorted tokens"
    fee: uint256 = self.feeAmount
    assert msg.value >= fee, "Insufficient fee"
    send(self.feeAddress, fee)
    msg_value: uint256 = msg.value
    msg_value -= fee
    token: address = _token
    _response32: Bytes[32] = empty(Bytes[32])
    toInvest: uint256 = 0
    midToken: address = WETH
    if token == VETH or token == ZERO_ADDRESS:
        if msg_value > amount:
            send(msg.sender, msg_value - amount)
        else:
            assert msg_value >= amount, "Insufficient value"
        WrappedEth(WETH).deposit(value=amount)
        token = WETH
        toInvest = amount
    #invest Token
    else:
        self.safeTransferFrom(token, msg.sender, self, amount)
        if msg_value > 0:
            send(msg.sender, msg_value)
        if token == WETH:
            toInvest = amount
        elif token != uniV3Params.token0 and token != uniV3Params.token1:
            toInvest = self._token2Token(token, WETH, amount, uniV3Params.deadline)
        else:
            midToken = token
            toInvest = amount
    if uniV3Params.token0 != WETH and uniV3Params.token1 != WETH and token != uniV3Params.token0 and token != uniV3Params.token1:
        midToken = self._getMidToken(WETH, uniV3Params.token0, uniV3Params.token1)
        toInvest = self._token2Token(WETH, midToken, toInvest, uniV3Params.deadline)

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
    _response32 = raw_call(
        UNISWAPV3FACTORY,
        concat(
            GETPOOL_MID,
            convert(uniV3Params.token0, bytes32),
            convert(uniV3Params.token1, bytes32),
            convert(uniV3Params.fee, bytes32)
        ),
        max_outsize=32,
        is_static_call=True
    )
    pool: address = convert(convert(_response32, bytes32), address)
    assert pool != ZERO_ADDRESS, "Pool does not exist"
    _response224: Bytes[224] = raw_call(
        pool,
        SLOT0_MID,
        max_outsize=224,
        is_static_call=True
    )
    sqrtPriceX96 = convert(slice(_response224, 0, 32), uint256)
    assert sqrtPriceX96 != 0, "Pool does not initialized"
    swapAmount: uint256 = 0
    if convert(midToken, uint256) > convert(endToken, uint256):
        swapAmount = self._getUserInForSqrtPriceX96(res0, res1, 2 ** 192 / sqrtPriceX96, toInvest)
    else:
        swapAmount = self._getUserInForSqrtPriceX96(res0, res1, sqrtPriceX96, toInvest)
    retAmount: uint256 = self._token2Token(midToken, endToken, swapAmount, uniV3Params.deadline)

    if uniV3Params.token0 == midToken:
        uniV3Params.amount0Desired = toInvest - swapAmount
        uniV3Params.amount1Desired = retAmount
    else:
        uniV3Params.amount1Desired = toInvest - swapAmount
        uniV3Params.amount0Desired = retAmount

    amount0: uint256 = 0
    amount1: uint256 = 0
    liquidity: uint256 = 0
    (amount0, amount1, liquidity) = self.addLiquidity(_tokenId, msg.sender, uniV3Params, sqrtPriceX96)
    assert liquidity >= _uniV3Params.liquidityMin, "High Slippage"
    amount0 = uniV3Params.amount0Desired - amount0
    amount1 = uniV3Params.amount1Desired - amount1
    if amount0 > 0:
        self.safeTransfer(uniV3Params.token0, msg.sender, amount0)
        self.safeApprove(uniV3Params.token0, NONFUNGIBLEPOSITIONMANAGER, 0)
    if amount1 > 0:
        self.safeTransfer(uniV3Params.token1, msg.sender, amount1)
        self.safeApprove(uniV3Params.token1, NONFUNGIBLEPOSITIONMANAGER, 0)

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