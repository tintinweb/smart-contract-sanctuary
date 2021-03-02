# Copyright (C) 2021 VolumeFi Software, Inc.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License. 
#  This program is distributed WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  @author VolumeFi, Software inc.
#  @notice This Vyper contract adds liquidity to any Uniswap V2 pool using ETH or any ERC20 Token.
#  SPDX-License-Identifier: Apache-2.0

# @version ^0.2.0

interface ERC20:
    def approve(spender: address, amount: uint256): nonpayable
    def transfer(recipient: address, amount: uint256): nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256): nonpayable

interface UniswapV2Pair:
    def token0() -> address: view
    def token1() -> address: view

interface UniswapV2Router02:
    def removeLiquidity(tokenA: address, tokenB: address, liquidity: uint256, amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256): nonpayable

interface WrappedEth:
    def withdraw(wad: uint256): nonpayable

UNISWAPV2ROUTER02: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEADLINE: constant(uint256) = MAX_UINT256 # change

paused: public(bool)
admin: public(address)
feeAmount: public(uint256)
feeAddress: public(address)

@external
def __init__():
    self.paused = False
    self.admin = msg.sender
    self.feeAddress = 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.feeAmount = 1 * 10 ** 16

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, to: address, deadline: uint256) -> uint256:
    if fromToken == toToken:
        return tokens2Trade
    ERC20(fromToken).approve(UNISWAPV2ROUTER02, 0)
    ERC20(fromToken).approve(UNISWAPV2ROUTER02, tokens2Trade)
    
    addrBytes: Bytes[288] = concat(convert(tokens2Trade, bytes32), convert(0, bytes32), convert(160, bytes32), convert(to, bytes32), convert(deadline, bytes32), convert(2, bytes32), convert(fromToken, bytes32), convert(toToken, bytes32))
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

@external
@payable
@nonreentrant('lock')
def divestEthPairToToken(pair: address, token: address, amount: uint256, deadline: uint256=MAX_UINT256) -> uint256:
    assert not self.paused, "Paused"
    fee: uint256 = self.feeAmount
    msg_value: uint256 = msg.value

    assert msg.value >= fee, "Insufficient fee"
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    send(self.feeAddress, fee)

    assert pair != ZERO_ADDRESS, "Invalid Unipool Address"

    token0: address = UniswapV2Pair(pair).token0()
    token1: address = UniswapV2Pair(pair).token1()

    assert token0 == WETH or token1 == WETH, "Not ETH Pair"

    ERC20(pair).transferFrom(msg.sender, self, amount)
    ERC20(pair).approve(UNISWAPV2ROUTER02, amount)

    token0Amount: uint256 = 0
    token1Amount: uint256 = 0
    (token0Amount, token1Amount) = UniswapV2Router02(UNISWAPV2ROUTER02).removeLiquidity(token0, token1, amount, 1, 1, self, deadline)
    tokenAmount: uint256 = 0
    if token == token0:
        tokenAmount = token0Amount + self._token2Token(token1, token0, token1Amount, self, deadline)
        ERC20(token).transfer(msg.sender, tokenAmount)
    elif token == token1:
        tokenAmount = token1Amount + self._token2Token(token0, token1, token0Amount, self, deadline)
        ERC20(token).transfer(msg.sender, tokenAmount)
    elif token == VETH or token == ZERO_ADDRESS:
        if token0 == WETH:
            tokenAmount = token0Amount + self._token2Token(token1, token0, token1Amount, self, deadline)
        else:
            tokenAmount = token1Amount + self._token2Token(token0, token1, token0Amount, self, deadline)
        WrappedEth(WETH).withdraw(tokenAmount)
        send(msg.sender, tokenAmount)
    elif token0 == WETH:
        tokenAmount = token0Amount + self._token2Token(token1, token0, token1Amount, self, deadline)
        tokenAmount = self._token2Token(WETH, token, tokenAmount, msg.sender, deadline)
    elif token1 == WETH:
        tokenAmount = token1Amount + self._token2Token(token0, token1, token0Amount, self, deadline)
        tokenAmount = self._token2Token(WETH, token, tokenAmount, msg.sender, deadline)
    else:
        raise "Token ERROR"
    return tokenAmount

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