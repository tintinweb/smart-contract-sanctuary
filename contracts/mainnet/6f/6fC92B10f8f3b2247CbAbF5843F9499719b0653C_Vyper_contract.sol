# Copyright (C) 2021 VolumeFi Software, Inc.

# @version ^0.2.0

interface ERC20:
    def balanceOf(addr: address) -> uint256: view
    def allowance(_owner: address, _spender: address) -> uint256: view
    def approve(spender: address, amount: uint256): nonpayable
    def transfer(recipient: address, amount: uint256): nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256): nonpayable

interface WrappedEth:
    def deposit(): payable
    def withdraw(wad: uint256): nonpayable

# Curve Registry Contract
interface CrvRegistry:
    def get_n_coins(_pool: address) -> uint256[2]: view
    def get_coins(_pool: address) -> address[8]: view
    def get_underlying_coins(_pool: address) -> address[8]: view
    def get_lp_token(_pool: address) -> address: view

# 4-token-Curve Pool interface for add_liquidity including is_underlying parameter
interface CurveUnderlyingAdd4Pool:
    def add_liquidity(_amounts: uint256[4], _min_amount: uint256, _is_underlying: bool): nonpayable

# 3-token-Curve Pool interface for add_liquidity including is_underlying parameter
interface CurveUnderlyingAdd3Pool:
    def add_liquidity(_amounts: uint256[3], _min_amount: uint256, _is_underlying: bool): nonpayable

# 2-token-Curve Pool interface for add_liquidity including is_underlying parameter
interface CurveUnderlyingAdd2Pool:
    def add_liquidity(_amounts: uint256[2], _min_amount: uint256, _is_underlying: bool): nonpayable

# 4-token Curve Pool interface for add_liquidity
interface Curve4Pool:
    def add_liquidity(_amounts: uint256[4], _min_amount: uint256): nonpayable

# 3-token Curve Pool interface for add_liquidity
interface Curve3Pool:
    def add_liquidity(_amounts: uint256[3], _min_amount: uint256): nonpayable

# 2-token Curve Pool interface for add_liquidity
interface Curve2Pool:
    def add_liquidity(_amounts: uint256[2], _min_amount: uint256): nonpayable

# 4-token-Curve Pool interface for add_liquidity including ETH as coin
interface CurveEth4Pool:
    def add_liquidity(_amounts: uint256[4], _min_amount: uint256): payable

# 3-token-Curve Pool interface for add_liquidity including ETH as coin
interface CurveEth3Pool:
    def add_liquidity(_amounts: uint256[3], _min_amount: uint256): payable

# 2-token-Curve Pool interface for add_liquidity including ETH as coin
interface CurveEth2Pool:
    def add_liquidity(_amounts: uint256[2], _min_amount: uint256): payable

event CurveTokenBought:
    lpToken: address
    tokenBought: uint256

UNISWAPV2ROUTER02: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEADLINE: constant(uint256) = MAX_UINT256

paused: public(bool)
admin: public(address)
feeAmount: public(uint256)
feeAddress: public(address)
crvRegistry: public(address) # Curve Registry Contract
uniIndex: public(HashMap[address, uint256]) # coin index to bring from uniswap
noUnderlyingPool: public(HashMap[address, bool]) # Curve Pools not using separate underlying coins
metaPool: public(HashMap[address, address]) # Curve meta Pools for deposit / withdraw
underlyingAddPool: public(HashMap[address, bool]) # Curve Pools with add_liquidity including is_underlying parameter
pausedPool: public(HashMap[address, bool]) # Pause protocol individual Curve Pool

