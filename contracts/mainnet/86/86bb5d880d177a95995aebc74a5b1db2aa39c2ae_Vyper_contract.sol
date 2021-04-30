# @version 0.2.8
# @author Lido <[email protected]>
# @licence MIT
from vyper.interfaces import ERC20


# Lido DAO Vault (Agent) contract
interface Vault:
    def deposit(_token: address, _value: uint256): payable


# The purchase has been executed exchanging ETH to vested LDO
event PurchaseExecuted:
    # the address that has received the vested LDO tokens
    ldo_receiver: indexed(address)
    # the number of LDO tokens vested to ldo_receiver
    ldo_allocation: uint256
    # the amount of ETH that was paid and forwarded to the DAO
    eth_cost: uint256
    # the vesting id to be used with the DAO's TokenManager contract
    vesting_id: uint256

event OfferStarted:
    started_at: uint256
    expires_at: uint256


MAX_PURCHASERS: constant(uint256) = 50
ETH_TO_LDO_RATE_PRECISION: constant(uint256) = 10**18

LDO_TOKEN: constant(address) = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32
LIDO_DAO_TOKEN_MANAGER: constant(address) = 0xf73a1260d222f447210581DDf212D915c09a3249
LIDO_DAO_VAULT: constant(address) = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c
LIDO_DAO_VAULT_ETH_TOKEN: constant(address) = ZERO_ADDRESS


# how much LDO in one ETH, ETH_TO_LDO_RATE_PRECISION being 1
eth_to_ldo_rate: public(uint256)
ldo_allocations: public(HashMap[address, uint256])
ldo_allocations_total: public(uint256)

# in seconds
offer_expiration_delay: public(uint256)
offer_started_at: public(uint256)
offer_expires_at: public(uint256)
vesting_cliff_delay: public(uint256)
vesting_end_delay: public(uint256)


@external
def __init__(
    _eth_to_ldo_rate: uint256,
    _vesting_cliff_delay: uint256,
    _vesting_end_delay: uint256,
    _offer_expiration_delay: uint256,
    _ldo_purchasers: address[MAX_PURCHASERS],
    _ldo_allocations: uint256[MAX_PURCHASERS],
    _ldo_allocations_total: uint256
):
    """
    @param _eth_to_ldo_rate How much LDO one gets for one ETH (multiplied by 10**18)
    @param _vesting_cliff_delay Delay from vesting start to vesting cliff, in seconds
    @param _vesting_end_delay Delay from vesting start to vesting end, in seconds
    @param _offer_expiration_delay Delay from the contract deployment to offer expiration, in seconds
    @param _ldo_purchasers List of valid LDO purchasers, padded by zeroes to the length of 50
    @param _ldo_allocations List of LDO token allocations, padded by zeroes to the length of 50
    @param _ldo_allocations_total Checksum of LDO token allocations
    """
    assert _eth_to_ldo_rate > 0
    assert _vesting_end_delay >= _vesting_cliff_delay
    assert _offer_expiration_delay > 0

    self.eth_to_ldo_rate = _eth_to_ldo_rate
    self.vesting_cliff_delay = _vesting_cliff_delay
    self.vesting_end_delay = _vesting_end_delay
    self.offer_expiration_delay = _offer_expiration_delay
    self.ldo_allocations_total = _ldo_allocations_total

    allocations_sum: uint256 = 0

    for i in range(MAX_PURCHASERS):
        purchaser: address = _ldo_purchasers[i]
        if purchaser == ZERO_ADDRESS:
            break
        assert self.ldo_allocations[purchaser] == 0
        allocation: uint256 = _ldo_allocations[i]
        assert allocation > 0
        self.ldo_allocations[purchaser] = allocation
        allocations_sum += allocation

    assert allocations_sum == _ldo_allocations_total


@internal
@view
def _get_allocation(_ldo_receiver: address) -> (uint256, uint256):
    ldo_allocation: uint256 = self.ldo_allocations[_ldo_receiver]
    eth_cost: uint256 = (ldo_allocation * ETH_TO_LDO_RATE_PRECISION) / self.eth_to_ldo_rate
    return (ldo_allocation, eth_cost)


@external
@view
def offer_started() -> bool:
    """
    @return Whether the offer has started.
    """
    return self.offer_started_at != 0


@external
@view
def offer_expired() -> bool:
    """
    @return Whether the offer has expired.
    """
    return block.timestamp >= self.offer_expires_at


