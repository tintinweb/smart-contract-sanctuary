# @version ^0.2.0


interface LinkToken:
    def transferAndCall(_to: address, _value: uint256, _data: Bytes[64]) -> bool: nonpayable


struct Member:
    _address: address
    _score: uint256
    _scoreIntegral: uint256
    

event Win:
    _requestId: bytes32
    _randomNumber: uint256
    _winnerScore: uint256


MAX_MEMBERS: constant(uint256) = 10 ** 5


linkToken: public(address)
vrfCoordinator: public(address)
members: public(Member[MAX_MEMBERS])
membersLength: public(uint256)
isStarted: public(bool)
requests: public(bytes32[MAX_MEMBERS])
requestsLength: public(uint256)
winnerScores: public(uint256[MAX_MEMBERS])
winnerScoresLength: public(uint256)

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
    assert self.isStarted == False, "already started"

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
def chooseWinner(seed: uint256, keyHash: bytes32, fee: uint256):
    assert msg.sender == self.owner, "owner only"
    assert self.membersLength > 0, "members are empty"

    _requestsLength: uint256 = self.requestsLength
    _callRequest: Bytes[64] = concat(keyHash, convert(seed, bytes32))
    LinkToken(self.linkToken).transferAndCall(self.vrfCoordinator, fee, _callRequest)

    _vrfSeedRequest: Bytes[128] = concat(
        keyHash,
        convert(seed, bytes32),
        convert(self, bytes32),
        convert(_requestsLength, bytes32)
    )
    _vrfSeed: uint256 = convert(keccak256(_vrfSeedRequest), uint256)
    self.requests[_requestsLength] = keccak256(concat(keyHash, convert(_vrfSeed, bytes32)))
    self.requestsLength = _requestsLength + 1
    self.isStarted = True


@external
def rawFulfillRandomness(requestId: bytes32, rnd: uint256):
    assert msg.sender == self.vrfCoordinator, "coordinator only"
    _membersLength: uint256 = self.membersLength
    assert self.membersLength > 0, "members are empty"

    for i in range(0, MAX_MEMBERS):
        if i >= self.requestsLength:
            break

        if self.requests[i] == requestId:
            _winnerScoresLength: uint256 = self.winnerScoresLength
            _winnerScore: uint256 = rnd % self.members[_membersLength - 1]._scoreIntegral
            self.winnerScores[_winnerScoresLength] = _winnerScore
            self.winnerScoresLength = _winnerScoresLength + 1
            log Win(requestId, rnd, _winnerScore)
            return

    assert False, "request id not found"


@view
@external
def winner(index: uint256) -> address:
    _membersLength: uint256 = self.membersLength
    assert index < self.winnerScoresLength, "indef overflow"

    _winnerScore: uint256 = self.winnerScores[index]
    for i in range(0, MAX_MEMBERS):
        if i >= self.membersLength:
            break

        if self.members[i]._scoreIntegral > _winnerScore:
            return self.members[i]._address

    return ZERO_ADDRESS