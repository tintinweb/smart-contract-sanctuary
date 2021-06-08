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


interface Mintable:
    def mint(owner: address, amount: uint256): nonpayable
    def burn(owner: address, amount: uint256): nonpayable


interface Lido:
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


event LiquidationsAdminUpdated:
    liquidations_admin: address


event AnchorRewardsDistributorUpdated:
    anchor_rewards_distributor: bytes32


BETH_DECIMALS: constant(uint256) = 18

# no rewards liquidations for 5m since previous liquidation (TESTNET ONLY)
NO_LIQUIDATION_INTERVAL: constant(uint256) = 60 * 5
# only admin can liquidate rewards for the first 2m after that (TESTNET ONLY)
RESTRICTED_LIQUIDATION_INTERVAL: constant(uint256) = NO_LIQUIDATION_INTERVAL + 60 * 2

admin: public(address)

beth_token: public(address)
steth_token: public(address)
bridge_connector: public(address)
rewards_liquidator: public(address)
anchor_rewards_distributor: public(bytes32)

liquidations_admin: public(address)
last_liquidation_time: public(uint256)
last_liquidation_shares_balance: public(uint256)
last_liquidation_steth_balance: public(uint256)
last_liquidation_shares_steth_rate: public(uint256)


@external
def __init__(beth_token: address, steth_token: address, admin: address):
    self.beth_token = beth_token
    self.steth_token = steth_token
    self.admin = admin
    self.last_liquidation_shares_steth_rate = Lido(steth_token).getPooledEthByShares(10**18)
    log AdminChanged(admin)


@external
def change_admin(new_admin: address):
    assert msg.sender == self.admin
    self.admin = new_admin
    log AdminChanged(new_admin)


@internal
def _set_bridge_connector(_bridge_connector: address):
    self.bridge_connector = _bridge_connector
    log BridgeConnectorUpdated(_bridge_connector)


@external
def set_bridge_connector(_bridge_connector: address):
    assert msg.sender == self.admin
    self._set_bridge_connector(_bridge_connector)


@internal
def _set_rewards_liquidator(_rewards_liquidator: address):
    self.rewards_liquidator = _rewards_liquidator
    log RewardsLiquidatorUpdated(_rewards_liquidator)


@external
def set_rewards_liquidator(_rewards_liquidator: address):
    assert msg.sender == self.admin
    self._set_rewards_liquidator(_rewards_liquidator)


@internal
def _set_liquidations_admin(_liquidations_admin: address):
    self.liquidations_admin = _liquidations_admin
    log LiquidationsAdminUpdated(_liquidations_admin)


@external
def set_liquidations_admin(_liquidations_admin: address):
    assert msg.sender == self.admin
    self._set_liquidations_admin(_liquidations_admin)


@internal
def _set_anchor_rewards_distributor(_anchor_rewards_distributor: bytes32):
    self.anchor_rewards_distributor = _anchor_rewards_distributor
    log AnchorRewardsDistributorUpdated(_anchor_rewards_distributor)


@external
def set_anchor_rewards_distributor(_anchor_rewards_distributor: bytes32):
    assert msg.sender == self.admin
    self._set_anchor_rewards_distributor(_anchor_rewards_distributor)


@external
def configure(
    _bridge_connector: address,
    _rewards_liquidator: address,
    _liquidations_admin: address,
    _anchor_rewards_distributor: bytes32,
):
    assert msg.sender == self.admin
    self._set_bridge_connector(_bridge_connector)
    self._set_rewards_liquidator(_rewards_liquidator)
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


@external
def submit(_amount: uint256, _terra_address: bytes32, _extra_data: Bytes[1024]):
    connector: address = self.bridge_connector

    beth_rate: uint256 = self._get_rate(False)
    beth_amount: uint256 = (_amount * beth_rate) / 10**18
    # the bridge might not support full precision amounts
    beth_amount = BridgeConnector(connector).adjust_amount(beth_amount, BETH_DECIMALS)

    steth_amount_adj: uint256 = (beth_amount * 10**18) / beth_rate
    assert steth_amount_adj <= _amount

    ERC20(self.steth_token).transferFrom(msg.sender, self, steth_amount_adj)
    Mintable(self.beth_token).mint(connector, beth_amount)
    BridgeConnector(connector).forward_beth(_terra_address, beth_amount, _extra_data)

    log Deposited(msg.sender, steth_amount_adj, _terra_address)


@external
def withdraw(_amount: uint256, _recipient: address = msg.sender):
    steth_rate: uint256 = self._get_rate(True)
    steth_amount: uint256 = (_amount * steth_rate) / 10**18

    Mintable(self.beth_token).burn(msg.sender, _amount)
    ERC20(self.steth_token).transfer(_recipient, steth_amount)

    log Withdrawn(_recipient, _amount)


@external
def collect_rewards() -> uint256:
    time_since_last_liquidation: uint256 = block.timestamp - self.last_liquidation_time

    if msg.sender == self.liquidations_admin:
        assert time_since_last_liquidation > NO_LIQUIDATION_INTERVAL
    else:
        assert time_since_last_liquidation > RESTRICTED_LIQUIDATION_INTERVAL

    steth_token: address = self.steth_token
    shares_balance: uint256 = Lido(steth_token).sharesOf(self)
    last_liquidation_shares_balance: uint256 = self.last_liquidation_shares_balance

    non_reward_balance_change: int256 = 0

    if shares_balance >= last_liquidation_shares_balance:
        non_reward_balance_change = convert(
            (shares_balance - last_liquidation_shares_balance) * self.last_liquidation_shares_steth_rate / 10**18, 
            int256
        )
    else:
        non_reward_balance_change = -1 * convert(
            (last_liquidation_shares_balance - shares_balance) * self.last_liquidation_shares_steth_rate / 10**18, 
            int256
        )

    steth_balance: uint256 = ERC20(steth_token).balanceOf(self)

    # -non_reward_balance_change cannot be greater than self.last_liquidation_steth_balance
    steth_base_balance: uint256 = convert(
        convert(self.last_liquidation_steth_balance, int256) + non_reward_balance_change,
        uint256
    )

    self.last_liquidation_shares_balance = shares_balance
    self.last_liquidation_steth_balance = steth_balance
    self.last_liquidation_time = block.timestamp
    self.last_liquidation_shares_steth_rate = Lido(steth_token).getPooledEthByShares(10**18)

    if steth_balance <= steth_base_balance:
        log RewardsCollected(0, 0)
        return 0

    steth_to_sell: uint256 = steth_balance - steth_base_balance

    connector: address = self.bridge_connector
    liquidator: address = self.rewards_liquidator

    ERC20(steth_token).transfer(liquidator, steth_to_sell)
    ust_amount: uint256 = RewardsLiquidator(liquidator).liquidate(connector)
    BridgeConnector(connector).forward_ust(self.anchor_rewards_distributor, ust_amount, b"")

    log RewardsCollected(steth_to_sell, ust_amount)

    return ust_amount