@internal
def _start_unless_started():
    if self.offer_started_at == 0:
        assert ERC20(LDO_TOKEN).balanceOf(self) == self.ldo_allocations_total, "not funded"
        started_at: uint256 = block.timestamp
        expires_at: uint256 = started_at + self.offer_expiration_delay
        self.offer_started_at = started_at
        self.offer_expires_at = expires_at
        log OfferStarted(started_at, expires_at)


@external
def start():
    """
    @notice Starts the offer if it 1) hasn't been started yet and 2) has received funding in full.
    """
    self._start_unless_started()


@external
@view
def get_allocation(_ldo_receiver: address = msg.sender) -> (uint256, uint256):
    """
    @param _ldo_receiver The LDO purchaser address to check
    @return
        A tuple: the first element is the amount of LDO available for purchase (zero if
        the purchase was already executed for that address), the second element is the
        Ether cost of the purchase.
    """
    return self._get_allocation(_ldo_receiver)


@internal
def _execute_purchase(_ldo_receiver: address, _caller: address, _eth_received: uint256) -> uint256:
    """
    @dev
        We don't use any reentrancy lock here because, among all external calls in this
        function (Vault.deposit, TokenManager.assignVested, LDO.transfer, and the default
        payable function of the message sender), only the last one executes the code not
        under our control, and we make this call after all state mutations.
    """
    self._start_unless_started()
    assert block.timestamp < self.offer_expires_at, "offer expired"

    ldo_allocation: uint256 = 0
    eth_cost: uint256 = 0
    ldo_allocation, eth_cost = self._get_allocation(_ldo_receiver)

    assert ldo_allocation > 0, "no allocation"
    assert _eth_received >= eth_cost, "insufficient funds"

    # clear the purchaser's allocation
    self.ldo_allocations[_ldo_receiver] = 0

    # forward ETH cost of the purchase to the DAO treasury contract
    Vault(LIDO_DAO_VAULT).deposit(
        LIDO_DAO_VAULT_ETH_TOKEN,
        eth_cost,
        value=eth_cost
    )

    vesting_start: uint256 = block.timestamp
    vesting_cliff: uint256 = vesting_start + self.vesting_cliff_delay
    vesting_end: uint256 = vesting_start + self.vesting_end_delay

    # TokenManager can only assign vested tokens from its own balance
    assert ERC20(LDO_TOKEN).transfer(LIDO_DAO_TOKEN_MANAGER, ldo_allocation)

    # assign vested LDO tokens to the purchaser from the DAO treasury reserves
    # Vyper has no uint64 data type so we have to use raw_call instead of an interface
    call_result: Bytes[32] = raw_call(
        LIDO_DAO_TOKEN_MANAGER,
        concat(
            method_id('assignVested(address,uint256,uint64,uint64,uint64,bool)'),
            convert(_ldo_receiver, bytes32),
            convert(ldo_allocation, bytes32),
            convert(vesting_start, bytes32),
            convert(vesting_cliff, bytes32),
            convert(vesting_end, bytes32),
            convert(False, bytes32)
        ),
        max_outsize=32
    )
    vesting_id: uint256 = convert(extract32(call_result, 0), uint256)

    log PurchaseExecuted(_ldo_receiver, ldo_allocation, eth_cost, vesting_id)

    # refund any excess ETH to the caller
    eth_refund: uint256 = _eth_received - eth_cost
    if eth_refund > 0:
        # use raw_call to forward all remaining gas just in case the caller is a smart contract
        raw_call(_caller, b"", value=eth_refund)

    return vesting_id


@external
@payable
def execute_purchase(_ldo_receiver: address = msg.sender) -> uint256:
    """
    @notice Purchases LDO for the specified address (defaults to message sender) in exchange for ETH.
    @param _ldo_receiver The address the purchase is executed for. Must be a valid purchaser.
    @return Vesting ID to be used with the DAO's `TokenManager` contract.
    """
    return self._execute_purchase(_ldo_receiver, msg.sender, msg.value)


@external
@payable
def __default__():
    """
    @notice Purchases LDO for the message sender in exchange for ETH.
    """
    self._execute_purchase(msg.sender, msg.sender, msg.value)


@external
def recover_unsold_tokens():
    """
    @notice Transfers unsold LDO tokens back to the DAO treasury.
    @dev May only be called after the offer expires.
    """
    assert self.offer_started_at != 0 and block.timestamp >= self.offer_expires_at
    unsold_ldo_amount: uint256 = ERC20(LDO_TOKEN).balanceOf(self)
    if unsold_ldo_amount > 0:
        ERC20(LDO_TOKEN).transfer(LIDO_DAO_VAULT, unsold_ldo_amount)