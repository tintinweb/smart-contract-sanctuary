# @version 0.2.15
# @author skozin
# @licence MIT

interface LidoOracle:
    def getLastCompletedEpochId() -> uint256: view
    def getBeaconSpec() -> (uint256, uint256, uint256, uint256): view

interface AnchorVault:
    def last_liquidation_time() -> uint256: view

interface CurveStableSwap:
    def balances(i: uint256) -> uint256: view


LIDO_ORACLE: constant(address) = 0x442af784A788A5bd6F42A01Ebe9F287a871243fb
ANCHOR_VAULT: constant(address) = 0xA2F987A546D4CD1c607Ee8141276876C26b72Bdf
STETH_POOL: constant(address) = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022


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
def pool_size() -> uint256:
    eth_balance: uint256 = CurveStableSwap(STETH_POOL).balances(0)
    steth_balance: uint256 = CurveStableSwap(STETH_POOL).balances(1)
    return eth_balance + steth_balance


@external
@view
def pool_imbalance_percent() -> int256:
    """
    @dev Value between -10**18 (only ETH in pool) to 10**18 (only stETH in pool).
    """
    eth_balance: uint256 = CurveStableSwap(STETH_POOL).balances(0)
    steth_balance: uint256 = CurveStableSwap(STETH_POOL).balances(1)
    total_balance: int256 = convert(eth_balance + steth_balance, int256)
    imbalance: int256 = convert(steth_balance, int256) - convert(eth_balance, int256)
    return (imbalance * 10**18) / total_balance