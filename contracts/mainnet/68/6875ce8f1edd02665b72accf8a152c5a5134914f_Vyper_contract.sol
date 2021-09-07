# @version 0.2.15
# @author skozin
# @licence MIT

interface LidoOracle:
    def getLastCompletedEpochId() -> uint256: view
    def getBeaconSpec() -> (uint256, uint256, uint256, uint256): view

interface AnchorVault:
    def last_liquidation_time() -> uint256: view


LIDO_ORACLE: constant(address) = 0x442af784A788A5bd6F42A01Ebe9F287a871243fb
ANCHOR_VAULT: constant(address) = 0xA2F987A546D4CD1c607Ee8141276876C26b72Bdf


admin: public(address)
oracle_report_period: public(uint256)
max_oracle_report_inclusion_delay: public(uint256)
max_rewards_liquidation_delay: public(uint256)


@external
def __init__(admin: address):
    self.admin = admin


@external
def set_admin(new_admin: address):
    assert msg.sender == self.admin # dev: unauthorized
    self.admin = new_admin


@external
def configure(
    oracle_report_period: uint256,
    max_oracle_report_inclusion_delay: uint256,
    max_rewards_liquidation_delay: uint256,
):
    assert msg.sender == self.admin # dev: unauthorized
    self.oracle_report_period = oracle_report_period
    self.max_oracle_report_inclusion_delay = max_oracle_report_inclusion_delay
    self.max_rewards_liquidation_delay = max_rewards_liquidation_delay


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


@internal
@view
def _last_rewards_liquidation_time() -> uint256:
    return AnchorVault(ANCHOR_VAULT).last_liquidation_time()


@internal
@view
def _time_since_last_liquidation() -> uint256:
    last_liquidation_at: uint256 = self._last_rewards_liquidation_time()
    return block.timestamp - last_liquidation_at

@external
@view
def time_since_last_liquidation() -> uint256:
    return self._time_since_last_liquidation()


@internal
@view
def _max_time_since_last_liquidation() -> uint256:
    return self.oracle_report_period + self.max_rewards_liquidation_delay

@external
@view
def max_time_since_last_liquidation() -> uint256:
    return self._max_time_since_last_liquidation()


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


@internal
@view
def _max_time_without_liquidation_since_reported_epoch() -> uint256:
    return self.max_oracle_report_inclusion_delay + self.max_rewards_liquidation_delay

@external
@view
def max_time_without_liquidation_since_reported_epoch() -> uint256:
    return self._max_time_without_liquidation_since_reported_epoch()


@external
@view
def is_rewards_liquidation_overdue_1() -> bool:
    return self._time_since_last_liquidation() > self._max_time_since_last_liquidation()


@external
@view
def is_rewards_liquidation_overdue_2() -> bool:
    return (
        self._time_without_liquidation_since_reported_epoch() >
        self._max_time_without_liquidation_since_reported_epoch()
    )