@internal
def _token2Token(fromToken: address, toToken: address, tokens2Trade: uint256, deadline: uint256) -> uint256:
    """
    @notice token to token swap using Uniswap
    @param fromToken contract address of the offered token
    @param toToken contract address of the desired toToken
    @param token2Trade amount of fromToken
    @param deadline timestamp after revert transaction
    @return amount of toToken
    """
    if fromToken == toToken:
        return tokens2Trade
    if ERC20(fromToken).allowance(self, UNISWAPV2ROUTER02) > 0:
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
def _eth2Token(token: address, eth2Trade: uint256, deadline: uint256) -> uint256:
    """
    @notice eth to token swap using Uniswap
    @param token contract address of the desired Token
    @param eth2Trade amount of Ethereum
    @param deadline timestamp after revert transaction
    @return amount of toToken
    """
    if token == VETH or token == ZERO_ADDRESS:
        return eth2Trade
    elif token == WETH:
        WrappedEth(WETH).deposit(value=eth2Trade)
        return eth2Trade
    else:
        WrappedEth(WETH).deposit(value=eth2Trade)
        return self._token2Token(WETH, token, eth2Trade, deadline)

@internal
def _token2Eth(token: address, amount: uint256, deadline: uint256) -> uint256:
    """
    @notice token to eth swap using Uniswap
    @param token contract address of the desired Token
    @param eth2Trade amount of Ethereum
    @param deadline timestamp after revert transaction
    @return amount of toToken
    """
    if token == VETH or token == ZERO_ADDRESS:
        return amount
    elif token == WETH:
        WrappedEth(WETH).withdraw(amount)
        return amount
    else:
        tokenAmount: uint256 = self._token2Token(token, WETH, amount, deadline)
        WrappedEth(WETH).withdraw(tokenAmount)
        return tokenAmount

@internal
def _pullTokens(token: address, amount: uint256, sender: address, msg_value: uint256):
    """
    @notice pull token from sender
    @param token contract address of the offered Token
    @param amount amount of the offered Token
    @param sender token sender address
    @param msg_value remaining Eth amount
    """
    if token == VETH or token == ZERO_ADDRESS:
        assert msg_value >= amount, "ETH not enough"
        if msg_value > amount:
            send(sender, msg_value - amount)
    else:
        ERC20(token).transferFrom(sender, self, amount)
        if msg_value > 0:
            send(sender, msg_value)

@internal
def _enterCurve(pool: address, entryToken: address, amount: uint256, index: uint256, tokenCount: uint256, lpToken: address) -> uint256:
    """
    @notice add liquidity to Curve pool
    @param pool contract address of Curve pool
    @param entryToken contract address to add liquidity
    @param amount amount of entryToken
    @param index index of entryToken in the pool
    @param tokenCount number of coins of the pool
    @param lpToken Curve LP token of the Pool
    @return amount of minted lpToken
    """
    if entryToken != ZERO_ADDRESS and entryToken != VETH:
        if ERC20(entryToken).allowance(self, pool) > 0:
            ERC20(entryToken).approve(pool, 0)
        ERC20(entryToken).approve(pool, amount)
    if tokenCount == 4:
        amounts: uint256[4] = empty(uint256[4])
        amounts[index] = amount
        if self.underlyingAddPool[pool]:
            CurveUnderlyingAdd4Pool(pool).add_liquidity(amounts, 0, True)
        elif entryToken == VETH:
            CurveEth4Pool(pool).add_liquidity(amounts, 0, value=amount)
        else:
            Curve4Pool(pool).add_liquidity(amounts, 0)
    elif tokenCount == 3:
        amounts: uint256[3] = empty(uint256[3])
        amounts[index] = amount
        if self.underlyingAddPool[pool]:
            CurveUnderlyingAdd3Pool(pool).add_liquidity(amounts, 0, True)
        elif entryToken == VETH:
            CurveEth3Pool(pool).add_liquidity(amounts, 0, value=amount)
        else:
            Curve3Pool(pool).add_liquidity(amounts, 0)
    elif tokenCount == 2:
        amounts: uint256[2] = empty(uint256[2])
        amounts[index] = amount
        if self.underlyingAddPool[pool]:
            CurveUnderlyingAdd2Pool(pool).add_liquidity(amounts, 0, True)
        elif entryToken == VETH:
            CurveEth2Pool(pool).add_liquidity(amounts, 0, value=amount)
        else:
            Curve2Pool(pool).add_liquidity(amounts, 0)
    else:
        raise "Token count error"
    return ERC20(lpToken).balanceOf(self)

