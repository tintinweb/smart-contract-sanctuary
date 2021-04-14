# @version ^0.2.0

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

struct ModifyParams:
    token0: address
    token1: address
    fee: uint256
    tickLower: int128
    tickUpper: int128
    amount: uint256
    recipient: address
    deadline: uint256

interface ERC20:
    def approve(spender: address, amount: uint256): nonpayable
    def transfer(recipient: address, amount: uint256): nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256): nonpayable

interface ERC721:
    def transferFrom(_from: address, _to: address, _tokenId: uint256): payable

interface NonfungiblePositionManager:
    def increaseLiquidity(tokenId: uint256, amount0Desired: uint256, amount1Desired: uint256, amount0Min: uint256, amount1Min: uint256, deadline: uint256) -> (uint256, uint256): payable
    def decreaseLiquidity(tokenId: uint256, liquidity: uint256, amount0Min: uint256, amount1Min: uint256, deadline: uint256) -> (uint256, uint256): payable
    def collect(tokenId: uint256, recipient: address, amount0Max: uint256, amount1Max: uint256) -> (uint256, uint256): payable
    def mint(params: MintParams) -> (uint256, uint256, uint256): payable
    def burn(tokenId: uint256): payable

interface WrappedEth:
    def deposit(): payable

NONFUNGIBLEPOSITIONMANAGER: constant(address) = 0x048A595f1605BdC9732eBb967a1B9d9D9EE7E6Ff

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH: constant(address) = 0xc778417E063141139Fce010982780140Aa0cD5Ab # 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEADLINE: constant(uint256) = MAX_UINT256 # change

paused: public(bool)
admin: public(address)
feeAddress: public(address)
feeAmount: public(uint256)

@external
def __init__():
    self.paused = False
    self.admin = msg.sender
    self.feeAddress = 0x2D8EAC24e31e260Ced8e2A115FFFE5542584Ee47 # 0xf29399fB3311082d9F8e62b988cBA44a5a98ebeD
    self.feeAmount = 5 * 10 ** 15

