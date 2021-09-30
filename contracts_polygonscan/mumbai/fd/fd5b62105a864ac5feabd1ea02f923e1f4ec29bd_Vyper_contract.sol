# @version ^0.2.16


interface LinkToken:
    def transferAndCall(_to: address, _value: uint256, _data: Bytes[64]) -> bool: nonpayable


struct Member:
    _address: address
    _score: uint256
    _scoreIntegral: uint256


event RequestIdMismatch:
    _lastRequestId: bytes32
    _calledRequestId: bytes32


event Win:
    _requestId: bytes32
    _randomNumber: uint256
    _winnerScoreIndex: uint256
    _winnerScore: uint256


MAX_MEMBERS: constant(uint256) = 10 ** 5


linkToken: public(address)
vrfCoordinator: public(address)
members: public(Member[MAX_MEMBERS])
membersLength: public(uint256)
winnerScores: public(uint256[MAX_MEMBERS])
winnerScoresCount: public(uint256)
isLotteryLaunched: public(bool)
nonce: uint256
testField: uint256
lastRequestId: public(bytes32)
owner: public(address)


@external
def __init__(_linkToken: address, _vrfCoordinator: address):
    assert _linkToken != ZERO_ADDRESS
    assert _vrfCoordinator != ZERO_ADDRESS
    self.linkToken = _linkToken
    self.vrfCoordinator = _vrfCoordinator
    self.owner = msg.sender


@external
def addMembers(members: address[100], scores: uint256[100]):
    assert msg.sender == self.owner, "owner only"
    assert self.isLotteryLaunched == False, "already launched"

    _scoreIntegral: uint256 = 0
    _membersLength: uint256 = self.membersLength
    if _membersLength > 0:
        _scoreIntegral = self.members[_membersLength - 1]._scoreIntegral

    count: uint256 = 0
    for i in range(0, 100):
        if members[i] == ZERO_ADDRESS:
            break

        count += 1
        _scoreIntegral += scores[i]
        self.members[i + _membersLength] = Member({_address: members[i], _scoreIntegral: _scoreIntegral, _score: scores[i] })

    self.membersLength = _membersLength + count


@external
def chooseNextWinner(seed: uint256, keyHash: bytes32, fee: uint256):
    assert msg.sender == self.owner, "owner only"
    assert self.membersLength > 0, "members are empty"

    _callRequest: Bytes[64] = concat(keyHash, convert(seed, bytes32))
    LinkToken(self.linkToken).transferAndCall(self.vrfCoordinator, fee, _callRequest)

    _nonce: uint256 = self.nonce
    _vrfSeedRequest: Bytes[128] = concat(
        keyHash,
        convert(seed, bytes32),
        convert(self, bytes32),
        convert(_nonce, bytes32)
    )
    _vrfSeed: uint256 = convert(keccak256(_vrfSeedRequest), uint256)
    self.nonce = _nonce + 1
    self.lastRequestId = keccak256(concat(keyHash, convert(_vrfSeed, bytes32)))
    self.isLotteryLaunched = True


@external
def rawFulfillRandomness(requestId: bytes32, rnd: uint256):
    assert msg.sender == self.vrfCoordinator, "coordinator only"
    assert self.isLotteryLaunched == True, "lottery has not been launched"

    if self.lastRequestId != requestId:
        log RequestIdMismatch(self.lastRequestId, requestId)
        return

    _membersLength: uint256 = self.membersLength
    assert self.membersLength > 0, "members are empty"

    _winnerScore: uint256 = rnd % self.members[_membersLength - 1]._scoreIntegral
    _lastWinnerScoresCount: uint256 = self.winnerScoresCount
    self.winnerScoresCount = _lastWinnerScoresCount + 1
    self.winnerScores[_lastWinnerScoresCount] = _winnerScore

    log Win(requestId, rnd, _lastWinnerScoresCount, _winnerScore)


@view
@external
def winner(index: uint256) -> address:
    _membersLength: uint256 = self.membersLength
    assert self.isLotteryLaunched == True, "lottery has not been launched"
    assert index < self.winnerScoresCount, "wrong winner index"

    _winnerScore: uint256 = self.winnerScores[index]
    for i in range(0, MAX_MEMBERS):
        if i >= self.membersLength:
            break

        if self.members[i]._scoreIntegral > _winnerScore:
            return self.members[i]._address

    return ZERO_ADDRESS