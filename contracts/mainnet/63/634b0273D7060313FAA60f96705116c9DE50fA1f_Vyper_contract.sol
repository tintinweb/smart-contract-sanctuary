# @version 0.2.12

"""
@title Unagii Token
@author stakewith.us
@license AGPL-3.0-or-later
"""

VERSION: constant(String[28]) = "0.1.1"

from vyper.interfaces import ERC20

implements: ERC20


interface DetailedERC20:
    def name() -> String[42]: view
    def symbol() -> String[20]: view
    # Vyper does not support uint8
    def decimals() -> uint256: view


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


event SetNextTimeLock:
    timeLock: address


event AcceptTimeLock:
    timeLock: address


event SetMinter:
    minter: address


name: public(String[64])
symbol: public(String[32])
# Vyper does not support uint8
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

# EIP 2612 #
# https://eips.ethereum.org/EIPS/eip-2612
# `nonces` track `permit` approvals with signature.
nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
)
PERMIT_TYPE_HASH: constant(bytes32) = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
)

timeLock: public(address)
nextTimeLock: public(address)
minter: public(address)
token: public(ERC20)
# placeholder address used when token ETH
ETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
# last block number balance of msg.sender was changed (mint, burn, transfer, transferFrom)
lastBlock: public(HashMap[address, uint256])


@external
def __init__(token: address):
    self.timeLock = msg.sender
    self.token = ERC20(token)

    if token == ETH:
        self.name = "unagii_ETH_v2"
        self.symbol = "uETHv2"
        self.decimals = 18
    else:
        self.name = concat("unagii_", DetailedERC20(token).name(), "_v2")
        self.symbol = concat("u", DetailedERC20(token).symbol(), "v2")
        self.decimals = DetailedERC20(token).decimals()

    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("unagii", Bytes[6])),
            keccak256(convert(VERSION, Bytes[28])),
            convert(chain.id, bytes32),
            convert(self, bytes32),
        )
    )


@internal
@view
def _getDomainSeparator() -> bytes32:
    return keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("unagii", Bytes[6])),
            keccak256(convert(VERSION, Bytes[28])),
            convert(chain.id, bytes32),
            convert(self, bytes32),
        )
    )


@external
def setName(name: String[42]):
    assert msg.sender == self.timeLock, "!time lock"
    self.name = name


@external
def setSymbol(symbol: String[20]):
    assert msg.sender == self.timeLock, "!time lock"
    self.symbol = symbol


@external
def setNextTimeLock(nextTimeLock: address):
    """
    @notice Set next time lock
    @param nextTimeLock Address of next time lock
    """
    assert msg.sender == self.timeLock, "!time lock"
    # allow next time lock = zero address (cancel next time lock)
    self.nextTimeLock = nextTimeLock
    log SetNextTimeLock(nextTimeLock)


@external
def acceptTimeLock():
    """
    @notice Accept time lock
    @dev Only `nextTimeLock` can claim time lock
    """
    assert msg.sender == self.nextTimeLock, "!next time lock"
    self.timeLock = msg.sender
    self.nextTimeLock = ZERO_ADDRESS
    log AcceptTimeLock(msg.sender)


@external
def setMinter(minter: address):
    """
    @notice Set minter
    @param minter Address of minter
    """
    assert msg.sender == self.timeLock, "!time lock"
    # allow minter = zero address
    self.minter = minter
    log SetMinter(minter)


@internal
def _transfer(_from: address, _to: address, amount: uint256):
    assert _to not in [self, ZERO_ADDRESS], "invalid receiver"

    # track lastest tx
    self.lastBlock[_from] = block.number
    self.lastBlock[_to] = block.number

    self.balanceOf[_from] -= amount
    self.balanceOf[_to] += amount
    log Transfer(_from, _to, amount)


@external
def transfer(_to: address, amount: uint256) -> bool:
    self._transfer(msg.sender, _to, amount)
    return True


@external
def transferFrom(_from: address, _to: address, amount: uint256) -> bool:
    # skip if unlimited approval
    if self.allowance[_from][msg.sender] < MAX_UINT256:
        self.allowance[_from][msg.sender] -= amount
        log Approval(_from, msg.sender, self.allowance[_from][msg.sender])
    self._transfer(_from, _to, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def increaseAllowance(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] += amount
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@external
def decreaseAllowance(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] -= amount
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@internal
@view
def _recover(digest: bytes32, v: uint256, r: bytes32, s: bytes32) -> address: 
    """
    @dev ECDSA signature malleability.
         Code ported from Solidity
         https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/cryptography/ECDSA.sol#L53
    """
    _r: uint256 = convert(r, uint256)
    _s: uint256 = convert(s, uint256)

    # 0x7FF... is intentionally not stored as constant(uint256) so that code is
    # compared with OpenZeppelin's Solidity code
    assert _s <= convert(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, uint256), "invalid signature s"
    assert v == 27 or v == 28, "invalid signature v"

    return ecrecover(digest, v, _r, _s)


@external
def permit(
    owner: address,
    spender: address,
    amount: uint256,
    deadline: uint256,
    v: uint256,
    r: bytes32,
    s: bytes32,
):
    """
    @notice Approves spender by owner's signature to expend owner's tokens.
            https://eips.ethereum.org/EIPS/eip-2612
    @dev Vyper does not have `uint8`, so replace `v: uint8` with `v: uint256`
    """
    assert owner != ZERO_ADDRESS, "owner = 0 address"
    assert deadline >= block.timestamp, "expired"

    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            self._getDomainSeparator(), # chain id may be different after fork, recompute domain separator
            keccak256(
                concat(
                    PERMIT_TYPE_HASH,
                    convert(owner, bytes32),
                    convert(spender, bytes32),
                    convert(amount, bytes32),
                    convert(self.nonces[owner], bytes32),
                    convert(deadline, bytes32),
                )
            ),
        )
    )

    # owner cannot = ZERO_ADDRESS from check above
    # this will fail if _recover() returns ZERO_ADDRESS
    assert self._recover(digest, v, r, s) == owner, "invalid signature"

    self.nonces[owner] += 1
    self.allowance[owner][spender] = amount
    log Approval(owner, spender, amount)


@external
def mint(_to: address, amount: uint256):
    assert msg.sender == self.minter, "!minter"
    assert _to not in [self, ZERO_ADDRESS], "invalid receiver"

    # track lastest tx
    self.lastBlock[_to] = block.number

    self.totalSupply += amount
    self.balanceOf[_to] += amount
    log Transfer(ZERO_ADDRESS, _to, amount)


@external
def burn(_from: address, amount: uint256):
    assert msg.sender == self.minter, "!minter"
    assert _from != ZERO_ADDRESS, "from = 0"

    # track lastest tx
    self.lastBlock[_from] = block.number

    self.totalSupply -= amount
    self.balanceOf[_from] -= amount
    log Transfer(_from, ZERO_ADDRESS, amount)