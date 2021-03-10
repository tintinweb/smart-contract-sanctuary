# @version ^0.2.0

interface UniswapV2Pair:
    def sync(): nonpayable

interface Stakable:
    def deposit(_account: address, _amount: uint256) -> bool: nonpayable
    def stake(_reward: uint256) -> bool: nonpayable
    def withdraw(_account: address) -> bool: nonpayable

event CommitOwnership:
    owner: address

event ApplyOwnership:
    owner: address


TOKEN: constant(address) = 0x1cF4592ebfFd730c7dc92c1bdFFDfc3B9EfCf29a
MAX_PAIRS_LENGTH: constant(uint256) = 10 ** 3


uniswapPairs: public(address[MAX_PAIRS_LENGTH])
indexByPair: public(HashMap[address, uint256])
lastPairIndex: public(uint256)

author: public(address)
owner: public(address)
futureOwner: public(address)


@external
def __init__():
    self.author = msg.sender
    self.owner = msg.sender


@external
def deposit(_account: address, _amount: uint256) -> bool:
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    return Stakable(TOKEN).deposit(_account, _amount)


@external
def stake(_reward: uint256) -> bool:
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    assert Stakable(TOKEN).stake(_reward)

    _lastPairIndex: uint256 = self.lastPairIndex
    for i in range(1, MAX_PAIRS_LENGTH):
        if i > _lastPairIndex:
            break

        UniswapV2Pair(self.uniswapPairs[i]).sync()

    return True


@external
def withdraw(_account: address) -> bool:
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    return Stakable(TOKEN).withdraw(_account)


@external
def addUniswapPair(_pair: address):
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    assert _pair != ZERO_ADDRESS
    pairIndex: uint256 = self.indexByPair[_pair]
    assert pairIndex == 0, "pair is exist"

    pairIndex = self.lastPairIndex + 1
    self.uniswapPairs[pairIndex] = _pair
    self.indexByPair[_pair] = pairIndex
    self.lastPairIndex = pairIndex


@external
def removeUniswapPair(_pair: address):
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    pairIndex: uint256 = self.indexByPair[_pair]
    assert pairIndex > 0, "pair is not exist"

    recentPairIndex: uint256 = self.lastPairIndex
    lastPair: address = self.uniswapPairs[recentPairIndex]

    self.uniswapPairs[pairIndex] = lastPair
    self.indexByPair[lastPair] = pairIndex
    self.indexByPair[_pair] = 0
    self.lastPairIndex = recentPairIndex - 1


@external
def transferOwnership(_futureOwner: address):
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    self.futureOwner = _futureOwner
    log CommitOwnership(_futureOwner)


@external
def applyOwnership():
    assert msg.sender == self.owner or msg.sender == self.author, "owner only"
    _owner: address = self.futureOwner
    assert _owner != ZERO_ADDRESS, "owner not set"
    self.owner = _owner
    log ApplyOwnership(_owner)