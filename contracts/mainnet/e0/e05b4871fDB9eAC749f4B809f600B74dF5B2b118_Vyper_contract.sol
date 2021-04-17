# Copyright (C) 2021 VolumeFi Software, Inc.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License. 
#  This program is distributed WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  @author VolumeFi, Software inc.
#  @notice This Vyper contract Adds liquidity to any Balancer pool from ETH or any ERC20 Token.
#  SPDX-License-Identifier: Apache-2.0

# @version ^0.2.0

interface ERC20:
    def allowance(owner: address, spender: address) -> uint256: view

interface BFactory:
    def isBPool(b: address) -> bool: view

interface BPool:
    def joinswapExternAmountIn(tokenIn: address, tokenAmountIn: uint256, minPoolAmountOut: uint256) -> uint256: payable
    def isBound(t: address) -> bool: view
    def getNumTokens() -> uint256: view

interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB: address) -> address: view

interface WrappedEth:
    def deposit(): payable

event LPTokenMint:
    lptoken: address
    recipient: address
    liquidity: uint256

event Paused:
    paused: bool

event FeeChanged:
    newFee: uint256

UNISWAPV2ROUTER02: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
UNISWAPV2FACTORY: constant(address) = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
BALANCERFACTORY: constant(address) = 0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEADLINE: constant(uint256) = MAX_UINT256 # change

TRANSFERFROM_MID: constant(Bytes[4]) = method_id("transferFrom(address,address,uint256)")
TRANSFER_MID: constant(Bytes[4]) = method_id("transfer(address,uint256)")
APPROVE_MID: constant(Bytes[4]) = method_id("approve(address,uint256)")
SWAPETFT_MID: constant(Bytes[4]) = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")
GETCURRENTTOKENS_MID: constant(Bytes[4]) = method_id("getCurrentTokens()")

paused: public(bool)
admin: public(address)
feeAmount: public(uint256)
feeAddress: public(address)

@external
def __init__():
    self.paused = False
    self.admin = msg.sender
    self.feeAddress = 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.feeAmount = 5 * 10 ** 15

@internal
def _enter2Balancer(_toBalancerPoolAddress: address, _fromTokenContractAddress: address, tokens2Trade: uint256) -> uint256:
    assert BPool(_toBalancerPoolAddress).isBound(_fromTokenContractAddress), "Token not bound"
    _response32: Bytes[32] = empty(Bytes[32])
    if ERC20(_fromTokenContractAddress).allowance(self, _toBalancerPoolAddress) > 0:
        _response32 = raw_call(
            _fromTokenContractAddress,
            concat(
                APPROVE_MID,
                convert(_toBalancerPoolAddress, bytes32),
                convert(0, bytes32)
            ),
            max_outsize=32
        )  # dev: failed approve
        if len(_response32) > 0:
            assert convert(_response32, bool), "Approve failed"  # dev: failed approve
    _response32 = raw_call(
        _fromTokenContractAddress,
        concat(
            APPROVE_MID,
            convert(_toBalancerPoolAddress, bytes32),
            convert(tokens2Trade, bytes32)
        ),
        max_outsize=32
    )  # dev: failed approve
    if len(_response32) > 0:
        assert convert(_response32, bool), "Approve failed"  # dev: failed approve
    poolTokensOut: uint256 = BPool(_toBalancerPoolAddress).joinswapExternAmountIn(_fromTokenContractAddress, tokens2Trade, 1)
    assert poolTokensOut > 0, "Error in entering balancer pool"
    return poolTokensOut

