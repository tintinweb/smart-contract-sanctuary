# @version 0.2.12
# @author skozin <[email protected]>
# @licence MIT
from vyper.interfaces import ERC20


interface BridgeConnector:
    def forward_beth(terra_address: bytes32, amount: uint256, extra_data: Bytes[1024]): nonpayable
    def forward_ust(terra_address: bytes32, amount: uint256, extra_data: Bytes[1024]): nonpayable
    def adjust_amount(amount: uint256, decimals: uint256) -> uint256: view


interface RewardsLiquidator:
    def liquidate(ust_recipient: address) -> uint256: nonpayable


interface InsuranceConnector:
    def total_shares_burnt() -> uint256: view


interface Mintable:
    def mint(owner: address, amount: uint256): nonpayable
    def burn(owner: address, amount: uint256): nonpayable


interface Lido:
    def submit(referral: address) -> uint256: payable
    def totalSupply() -> uint256: view
    def getTotalShares() -> uint256: view
    def sharesOf(owner: address) -> uint256: view
    def getPooledEthByShares(shares_amount: uint256) -> uint256: view


event Deposited:
    sender: indexed(address)
    amount: uint256
    terra_address: bytes32


event Withdrawn:
    recipient: indexed(address)
    amount: uint256


event RewardsCollected:
    steth_amount: uint256
    ust_amount: uint256


event AdminChanged:
    new_admin: address


event BridgeConnectorUpdated:
    bridge_connector: address


event RewardsLiquidatorUpdated:
    rewards_liquidator: address


event InsuranceConnectorUpdated:
    insurance_connector: address


event LiquidationsAdminUpdated:
    liquidations_admin: address


event AnchorRewardsDistributorUpdated:
    anchor_rewards_distributor: bytes32


BETH_DECIMALS: constant(uint256) = 18

# no rewards liquidations for 24h since previous liquidation
NO_LIQUIDATION_INTERVAL: constant(uint256) = 60 * 60 * 24
# only admin can liquidate rewards for the first 2h after that
RESTRICTED_LIQUIDATION_INTERVAL: constant(uint256) = NO_LIQUIDATION_INTERVAL + 60 * 60 * 2

admin: public(address)

beth_token: public(address)
steth_token: public(address)
bridge_connector: public(address)
rewards_liquidator: public(address)
insurance_connector: public(address)
anchor_rewards_distributor: public(bytes32)

liquidations_admin: public(address)
last_liquidation_time: public(uint256)
last_liquidation_share_price: public(uint256)
last_liquidation_shares_burnt: public(uint256)


@external
def __init__(beth_token: address, steth_token: address, admin: address):
    assert ERC20(beth_token).totalSupply() == 0 # dev: non-zero bETH total supply
    self.beth_token = beth_token
    self.steth_token = steth_token
    self.admin = admin
    self.last_liquidation_share_price = Lido(steth_token).getPooledEthByShares(10**18)
    log AdminChanged(admin)


@external
def change_admin(new_admin: address):
    assert msg.sender == self.admin # dev: unauthorized
    self.admin = new_admin
    log AdminChanged(new_admin)


@internal
def _set_bridge_connector(_bridge_connector: address):
    self.bridge_connector = _bridge_connector
    log BridgeConnectorUpdated(_bridge_connector)


@external
def set_bridge_connector(_bridge_connector: address):
    assert msg.sender == self.admin # dev: unauthorized
    self._set_bridge_connector(_bridge_connector)


@internal
def _set_rewards_liquidator(_rewards_liquidator: address):
    self.rewards_liquidator = _rewards_liquidator # dev: unauthorized
    log RewardsLiquidatorUpdated(_rewards_liquidator)


@external
def set_rewards_liquidator(_rewards_liquidator: address):
    assert msg.sender == self.admin # dev: unauthorized
    self._set_rewards_liquidator(_rewards_liquidator)


@internal
def _set_insurance_connector(_insurance_connector: address):
    self.insurance_connector = _insurance_connector
    log InsuranceConnectorUpdated(_insurance_connector)


@external
def set_insurance_connector(_insurance_connector: address):
    assert msg.sender == self.admin # dev: unauthorized
    self._set_insurance_connector(_insurance_connector)


