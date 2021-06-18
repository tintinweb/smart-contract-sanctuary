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
def checkpoint(_gauge: address):
    # anyswap bridge cannot handle multiple transfers in one call, so we
    # block smart contracts that could checkpoint multiple gauges at once
    assert msg.sender == tx.origin

    RootGauge(_gauge).checkpoint()