interface UniswapV2Pair:
    def token0() -> address: view
    def token1() -> address: view
    def getReserves() -> (uint256, uint256, uint256): view

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
def _getMidTokenNumber(midToken: address, tokens: address[8]) -> uint256:
    maxeth: uint256 = 0
    maxi: uint256 = 0
    for i in range(8):
        if tokens[i] == ZERO_ADDRESS:
            break
        if midToken == tokens[i]:
            return i
        pair: address = UniswapV2Factory(UNISWAPV2FACTORY).getPair(midToken, tokens[i])
        eth: uint256 = 0
        if pair != ZERO_ADDRESS:
            eth = self._getLiquidityInPool(midToken, pair)
        if eth > maxeth:
            maxeth = eth
            maxi = i
    return maxi

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    _response32: Bytes[32] = empty(Bytes[32])
    if ERC20(fromToken).allowance(self, UNISWAPV2ROUTER02) > 0:
        _response32 = raw_call(
            fromToken,
            concat(
                APPROVE_MID,
                convert(UNISWAPV2ROUTER02, bytes32),
                convert(0, bytes32)
            ),
            max_outsize=32
        )  # dev: failed approve
        if len(_response32) > 0:
            assert convert(_response32, bool), "Approve failed"  # dev: failed approve
    _response32 = raw_call(
        fromToken,
        concat(
            APPROVE_MID,
            convert(UNISWAPV2ROUTER02, bytes32),
            convert(tokens2Trade, bytes32)
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
def _enter2BalancerViaUniswap(_toBalancerPoolAddress: address, _fromTokenContractAddress: address, _tokens2Trade: uint256) -> uint256:
    tokens2Trade: uint256 = self._token2Token(_fromTokenContractAddress, WETH, _tokens2Trade, DEADLINE)
    numTokens: uint256 = BPool(_toBalancerPoolAddress).getNumTokens()
    
    funcsig: Bytes[4] = GETCURRENTTOKENS_MID
    
    _response320: Bytes[320] = raw_call(
        _toBalancerPoolAddress,
        funcsig,
        is_static_call=True,
        max_outsize=320
    )
    tokens: address[8] = [ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS]
    for i in range(8):
        tokens[i] = convert(convert(slice(_response320, 32 * (convert(i, uint256) + 2), 32), uint256), address)
        if convert(i, uint256) == (numTokens - 1):
            break
    midTokenNumber: uint256 = self._getMidTokenNumber(WETH, tokens)
    tokens2Trade = self._token2Token(WETH, tokens[midTokenNumber], tokens2Trade, DEADLINE)
    tokens2Trade = self._enter2Balancer(_toBalancerPoolAddress, tokens[midTokenNumber], tokens2Trade)
    return tokens2Trade

@external
@payable
@nonreentrant('lock')
def investTokenForBalancerPoolToken(_token: address, _pair: address, amount: uint256, minPoolTokens: uint256, deadline: uint256=DEADLINE) -> uint256:
    assert amount > 0, "Invalid input amount"
    assert block.timestamp <= deadline, "Expired"
    assert not self.paused, "Paused"
    assert BFactory(BALANCERFACTORY).isBPool(_pair), "!Balancer Pool"
    fee: uint256 = self.feeAmount
    assert msg.value >= fee, "Insufficient fee"
    send(self.feeAddress, fee)
    msg_value: uint256 = msg.value
    msg_value -= fee
    token: address = _token
    _response32: Bytes[32] = empty(Bytes[32])
    if token == VETH or token == ZERO_ADDRESS:
        if msg_value > amount:
            send(msg.sender, msg_value - amount)
        else:
            assert msg_value >= amount, "Insufficient value"
        WrappedEth(WETH).deposit(value=amount)
        token = WETH
    else:
        _response32 = raw_call(
            token,
            concat(
                TRANSFERFROM_MID,
                convert(msg.sender, bytes32),
                convert(self, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32
        )  # dev: failed transfer
        if len(_response32) > 0:
            assert convert(_response32, bool), "TransferFrom failed"  # dev: failed transfer
    isBound: bool = BPool(_pair).isBound(token)
    balancerTokens: uint256 = 0
    if (isBound):
        balancerTokens = self._enter2Balancer(_pair, token, amount)
    else:
        balancerTokens = self._enter2BalancerViaUniswap(_pair, token, amount)
    _response32 = raw_call(
        _pair,
        concat(
            TRANSFER_MID,
            convert(msg.sender, bytes32),
            convert(balancerTokens, bytes32),
        ),
        max_outsize=32
    )  # dev: failed transfer
    if len(_response32) > 0:
        assert convert(_response32, bool), "Transfer failed"  # dev: failed transfer

    assert balancerTokens >= minPoolTokens, "High Slippage"

    log LPTokenMint(_pair, msg.sender, balancerTokens)

    return balancerTokens

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
            _response32: Bytes[32] = raw_call(
                token[i],
                concat(
                    TRANSFER_MID,
                    convert(to[i], bytes32),
                    convert(amount[i], bytes32),
                ),
                max_outsize=32
            )  # dev: failed transfer
            if len(_response32) > 0:
                assert convert(_response32, bool), "Transfer failed"  # dev: failed transfer

@external
@nonreentrant('lock')
def withdraw(token: address, amount: uint256, to: address):
    assert msg.sender == self.admin, "Not admin"
    if token == VETH:
        send(to, amount)
    elif token != ZERO_ADDRESS:
        _response32: Bytes[32] = raw_call(
            token,
            concat(
                TRANSFER_MID,
                convert(to, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32
        )  # dev: failed transfer
        if len(_response32) > 0:
            assert convert(_response32, bool), "Transfer failed"  # dev: failed transfer

@external
@payable
def __default__():
    assert msg.sender == WETH, "can't receive Eth"