@internal
@view
def _getCurvePool(crvReg: address, swap: address, token: address) -> (address, address, uint256, uint256):
    """
    @notice get Curve Pool information from Curve Registry
    @param crvReg contract address of Curve Registry
    @param swap contract address of Curve pool
    @param token contract address of offered token
    @return pool contract address of Curve pool
    @return entryToken contract address to add liquidity
    @return tokenIndex index of entryToken in the pool
    @return tokenCount number of coins of the pool
    """
    pool: address = self.metaPool[swap]
    entryToken: address = token
    tokenIndex: uint256 = 0
    if pool == ZERO_ADDRESS:
        pool = swap
    if token == ZERO_ADDRESS:
        entryToken = VETH
    tokenCount: uint256 = CrvRegistry(crvReg).get_n_coins(swap)[1]
    coins: address[8] = empty(address[8])
    if self.noUnderlyingPool[swap]:
        coins = CrvRegistry(crvReg).get_coins(swap)
    else:
        coins = CrvRegistry(crvReg).get_underlying_coins(swap)

    for i in range(8):
        if i == tokenCount:
            tokenIndex = self.uniIndex[swap]
            entryToken = coins[tokenIndex]
            break
        if coins[i] == entryToken:
            tokenIndex = i
            break
    return (pool, entryToken, tokenIndex, tokenCount)

@internal
def _getEntryToken(token: address, entryToken: address, amount: uint256, deadline: uint256) -> uint256:
    """
    @notice get entry token amount to Curve pool
    @param token contract address of the offered token
    @param entryToken contract address to add liquidity
    @param amount amount of the offered token
    @return amount of the entryToken
    """
    tokenAmount: uint256 = amount
    if token == entryToken:
        return tokenAmount
    if token == VETH or token == ZERO_ADDRESS:
        if entryToken == WETH:
            WrappedEth(WETH).deposit(value=tokenAmount)
        else:
            tokenAmount = self._eth2Token(entryToken, tokenAmount, deadline)
    elif token == WETH:
        if entryToken == VETH or entryToken == ZERO_ADDRESS:
            WrappedEth(WETH).withdraw(tokenAmount)
        else:
            tokenAmount = self._token2Token(WETH, entryToken, tokenAmount, deadline)
    else:
        if entryToken == VETH or entryToken == ZERO_ADDRESS:
            tokenAmount = self._token2Eth(token, tokenAmount, deadline)
        else:
            tokenAmount = self._token2Token(token, WETH, tokenAmount, deadline)
            if entryToken != WETH:
                tokenAmount = self._token2Token(WETH, entryToken, tokenAmount, deadline)
    return tokenAmount

