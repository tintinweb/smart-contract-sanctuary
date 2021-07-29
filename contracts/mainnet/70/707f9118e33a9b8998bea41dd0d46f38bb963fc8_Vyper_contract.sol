# @version 0.2.12
# @author banteg
# @license MIT
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


event AdminChanged:
    new_admin: address


event MinterChanged:
    new_minter: address


name: public(String[26])
symbol: public(String[7])
decimals: public(uint256)
version: public(String[1])

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')

admin: public(address)
minter: public(address)


@external
def __init__(_symbol: String[7], _minter: address, _admin: address):
    self.name = 'bETH'
    self.symbol = _symbol
    self.decimals = 18
    self.version = '1'
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert(self.name, Bytes[26])),
            keccak256(convert(self.version, Bytes[1])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )
    self.minter = _minter
    self.admin = _admin
    log AdminChanged(_admin)
    log MinterChanged(_minter)


@external
def change_admin(new_admin: address):
    assert msg.sender == self.admin
    self.admin = new_admin
    log AdminChanged(new_admin)


@external
def set_minter(new_minter: address):
    assert msg.sender == self.admin
    self.minter = new_minter
    log MinterChanged(new_minter)


@external
def mint(owner: address, amount: uint256):
    assert msg.sender == self.minter
    self.totalSupply += amount
    self.balanceOf[owner] += amount
    log Transfer(ZERO_ADDRESS, owner, amount)


@external
def burn(owner: address, amount: uint256):
    assert msg.sender == self.minter
    self.totalSupply -= amount
    self.balanceOf[owner] -= amount
    log Transfer(owner, ZERO_ADDRESS, amount)


@internal
def _transfer(sender: address, receiver: address, amount: uint256):
    assert receiver not in [self, ZERO_ADDRESS]
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(sender, receiver, amount)


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self._transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    if msg.sender != sender and self.allowance[sender][msg.sender] != MAX_UINT256:
        self.allowance[sender][msg.sender] -= amount
        log Approval(sender, msg.sender, self.allowance[sender][msg.sender])
    self._transfer(sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def permit(owner: address, spender: address, amount: uint256, expiry: uint256, signature: Bytes[65]) -> bool:
    assert owner != ZERO_ADDRESS  # dev: invalid owner
    assert expiry == 0 or expiry >= block.timestamp  # dev: permit expired
    nonce: uint256 = self.nonces[owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                concat(
                    PERMIT_TYPE_HASH,
                    convert(owner, bytes32),
                    convert(spender, bytes32),
                    convert(amount, bytes32),
                    convert(nonce, bytes32),
                    convert(expiry, bytes32),
                )
            )
        )
    )
    # NOTE: the signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
    self.allowance[owner][spender] = amount
    self.nonces[owner] = nonce + 1
    log Approval(owner, spender, amount)
    return True