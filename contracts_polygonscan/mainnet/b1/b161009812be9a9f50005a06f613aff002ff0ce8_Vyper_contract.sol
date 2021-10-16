# @version 0.2.12
# WARNING: Any coins or tokens sent to this contract will be considered as incentives and distributed to stakers
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
boopedAmount: public(HashMap[address, uint256])
totalBooped: public(uint256)
inPoolSince: public(HashMap[address, uint256])
outstandingOf: public(HashMap[address, uint256])
totalOutstanding: public(uint256)
totalRevenue: public(uint256)
daoFeesAccrued: public(uint256)
feeBPS: public(uint256)
daoFeeBPS: public(uint256)
owner: public(address)
swapper: public(address)
dao: public(address)
feeController: public(address)
paymentsReceived: public(uint256)
nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
BASE_TOKEN: public(address)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")

@external
def __init__(base_token:address, fee_bps:uint256, dao_fee_bps: uint256):
    self.BASE_TOKEN = base_token
    self.feeBPS = fee_bps
    self.daoFeeBPS = dao_fee_bps
    self.owner = msg.sender
    self.swapper = msg.sender
    self.dao = msg.sender
    self.feeController = msg.sender
    self.totalRevenue = 1
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("Boop", Bytes[5])),
            keccak256(convert("1", Bytes[1])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )


@view
@external
def name() -> String[5]:
    return "Boop"


@view
@external
def symbol() -> String[5]:
    return "BOOP"


@view
@external
def decimals() -> uint256:
    return 12


@view
@internal
def _estimateFee(amount: uint256) -> uint256:
    return amount * self.feeBPS / 10000


@view
@internal
def _estimateDaoFee(amount: uint256) -> uint256:
    return amount * self.daoFeeBPS / 10000


@internal
def _mint(receiver: address, amount: uint256):
    assert not receiver in [self, ZERO_ADDRESS], "Invalid destination"

    self.balanceOf[receiver] += amount
    self.boopedAmount[receiver] += amount
    self.totalSupply += amount
    self.totalBooped += amount

    log Transfer(ZERO_ADDRESS, receiver, amount)


@view
@internal
def _getUnaccountedRewards(sender: address) -> uint256:
    rewards_to_pay: uint256 = 0
    if self.inPoolSince[sender] == 0 or self.inPoolSince[sender] == self.totalRevenue:
        return 0
    elif self.totalBooped > 0:
        cumulative_rewards: uint256 = (self.totalRevenue - self.inPoolSince[sender]) * (10000 - self.daoFeeBPS) / 10000
        user_stake: uint256 = self.boopedAmount[sender] + self.outstandingOf[sender]
        total_staked: uint256 = self.totalBooped + self.totalOutstanding
        rewards_to_pay  = cumulative_rewards * user_stake / total_staked
    return rewards_to_pay


@internal
def _updateStake(sender: address):
    amount: uint256 = self._getUnaccountedRewards(sender)
    self.outstandingOf[sender] += amount
    self.totalOutstanding += amount
    self.inPoolSince[sender] = self.totalRevenue


@internal
def _reduceStake(sender: address):
    self._updateStake(sender)
    # Reduce stake if wallet doesn't have all minted coins. This is to ensure no idex
    # gets locked over time and fees are paid only to holders who actively created supply
    if self.boopedAmount[sender] > self.balanceOf[sender]:
        amount: uint256 = self.boopedAmount[sender] - self.balanceOf[sender]
        self.totalBooped -= amount
        self.boopedAmount[sender] = self.balanceOf[sender]


@internal
def _burn(sender: address, amount: uint256):
    self.balanceOf[sender] -= amount
    self.totalSupply -= amount

    self._reduceStake(sender)

    log Transfer(sender, ZERO_ADDRESS, amount)


@view
@external
def getRewardsEstimate(sender: address) -> uint256:
    return self._getUnaccountedRewards(sender) + self.outstandingOf[sender]


@internal
def _resetRewards(sender: address):
    self.totalOutstanding -= self.outstandingOf[sender]
    self.outstandingOf[sender] = 0


@internal
def _accountRewards(amount: uint256):
    self.totalRevenue += amount
    self.daoFeesAccrued += self._estimateDaoFee(amount)


@internal
def _addToRewards(sender: address, amount: uint256) -> bool:
    assert ERC20(self.BASE_TOKEN).transferFrom(sender, self, amount), "Failure in ERC20 transfer"
    self._accountRewards(amount)
    return True


@internal
def _transfer(sender: address, receiver: address, amount: uint256):
    assert not receiver in [self, ZERO_ADDRESS], "Invalid destination"
    assert self.balanceOf[sender] >= amount, "Invalid amount"

    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    self._reduceStake(sender)

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


@internal
def _boop(sender: address, amount: uint256) -> bool:
    self._updateStake(sender)
    mint_amount: uint256 = min(amount, ERC20(self.BASE_TOKEN).balanceOf(sender))
    assert ERC20(self.BASE_TOKEN).transferFrom(sender, self, mint_amount), "Failure in ERC20 transfer"
    self._mint(sender, mint_amount)
    return True