@external
def __init__():
    self.admin = msg.sender
    self.feeAmount = 1 * 10 ** 16
    self.feeAddress = 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.crvRegistry = 0x7D86446dDb609eD0F5f8684AcF30380a356b2B4c

    # Curve meta pool addresses for deposit / withdraw
    self.metaPool[0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56] = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06 # Compound
    self.metaPool[0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C] = 0xac795D2c97e60DF6a99ff1c814727302fD747a80 # USDT
    self.metaPool[0x06364f10B501e868329afBc005b3492902d6C763] = 0xA50cCc70b6a011CffDdf45057E39679379187287 # PAX
    self.metaPool[0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51] = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3 # Y
    self.metaPool[0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27] = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB # BUSD
    self.metaPool[0xA5407eAE9Ba41422680e2e00537571bcC53efBfD] = 0xFCBa3E75865d2d561BE8D220616520c171F12851 # sUSD
    self.metaPool[0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956] = 0x64448B78561690B70E17CBE8029a3e5c1bB7136e # gusd
    self.metaPool[0x3eF6A01A0f81D6046290f3e2A8c5b843e738E604] = 0x09672362833d8f703D5395ef3252D4Bfa51c15ca # husd
    self.metaPool[0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb] = 0xF1f85a74AD6c64315F85af52d3d46bF715236ADc # usdk
    self.metaPool[0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1] = 0x094d12e5b541784701FD8d65F11fc0598FBC6332 # usdn
    self.metaPool[0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171] = 0x1de7f0866e2c4adAC7b457c58Cc25c8688CDa1f2 # linkusd
    self.metaPool[0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6] = 0x803A2B40c5a9BB2B86DD630B274Fa2A9202874C2 # musd
    self.metaPool[0xC18cC39da8b11dA8c3541C598eE022258F9744da] = 0xBE175115BF33E12348ff77CcfEE4726866A0Fbd5 # rsv
    self.metaPool[0xC25099792E9349C7DD09759744ea681C7de2cb66] = 0xaa82ca713D94bBA7A89CEAB55314F9EfFEdDc78c # tbtc
    self.metaPool[0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c] = 0x61E10659fe3aa93d036d099405224E4Ac24996d0 # dusd
    self.metaPool[0x7F55DDe206dbAD629C080068923b36fe9D6bDBeF] = 0x11F419AdAbbFF8d595E7d5b223eee3863Bb3902C # pbtc
    self.metaPool[0x071c661B4DeefB59E2a3DdB20Db036821eeE8F4b] = 0xC45b2EEe6e09cA176Ca3bB5f7eEe7C47bF93c756 # bbtc
    self.metaPool[0xd81dA8D904b52208541Bade1bD6595D8a251F8dd] = 0xd5BCf53e2C81e1991570f33Fa881c49EEa570C8D # obtc
    self.metaPool[0x890f4e345B1dAED0367A877a1612f86A1f86985f] = 0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d # ust
    self.metaPool[0x42d7025938bEc20B69cBae5A77421082407f053A] = 0x3c8cAee4E09296800f8D29A68Fa3837e2dae4940 # steth

    # Curve Pools with add_liquidity including is_underlying parameter
    self.underlyingAddPool[0xDeBF20617708857ebe4F679508E7b7863a8A8EeE] = True # aave
    self.underlyingAddPool[0xEB16Ae0052ed37f479f7fe63849198Df1765a733] = True # saave
    self.underlyingAddPool[0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF] = True # ironbank

    # Curve Pools not using separate underlying coins
    self.noUnderlyingPool[0x93054188d876f558f4a66B2EF1d97d16eDf0895B] = True # ren
    self.noUnderlyingPool[0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714] = True # sbtc
    self.noUnderlyingPool[0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F] = True # hbtc

    # coin index of Curve Pools to bring from uniswap (maximum liquidity XXX-ETH)
    self.uniIndex[0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56] = 1 # Compound - USDC
    self.uniIndex[0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C] = 1 # USDT - USDC
    self.uniIndex[0x06364f10B501e868329afBc005b3492902d6C763] = 1 # PAX - USDC
    self.uniIndex[0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51] = 1 # Y - USDC
    self.uniIndex[0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27] = 1 # BUSD - USDC
    self.uniIndex[0xA5407eAE9Ba41422680e2e00537571bcC53efBfD] = 1 # sUSD - USDC
    self.uniIndex[0x93054188d876f558f4a66B2EF1d97d16eDf0895B] = 1 # ren - WBTC
    self.uniIndex[0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714] = 1 # sbtc - WBTC
    self.uniIndex[0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F] = 1 # hbtc - WBTC
    self.uniIndex[0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7] = 1 # 3pool - USDC
    self.uniIndex[0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956] = 2 # gusd - USDC
    self.uniIndex[0x3eF6A01A0f81D6046290f3e2A8c5b843e738E604] = 2 # husd - USDC
    self.uniIndex[0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb] = 2 # usdk - USDC
    self.uniIndex[0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1] = 2 # usdn - USDC
    self.uniIndex[0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171] = 2 # linkusd - USDC
    self.uniIndex[0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6] = 2 # musd - USDC
    self.uniIndex[0xC18cC39da8b11dA8c3541C598eE022258F9744da] = 2 # rsv - USDC
    self.uniIndex[0xC25099792E9349C7DD09759744ea681C7de2cb66] = 2 # tbtc - WBTC
    self.uniIndex[0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c] = 2 # dusd - USDC
    self.uniIndex[0x7F55DDe206dbAD629C080068923b36fe9D6bDBeF] = 2 # pbtc - WBTC
    self.uniIndex[0x071c661B4DeefB59E2a3DdB20Db036821eeE8F4b] = 2 # bbtc - WBTC
    self.uniIndex[0xd81dA8D904b52208541Bade1bD6595D8a251F8dd] = 2 # obtc - WBTC
    self.uniIndex[0x890f4e345B1dAED0367A877a1612f86A1f86985f] = 2 # ust - USDC
    self.uniIndex[0x0Ce6a5fF5217e38315f87032CF90686C96627CAA] = 0 # eurs - EURS
    self.uniIndex[0xc5424B857f758E906013F3555Dad202e4bdB4567] = 0 # seth - ETH
    self.uniIndex[0xDeBF20617708857ebe4F679508E7b7863a8A8EeE] = 1 # aave - USDC
    self.uniIndex[0xDC24316b9AE028F1497c275EB9192a3Ea0f67022] = 0 # steth - ETH
    self.uniIndex[0xEB16Ae0052ed37f479f7fe63849198Df1765a733] = 0 # saave - DAI
    self.uniIndex[0xA96A65c051bF88B4095Ee1f2451C2A9d43F53Ae2] = 0 # ankreth - ETH
    self.uniIndex[0x42d7025938bEc20B69cBae5A77421082407f053A] = 2 # usdp - USDC
    self.uniIndex[0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF] = 1 # ironbank - USDC
    self.uniIndex[0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0] = 0 # link - LINK

