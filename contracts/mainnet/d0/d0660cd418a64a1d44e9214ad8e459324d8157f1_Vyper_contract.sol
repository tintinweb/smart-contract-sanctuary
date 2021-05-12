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


allowance: public(HashMap[address, HashMap[address, uint256]])
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")

YFI: constant(address) = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e


@external
def __init__():
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("Woofy", Bytes[5])),
            keccak256(convert("1", Bytes[1])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )


@view
@external
def name() -> String[5]:
    return "Woofy"


@view
@external
def symbol() -> String[5]:
    return "WOOFY"


@view
@external
def decimals() -> uint256:
    return 12


@internal
def _mint(receiver: address, amount: uint256):
    assert not receiver in [self, ZERO_ADDRESS]

    self.balanceOf[receiver] += amount
    self.totalSupply += amount

    log Transfer(ZERO_ADDRESS, receiver, amount)


@internal
def _burn(sender: address, amount: uint256):
    self.balanceOf[sender] -= amount
    self.totalSupply -= amount

    log Transfer(sender, ZERO_ADDRESS, amount)


@internal
def _transfer(sender: address, receiver: address, amount: uint256):
    assert not receiver in [self, ZERO_ADDRESS]

    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(sender, receiver, amount)


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self._transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount
    self._transfer(sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def woof(amount: uint256 = MAX_UINT256, receiver: address = msg.sender) -> bool:
    mint_amount: uint256 = min(amount, ERC20(YFI).balanceOf(msg.sender))
    assert ERC20(YFI).transferFrom(msg.sender, self, mint_amount)
    self._mint(receiver, mint_amount)
    return True


@external
def unwoof(amount: uint256 = MAX_UINT256, receiver: address = msg.sender) -> bool:
    burn_amount: uint256 = min(amount, self.balanceOf[msg.sender])
    self._burn(msg.sender, burn_amount)
    assert ERC20(YFI).transfer(receiver, burn_amount)
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
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
    self.allowance[owner][spender] = amount
    self.nonces[owner] = nonce + 1
    log Approval(owner, spender, amount)
    return True