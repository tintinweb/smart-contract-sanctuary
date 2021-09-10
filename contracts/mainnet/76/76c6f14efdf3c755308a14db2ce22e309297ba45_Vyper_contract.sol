# @version 0.2.15
# @author skozin
# @licence MIT

interface LidoOracle:
    def getLastCompletedEpochId() -> uint256: view
    def getBeaconSpec() -> (uint256, uint256, uint256, uint256): view

interface LidoNodeOperators:
    def getNodeOperatorsCount() -> uint256: view
    def getNodeOperator(id: uint256, full_info: bool) -> (bool, String[100], address, uint256, uint256, uint256, uint256): view

interface AnchorVault:
    def last_liquidation_time() -> uint256: view

interface WstETH:
    def getStETHByWstETH(wstETHAmount: uint256) -> uint256: view

interface CurveStableSwap:
    def balances(i: uint256) -> uint256: view


LIDO_ORACLE: constant(address) = 0x442af784A788A5bd6F42A01Ebe9F287a871243fb
LIDO_NODE_OPS_REGISTRY: constant(address) = 0x55032650b14df07b85bF18A3a3eC8E0Af2e028d5
ANCHOR_VAULT: constant(address) = 0xA2F987A546D4CD1c607Ee8141276876C26b72Bdf
CURVE_STETH_POOL: constant(address) = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022
WSTETH_TOKEN: constant(address) = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
BALANCER_VAULT: constant(address) = 0xBA12222222228d8Ba445958a75a0704d566BF2C8
BALANCER_POOL_ID: constant(bytes32) = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080


admin: public(address)


@external
def __init__():
    self.admin = msg.sender


@external
def set_admin(new_admin: address):
    assert msg.sender == self.admin # dev: unauthorized
    self.admin = new_admin


@external
def kill():
    assert msg.sender == self.admin # dev: unauthorized
    selfdestruct(msg.sender)


@internal
@view
def _get_node_op_spare_keys_count(id: uint256) -> uint256:
    active: bool = False
    name: String[100] = ""
    reward_address: address = ZERO_ADDRESS
    staking_limit: uint256 = 0
    stopped_validators: uint256 = 0
    total_signing_keys: uint256 = 0
    used_signing_keys: uint256 = 0

    (active, name, reward_address, staking_limit,
        stopped_validators,
        total_signing_keys,
        used_signing_keys) = LidoNodeOperators(LIDO_NODE_OPS_REGISTRY).getNodeOperator(id, False)

    if (not active) or (staking_limit <= used_signing_keys):
        return 0

    return min(total_signing_keys, staking_limit) - used_signing_keys

@external
@view
def get_node_op_spare_keys_count(id: uint256) -> uint256:
    return self._get_node_op_spare_keys_count(id)


@external
@view
def spare_signing_keys_count() -> uint256:
    total_ops: uint256 = LidoNodeOperators(LIDO_NODE_OPS_REGISTRY).getNodeOperatorsCount()
    spare_keys: uint256 = 0
    for i in range(300):
        if i >= total_ops:
            break
        spare_keys += self._get_node_op_spare_keys_count(i)
    return spare_keys


@internal
@view
def _last_reported_epoch_time() -> uint256:
    _: uint256 = 0
    slots_per_epoch: uint256 = 0
    seconds_per_slot: uint256 = 0
    genesis_time: uint256 = 0
    (_, slots_per_epoch, seconds_per_slot, genesis_time) = LidoOracle(LIDO_ORACLE).getBeaconSpec()
    epoch_id: uint256 = LidoOracle(LIDO_ORACLE).getLastCompletedEpochId()
    return genesis_time + epoch_id * slots_per_epoch * seconds_per_slot

@external
@view
def last_reported_epoch_time() -> uint256:
    return self._last_reported_epoch_time()

@external
@view
def time_since_last_reported_epoch() -> uint256:
    return block.timestamp - self._last_reported_epoch_time()


@internal
@view
def _last_rewards_liquidation_time() -> uint256:
    return AnchorVault(ANCHOR_VAULT).last_liquidation_time()

@external
@view
def last_rewards_liquidation_time() -> uint256:
    return self._last_rewards_liquidation_time()


@external
@view
def time_since_last_liquidation() -> uint256:
    last_liquidation_at: uint256 = self._last_rewards_liquidation_time()
    return block.timestamp - last_liquidation_at


@internal
@view
def _time_without_liquidation_since_reported_epoch() -> uint256:
    reported_epoch_time: uint256 = self._last_reported_epoch_time()
    last_liquidation_at: uint256 = self._last_rewards_liquidation_time()
    if last_liquidation_at > reported_epoch_time:
        return 0
    return block.timestamp - reported_epoch_time

@external
@view
def time_without_liquidation_since_reported_epoch() -> uint256:
    return self._time_without_liquidation_since_reported_epoch()


@external
@view
def curve_pool_size() -> uint256:
    eth_balance: uint256 = CurveStableSwap(CURVE_STETH_POOL).balances(0)
    steth_balance: uint256 = CurveStableSwap(CURVE_STETH_POOL).balances(1)
    return eth_balance + steth_balance


@internal
@pure
def _calc_imbalance(eth_balance: uint256, steth_balance: uint256) -> int256:
    if steth_balance >= eth_balance:
        return convert((steth_balance * 10**18) / eth_balance - 10**18, int256)
    else:
        return -convert((eth_balance * 10**18) / steth_balance - 10**18, int256)


@external
@view
def curve_pool_imbalance_percent() -> int256:
    """
    @dev Value between -10**18 (only ETH in pool) to 10**18 (only stETH in pool).
    """
    eth_balance: uint256 = CurveStableSwap(CURVE_STETH_POOL).balances(0)
    steth_balance: uint256 = CurveStableSwap(CURVE_STETH_POOL).balances(1)
    return self._calc_imbalance(eth_balance, steth_balance)


@internal
@view
def _balancer_get_balances() -> (uint256, uint256):
    result: Bytes[32 * 9] = raw_call(
        BALANCER_VAULT,
        concat(method_id("getPoolTokens(bytes32)"), BALANCER_POOL_ID),
        max_outsize = 32 * 9,
        is_static_call = True
    )
    # the return type is (tokens address[], balances uint256[], lastChangeBlock uint256)
    # and there are two items in each array
    wsteth_balance: uint256 = convert(extract32(result, 32*7), uint256)
    eth_balance: uint256 = convert(extract32(result, 32*8), uint256)
    return (wsteth_balance, eth_balance)


@external
@view
def balancer_pool_size() -> uint256:
    wsteth_balance: uint256 = 0
    eth_balance: uint256 = 0
    (wsteth_balance, eth_balance) = self._balancer_get_balances()
    return wsteth_balance + eth_balance


@external
@view
def balancer_pool_imbalance_percent() -> int256:
    wsteth_balance: uint256 = 0
    eth_balance: uint256 = 0
    (wsteth_balance, eth_balance) = self._balancer_get_balances()
    steth_balance: uint256 = WstETH(WSTETH_TOKEN).getStETHByWstETH(wsteth_balance)
    return self._calc_imbalance(eth_balance, steth_balance)