@internal
def _set_liquidations_admin(_liquidations_admin: address):
    self.liquidations_admin = _liquidations_admin
    log LiquidationsAdminUpdated(_liquidations_admin)


@external
def set_liquidations_admin(_liquidations_admin: address):
    assert msg.sender == self.admin # dev: unauthorized
    self._set_liquidations_admin(_liquidations_admin)


@internal
def _set_anchor_rewards_distributor(_anchor_rewards_distributor: bytes32):
    self.anchor_rewards_distributor = _anchor_rewards_distributor
    log AnchorRewardsDistributorUpdated(_anchor_rewards_distributor)


@external
def set_anchor_rewards_distributor(_anchor_rewards_distributor: bytes32):
    assert msg.sender == self.admin # dev: unauthorized
    self._set_anchor_rewards_distributor(_anchor_rewards_distributor)


@external
def configure(
    _bridge_connector: address,
    _rewards_liquidator: address,
    _insurance_connector: address,
    _liquidations_admin: address,
    _anchor_rewards_distributor: bytes32,
):
    assert msg.sender == self.admin # dev: unauthorized
    self._set_bridge_connector(_bridge_connector)
    self._set_rewards_liquidator(_rewards_liquidator)
    self._set_insurance_connector(_insurance_connector)
    self._set_liquidations_admin(_liquidations_admin)
    self._set_anchor_rewards_distributor(_anchor_rewards_distributor)


@internal
@view
def _get_rate(_is_withdraw_rate: bool) -> uint256:
    steth_balance: uint256 = ERC20(self.steth_token).balanceOf(self)
    beth_supply: uint256 = ERC20(self.beth_token).totalSupply()
    if steth_balance >= beth_supply:
        return 10**18
    elif _is_withdraw_rate:
        return (steth_balance * 10**18) / beth_supply
    elif steth_balance == 0:
        return 10**18
    else:
        return (beth_supply * 10**18) / steth_balance


@external
@view
def get_rate() -> uint256:
    """
    @dev How much bETH one receives for depositing one stETH, and how much bETH one needs
         to provide to withdraw one stETH, 10**18 being the 1:1 rate.
    """
    return self._get_rate(False)


@pure
@internal
def _diff_abs(new: uint256, old: uint256) -> uint256:
    if new > old :
        return new - old
    else:
        return old - new


@view
@internal
def _can_deposit_or_withdraw() -> bool:
    share_price: uint256 = Lido(self.steth_token).getPooledEthByShares(10**18)
    return self._diff_abs(share_price, self.last_liquidation_share_price) <= 100


@view
@external
def can_deposit_or_withdraw() -> bool:
    """
    @dev Whether deposits and withdrawals are enabled.

    Deposits and withdrawals are disabled if stETH token has rebased (e.g. Lido
    oracle reported Beacon chain rewards/penalties or insurance was applied) but
    vault rewards accrued since the last rewards sell operation are not sold to
    UST yet. Normally, this period should not last more than a couple of minutes
    each 24h.
    """
    return self._can_deposit_or_withdraw()


@external
@payable
def submit(_amount: uint256, _terra_address: bytes32, _extra_data: Bytes[1024]):
    assert self._can_deposit_or_withdraw() # dev: share price changed

    steth_token: address = self.steth_token
    steth_amount: uint256 = _amount

    if msg.value != 0:
        assert msg.value == _amount # dev: unexpected ETH amount sent
        shares_minted: uint256 = Lido(steth_token).submit(self, value=_amount)
        steth_amount = Lido(steth_token).getPooledEthByShares(shares_minted)

    connector: address = self.bridge_connector

    beth_rate: uint256 = self._get_rate(False)
    beth_amount: uint256 = (steth_amount * beth_rate) / 10**18
    # the bridge might not support full precision amounts
    beth_amount = BridgeConnector(connector).adjust_amount(beth_amount, BETH_DECIMALS)

    steth_amount_adj: uint256 = (beth_amount * 10**18) / beth_rate
    assert steth_amount_adj <= steth_amount # dev: invalid adjusted amount

    if msg.value == 0:
        ERC20(steth_token).transferFrom(msg.sender, self, steth_amount_adj)
    elif steth_amount_adj < steth_amount:
        ERC20(steth_token).transfer(msg.sender, steth_amount - steth_amount_adj)

    Mintable(self.beth_token).mint(connector, beth_amount)
    BridgeConnector(connector).forward_beth(_terra_address, beth_amount, _extra_data)

    log Deposited(msg.sender, steth_amount_adj, _terra_address)


