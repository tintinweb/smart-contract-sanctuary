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

renDOGE: constant(address) = 0x3832d2F059E55934220881F831bE501D180671A7
WDOGE: constant(address) = 0x35a532d376FFd9a705d0Bb319532837337A398E7
SHIB: constant(address) = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE
AKITA: constant(address) = 0x3301Ee63Fb29F863f2333Bd4466acb46CD8323E6
WOOFY: constant(address) = 0xD0660cD418a64a1d44E9214ad8e459324D8157f1

@external
def __init__():
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("Doge5", Bytes[5])),
            keccak256(convert("1", Bytes[1])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )


@view
@external
def name() -> String[5]:
    return "Doge5"


@view
@external
def symbol() -> String[5]:
    return "DOGE5"


@view
@external
def decimals() -> uint256:
    return 18


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
    mint_amount: uint256 = min(amount, ERC20(SHIB).balanceOf(msg.sender))
    assert ERC20(SHIB).transferFrom(msg.sender, self, mint_amount)
    assert ERC20(AKITA).transferFrom(msg.sender, self, mint_amount)
    assert ERC20(WDOGE).transferFrom(msg.sender, self, mint_amount)
    assert ERC20(renDOGE).transferFrom(msg.sender, self, mint_amount/(10**10))
    assert ERC20(WOOFY).transferFrom(msg.sender, self, mint_amount/(10**6))
    self._mint(receiver, mint_amount)
    return True


@external
def unwoof(amount: uint256 = MAX_UINT256, receiver: address = msg.sender) -> bool:
    burn_amount: uint256 = min(amount, self.balanceOf[msg.sender])
    self._burn(msg.sender, burn_amount)
    assert ERC20(SHIB).transfer(receiver, burn_amount)
    assert ERC20(AKITA).transfer(receiver, burn_amount)
    assert ERC20(WDOGE).transfer(receiver, burn_amount)
    assert ERC20(renDOGE).transfer(receiver, burn_amount/(10**10))	
    assert ERC20(WOOFY).transfer(receiver, burn_amount/(10**6))		
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