@external
@payable
@nonreentrant('lock')
def investTokenForCrvPair(token: address, amount: uint256, swap: address, minPoolTokens: uint256, deadline: uint256=DEADLINE) -> uint256:
    """
    @notice invest token / Eth for Curve Liquidity Provider pools
    @param token contract address of the offered Token
    @param amount amount of the offered Token
    @param swap contract address of Curve pool
    @param minPoolTokens minimum lptoken amount to succeed transaction
    @param deadline timestamp after revert transaction
    @return amount of lpToken to investor
    """
    assert self.pausedPool[swap] == False, "Paused Pair"
    assert self.paused == False, "Paused"
    crvReg: address = self.crvRegistry
    lpToken: address = CrvRegistry(crvReg).get_lp_token(swap)
    fee: uint256 = self.feeAmount
    msg_value: uint256 = msg.value
    
    assert msg.value >= fee, "Insufficient fee"
    send(self.feeAddress, fee)
    msg_value -= fee
    assert amount > 0, "Invalid input amount"

    self._pullTokens(token, amount, msg.sender, msg_value)
    pool: address = ZERO_ADDRESS
    entryToken: address = VETH
    tokenIndex: uint256 = 0
    tokenCount: uint256 = 0
    (pool, entryToken, tokenIndex, tokenCount) = self._getCurvePool(crvReg, swap, token)

    entryAmount: uint256 = self._getEntryToken(token, entryToken, amount, deadline)

    crvTokensBought: uint256 = self._enterCurve(pool, entryToken, entryAmount, tokenIndex, tokenCount, lpToken)
    ERC20(lpToken).transfer(msg.sender, crvTokensBought)

    assert crvTokensBought >= minPoolTokens
    log CurveTokenBought(lpToken, crvTokensBought)
    return crvTokensBought

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
def newCrvRegistry(_crvRegistry: address):
    assert msg.sender == self.admin, "Not admin"
    self.crvRegistry = _crvRegistry

@external
def modifyMetaPool(swap: address, meta: address):
    assert msg.sender == self.admin, "Not admin"
    self.metaPool[swap] = meta

@external
def modifyUnderlyingAddPool(swap: address, underlyingAdd: bool):
    assert msg.sender == self.admin, "Not admin"
    self.underlyingAddPool[swap] = underlyingAdd

@external
def modifyNoUnderlyingPool(swap: address, noUnderlying: bool):
    assert msg.sender == self.admin, "Not admin"
    self.noUnderlyingPool[swap] = noUnderlying

@external
def modifyUniIndex(swap: address, _uniIndex: uint256):
    assert msg.sender == self.admin, "Not admin"
    self.uniIndex[swap] = _uniIndex

@external
def pausePool(swap: address, _pausedPool: bool):
    assert msg.sender == self.admin, "Not admin"
    self.pausedPool[swap] = _pausedPool

@external
@payable
def __default__(): pass