@external
def withdraw(_amount: uint256, _recipient: address = msg.sender):
    assert self._can_deposit_or_withdraw() # dev: share price changed

    steth_rate: uint256 = self._get_rate(True)
    steth_amount: uint256 = (_amount * steth_rate) / 10**18

    Mintable(self.beth_token).burn(msg.sender, _amount)
    ERC20(self.steth_token).transfer(_recipient, steth_amount)

    log Withdrawn(_recipient, _amount)


@external
def collect_rewards() -> uint256:
    time_since_last_liquidation: uint256 = block.timestamp - self.last_liquidation_time

    if msg.sender == self.liquidations_admin:
        assert time_since_last_liquidation > NO_LIQUIDATION_INTERVAL # dev: too eraly to sell
    else:
        assert time_since_last_liquidation > RESTRICTED_LIQUIDATION_INTERVAL # dev: too eraly to sell

    # The code below sells all rewards accrued by stETH held in the vallet to UST
    # and forwards the outcome to the rewards distributor contract in Terra.
    #
    # To calculate the amount of rewards, we need to take the amount of stETH shares
    # the vault holds and determine how these shares' price increased since the last
    # rewards sell operation. We know that each shares that was transferred to the
    # vault since then was worth the same amount of stETH because the vault reverts
    # any deposits and withdrawals if the current share price is different from the
    # one actual at the last rewards sell time (see `can_deposit_or_withdraw` fn).
    #
    # When calculating the difference in share price, we need to account for possible
    # insurance applications that might have occured since the last rewards sell operation.
    # Insurance is applied by burning stETH shares, and the resulting price increase of
    # a single share shouldn't be considered as rewards and should recover bETH/stETH
    # peg instead:
    #
    # rewards = vault_shares_bal * (new_share_price - prev_share_price)
    #
    # new_share_price = new_total_ether / new_total_shares
    # new_total_ether = prev_total_ether + d_ether_io + d_rewards
    # new_total_shares = prev_total_shares + d_shares_io - d_shares_insurance_burnt
    #
    # rewards_corrected = vault_shares_bal * (new_share_price_corrected - prev_share_price)
    # new_share_price_corrected = new_total_ether / new_total_shares_corrected
    # new_total_shares_corrected = prev_total_shares + d_shares_io
    # new_share_price_corrected = new_total_ether / (new_total_shares + d_shares_insurance_burnt)

    steth_token: address = self.steth_token
    total_pooled_eth: uint256 = Lido(steth_token).totalSupply()
    total_shares: uint256 = Lido(steth_token).getTotalShares()

    share_price: uint256 = (10**18 * total_pooled_eth) / total_shares
    shares_burnt: uint256 = InsuranceConnector(self.insurance_connector).total_shares_burnt()

    prev_share_price: uint256 = self.last_liquidation_share_price
    prev_shares_burnt: uint256 = self.last_liquidation_shares_burnt

    self.last_liquidation_time = block.timestamp
    self.last_liquidation_share_price = share_price
    self.last_liquidation_shares_burnt = shares_burnt

    shares_burnt_since: uint256 = shares_burnt - prev_shares_burnt
    share_price_corrected: uint256 = (10**18 * total_pooled_eth) / (total_shares + shares_burnt_since)

    if share_price_corrected <= prev_share_price:
        log RewardsCollected(0, 0)
        return 0

    shares_balance: uint256 = Lido(steth_token).sharesOf(self)
    steth_to_sell: uint256 = shares_balance * (share_price_corrected - prev_share_price) / 10**18

    connector: address = self.bridge_connector
    liquidator: address = self.rewards_liquidator

    ERC20(steth_token).transfer(liquidator, steth_to_sell)
    ust_amount: uint256 = RewardsLiquidator(liquidator).liquidate(connector)

    BridgeConnector(connector).forward_ust(self.anchor_rewards_distributor, ust_amount, b"")

    log RewardsCollected(steth_to_sell, ust_amount)

    return ust_amount