@internal
def _takeFeesFromAmount(amount: uint256) -> uint256:
    fee_amount: uint256 = self._estimateFee(amount)
    self._accountRewards(fee_amount)
    return amount - fee_amount


@internal
def _sendBaseToken(receiver: address, amount: uint256) -> bool:
    assert ERC20(self.BASE_TOKEN).transfer(receiver, amount), "Failure in ERC20 transfer"
    return True


@internal
def _claim(sender: address) -> uint256:
    self._updateStake(sender)
    rewards_to_pay: uint256 = self.outstandingOf[sender]
    rewards_amount: uint256 = 0
    if rewards_to_pay > 0:
        self._resetRewards(sender)
        rewards_amount = self._takeFeesFromAmount(rewards_to_pay)
    return rewards_amount


@internal
def _unboop(sender: address, amount: uint256) -> bool:
    rewards_after_fees: uint256 = self._claim(sender)
    burn_amount: uint256 = min(amount, self.balanceOf[sender])
    amount_after_fees: uint256 = self._takeFeesFromAmount(burn_amount)
    self._burn(sender, burn_amount)
    self._sendBaseToken(sender, amount_after_fees + rewards_after_fees)
    return True


@external
def boop(amount: uint256) -> bool:
    self._boop(msg.sender, amount)
    return True


@external
def unboop(amount: uint256) -> bool:
    self._unboop(msg.sender, amount)
    return True


@external
def claim() -> bool:
    rewards_after_fees: uint256 = self._claim(msg.sender)
    self._sendBaseToken(msg.sender, rewards_after_fees)
    return True


@external
def addToRewards(amount: uint256) -> bool:
    return self._addToRewards(msg.sender, amount)


@external
def changeSwapper(swapper: address) -> bool:
    assert msg.sender == self.owner, "Unauthorized"
    assert swapper not in [ZERO_ADDRESS, self], "Invalid address"
    self.swapper = swapper
    return True


@external
def changeOwner(owner: address) -> bool:
    assert msg.sender == self.owner, "Unauthorized"
    # Owner can burn ownership by setting value to ZERO_ADDRESS when required
    assert owner != self, "Can't set owner to self"
    self.owner = owner
    return True


@external
def changeDao(dao: address) -> bool:
    assert msg.sender == self.dao, "Unauthorized"
    # DAO will receive it's share for incentives and development fees
    # we don't want to allow wasting that
    assert dao not in [ZERO_ADDRESS, self], "Invalid address"
    self.dao = dao
    return True


@external
def changeFeeController(fee_controller: address) -> bool:
    assert msg.sender == self.owner, "Unauthorized"
    assert fee_controller not in [ZERO_ADDRESS, self], "Invalid address"
    self.feeController = fee_controller
    return True


@external
def changeDaoFeeBPS(dao_fee_bps: uint256) -> bool:
    assert msg.sender == self.dao, "Unauthorized"
    # Dao's share of the fees, DAO can decide to take up to 50% of the fees
    # to pay for dev work or growth incentives
    assert dao_fee_bps <= 5000, "DAO share of fees can't be higher than 50%"
    self.daoFeeBPS = dao_fee_bps
    return True


@external
def changeTradeFeeBPS(fee_bps: uint256) -> bool:
    assert msg.sender == self.feeController, "Unauthorized"
    # Fees should remain low in low volatility and potentially increase in higher volatility
    assert fee_bps <= 500, "Can't set trade fee higher than 5%"
    self.feeBPS = fee_bps
    return True


@external
@payable
def __default__():
    # Accrue staking rewards from idex replicator/validator
    self.paymentsReceived += msg.value


@internal
def _sendEthPayableToSwapper():
    assert self.paymentsReceived != 0, "No payments accrued"
    send(self.swapper, self.paymentsReceived)
    self.paymentsReceived = 0


@internal
def _sendERC20PayableToSwapper(token: address) -> bool:
    amount: uint256 = ERC20(token).balanceOf(self)
    if amount == 0:
        return True
    if token == self.BASE_TOKEN:
        amount = amount - self.totalSupply
        # don't need to swap, just distribute it as rewards
        self._accountRewards(amount)
        return True
    assert ERC20(token).transfer(self.swapper, amount), "Failure in ERC20 transfer"
    return True


@external
def sendSwapperPayment(token: address) -> bool:
    assert token != self, "Invalid option"
    # Swapper will swap ETH or any ERC20 to IDEX and call addToRewards
    # to be distributed to stakers
    if token == ZERO_ADDRESS:
        self._sendEthPayableToSwapper()
    elif token.is_contract:
        assert self._sendERC20PayableToSwapper(token)
    elif not token.is_contract:
        raise "Not a contract"
    return True


@external
def sendDaoPayment() -> bool:
    assert self.daoFeesAccrued > 0, "No fees accrued"
    amount: uint256 = self.daoFeesAccrued
    self.daoFeesAccrued -= amount
    self._sendBaseToken(self.dao, amount)
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