@external
@payable
@nonreentrant('lock')
def addLiquidityForUniV3(_tokenId: uint256, _uniV3Params: MintParams):
    assert not self.paused, "Paused"
    fee: uint256 = self.feeAmount
    msg_value: uint256 = msg.value
    assert msg.value >= fee, "Insufficient fee"
    if fee > 0:
        send(self.feeAddress, fee)
        msg_value -= fee
    uniV3Params: MintParams = _uniV3Params
    assert uniV3Params.token0 != uniV3Params.token1, "Same token"
    if uniV3Params.token0 == ZERO_ADDRESS or uniV3Params.token0 == VETH:
        WrappedEth(WETH).deposit(value=msg_value)
        uniV3Params.token0 = WETH
    else:
        ERC20(uniV3Params.token0).transferFrom(msg.sender, self, uniV3Params.amount0Desired)
    if uniV3Params.token1 == ZERO_ADDRESS or uniV3Params.token1 == VETH:
        WrappedEth(WETH).deposit(value=msg_value)
        uniV3Params.token1 = WETH
    else:
        ERC20(uniV3Params.token1).transferFrom(msg.sender, self, uniV3Params.amount1Desired)
    pool: address = ZERO_ADDRESS
    if convert(uniV3Params.token0, uint256) > convert(uniV3Params.token1, uint256):
        tempAddress: address = uniV3Params.token0
        uniV3Params.token0 = uniV3Params.token1
        uniV3Params.token1 = tempAddress
        tempAmount: uint256 = uniV3Params.amount0Desired
        uniV3Params.amount0Desired = uniV3Params.amount1Desired
        uniV3Params.amount1Desired = tempAmount
        tempAmount = uniV3Params.amount0Min
        uniV3Params.amount0Min = uniV3Params.amount1Min
        uniV3Params.amount1Min = tempAmount
    ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, uniV3Params.amount0Desired)
    ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, uniV3Params.amount1Desired)
    if _tokenId == 0:
        tokenId: uint256 = 0
        amount0: uint256 = 0
        amount1: uint256 = 0
        (tokenId, amount0, amount1) = NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).mint(uniV3Params)
        if amount0 < uniV3Params.amount0Desired:
            ERC20(uniV3Params.token0).transfer(msg.sender, uniV3Params.amount0Desired - amount0)
            ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
        if amount1 < uniV3Params.amount1Desired:
            ERC20(uniV3Params.token1).transfer(msg.sender, uniV3Params.amount1Desired - amount1)
            ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
    else:
        amount0: uint256 = 0
        amount1: uint256 = 0
        (amount0, amount1) = NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).increaseLiquidity(_tokenId, uniV3Params.amount0Desired, uniV3Params.amount1Desired, uniV3Params.amount0Min, uniV3Params.amount1Min, uniV3Params.deadline)
        if amount0 < uniV3Params.amount0Desired:
            ERC20(uniV3Params.token0).transfer(msg.sender, uniV3Params.amount0Desired - amount0)
            ERC20(uniV3Params.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
        if amount1 < uniV3Params.amount1Desired:
            ERC20(uniV3Params.token1).transfer(msg.sender, uniV3Params.amount1Desired - amount1)
            ERC20(uniV3Params.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)

@external
@payable
@nonreentrant('lock')
def modifyPositionForUniV3NFLP(_tokenId: uint256, _modifyParams: ModifyParams):
    assert _tokenId != 0, "Wrong Token ID"
    funcsig: Bytes[4] = method_id("positions(uint256)")
    addrBytes: bytes32 = convert(_tokenId, bytes32)
    full_data: Bytes[36] = concat(funcsig, addrBytes)
    _response: Bytes[384] = raw_call(
        NONFUNGIBLEPOSITIONMANAGER,
        full_data,
        max_outsize=384
    )
    liquidity: uint256 = convert(slice(_response, 224, 32), uint256)
    modifyParams: ModifyParams = _modifyParams
    
    if modifyParams.token0 == ZERO_ADDRESS or modifyParams.token0 == VETH:
        modifyParams.token0 = WETH
    if modifyParams.token1 == ZERO_ADDRESS or modifyParams.token1 == VETH:
        modifyParams.token1 = WETH
    pool: address = ZERO_ADDRESS
    if convert(modifyParams.token0, uint256) > convert(modifyParams.token1, uint256):
        tempAddress: address = modifyParams.token0
        modifyParams.token0 = modifyParams.token1
        modifyParams.token1 = tempAddress

    ERC721(NONFUNGIBLEPOSITIONMANAGER).transferFrom(msg.sender, self, _tokenId)
    amount0fee: uint256 = 0
    amount1fee: uint256 = 0
    (amount0fee, amount1fee) = NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).collect(_tokenId, self, MAX_UINT256, MAX_UINT256)
    amount0: uint256 = 0
    amount1: uint256 = 0
    (amount0, amount1) = NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).decreaseLiquidity(_tokenId, liquidity, 1, 1, modifyParams.deadline)
    NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).burn(_tokenId)
    amount0 += amount0fee
    amount1 += amount1fee
    ERC20(modifyParams.token0).approve(NONFUNGIBLEPOSITIONMANAGER, amount0)
    ERC20(modifyParams.token1).approve(NONFUNGIBLEPOSITIONMANAGER, amount1)
    mintParams: MintParams = MintParams({
        token0: modifyParams.token0,
        token1: modifyParams.token1,
        fee: modifyParams.fee,
        tickLower: modifyParams.tickLower,
        tickUpper: modifyParams.tickUpper,
        amount0Desired: amount0,
        amount1Desired: amount1,
        amount0Min: 1,
        amount1Min: 1,
        recipient: msg.sender,
        deadline: modifyParams.deadline
    })
    tokenId: uint256 = 0
    amount0new: uint256 = 0
    amount1new: uint256 = 0
    (tokenId, amount0new, amount1new) = NonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).mint(mintParams)
    if amount0 > amount0new:
        ERC20(modifyParams.token0).transfer(msg.sender, amount0new - amount0)
        ERC20(modifyParams.token0).approve(NONFUNGIBLEPOSITIONMANAGER, 0)
    if amount1 > amount1new:
        ERC20(modifyParams.token1).transfer(msg.sender, amount1new - amount1)
        ERC20(modifyParams.token1).approve(NONFUNGIBLEPOSITIONMANAGER, 0)

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