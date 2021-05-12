# @version 0.2.12
"""
@title Checkpoint Proxy
@author Curve.Fi
@license MIT
@notice Calls `checkpoint` on Anyswap gauges to meet bridge whitelisting requirements
"""

interface RootGauge:
    def checkpoint() -> bool: nonpayable


@external
def checkpoint(_gauge: address) -> bool:
    RootGauge(_gauge).checkpoint()

    return True


@external
def checkpoint_many(_gauges: address[10]) -> bool:
    for gauge in _gauges:
        if gauge == ZERO_ADDRESS:
            break
        RootGauge(gauge).checkpoint()

    return True