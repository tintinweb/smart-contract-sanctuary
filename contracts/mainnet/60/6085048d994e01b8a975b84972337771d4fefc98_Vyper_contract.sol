# @version 0.2.12

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event AddTrustedERC721:
    contract: indexed(address)

event RmTrustedERC721:
    contract: indexed(address)

event Reward:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


interface ERC721Contract():
    def ownerOf(_tokenId: uint256) -> address: view
    def firstReward(_tokenId: uint256) -> uint256: view


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: address
erc721: HashMap[address, bool]
rewards: HashMap[uint256, uint256]


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.minter = msg.sender
    log Transfer(ZERO_ADDRESS, msg.sender, 0)


@external
def addTrustedERC721(_contract : address):
    assert _contract != ZERO_ADDRESS
    assert msg.sender == self.minter
    assert not self.erc721[_contract]
    self.erc721[_contract] = True
    log AddTrustedERC721(_contract)


@external
def rmTrustedERC721(_contract : address):
    assert _contract != ZERO_ADDRESS
    assert msg.sender == self.minter
    assert self.erc721[_contract]
    self.erc721[_contract] = False
    log RmTrustedERC721(_contract)


@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    assert self.minter == msg.sender
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@external
def reward(_contract: address, _key: String[256]):
    assert self.erc721[_contract] == True
    _tokenIdBytes: bytes32 = keccak256(_key)
    _tokenId: uint256 = convert(_tokenIdBytes, uint256)
    owner: address = ERC721Contract(_contract).ownerOf(_tokenId)
    assert owner != ZERO_ADDRESS
    assert owner == msg.sender
    firstReward: uint256 = ERC721Contract(_contract).firstReward(_tokenId)
    assert firstReward != 0
    rewards: uint256 = self.rewards[_tokenId]
    reward: uint256 = firstReward / (9 ** rewards)
    self.rewards[_tokenId] = rewards + 1
    self.totalSupply += reward
    self.balanceOf[owner] += reward
    log Transfer(ZERO_ADDRESS, owner, reward)
    log Reward(_contract, owner, reward)


@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)